package service;

import dao.WarehouseDAO;
import java.util.List;
import model.*;

public class WarehouseService {
    private WarehouseDAO dao;

    public WarehouseService() {
        this.dao = new WarehouseDAO();
    }

    public List<Warehouse> getAllActiveWarehouses() {
        return dao.getAllActiveWarehouses();
    }

    public int countPendingExportTickets(int arg0) {
        return dao.countPendingExportTickets(arg0);
    }

    public int countProductsInStock(int arg0) {
        return dao.countProductsInStock(arg0);
    }

    public int countPendingImportTickets(int arg0) {
        return dao.countPendingImportTickets(arg0);
    }

    public int countIncomingTransfers(int arg0) {
        return dao.countIncomingTransfers(arg0);
    }

    public Warehouse getById(int arg0) {
        return dao.getById(arg0);
    }

    public List<Warehouse> getAllWarehouses() {
        return dao.getAllWarehouses();
    }

    public boolean toggleStatus(int arg0) {
        return dao.toggleStatus(arg0);
    }

    public int getTotalStockQty(int arg0) {
        return dao.getTotalStockQty(arg0);
    }

    public int countStaff(int arg0) {
        return dao.countStaff(arg0);
    }

    public boolean add(Warehouse arg0) {
        return dao.add(arg0);
    }

    public boolean update(Warehouse arg0) {
        return dao.update(arg0);
    }

}
