package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.ExportRequest;
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
}
