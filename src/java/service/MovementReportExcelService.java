package service;

import java.io.OutputStream;
import java.util.List;
import model.DailyMovementRow;
import model.PeriodSummaryRow;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/**
 * Xuất Excel cho 2 báo cáo xuất-nhập theo mẫu giấy, theo đúng pattern của StockSnapshotExcelService.
 */
public class MovementReportExcelService {

    private static final String[] DAILY_HEADERS = {
        "TT", "Mã vật tư", "Tên vật tư", "Đơn vị tính", "Ngày", "Nhập kho", "Xuất kho", "Điều chỉnh kiểm kê", "Kho", "Ghi chú"
    };

    private static final String[] PERIOD_HEADERS = {
        "TT", "Mã vật tư", "Tên vật tư", "Tình trạng", "Đơn vị tính", "Kho",
        "Đầu kỳ (Tồn kho)", "Trong kỳ - Nhập kho", "Trong kỳ - Xuất kho", "Điều chỉnh kiểm kê", "Cuối kỳ (Tồn kho)", "Ghi chú"
    };

    public void exportDaily(List<DailyMovementRow> data, String fromDate, String toDate, OutputStream out) throws Exception {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Chi tiet XNK theo ngay");
            CellStyle titleStyle = titleStyle(wb);
            CellStyle headerStyle = headerStyle(wb);
            CellStyle numberStyle = numberStyle(wb);

            Row titleRow = sheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("BÁO CÁO CHI TIẾT XUẤT - NHẬP VẬT TƯ THEO NGÀY (" + fromDate + " đến " + toDate + ")");
            titleCell.setCellStyle(titleStyle);

            int headerRowIdx = 2;
            Row headerRow = sheet.createRow(headerRowIdx);
            for (int i = 0; i < DAILY_HEADERS.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(DAILY_HEADERS[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = headerRowIdx + 1;
            int tt = 1;
            for (DailyMovementRow r : data) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(tt++);
                row.createCell(1).setCellValue(r.getSku() != null ? r.getSku() : "");
                row.createCell(2).setCellValue(r.getProductName() != null ? r.getProductName() : "");
                row.createCell(3).setCellValue(r.getUnit() != null ? r.getUnit() : "");
                row.createCell(4).setCellValue(r.getDate() != null ? r.getDate() : "");

                Cell impCell = row.createCell(5);
                impCell.setCellValue(r.getImportQuantity());
                impCell.setCellStyle(numberStyle);

                Cell expCell = row.createCell(6);
                expCell.setCellValue(r.getExportQuantity());
                expCell.setCellStyle(numberStyle);

                Cell adjustmentCell = row.createCell(7);
                adjustmentCell.setCellValue(r.getAdjustmentQuantity());
                adjustmentCell.setCellStyle(numberStyle);

                row.createCell(8).setCellValue(r.getWarehouseName() != null ? r.getWarehouseName() : "");
                row.createCell(9).setCellValue(r.getNote() != null ? r.getNote() : "");
            }

            for (int i = 0; i < DAILY_HEADERS.length; i++) sheet.autoSizeColumn(i);
            sheet.setAutoFilter(new org.apache.poi.ss.util.CellRangeAddress(headerRowIdx, headerRowIdx, 0, DAILY_HEADERS.length - 1));

            wb.write(out);
        }
    }

    public void exportPeriod(List<PeriodSummaryRow> data, String fromDate, String toDate, OutputStream out) throws Exception {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Tong hop NXT");
            CellStyle titleStyle = titleStyle(wb);
            CellStyle headerStyle = headerStyle(wb);
            CellStyle numberStyle = numberStyle(wb);

            Row titleRow = sheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("BÁO CÁO TỔNG HỢP NHẬP - XUẤT - TỒN (" + fromDate + " đến " + toDate + ")");
            titleCell.setCellStyle(titleStyle);

            int headerRowIdx = 2;
            Row headerRow = sheet.createRow(headerRowIdx);
            for (int i = 0; i < PERIOD_HEADERS.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(PERIOD_HEADERS[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = headerRowIdx + 1;
            int tt = 1;
            for (PeriodSummaryRow r : data) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(tt++);
                row.createCell(1).setCellValue(r.getSku() != null ? r.getSku() : "");
                row.createCell(2).setCellValue(r.getProductName() != null ? r.getProductName() : "");
                row.createCell(3).setCellValue(r.getConditionLabel() != null ? r.getConditionLabel() : "");
                row.createCell(4).setCellValue(r.getUnit() != null ? r.getUnit() : "");
                row.createCell(5).setCellValue(r.getWarehouseName() != null ? r.getWarehouseName() : "");

                int[] quantities = { r.getOpeningQuantity(), r.getImportQuantity(), r.getExportQuantity(),
                        r.getAdjustmentQuantity(), r.getClosingQuantity() };
                for (int i = 0; i < quantities.length; i++) {
                    Cell qtyCell = row.createCell(6 + i);
                    qtyCell.setCellValue(quantities[i]);
                    qtyCell.setCellStyle(numberStyle);
                }
                row.createCell(11).setCellValue(r.getNote() != null ? r.getNote() : "");
            }

            for (int i = 0; i < PERIOD_HEADERS.length; i++) sheet.autoSizeColumn(i);
            sheet.setAutoFilter(new org.apache.poi.ss.util.CellRangeAddress(headerRowIdx, headerRowIdx, 0, PERIOD_HEADERS.length - 1));

            wb.write(out);
        }
    }

    private CellStyle titleStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setBold(true);
        font.setFontHeightInPoints((short) 14);
        style.setFont(font);
        return style;
    }

    private CellStyle headerStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setBold(true);
        style.setFont(font);
        style.setFillForegroundColor(IndexedColors.LIGHT_GREEN.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setBorderBottom(BorderStyle.THIN);
        style.setBorderTop(BorderStyle.THIN);
        style.setBorderLeft(BorderStyle.THIN);
        style.setBorderRight(BorderStyle.THIN);
        return style;
    }

    private CellStyle numberStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        DataFormat df = wb.createDataFormat();
        style.setDataFormat(df.getFormat("#,##0"));
        return style;
    }
}
