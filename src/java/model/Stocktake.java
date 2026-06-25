package model;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;

/**
 * Phiếu kiểm kê — đếm thực tế trong kho, so với tồn lý thuyết.
 *
 * Status flow:
 *   DRAFT → COUNTING → SUBMITTED → (L1_APPROVED →)? APPROVED → ADJUSTED
 *                            ↓
 *                        REJECTED → quay về COUNTING
 *
 * Nếu requires_l2_approval = TRUE thì sau SUBMITTED phải qua L1_APPROVED
 * trước khi sang APPROVED (Business Admin duyệt cấp 2).
 */
public class Stocktake {

    // Scope
    public static final String SCOPE_FULL    = "FULL";
    public static final String SCOPE_PARTIAL = "PARTIAL";

    // Count mode
    public static final String MODE_QUANTITY = "QUANTITY";   // chỉ nhập số đếm
    public static final String MODE_SERIAL   = "SERIAL";     // scan từng serial

    // Status
    public static final String STATUS_DRAFT        = "DRAFT";
    public static final String STATUS_COUNTING     = "COUNTING";
    public static final String STATUS_SUBMITTED    = "SUBMITTED";
    public static final String STATUS_L1_APPROVED  = "L1_APPROVED";
    public static final String STATUS_APPROVED     = "APPROVED";
    public static final String STATUS_REJECTED     = "REJECTED";
    public static final String STATUS_ADJUSTED     = "ADJUSTED";
    public static final String STATUS_CANCELLED    = "CANCELLED";

    private int id;
    private String stocktakeCode;
    private int warehouseId;
    private String scope;            // FULL | PARTIAL
    private String countMode;        // QUANTITY | SERIAL
    private String status;
    private boolean requiresL2Approval;
    private BigDecimal variancePercent;
    private BigDecimal varianceValue;
    private String notes;
    private String rejectReason;

    private Timestamp createdAt;
    private int createdBy;
    private Integer countedBy;
    private Timestamp countedAt;
    private Timestamp submittedAt;
    private Integer l1ApprovedBy;
    private Timestamp l1ApprovedAt;
    private Integer l2ApprovedBy;
    private Timestamp l2ApprovedAt;
    private Timestamp adjustedAt;

    // Join fields
    private String warehouseName;
    private String createdByFullName;
    private String countedByFullName;
    private String l1ApprovedByFullName;
    private String l2ApprovedByFullName;
    private List<StocktakeDetail> details;
    private List<StocktakeItem> items;

    public Stocktake() {}

    // ===== Helpers =====
    public boolean isDraft()        { return STATUS_DRAFT.equals(status); }
    public boolean isCounting()     { return STATUS_COUNTING.equals(status); }
    public boolean isSubmitted()    { return STATUS_SUBMITTED.equals(status); }
    public boolean isL1Approved()   { return STATUS_L1_APPROVED.equals(status); }
    public boolean isApproved()     { return STATUS_APPROVED.equals(status); }
    public boolean isRejected()     { return STATUS_REJECTED.equals(status); }
    public boolean isAdjusted()     { return STATUS_ADJUSTED.equals(status); }
    public boolean isCancelled()    { return STATUS_CANCELLED.equals(status); }
    public boolean isSerialMode()   { return MODE_SERIAL.equals(countMode); }
    public boolean isQuantityMode() { return MODE_QUANTITY.equals(countMode); }
    public boolean isFullScope()    { return SCOPE_FULL.equals(scope); }

    // ===== Getters/Setters =====
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getStocktakeCode() { return stocktakeCode; }
    public void setStocktakeCode(String v) { this.stocktakeCode = v; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int v) { this.warehouseId = v; }

    public String getScope() { return scope; }
    public void setScope(String v) { this.scope = v; }

    public String getCountMode() { return countMode; }
    public void setCountMode(String v) { this.countMode = v; }

    public String getStatus() { return status; }
    public void setStatus(String v) { this.status = v; }

    public boolean isRequiresL2Approval() { return requiresL2Approval; }
    public void setRequiresL2Approval(boolean v) { this.requiresL2Approval = v; }

    public BigDecimal getVariancePercent() { return variancePercent; }
    public void setVariancePercent(BigDecimal v) { this.variancePercent = v; }

    public BigDecimal getVarianceValue() { return varianceValue; }
    public void setVarianceValue(BigDecimal v) { this.varianceValue = v; }

    public String getNotes() { return notes; }
    public void setNotes(String v) { this.notes = v; }

    public String getRejectReason() { return rejectReason; }
    public void setRejectReason(String v) { this.rejectReason = v; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp v) { this.createdAt = v; }

    public int getCreatedBy() { return createdBy; }
    public void setCreatedBy(int v) { this.createdBy = v; }

    public Integer getCountedBy() { return countedBy; }
    public void setCountedBy(Integer v) { this.countedBy = v; }

    public Timestamp getCountedAt() { return countedAt; }
    public void setCountedAt(Timestamp v) { this.countedAt = v; }

    public Timestamp getSubmittedAt() { return submittedAt; }
    public void setSubmittedAt(Timestamp v) { this.submittedAt = v; }

    public Integer getL1ApprovedBy() { return l1ApprovedBy; }
    public void setL1ApprovedBy(Integer v) { this.l1ApprovedBy = v; }

    public Timestamp getL1ApprovedAt() { return l1ApprovedAt; }
    public void setL1ApprovedAt(Timestamp v) { this.l1ApprovedAt = v; }

    public Integer getL2ApprovedBy() { return l2ApprovedBy; }
    public void setL2ApprovedBy(Integer v) { this.l2ApprovedBy = v; }

    public Timestamp getL2ApprovedAt() { return l2ApprovedAt; }
    public void setL2ApprovedAt(Timestamp v) { this.l2ApprovedAt = v; }

    public Timestamp getAdjustedAt() { return adjustedAt; }
    public void setAdjustedAt(Timestamp v) { this.adjustedAt = v; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String v) { this.warehouseName = v; }

    public String getCreatedByFullName() { return createdByFullName; }
    public void setCreatedByFullName(String v) { this.createdByFullName = v; }

    public String getCountedByFullName() { return countedByFullName; }
    public void setCountedByFullName(String v) { this.countedByFullName = v; }

    public String getL1ApprovedByFullName() { return l1ApprovedByFullName; }
    public void setL1ApprovedByFullName(String v) { this.l1ApprovedByFullName = v; }

    public String getL2ApprovedByFullName() { return l2ApprovedByFullName; }
    public void setL2ApprovedByFullName(String v) { this.l2ApprovedByFullName = v; }

    public List<StocktakeDetail> getDetails() { return details; }
    public void setDetails(List<StocktakeDetail> v) { this.details = v; }

    public List<StocktakeItem> getItems() { return items; }
    public void setItems(List<StocktakeItem> v) { this.items = v; }
}
