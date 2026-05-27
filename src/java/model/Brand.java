package model;

public class Brand {

    private int id;
    private String brandName;
    private String description;
    private boolean status;

    public Brand() {
    }

    public Brand(int id, String brandName, String description, boolean status) {
        this.id = id;
        this.brandName = brandName;
        this.description = description;
        this.status = status;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getBrandName() {
        return brandName;
    }

    public void setBrandName(String brandName) {
        this.brandName = brandName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
    }
}
