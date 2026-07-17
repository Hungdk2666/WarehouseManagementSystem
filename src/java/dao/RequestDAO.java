package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import model.Request;
import model.RequestDetail;
import utils.DBUtils;

/**
 * Gộp Import_Request + Export_Request DAO.
 * Tham số `type` ('IN' / 'OUT') quyết định luồng và filter.
 */
public class RequestDAO {

    private final NotificationDAO notificationDAO = new NotificationDAO();
    private final AuditLogDAO auditLogDAO = new AuditLogDAO();

    private static final String BASE_SELECT =
        "SELECT r.*, w.warehouse_name, rt.ticket_code AS ref_ticket_code, "
        + "u.full_name AS staff_name, "
        + "a.full_name AS approver_name, "
        + "cr.full_name AS cancel_requested_name, "
        + "cb.full_name AS cancelled_name, "
        + "CASE r.partner_type "
        + "  WHEN 'SUPPLIER'      THEN (SELECT supplier_name    FROM Suppliers            WHERE id = r.partner_id) "
        + "  WHEN 'CUSTOMER'      THEN (SELECT customer_name    FROM Customers            WHERE id = r.partner_id) "
        + "  WHEN 'WAREHOUSE'     THEN (SELECT warehouse_name   FROM Warehouses           WHERE id = r.partner_id) "
        + "  WHEN 'INTERNAL_DEST' THEN (SELECT destination_name FROM Internal_Destinations WHERE id = r.partner_id) "
        + "  ELSE NULL END AS partner_name "
        + "FROM Requests r "
        + "JOIN Warehouses w ON w.id = r.warehouse_id "
        + "LEFT JOIN Tickets rt ON rt.id = r.ref_ticket_id "
        + "JOIN Users u  ON u.id  = r.staff_id "
        + "LEFT JOIN Users a  ON a.id  = r.approved_by "
        + "LEFT JOIN Users cr ON cr.id = r.cancel_requested_by "
        + "LEFT JOIN Users cb ON cb.id = r.cancelled_by ";

