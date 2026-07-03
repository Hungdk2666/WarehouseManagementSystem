package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.LinkedHashSet;
import java.util.List;
import model.Request;
import model.Ticket;
import model.TicketDetail;
import utils.DBUtils;

/**
 * Gộp Import_Ticket + Export_Ticket DAO.
 * confirm() phân nhánh theo type IN/OUT:
 * - IN: sinh serial, cộng tồn, cập nhật average_cost (nếu reason=PURCHASE),
 * nếu IN-TRANSFER thì cập nhật OUT-TRANSFER ticket đối ứng → COMPLETED.
 * - OUT: nhận serials, trừ tồn, mark IN_TRANSIT (TRANSFER) hoặc EXPORTED.
 * Nếu OUT-TRANSFER: tự sinh Request IN-TRANSFER bên kho đích (APPROVED).
 */
public class TicketDAO {

    private final NotificationDAO notificationDAO = new NotificationDAO();
    private final AuditLogDAO auditLogDAO = new AuditLogDAO();
    private final RequestDAO requestDAO = new RequestDAO();
    private final ProductItemDAO productItemDAO = new ProductItemDAO();

    private static final String BASE_SELECT = "SELECT t.*, "
            + "r.request_code, r.reason AS req_reason, r.requested_condition, r.partner_type, r.partner_id, r.staff_id AS req_staff_id, "
            + "w.warehouse_name, "
            + "k.full_name AS keeper_name, "
            + "c.full_name AS confirmed_by_name, "
            + "CASE r.partner_type "
            + "  WHEN 'SUPPLIER'      THEN (SELECT supplier_name    FROM Suppliers            WHERE id = r.partner_id) "
            + "  WHEN 'CUSTOMER'      THEN (SELECT customer_name    FROM Customers            WHERE id = r.partner_id) "
            + "  WHEN 'WAREHOUSE'     THEN (SELECT warehouse_name   FROM Warehouses           WHERE id = r.partner_id) "
            + "  WHEN 'INTERNAL_DEST' THEN (SELECT destination_name FROM Internal_Destinations WHERE id = r.partner_id) "
            + "  ELSE NULL END AS partner_name "
            + "FROM Tickets t "
            + "JOIN Requests r ON r.id = t.request_id "
            + "JOIN Warehouses w ON w.id = t.warehouse_id "
            + "JOIN Users k ON k.id = t.keeper_id "
            + "LEFT JOIN Users c ON c.id = t.confirmed_by ";

    private Ticket mapRow(ResultSet rs) throws Exception {
        Ticket t = new Ticket();
        t.setId(rs.getInt("id"));
        t.setTicketCode(rs.getString("ticket_code"));
        t.setType(rs.getString("type"));
        t.setRequestId(rs.getInt("request_id"));
        t.setWarehouseId(rs.getInt("warehouse_id"));
        t.setKeeperId(rs.getInt("keeper_id"));
        t.setStatus(rs.getString("status"));
        t.setReturnStatus(rs.getString("return_status"));
        t.setCreatedAt(rs.getTimestamp("created_at"));
        t.setConfirmedBy((Integer) rs.getObject("confirmed_by"));
        t.setConfirmedAt(rs.getTimestamp("confirmed_at"));
        t.setWarehouseName(rs.getString("warehouse_name"));
        t.setKeeperFullName(rs.getString("keeper_name"));
        t.setConfirmedByFullName(rs.getString("confirmed_by_name"));
        t.setRequestCode(rs.getString("request_code"));
        t.setRequestReason(rs.getString("req_reason"));
        t.setRequestedCondition(rs.getString("requested_condition"));
        t.setPartnerName(rs.getString("partner_name"));
        return t;
    }

    private TicketDetail mapDetail(ResultSet rs) throws Exception {
        TicketDetail d = new TicketDetail();
        d.setTicketId(rs.getInt("ticket_id"));
        d.setProductId(rs.getInt("product_id"));
        d.setQuantity(rs.getInt("quantity"));
        d.setUnitCost(rs.getBigDecimal("unit_cost"));
        d.setProductName(rs.getString("product_name"));
        d.setSku(rs.getString("sku"));
        d.setUnit(rs.getString("unit"));
        return d;
    }

