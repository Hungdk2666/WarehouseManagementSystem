package model;

public class ProductSpecification {

    private int id;
    private int productId;
    private String specKey;
    private String specValue;

    public ProductSpecification() {
    }

    public ProductSpecification(int id, int productId, String specKey, String specValue) {
        this.id = id;
        this.productId = productId;
        this.specKey = specKey;
        this.specValue = specValue;
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

    public String getSpecKey() {
        return specKey;
    }

    public void setSpecKey(String specKey) {
        this.specKey = specKey;
    }

    public String getSpecValue() {
        return specValue;
    }

    public void setSpecValue(String specValue) {
        this.specValue = specValue;
    }
}
