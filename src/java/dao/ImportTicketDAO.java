package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Calendar;
import model.ImportTicket;
import model.ImportTicketDetail;
import utils.DBUtils;

public class ImportTicketDAO {

    public List<ImportTicket> getAllImportTickets() {
        List<ImportTicket> list = new ArrayList<>();
        String query = "SELECT t.*, r.request_code, k.full_name AS keeper_name, c.full_name AS confirmed_name, s.supplier_name "
                     + "FROM Import_Tickets t "
                     + "JOIN Import_Requests r ON t.request_id = r.id "
                     + "JOIN Suppliers s ON r.supplier_id = s.id "
                     + "JOIN Users k ON t.keeper_id = k.id "
                     + "LEFT JOIN Users c ON t.confirmed_by = c.id "
                     + "ORDER BY t.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ImportTicket t = new ImportTicket();
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
                t.setSupplierName(rs.getString("supplier_name"));
                list.add(t);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public ImportTicket getImportTicketById(int id) {
        String query = "SELECT t.*, r.request_code, k.full_name AS keeper_name, c.full_name AS confirmed_name, s.supplier_name "
                     + "FROM Import_Tickets t "
                     + "JOIN Import_Requests r ON t.request_id = r.id "
                     + "JOIN Suppliers s ON r.supplier_id = s.id "
                     + "JOIN Users k ON t.keeper_id = k.id "
                     + "LEFT JOIN Users c ON t.confirmed_by = c.id "
                     + "WHERE t.id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    ImportTicket t = new ImportTicket();
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
                    t.setSupplierName(rs.getString("supplier_name"));
                    
                    t.setDetails(getImportTicketDetails(id, conn));
                    return t;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private List<ImportTicketDetail> getImportTicketDetails(int ticketId, Connection conn) throws Exception {
        List<ImportTicketDetail> list = new ArrayList<>();
        String query = "SELECT d.*, p.product_name, p.sku, p.unit "
                     + "FROM Import_Ticket_Details d "
                     + "JOIN Products p ON d.product_id = p.id "
                     + "WHERE d.ticket_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ImportTicketDetail d = new ImportTicketDetail();
                    d.setTicketId(rs.getInt("ticket_id"));
                    d.setProductId(rs.getInt("product_id"));
                    d.setQuantity(rs.getInt("quantity"));
                    d.setUnitPrice(rs.getDouble("unit_price"));
                    
                    d.setProductName(rs.getString("product_name"));
                    d.setSku(rs.getString("sku"));
                    d.setUnit(rs.getString("unit"));
                    list.add(d);
                }
            }
        }
        return list;
    }
    
    public List<ImportTicket> getImportTicketsByRequestId(int requestId) {
        List<ImportTicket> list = new ArrayList<>();
        String query = "SELECT t.*, r.request_code, k.full_name AS keeper_name, c.full_name AS confirmed_name, s.supplier_name "
                     + "FROM Import_Tickets t "
                     + "JOIN Import_Requests r ON t.request_id = r.id "
                     + "JOIN Suppliers s ON r.supplier_id = s.id "
                     + "JOIN Users k ON t.keeper_id = k.id "
                     + "LEFT JOIN Users c ON t.confirmed_by = c.id "
                     + "WHERE t.request_id = ? "
                     + "ORDER BY t.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ImportTicket t = new ImportTicket();
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
                    t.setSupplierName(rs.getString("supplier_name"));
                    list.add(t);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}
