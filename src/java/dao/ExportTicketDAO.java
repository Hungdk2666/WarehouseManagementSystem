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
    
    public boolean confirmTicket(int ticketId, int confirmedBy, List<String> serials) {
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            // 1. Fetch ticket details
            ExportTicket ticket = getExportTicketById(ticketId);
            if (ticket == null || !"DRAFT".equals(ticket.getStatus())) {
                conn.rollback();
                return false;
            }
            List<ExportTicketDetail> details = getExportTicketDetails(ticketId, conn);

            // 1.5. Validate that we have received the exact amount of serials required
            int totalRequired = 0;
            for (ExportTicketDetail d : details) {
                totalRequired += d.getQuantity();
            }
            if (serials == null || serials.size() != totalRequired) {
                System.err.println("Confirm Failed: Serial numbers count mismatch. Expected: " + totalRequired + ", Got: " + (serials == null ? 0 : serials.size()));
                conn.rollback();
                return false;
            }

            // 2. Process each item: check stock, subtract stock, save unit_cost snapshot, write Product_Ledger
            for (ExportTicketDetail d : details) {
                int productId = d.getProductId();
                int issueQty = d.getQuantity();

                // Find the serials belonging to this product from the passed list
                List<String> productSerials = new ArrayList<>();
                for (String s : serials) {
                    String checkQuery = "SELECT count(*) FROM Product_Items WHERE serial_number = ? AND product_id = ? AND status = 'IN_STOCK'";
                    try (PreparedStatement psCheck = conn.prepareStatement(checkQuery)) {
                        psCheck.setString(1, s);
                        psCheck.setInt(2, productId);
                        try (ResultSet rs = psCheck.executeQuery()) {
                            if (rs.next() && rs.getInt(1) > 0) {
                                productSerials.add(s);
                            }
                        }
                    }
                }

                if (productSerials.size() != issueQty) {
                    System.err.println("Confirm Failed: Scanned serials for product ID " + productId + " are invalid or count does not match " + issueQty);
                    conn.rollback();
                    return false;
                }

                // Lock and retrieve current inventory stock
                int currentQty = 0;
                String qStock = "SELECT quantity FROM Inventories WHERE product_id = ? FOR UPDATE";
                try (PreparedStatement psStock = conn.prepareStatement(qStock)) {
                    psStock.setInt(1, productId);
                    try (ResultSet rsStock = psStock.executeQuery()) {
                        if (rsStock.next()) {
                            currentQty = rsStock.getInt("quantity");
                        }
                    }
                }

                // Inventory check: prevent negative stock
                if (currentQty < issueQty) {
                    System.err.println("Confirm Failed: Insufficient stock for product ID " + productId + ". Available: " + currentQty + ", Requested: " + issueQty);
                    conn.rollback();
                    return false;
                }

                // Fetch current average cost to record as snapshot unit_cost
                double averageCost = 0.00;
                String qAvg = "SELECT average_cost FROM Products WHERE id = ?";
                try (PreparedStatement psAvg = conn.prepareStatement(qAvg)) {
                    psAvg.setInt(1, productId);
                    try (ResultSet rsAvg = psAvg.executeQuery()) {
                        if (rsAvg.next()) {
                            averageCost = rsAvg.getDouble("average_cost");
                        }
                    }
                }

                // Subtract stock
                int newQty = currentQty - issueQty;
                String uInv = "UPDATE Inventories SET quantity = ? WHERE product_id = ?";
                try (PreparedStatement psUInv = conn.prepareStatement(uInv)) {
                    psUInv.setInt(1, newQty);
                    psUInv.setInt(2, productId);
                    psUInv.executeUpdate();
                }

                // Save snapshot cost
                String uDetailCost = "UPDATE Export_Ticket_Details SET unit_cost = ? WHERE ticket_id = ? AND product_id = ?";
                try (PreparedStatement psCost = conn.prepareStatement(uDetailCost)) {
                    psCost.setDouble(1, averageCost);
                    psCost.setInt(2, ticketId);
                    psCost.setInt(3, productId);
                    psCost.executeUpdate();
                }

                // Update status of serials to EXPORTED and set export_ticket_id
                String uSerial = "UPDATE Product_Items SET status = 'EXPORTED', export_ticket_id = ? WHERE serial_number = ?";
                try (PreparedStatement psUSerial = conn.prepareStatement(uSerial)) {
                    for (String s : productSerials) {
                        psUSerial.setInt(1, ticketId);
                        psUSerial.setString(2, s);
                        psUSerial.executeUpdate();
                    }
                }

                // Write Product Ledger (Audit trail)
                String insLedger = "INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by) "
                                 + "VALUES (?, 'EXPORT', ?, ?, ?, ?)";
                try (PreparedStatement psL = conn.prepareStatement(insLedger)) {
                    psL.setInt(1, productId);
                    psL.setInt(2, ticketId);
                    psL.setInt(3, -issueQty); // negative for exports
                    psL.setInt(4, newQty);
                    psL.setInt(5, ticket.getKeeperId());
                    psL.executeUpdate();
                }
            }

            // 3. Update Export_Tickets status
            String uTicket = "UPDATE Export_Tickets SET status = 'CONFIRMED', confirmed_by = ?, confirmed_at = CURRENT_TIMESTAMP WHERE id = ?";
            try (PreparedStatement psUTicket = conn.prepareStatement(uTicket)) {
                psUTicket.setInt(1, confirmedBy);
                psUTicket.setInt(2, ticketId);
                psUTicket.executeUpdate();
            }

            // 4. Update Export_Requests status
            int requestId = ticket.getRequestId();
            
            // Get Request details
            String reqItemsQuery = "SELECT product_id, quantity FROM Export_Request_Details WHERE request_id = ?";
            List<Integer> reqProductIds = new ArrayList<>();
            List<Integer> reqQuantities = new ArrayList<>();
            try (PreparedStatement psReq = conn.prepareStatement(reqItemsQuery)) {
                psReq.setInt(1, requestId);
                try (ResultSet rsReq = psReq.executeQuery()) {
                    while (rsReq.next()) {
                        reqProductIds.add(rsReq.getInt("product_id"));
                        reqQuantities.add(rsReq.getInt("quantity"));
                    }
                }
            }

            boolean allCompleted = true;
            for (int i = 0; i < reqProductIds.size(); i++) {
                int pId = reqProductIds.get(i);
                int requestedQty = reqQuantities.get(i);

                // Sum confirmed issued quantities for this product
                String sumQuery = "SELECT COALESCE(SUM(td.quantity), 0) AS total_issued "
                                + "FROM Export_Ticket_Details td "
                                + "JOIN Export_Tickets t ON td.ticket_id = t.id "
                                + "WHERE t.request_id = ? AND td.product_id = ? AND t.status = 'CONFIRMED'";
                int totalIssued = 0;
                try (PreparedStatement psSum = conn.prepareStatement(sumQuery)) {
                    psSum.setInt(1, requestId);
                    psSum.setInt(2, pId);
                    try (ResultSet rsSum = psSum.executeQuery()) {
                        if (rsSum.next()) {
                            totalIssued = rsSum.getInt("total_issued");
                        }
                    }
                }

                if (totalIssued < requestedQty) {
                    allCompleted = false;
                }
            }

            String newRequestStatus = "APPROVED";
            if (allCompleted) {
                newRequestStatus = "COMPLETED";
            }

            String uRequest = "UPDATE Export_Requests SET status = ? WHERE id = ?";
            try (PreparedStatement psUReq = conn.prepareStatement(uRequest)) {
                psUReq.setString(1, newRequestStatus);
                psUReq.setInt(2, requestId);
                psUReq.executeUpdate();
            }

            // 5. Insert System Log
            String insLog = "INSERT INTO System_Logs (user_id, action, details) VALUES (?, 'CONFIRM_GIN', ?)";
            try (PreparedStatement psLog = conn.prepareStatement(insLog)) {
                psLog.setInt(1, confirmedBy);
                psLog.setString(2, "Confirmed GIN: " + ticket.getTicketCode() + " for Export Request: " + ticket.getRequestCode());
                psLog.executeUpdate();
            }

            conn.commit();
            return true;
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

    public boolean cancelTicket(int ticketId) {
        String query = "UPDATE Export_Tickets SET status = 'CANCELLED' WHERE id = ? AND status = 'DRAFT'";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
