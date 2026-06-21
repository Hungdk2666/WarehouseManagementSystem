package service;

import dao.BrandDAO;
import java.util.List;
import model.*;

public class BrandService {
    private BrandDAO dao;

    public BrandService() {
        this.dao = new BrandDAO();
    }

    public boolean updateBrand(Brand arg0) {
        return dao.updateBrand(arg0);
    }

    public List<Brand> getAllBrands() {
        return dao.getAllBrands();
    }

    public Brand getBrandById(int arg0) {
        return dao.getBrandById(arg0);
    }

    public boolean addBrand(Brand arg0) {
        return dao.addBrand(arg0);
    }

    public boolean toggleBrandStatus(int arg0) {
        return dao.toggleBrandStatus(arg0);
    }

}
