package service;

import dao.StockSnapshotDAO;
import java.util.List;
import model.StockSnapshotRow;

/**
 * Lớp trung gian mỏng cho báo cáo tồn kho theo ngày.
 */
public class StockSnapshotService {

    private final StockSnapshotDAO dao = new StockSnapshotDAO();

    public List<StockSnapshotRow> getSnapshot(String date, Integer warehouseId,
            String search, boolean includeZero) {
        return dao.getSnapshot(date, warehouseId, search, includeZero);
    }
}
