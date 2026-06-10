package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.ExportTicket;
import utils.DBUtils;

public class ExportTicketDAO {

    public List<ExportTicket> getAllExportTickets() {
        List<ExportTicket> list = new ArrayList<>();
        String query = "SELECT t.*, r.request_code, k.full_name AS keeper_name, c.full_name AS confirmed_name, d.destination_name, r.export_reason "
                     + "FROM Export_Tickets t "
                     + "JOIN Export_Requests r ON t.request_id = r.id "
                     + "JOIN Internal_Destinations d ON r.destination_id = d.id "
                     + "JOIN Users k ON t.keeper_id = k.id "
                     + "LEFT JOIN Users c ON t.confirmed_by = c.id "
                     + "ORDER BY t.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ExportTicket t = new ExportTicket();
                t.setId(rs.getInt("id"));
                t.setTicketCode(rs.getString("ticket_code"));
                t.setRequestId(rs.getInt("request_id"));
                t.setKeeperId(rs.getInt("keeper_id"));
                t.setStatus(rs.getString("status"));
                t.setCreatedAt(rs.getTimestamp("created_at"));
                t.setConfirmedBy((Integer) rs.getObject("confirmed_by"));
                t.setConfirmedAt(rs.getTimestamp("confirmed_at"));
                
                t.setRequestCode(rs.getString("request_code"));
                t.setKeeperFullName(rs.getString("keeper_name"));
                t.setConfirmedByFullName(rs.getString("confirmed_name"));
                t.setDestinationName(rs.getString("destination_name"));
                t.setExportReason(rs.getString("export_reason"));
                list.add(t);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}
