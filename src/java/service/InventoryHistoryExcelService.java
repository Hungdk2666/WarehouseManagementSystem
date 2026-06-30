package service;

import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.List;
import model.HistoryEntry;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

public class InventoryHistoryExcelService {

    private static final String[] HEADERS = {
        "Thời gian", "Loại giao dịch", "Mã phiếu", "Mã yêu cầu",
        "SKU", "Tên sản phẩm", "Số lượng thay đổi", "Tồn sau GD",
        "Kho", "Đối tác", "Đơn giá", "Thành tiền",
        "Người thực hiện", "Người duyệt YC"
    };

    public void export(List<HistoryEntry> data, OutputStream out) throws Exception {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet sheet = wb.createSheet("Lịch sử xuất nhập kho");

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

            CellStyle dateStyle = wb.createCellStyle();
            DataFormat df = wb.createDataFormat();
            dateStyle.setDataFormat(df.getFormat("dd/MM/yyyy HH:mm"));

            CellStyle numberStyle = wb.createCellStyle();
            numberStyle.setDataFormat(df.getFormat("#,##0"));

            CellStyle currencyStyle = wb.createCellStyle();
            currencyStyle.setDataFormat(df.getFormat("#,##0"));

            CellStyle positiveStyle = wb.createCellStyle();
            Font greenFont = wb.createFont();
            greenFont.setColor(IndexedColors.GREEN.getIndex());
            greenFont.setBold(true);
            positiveStyle.setFont(greenFont);
            positiveStyle.setDataFormat(df.getFormat("+#,##0"));

            CellStyle negativeStyle = wb.createCellStyle();
            Font redFont = wb.createFont();
            redFont.setColor(IndexedColors.RED.getIndex());
            redFont.setBold(true);
            negativeStyle.setFont(redFont);
            negativeStyle.setDataFormat(df.getFormat("#,##0"));

            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < HEADERS.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(HEADERS[i]);
                cell.setCellStyle(headerStyle);
            }

            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");

            int rowIdx = 1;
            for (HistoryEntry e : data) {
                Row row = sheet.createRow(rowIdx++);

                Cell c0 = row.createCell(0);
                if (e.getCreatedAt() != null) {
                    c0.setCellValue(e.getCreatedAt());
                    c0.setCellStyle(dateStyle);
                }

                row.createCell(1).setCellValue(e.getTransactionTypeLabel());
                row.createCell(2).setCellValue(e.getTicketCode() != null ? e.getTicketCode() : "");
                row.createCell(3).setCellValue(e.getRequestCode() != null ? e.getRequestCode() : "");
                row.createCell(4).setCellValue(e.getSku() != null ? e.getSku() : "");
                row.createCell(5).setCellValue(e.getProductName() != null ? e.getProductName() : "");

                Cell qtyCell = row.createCell(6);
                qtyCell.setCellValue(e.getChangeQuantity());
                qtyCell.setCellStyle(e.getChangeQuantity() >= 0 ? positiveStyle : negativeStyle);

                Cell balCell = row.createCell(7);
                balCell.setCellValue(e.getBalanceQuantity());
                balCell.setCellStyle(numberStyle);

                row.createCell(8).setCellValue(e.getWarehouseName() != null ? e.getWarehouseName() : "");
                row.createCell(9).setCellValue(e.getPartnerName() != null ? e.getPartnerName() : "");

                if (e.getUnitCost() != null) {
                    Cell priceCell = row.createCell(10);
                    priceCell.setCellValue(e.getUnitCost().doubleValue());
                    priceCell.setCellStyle(currencyStyle);

                    Cell totalCell = row.createCell(11);
                    totalCell.setCellValue(Math.abs(e.getChangeQuantity()) * e.getUnitCost().doubleValue());
                    totalCell.setCellStyle(currencyStyle);
                }

                row.createCell(12).setCellValue(e.getCreatedByName() != null ? e.getCreatedByName() : "");
                row.createCell(13).setCellValue(e.getApprovedByName() != null ? e.getApprovedByName() : "");
            }

            for (int i = 0; i < HEADERS.length; i++) {
                sheet.autoSizeColumn(i);
            }

            sheet.setAutoFilter(new org.apache.poi.ss.util.CellRangeAddress(0, 0, 0, HEADERS.length - 1));

            wb.write(out);
        }
    }
}
