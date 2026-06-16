package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import model.ExportRequest;
import model.ExportRequestDetail;
import utils.DBUtils;

public class ExportRequestDAO {

    public List<ExportRequest> getAllExportRequests() {
        List<ExportRequest> list = new ArrayList<>();
        String query = "SELECT r.*, d.destination_name, u.full_name AS creator_name, a.full_name AS approver_name, "
                     + "cr.full_name AS cancel_requested_name, cb.full_name AS cancelled_name "
                     + "FROM Export_Requests r "
                     + "JOIN Internal_Destinations d ON r.destination_id = d.id "
                     + "JOIN Users u ON r.staff_id = u.id "
                     + "LEFT JOIN Users a ON r.approved_by = a.id "
                     + "LEFT JOIN Users cr ON r.cancel_requested_by = cr.id "
                     + "LEFT JOIN Users cb ON r.cancelled_by = cb.id "
                     + "ORDER BY r.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ExportRequest r = new ExportRequest();
                r.setId(rs.getInt("id"));
                r.setRequestCode(rs.getString("request_code"));
                r.setDestinationId(rs.getInt("destination_id"));
                r.setExportReason(rs.getString("export_reason"));
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
                
                r.setDestinationName(rs.getString("destination_name"));
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
    
    public List<ExportRequest> getApprovedRequests() {
        List<ExportRequest> list = new ArrayList<>();
        String query = "SELECT r.*, d.destination_name, u.full_name AS creator_name "
                     + "FROM Export_Requests r "
                     + "JOIN Internal_Destinations d ON r.destination_id = d.id "
                     + "JOIN Users u ON r.staff_id = u.id "
                     + "WHERE r.status = 'APPROVED' AND r.cancel_requested_at IS NULL "
                     + "ORDER BY r.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ExportRequest r = new ExportRequest();
                r.setId(rs.getInt("id"));
                r.setRequestCode(rs.getString("request_code"));
                r.setDestinationId(rs.getInt("destination_id"));
                r.setExportReason(rs.getString("export_reason"));
                r.setCreatorId(rs.getInt("staff_id"));
                r.setStatus(rs.getString("status"));
                r.setExpectedDate(rs.getDate("expected_date"));
                r.setCreatedAt(rs.getTimestamp("created_at"));
                
                r.setDestinationName(rs.getString("destination_name"));
                r.setCreatorFullName(rs.getString("creator_name"));
                list.add(r);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    
    public ExportRequest getExportRequestById(int id) {
        String query = "SELECT r.*, d.destination_name, u.full_name AS creator_name, a.full_name AS approver_name, "
                     + "cr.full_name AS cancel_requested_name, cb.full_name AS cancelled_name "
                     + "FROM Export_Requests r "
                     + "JOIN Internal_Destinations d ON r.destination_id = d.id "
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
                    ExportRequest r = new ExportRequest();
                    r.setId(rs.getInt("id"));
                    r.setRequestCode(rs.getString("request_code"));
                    r.setDestinationId(rs.getInt("destination_id"));
                    r.setExportReason(rs.getString("export_reason"));
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
                    
                    r.setDestinationName(rs.getString("destination_name"));
                    r.setCreatorFullName(rs.getString("creator_name"));
                    r.setApprovedByFullName(rs.getString("approver_name"));
                    r.setCancelRequestedByFullName(rs.getString("cancel_requested_name"));
                    r.setCancelledByFullName(rs.getString("cancelled_name"));
                    
                    r.setDetails(getExportRequestDetails(id, conn));
                    return r;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
    
    private List<ExportRequestDetail> getExportRequestDetails(int requestId, Connection conn) throws Exception {
        List<ExportRequestDetail> list = new ArrayList<>();
        String query = "SELECT d.*, p.product_name, p.sku, p.unit, "
                     + "COALESCE((SELECT SUM(td.quantity) FROM Export_Ticket_Details td "
                     + "          JOIN Export_Tickets t ON td.ticket_id = t.id "
                     + "          WHERE t.request_id = d.request_id "
                     + "            AND td.product_id = d.product_id "
                     + "            AND t.status = 'CONFIRMED'), 0) AS issued_quantity "
                     + "FROM Export_Request_Details d "
                     + "JOIN Products p ON d.product_id = p.id "
                     + "WHERE d.request_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ExportRequestDetail d = new ExportRequestDetail();
                    d.setRequestId(rs.getInt("request_id"));
                    d.setProductId(rs.getInt("product_id"));
                    d.setQuantity(rs.getInt("quantity"));
                    
                    d.setProductName(rs.getString("product_name"));
                    d.setSku(rs.getString("sku"));
                    d.setUnit(rs.getString("unit"));
                    d.setIssuedQuantity(rs.getInt("issued_quantity"));
                    list.add(d);
                }
            }
        }
        return list;
    }
    
    public boolean addExportRequest(ExportRequest req, List<ExportRequestDetail> details) {
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);
            
            // 1. Generate unique request_code: REQ-EXP-[YEAR]-[RANDOM_4_DIGIT]
            Calendar cal = Calendar.getInstance();
            int year = cal.get(Calendar.YEAR);
            String code = "REQ-EXP-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
            
            // Validate code uniqueness
            boolean isUnique = false;
            int retries = 0;
            while (!isUnique && retries < 5) {
                String checkQuery = "SELECT COUNT(*) FROM Export_Requests WHERE request_code = ?";
                try (PreparedStatement psCheck = conn.prepareStatement(checkQuery)) {
                    psCheck.setString(1, code);
                    try (ResultSet rsCheck = psCheck.executeQuery()) {
                        if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                            isUnique = true;
                        } else {
                            code = "REQ-EXP-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
                            retries++;
                        }
                    }
                }
            }

            // 2. Insert into Export_Requests
            String insertReq = "INSERT INTO Export_Requests (request_code, destination_id, export_reason, staff_id, status, expected_date) "
                             + "VALUES (?, ?, ?, ?, 'PENDING', ?)";
            int requestId = 0;
            try (PreparedStatement ps = conn.prepareStatement(insertReq, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, code);
                ps.setInt(2, req.getDestinationId());
                ps.setString(3, req.getExportReason());
                ps.setInt(4, req.getCreatorId());
                ps.setDate(5, req.getExpectedDate());
                ps.executeUpdate();
                
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        requestId = rs.getInt(1);
                    }
                }
            }
            
            // 3. Insert into Export_Request_Details
            if (requestId > 0) {
                String insertDetail = "INSERT INTO Export_Request_Details (request_id, product_id, quantity) "
                                    + "VALUES (?, ?, ?)";
                try (PreparedStatement psd = conn.prepareStatement(insertDetail)) {
                    for (ExportRequestDetail d : details) {
                        psd.setInt(1, requestId);
                        psd.setInt(2, d.getProductId());
                        psd.setInt(3, d.getQuantity());
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

}
