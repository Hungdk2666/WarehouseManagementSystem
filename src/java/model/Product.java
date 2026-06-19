package model;

public class Product {

    private int id;
    private String productName;
    private String sku;
    private String unit;
    private int minStock;
    private double averageCost;
    private boolean status;
    private Integer categoryId;
    private Integer brandId;
    private java.util.List<ProductSpecification> specifications;

    // Join fields
    private String categoryName;
    private String brandName;
    private int quantity; // physical inventory level
    private int physicalQty;
    private int availableQty;
    private int availableNewQty;
    private int availableUsedQty;
    private int reservedQty;
    private int reservedNewQty;
    private int reservedUsedQty;
    private int damagedQty;

    public Product() {
    }

    public Product(int id, String productName, String sku, String unit, int minStock, double averageCost, boolean status, Integer categoryId, Integer brandId) {
        this.id = id;
        this.productName = productName;
        this.sku = sku;
        this.unit = unit;
        this.minStock = minStock;
        this.averageCost = averageCost;
        this.status = status;
        this.categoryId = categoryId;
        this.brandId = brandId;
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

    public java.util.List<ProductSpecification> getSpecifications() {
        return specifications;
    }

    public void setSpecifications(java.util.List<ProductSpecification> specifications) {
        this.specifications = specifications;
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

    public int getPhysicalQty() {
        return physicalQty;
    }

    public void setPhysicalQty(int physicalQty) {
        this.physicalQty = physicalQty;
    }

    public int getAvailableQty() {
        return availableQty;
    }

    public void setAvailableQty(int availableQty) {
        this.availableQty = availableQty;
    }

    public int getReservedQty() {
        return reservedQty;
    }

    public void setReservedQty(int reservedQty) {
        this.reservedQty = reservedQty;
    }

    public int getDamagedQty() {
        return damagedQty;
    }

    public void setDamagedQty(int damagedQty) {
        this.damagedQty = damagedQty;
    }

    public int getAvailableNewQty() {
        return availableNewQty;
    }

    public void setAvailableNewQty(int availableNewQty) {
        this.availableNewQty = availableNewQty;
    }

    public int getAvailableUsedQty() {
        return availableUsedQty;
    }

    public void setAvailableUsedQty(int availableUsedQty) {
        this.availableUsedQty = availableUsedQty;
    }

    public int getReservedNewQty() {
        return reservedNewQty;
    }

    public void setReservedNewQty(int reservedNewQty) {
        this.reservedNewQty = reservedNewQty;
    }

    public int getReservedUsedQty() {
        return reservedUsedQty;
    }

    public void setReservedUsedQty(int reservedUsedQty) {
        this.reservedUsedQty = reservedUsedQty;
    }
}
