package service;

import java.io.OutputStream;
import java.util.List;
import model.TicketReportRow;
import org.apache.poi.ss.usermodel.BorderStyle;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.DataFormat;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

/** Excel exports for operational ticket reports, deliberately without export prices. */
public class TicketReportExcelService {
    private static final String[] IMPORT_HEADERS = {
        "TT", "Ngày nhập", "Số phiếu", "Loại nhập", "Mã vật tư", "Tên vật tư", "Đơn vị tính",
        "Số lượng", "Đơn giá nhập", "Thành tiền", "Kho nhận", "Nguồn hàng"
    };
    private static final String[] EXPORT_HEADERS = {
        "TT", "Ngày xuất", "Số phiếu", "Loại xuất", "Mã vật tư", "Tên vật tư", "Đơn vị tính",
        "Số lượng", "Kho xuất", "Điểm đến"
    };

    public void exportImport(List<TicketReportRow> rows, String fromDate, String toDate, OutputStream out) throws Exception {
        export(rows, fromDate, toDate, true, out);
    }

    public void exportExport(List<TicketReportRow> rows, String fromDate, String toDate, OutputStream out) throws Exception {
        export(rows, fromDate, toDate, false, out);
    }

    private void export(List<TicketReportRow> rows, String fromDate, String toDate,
            boolean importReport, OutputStream out) throws Exception {
        try (Workbook workbook = new XSSFWorkbook()) {
            String[] headers = importReport ? IMPORT_HEADERS : EXPORT_HEADERS;
            Sheet sheet = workbook.createSheet(importReport ? "Bao cao nhap hang" : "Bao cao xuat kho");
            CellStyle title = titleStyle(workbook);
            CellStyle header = headerStyle(workbook);
            CellStyle number = numberStyle(workbook);

            Row titleRow = sheet.createRow(0);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue((importReport ? "BÁO CÁO NHẬP HÀNG" : "BÁO CÁO XUẤT KHO")
                    + " (" + fromDate + " đến " + toDate + ")");
            titleCell.setCellStyle(title);

            Row headerRow = sheet.createRow(2);
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(header);
            }

            int rowIndex = 3;
            int ordinal = 1;
            for (TicketReportRow item : rows) {
                Row row = sheet.createRow(rowIndex++);
                row.createCell(0).setCellValue(ordinal++);
                row.createCell(1).setCellValue(value(item.getTransactionDate()));
                row.createCell(2).setCellValue(value(item.getTicketCode()));
                row.createCell(3).setCellValue(value(item.getReasonLabel()));
                row.createCell(4).setCellValue(value(item.getSku()));
                row.createCell(5).setCellValue(value(item.getProductName()));
                row.createCell(6).setCellValue(value(item.getUnit()));
                Cell quantity = row.createCell(7);
                quantity.setCellValue(item.getQuantity());
                quantity.setCellStyle(number);
                if (importReport) {
                    Cell unitCost = row.createCell(8);
                    Cell totalCost = row.createCell(9);
                    if (item.hasCost()) {
                        unitCost.setCellValue(item.getUnitCost().doubleValue());
                        totalCost.setCellValue(item.getTotalCost().doubleValue());
                        unitCost.setCellStyle(number);
                        totalCost.setCellStyle(number);
                    }
                    row.createCell(10).setCellValue(value(item.getWarehouseName()));
                    row.createCell(11).setCellValue(value(item.getPartnerName()));
                } else {
                    row.createCell(8).setCellValue(value(item.getWarehouseName()));
                    row.createCell(9).setCellValue(value(item.getPartnerName()));
                }
            }
            for (int i = 0; i < headers.length; i++) sheet.autoSizeColumn(i);
            sheet.setAutoFilter(new org.apache.poi.ss.util.CellRangeAddress(2, 2, 0, headers.length - 1));
            workbook.write(out);
        }
    }

    private String value(String text) { return text == null ? "" : text; }
    private CellStyle titleStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle(); Font font = workbook.createFont();
        font.setBold(true); font.setFontHeightInPoints((short) 14); style.setFont(font); return style;
    }
    private CellStyle headerStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle(); Font font = workbook.createFont(); font.setBold(true); style.setFont(font);
        style.setFillForegroundColor(IndexedColors.LIGHT_GREEN.getIndex()); style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        style.setBorderBottom(BorderStyle.THIN); style.setBorderTop(BorderStyle.THIN); style.setBorderLeft(BorderStyle.THIN); style.setBorderRight(BorderStyle.THIN); return style;
    }
    private CellStyle numberStyle(Workbook workbook) {
        CellStyle style = workbook.createCellStyle(); DataFormat format = workbook.createDataFormat(); style.setDataFormat(format.getFormat("#,##0")); return style;
    }
}
