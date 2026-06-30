package service;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import utils.DBUtils;

public class ManufacturerSerialExcelService {

    public static class ParseResult {
        private boolean valid;
        private List<String> errors;
        private Map<String, List<String>> serialsBySku; // SKU -> list of manufacturer serials

        public ParseResult() {
            this.valid = true;
            this.errors = new ArrayList<>();
            this.serialsBySku = new LinkedHashMap<>();
        }

        public boolean isValid() { return valid; }
        public void setValid(boolean v) { this.valid = v; }
        public List<String> getErrors() { return errors; }
        public Map<String, List<String>> getSerialsBySku() { return serialsBySku; }

        public void addError(String error) {
            this.errors.add(error);
            this.valid = false;
        }

        public int getTotalSerials() {
            int total = 0;
            for (List<String> list : serialsBySku.values()) total += list.size();
            return total;
        }
    }

    /**
     * Parse Excel file and validate against ticket details.
     * @param inputStream  the uploaded .xlsx file
     * @param expectedBySku  map of SKU -> expected quantity from the ticket
     * @return ParseResult with errors or validated serials grouped by SKU
     */
    public ParseResult parseAndValidate(InputStream inputStream, Map<String, Integer> expectedBySku) {
        ParseResult result = new ParseResult();

        try (Workbook workbook = WorkbookFactory.create(inputStream)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null) {
                result.addError("File Excel không có sheet nào.");
                return result;
            }

            int headerRowIdx = findHeaderRow(sheet);
            if (headerRowIdx < 0) {
                result.addError("Không tìm thấy header. File cần có cột 'sku' và 'manufacturer_serial'.");
                return result;
            }

            Row headerRow = sheet.getRow(headerRowIdx);
            int skuCol = findColumn(headerRow, "sku");
            int serialCol = findColumn(headerRow, "manufacturer_serial", "serial_nsx", "mfr_serial", "serial");
            if (skuCol < 0 || serialCol < 0) {
                result.addError("Không tìm thấy cột 'sku' hoặc 'manufacturer_serial' trong header.");
                return result;
            }

            Set<String> seenInFile = new HashSet<>();
            Map<String, List<String>> parsed = new LinkedHashMap<>();

            for (int i = headerRowIdx + 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;

                String sku = getCellString(row.getCell(skuCol)).trim();
                String mfrSerial = getCellString(row.getCell(serialCol)).trim();

                if (sku.isEmpty() && mfrSerial.isEmpty()) continue;

                int rowNum = i + 1;

                if (sku.isEmpty()) {
                    result.addError("Dòng " + rowNum + ": thiếu SKU.");
                    continue;
                }
                if (mfrSerial.isEmpty()) {
                    result.addError("Dòng " + rowNum + ": thiếu manufacturer_serial.");
                    continue;
                }

                if (!expectedBySku.containsKey(sku)) {
                    result.addError("Dòng " + rowNum + ": SKU '" + sku + "' không có trong phiếu nhập.");
                    continue;
                }

                if (seenInFile.contains(mfrSerial)) {
                    result.addError("Dòng " + rowNum + ": serial '" + mfrSerial + "' bị trùng trong file.");
                    continue;
                }
                seenInFile.add(mfrSerial);

                parsed.computeIfAbsent(sku, k -> new ArrayList<>()).add(mfrSerial);
            }

            if (result.isValid() || result.getErrors().isEmpty()) {
                for (Map.Entry<String, Integer> entry : expectedBySku.entrySet()) {
                    String sku = entry.getKey();
                    int expected = entry.getValue();
                    List<String> serials = parsed.getOrDefault(sku, new ArrayList<>());
                    if (serials.size() != expected) {
                        result.addError("SKU '" + sku + "': cần " + expected + " serial, file có " + serials.size() + ".");
                    }
                }
            }

            if (result.isValid()) {
                List<String> dbDuplicates = checkDuplicatesInDB(seenInFile);
                for (String dup : dbDuplicates) {
                    result.addError("Serial '" + dup + "' đã tồn tại trong hệ thống.");
                }
            }

            if (result.isValid()) {
                result.serialsBySku = parsed;
            }

        } catch (Exception e) {
            result.addError("Không đọc được file Excel: " + e.getMessage());
        }

        return result;
    }

    private int findHeaderRow(Sheet sheet) {
        for (int i = 0; i <= Math.min(5, sheet.getLastRowNum()); i++) {
            Row row = sheet.getRow(i);
            if (row == null) continue;
            for (int c = row.getFirstCellNum(); c < row.getLastCellNum(); c++) {
                String val = getCellString(row.getCell(c)).trim().toLowerCase();
                if ("sku".equals(val)) return i;
            }
        }
        return -1;
    }

    private int findColumn(Row headerRow, String... names) {
        for (int c = headerRow.getFirstCellNum(); c < headerRow.getLastCellNum(); c++) {
            String val = getCellString(headerRow.getCell(c)).trim().toLowerCase();
            for (String name : names) {
                if (name.equals(val)) return c;
            }
        }
        return -1;
    }

    private String getCellString(Cell cell) {
        if (cell == null) return "";
        if (cell.getCellType() == CellType.STRING) return cell.getStringCellValue();
        if (cell.getCellType() == CellType.NUMERIC) return String.valueOf((long) cell.getNumericCellValue());
        return "";
    }

    private List<String> checkDuplicatesInDB(Set<String> serials) {
        List<String> duplicates = new ArrayList<>();
        if (serials.isEmpty()) return duplicates;

        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < serials.size(); i++) {
            if (i > 0) placeholders.append(",");
            placeholders.append("?");
        }

        String sql = "SELECT manufacturer_serial FROM Product_Items WHERE manufacturer_serial IN (" + placeholders + ")";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = 1;
            for (String s : serials) ps.setString(idx++, s);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) duplicates.add(rs.getString(1));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return duplicates;
    }
}
