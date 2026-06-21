package service;

import dao.ProductDAO;
import java.util.List;
import model.*;

public class ProductService {
    private ProductDAO dao;

    public ProductService() {
        this.dao = new ProductDAO();
    }

    public List<Product> searchAndFilterProducts(String arg0, Integer arg1, Integer arg2, boolean arg3) {
        return dao.searchAndFilterProducts(arg0, arg1, arg2, arg3);
    }

    public List<Product> searchAndFilterProducts(String arg0, Integer arg1, Integer arg2, boolean arg3, Integer arg4) {
        return dao.searchAndFilterProducts(arg0, arg1, arg2, arg3, arg4);
    }

    public List<ProductSpecification> getSpecificationsByProductId(int arg0) {
        return dao.getSpecificationsByProductId(arg0);
    }

    public boolean toggleProductStatus(int arg0) {
        return dao.toggleProductStatus(arg0);
    }

    public List<WarehouseStockBreakdown> getWarehouseStockBreakdown(int arg0) {
        return dao.getWarehouseStockBreakdown(arg0);
    }

    public List<Product> getAllProducts() {
        return dao.getAllProducts();
    }

    public List<Product> getAllProducts(Integer arg0) {
        return dao.getAllProducts(arg0);
    }

    public Product getProductById(int arg0, Integer arg1) {
        return dao.getProductById(arg0, arg1);
    }

    public Product getProductById(int arg0) {
        return dao.getProductById(arg0);
    }

    public boolean updateProduct(Product arg0) {
        return dao.updateProduct(arg0);
    }

    public int getAvailableQty(int arg0, int arg1) {
        return dao.getAvailableQty(arg0, arg1);
    }

    public boolean addProduct(Product arg0) {
        return dao.addProduct(arg0);
    }

    public boolean isSkuExists(String arg0, int arg1) {
        return dao.isSkuExists(arg0, arg1);
    }

}