    // ============================================================
    // READ
    // ============================================================
    public List<Ticket> getAll(String type) {
        List<Ticket> list = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn
                        .prepareStatement(BASE_SELECT + "WHERE t.type = ? ORDER BY t.created_at DESC")) {
            ps.setString(1, type);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public Ticket getById(int id) {
        Ticket t = null;
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(BASE_SELECT + "WHERE t.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    t = mapRow(rs);
            }
            if (t != null)
                t.setDetails(getDetailsByTicketId(id, conn));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return t;
    }

    public List<Ticket> getByRequestId(int requestId) {
        List<Ticket> list = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn
                        .prepareStatement(BASE_SELECT + "WHERE t.request_id = ? ORDER BY t.created_at DESC")) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Phiếu OUT đã xuất kho (CONFIRMED/IN_TRANSIT) — để tạo Return Request. */
    public List<Ticket> getDispatchedOutTickets() {
        List<Ticket> list = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(
                        BASE_SELECT
                                + "WHERE t.type = 'OUT' AND t.status IN ('CONFIRMED','IN_TRANSIT','COMPLETED') ORDER BY t.confirmed_at DESC")) {
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Detail của 1 ticket — public version cho Servlet/JSP. */
    public List<TicketDetail> getDetailsByTicketId(int ticketId) {
        try (Connection conn = DBUtils.getConnection()) {
            return getDetailsByTicketId(ticketId, conn);
        } catch (Exception e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }

    /**
     * Phiếu OUT-TRANSFER đang IN_TRANSIT có kho đích = warehouseId (vẫn còn dùng
     * cho UI list).
     */
    public List<Ticket> getIncomingTransfersForWarehouse(int warehouseId) {
        List<Ticket> list = new ArrayList<>();
        String sql = BASE_SELECT
                + "WHERE t.type = 'OUT' AND t.status = 'IN_TRANSIT' "
                + "  AND r.reason = 'TRANSFER' AND r.partner_id = ? "
                + "ORDER BY t.confirmed_at DESC";
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<TicketDetail> getDetailsByTicketId(int ticketId, Connection conn) throws Exception {
        List<TicketDetail> list = new ArrayList<>();
        String sql = "SELECT d.*, p.product_name, p.sku, p.unit "
                + "FROM Ticket_Details d JOIN Products p ON p.id = d.product_id "
                + "WHERE d.ticket_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapDetail(rs));
            }
        }
        return list;
    }

    // ============================================================
    // CREATE (draft)
    // ============================================================
    public boolean add(Ticket ticket, List<TicketDetail> details) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Lock parent request
                try (PreparedStatement psLock = conn.prepareStatement(
                        "SELECT id, type, status FROM Requests WHERE id = ? FOR UPDATE")) {
                    psLock.setInt(1, ticket.getRequestId());
                    try (ResultSet rs = psLock.executeQuery()) {
                        if (!rs.next()) {
                            conn.rollback();
                            return false;
                        }
                        ticket.setType(rs.getString("type"));
                    }
                }

                // Validate quantity not exceeding requested
                for (TicketDetail d : details) {
                    int requestedQty = 0, activeQty = 0;
                    try (PreparedStatement ps = conn.prepareStatement(
                            "SELECT (SELECT quantity FROM Request_Details WHERE request_id = ? AND product_id = ?) AS req_qty, "
                                    + "COALESCE((SELECT SUM(td.quantity) FROM Ticket_Details td "
                                    + "          JOIN Tickets t ON td.ticket_id = t.id "
                                    + "          WHERE t.request_id = ? AND td.product_id = ? "
                                    + "                AND t.status IN ('DRAFT','CONFIRMED','IN_TRANSIT','COMPLETED')), 0) AS act_qty")) {
                        ps.setInt(1, ticket.getRequestId());
                        ps.setInt(2, d.getProductId());
                        ps.setInt(3, ticket.getRequestId());
                        ps.setInt(4, d.getProductId());
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                requestedQty = rs.getInt("req_qty");
                                activeQty = rs.getInt("act_qty");
                            }
                        }
                    }
                    if (activeQty + d.getQuantity() > requestedQty) {
                        conn.rollback();
                        return false;
                    }
                }

