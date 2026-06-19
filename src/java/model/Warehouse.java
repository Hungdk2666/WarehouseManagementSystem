package model;

import java.sql.Timestamp;

public class Warehouse {
    private int id;
    private String warehouseName;
    private String address;
    private boolean status;
    private Timestamp createdAt;

    public Warehouse() {}

    public Warehouse(int id, String warehouseName, String address, boolean status, Timestamp createdAt) {
        this.id = id;
        this.warehouseName = warehouseName;
        this.address = address;
        this.status = status;
        this.createdAt = createdAt;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getWarehouseName() { return warehouseName; }
    public void setWarehouseName(String warehouseName) { this.warehouseName = warehouseName; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public boolean isStatus() { return status; }
    public void setStatus(boolean status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
