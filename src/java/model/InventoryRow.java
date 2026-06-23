package model;

import java.math.BigDecimal;

/**
 * 1 dòng tồn kho = (warehouse_id, product_id) — không phải entity DB
 * mà là view tổng hợp để hiển thị danh sách trang Inventory.
 */
public class InventoryRow {

    private int warehouseId;
    private int productId;
    private int quantity;             // tồn bán được (NEW)
    private int quarantineQuantity;   // hàng cách ly (DAMAGED, chưa xuất bảo hành)
    private int inTransitQuantity;    // hàng đang chuyển kho (đi/đến) — denormalize từ Product_Items
    private int lostQuantity;         // hàng đã đánh dấu LOST

    // Join
    private String productName;
    private String sku;
    private String unit;
    private int minStock;
    private BigDecimal averageCost;
    private String categoryName;
    private String brandName;
    private String warehouseName;

    public InventoryRow() {}

    public int getTotalQuantity() { return quantity + quarantineQuantity; }
    public BigDecimal getInventoryValue() {
        if (averageCost == null) return BigDecimal.ZERO;
        return averageCost.multiply(BigDecimal.valueOf(quantity));
    }
    public boolean isLowStock() { return quantity < minStock; }
    public boolean hasDamaged() { return quarantineQuantity > 0; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int v) { this.warehouseId = v; }

    public int getProductId() { return productId; }
    public void setProductId(int v) { this.productId = v; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int v) { this.quantity = v; }

    public int getQuarantineQuantity() { return quarantineQuantity; }
    public void setQuarantineQuantity(int v) { this.quarantineQuantity = v; }

    public int getInTransitQuantity() { return inTransitQuantity; }
    public void setInTransitQuantity(int v) { this.inTransitQuantity = v; }

    public int getLostQuantity() { return lostQuantity; }
    public void setLostQuantity(int v) { this.lostQuantity = v; }

    public String getProductName() { return productName; }
    public void setProductName(String v) { this.productName = v; }

    public String getSku() { return sku; }
    public void setSku(String v) { this.sku = v; }

    public String getUnit() { return unit; }
    public void setUnit(String v) { this.unit = v; }

    public int getMinStock() { return minStock; }
    public void setMinStock(int v) { this.minStock = v; }

    public BigDecimal getAverageCost() { return averageCost; }
    public void setAverageCost(BigDecimal v) { this.averageCost = v; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String v) { this.categoryName = v; }

    public String getBrandName() { return brandName; }
    public void setBrandName(String v) { this.brandName = v; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String v) { this.warehouseName = v; }
}
