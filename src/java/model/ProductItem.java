package model;

import java.sql.Timestamp;

public class ProductItem {
    private int id;
    private int productId;
    private String serialNumber;
    private String manufacturerSerial;
    private String status;
    private Timestamp createdAt;
    private String itemCondition; // NEW, USED, DAMAGED
    private int warehouseId;

    // Helper properties for joins (e.g. displaying product names in views)
    private String productName;
    private String sku;
    private String unit;

    public ProductItem() {
    }

    public ProductItem(int id, int productId, String serialNumber, String status, Timestamp createdAt, String itemCondition) {
        this.id = id;
        this.productId = productId;
        this.serialNumber = serialNumber;
        this.status = status;
        this.createdAt = createdAt;
        this.itemCondition = itemCondition;
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

    public String getItemCondition() {
        return itemCondition;
    }

    public void setItemCondition(String itemCondition) {
        this.itemCondition = itemCondition;
    }

    public int getWarehouseId() {
        return warehouseId;
    }

    public void setWarehouseId(int warehouseId) {
        this.warehouseId = warehouseId;
    }

    private String warehouseName;
    private double unitCost;

    public String getWarehouseName() {
        return warehouseName;
    }

    public void setWarehouseName(String warehouseName) {
        this.warehouseName = warehouseName;
    }

    public double getUnitCost() {
        return unitCost;
    }

    public void setUnitCost(double unitCost) {
        this.unitCost = unitCost;
    }

    public String getManufacturerSerial() {
        return manufacturerSerial;
    }

    public void setManufacturerSerial(String manufacturerSerial) {
        this.manufacturerSerial = manufacturerSerial;
    }
}
