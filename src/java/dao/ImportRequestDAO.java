package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Calendar;
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

    public List<ImportRequest> getApprovedRequests() {
        List<ImportRequest> list = new ArrayList<>();
        String query = "SELECT r.*, s.supplier_name, u.full_name AS creator_name "
                     + "FROM Import_Requests r "
                     + "JOIN Suppliers s ON r.supplier_id = s.id "
                     + "JOIN Users u ON r.staff_id = u.id "
                     + "WHERE r.status = 'APPROVED' AND r.cancel_requested_at IS NULL "
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
                
                r.setSupplierName(rs.getString("supplier_name"));
                r.setCreatorFullName(rs.getString("creator_name"));
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
    
    public boolean addImportRequest(ImportRequest req, List<ImportRequestDetail> details) {
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);
            
            // 1. Generate unique request_code: REQ-[YEAR]-[RANDOM_4_DIGIT] or sequence
            Calendar cal = Calendar.getInstance();
            int year = cal.get(Calendar.YEAR);
            String code = "REQ-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
            
            // Validate code uniqueness
            boolean isUnique = false;
            int retries = 0;
            while (!isUnique && retries < 5) {
                String checkQuery = "SELECT COUNT(*) FROM Import_Requests WHERE request_code = ?";
                try (PreparedStatement psCheck = conn.prepareStatement(checkQuery)) {
                    psCheck.setString(1, code);
                    try (ResultSet rsCheck = psCheck.executeQuery()) {
                        if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                            isUnique = true;
                        } else {
                            code = "REQ-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
                            retries++;
                        }
                    }
                }
            }

            // 2. Insert into Import_Requests
            String insertReq = "INSERT INTO Import_Requests (request_code, supplier_id, staff_id, status, expected_date) "
                             + "VALUES (?, ?, ?, 'PENDING', ?)";
            int requestId = 0;
            try (PreparedStatement ps = conn.prepareStatement(insertReq, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, code);
                ps.setInt(2, req.getSupplierId());
                ps.setInt(3, req.getCreatorId());
                ps.setDate(4, req.getExpectedDate());
                ps.executeUpdate();
                
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        requestId = rs.getInt(1);
                    }
                }
            }
            
            // 3. Insert into Import_Request_Details
            if (requestId > 0) {
                String insertDetail = "INSERT INTO Import_Request_Details (request_id, product_id, quantity, unit_price) "
                                    + "VALUES (?, ?, ?, ?)";
                try (PreparedStatement psd = conn.prepareStatement(insertDetail)) {
                    for (ImportRequestDetail d : details) {
                        psd.setInt(1, requestId);
                        psd.setInt(2, d.getProductId());
                        psd.setInt(3, d.getQuantity());
                        psd.setDouble(4, d.getUnitPrice());
                        psd.addBatch();
                    }
                    psd.executeBatch();
                }
                conn.commit();
                return true;
            } else {
                conn.rollback();
            }
        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (Exception ex) { ex.printStackTrace(); }
            }
        }
        return false;
    }
    
    public boolean updateStatus(int id, String status, Integer approvedBy) {
        String query = "UPDATE Import_Requests SET status = ?, approved_by = ?, approved_at = CURRENT_TIMESTAMP WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, status);
            if (approvedBy != null) {
                ps.setInt(2, approvedBy);
            } else {
                ps.setNull(2, java.sql.Types.INTEGER);
            }
            ps.setInt(3, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public boolean cancelRequest(int id, Integer userId) {
        String query = "UPDATE Import_Requests SET status = 'CANCELLED', cancelled_by = ?, cancelled_at = CURRENT_TIMESTAMP WHERE id = ? AND status = 'PENDING'";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            if (userId != null) {
                ps.setInt(1, userId);
            } else {
                ps.setNull(1, java.sql.Types.INTEGER);
            }
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean requestCancel(int id, int userId, String reason) {
        String query = "UPDATE Import_Requests SET cancel_requested_by = ?, cancel_requested_at = CURRENT_TIMESTAMP, cancel_reason = ? "
                     + "WHERE id = ? AND status = 'APPROVED' AND cancel_requested_at IS NULL";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setString(2, reason);
            ps.setInt(3, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean approveCancel(int id, int userId) {
        String query = "UPDATE Import_Requests SET status = 'CANCELLED', cancelled_by = ?, cancelled_at = CURRENT_TIMESTAMP "
                     + "WHERE id = ? AND status = 'APPROVED' AND cancel_requested_at IS NOT NULL";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean rejectCancel(int id) {
        String query = "UPDATE Import_Requests SET cancel_requested_by = NULL, cancel_requested_at = NULL, cancel_reason = NULL "
                     + "WHERE id = ? AND status = 'APPROVED' AND cancel_requested_at IS NOT NULL";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
