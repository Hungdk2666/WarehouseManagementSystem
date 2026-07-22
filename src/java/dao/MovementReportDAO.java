package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import model.DailyMovementRow;
import model.PeriodSummaryRow;
import utils.DBUtils;

/**
 *  - getDailyMovement: "Báo cáo chi tiết xuất - nhập vật tư theo ngày" (1 dòng = 1 SP/1 kho/1 ngày phát sinh).
 *  - getPeriodSummary: "Báo cáo tổng hợp Nhập - Xuất - Tồn" (1 dòng = 1 SP/1 kho/1 tình trạng, đầu kỳ - phát sinh - cuối kỳ).
 *
 * Đầu kỳ/Cuối kỳ tái dựng từ Product_Ledger theo đúng cách StockSnapshotDAO đang làm
 * (dòng ledger cuối cùng có created_at trước mốc cắt, cho mỗi cặp product/warehouse).
 * Phát sinh trong kỳ = tổng change_quantity (tách theo dấu) của các dòng ledger nằm trong khoảng ngày,
 * bỏ qua OPENING_BALANCE (mốc khởi tạo, không phải giao dịch thật).
 */
public class MovementReportDAO {

    private final ReportingRollupDAO rollupDAO = new ReportingRollupDAO();

    private static final String LATEST_BALANCE_SELECT =
        "SELECT p.id AS product_id, p.sku, p.product_name, p.unit, "
      + "       w.id AS warehouse_id, w.warehouse_name, "
      + "       COALESCE(pl.balance_new_quantity, 0) AS new_qty, "
      + "       COALESCE(pl.balance_used_quantity, 0) AS used_qty, "
      + "       COALESCE(pl.balance_damaged_quantity, 0) AS damaged_qty "
      + "FROM Product_Ledger pl "
      + "JOIN ( "
      + "    SELECT product_id, warehouse_id, MAX(id) AS max_id "
      + "    FROM Product_Ledger "
      + "    WHERE created_at %s ? "
      + "    GROUP BY product_id, warehouse_id "
      + ") latest ON latest.max_id = pl.id "
      + "JOIN Products p ON p.id = pl.product_id "
      + "JOIN Warehouses w ON w.id = pl.warehouse_id "
      + "WHERE 1=1 ";

    private static final String MOVEMENT_SELECT =
        "SELECT p.id AS product_id, p.sku, p.product_name, p.unit, "
      + "       w.id AS warehouse_id, w.warehouse_name, "
      + "       SUM(CASE WHEN pl.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') "
      + "                THEN GREATEST(COALESCE(pl.change_new_quantity,0),0) ELSE 0 END) AS import_new, "
      + "       SUM(CASE WHEN pl.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') "
      + "                THEN GREATEST(-COALESCE(pl.change_new_quantity,0),0) ELSE 0 END) AS export_new, "
      + "       SUM(CASE WHEN pl.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') "
      + "                THEN GREATEST(COALESCE(pl.change_used_quantity,0),0) ELSE 0 END) AS import_used, "
      + "       SUM(CASE WHEN pl.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') "
      + "                THEN GREATEST(-COALESCE(pl.change_used_quantity,0),0) ELSE 0 END) AS export_used, "
      + "       SUM(CASE WHEN pl.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') "
      + "                THEN GREATEST(COALESCE(pl.change_damaged_quantity,0),0) ELSE 0 END) AS import_damaged, "
      + "       SUM(CASE WHEN pl.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') "
      + "                THEN GREATEST(-COALESCE(pl.change_damaged_quantity,0),0) ELSE 0 END) AS export_damaged, "
      + "       SUM(CASE WHEN pl.transaction_type = 'STOCKTAKE' THEN COALESCE(pl.change_new_quantity,0) ELSE 0 END) AS adjustment_new, "
      + "       SUM(CASE WHEN pl.transaction_type = 'STOCKTAKE' THEN COALESCE(pl.change_used_quantity,0) ELSE 0 END) AS adjustment_used, "
      + "       SUM(CASE WHEN pl.transaction_type = 'STOCKTAKE' THEN COALESCE(pl.change_damaged_quantity,0) ELSE 0 END) AS adjustment_damaged "
      + "FROM Product_Ledger pl "
      + "JOIN Products p ON p.id = pl.product_id "
      + "JOIN Warehouses w ON w.id = pl.warehouse_id "
      + "WHERE pl.transaction_type <> 'OPENING_BALANCE' AND pl.created_at BETWEEN ? AND ? ";

