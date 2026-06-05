package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.ImportRequest;
import model.ImportRequestDetail;
import utils.DBUtils;

public class ImportRequestDAO {

    public List<ImportRequest> getAllImportRequests() {
        List<ImportRequest> list = new ArrayList<>();
        String query = "SELECT r.*, s.supplier_name, u.full_name AS creator_name, a.full_name AS approver_name, "
                     + "cr.full_name AS cancel_requested_name, cb.full_name AS cancelled_name "
                     + "FROM Import_Requests r "
                     + "JOIN Suppliers s ON r.supplier_id = s.id "
                     + "JOIN Users u ON r.staff_id = u.id "
                     + "LEFT JOIN Users a ON r.approved_by = a.id "
                     + "LEFT JOIN Users cr ON r.cancel_requested_by = cr.id "
                     + "LEFT JOIN Users cb ON r.cancelled_by = cb.id "
                     + "ORDER BY r.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ImportRequest r = new ImportRequest();
                r.setId(rs.getInt("id"));
                r.setRequestCode(rs.getString("request_code"));
                r.setSupplierId(rs.getInt("supplier_id"));
                r.setCreatorId(rs.getInt("staff_id"));
                r.setStatus(rs.getString("status"));
                r.setExpectedDate(rs.getDate("expected_date"));
                r.setCreatedAt(rs.getTimestamp("created_at"));
                r.setApprovedBy((Integer) rs.getObject("approved_by"));
                r.setApprovedAt(rs.getTimestamp("approved_at"));
                r.setCancelRequestedBy((Integer) rs.getObject("cancel_requested_by"));
                r.setCancelRequestedAt(rs.getTimestamp("cancel_requested_at"));
                r.setCancelReason(rs.getString("cancel_reason"));
                r.setCancelledBy((Integer) rs.getObject("cancelled_by"));
                r.setCancelledAt(rs.getTimestamp("cancelled_at"));
                
                r.setSupplierName(rs.getString("supplier_name"));
                r.setCreatorFullName(rs.getString("creator_name"));
                r.setApprovedByFullName(rs.getString("approver_name"));
                r.setCancelRequestedByFullName(rs.getString("cancel_requested_name"));
                r.setCancelledByFullName(rs.getString("cancelled_name"));
                list.add(r);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ImportRequest getImportRequestById(int id) {
        String query = "SELECT r.*, s.supplier_name, u.full_name AS creator_name, a.full_name AS approver_name, "
                     + "cr.full_name AS cancel_requested_name, cb.full_name AS cancelled_name "
                     + "FROM Import_Requests r "
                     + "JOIN Suppliers s ON r.supplier_id = s.id "
                     + "JOIN Users u ON r.staff_id = u.id "
                     + "LEFT JOIN Users a ON r.approved_by = a.id "
                     + "LEFT JOIN Users cr ON r.cancel_requested_by = cr.id "
                     + "LEFT JOIN Users cb ON r.cancelled_by = cb.id "
                     + "WHERE r.id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ImportRequest r = new ImportRequest();
                    r.setId(rs.getInt("id"));
                    r.setRequestCode(rs.getString("request_code"));
                    r.setSupplierId(rs.getInt("supplier_id"));
                    r.setCreatorId(rs.getInt("staff_id"));
                    r.setStatus(rs.getString("status"));
                    r.setExpectedDate(rs.getDate("expected_date"));
                    r.setCreatedAt(rs.getTimestamp("created_at"));
                    r.setApprovedBy((Integer) rs.getObject("approved_by"));
                    r.setApprovedAt(rs.getTimestamp("approved_at"));
                    r.setCancelRequestedBy((Integer) rs.getObject("cancel_requested_by"));
                    r.setCancelRequestedAt(rs.getTimestamp("cancel_requested_at"));
                    r.setCancelReason(rs.getString("cancel_reason"));
                    r.setCancelledBy((Integer) rs.getObject("cancelled_by"));
                    r.setCancelledAt(rs.getTimestamp("cancelled_at"));
                    
                    r.setSupplierName(rs.getString("supplier_name"));
                    r.setCreatorFullName(rs.getString("creator_name"));
                    r.setApprovedByFullName(rs.getString("approver_name"));
                    r.setCancelRequestedByFullName(rs.getString("cancel_requested_name"));
                    r.setCancelledByFullName(rs.getString("cancelled_name"));
                    
                    r.setDetails(getImportRequestDetails(id, conn));
                    return r;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private List<ImportRequestDetail> getImportRequestDetails(int requestId, Connection conn) throws Exception {
        List<ImportRequestDetail> list = new ArrayList<>();
        String query = "SELECT d.*, p.product_name, p.sku, p.unit, "
                     + "COALESCE((SELECT SUM(td.quantity) FROM Import_Ticket_Details td "
                     + "          JOIN Import_Tickets t ON td.ticket_id = t.id "
                     + "          WHERE t.request_id = d.request_id "
                     + "            AND td.product_id = d.product_id "
                     + "            AND t.status = 'CONFIRMED'), 0) AS received_quantity "
                     + "FROM Import_Request_Details d "
                     + "JOIN Products p ON d.product_id = p.id "
                     + "WHERE d.request_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ImportRequestDetail d = new ImportRequestDetail();
                    d.setRequestId(rs.getInt("request_id"));
                    d.setProductId(rs.getInt("product_id"));
                    d.setQuantity(rs.getInt("quantity"));
                    d.setUnitPrice(rs.getDouble("unit_price"));
                    
                    d.setProductName(rs.getString("product_name"));
                    d.setSku(rs.getString("sku"));
                    d.setUnit(rs.getString("unit"));
                    d.setReceivedQuantity(rs.getInt("received_quantity"));
                    list.add(d);
                }
            }
        }
        return list;
    }
}
