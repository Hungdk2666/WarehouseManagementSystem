package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.HistoryEntry;
import utils.DBUtils;

public class InventoryHistoryDAO {

    private static final String BASE_SELECT =
        "SELECT l.id, l.transaction_type, l.change_quantity, "
      + "       l.change_new_quantity, l.change_used_quantity, l.change_damaged_quantity, l.created_at, "
      // "Tồn sau GD" hiển thị nhất quán = tổng vật lý (mới+cũ+hỏng) khi có cột granular;
      // nếu bút toán cũ chưa có granular thì giữ balance_quantity như trước.
      + "       CASE WHEN l.balance_new_quantity IS NULL AND l.balance_used_quantity IS NULL AND l.balance_damaged_quantity IS NULL "
      + "            THEN l.balance_quantity "
      + "            ELSE COALESCE(l.balance_new_quantity,0)+COALESCE(l.balance_used_quantity,0)+COALESCE(l.balance_damaged_quantity,0) END AS balance_quantity, "
      + "       l.reference_id, l.product_id, l.warehouse_id, "
      + "       p.product_name, p.sku, "
      + "       w.warehouse_name, "
      + "       t.ticket_code, t.type AS ticket_type, "
      + "       st.stocktake_code, "
      + "       r.request_code, r.reason AS request_reason, "
      + "       COALESCE(s.supplier_name, cust.customer_name, w2.warehouse_name, dest.destination_name) AS partner_name, "
      + "       u.full_name AS created_by_name, "
      + "       ua.full_name AS approved_by_name, "
      + "       td.unit_cost "
      + "FROM Product_Ledger l "
      + "JOIN Products p ON p.id = l.product_id "
      + "JOIN Warehouses w ON w.id = l.warehouse_id "
      + "LEFT JOIN Tickets t ON t.id = l.reference_id AND l.transaction_type <> 'STOCKTAKE' "
      + "LEFT JOIN Stocktakes st ON st.id = l.reference_id AND l.transaction_type = 'STOCKTAKE' "
      + "LEFT JOIN Requests r ON r.id = t.request_id "
      + "LEFT JOIN Suppliers s ON r.partner_type = 'SUPPLIER' AND s.id = r.partner_id "
      + "LEFT JOIN Customers cust ON r.partner_type = 'CUSTOMER' AND cust.id = r.partner_id "
      + "LEFT JOIN Warehouses w2 ON r.partner_type = 'WAREHOUSE' AND w2.id = r.partner_id "
      + "LEFT JOIN Internal_Destinations dest ON r.partner_type = 'INTERNAL_DEST' AND dest.id = r.partner_id "
      + "LEFT JOIN Users u ON u.id = l.created_by "
      + "LEFT JOIN Users ua ON ua.id = r.approved_by "
      + "LEFT JOIN Ticket_Details td ON td.ticket_id = t.id AND td.product_id = l.product_id ";

    private static final String COUNT_SELECT =
        "SELECT COUNT(*) "
      + "FROM Product_Ledger l "
      + "JOIN Products p ON p.id = l.product_id "
      + "JOIN Warehouses w ON w.id = l.warehouse_id "
      + "LEFT JOIN Tickets t ON t.id = l.reference_id AND l.transaction_type <> 'STOCKTAKE' "
      + "LEFT JOIN Stocktakes st ON st.id = l.reference_id AND l.transaction_type = 'STOCKTAKE' "
      + "LEFT JOIN Requests r ON r.id = t.request_id ";

    public List<HistoryEntry> getHistory(String search, String transactionType,
            Integer warehouseId, String startDate, String endDate,
            int page, int pageSize) {
        List<HistoryEntry> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(BASE_SELECT).append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        appendFilters(sql, params, search, transactionType, warehouseId, startDate, endDate);
        sql.append("ORDER BY l.created_at DESC, l.id DESC LIMIT ? OFFSET ?");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            for (Object param : params) ps.setObject(idx++, param);
            ps.setInt(idx++, pageSize);
            ps.setInt(idx, (page - 1) * pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public int getCount(String search, String transactionType,
            Integer warehouseId, String startDate, String endDate) {
        StringBuilder sql = new StringBuilder(COUNT_SELECT).append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        appendFilters(sql, params, search, transactionType, warehouseId, startDate, endDate);

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            for (Object param : params) ps.setObject(idx++, param);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    public List<HistoryEntry> getHistoryForExport(String search, String transactionType,
            Integer warehouseId, String startDate, String endDate) {
        List<HistoryEntry> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(BASE_SELECT).append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        appendFilters(sql, params, search, transactionType, warehouseId, startDate, endDate);
        sql.append("ORDER BY l.created_at DESC, l.id DESC");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = 1;
            for (Object param : params) ps.setObject(idx++, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    private void appendFilters(StringBuilder sql, List<Object> params,
            String search, String transactionType, Integer warehouseId,
            String startDate, String endDate) {
        if (transactionType != null && !transactionType.trim().isEmpty()) {
            sql.append("AND l.transaction_type = ? ");
            params.add(transactionType.trim());
        }
        if (warehouseId != null) {
            sql.append("AND l.warehouse_id = ? ");
            params.add(warehouseId);
        }
        if (startDate != null && !startDate.trim().isEmpty()) {
            sql.append("AND l.created_at >= ? ");
            params.add(startDate.trim() + " 00:00:00");
        }
        if (endDate != null && !endDate.trim().isEmpty()) {
            sql.append("AND l.created_at <= ? ");
            params.add(endDate.trim() + " 23:59:59");
        }
        if (search != null && !search.trim().isEmpty()) {
            sql.append("AND (p.product_name LIKE ? OR p.sku LIKE ? OR t.ticket_code LIKE ? "
                    + "OR st.stocktake_code LIKE ? OR r.request_code LIKE ?) ");
            String pattern = "%" + search.trim() + "%";
            params.add(pattern);
            params.add(pattern);
            params.add(pattern);
            params.add(pattern);
            params.add(pattern);
        }
    }

    private HistoryEntry mapRow(ResultSet rs) throws Exception {
        HistoryEntry e = new HistoryEntry();
        e.setId(rs.getInt("id"));
        e.setTransactionType(rs.getString("transaction_type"));
        e.setChangeQuantity(rs.getInt("change_quantity"));
        e.setChangeNewQuantity((Integer) rs.getObject("change_new_quantity"));
        e.setChangeUsedQuantity((Integer) rs.getObject("change_used_quantity"));
        e.setChangeDamagedQuantity((Integer) rs.getObject("change_damaged_quantity"));
        e.setBalanceQuantity(rs.getInt("balance_quantity"));
        e.setCreatedAt(rs.getTimestamp("created_at"));
        e.setReferenceId(rs.getInt("reference_id"));
        e.setProductId(rs.getInt("product_id"));
        e.setWarehouseId(rs.getInt("warehouse_id"));
        e.setProductName(rs.getString("product_name"));
        e.setSku(rs.getString("sku"));
        e.setWarehouseName(rs.getString("warehouse_name"));
        e.setTicketCode(rs.getString("ticket_code"));
        e.setStocktakeCode(rs.getString("stocktake_code"));
        e.setTicketType(rs.getString("ticket_type"));
        e.setRequestCode(rs.getString("request_code"));
        e.setRequestReason(rs.getString("request_reason"));
        e.setPartnerName(rs.getString("partner_name"));
        e.setCreatedByName(rs.getString("created_by_name"));
        e.setApprovedByName(rs.getString("approved_by_name"));
        e.setUnitCost(rs.getBigDecimal("unit_cost"));
        return e;
    }
}
