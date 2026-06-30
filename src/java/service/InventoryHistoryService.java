package service;

import dao.InventoryHistoryDAO;
import java.util.List;
import model.HistoryEntry;

public class InventoryHistoryService {
    private InventoryHistoryDAO dao = new InventoryHistoryDAO();

    public List<HistoryEntry> getHistory(String search, String transactionType,
            Integer warehouseId, String startDate, String endDate,
            int page, int pageSize) {
        return dao.getHistory(search, transactionType, warehouseId, startDate, endDate, page, pageSize);
    }

    public int getCount(String search, String transactionType,
            Integer warehouseId, String startDate, String endDate) {
        return dao.getCount(search, transactionType, warehouseId, startDate, endDate);
    }

    public List<HistoryEntry> getHistoryForExport(String search, String transactionType,
            Integer warehouseId, String startDate, String endDate) {
        return dao.getHistoryForExport(search, transactionType, warehouseId, startDate, endDate);
    }
}
