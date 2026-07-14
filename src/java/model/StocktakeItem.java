package model;

import java.sql.Timestamp;

/**
 * Một serial cụ thể được scan trong phiếu kiểm kê (countMode='SERIAL').
 *
 * scannedStatus:
 *   FOUND   — serial có trong DB, scan được, OK
 *   MISSING — serial có trong DB nhưng không tìm thấy ngoài kho → đánh dấu LOST
 *   DAMAGED — serial scan được, nhưng nhân viên đánh dấu hỏng → chuyển sang QUARANTINE + condition=DAMAGED
 *   EXTRA   — serial ngoài kho có, nhưng DB chưa có → tạo mới Product_Items khi adjust
 */
public class StocktakeItem {

    public static final String STATUS_FOUND   = "FOUND";
    public static final String STATUS_MISSING = "MISSING";
    public static final String STATUS_DAMAGED = "DAMAGED";
    public static final String STATUS_EXTRA   = "EXTRA";

    public static final String PHASE_COUNT  = "COUNT";
    public static final String PHASE_VERIFY = "VERIFY";

    private int id;
    private int stocktakeId;
    private Integer productItemId;       // NULL khi scannedStatus=EXTRA
    private int productId;
    private String serialNumber;
    private String scannedStatus;
    private String newCondition;         // NULL hoặc NEW/USED/DAMAGED
    private String note;
    private String phase;                // COUNT | VERIFY
    private Timestamp createdAt;

    // Join
    private String productName;
    private String sku;

    public StocktakeItem() {}

    public int getId() { return id; }
    public void setId(int v) { this.id = v; }

    public int getStocktakeId() { return stocktakeId; }
    public void setStocktakeId(int v) { this.stocktakeId = v; }

    public Integer getProductItemId() { return productItemId; }
    public void setProductItemId(Integer v) { this.productItemId = v; }

    public int getProductId() { return productId; }
    public void setProductId(int v) { this.productId = v; }

    public String getSerialNumber() { return serialNumber; }
    public void setSerialNumber(String v) { this.serialNumber = v; }

    public String getScannedStatus() { return scannedStatus; }
    public void setScannedStatus(String v) { this.scannedStatus = v; }

    public String getNewCondition() { return newCondition; }
    public void setNewCondition(String v) { this.newCondition = v; }

    public String getNote() { return note; }
    public void setNote(String v) { this.note = v; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp v) { this.createdAt = v; }

    public String getProductName() { return productName; }
    public void setProductName(String v) { this.productName = v; }

    public String getSku() { return sku; }
    public void setSku(String v) { this.sku = v; }

    public String getPhase() { return phase; }
    public void setPhase(String v) { this.phase = v; }
}
