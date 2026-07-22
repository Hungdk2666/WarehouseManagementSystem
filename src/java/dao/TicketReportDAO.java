package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.TicketReportRow;
import utils.DBUtils;

/** Data source for the operational import and export ticket reports. */
public class TicketReportDAO {

    public List<TicketReportRow> getRows(String ticketType, String fromDate, String toDate,
            Integer warehouseId, String search) {
        List<TicketReportRow> rows = new ArrayList<>();
        if (blank(fromDate) || blank(toDate)
                || (!"IN".equals(ticketType) && !"OUT".equals(ticketType))) return rows;

        StringBuilder sql = new StringBuilder(
            "SELECT DATE(t.confirmed_at) AS transaction_date, t.ticket_code, r.reason, "
          + "p.sku, p.product_name, p.unit, td.quantity, "
          + "CASE WHEN r.reason='PURCHASE' THEN td.unit_cost ELSE NULL END AS unit_cost, "
          + "CASE WHEN r.reason='PURCHASE' THEN td.quantity * td.unit_cost ELSE NULL END AS total_cost, "
          + "w.warehouse_name, CASE r.partner_type "
          + " WHEN 'SUPPLIER' THEN (SELECT supplier_name FROM Suppliers WHERE id=r.partner_id) "
          + " WHEN 'WAREHOUSE' THEN (SELECT warehouse_name FROM Warehouses WHERE id=r.partner_id) "
          + " WHEN 'INTERNAL_DEST' THEN (SELECT destination_name FROM Internal_Destinations WHERE id=r.partner_id) "
          + " ELSE NULL END AS partner_name "
          + "FROM Tickets t "
          + "JOIN Requests r ON r.id=t.request_id "
          + "JOIN Ticket_Details td ON td.ticket_id=t.id "
          + "JOIN Products p ON p.id=td.product_id "
          + "JOIN Warehouses w ON w.id=t.warehouse_id "
          + "WHERE t.type=? AND t.status IN ('CONFIRMED','IN_TRANSIT','COMPLETED') "
          + "AND t.confirmed_at BETWEEN ? AND ? ");
        List<Object> params = new ArrayList<>();
        params.add(ticketType);
        params.add(fromDate.trim() + " 00:00:00");
        params.add(toDate.trim() + " 23:59:59");
        if (warehouseId != null) {
            sql.append("AND t.warehouse_id=? ");
            params.add(warehouseId);
        }
        if (!blank(search)) {
            sql.append("AND (p.sku LIKE ? OR p.product_name LIKE ? OR t.ticket_code LIKE ?) ");
            String pattern = "%" + search.trim() + "%";
            params.add(pattern);
            params.add(pattern);
            params.add(pattern);
        }
        sql.append("ORDER BY t.confirmed_at DESC, t.ticket_code DESC, p.sku");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int index = 1;
            for (Object param : params) ps.setObject(index++, param);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TicketReportRow row = new TicketReportRow();
                    row.setTransactionDate(rs.getDate("transaction_date").toString());
                    row.setTicketCode(rs.getString("ticket_code"));
                    row.setReason(rs.getString("reason"));
                    row.setSku(rs.getString("sku"));
                    row.setProductName(rs.getString("product_name"));
                    row.setUnit(rs.getString("unit"));
                    row.setQuantity(rs.getInt("quantity"));
                    row.setUnitCost(rs.getBigDecimal("unit_cost"));
                    row.setTotalCost(rs.getBigDecimal("total_cost"));
                    row.setWarehouseName(rs.getString("warehouse_name"));
                    row.setPartnerName(rs.getString("partner_name"));
                    rows.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return rows;
    }

    private boolean blank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
