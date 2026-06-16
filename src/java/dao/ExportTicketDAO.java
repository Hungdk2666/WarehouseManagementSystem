package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.ExportTicket;
import model.ExportTicketDetail;
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
    
    public List<ExportTicket> getExportTicketsByRequestId(int requestId) {
        List<ExportTicket> list = new ArrayList<>();
        String query = "SELECT t.*, r.request_code, k.full_name AS keeper_name, c.full_name AS confirmed_name, d.destination_name, r.export_reason "
                     + "FROM Export_Tickets t "
                     + "JOIN Export_Requests r ON t.request_id = r.id "
                     + "JOIN Internal_Destinations d ON r.destination_id = d.id "
                     + "JOIN Users k ON t.keeper_id = k.id "
                     + "LEFT JOIN Users c ON t.confirmed_by = c.id "
                     + "WHERE t.request_id = ? "
                     + "ORDER BY t.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
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
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ExportTicket getExportTicketById(int id) {
        String query = "SELECT t.*, r.request_code, k.full_name AS keeper_name, c.full_name AS confirmed_name, d.destination_name, r.export_reason "
                     + "FROM Export_Tickets t "
                     + "JOIN Export_Requests r ON t.request_id = r.id "
                     + "JOIN Internal_Destinations d ON r.destination_id = d.id "
                     + "JOIN Users k ON t.keeper_id = k.id "
                     + "LEFT JOIN Users c ON t.confirmed_by = c.id "
                     + "WHERE t.id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
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
                    
                    t.setDetails(getExportTicketDetails(id, conn));
                    return t;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
    
    private List<ExportTicketDetail> getExportTicketDetails(int ticketId, Connection conn) throws Exception {
        List<ExportTicketDetail> list = new ArrayList<>();
        String query = "SELECT d.*, p.product_name, p.sku, p.unit "
                     + "FROM Export_Ticket_Details d "
                     + "JOIN Products p ON d.product_id = p.id "
                     + "WHERE d.ticket_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ExportTicketDetail d = new ExportTicketDetail();
                    d.setTicketId(rs.getInt("ticket_id"));
                    d.setProductId(rs.getInt("product_id"));
                    d.setQuantity(rs.getInt("quantity"));
                    d.setUnitCost(rs.getDouble("unit_cost"));
                    
                    d.setProductName(rs.getString("product_name"));
                    d.setSku(rs.getString("sku"));
                    d.setUnit(rs.getString("unit"));
                    list.add(d);
                }
            }
        }
        return list;
    }
}
