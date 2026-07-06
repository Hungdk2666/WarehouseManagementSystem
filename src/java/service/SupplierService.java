package service;

import dao.SupplierDAO;
import java.util.List;
import model.*;

public class SupplierService {
    private SupplierDAO dao;

    public SupplierService() {
        this.dao = new SupplierDAO();
    }

    public boolean toggleSupplierStatus(int arg0) {
        return dao.toggleSupplierStatus(arg0);
    }

    public Supplier getSupplierById(int arg0) {
        return dao.getSupplierById(arg0);
    }

    public List<Supplier> getAllSuppliers() {
        return dao.getAllSuppliers();
    }

    public boolean updateSupplier(Supplier arg0) {
        return dao.updateSupplier(arg0);
    }

    public boolean addSupplier(Supplier arg0) {
        return dao.addSupplier(arg0);
    }

    public List<Supplier> getActiveSuppliers() {
        return dao.getActiveSuppliers();
    }

}
