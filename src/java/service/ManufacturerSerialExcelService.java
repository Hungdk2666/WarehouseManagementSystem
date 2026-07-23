package service;

import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.ss.usermodel.FormulaEvaluator;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;

/**
 * Reads manufacturer serials from Excel. Database duplicate checks are kept in
 * the ticket confirmation transaction so Excel and direct scans follow exactly
 * the same business rules.
 */
public class ManufacturerSerialExcelService {

    public static class ParseResult {
        private boolean valid = true;
        private final List<String> errors = new ArrayList<>();
        private Map<Integer, List<String>> serialsByProductId = new LinkedHashMap<>();

        public boolean isValid() { return valid; }
        public List<String> getErrors() { return errors; }
        public Map<Integer, List<String>> getSerialsByProductId() { return serialsByProductId; }

        public void addError(String error) {
            errors.add(error);
            valid = false;
        }

        public int getTotalSerials() {
            int total = 0;
            for (List<String> list : serialsByProductId.values()) total += list.size();
            return total;
        }
    }

    /**
     * @param inputStream uploaded Excel workbook
     * @param expectedBySku SKU -> quantity that will actually be received
     * @param productIdBySku SKU -> product id
     */
    public ParseResult parseAndValidate(InputStream inputStream,
            Map<String, Integer> expectedBySku,
            Map<String, Integer> productIdBySku) {
        ParseResult result = new ParseResult();

        Map<String, Integer> normalizedExpected = new HashMap<>();
        Map<String, Integer> normalizedProductIds = new HashMap<>();
        Map<String, String> displaySku = new HashMap<>();
        for (Map.Entry<String, Integer> entry : expectedBySku.entrySet()) {
            String key = normalizeSku(entry.getKey());
            normalizedExpected.put(key, entry.getValue());
            normalizedProductIds.put(key, productIdBySku.get(entry.getKey()));
            displaySku.put(key, entry.getKey());
        }

        try (Workbook workbook = WorkbookFactory.create(inputStream)) {
            Sheet sheet = workbook.getNumberOfSheets() > 0 ? workbook.getSheetAt(0) : null;
            if (sheet == null) {
                result.addError("File Excel không có sheet nào.");
                return result;
            }

            DataFormatter formatter = new DataFormatter(Locale.ROOT);
            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();
            int headerRowIdx = findHeaderRow(sheet, formatter, evaluator);
            if (headerRowIdx < 0) {
                result.addError("Không tìm thấy dòng tiêu đề. File cần có cột 'sku' và 'manufacturer_serial'.");
                return result;
            }

            Row headerRow = sheet.getRow(headerRowIdx);
            int skuCol = findColumn(headerRow, formatter, evaluator, "sku");
            int serialCol = findColumn(headerRow, formatter, evaluator,
                    "manufacturer_serial", "serial_nsx", "mfr_serial", "serial");
            if (skuCol < 0 || serialCol < 0) {
                result.addError("File cần có đủ hai cột 'sku' và 'manufacturer_serial'.");
                return result;
            }

            Map<Integer, List<String>> parsed = new LinkedHashMap<>();
            Set<String> seenInFile = new HashSet<>();

            for (int i = headerRowIdx + 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                String sku = cellText(row, skuCol, formatter, evaluator).trim();
                String manufacturerSerial = cellText(row, serialCol, formatter, evaluator).trim();
                if (sku.isEmpty() && manufacturerSerial.isEmpty()) continue;

                int rowNumber = i + 1;
                String skuKey = normalizeSku(sku);
                if (sku.isEmpty()) {
                    result.addError("Dòng " + rowNumber + ": thiếu SKU.");
                    continue;
                }
                if (!normalizedExpected.containsKey(skuKey)) {
                    result.addError("Dòng " + rowNumber + ": SKU '" + sku + "' không có trong phiếu nhập.");
                    continue;
                }
                if (!isValidSerial(manufacturerSerial)) {
                    result.addError("Dòng " + rowNumber + ": serial nhà sản xuất trống, quá 100 ký tự hoặc chứa ký tự không hợp lệ.");
                    continue;
                }

                int productId = normalizedProductIds.get(skuKey);
                String duplicateKey = productId + "\u0000" + manufacturerSerial.toLowerCase(Locale.ROOT);
                if (!seenInFile.add(duplicateKey)) {
                    result.addError("Dòng " + rowNumber + ": serial '" + manufacturerSerial
                            + "' bị lặp cho cùng sản phẩm " + displaySku.get(skuKey) + ".");
                    continue;
                }
                parsed.computeIfAbsent(productId, ignored -> new ArrayList<>()).add(manufacturerSerial);
            }

            for (Map.Entry<String, Integer> entry : normalizedExpected.entrySet()) {
                int productId = normalizedProductIds.get(entry.getKey());
                int actual = parsed.getOrDefault(productId, new ArrayList<>()).size();
                if (actual != entry.getValue()) {
                    result.addError("SKU '" + displaySku.get(entry.getKey()) + "': cần "
                            + entry.getValue() + " serial, file có " + actual + ".");
                }
            }

            if (result.isValid()) result.serialsByProductId = parsed;
        } catch (Exception e) {
            result.addError("Không đọc được file Excel: " + e.getMessage());
        }
        return result;
    }

    private int findHeaderRow(Sheet sheet, DataFormatter formatter, FormulaEvaluator evaluator) {
        for (int i = 0; i <= Math.min(5, sheet.getLastRowNum()); i++) {
            Row row = sheet.getRow(i);
            if (row == null) continue;
            for (int c = Math.max(0, row.getFirstCellNum()); c < row.getLastCellNum(); c++) {
                if ("sku".equals(cellText(row, c, formatter, evaluator).trim().toLowerCase(Locale.ROOT))) return i;
            }
        }
        return -1;
    }

    private int findColumn(Row row, DataFormatter formatter, FormulaEvaluator evaluator, String... names) {
        for (int c = Math.max(0, row.getFirstCellNum()); c < row.getLastCellNum(); c++) {
            String value = cellText(row, c, formatter, evaluator).trim().toLowerCase(Locale.ROOT);
            for (String name : names) if (name.equals(value)) return c;
        }
        return -1;
    }

    private String cellText(Row row, int column, DataFormatter formatter, FormulaEvaluator evaluator) {
        if (row == null || row.getCell(column) == null) return "";
        return formatter.formatCellValue(row.getCell(column), evaluator);
    }

    private String normalizeSku(String sku) {
        return sku == null ? "" : sku.trim().toLowerCase(Locale.ROOT);
    }

    private boolean isValidSerial(String serial) {
        if (serial == null || serial.isEmpty() || serial.length() > 100) return false;
        for (int i = 0; i < serial.length(); i++) {
            if (Character.isISOControl(serial.charAt(i))) return false;
        }
        return true;
    }
}
