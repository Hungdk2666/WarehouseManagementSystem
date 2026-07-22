package model;

/**
 * Một dòng trong "Báo cáo tổng hợp Nhập - Xuất - Tồn".
 * Mỗi dòng = 1 sản phẩm, 1 kho, 1 tình trạng hàng (Mới/Cũ/Hỏng), trong 1 kỳ (từ ngày - đến ngày).
 * Đầu kỳ / Cuối kỳ tái dựng từ Product_Ledger (giống StockSnapshotDAO);
 * Nhập/Xuất trong kỳ = tổng phát sinh trong khoảng ngày đã chọn.
 */
public class PeriodSummaryRow {
    private String sku;
    private String productName;
    private String unit;
    private int warehouseId;
    private String warehouseName;
    private String condition; // NEW | USED | DAMAGED
    private int openingQuantity;
    private int importQuantity;
    private int exportQuantity;
    private int adjustmentQuantity;
    private int closingQuantity;
    private String note;

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int warehouseId) { this.warehouseId = warehouseId; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String warehouseName) { this.warehouseName = warehouseName; }

    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }

    public String getConditionLabel() {
        if ("NEW".equals(condition)) return "Hàng mới";
        if ("USED".equals(condition)) return "Hàng cũ";
        if ("DAMAGED".equals(condition)) return "Hàng hỏng";
        return condition;
    }

    public int getOpeningQuantity() { return openingQuantity; }
    public void setOpeningQuantity(int openingQuantity) { this.openingQuantity = openingQuantity; }

    public int getImportQuantity() { return importQuantity; }
    public void setImportQuantity(int importQuantity) { this.importQuantity = importQuantity; }

    public int getExportQuantity() { return exportQuantity; }
    public void setExportQuantity(int exportQuantity) { this.exportQuantity = exportQuantity; }

    public int getAdjustmentQuantity() { return adjustmentQuantity; }
    public void setAdjustmentQuantity(int adjustmentQuantity) { this.adjustmentQuantity = adjustmentQuantity; }

    public int getClosingQuantity() { return closingQuantity; }
    public void setClosingQuantity(int closingQuantity) { this.closingQuantity = closingQuantity; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