    /**
     * @param fromDate, toDate "yyyy-MM-dd" (bắt buộc phải có giá trị hợp lệ, không thì trả rỗng)
     */
    public List<DailyMovementRow> getDailyMovement(String fromDate, String toDate,
            Integer warehouseId, String search) {
        List<DailyMovementRow> rollupRows = rollupDAO.getDailyMovement(fromDate, toDate, warehouseId, search);
        if (rollupRows != null) {
            return rollupRows;
        }
        List<DailyMovementRow> list = new ArrayList<>();
        if (isBlank(fromDate) || isBlank(toDate)) return list;

        StringBuilder sql = new StringBuilder(
            "SELECT p.sku, p.product_name, p.unit, w.id AS warehouse_id, w.warehouse_name, "
          + "       DATE(pl.created_at) AS tx_date, "
          + "       SUM(CASE WHEN pl.transaction_type IN ('IMPORT','RETURN','TRANSFER_IN','TRANSFER_RETURN') "
          + "                THEN GREATEST(pl.change_quantity,0) ELSE 0 END) AS import_qty, "
          + "       SUM(CASE WHEN pl.transaction_type IN ('EXPORT','TRANSFER_OUT','TRANSFER_RETURN_OUT') "
          + "                THEN GREATEST(-pl.change_quantity,0) ELSE 0 END) AS export_qty, "
          + "       SUM(CASE WHEN pl.transaction_type = 'STOCKTAKE' THEN pl.change_quantity ELSE 0 END) AS adjustment_qty, "
          + "       MAX(CASE WHEN pl.transaction_type = 'STOCKTAKE' THEN 1 ELSE 0 END) AS has_adjustment "
          + "FROM Product_Ledger pl "
          + "JOIN Products p ON p.id = pl.product_id "
          + "JOIN Warehouses w ON w.id = pl.warehouse_id "
          + "WHERE pl.transaction_type <> 'OPENING_BALANCE' AND pl.created_at BETWEEN ? AND ? ");
        List<Object> params = new ArrayList<>();
        params.add(fromDate.trim() + " 00:00:00");
        params.add(toDate.trim() + " 23:59:59");

        appendWarehouseAndSearch(sql, params, warehouseId, search);
        sql.append("GROUP BY p.id, w.id, DATE(pl.created_at) ORDER BY tx_date, w.warehouse_name, p.sku");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            for (Object param : params) ps.setObject(idx++, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DailyMovementRow r = new DailyMovementRow();
                    r.setSku(rs.getString("sku"));
                    r.setProductName(rs.getString("product_name"));
                    r.setUnit(rs.getString("unit"));
                    r.setWarehouseId(rs.getInt("warehouse_id"));
                    r.setWarehouseName(rs.getString("warehouse_name"));
                    r.setDate(rs.getDate("tx_date").toString());
                    r.setImportQuantity(rs.getInt("import_qty"));
                    r.setExportQuantity(rs.getInt("export_qty"));
                    r.setAdjustmentQuantity(rs.getInt("adjustment_qty"));
                    r.setNote(rs.getInt("has_adjustment") == 1 ? "Có điều chỉnh kiểm kê" : "");
                    list.add(r);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * @param fromDate, toDate "yyyy-MM-dd"
     * @param includeZero true = hiện cả dòng không phát sinh gì (đầu kỳ=cuối kỳ=0, không nhập không xuất)
     */
    public List<PeriodSummaryRow> getPeriodSummary(String fromDate, String toDate,
            Integer warehouseId, String search, boolean includeZero) {
        List<PeriodSummaryRow> rollupRows = rollupDAO.getPeriodSummary(fromDate, toDate, warehouseId, search, includeZero);
        if (rollupRows != null) {
            return rollupRows;
        }
        List<PeriodSummaryRow> result = new ArrayList<>();
        if (isBlank(fromDate) || isBlank(toDate)) return result;

        String openingCutoff = fromDate.trim() + " 00:00:00";
        String closingCutoff = toDate.trim() + " 23:59:59";

        // Map cục bộ theo lời gọi (không dùng field instance) để tránh lẫn dữ liệu
        // giữa các request chạy đồng thời nếu DAO bị dùng chung 1 instance.
        Map<String, ProductWarehouseInfo> infoByKey = new LinkedHashMap<>();

        Map<String, int[]> opening = loadBalances(openingCutoff, "<", warehouseId, search, infoByKey);
        Map<String, int[]> closing = loadBalances(closingCutoff, "<=", warehouseId, search, infoByKey);
        Map<String, int[]> movement = loadMovement(openingCutoff, closingCutoff, warehouseId, search, infoByKey);

        List<String> orderedKeys = new ArrayList<>(infoByKey.keySet());

        for (String key : orderedKeys) {
            ProductWarehouseInfo info = infoByKey.get(key);
            int[] open = opening.getOrDefault(key, new int[]{0, 0, 0});
            int[] close = closing.getOrDefault(key, new int[]{0, 0, 0});
            int[] mv = movement.getOrDefault(key, new int[]{0, 0, 0, 0, 0, 0, 0, 0, 0});

            String[] conditions = {"NEW", "USED", "DAMAGED"};
            for (int i = 0; i < conditions.length; i++) {
                int openQty = open[i];
                int closeQty = close[i];
                int impQty = mv[i * 2];
                int expQty = mv[i * 2 + 1];
                int adjustmentQty = mv[6 + i];
                if (!includeZero && openQty == 0 && closeQty == 0 && impQty == 0
                        && expQty == 0 && adjustmentQty == 0) continue;

                PeriodSummaryRow row = new PeriodSummaryRow();
                row.setSku(info.sku);
                row.setProductName(info.productName);
                row.setUnit(info.unit);
                row.setWarehouseId(info.warehouseId);
                row.setWarehouseName(info.warehouseName);
                row.setCondition(conditions[i]);
                row.setOpeningQuantity(openQty);
                row.setImportQuantity(impQty);
                row.setExportQuantity(expQty);
                row.setAdjustmentQuantity(adjustmentQty);
                row.setClosingQuantity(closeQty);
                row.setNote("");
                result.add(row);
            }
        }
        result.sort((a, b) -> {
            int c = a.getWarehouseName().compareTo(b.getWarehouseName());
            if (c != 0) return c;
            c = a.getSku().compareTo(b.getSku());
            if (c != 0) return c;
            return a.getCondition().compareTo(b.getCondition());
        });
        return result;
    }

    private Map<String, int[]> loadBalances(String cutoff, String operator,
            Integer warehouseId, String search, Map<String, ProductWarehouseInfo> infoOut) {
        Map<String, int[]> map = new LinkedHashMap<>();
        String sql = String.format(LATEST_BALANCE_SELECT, operator);
        StringBuilder sb = new StringBuilder(sql);
        List<Object> params = new ArrayList<>();
        params.add(cutoff);
        appendWarehouseAndSearch(sb, params, warehouseId, search);
        sb.append("ORDER BY w.warehouse_name, p.sku");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            int idx = 1;
            for (Object param : params) ps.setObject(idx++, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String key = rs.getInt("product_id") + "_" + rs.getInt("warehouse_id");
                    map.put(key, new int[]{ rs.getInt("new_qty"), rs.getInt("used_qty"), rs.getInt("damaged_qty") });
                    rememberInfo(key, rs, infoOut);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }

    private Map<String, int[]> loadMovement(String fromCutoff, String toCutoff,
            Integer warehouseId, String search, Map<String, ProductWarehouseInfo> infoOut) {
        Map<String, int[]> map = new LinkedHashMap<>();
        StringBuilder sb = new StringBuilder(MOVEMENT_SELECT);
        List<Object> params = new ArrayList<>();
        params.add(fromCutoff);
        params.add(toCutoff);
        appendWarehouseAndSearch(sb, params, warehouseId, search);
        sb.append("GROUP BY p.id, w.id ORDER BY w.warehouse_name, p.sku");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            int idx = 1;
            for (Object param : params) ps.setObject(idx++, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String key = rs.getInt("product_id") + "_" + rs.getInt("warehouse_id");
                    map.put(key, new int[]{
                        rs.getInt("import_new"), rs.getInt("export_new"),
                        rs.getInt("import_used"), rs.getInt("export_used"),
                        rs.getInt("import_damaged"), rs.getInt("export_damaged"),
                        rs.getInt("adjustment_new"), rs.getInt("adjustment_used"),
                        rs.getInt("adjustment_damaged")
                    });
                    rememberInfo(key, rs, infoOut);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }

    private void rememberInfo(String key, ResultSet rs, Map<String, ProductWarehouseInfo> infoOut) throws Exception {
        if (infoOut.containsKey(key)) return;
        ProductWarehouseInfo info = new ProductWarehouseInfo();
        info.sku = rs.getString("sku");
        info.productName = rs.getString("product_name");
        info.unit = rs.getString("unit");
        info.warehouseId = rs.getInt("warehouse_id");
        info.warehouseName = rs.getString("warehouse_name");
        infoOut.put(key, info);
    }

    private void appendWarehouseAndSearch(StringBuilder sql, List<Object> params,
            Integer warehouseId, String search) {
        if (warehouseId != null) {
            sql.append("AND w.id = ? ");
            params.add(warehouseId);
        }
        if (search != null && !search.trim().isEmpty()) {
            sql.append("AND (p.sku LIKE ? OR p.product_name LIKE ?) ");
            String pattern = "%" + search.trim() + "%";
            params.add(pattern);
            params.add(pattern);
        }
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static class ProductWarehouseInfo {
        String sku;
        String productName;
        String unit;
        int warehouseId;
        String warehouseName;
    }
}