                String code = generateUniqueCode(ticket.getType(), conn);
                int newId;
                String insT = "INSERT INTO Tickets (ticket_code, type, request_id, warehouse_id, keeper_id, status) "
                        + "VALUES (?, ?, ?, ?, ?, 'DRAFT')";
                try (PreparedStatement ps = conn.prepareStatement(insT, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, code);
                    ps.setString(2, ticket.getType());
                    ps.setInt(3, ticket.getRequestId());
                    ps.setInt(4, ticket.getWarehouseId());
                    ps.setInt(5, ticket.getKeeperId());
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) {
                            conn.rollback();
                            return false;
                        }
                        newId = keys.getInt(1);
                        ticket.setId(newId);
                        ticket.setTicketCode(code);
                    }
                }

                String insD = "INSERT INTO Ticket_Details (ticket_id, product_id, quantity, unit_cost) "
                        + "VALUES (?, ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insD)) {
                    for (TicketDetail d : details) {
                        ps.setInt(1, newId);
                        ps.setInt(2, d.getProductId());
                        ps.setInt(3, d.getQuantity());
                        if (d.getUnitCost() != null)
                            ps.setBigDecimal(4, d.getUnitCost());
                        else
                            ps.setBigDecimal(4, java.math.BigDecimal.ZERO);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                auditLogDAO.log(ticket.getKeeperId(),
                        ticket.isIn() ? "CREATE_TICKET_IN" : "CREATE_TICKET_OUT",
                        "Phiếu " + code);
                conn.commit();
                return true;
            } catch (Exception ex) {
                conn.rollback();
                ex.printStackTrace();
                return false;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ============================================================
    // CANCEL (draft only)
    // ============================================================
    public boolean cancel(int ticketId) {
        try (Connection conn = DBUtils.getConnection();
                PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Tickets SET status='CANCELLED' WHERE id = ? AND status = 'DRAFT'")) {
            ps.setInt(1, ticketId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ============================================================
    // CONFIRM
    // ============================================================
    public boolean confirm(int ticketId, int confirmedBy) {
        return confirm(ticketId, confirmedBy, null, null);
    }

    public boolean confirm(int ticketId, int confirmedBy, List<String> serials) {
        return confirm(ticketId, confirmedBy, serials, null);
    }

    public boolean confirm(int ticketId, int confirmedBy, List<String> serials,
                           java.util.Map<String, java.util.List<String>> manufacturerSerialsBySku) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Lock ticket
                Ticket ticket = lockTicketForUpdate(ticketId, conn);
                if (ticket == null || !Ticket.STATUS_DRAFT.equals(ticket.getStatus())) {
                    conn.rollback();
                    return false;
                }

                // Load parent request (lock too)
                Request req = lockRequestForUpdate(ticket.getRequestId(), conn);
                if (req == null) {
                    conn.rollback();
                    return false;
                }

                // Request phải đang APPROVED hoặc PARTIALLY_COMPLETED
                if (!Request.STATUS_APPROVED.equals(req.getStatus())
                        && !Request.STATUS_PARTIALLY_COMPLETED.equals(req.getStatus())) {
                    conn.rollback();
                    return false;
                }

                // Chặn confirm khi kho đang kiểm kê
                if (new StocktakeDAO().isWarehouseFrozen(ticket.getWarehouseId())) {
                    conn.rollback();
                    return false;
                }

                List<TicketDetail> details = getDetailsByTicketId(ticketId, conn);

                boolean ok = ticket.isIn()
                        ? processConfirmIn(ticket, req, details, confirmedBy, serials, manufacturerSerialsBySku, conn)
                        : processConfirmOut(ticket, req, details, confirmedBy, serials, conn);

                if (!ok) {
                    conn.rollback();
                    return false;
                }
                conn.commit();
                return true;
            } catch (Exception ex) {
                conn.rollback();
                ex.printStackTrace();
                return false;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ============================================================
    // IN confirm — sinh serial, cộng tồn, update avg cost
    // ============================================================
    private boolean processConfirmIn(Ticket ticket, Request req, List<TicketDetail> details,
            int confirmedBy, List<String> serials,
            java.util.Map<String, java.util.List<String>> manufacturerSerialsBySku, Connection conn) throws Exception {

        boolean isReturn = Request.REASON_RETURN.equals(req.getReason());
        boolean isTransfer = Request.REASON_TRANSFER.equals(req.getReason());

        for (TicketDetail d : details) {
            int productId = d.getProductId();
            int recQty = d.getQuantity();
            double recPrice = d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0;
            String condition = req.getRequestedCondition() != null ? req.getRequestedCondition() : "NEW";
            boolean isDamaged = "DAMAGED".equals(condition);

            // Lock current inventory
            int currentQty = 0;
            int currentQuarantineQty = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT quantity, quarantine_quantity FROM Inventories WHERE product_id = ? AND warehouse_id = ? FOR UPDATE")) {
                ps.setInt(1, productId);
                ps.setInt(2, ticket.getWarehouseId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentQty = rs.getInt("quantity");
                        currentQuarantineQty = rs.getInt("quarantine_quantity");
                    }
                }
            }

            double currentAvg = 0.00;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT average_cost FROM Products WHERE id = ? FOR UPDATE")) {
                ps.setInt(1, productId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next())
                        currentAvg = rs.getDouble("average_cost");
                }
            }

            int newQty = isDamaged ? currentQty : (currentQty + recQty);
            int newQuarantineQty = isDamaged ? (currentQuarantineQty + recQty) : currentQuarantineQty;
            int totalPhysicalQty = currentQty + currentQuarantineQty;
            int newTotalPhysicalQty = newQty + newQuarantineQty;

            double newAvg = currentAvg;
            // Chỉ PURCHASE cập nhật average_cost
            if (!isReturn && !isTransfer && recPrice > 0 && newTotalPhysicalQty > 0) {
                newAvg = (totalPhysicalQty * currentAvg + recQty * recPrice) / newTotalPhysicalQty;
            }

            // Update inventory
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Inventories (warehouse_id, product_id, quantity, quarantine_quantity) VALUES (?, ?, ?, ?) "
                            + "ON DUPLICATE KEY UPDATE quantity = ?, quarantine_quantity = ?")) {
                ps.setInt(1, ticket.getWarehouseId());
                ps.setInt(2, productId);
                ps.setInt(3, newQty);
                ps.setInt(4, newQuarantineQty);
                ps.setInt(5, newQty);
                ps.setInt(6, newQuarantineQty);
                ps.executeUpdate();
            }

            if (!isReturn && !isTransfer) {
                try (PreparedStatement ps = conn
                        .prepareStatement("UPDATE Products SET average_cost = ? WHERE id = ?")) {
                    ps.setDouble(1, newAvg);
                    ps.setInt(2, productId);
                    ps.executeUpdate();
                }
            }

            // Ledger
            String ledgerType = isReturn ? "RETURN" : (isTransfer ? "TRANSFER_IN" : "IMPORT");
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by, warehouse_id) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?)")) {
                ps.setInt(1, productId);
                ps.setString(2, ledgerType);
                ps.setInt(3, ticket.getId());
                ps.setInt(4, recQty);
                ps.setInt(5, newTotalPhysicalQty);
                ps.setInt(6, confirmedBy);
                ps.setInt(7, ticket.getWarehouseId());
                ps.executeUpdate();
            }

            if (isTransfer && req.getRefTicketId() != null) {
                // IN-TRANSFER: lấy đúng `recQty` Product_Items đang IN_TRANSIT từ OUT đối ứng
                // (nếu user chỉ nhận một phần, không flip tất cả)
                Integer outTicketId = req.getRefTicketId();
                List<Integer> itemIds = new ArrayList<>();
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT pi.id FROM Product_Items pi "
                                + "JOIN Product_Item_Movements m ON m.product_item_id = pi.id "
                                + "WHERE m.ticket_id = ? AND m.action = 'TRANSFER_OUT' "
                                + "  AND pi.product_id = ? AND pi.status = 'IN_TRANSIT' "
                                + "ORDER BY pi.id LIMIT ? FOR UPDATE")) {
                    ps.setInt(1, outTicketId);
                    ps.setInt(2, productId);
                    ps.setInt(3, recQty);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next())
                            itemIds.add(rs.getInt(1));
                    }
                }
                if (itemIds.size() < recQty) {
                    // Không đủ hàng IN_TRANSIT để nhận → từ chối
                    return false;
                }
                // Update: chỉ những item trong itemIds
                String newStatus = isDamaged ? "QUARANTINE" : "IN_STOCK";
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Product_Items SET status = ?, warehouse_id = ?, item_condition = ? WHERE id = ?")) {
                    for (int itemId : itemIds) {
                        ps.setString(1, newStatus);
                        ps.setInt(2, ticket.getWarehouseId());
                        ps.setString(3, condition);
                        ps.setInt(4, itemId);
                        ps.executeUpdate();
                    }
                }
                // Sinh TRANSFER_IN movement cho đúng các item này
                String insMov = "INSERT INTO Product_Item_Movements "
                        + "(product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_by) "
                        + "VALUES (?, ?, 'TRANSFER_IN', ?, ?, ?, ?)";
                try (PreparedStatement ps = conn.prepareStatement(insMov)) {
                    for (int itemId : itemIds) {
                        ps.setInt(1, itemId);
                        ps.setInt(2, ticket.getId());
                        ps.setInt(3, req.getPartnerId()); // kho nguồn
                        ps.setInt(4, ticket.getWarehouseId()); // kho đích
                        ps.setString(5, condition);
                        ps.setInt(6, confirmedBy);
                        ps.executeUpdate();
                    }
                }
            } else if (isReturn) {
                // RETURN: user must provide scanned serials
                if (serials == null || serials.isEmpty())
                    return false;
                List<String> expectedSerialsList = new ArrayList<>();
                String expectedSerialsStr = req.getExpectedSerials();
                if (expectedSerialsStr != null && !expectedSerialsStr.trim().isEmpty()) {
                    for (String es : expectedSerialsStr.split(",")) {
                        if (es != null && !es.trim().isEmpty()) expectedSerialsList.add(es.trim());
                    }
                }

                List<String> productSerials = new ArrayList<>();
                for (String s : serials) {
                    if (!expectedSerialsList.contains(s)) continue;
                    try (PreparedStatement ps = conn.prepareStatement(
                            "SELECT COUNT(*) FROM Product_Items WHERE serial_number = ? AND product_id = ? AND status = 'EXPORTED'")) {
                        ps.setString(1, s);
                        ps.setInt(2, productId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next() && rs.getInt(1) > 0)
                                productSerials.add(s);
                        }
                    }
                }
                if (productSerials.size() != recQty)
                    return false;

                String newStatus = isDamaged ? "QUARANTINE" : "IN_STOCK";
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Product_Items SET status = ?, warehouse_id = ?, item_condition = ? WHERE serial_number = ?")) {
                    for (String s : productSerials) {
                        ps.setString(1, newStatus);
                        ps.setInt(2, ticket.getWarehouseId());
                        ps.setString(3, condition);
                        ps.setString(4, s);
                        ps.executeUpdate();
                    }
                }

                String movSql = "INSERT INTO Product_Item_Movements "
                        + "(product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_by) "
                        + "VALUES ((SELECT id FROM Product_Items WHERE serial_number = ?), ?, 'RETURN_IN', NULL, ?, "
                        + " (SELECT item_condition FROM Product_Items WHERE serial_number = ?), ?)";
                try (PreparedStatement ps = conn.prepareStatement(movSql)) {
                    for (String s : productSerials) {
                        ps.setString(1, s);
                        ps.setInt(2, ticket.getId());
                        ps.setInt(3, ticket.getWarehouseId());
                        ps.setString(4, s);
                        ps.setInt(5, confirmedBy);
                        ps.executeUpdate();
                    }
                }

                // Remove used serials from list to prevent matching in next iteration if
                // duplicate products (though shouldn't happen)
                serials.removeAll(productSerials);

            } else {
                // PURCHASE: sinh serial mới + gắn serial NSX nếu có
                String skuKey = d.getSku() != null ? d.getSku() : ("P" + productId);
                java.util.List<String> mfrSerials = (manufacturerSerialsBySku != null)
                        ? manufacturerSerialsBySku.get(skuKey) : null;
                List<String> newSerials = productItemDAO.addProductItemsAndReturnSerials(
                        productId, ticket.getId(), recQty, skuKey,
                        ticket.getWarehouseId(), condition, mfrSerials, conn);

                String movSql = "INSERT INTO Product_Item_Movements "
                        + "(product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_by) "
                        + "VALUES ((SELECT id FROM Product_Items WHERE serial_number = ?), ?, 'IMPORT_IN', NULL, ?, "
                        + " (SELECT item_condition FROM Product_Items WHERE serial_number = ?), ?)";
                try (PreparedStatement ps = conn.prepareStatement(movSql)) {
                    for (String s : newSerials) {
                        ps.setString(1, s);
                        ps.setInt(2, ticket.getId());
                        ps.setInt(3, ticket.getWarehouseId());
                        ps.setString(4, s);
                        ps.setInt(5, confirmedBy);
                        ps.executeUpdate();
                    }
                }
            }
        }

        // Update ticket status → CONFIRMED
        updateTicketStatus(ticket.getId(), Ticket.STATUS_CONFIRMED, confirmedBy, conn);

        // Update parent request status
        rollupRequestStatus(req, conn);

        // Nếu IN-TRANSFER: đánh dấu Ticket OUT đối ứng → COMPLETED
        if (Request.REASON_TRANSFER.equals(req.getReason()) && req.getRefTicketId() != null) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Tickets SET status = 'COMPLETED' WHERE id = ? AND status = 'IN_TRANSIT'")) {
                ps.setInt(1, req.getRefTicketId());
                ps.executeUpdate();
            }
            // Đánh dấu Request OUT gốc → COMPLETED nếu chưa
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Requests r JOIN Tickets t ON t.request_id = r.id "
                            + "SET r.status = 'COMPLETED' WHERE t.id = ?")) {
                ps.setInt(1, req.getRefTicketId());
                ps.executeUpdate();
            }
        }

        // Audit + notification
        auditLogDAO.log(confirmedBy, "CONFIRM_TICKET_IN",
                "Phiếu " + ticket.getTicketCode() + " (Yêu cầu " + req.getRequestCode() + ")");
        if (req.getStaffId() != confirmedBy) {
            notificationDAO.createNotification(req.getStaffId(),
                    "Phiếu " + ticket.getTicketCode() + " đã được nhập kho",
                    "", "/warehouse/import-ticket?action=detail&id=" + ticket.getId(), conn);
        }
        return true;
    }

    // ============================================================
    // OUT confirm — nhận serial, trừ tồn, mark IN_TRANSIT/EXPORTED
    // Nếu OUT-TRANSFER: tự sinh Request IN-TRANSFER bên kho đích
    // ============================================================
    private boolean processConfirmOut(Ticket ticket, Request req, List<TicketDetail> details,
            int confirmedBy, List<String> serials, Connection conn) throws Exception {

        // Defensive guard: DISPOSAL đã chuyển sang module /warehouse/disposal.
        // Chặn tuyệt đối bất kỳ ticket cũ nào không được confirm qua luồng xuất kho thường
        // (luồng cũ rút hàng tốt thay vì hàng QUARANTINE → bug tồn kho).
        if (Request.REASON_DISPOSAL.equals(req.getReason())) {
            return false;
        }

        boolean isTransfer = Request.REASON_TRANSFER.equals(req.getReason());

        // Auto-pick serials nếu caller không cung cấp (test compat)
        if (serials == null) {
            serials = new ArrayList<>();
            for (TicketDetail d : details) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT serial_number FROM Product_Items "
                                + "WHERE product_id = ? AND warehouse_id = ? AND status = 'IN_STOCK' "
                                + "  AND item_condition = ? "
                                + "ORDER BY id LIMIT ?")) {
                    ps.setInt(1, d.getProductId());
                    ps.setInt(2, ticket.getWarehouseId());
                    ps.setString(3, req.getRequestedCondition() == null ? "NEW" : req.getRequestedCondition());
                    ps.setInt(4, d.getQuantity());
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next())
                            serials.add(rs.getString(1));
                    }
                }
            }
        }
        // Dedup
        List<String> deduped = new ArrayList<>(new LinkedHashSet<>(serials));

        int totalRequired = 0;
        for (TicketDetail d : details)
            totalRequired += d.getQuantity();
        if (deduped.size() != totalRequired)
            return false;

        for (TicketDetail d : details) {
            int productId = d.getProductId();
            int issueQty = d.getQuantity();

            List<String> productSerials = new ArrayList<>();
            for (String s : deduped) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM Product_Items WHERE serial_number = ? AND product_id = ? "
                                + "AND status = 'IN_STOCK' AND warehouse_id = ? AND item_condition = ?")) {
                    ps.setString(1, s);
                    ps.setInt(2, productId);
                    ps.setInt(3, ticket.getWarehouseId());
                    ps.setString(4, req.getRequestedCondition() == null ? "NEW" : req.getRequestedCondition());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next() && rs.getInt(1) > 0)
                            productSerials.add(s);
                    }
                }
            }
            if (productSerials.size() != issueQty)
                return false;

            // Lock inventory
            int currentQty = 0;
            int currentQuarantineQty = 0;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT quantity, quarantine_quantity FROM Inventories WHERE product_id = ? AND warehouse_id = ? FOR UPDATE")) {
                ps.setInt(1, productId);
                ps.setInt(2, ticket.getWarehouseId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        currentQty = rs.getInt("quantity");
                        currentQuarantineQty = rs.getInt("quarantine_quantity");
                    }
                }
            }
            if (currentQty < issueQty)
                return false;

            // Snapshot avg cost
            double avgCost = 0.00;
            try (PreparedStatement ps = conn.prepareStatement("SELECT average_cost FROM Products WHERE id = ?")) {
                ps.setInt(1, productId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next())
                        avgCost = rs.getDouble("average_cost");
                }
            }

            int newQty = currentQty - issueQty;
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Inventories SET quantity = ? WHERE product_id = ? AND warehouse_id = ?")) {
                ps.setInt(1, newQty);
                ps.setInt(2, productId);
                ps.setInt(3, ticket.getWarehouseId());
                ps.executeUpdate();
            }

            // Lưu snapshot unit_cost
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Ticket_Details SET unit_cost = ? WHERE ticket_id = ? AND product_id = ?")) {
                ps.setDouble(1, avgCost);
                ps.setInt(2, ticket.getId());
                ps.setInt(3, productId);
                ps.executeUpdate();
            }

            // Update Product_Items
            String newItemStatus = isTransfer ? "IN_TRANSIT" : "EXPORTED";
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Product_Items SET status = ? WHERE serial_number = ?")) {
                for (String s : productSerials) {
                    ps.setString(1, newItemStatus);
                    ps.setString(2, s);
                    ps.executeUpdate();
                }
            }

            // Movements
            String action = isTransfer ? "TRANSFER_OUT" : "EXPORT_OUT";
            int toWh = isTransfer ? req.getPartnerId() : ticket.getWarehouseId();
            String movSql = "INSERT INTO Product_Item_Movements "
                    + "(product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_by) "
                    + "VALUES ((SELECT id FROM Product_Items WHERE serial_number = ?), ?, ?, ?, ?, "
                    + "(SELECT item_condition FROM Product_Items WHERE serial_number = ?), ?)";
            try (PreparedStatement ps = conn.prepareStatement(movSql)) {
                for (String s : productSerials) {
                    ps.setString(1, s);
                    ps.setInt(2, ticket.getId());
                    ps.setString(3, action);
                    ps.setInt(4, ticket.getWarehouseId());
                    ps.setInt(5, toWh);
                    ps.setString(6, s);
                    ps.setInt(7, confirmedBy);
                    ps.executeUpdate();
                }
            }

            // Ledger
            int newTotalPhysicalQty = newQty + currentQuarantineQty;
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Product_Ledger (product_id, transaction_type, reference_id, change_quantity, balance_quantity, created_by, warehouse_id) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?)")) {
                ps.setInt(1, productId);
                ps.setString(2, isTransfer ? "TRANSFER_OUT" : "EXPORT");
                ps.setInt(3, ticket.getId());
                ps.setInt(4, -issueQty);
                ps.setInt(5, newTotalPhysicalQty);
                ps.setInt(6, confirmedBy);
                ps.setInt(7, ticket.getWarehouseId());
                ps.executeUpdate();
            }
        }

        // Low-stock check: cảnh báo nếu tồn kho xuống dưới min_stock
        for (TicketDetail d : details) {
            int productId = d.getProductId();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT i.quantity, p.min_stock, p.product_name, p.sku "
                    + "FROM Inventories i JOIN Products p ON p.id = i.product_id "
                    + "WHERE i.product_id = ? AND i.warehouse_id = ?")) {
                ps.setInt(1, productId);
                ps.setInt(2, ticket.getWarehouseId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int qty = rs.getInt("quantity");
                        int minStock = rs.getInt("min_stock");
                        if (qty < minStock) {
                            String pName = rs.getString("product_name");
                            String pSku = rs.getString("sku");
                            notificationDAO.createNotificationForWarehouse(ticket.getWarehouseId(),
                                    "Cảnh báo tồn kho thấp",
                                    pName + " (" + pSku + ") còn " + qty + "/" + minStock,
                                    "/warehouse/product?action=details&id=" + productId, conn);
                        }
                    }
                }
            }
        }

        // Ticket status
        String finalStatus = isTransfer ? Ticket.STATUS_IN_TRANSIT : Ticket.STATUS_CONFIRMED;
        updateTicketStatus(ticket.getId(), finalStatus, confirmedBy, conn);

        // Roll-up parent request
        rollupRequestStatus(req, conn);

        // Audit + notify
        auditLogDAO.log(confirmedBy, "CONFIRM_TICKET_OUT",
                "Phiếu " + ticket.getTicketCode() + " (Yêu cầu " + req.getRequestCode() + ")");
        if (req.getStaffId() != confirmedBy) {
            notificationDAO.createNotification(req.getStaffId(),
                    "Phiếu " + ticket.getTicketCode() + " đã xuất kho",
                    "", "/warehouse/export-ticket?action=detail&id=" + ticket.getId(), conn);
        }
        if (ticket.getKeeperId() != confirmedBy && ticket.getKeeperId() != req.getStaffId()) {
            notificationDAO.createNotification(ticket.getKeeperId(),
                    "Phiếu xuất " + ticket.getTicketCode() + " đã được xác nhận",
                    "", "/warehouse/export-ticket?action=detail&id=" + ticket.getId(), conn);
        }

        // Auto-create IN-TRANSFER request bên kho đích nếu OUT-TRANSFER
        if (isTransfer) {
            int inReqId = requestDAO.createTransferInRequest(req, ticket.getId(), conn);
            notificationDAO.createNotificationForWarehouse(req.getPartnerId(),
                    "Hàng chuyển kho đang đến",
                    "Phiếu xuất " + ticket.getTicketCode() + " từ kho " + ticket.getWarehouseId()
                            + " đang đến. Hãy tạo phiếu nhập để xác nhận nhận hàng.",
                    "/warehouse/import-request?action=detail&id=" + inReqId, conn);
        }
        return true;
    }

    // ============================================================
    // Helpers
    // ============================================================
    private Ticket lockTicketForUpdate(int id, Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id, ticket_code, type, request_id, warehouse_id, keeper_id, status "
                        + "FROM Tickets WHERE id = ? FOR UPDATE")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next())
                    return null;
                Ticket t = new Ticket();
                t.setId(rs.getInt("id"));
                t.setTicketCode(rs.getString("ticket_code"));
                t.setType(rs.getString("type"));
                t.setRequestId(rs.getInt("request_id"));
                t.setWarehouseId(rs.getInt("warehouse_id"));
                t.setKeeperId(rs.getInt("keeper_id"));
                t.setStatus(rs.getString("status"));
                return t;
            }
        }
    }

    private Request lockRequestForUpdate(int id, Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM Requests WHERE id = ? FOR UPDATE")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next())
                    return null;
                Request r = new Request();
                r.setId(rs.getInt("id"));
                r.setRequestCode(rs.getString("request_code"));
                r.setType(rs.getString("type"));
                r.setReason(rs.getString("reason"));
                r.setWarehouseId(rs.getInt("warehouse_id"));
                r.setPartnerType(rs.getString("partner_type"));
                r.setPartnerId((Integer) rs.getObject("partner_id"));
                r.setRefTicketId((Integer) rs.getObject("ref_ticket_id"));
                r.setExpectedSerials(rs.getString("expected_serials"));
                r.setStaffId(rs.getInt("staff_id"));
                r.setRequestedCondition(rs.getString("requested_condition"));
                r.setStatus(rs.getString("status"));
                r.setExpectedDate(rs.getDate("expected_date"));
                r.setApprovedBy((Integer) rs.getObject("approved_by"));
                return r;
            }
        }
    }

    private void updateTicketStatus(int ticketId, String status, int confirmedBy, Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE Tickets SET status = ?, confirmed_by = ?, confirmed_at = NOW() WHERE id = ?")) {
            ps.setString(1, status);
            ps.setInt(2, confirmedBy);
            ps.setInt(3, ticketId);
            ps.executeUpdate();
        }
    }

    /** Cập nhật status request cha dựa trên tổng quantity đã ticketing. */
    private void rollupRequestStatus(Request req, Connection conn) throws Exception {
        boolean allCompleted = true;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT product_id, quantity FROM Request_Details WHERE request_id = ?")) {
            ps.setInt(1, req.getId());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int pId = rs.getInt("product_id");
                    int reqQty = rs.getInt("quantity");
                    int doneQty = 0;
                    try (PreparedStatement ps2 = conn.prepareStatement(
                            "SELECT COALESCE(SUM(td.quantity), 0) FROM Ticket_Details td "
                                    + "JOIN Tickets t ON td.ticket_id = t.id "
                                    + "WHERE t.request_id = ? AND td.product_id = ? "
                                    + "  AND t.status IN ('CONFIRMED','IN_TRANSIT','COMPLETED')")) {
                        ps2.setInt(1, req.getId());
                        ps2.setInt(2, pId);
                        try (ResultSet rs2 = ps2.executeQuery()) {
                            if (rs2.next())
                                doneQty = rs2.getInt(1);
                        }
                    }
                    if (doneQty < reqQty) {
                        allCompleted = false;
                        break;
                    }
                }
            }
        }
        String newStatus = allCompleted ? Request.STATUS_COMPLETED : Request.STATUS_PARTIALLY_COMPLETED;
        try (PreparedStatement ps = conn.prepareStatement("UPDATE Requests SET status = ? WHERE id = ?")) {
            ps.setString(1, newStatus);
            ps.setInt(2, req.getId());
            ps.executeUpdate();
        }
    }

    // ============================================================
    // Generate unique code
    // ============================================================
    public String generateUniqueCode(String type, Connection conn) throws Exception {
        int year = Calendar.getInstance().get(Calendar.YEAR);
        String prefix = "TKT-" + (Ticket.TYPE_IN.equals(type) ? "IN-" : "OUT-") + year + "-";
        int seq = 1;
        String code;
        do {
            code = prefix + String.format("%04d", seq++);
            try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM Tickets WHERE ticket_code = ?")) {
                ps.setString(1, code);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && rs.getInt(1) == 0)
                        return code;
                }
            }
        } while (seq < 10000);
        throw new Exception("Cannot generate unique ticket code");
    }
}
