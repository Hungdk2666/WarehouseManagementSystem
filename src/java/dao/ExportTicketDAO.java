package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Calendar;
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
    
    public boolean addExportTicket(ExportTicket ticket, List<ExportTicketDetail> details) {
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            // 1. Generate unique ticketCode: TKT-EXP-[YEAR]-[RANDOM_4_DIGIT]
            Calendar cal = Calendar.getInstance();
            int year = cal.get(Calendar.YEAR);
            String code = "TKT-EXP-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
            
            // Validate code uniqueness
            boolean isUnique = false;
            int retries = 0;
            while (!isUnique && retries < 5) {
                String checkQuery = "SELECT COUNT(*) FROM Export_Tickets WHERE ticket_code = ?";
                try (PreparedStatement psCheck = conn.prepareStatement(checkQuery)) {
                    psCheck.setString(1, code);
                    try (ResultSet rsCheck = psCheck.executeQuery()) {
                        if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                            isUnique = true;
                        } else {
                            code = "TKT-EXP-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
                            retries++;
                        }
                    }
                }
            }

            // 2. Insert into Export_Tickets
            String insertTicket = "INSERT INTO Export_Tickets (ticket_code, request_id, keeper_id, status) "
                                + "VALUES (?, ?, ?, 'DRAFT')";
            int ticketId = 0;
            try (PreparedStatement ps = conn.prepareStatement(insertTicket, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, code);
                ps.setInt(2, ticket.getRequestId());
                ps.setInt(3, ticket.getKeeperId());
                ps.executeUpdate();
                
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        ticketId = rs.getInt(1);
                    }
                }
            }

            // 3. Insert into Export_Ticket_Details
            if (ticketId > 0) {
                String insertDetail = "INSERT INTO Export_Ticket_Details (ticket_id, product_id, quantity, unit_cost) "
                                    + "VALUES (?, ?, ?, 0.00)";
                try (PreparedStatement psd = conn.prepareStatement(insertDetail)) {
                    for (ExportTicketDetail d : details) {
                        psd.setInt(1, ticketId);
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
