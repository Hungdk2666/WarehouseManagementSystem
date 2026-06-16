package model;

public class ExportTicketDetail {
    private int ticketId;
    private int productId;
    private int quantity;
    private double unitCost;

    // Join fields
    private String productName;
    private String sku;
    private String unit;

    // Helper validation fields
    private int currentInventoryQty;
    private int requestedQtyRemaining;

    public ExportTicketDetail() {
    }

    public int getTicketId() {
        return ticketId;
    }

    public void setTicketId(int ticketId) {
        this.ticketId = ticketId;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public double getUnitCost() {
        return unitCost;
    }

    public void setUnitCost(double unitCost) {
        this.unitCost = unitCost;
    }

    public String getProductName() {
        return productName;
    }

    public void setProductName(String productName) {
        this.productName = productName;
    }

    public String getSku() {
        return sku;
    }

    public void setSku(String sku) {
        this.sku = sku;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public int getCurrentInventoryQty() {
        return currentInventoryQty;
    }

    public void setCurrentInventoryQty(int currentInventoryQty) {
        this.currentInventoryQty = currentInventoryQty;
    }

    public int getRequestedQtyRemaining() {
        return requestedQtyRemaining;
    }

    public void setRequestedQtyRemaining(int requestedQtyRemaining) {
        this.requestedQtyRemaining = requestedQtyRemaining;
    }
}
