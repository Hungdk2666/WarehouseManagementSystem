package service;

import dao.ProductItemDAO;
import java.util.List;
import java.sql.Connection;
import model.*;

public class ProductItemService {
    private ProductItemDAO dao;

    public ProductItemService() {
        this.dao = new ProductItemDAO();
    }

    public List<String> addProductItemsAndReturnSerials(int arg0, int arg1, int arg2, String arg3, int arg4, String arg5, Connection arg6) throws Exception {
        return dao.addProductItemsAndReturnSerials(arg0, arg1, arg2, arg3, arg4, arg5, arg6);
    }

    public List<String> addProductItemsAndReturnSerials(int arg0, int arg1, int arg2, String arg3, int arg4, Connection arg5) throws Exception {
        return dao.addProductItemsAndReturnSerials(arg0, arg1, arg2, arg3, arg4, arg5);
    }

    public boolean checkSerialAvailable(String arg0, int arg1) {
        return dao.checkSerialAvailable(arg0, arg1);
    }

    public boolean checkSerialAvailable(String arg0, int arg1, Integer arg2) {
        return dao.checkSerialAvailable(arg0, arg1, arg2);
    }

    public List<ProductItem> getExportedItemsByProductId(int arg0) {
        return dao.getExportedItemsByProductId(arg0);
    }

    public List<ProductItem> getItemsByImportTicketId(int arg0) {
        return dao.getItemsByImportTicketId(arg0);
    }

    public List<ProductItem> getExportedItemsByExportTicketId(int arg0) {
        return dao.getExportedItemsByExportTicketId(arg0);
    }

    public List<ProductItem> getItemsByExportTicketId(int arg0) {
        return dao.getItemsByExportTicketId(arg0);
    }

    public List<ProductItem> getInStockItemsByProductId(int arg0, String arg1) {
        return dao.getInStockItemsByProductId(arg0, arg1);
    }

    public List<ProductItem> getInStockItemsByProductId(int arg0, Integer arg1) {
        return dao.getInStockItemsByProductId(arg0, arg1);
    }

    public List<ProductItem> getInStockItemsByProductId(int arg0, Integer arg1, String arg2) {
        return dao.getInStockItemsByProductId(arg0, arg1, arg2);
    }

    public List<ProductItem> getItemsByTicketId(int arg0) {
        return dao.getItemsByTicketId(arg0);
    }

    public boolean addProductItems(int arg0, int arg1, int arg2, String arg3, int arg4, Connection arg5) throws Exception {
        return dao.addProductItems(arg0, arg1, arg2, arg3, arg4, arg5);
    }

    public boolean addProductItems(int arg0, int arg1, int arg2, String arg3, Connection arg4) throws Exception {
        return dao.addProductItems(arg0, arg1, arg2, arg3, arg4);
    }

}
