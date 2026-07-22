package model;

/**
 * Một dòng trong "Báo cáo chi tiết xuất - nhập vật tư theo ngày".
 * Mỗi dòng = tổng phát sinh nhập/xuất của 1 sản phẩm tại 1 kho, trong 1 ngày cụ thể.
 */
public class DailyMovementRow {
    private String sku;
    private String productName;
    private String unit;
    private int warehouseId;
    private String warehouseName;
    private String date;
    private int importQuantity;
    private int exportQuantity;
    private int adjustmentQuantity;
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

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public int getImportQuantity() { return importQuantity; }
    public void setImportQuantity(int importQuantity) { this.importQuantity = importQuantity; }

    public int getExportQuantity() { return exportQuantity; }
    public void setExportQuantity(int exportQuantity) { this.exportQuantity = exportQuantity; }

    public int getAdjustmentQuantity() { return adjustmentQuantity; }
    public void setAdjustmentQuantity(int adjustmentQuantity) { this.adjustmentQuantity = adjustmentQuantity; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
