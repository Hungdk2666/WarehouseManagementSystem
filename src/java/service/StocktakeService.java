package service;

import dao.StocktakeDAO;
import java.math.BigDecimal;
import java.util.List;
import model.Stocktake;
import model.StocktakeConfig;
import model.StocktakeDetail;
import model.StocktakeItem;

public class StocktakeService {

    private final StocktakeDAO dao = new StocktakeDAO();

    public List<Stocktake> getAll(Integer warehouseId, String status) { return dao.getAll(warehouseId, status); }
    public Stocktake getById(int id) { return dao.getById(id); }

    public boolean create(Stocktake s, List<Integer> productIds) { return dao.create(s, productIds); }
    public boolean startCounting(int id, int userId) { return dao.startCounting(id, userId); }
    public boolean saveQuantityCounts(int id, List<StocktakeDetail> details) { return dao.saveQuantityCounts(id, details); }
    public boolean saveSerialCounts(int id, List<StocktakeItem> items) { return dao.saveSerialCounts(id, items); }
    public boolean checkAndSetVerificationRequired(int id) { return dao.checkAndSetVerificationRequired(id); }
    public boolean saveVerificationCounts(int id, List<StocktakeItem> items, int userId) { return dao.saveVerificationCounts(id, items, userId); }
    public List<Integer> getVarianceProductIds(int id) { return dao.getVarianceProductIds(id); }
    public List<Integer> getVerificationProductIds(int id) { return dao.getVerificationProductIds(id); }
    public List<Integer> getDamagedOnlyProductIds(int id) { return dao.getDamagedOnlyProductIds(id); }
    public boolean submit(int id) { return dao.submit(id); }
    public boolean approveL1(int id, int approverId) { return dao.approveL1(id, approverId); }
    public boolean approveL2(int id, int approverId) { return dao.approveL2(id, approverId); }
    public boolean reject(int id, int approverId, String reason) { return dao.reject(id, approverId, reason); }
    public boolean cancel(int id, int userId) { return dao.cancel(id, userId); }

    public Stocktake getActiveStocktakeForWarehouse(int warehouseId) {
        return dao.getActiveStocktakeForWarehouse(warehouseId);
    }
    public boolean isWarehouseFrozen(int warehouseId) {
        return dao.isWarehouseFrozen(warehouseId);
    }

    public StocktakeConfig getConfig() { return dao.getConfig(); }
    public boolean updateConfig(BigDecimal percent, BigDecimal value, int userId) { return dao.updateConfig(percent, value, userId); }
}
