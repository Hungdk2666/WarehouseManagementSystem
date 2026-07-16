package model;

/**
 * Một dòng trong "Báo cáo tồn kho theo ngày".
 * Mỗi dòng = tồn của 1 sản phẩm trong 1 kho, tại thời điểm cuối ngày được chọn.
 * Tồn được tái dựng từ bảng Product_Ledger (không có bảng snapshot riêng).
 */
public class StockSnapshotRow {
    private String sku;
    private String productName;
    private String unit;
    private int warehouseId;
    private String warehouseName;
    private int newQuantity;
    private int usedQuantity;
    private int damagedQuantity;
    private int quantity;

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

    public int getNewQuantity() { return newQuantity; }
    public void setNewQuantity(int newQuantity) { this.newQuantity = newQuantity; }

    public int getUsedQuantity() { return usedQuantity; }
    public void setUsedQuantity(int usedQuantity) { this.usedQuantity = usedQuantity; }

    public int getDamagedQuantity() { return damagedQuantity; }
    public void setDamagedQuantity(int damagedQuantity) { this.damagedQuantity = damagedQuantity; }

    public int getTotalQuantity() { return quantity; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
}