    private Request mapRow(ResultSet rs) throws Exception {
        Request r = new Request();
        r.setId(rs.getInt("id"));
        r.setRequestCode(rs.getString("request_code"));
        r.setType(rs.getString("type"));
        r.setReason(rs.getString("reason"));
        r.setWarehouseId(rs.getInt("warehouse_id"));
        r.setPartnerType(rs.getString("partner_type"));
        r.setPartnerId((Integer) rs.getObject("partner_id"));
        r.setRefTicketId((Integer) rs.getObject("ref_ticket_id"));
        r.setRefTicketCode(rs.getString("ref_ticket_code"));
        r.setReturnReason(rs.getString("return_reason"));
        r.setShippingAddress(rs.getString("shipping_address"));
        r.setExpectedSerials(rs.getString("expected_serials"));
        r.setExpectedDate(rs.getDate("expected_date"));
        r.setStaffId(rs.getInt("staff_id"));
        r.setRequestedCondition(rs.getString("requested_condition"));
        r.setStatus(rs.getString("status"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        r.setApprovedBy((Integer) rs.getObject("approved_by"));
        r.setApprovedAt(rs.getTimestamp("approved_at"));
        r.setCancelRequestedBy((Integer) rs.getObject("cancel_requested_by"));
        r.setCancelRequestedAt(rs.getTimestamp("cancel_requested_at"));
        r.setCancelReason(rs.getString("cancel_reason"));
        r.setCancelledBy((Integer) rs.getObject("cancelled_by"));
        r.setCancelledAt(rs.getTimestamp("cancelled_at"));
        r.setWarehouseName(rs.getString("warehouse_name"));
        r.setPartnerName(rs.getString("partner_name"));
        r.setStaffFullName(rs.getString("staff_name"));
        r.setApprovedByFullName(rs.getString("approver_name"));
        r.setCancelRequestedByFullName(rs.getString("cancel_requested_name"));
        r.setCancelledByFullName(rs.getString("cancelled_name"));
        return r;
    }

    private RequestDetail mapDetail(ResultSet rs) throws Exception {
        RequestDetail d = new RequestDetail();
        d.setRequestId(rs.getInt("request_id"));
        d.setProductId(rs.getInt("product_id"));
        d.setQuantity(rs.getInt("quantity"));
        d.setUnitPrice(rs.getBigDecimal("unit_price"));
        d.setProductName(rs.getString("product_name"));
        d.setSku(rs.getString("sku"));
        d.setUnit(rs.getString("unit"));
        return d;
    }

    // ============================================================
    // READ
    // ============================================================
    public List<Request> getAll(String type) {
        return getAll(type, null);
    }

    /**
     * @param warehouseId nếu khác null → chỉ lấy yêu cầu của kho này.
     *                    User không được gán kho truyền null để xem toàn hệ thống.
     */
    public List<Request> getAll(String type, Integer warehouseId) {
        List<Request> list = new ArrayList<>();
        String sql = BASE_SELECT + "WHERE r.type = ? ";
        if (warehouseId != null) sql += "AND r.warehouse_id = ? ";
        sql += "ORDER BY r.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, type);
            if (warehouseId != null) ps.setInt(2, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Danh sách vận hành: ẩn yêu cầu đã kết thúc khỏi kho/admin.
     * Sales vẫn nhìn thấy các yêu cầu terminal do chính mình tạo để biết kết quả.
     */
    public List<Request> getForList(String type, Integer warehouseId, Integer ownStaffId) {
        List<Request> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(BASE_SELECT)
                .append("WHERE r.type = ? AND (r.status NOT IN ('REJECTED','REVOKED','CANCELLED') ");
        if (ownStaffId != null) {
            sql.append("OR r.staff_id = ? ");
        }
        sql.append(") ");
        if (warehouseId != null) sql.append("AND r.warehouse_id = ? ");
        sql.append("ORDER BY r.created_at DESC");
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int index = 1;
            ps.setString(index++, type);
            if (ownStaffId != null) ps.setInt(index++, ownStaffId);
            if (warehouseId != null) ps.setInt(index, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Request> getPendingOrApproved(String type) {
        return getPendingOrApproved(type, null);
    }

    /**
     * @param warehouseId nếu khác null → chỉ lấy yêu cầu của kho này (lọc theo Requests.warehouse_id).
     *                    Dùng để staff kho TPHCM không thấy yêu cầu kho HN và ngược lại.
     */
    public List<Request> getPendingOrApproved(String type, Integer warehouseId) {
        List<Request> list = new ArrayList<>();
        String sql = BASE_SELECT
                + "WHERE r.type = ? AND r.status IN ('APPROVED','PARTIALLY_COMPLETED') AND r.cancel_requested_at IS NULL ";
        if (warehouseId != null) sql += "AND r.warehouse_id = ? ";
        sql += "ORDER BY r.created_at DESC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, type);
            if (warehouseId != null) ps.setInt(2, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Request getById(int id) {
        Request req = null;
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(BASE_SELECT + "WHERE r.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) req = mapRow(rs);
            }
            if (req != null) req.setDetails(getDetailsByRequestId(id, conn));
        } catch (Exception e) { e.printStackTrace(); }
        return req;
    }

    public List<RequestDetail> getDetailsByRequestId(int requestId, Connection conn) throws Exception {
        List<RequestDetail> details = new ArrayList<>();
        // LEFT JOIN với subquery để tính processed_quantity: tổng số đã xử lý qua các Ticket
        // (status CONFIRMED / IN_TRANSIT / COMPLETED — không tính DRAFT/CANCELLED)
        String sql =
              "SELECT d.*, p.product_name, p.sku, p.unit, "
            + "       COALESCE(proc.processed_qty, 0) AS processed_qty "
            + "FROM Request_Details d "
            + "JOIN Products p ON p.id = d.product_id "
            + "LEFT JOIN ("
            + "    SELECT td.product_id, SUM(td.quantity) AS processed_qty "
            + "    FROM Ticket_Details td "
            + "    JOIN Tickets t ON t.id = td.ticket_id "
            + "    WHERE t.request_id = ? "
            + "      AND t.status IN ('CONFIRMED','IN_TRANSIT','COMPLETED') "
            + "    GROUP BY td.product_id "
            + ") proc ON proc.product_id = d.product_id "
            + "WHERE d.request_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, requestId);
            ps.setInt(2, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RequestDetail d = mapDetail(rs);
                    d.setProcessedQuantity(rs.getInt("processed_qty"));
                    details.add(d);
                }
            }
        }
        return details;
    }

    // ============================================================
    // CREATE
    // ============================================================
    public boolean add(Request req, List<RequestDetail> details) {
        String insReq = "INSERT INTO Requests "
            + "(request_code, type, reason, warehouse_id, partner_type, partner_id, ref_ticket_id, "
            + " return_reason, shipping_address, expected_serials, expected_date, staff_id, requested_condition, status) "
            + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        String insDet = "INSERT INTO Request_Details "
            + "(request_id, product_id, quantity, unit_price) VALUES (?,?,?,?)";

        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                if (req.getRequestCode() == null || req.getRequestCode().isEmpty()) {
                    req.setRequestCode(generateUniqueCode(req.getType(), conn));
                }
                int newId;
                try (PreparedStatement ps = conn.prepareStatement(insReq, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, req.getRequestCode());
                    ps.setString(2, req.getType());
                    ps.setString(3, req.getReason());
                    ps.setInt(4, req.getWarehouseId());
                    ps.setString(5, req.getPartnerType());
                    if (req.getPartnerId() != null) ps.setInt(6, req.getPartnerId()); else ps.setNull(6, Types.INTEGER);
                    if (req.getRefTicketId() != null) ps.setInt(7, req.getRefTicketId()); else ps.setNull(7, Types.INTEGER);
                    if (req.getReturnReason() != null) ps.setString(8, req.getReturnReason()); else ps.setNull(8, Types.VARCHAR);
                    if (req.getShippingAddress() != null) ps.setString(9, req.getShippingAddress()); else ps.setNull(9, Types.VARCHAR);
                    if (req.getExpectedSerials() != null) ps.setString(10, req.getExpectedSerials()); else ps.setNull(10, Types.VARCHAR);
                    if (req.getExpectedDate() != null) ps.setDate(11, req.getExpectedDate()); else ps.setNull(11, Types.DATE);
                    ps.setInt(12, req.getStaffId());
                    ps.setString(13, req.getRequestedCondition() == null ? "NEW" : req.getRequestedCondition());
                    ps.setString(14, req.getStatus() == null ? Request.STATUS_PENDING : req.getStatus());
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) { conn.rollback(); return false; }
                        newId = keys.getInt(1);
                        req.setId(newId);
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(insDet)) {
                    for (RequestDetail d : details) {
                        ps.setInt(1, newId);
                        ps.setInt(2, d.getProductId());
                        ps.setInt(3, d.getQuantity());
                        if (d.getUnitPrice() != null) ps.setBigDecimal(4, d.getUnitPrice()); else ps.setNull(4, Types.DECIMAL);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                // Audit + notification
                String actionLabel = req.isIn() ? "CREATE_REQUEST_IN" : "CREATE_REQUEST_OUT";
                auditLogDAO.log(req.getStaffId(), actionLabel, "Yêu cầu " + req.getRequestCode());

                // Notify role 2 (Business Admin) — người duyệt
                String title = req.isIn() ? "Yêu cầu nhập kho mới" : "Yêu cầu xuất kho mới";
                String msg = "Yêu cầu " + req.getRequestCode() + " đang chờ duyệt";
                String link = req.isIn() ? "/warehouse/import-request?action=detail&id=" + newId
                                         : "/warehouse/export-request?action=detail&id=" + newId;
                notificationDAO.createNotificationForRole(2, title, msg, link, conn);

                conn.commit();
                return true;
            } catch (Exception ex) {
                conn.rollback();
                ex.printStackTrace();
                return false;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ============================================================
    // APPROVE / REJECT
    // ============================================================
    public boolean updateStatus(int id, String status, int approvedBy) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Request req = getById(id);
                if (req == null) { conn.rollback(); return false; }

                // Chỉ cho phép duyệt/từ chối khi request đang PENDING
                if (!Request.STATUS_PENDING.equals(req.getStatus())) {
                    conn.rollback();
                    return false;
                }

                String sql = "UPDATE Requests SET status = ?, approved_by = ?, approved_at = NOW() WHERE id = ? AND status = 'PENDING'";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, status);
                    ps.setInt(2, approvedBy);
                    ps.setInt(3, id);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }

                String statusVi = "APPROVED".equals(status) ? "Đã xác nhận"
                        : "REJECTED".equals(status) ? "Từ chối" : status;
                auditLogDAO.log(approvedBy, "APPROVE_REQUEST_" + req.getType(),
                        "Yêu cầu " + req.getRequestCode() + " → " + statusVi);

                String link = req.isIn() ? "/warehouse/import-request?action=detail&id=" + id
                                         : "/warehouse/export-request?action=detail&id=" + id;
                if (Request.STATUS_APPROVED.equals(status)) {
                    notificationDAO.createNotification(req.getStaffId(),
                            "Yêu cầu " + req.getRequestCode() + " đã được xác nhận",
                            "Tiến hành tạo phiếu " + (req.isIn() ? "nhập" : "xuất") + " kho", link, conn);
                    // Notify warehouse staff to create ticket
                    notificationDAO.createNotificationForWarehouse(req.getWarehouseId(),
                            "Có yêu cầu " + (req.isIn() ? "nhập" : "xuất") + " đã xác nhận",
                            "Hãy tạo phiếu cho " + req.getRequestCode(), link, conn);
                } else if (Request.STATUS_REJECTED.equals(status)) {
                    notificationDAO.createNotification(req.getStaffId(),
                            "Yêu cầu " + req.getRequestCode() + " bị từ chối", "", link, conn);
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
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ============================================================
    // CANCEL workflows
    // ============================================================
    public boolean cancelRequest(int id, int userId) {
        String sql = "UPDATE Requests SET status = 'REVOKED', cancelled_by = ?, cancelled_at = NOW() "
                   + "WHERE id = ? AND status = 'PENDING'";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, id);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) auditLogDAO.log(userId, "REVOKE_REQUEST", "Thu hồi yêu cầu id=" + id + " trước duyệt");
            return ok;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean requestCancel(int id, int userId, String reason) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Request req = getById(id);
                if (req == null) { conn.rollback(); return false; }

                // Khóa dòng yêu cầu để tránh chạy đua với confirm phiếu (giống approveCancel).
                try (PreparedStatement lock = conn.prepareStatement(
                        "SELECT id FROM Requests WHERE id = ? FOR UPDATE")) {
                    lock.setInt(1, id);
                    lock.executeQuery();
                }

                // Sau khi xử lý một phần, thao tác này có nghĩa là đóng phần còn
                // lại; riêng transfer sẽ tiếp tục qua trạng thái vận chuyển/trả hàng.
                String sql = "UPDATE Requests SET cancel_requested_by = ?, cancel_requested_at = NOW(), cancel_reason = ? "
                        + "WHERE id = ? AND status IN ('APPROVED','PARTIALLY_COMPLETED') "
                        + "AND cancel_requested_at IS NULL";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, userId);
                    ps.setString(2, reason);
                    ps.setInt(3, id);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }
                auditLogDAO.log(userId, "REQUEST_CANCEL_REQUEST", "Yêu cầu " + req.getRequestCode() + ": " + reason);
                String link = req.isIn() ? "/warehouse/import-request?action=detail&id=" + id
                                         : "/warehouse/export-request?action=detail&id=" + id;
                notificationDAO.createNotificationForRole(2,
                        "Đề nghị hủy yêu cầu " + req.getRequestCode(),
                        "Lý do: " + reason, link, conn);
                conn.commit();
                return true;
            } catch (Exception ex) { conn.rollback(); ex.printStackTrace(); return false; }
            finally { conn.setAutoCommit(true); }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean approveCancel(int id, int userId) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Request req = getById(id);
                if (req == null) { conn.rollback(); return false; }

                // Khóa dòng yêu cầu để tránh chạy đua với confirm phiếu
                String lockedStatus;
                try (PreparedStatement lock = conn.prepareStatement(
                        "SELECT status FROM Requests WHERE id = ? FOR UPDATE")) {
                    lock.setInt(1, id);
                    try (ResultSet rs = lock.executeQuery()) {
                        if (!rs.next()) { conn.rollback(); return false; }
                        lockedStatus = rs.getString("status");
                    }
                }

                boolean wasPartial = Request.STATUS_PARTIALLY_COMPLETED.equals(lockedStatus);
                boolean inboundTransfer = req.isIn() && Request.REASON_TRANSFER.equals(req.getReason())
                        && req.getRefTicketId() != null;

                // Hủy yêu cầu nhận transfer luôn sinh chứng từ nhập trả nguồn.
                Integer transferReturnRequestId = null;
                if (inboundTransfer) {
                    transferReturnRequestId = createTransferReturnInRequest(req, userId, conn);
                    if (transferReturnRequestId == null) { conn.rollback(); return false; }
                }

                String newStatus;
                if (inboundTransfer) {
                    newStatus = Request.STATUS_RETURNING;
                } else if (wasPartial && req.isOut() && Request.REASON_TRANSFER.equals(req.getReason())) {
                    newStatus = Request.STATUS_PARTIALLY_CLOSED_IN_TRANSIT;
                } else if (wasPartial) {
                    newStatus = Request.STATUS_PARTIALLY_CLOSED;
                } else {
                    newStatus = Request.STATUS_CANCELLED;
                }

                String sql = "UPDATE Requests SET status=?, cancelled_by=?, cancelled_at=NOW() "
                        + "WHERE id=? AND cancel_requested_at IS NOT NULL "
                        + "AND status IN ('APPROVED','PARTIALLY_COMPLETED')";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, newStatus);
                    ps.setInt(2, userId);
                    ps.setInt(3, id);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }

