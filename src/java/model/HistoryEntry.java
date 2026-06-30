package model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class HistoryEntry {
    private int id;
    private String transactionType;
    private int changeQuantity;
    private int balanceQuantity;
    private Timestamp createdAt;

    private int referenceId;
    private String ticketCode;
    private String ticketType;
    private String requestCode;
    private String requestReason;

    private int productId;
    private String productName;
    private String sku;

    private int warehouseId;
    private String warehouseName;

    private String partnerName;
    private String createdByName;
    private String approvedByName;

    private BigDecimal unitCost;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTransactionType() { return transactionType; }
    public void setTransactionType(String transactionType) { this.transactionType = transactionType; }

    public int getChangeQuantity() { return changeQuantity; }
    public void setChangeQuantity(int changeQuantity) { this.changeQuantity = changeQuantity; }

    public int getBalanceQuantity() { return balanceQuantity; }
    public void setBalanceQuantity(int balanceQuantity) { this.balanceQuantity = balanceQuantity; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public int getReferenceId() { return referenceId; }
    public void setReferenceId(int referenceId) { this.referenceId = referenceId; }

    public String getTicketCode() { return ticketCode; }
    public void setTicketCode(String ticketCode) { this.ticketCode = ticketCode; }

    public String getTicketType() { return ticketType; }
    public void setTicketType(String ticketType) { this.ticketType = ticketType; }

    public String getRequestCode() { return requestCode; }
    public void setRequestCode(String requestCode) { this.requestCode = requestCode; }

    public String getRequestReason() { return requestReason; }
    public void setRequestReason(String requestReason) { this.requestReason = requestReason; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }

    public int getWarehouseId() { return warehouseId; }
    public void setWarehouseId(int warehouseId) { this.warehouseId = warehouseId; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String warehouseName) { this.warehouseName = warehouseName; }

    public String getPartnerName() { return partnerName; }
    public void setPartnerName(String partnerName) { this.partnerName = partnerName; }

    public String getCreatedByName() { return createdByName; }
    public void setCreatedByName(String createdByName) { this.createdByName = createdByName; }

    public String getApprovedByName() { return approvedByName; }
    public void setApprovedByName(String approvedByName) { this.approvedByName = approvedByName; }

    public BigDecimal getUnitCost() { return unitCost; }
    public void setUnitCost(BigDecimal unitCost) { this.unitCost = unitCost; }

    public String getTransactionTypeLabel() {
        if (transactionType == null) return "";
        switch (transactionType) {
            case "IMPORT":       return "Nhập mua";
            case "EXPORT":       return "Xuất bán";
            case "TRANSFER_IN":  return "Nhận chuyển kho";
            case "TRANSFER_OUT": return "Chuyển kho đi";
            case "RETURN":       return "Trả hàng";
            case "STOCKTAKE":    return "Kiểm kê điều chỉnh";
            default:             return transactionType;
        }
    }

    public String getTransactionTypeBadgeClass() {
        if (transactionType == null) return "bg-secondary text-white";
        switch (transactionType) {
            case "IMPORT":       return "bg-success text-white";
            case "EXPORT":       return "bg-danger text-white";
            case "TRANSFER_IN":  return "bg-info text-white";
            case "TRANSFER_OUT": return "bg-primary text-white";
            case "RETURN":       return "bg-warning text-dark";
            case "STOCKTAKE":    return "bg-secondary text-white";
            default:             return "bg-secondary text-white";
        }
    }
}
