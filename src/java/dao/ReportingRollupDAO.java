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
import model.StockSnapshotRow;
import utils.DBUtils;

/**
 * Read model for reporting rollups. A method returns null when the requested
 * history has not been backfilled yet; callers then use the legacy ledger
 * query so that schema rollout never makes a report silently incomplete.
 */
public class ReportingRollupDAO {

    public List<StockSnapshotRow> getSnapshot(String date, Integer warehouseId,
            String search, boolean includeZero) {
        String cutoff = normalizeDate(date);
        if (!hasCoverage(cutoff)) return null;

        List<StockSnapshotRow> rows = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT p.sku, p.product_name, p.unit, w.id AS warehouse_id, w.warehouse_name, "
          + "s.new_quantity, s.used_quantity, s.damaged_quantity, s.total_quantity "
          + "FROM Inventory_Daily_Snapshots s JOIN ( "
          + "  SELECT warehouse_id, product_id, MAX(snapshot_date) AS max_date "
          + "  FROM Inventory_Daily_Snapshots WHERE snapshot_date <= ? "
          + "  GROUP BY warehouse_id, product_id "
          + ") latest ON latest.warehouse_id=s.warehouse_id AND latest.product_id=s.product_id "
          + " AND latest.max_date=s.snapshot_date "
          + "JOIN Products p ON p.id=s.product_id JOIN Warehouses w ON w.id=s.warehouse_id WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        params.add(cutoff);
        appendFilters(sql, params, warehouseId, search);
        if (!includeZero) sql.append("AND s.total_quantity > 0 ");
        sql.append("ORDER BY w.warehouse_name, p.sku");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    StockSnapshotRow row = new StockSnapshotRow();
                    row.setSku(rs.getString("sku"));
                    row.setProductName(rs.getString("product_name"));
                    row.setUnit(rs.getString("unit"));
                    row.setWarehouseId(rs.getInt("warehouse_id"));
                    row.setWarehouseName(rs.getString("warehouse_name"));
                    row.setNewQuantity(rs.getInt("new_quantity"));
                    row.setUsedQuantity(rs.getInt("used_quantity"));
                    row.setDamagedQuantity(rs.getInt("damaged_quantity"));
                    row.setQuantity(rs.getInt("total_quantity"));
                    rows.add(row);
                }
            }
        } catch (Exception e) {
            return null;
        }
        return rows;
    }

    public List<DailyMovementRow> getDailyMovement(String fromDate, String toDate,
            Integer warehouseId, String search) {
        if (isBlank(fromDate) || isBlank(toDate) || !hasCoverage(fromDate.trim())) return null;
        List<DailyMovementRow> rows = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT p.sku, p.product_name, p.unit, w.id AS warehouse_id, w.warehouse_name, "
          + "m.movement_date, SUM(m.import_new+m.import_used+m.import_damaged) AS import_qty, "
          + "SUM(m.export_new+m.export_used+m.export_damaged) AS export_qty, "
          + "SUM(m.adjustment_new+m.adjustment_used+m.adjustment_damaged) AS adjustment_qty, "
          + "MAX(CASE WHEN m.adjustment_new<>0 OR m.adjustment_used<>0 OR m.adjustment_damaged<>0 THEN 1 ELSE 0 END) AS has_adjustment "
          + "FROM Inventory_Daily_Movements m JOIN Products p ON p.id=m.product_id "
          + "JOIN Warehouses w ON w.id=m.warehouse_id WHERE m.movement_date BETWEEN ? AND ? ");
        List<Object> params = new ArrayList<>();
        params.add(fromDate.trim());
        params.add(toDate.trim());
        appendFilters(sql, params, warehouseId, search);
        sql.append("GROUP BY p.id, w.id, m.movement_date ORDER BY m.movement_date, w.warehouse_name, p.sku");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    DailyMovementRow row = new DailyMovementRow();
                    row.setSku(rs.getString("sku"));
                    row.setProductName(rs.getString("product_name"));
                    row.setUnit(rs.getString("unit"));
                    row.setWarehouseId(rs.getInt("warehouse_id"));
                    row.setWarehouseName(rs.getString("warehouse_name"));
                    row.setDate(rs.getDate("movement_date").toString());
                    row.setImportQuantity(rs.getInt("import_qty"));
                    row.setExportQuantity(rs.getInt("export_qty"));
                    row.setAdjustmentQuantity(rs.getInt("adjustment_qty"));
                    row.setNote(rs.getInt("has_adjustment") == 1 ? "Có điều chỉnh kiểm kê" : "");
                    rows.add(row);
                }
            }
        } catch (Exception e) {
            return null;
        }
        return rows;
    }

    public List<PeriodSummaryRow> getPeriodSummary(String fromDate, String toDate,
            Integer warehouseId, String search, boolean includeZero) {
        if (isBlank(fromDate) || isBlank(toDate) || !hasCoverage(fromDate.trim())) return null;
        Map<String, ProductWarehouseInfo> info = new LinkedHashMap<>();
        Map<String, int[]> opening = loadBalances(fromDate.trim(), true, warehouseId, search, info);
        Map<String, int[]> closing = loadBalances(toDate.trim(), false, warehouseId, search, info);
        Map<String, int[]> movement = loadMovements(fromDate.trim(), toDate.trim(), warehouseId, search, info);
        List<PeriodSummaryRow> result = new ArrayList<>();

        for (String key : info.keySet()) {
            ProductWarehouseInfo product = info.get(key);
            int[] open = opening.getOrDefault(key, new int[]{0, 0, 0});
            int[] close = closing.getOrDefault(key, new int[]{0, 0, 0});
            int[] mv = movement.getOrDefault(key, new int[9]);
            String[] conditions = {"NEW", "USED", "DAMAGED"};
            for (int i = 0; i < conditions.length; i++) {
                int openQty = open[i];
                int closeQty = close[i];
                int importQty = mv[i * 2];
                int exportQty = mv[i * 2 + 1];
                int adjustmentQty = mv[6 + i];
                if (!includeZero && openQty == 0 && closeQty == 0 && importQty == 0
                        && exportQty == 0 && adjustmentQty == 0) continue;
                PeriodSummaryRow row = new PeriodSummaryRow();
                row.setSku(product.sku);
                row.setProductName(product.productName);
                row.setUnit(product.unit);
                row.setWarehouseId(product.warehouseId);
                row.setWarehouseName(product.warehouseName);
                row.setCondition(conditions[i]);
                row.setOpeningQuantity(openQty);
                row.setImportQuantity(importQty);
                row.setExportQuantity(exportQty);
                row.setAdjustmentQuantity(adjustmentQty);
                row.setClosingQuantity(closeQty);
                row.setNote("");
                result.add(row);
            }
        }
        result.sort((a, b) -> {
            int compare = a.getWarehouseName().compareTo(b.getWarehouseName());
            if (compare != 0) return compare;
            compare = a.getSku().compareTo(b.getSku());
            return compare != 0 ? compare : a.getCondition().compareTo(b.getCondition());
        });
        return result;
    }

    private Map<String, int[]> loadBalances(String date, boolean beforeDate, Integer warehouseId,
            String search, Map<String, ProductWarehouseInfo> info) {
        Map<String, int[]> result = new LinkedHashMap<>();
        String operator = beforeDate ? "<" : "<=";
        StringBuilder sql = new StringBuilder(
            "SELECT p.id AS product_id, p.sku, p.product_name, p.unit, w.id AS warehouse_id, w.warehouse_name, "
          + "s.new_quantity, s.used_quantity, s.damaged_quantity "
          + "FROM Inventory_Daily_Snapshots s JOIN ( "
          + " SELECT warehouse_id, product_id, MAX(snapshot_date) AS max_date FROM Inventory_Daily_Snapshots "
          + " WHERE snapshot_date " + operator + " ? GROUP BY warehouse_id, product_id "
          + ") latest ON latest.warehouse_id=s.warehouse_id AND latest.product_id=s.product_id AND latest.max_date=s.snapshot_date "
          + "JOIN Products p ON p.id=s.product_id JOIN Warehouses w ON w.id=s.warehouse_id WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        params.add(date);
        appendFilters(sql, params, warehouseId, search);
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String key = key(rs.getInt("product_id"), rs.getInt("warehouse_id"));
                    result.put(key, new int[]{rs.getInt("new_quantity"), rs.getInt("used_quantity"), rs.getInt("damaged_quantity")});
                    rememberInfo(key, rs, info);
                }
            }
        } catch (Exception e) {
            return new LinkedHashMap<>();
        }
        return result;
    }

    private Map<String, int[]> loadMovements(String fromDate, String toDate, Integer warehouseId,
            String search, Map<String, ProductWarehouseInfo> info) {
        Map<String, int[]> result = new LinkedHashMap<>();
        StringBuilder sql = new StringBuilder(
            "SELECT p.id AS product_id, p.sku, p.product_name, p.unit, w.id AS warehouse_id, w.warehouse_name, "
          + "SUM(m.import_new) import_new, SUM(m.export_new) export_new, SUM(m.import_used) import_used, SUM(m.export_used) export_used, "
          + "SUM(m.import_damaged) import_damaged, SUM(m.export_damaged) export_damaged, "
          + "SUM(m.adjustment_new) adjustment_new, SUM(m.adjustment_used) adjustment_used, SUM(m.adjustment_damaged) adjustment_damaged "
          + "FROM Inventory_Daily_Movements m JOIN Products p ON p.id=m.product_id "
          + "JOIN Warehouses w ON w.id=m.warehouse_id WHERE m.movement_date BETWEEN ? AND ? ");
        List<Object> params = new ArrayList<>();
        params.add(fromDate);
        params.add(toDate);
        appendFilters(sql, params, warehouseId, search);
        sql.append("GROUP BY p.id, w.id");
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String key = key(rs.getInt("product_id"), rs.getInt("warehouse_id"));
                    result.put(key, new int[]{rs.getInt("import_new"), rs.getInt("export_new"),
                        rs.getInt("import_used"), rs.getInt("export_used"), rs.getInt("import_damaged"),
                        rs.getInt("export_damaged"), rs.getInt("adjustment_new"), rs.getInt("adjustment_used"),
                        rs.getInt("adjustment_damaged")});
                    rememberInfo(key, rs, info);
                }
            }
        } catch (Exception e) {
            return new LinkedHashMap<>();
        }
        return result;
    }

    private boolean hasCoverage(String requiredDate) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                    "SELECT coverage_start FROM Reporting_Rollup_State WHERE rollup_name='LEDGER_DAILY'")) {
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getDate(1).toString().compareTo(requiredDate) <= 0;
            }
        } catch (Exception e) {
            return false;
        }
    }

    private void appendFilters(StringBuilder sql, List<Object> params, Integer warehouseId, String search) {
        if (warehouseId != null) {
            sql.append("AND w.id=? ");
            params.add(warehouseId);
        }
        if (!isBlank(search)) {
            String pattern = "%" + search.trim() + "%";
            sql.append("AND (p.sku LIKE ? OR p.product_name LIKE ?) ");
            params.add(pattern);
            params.add(pattern);
        }
    }

    private void bind(PreparedStatement ps, List<Object> params) throws Exception {
        for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
    }

    private void rememberInfo(String key, ResultSet rs, Map<String, ProductWarehouseInfo> info) throws Exception {
        if (info.containsKey(key)) return;
        ProductWarehouseInfo value = new ProductWarehouseInfo();
        value.sku = rs.getString("sku");
        value.productName = rs.getString("product_name");
        value.unit = rs.getString("unit");
        value.warehouseId = rs.getInt("warehouse_id");
        value.warehouseName = rs.getString("warehouse_name");
        info.put(key, value);
    }

    private String normalizeDate(String date) {
        return isBlank(date) ? java.time.LocalDate.now().toString() : date.trim();
    }

    private String key(int productId, int warehouseId) { return productId + "_" + warehouseId; }
    private boolean isBlank(String value) { return value == null || value.trim().isEmpty(); }

    private static class ProductWarehouseInfo {
        String sku;
        String productName;
        String unit;
        int warehouseId;
        String warehouseName;
    }
}
