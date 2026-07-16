package service;

import java.io.OutputStream;
import java.util.List;
import model.StockSnapshotRow;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Xuất báo cáo tồn kho theo ngày ra file Excel (.xlsx).
 * Dùng Apache POI 5.2.5 (đã có sẵn trong web/WEB-INF/lib), theo đúng pattern của
 * InventoryHistoryExcelService.
 */
public class StockSnapshotExcelService {

    private static final String[] HEADERS = {
        "SKU", "Tên sản phẩm", "Đơn vị", "Kho", "Hàng mới", "Hàng cũ", "Hàng hỏng", "Tổng hàng"
    };

    /**
     * @param data      danh sách dòng tồn kho
     * @param reportDate ngày báo cáo (yyyy-MM-dd hoặc rỗng = hôm nay), dùng cho tiêu đề sheet
     * @param out       output stream để ghi file
     */
    public void export(List<StockSnapshotRow> data, String reportDate, OutputStream out) throws Exception {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Ton kho theo ngay");

            CellStyle titleStyle = wb.createCellStyle();
            Font titleFont = wb.createFont();
            titleFont.setBold(true);
            titleFont.setFontHeightInPoints((short) 14);
            titleStyle.setFont(titleFont);

            CellStyle headerStyle = wb.createCellStyle();
            Font headerFont = wb.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.LIGHT_GREEN.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerStyle.setBorderBottom(BorderStyle.THIN);
            headerStyle.setBorderTop(BorderStyle.THIN);
            headerStyle.setBorderLeft(BorderStyle.THIN);
            headerStyle.setBorderRight(BorderStyle.THIN);

            CellStyle numberStyle = wb.createCellStyle();
            DataFormat df = wb.createDataFormat();
            numberStyle.setDataFormat(df.getFormat("#,##0"));

            // Dòng tiêu đề
            String dateLabel = (reportDate == null || reportDate.trim().isEmpty()) ? "hôm nay" : reportDate.trim();
            Row titleRow = sheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("BÁO CÁO TỒN KHO TẠI NGÀY " + dateLabel);
            titleCell.setCellStyle(titleStyle);

            // Dòng header (dòng thứ 3, để trống 1 dòng sau tiêu đề)
            int headerRowIdx = 2;
            Row headerRow = sheet.createRow(headerRowIdx);
            for (int i = 0; i < HEADERS.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(HEADERS[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = headerRowIdx + 1;
            for (StockSnapshotRow r : data) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(r.getSku() != null ? r.getSku() : "");
                row.createCell(1).setCellValue(r.getProductName() != null ? r.getProductName() : "");
                row.createCell(2).setCellValue(r.getUnit() != null ? r.getUnit() : "");
                row.createCell(3).setCellValue(r.getWarehouseName() != null ? r.getWarehouseName() : "");

                int[] quantities = { r.getNewQuantity(), r.getUsedQuantity(), r.getDamagedQuantity(), r.getTotalQuantity() };
                for (int i = 0; i < quantities.length; i++) {
                    Cell qtyCell = row.createCell(4 + i);
                    qtyCell.setCellValue(quantities[i]);
                    qtyCell.setCellStyle(numberStyle);
                }
            }

            for (int i = 0; i < HEADERS.length; i++) {
                sheet.autoSizeColumn(i);
            }

            sheet.setAutoFilter(new org.apache.poi.ss.util.CellRangeAddress(
                    headerRowIdx, headerRowIdx, 0, HEADERS.length - 1));

            wb.write(out);
        }
    }
}