                // Đánh dấu yêu cầu xuất nguồn đang trên đường trả. Chứng từ xuất
                // chỉ thành RETURNED sau khi kho nguồn quét nhận đủ serial.
                if (inboundTransfer) {
                    refreshTransferOutStatusAfterInboundCancel(req.getRefTicketId(), conn);
                }

                // Hủy luôn mọi phiếu còn ở trạng thái nháp của đơn này để trả lại số hàng
                // bị "giữ chỗ" (view Inventory_Available tính đặt-giữ theo phiếu DRAFT).
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Tickets SET status='CANCELLED' WHERE request_id=? AND status='DRAFT'")) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }

                auditLogDAO.log(userId, "APPROVE_CANCEL_REQUEST",
                        "Yêu cầu " + req.getRequestCode() + " → " + newStatus);
                String link = req.isIn() ? "/warehouse/import-request?action=detail&id=" + id
                                         : "/warehouse/export-request?action=detail&id=" + id;
                notificationDAO.createNotification(req.getStaffId(),
                        "Yêu cầu hủy " + req.getRequestCode() + " được chấp thuận", "", link, conn);
                if (transferReturnRequestId != null) {
                    notificationDAO.createNotificationForWarehouse(req.getPartnerId(),
                            "Cần nhận lại hàng chuyển kho",
                            "Yêu cầu nhập ở kho đích đã hủy. Hãy quét serial thực nhận để nhập trả cho phiếu xuất liên kết.",
                            "/warehouse/import-request?action=detail&id=" + transferReturnRequestId, conn);
                }
                conn.commit();
                return true;
            } catch (Exception ex) { conn.rollback(); ex.printStackTrace(); return false; }
            finally { conn.setAutoCommit(true); }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean rejectCancel(int id) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Request req = getById(id);
                if (req == null) { conn.rollback(); return false; }
                String sql = "UPDATE Requests SET cancel_requested_by = NULL, cancel_requested_at = NULL, cancel_reason = NULL WHERE id = ?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, id);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }
                auditLogDAO.log(null, "REJECT_CANCEL_REQUEST", "Yêu cầu " + req.getRequestCode());
                String link = req.isIn() ? "/warehouse/import-request?action=detail&id=" + id
                                         : "/warehouse/export-request?action=detail&id=" + id;
                if (req.getCancelRequestedBy() != null) {
                    notificationDAO.createNotification(req.getCancelRequestedBy(),
                            "Yêu cầu hủy " + req.getRequestCode() + " bị từ chối", "", link, conn);
                }
                conn.commit();
                return true;
            } catch (Exception ex) { conn.rollback(); ex.printStackTrace(); return false; }
            finally { conn.setAutoCommit(true); }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Há»§y má»™t lĂ´ nháº­p khĂ´ng Ä‘Æ°á»£c Ä‘Ă¡nh dáº¥u toĂ n bá»™ yĂªu cáº§u xuáº¥t lĂ 
     * RETURNING náº¿u váº«n cĂ²n lĂ´ khĂ¡c Ä‘ang giao bĂ¬nh thÆ°á»ng.
     */
    private void refreshTransferOutStatusAfterInboundCancel(int outTicketId, Connection conn) throws Exception {
        int outRequestId;
        String currentStatus;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT r.id, r.status FROM Tickets t JOIN Requests r ON r.id=t.request_id "
                        + "WHERE t.id=? AND t.type='OUT' AND r.type='OUT' AND r.reason='TRANSFER' FOR UPDATE")) {
            ps.setInt(1, outTicketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return;
                outRequestId = rs.getInt("id");
                currentStatus = rs.getString("status");
            }
        }

        boolean hasDeliveringTicket = false;
        boolean hasReturningTicket = false;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT ot.id, in_req.status AS in_status, in_req.cancelled_at "
                        + "FROM Tickets ot JOIN Requests out_req ON out_req.id=ot.request_id "
                        + "LEFT JOIN Requests in_req ON in_req.ref_ticket_id=ot.id "
                        + " AND in_req.type='IN' AND in_req.reason='TRANSFER' "
                        + " AND in_req.warehouse_id=out_req.partner_id "
                        + "WHERE ot.request_id=? AND ot.type='OUT' AND ot.status='IN_TRANSIT'")) {
            ps.setInt(1, outRequestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String inStatus = rs.getString("in_status");
                    boolean returning = rs.getTimestamp("cancelled_at") != null
                            || Request.STATUS_RETURNING.equals(inStatus)
                            || Request.STATUS_RETURNED.equals(inStatus)
                            || Request.STATUS_CANCELLED.equals(inStatus);
                    if (returning) hasReturningTicket = true;
                    else hasDeliveringTicket = true;
                }
            }
        }

        String status = currentStatus;
        if (hasDeliveringTicket) {
            if (!Request.STATUS_PARTIALLY_COMPLETED.equals(currentStatus)
                    && !Request.STATUS_PARTIALLY_CLOSED_IN_TRANSIT.equals(currentStatus)) {
                status = Request.STATUS_IN_TRANSIT;
            }
        } else if (hasReturningTicket) {
            status = Request.STATUS_RETURNING;
        }
        try (PreparedStatement ps = conn.prepareStatement("UPDATE Requests SET status=? WHERE id=?")) {
            ps.setString(1, status);
            ps.setInt(2, outRequestId);
            ps.executeUpdate();
        }
    }

    // ============================================================
    // Internal helper: create IN-TRANSFER request automatically
    // Gọi từ TicketDAO khi confirm Ticket OUT-TRANSFER.
    // ============================================================
    public int createTransferInRequest(Request outRequest, int outTicketId, Connection conn) throws Exception {
        String code = generateUniqueCode(Request.TYPE_IN, conn);
        String sql = "INSERT INTO Requests "
            + "(request_code, type, reason, warehouse_id, partner_type, partner_id, ref_ticket_id, "
            + " expected_date, staff_id, requested_condition, status, approved_by, approved_at, auto_approved) "
            + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?, NOW(), TRUE)";
        int newId;
        try (PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, code);
            ps.setString(2, Request.TYPE_IN);
            ps.setString(3, Request.REASON_TRANSFER);
            ps.setInt(4, outRequest.getPartnerId());          // kho đích trở thành warehouse_id của IN
            ps.setString(5, Request.PARTNER_WAREHOUSE);
            ps.setInt(6, outRequest.getWarehouseId());         // kho nguồn trở thành partner
            ps.setInt(7, outTicketId);
            if (outRequest.getExpectedDate() != null) ps.setDate(8, outRequest.getExpectedDate());
            else ps.setNull(8, Types.DATE);
            ps.setInt(9, outRequest.getStaffId());
            ps.setString(10, outRequest.getRequestedCondition() == null ? "NEW" : outRequest.getRequestedCondition());
            ps.setString(11, Request.STATUS_APPROVED);
            ps.setInt(12, outRequest.getApprovedBy() == null ? outRequest.getStaffId() : outRequest.getApprovedBy());
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                newId = keys.getInt(1);
            }
        }
        // Sao chép detail theo SỐ LƯỢNG THỰC XUẤT của phiếu (Ticket_Details), KHÔNG phải
        // theo đơn gốc — để khi xuất từng phần, kho đích chỉ kỳ vọng đúng số hàng đang về.
        String copyDet =
            "INSERT INTO Request_Details (request_id, product_id, quantity, unit_price) "
          + "SELECT ?, product_id, quantity, NULL FROM Ticket_Details WHERE ticket_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(copyDet)) {
            ps.setInt(1, newId);
            ps.setInt(2, outTicketId);
            ps.executeUpdate();
        }
        return newId;
    }

    /**
     * Tạo yêu cầu nhập trả tự động tại kho nguồn khi kho đích hủy yêu cầu
     * nhận hàng. Hỗ trợ cả serial còn IN_TRANSIT lẫn serial đã được kho đích
     * nhận; serial đã nhận chỉ bị giảm tồn ở kho đích khi kho nguồn thực sự
     * quét xác nhận nhập trả.
     *
     * @return id yêu cầu nhập trả, hoặc {@code null} nếu trạng thái vật lý không hợp lệ.
     */
    private Integer createTransferReturnInRequest(Request cancelledInbound, int userId,
            Connection conn) throws Exception {
        int outTicketId = cancelledInbound.getRefTicketId();
        int sourceWarehouseId;
        int destinationWarehouseId;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT t.warehouse_id AS source_warehouse_id, r.partner_id AS destination_warehouse_id "
                        + "FROM Tickets t JOIN Requests r ON r.id=t.request_id "
                        + "WHERE t.id=? AND t.type='OUT' AND t.status='IN_TRANSIT' "
                        + "AND r.reason='TRANSFER' FOR UPDATE")) {
            ps.setInt(1, outTicketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                sourceWarehouseId = rs.getInt("source_warehouse_id");
                destinationWarehouseId = rs.getInt("destination_warehouse_id");
            }
        }
        if (cancelledInbound.getWarehouseId() != destinationWarehouseId
                || cancelledInbound.getPartnerId() == null
                || cancelledInbound.getPartnerId() != sourceWarehouseId) return null;

        int transferred = 0;
        int returnable = 0;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT COUNT(*) AS transferred, COALESCE(SUM(pi.status='IN_TRANSIT' "
                        + "OR (pi.warehouse_id=? AND pi.status IN ('IN_STOCK','QUARANTINE'))),0) AS returnable "
                        + "FROM Product_Items pi JOIN Product_Item_Movements m ON m.product_item_id=pi.id "
                        + "WHERE m.ticket_id=? AND m.action='TRANSFER_OUT' FOR UPDATE")) {
            ps.setInt(1, destinationWarehouseId);
            ps.setInt(2, outTicketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    transferred = rs.getInt("transferred");
                    returnable = rs.getInt("returnable");
                }
            }
        }
        if (transferred == 0 || transferred != returnable) return null;

        // Chống duyệt hủy hai lần tạo hai yêu cầu trả cho cùng một phiếu xuất.
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM Requests WHERE type='IN' AND reason='TRANSFER' "
                        + "AND warehouse_id=? AND ref_ticket_id=? AND expected_serials IS NOT NULL "
                        + "AND status IN ('APPROVED','PARTIALLY_COMPLETED') FOR UPDATE")) {
            ps.setInt(1, sourceWarehouseId);
            ps.setInt(2, outTicketId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return null;
            }
        }

        List<String> expectedSerials = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT pi.serial_number FROM Product_Items pi "
                        + "JOIN Product_Item_Movements m ON m.product_item_id=pi.id "
                        + "WHERE m.ticket_id=? AND m.action='TRANSFER_OUT' AND (pi.status='IN_TRANSIT' "
                        + "OR (pi.warehouse_id=? AND pi.status IN ('IN_STOCK','QUARANTINE'))) ORDER BY pi.id")) {
            ps.setInt(1, outTicketId);
            ps.setInt(2, destinationWarehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) expectedSerials.add(rs.getString(1));
            }
        }
        if (expectedSerials.isEmpty()) return null;

        String code = generateUniqueCode(Request.TYPE_IN, conn);
        int newId;
        String insert = "INSERT INTO Requests "
                + "(request_code,type,reason,warehouse_id,partner_type,partner_id,ref_ticket_id,expected_serials,"
                + "staff_id,requested_condition,status,approved_by,approved_at,auto_approved) "
                + "VALUES (?,?,?,?,?,?,?,?,?,?,?, ?,NOW(),TRUE)";
        try (PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, code);
            ps.setString(2, Request.TYPE_IN);
            ps.setString(3, Request.REASON_TRANSFER);
            ps.setInt(4, sourceWarehouseId);
            ps.setString(5, Request.PARTNER_WAREHOUSE);
            ps.setInt(6, destinationWarehouseId);
            ps.setInt(7, outTicketId);
            ps.setString(8, String.join(",", expectedSerials));
            ps.setInt(9, userId);
            ps.setString(10, "NEW");
            ps.setString(11, Request.STATUS_APPROVED);
            ps.setInt(12, userId);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (!keys.next()) return null;
                newId = keys.getInt(1);
            }
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Request_Details (request_id,product_id,quantity,unit_price) "
                        + "SELECT ?,product_id,quantity,NULL FROM Ticket_Details WHERE ticket_id=?")) {
            ps.setInt(1, newId);
            ps.setInt(2, outTicketId);
            ps.executeUpdate();
        }
        auditLogDAO.log(conn, userId, "CREATE_TRANSFER_RETURN_REQUEST",
                "Yêu cầu nhập trả " + code + " cho phiếu xuất #" + outTicketId);
        return newId;
    }

    // ============================================================
    // Update status (no transaction — gọi trong transaction lớn từ TicketDAO)
    // ============================================================
    public void setStatus(int requestId, String status, Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement("UPDATE Requests SET status = ? WHERE id = ?")) {
            ps.setString(1, status);
            ps.setInt(2, requestId);
            ps.executeUpdate();
        }
    }

    // ============================================================
    // Generate unique code
    // ============================================================
    public String generateUniqueCode(String type, Connection conn) throws Exception {
        int year = Calendar.getInstance().get(Calendar.YEAR);
        String prefix = "REQ-" + (Request.TYPE_IN.equals(type) ? "IN-" : "OUT-") + year + "-";
        String sql = "SELECT request_code FROM Requests WHERE request_code LIKE ? ORDER BY id DESC LIMIT 1";
        int next = 1;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, prefix + "%");
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String last = rs.getString(1);
                    try { next = Integer.parseInt(last.substring(prefix.length())) + 1; }
                    catch (Exception ignore) {}
                }
            }
        }
        // Nếu mã dự kiến đã tồn tại (2 người tạo cùng lúc), nhảy sang số kế tiếp còn trống.
        String existsSql = "SELECT 1 FROM Requests WHERE request_code = ?";
        while (next < 100000) {
            String candidate = prefix + String.format("%04d", next);
            try (PreparedStatement ps = conn.prepareStatement(existsSql)) {
                ps.setString(1, candidate);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) return candidate;
                }
            }
            next++;
        }
        throw new Exception("Cannot generate unique request code");
    }

    public String generateUniqueCode(String type) {
        try (Connection conn = DBUtils.getConnection()) {
            return generateUniqueCode(type, conn);
        } catch (Exception e) { e.printStackTrace(); return null; }
    }
}
