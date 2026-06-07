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
    
    public boolean addImportTicket(ImportTicket ticket, List<ImportTicketDetail> details) {
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            // 1. Generate unique ticketCode: TKT-[YEAR]-[RANDOM_4_DIGIT] or sequence
            Calendar cal = Calendar.getInstance();
            int year = cal.get(Calendar.YEAR);
            String code = "TKT-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
            
            // Validate code uniqueness
            boolean isUnique = false;
            int retries = 0;
            while (!isUnique && retries < 5) {
                String checkQuery = "SELECT COUNT(*) FROM Import_Tickets WHERE ticket_code = ?";
                try (PreparedStatement psCheck = conn.prepareStatement(checkQuery)) {
                    psCheck.setString(1, code);
                    try (ResultSet rsCheck = psCheck.executeQuery()) {
                        if (rsCheck.next() && rsCheck.getInt(1) == 0) {
                            isUnique = true;
                        } else {
                            code = "TKT-" + year + "-" + String.format("%04d", (int)(Math.random() * 10000));
                            retries++;
                        }
                    }
                }
            }

            // 2. Insert into Import_Tickets
            String insertTicket = "INSERT INTO Import_Tickets (ticket_code, request_id, keeper_id, status) "
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

            // 3. Insert into Import_Ticket_Details
            if (ticketId > 0) {
                String insertDetail = "INSERT INTO Import_Ticket_Details (ticket_id, product_id, quantity, unit_price) "
                                    + "VALUES (?, ?, ?, ?)";
                try (PreparedStatement psd = conn.prepareStatement(insertDetail)) {
                    for (ImportTicketDetail d : details) {
                        psd.setInt(1, ticketId);
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
    
    public boolean cancelTicket(int id) {
        String query = "UPDATE Import_Tickets SET status = 'CANCELLED' WHERE id = ? AND status = 'DRAFT'";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean confirmTicket(int ticketId, int confirmedBy) {
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false);

            // 1. Fetch ticket details
            ImportTicket ticket = getImportTicketById(ticketId);
            if (ticket == null || !"DRAFT".equals(ticket.getStatus())) {
                conn.rollback();
                return false;
            }
            List<ImportTicketDetail> details = getImportTicketDetails(ticketId, conn);

            // 2. Process each item: update Inventory, recalculate Average Cost, write Product_Ledger
            for (ImportTicketDetail d : details) {
                int productId = d.getProductId();
                int recQty = d.getQuantity();
                double recPrice = d.getUnitPrice();

                // Fetch current stock
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

                // Fetch current average cost
                double currentAvg = 0.00;
                String qAvg = "SELECT average_cost FROM Products WHERE id = ? FOR UPDATE";
                try (PreparedStatement psAvg = conn.prepareStatement(qAvg)) {
                    psAvg.setInt(1, productId);
                    try (ResultSet rsAvg = psAvg.executeQuery()) {
                        if (rsAvg.next()) {
                            currentAvg = rsAvg.getDouble("average_cost");
                        }
                    }
                }

                // Recalculate Average Cost: (oldQty * oldAvg + newQty * newPrice) / (oldQty + newQty)
                int newQty = currentQty + recQty;
                double newAvg = currentAvg;
                if (newQty > 0) {
                    newAvg = (currentQty * currentAvg + recQty * recPrice) / newQty;
                }

                // Update Inventories
                String uInv = "UPDATE Inventories SET quantity = ? WHERE product_id = ?";
                try (PreparedStatement psUInv = conn.prepareStatement(uInv)) {
                    psUInv.setInt(1, newQty);
                    psUInv.setInt(2, productId);
                    psUInv.executeUpdate();
                }

                // Update Products Average Cost
                String uProd = "UPDATE Products SET average_cost = ? WHERE id = ?";
                try (PreparedStatement psUProd = conn.prepareStatement(uProd)) {
                    psUProd.setDouble(1, newAvg);
                    psUProd.setInt(2, productId);
                    psUProd.executeUpdate();
                }

                // Write Product Ledger (Audit trail)
                String insLedger = "INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by) "
                                 + "VALUES (?, 'IMPORT', ?, ?, ?, ?)";
                try (PreparedStatement psL = conn.prepareStatement(insLedger)) {
                    psL.setInt(1, productId);
                    psL.setInt(2, ticketId);
                    psL.setInt(3, recQty);
                    psL.setInt(4, newQty);
                    psL.setInt(5, ticket.getKeeperId());
                    psL.executeUpdate();
                }

                // Generate and insert Product Items (Serial Numbers)
                ProductItemDAO itemDAO = new ProductItemDAO();
                itemDAO.addProductItems(productId, ticketId, recQty, d.getSku(), conn);
            }

            // 3. Update Import_Tickets status
            String uTicket = "UPDATE Import_Tickets SET status = 'CONFIRMED', confirmed_by = ?, confirmed_at = CURRENT_TIMESTAMP WHERE id = ?";
            try (PreparedStatement psUTicket = conn.prepareStatement(uTicket)) {
                psUTicket.setInt(1, confirmedBy);
                psUTicket.setInt(2, ticketId);
                psUTicket.executeUpdate();
            }

            // 4. Update Import_Requests (PO) status
            int requestId = ticket.getRequestId();
            
            // Get PO Items
            String poItemsQuery = "SELECT product_id, quantity FROM Import_Request_Details WHERE request_id = ?";
            List<Integer> poProductIds = new ArrayList<>();
            List<Integer> poRequestedQtys = new ArrayList<>();
            try (PreparedStatement psPO = conn.prepareStatement(poItemsQuery)) {
                psPO.setInt(1, requestId);
                try (ResultSet rsPO = psPO.executeQuery()) {
                    while (rsPO.next()) {
                        poProductIds.add(rsPO.getInt("product_id"));
                        poRequestedQtys.add(rsPO.getInt("quantity"));
                    }
                }
            }

            boolean allCompleted = true;
            boolean anyReceived = false;

            for (int i = 0; i < poProductIds.size(); i++) {
                int pId = poProductIds.get(i);
                int reqQty = poRequestedQtys.get(i);

                // Sum confirmed received quantities for this product
                String sumQuery = "SELECT COALESCE(SUM(td.quantity), 0) AS total_received "
                                + "FROM Import_Ticket_Details td "
                                + "JOIN Import_Tickets t ON td.ticket_id = t.id "
                                + "WHERE t.request_id = ? AND td.product_id = ? AND t.status = 'CONFIRMED'";
                int totalReceived = 0;
                try (PreparedStatement psSum = conn.prepareStatement(sumQuery)) {
                    psSum.setInt(1, requestId);
                    psSum.setInt(2, pId);
                    try (ResultSet rsSum = psSum.executeQuery()) {
                        if (rsSum.next()) {
                            totalReceived = rsSum.getInt("total_received");
                        }
                    }
                }

                if (totalReceived > 0) {
                    anyReceived = true;
                }
                if (totalReceived < reqQty) {
                    allCompleted = false;
                }
            }

            String newPOStatus = "APPROVED";
            if (allCompleted) {
                newPOStatus = "COMPLETED";
            }

            String uPO = "UPDATE Import_Requests SET status = ? WHERE id = ?";
            try (PreparedStatement psUPO = conn.prepareStatement(uPO)) {
                psUPO.setString(1, newPOStatus);
                psUPO.setInt(2, requestId);
                psUPO.executeUpdate();
            }

            // 5. Insert System Log
            String insLog = "INSERT INTO System_Logs (user_id, action, details) VALUES (?, 'CONFIRM_GRN', ?)";
            try (PreparedStatement psLog = conn.prepareStatement(insLog)) {
                psLog.setInt(1, confirmedBy);
                psLog.setString(2, "Confirmed GRN: " + ticket.getTicketCode() + " for PO: " + ticket.getRequestCode());
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
