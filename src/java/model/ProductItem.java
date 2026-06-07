package model;

import java.sql.Timestamp;

public class ProductItem {
    private int id;
    private int productId;
    private String serialNumber;
    private String status;
    private int importTicketId;
    private Integer exportTicketId;
    private Timestamp createdAt;

    // Helper properties for joins (e.g. displaying product names in views)
    private String productName;
    private String sku;
    private String unit;

    public ProductItem() {
    }

    public ProductItem(int id, int productId, String serialNumber, String status, int importTicketId, Integer exportTicketId, Timestamp createdAt) {
        this.id = id;
        this.productId = productId;
        this.serialNumber = serialNumber;
        this.status = status;
        this.importTicketId = importTicketId;
        this.exportTicketId = exportTicketId;
        this.createdAt = createdAt;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public String getSerialNumber() {
        return serialNumber;
    }

    public void setSerialNumber(String serialNumber) {
        this.serialNumber = serialNumber;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public int getImportTicketId() {
        return importTicketId;
    }

    public void setImportTicketId(int importTicketId) {
        this.importTicketId = importTicketId;
    }

    public Integer getExportTicketId() {
        return exportTicketId;
    }

    public void setExportTicketId(Integer exportTicketId) {
        this.exportTicketId = exportTicketId;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
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
}
