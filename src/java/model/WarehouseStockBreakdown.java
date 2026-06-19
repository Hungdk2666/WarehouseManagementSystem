package model;

public class WarehouseStockBreakdown {
    private int warehouseId;
    private String warehouseName;
    private int physicalQty;
    private int availableQty;
    private int reservedQty;
    private int damagedQty;

    public WarehouseStockBreakdown() {
    }

    public WarehouseStockBreakdown(int warehouseId, String warehouseName, int physicalQty, int availableQty, int reservedQty, int damagedQty) {
        this.warehouseId = warehouseId;
        this.warehouseName = warehouseName;
        this.physicalQty = physicalQty;
        this.availableQty = availableQty;
        this.reservedQty = reservedQty;
        this.damagedQty = damagedQty;
    }

    public int getWarehouseId() {
        return warehouseId;
    }

    public void setWarehouseId(int warehouseId) {
        this.warehouseId = warehouseId;
    }

    public String getWarehouseName() {
        return warehouseName;
    }

    public void setWarehouseName(String warehouseName) {
        this.warehouseName = warehouseName;
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
}
