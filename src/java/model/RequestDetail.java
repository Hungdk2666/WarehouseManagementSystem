package model;

import java.math.BigDecimal;

public class RequestDetail {
    private int requestId;
    private int productId;
    private int quantity;
    private BigDecimal unitPrice;        // chỉ bắt buộc cho IN-PURCHASE

    // Join fields
    private String productName;
    private String sku;
    private String unit;
    private int processedQuantity;       // tổng số đã xử lý qua Tickets (CONFIRMED/IN_TRANSIT/COMPLETED)

    public RequestDetail() {}

    public int getRequestId() { return requestId; }
    public void setRequestId(int requestId) { this.requestId = requestId; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }


    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }

    public String getSku() { return sku; }
    public void setSku(String sku) { this.sku = sku; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public int getProcessedQuantity() { return processedQuantity; }
    public void setProcessedQuantity(int processedQuantity) { this.processedQuantity = processedQuantity; }
}
