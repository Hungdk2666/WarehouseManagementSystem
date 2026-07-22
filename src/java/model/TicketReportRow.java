package model;

import java.math.BigDecimal;

/** A single product line in an operational import or export ticket report. */
public class TicketReportRow {
    private String transactionDate;
    private String ticketCode;
    private String reason;
    private String sku;
    private String productName;
    private String unit;
    private int quantity;
    private BigDecimal unitCost;
    private BigDecimal totalCost;
    private String warehouseName;
    private String partnerName;

    public String getTransactionDate() { return transactionDate; }
    public void setTransactionDate(String transactionDate) { this.transactionDate = transactionDate; }
    public String getTicketCode() { return ticketCode; }
    public void setTicketCode(String ticketCode) { this.ticketCode = ticketCode; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public BigDecimal getUnitCost() { return unitCost; }
    public void setUnitCost(BigDecimal unitCost) { this.unitCost = unitCost; }
    public BigDecimal getTotalCost() { return totalCost; }
    public void setTotalCost(BigDecimal totalCost) { this.totalCost = totalCost; }
    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String warehouseName) { this.warehouseName = warehouseName; }
    public String getPartnerName() { return partnerName; }
    public void setPartnerName(String partnerName) { this.partnerName = partnerName; }

    public boolean hasCost() { return unitCost != null && totalCost != null; }

    public String getReasonLabel() {
        if ("PURCHASE".equals(reason)) return "Nhập mua";
        if ("RETURN".equals(reason)) return "Nhập trả";
        if ("TRANSFER".equals(reason)) return "Nhập chuyển kho";
        if ("DISPLAY".equals(reason)) return "Xuất trưng bày";
        if ("WARRANTY".equals(reason)) return "Xuất bảo hành";
        if ("CUSTOMER_SALE".equals(reason)) return "Xuất theo yêu cầu";
        return reason == null ? "" : reason;
    }
}
