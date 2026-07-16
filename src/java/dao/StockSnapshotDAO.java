package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.StockSnapshotRow;
import utils.DBUtils;

/**
 * Tái dựng tồn kho tại một ngày trong quá khứ (hoặc hiện tại) từ bảng Product_Ledger.
 *
 * Bảng Inventories chỉ lưu tồn HIỆN TẠI (bị ghi đè), không có timestamp nên không
 * truy được tồn quá khứ. Product_Ledger ghi mỗi giao dịch 1 dòng kèm balance_quantity
 * (số dư sau giao dịch) + created_at, giống sao kê ngân hàng.
 *
 * Tồn tại ngày X = balance_quantity của dòng ledger CUỐI CÙNG có created_at <= cuối ngày X,
 * cho mỗi cặp (product_id, warehouse_id). Dùng MAX(id) thay vì MAX(created_at) để tránh
 * lỗi khi 2 giao dịch trùng timestamp (id auto-increment nên id lớn hơn = mới hơn).
 */
public class StockSnapshotDAO {

    private final ReportingRollupDAO rollupDAO = new ReportingRollupDAO();

    private static final String TOTAL_EXPR =
        "CASE WHEN pl.balance_new_quantity IS NULL AND pl.balance_used_quantity IS NULL AND pl.balance_damaged_quantity IS NULL "
      + "THEN pl.balance_quantity ELSE COALESCE(pl.balance_new_quantity, 0) + COALESCE(pl.balance_used_quantity, 0) + COALESCE(pl.balance_damaged_quantity, 0) END";

    private static final String BASE_SELECT =
        "SELECT p.sku, p.product_name, p.unit, "
      + "       w.id AS warehouse_id, w.warehouse_name, "
      + "       COALESCE(pl.balance_new_quantity, 0) AS new_quantity, "
      + "       COALESCE(pl.balance_used_quantity, 0) AS used_quantity, "
      + "       COALESCE(pl.balance_damaged_quantity, 0) AS damaged_quantity, "
      + "       " + TOTAL_EXPR + " AS quantity "
      + "FROM Product_Ledger pl "
      + "JOIN ( "
      + "    SELECT product_id, warehouse_id, MAX(id) AS max_id "
      + "    FROM Product_Ledger "
      + "    WHERE created_at <= ? "
      + "    GROUP BY product_id, warehouse_id "
      + ") latest ON latest.max_id = pl.id "
      + "JOIN Products p ON p.id = pl.product_id "
      + "JOIN Warehouses w ON w.id = pl.warehouse_id ";

    /**
     * @param date       ngày cần xem tồn, định dạng "yyyy-MM-dd" (lấy tồn cuối ngày này)
     * @param warehouseId lọc theo kho (null = tất cả kho)
     * @param search     tìm theo SKU hoặc tên sản phẩm (null/rỗng = không lọc)
     * @param includeZero true = hiện cả sản phẩm tồn 0; false = chỉ hiện tồn > 0
     */
    public List<StockSnapshotRow> getSnapshot(String date, Integer warehouseId,
            String search, boolean includeZero) {
        List<StockSnapshotRow> rollupRows = rollupDAO.getSnapshot(date, warehouseId, search, includeZero);
        if (rollupRows != null) {
            return rollupRows;
        }
        List<StockSnapshotRow> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(BASE_SELECT).append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        // Tham số đầu tiên nằm trong subquery latest (created_at <= cuối ngày X)
        List<Object> allParams = new ArrayList<>();
        allParams.add(endOfDay(date));

        appendFilters(sql, params, warehouseId, search, includeZero);
        sql.append("ORDER BY w.warehouse_name, p.sku");

        allParams.addAll(params);

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            for (Object param : allParams) ps.setObject(idx++, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private void appendFilters(StringBuilder sql, List<Object> params,
            Integer warehouseId, String search, boolean includeZero) {
        if (warehouseId != null) {
            sql.append("AND pl.warehouse_id = ? ");
            params.add(warehouseId);
        }
        if (search != null && !search.trim().isEmpty()) {
            sql.append("AND (p.sku LIKE ? OR p.product_name LIKE ?) ");
            String pattern = "%" + search.trim() + "%";
            params.add(pattern);
            params.add(pattern);
        }
        if (!includeZero) {
            sql.append("AND " + TOTAL_EXPR + " > 0 ");
        }
    }

    private StockSnapshotRow mapRow(ResultSet rs) throws Exception {
        StockSnapshotRow r = new StockSnapshotRow();
        r.setSku(rs.getString("sku"));
        r.setProductName(rs.getString("product_name"));
        r.setUnit(rs.getString("unit"));
        r.setWarehouseId(rs.getInt("warehouse_id"));
        r.setWarehouseName(rs.getString("warehouse_name"));
        r.setNewQuantity(rs.getInt("new_quantity"));
        r.setUsedQuantity(rs.getInt("used_quantity"));
        r.setDamagedQuantity(rs.getInt("damaged_quantity"));
        r.setQuantity(rs.getInt("quantity"));
        return r;
    }

    /** Chuyển "yyyy-MM-dd" thành mốc cuối ngày để so sánh <=. Rỗng/null = cuối ngày hôm nay. */
    private String endOfDay(String date) {
        if (date == null || date.trim().isEmpty()) {
            return "9999-12-31 23:59:59"; // không giới hạn -> lấy dòng ledger mới nhất (tồn hiện tại)
        }
        return date.trim() + " 23:59:59";
    }
}
