package model;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * 1 SKU gộp từ nhiều kho — dùng khi xem "Tất cả kho".
 */
public class InventoryGroupedRow {

    private int productId;
    private String productName;
    private String sku;
    private String unit;
    private int minStock;
    private String categoryName;
    private String brandName;
    private BigDecimal averageCost;

    private int totalNew;
    private int totalUsed;
    private int totalQuantity;
    private int totalQuarantine;
    private int totalInTransit;
    private int totalLost;

    private List<InventoryRow> warehouses = new ArrayList<>();

    public InventoryGroupedRow() {}

    public boolean isAnyLowStock() {
        for (InventoryRow w : warehouses) {
            if (w.isLowStock()) return true;
        }
        return false;
    }

    public boolean hasAnyDamaged() { return totalQuarantine > 0; }
    public boolean hasAnyInTransit() { return totalInTransit > 0; }

    public int getProductId() { return productId; }
    public void setProductId(int v) { this.productId = v; }

    public String getProductName() { return productName; }
    public void setProductName(String v) { this.productName = v; }

    public String getSku() { return sku; }
    public void setSku(String v) { this.sku = v; }

    public String getUnit() { return unit; }
    public void setUnit(String v) { this.unit = v; }

    public int getMinStock() { return minStock; }
    public void setMinStock(int v) { this.minStock = v; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String v) { this.categoryName = v; }

    public String getBrandName() { return brandName; }
    public void setBrandName(String v) { this.brandName = v; }

    public BigDecimal getAverageCost() { return averageCost; }
    public void setAverageCost(BigDecimal v) { this.averageCost = v; }

    public int getTotalNew() { return totalNew; }
    public void setTotalNew(int v) { this.totalNew = v; }

    public int getTotalUsed() { return totalUsed; }
    public void setTotalUsed(int v) { this.totalUsed = v; }

    public int getTotalOnHand() { return totalNew + totalUsed + totalQuarantine; }

    public int getTotalQuantity() { return totalQuantity; }
    public void setTotalQuantity(int v) { this.totalQuantity = v; }

    public int getTotalQuarantine() { return totalQuarantine; }
    public void setTotalQuarantine(int v) { this.totalQuarantine = v; }

    public int getTotalInTransit() { return totalInTransit; }
    public void setTotalInTransit(int v) { this.totalInTransit = v; }

    public int getTotalLost() { return totalLost; }
    public void setTotalLost(int v) { this.totalLost = v; }

    public List<InventoryRow> getWarehouses() { return warehouses; }
    public void setWarehouses(List<InventoryRow> v) { this.warehouses = v; }
}
