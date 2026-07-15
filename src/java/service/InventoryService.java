package service;

import dao.InventoryDAO;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import model.InventoryGroupedRow;
import model.InventoryRow;
import model.ProductItem;

public class InventoryService {

    private final InventoryDAO dao = new InventoryDAO();

    public List<InventoryRow> list(Integer warehouseId, Integer categoryId,
                                   Integer brandId, boolean onlyLowStock,
                                   boolean onlyHasDamaged, String keyword) {
        return dao.list(warehouseId, categoryId, brandId, onlyLowStock, onlyHasDamaged, keyword);
    }

    public InventoryRow getByKey(int warehouseId, int productId) {
        return dao.getByKey(warehouseId, productId);
    }

    public InventoryDAO.InventoryKpi getKpi(Integer warehouseId) {
        return dao.getKpi(warehouseId);
    }

    private static final List<String> IN_STOCK_STATUSES = java.util.Arrays.asList("IN_STOCK", "QUARANTINE");
    private static final List<String> GONE_STATUSES = java.util.Arrays.asList("EXPORTED", "IN_TRANSIT", "LOST");

    /** Serial còn thực sự nằm trong kho (đang dùng được hoặc đang cách ly). */
    public List<ProductItem> getSerials(int warehouseId, int productId) {
        return dao.getSerialsByWarehouseProduct(warehouseId, productId, IN_STOCK_STATUSES);
    }

    /** Serial đã rời khỏi kho này: đã xuất, đang chuyển đi kho khác, hoặc đã mất. */
    public List<ProductItem> getExportedOrLostSerials(int warehouseId, int productId) {
        return dao.getSerialsByWarehouseProduct(warehouseId, productId, GONE_STATUSES);
    }

    public List<InventoryDAO.LedgerEntry> getRecentLedger(int warehouseId, int productId) {
        return dao.getRecentLedger(warehouseId, productId, 30);
    }

    public List<InventoryGroupedRow> listGrouped(Integer categoryId, Integer brandId,
                                                  boolean onlyLowStock, boolean onlyHasDamaged,
                                                  String keyword) {
        List<InventoryRow> flat = dao.list(null, categoryId, brandId, onlyLowStock, onlyHasDamaged, keyword);
        Map<Integer, InventoryGroupedRow> map = new LinkedHashMap<>();

        for (InventoryRow r : flat) {
            InventoryGroupedRow g = map.get(r.getProductId());
            if (g == null) {
                g = new InventoryGroupedRow();
                g.setProductId(r.getProductId());
                g.setProductName(r.getProductName());
                g.setSku(r.getSku());
                g.setUnit(r.getUnit());
                g.setMinStock(r.getMinStock());
                g.setCategoryName(r.getCategoryName());
                g.setBrandName(r.getBrandName());
                g.setAverageCost(r.getAverageCost());
                map.put(r.getProductId(), g);
            }
            g.setTotalNew(g.getTotalNew() + r.getNewQuantity());
            g.setTotalUsed(g.getTotalUsed() + r.getUsedQuantity());
            g.setTotalQuantity(g.getTotalQuantity() + r.getQuantity());
            g.setTotalQuarantine(g.getTotalQuarantine() + r.getQuarantineQuantity());
            g.setTotalInTransit(g.getTotalInTransit() + r.getInTransitQuantity());
            g.setTotalLost(g.getTotalLost() + r.getLostQuantity());
            g.getWarehouses().add(r);
        }

        return new ArrayList<>(map.values());
    }
}
