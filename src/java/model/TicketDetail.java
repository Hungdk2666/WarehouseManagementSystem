package model;

import java.math.BigDecimal;

public class TicketDetail {
    private int ticketId;
    private int productId;
    private int quantity;
    private BigDecimal unitCost;         // IN: giá nhập | OUT: giá vốn xuất

    // Join fields
    private String productName;
    private String sku;
    private String unit;

    public TicketDetail() {}

    public int getTicketId() { return ticketId; }
    public void setTicketId(int ticketId) { this.ticketId = ticketId; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public BigDecimal getUnitCost() { return unitCost; }
    public void setUnitCost(BigDecimal unitCost) { this.unitCost = unitCost; }


    public String getProductName() { return productName; }
    public void setProductName(String v) { this.productName = v; }

    public String getSku() { return sku; }
    public void setSku(String v) { this.sku = v; }

    public String getUnit() { return unit; }
    public void setUnit(String v) { this.unit = v; }
}
