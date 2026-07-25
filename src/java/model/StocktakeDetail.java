package model;

/**
 * Dòng chi tiết phiếu kiểm kê — 1 SKU.
 *   theoreticalQty = số trong sổ (lấy từ Inventories.quantity lúc tạo phiếu)
 *   actualQty      = số đếm được thực tế
 *   damagedQty     = trong số đếm được, có bao nhiêu cái hỏng (tách riêng để chuyển sang quarantine)
 *
 * Chênh lệch = actualQty - theoreticalQty
 *   &lt; 0 → thiếu (LOST)
 *   > 0 → thừa (FOUND)
 *   = 0 → khớp
 */
public class StocktakeDetail {

    public static final String REASON_NONE     = "NONE";
    public static final String REASON_LOST     = "LOST";
    public static final String REASON_FOUND    = "FOUND";
    public static final String REASON_DAMAGED  = "DAMAGED";
    public static final String REASON_EXPIRED  = "EXPIRED";
    public static final String REASON_MISCOUNT = "MISCOUNT";
    public static final String REASON_OTHER    = "OTHER";

    private int stocktakeId;
    private int productId;
    private int theoreticalQty;
    private int actualQty;
    private int damagedQty;
    // Snapshot theo tình trạng. Tổng vẫn được giữ ở các cột cũ để tương thích
    // với phiếu lịch sử và các màn hình/báo cáo đang dùng tổng số lượng.
    private int theoreticalNewQty;
    private int theoreticalUsedQty;
    private int theoreticalDamagedQty;
    private int actualNewQty;
    private int actualUsedQty;
    private int actualDamagedQty;
    private String varianceReason;
    private String note;

    // Join fields
    private String productName;
    private String sku;
    private String unit;
    private double unitCost;        // dùng để tính varianceValue khi submit

    public StocktakeDetail() {}

    public int getVariance() { return actualQty - theoreticalQty; }

    public int getStocktakeId() { return stocktakeId; }
    public void setStocktakeId(int v) { this.stocktakeId = v; }

    public int getProductId() { return productId; }
    public void setProductId(int v) { this.productId = v; }

    public int getTheoreticalQty() { return theoreticalQty; }
    public void setTheoreticalQty(int v) { this.theoreticalQty = v; }

    public int getActualQty() { return actualQty; }
    public void setActualQty(int v) { this.actualQty = v; }

    public int getDamagedQty() { return damagedQty; }
    public void setDamagedQty(int v) { this.damagedQty = v; }

    public int getTheoreticalNewQty() { return theoreticalNewQty; }
    public void setTheoreticalNewQty(int v) { this.theoreticalNewQty = v; }

    public int getTheoreticalUsedQty() { return theoreticalUsedQty; }
    public void setTheoreticalUsedQty(int v) { this.theoreticalUsedQty = v; }

    public int getTheoreticalDamagedQty() { return theoreticalDamagedQty; }
    public void setTheoreticalDamagedQty(int v) { this.theoreticalDamagedQty = v; }

    public int getActualNewQty() { return actualNewQty; }
    public void setActualNewQty(int v) { this.actualNewQty = v; }

    public int getActualUsedQty() { return actualUsedQty; }
    public void setActualUsedQty(int v) { this.actualUsedQty = v; }

    public int getActualDamagedQty() { return actualDamagedQty; }
    public void setActualDamagedQty(int v) { this.actualDamagedQty = v; }

    public String getVarianceReason() { return varianceReason; }
    public void setVarianceReason(String v) { this.varianceReason = v; }

    public String getNote() { return note; }
    public void setNote(String v) { this.note = v; }

    public String getProductName() { return productName; }
    public void setProductName(String v) { this.productName = v; }

    public String getSku() { return sku; }
    public void setSku(String v) { this.sku = v; }

    public String getUnit() { return unit; }
    public void setUnit(String v) { this.unit = v; }

    public double getUnitCost() { return unitCost; }
    public void setUnitCost(double v) { this.unitCost = v; }
}
