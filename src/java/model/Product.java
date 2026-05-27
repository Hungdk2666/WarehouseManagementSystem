package model;

public class Product {

    private int id;
    private String productName;
    private String sku;
    private String unit;
    private int minStock;
    private double defaultCost;
    private double averageCost;
    private boolean status;
    private Integer categoryId;
    private Integer brandId;
    private String technicalSpecifications;

    // Join fields
    private String categoryName;
    private String brandName;
    private int quantity; // physical inventory level

    public Product() {
    }

    public Product(int id, String productName, String sku, String unit, int minStock, double defaultCost, double averageCost, boolean status, Integer categoryId, Integer brandId, String technicalSpecifications) {
        this.id = id;
        this.productName = productName;
        this.sku = sku;
        this.unit = unit;
        this.minStock = minStock;
        this.defaultCost = defaultCost;
        this.averageCost = averageCost;
        this.status = status;
        this.categoryId = categoryId;
        this.brandId = brandId;
        this.technicalSpecifications = technicalSpecifications;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
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

    public int getMinStock() {
        return minStock;
    }

    public void setMinStock(int minStock) {
        this.minStock = minStock;
    }

    public double getDefaultCost() {
        return defaultCost;
    }

    public void setDefaultCost(double defaultCost) {
        this.defaultCost = defaultCost;
    }

    public double getAverageCost() {
        return averageCost;
    }

    public void setAverageCost(double averageCost) {
        this.averageCost = averageCost;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
    }

    public Integer getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Integer categoryId) {
        this.categoryId = categoryId;
    }

    public Integer getBrandId() {
        return brandId;
    }

    public void setBrandId(Integer brandId) {
        this.brandId = brandId;
    }

    public String getTechnicalSpecifications() {
        return technicalSpecifications;
    }

    public void setTechnicalSpecifications(String technicalSpecifications) {
        this.technicalSpecifications = technicalSpecifications;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public String getBrandName() {
        return brandName;
    }

    public void setBrandName(String brandName) {
        this.brandName = brandName;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }
}
