package dao;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import model.Stocktake;
import model.StocktakeConfig;
import model.StocktakeDetail;
import model.StocktakeItem;
import utils.DBUtils;

/**
 * DAO cho luồng kiểm kê.
 *
 *   Luồng trạng thái:
 *     DRAFT → COUNTING → SUBMITTED → (L1_APPROVED →)? APPROVED → ADJUSTED
 *
 *   applyAdjustment() là thao tác cuối — cập nhật Inventories, Product_Items,
 *   Product_Ledger, Product_Item_Movements. Phải transactional.
 */
public class StocktakeDAO {

    private final NotificationDAO notificationDAO = new NotificationDAO();
    private final AuditLogDAO auditLogDAO = new AuditLogDAO();

    private static final String BASE_SELECT =
        "SELECT s.*, w.warehouse_name, "
        + "u1.full_name AS created_by_name, "
        + "u2.full_name AS counted_by_name, "
        + "u3.full_name AS l1_name, "
        + "u4.full_name AS l2_name, "
        + "u5.full_name AS verified_by_name "
        + "FROM Stocktakes s "
        + "JOIN Warehouses w ON w.id = s.warehouse_id "
        + "JOIN Users u1 ON u1.id = s.created_by "
        + "LEFT JOIN Users u2 ON u2.id = s.counted_by "
        + "LEFT JOIN Users u3 ON u3.id = s.l1_approved_by "
        + "LEFT JOIN Users u4 ON u4.id = s.l2_approved_by "
        + "LEFT JOIN Users u5 ON u5.id = s.verified_by ";

    private Stocktake mapRow(ResultSet rs) throws Exception {
        Stocktake s = new Stocktake();
        s.setId(rs.getInt("id"));
        s.setStocktakeCode(rs.getString("stocktake_code"));
        s.setWarehouseId(rs.getInt("warehouse_id"));
        s.setScope(rs.getString("scope"));
        s.setCountMode(rs.getString("count_mode"));
        s.setStatus(rs.getString("status"));
        s.setRequiresL2Approval(rs.getBoolean("requires_l2_approval"));
        s.setVariancePercent(rs.getBigDecimal("variance_percent"));
        s.setVarianceValue(rs.getBigDecimal("variance_value"));
        s.setNotes(rs.getString("notes"));
        s.setRejectReason(rs.getString("reject_reason"));
        s.setVerificationStatus(rs.getString("verification_status"));
        s.setVerifiedBy((Integer) rs.getObject("verified_by"));
        s.setVerifiedAt(rs.getTimestamp("verified_at"));
        s.setCreatedAt(rs.getTimestamp("created_at"));
        s.setCreatedBy(rs.getInt("created_by"));
        s.setCountedBy((Integer) rs.getObject("counted_by"));
        s.setCountedAt(rs.getTimestamp("counted_at"));
        s.setSubmittedAt(rs.getTimestamp("submitted_at"));
        s.setL1ApprovedBy((Integer) rs.getObject("l1_approved_by"));
        s.setL1ApprovedAt(rs.getTimestamp("l1_approved_at"));
        s.setL2ApprovedBy((Integer) rs.getObject("l2_approved_by"));
        s.setL2ApprovedAt(rs.getTimestamp("l2_approved_at"));
        s.setAdjustedAt(rs.getTimestamp("adjusted_at"));
        s.setWarehouseName(rs.getString("warehouse_name"));
        s.setCreatedByFullName(rs.getString("created_by_name"));
        s.setCountedByFullName(rs.getString("counted_by_name"));
        s.setL1ApprovedByFullName(rs.getString("l1_name"));
        s.setL2ApprovedByFullName(rs.getString("l2_name"));
        s.setVerifiedByFullName(rs.getString("verified_by_name"));
        return s;
    }

    private StocktakeDetail mapDetail(ResultSet rs) throws Exception {
        StocktakeDetail d = new StocktakeDetail();
        d.setStocktakeId(rs.getInt("stocktake_id"));
        d.setProductId(rs.getInt("product_id"));
        d.setTheoreticalQty(rs.getInt("theoretical_qty"));
        d.setActualQty(rs.getInt("actual_qty"));
        d.setDamagedQty(rs.getInt("damaged_qty"));
        d.setVarianceReason(rs.getString("variance_reason"));
        d.setNote(rs.getString("note"));
        d.setProductName(rs.getString("product_name"));
        d.setSku(rs.getString("sku"));
        d.setUnit(rs.getString("unit"));
        d.setUnitCost(rs.getDouble("average_cost"));
        return d;
    }

    private StocktakeItem mapItem(ResultSet rs) throws Exception {
        StocktakeItem it = new StocktakeItem();
        it.setId(rs.getInt("id"));
        it.setStocktakeId(rs.getInt("stocktake_id"));
        it.setProductItemId((Integer) rs.getObject("product_item_id"));
        it.setProductId(rs.getInt("product_id"));
        it.setSerialNumber(rs.getString("serial_number"));
        it.setScannedStatus(rs.getString("scanned_status"));
        it.setNewCondition(rs.getString("new_condition"));
        it.setNote(rs.getString("note"));
        it.setPhase(rs.getString("phase"));
        it.setCreatedAt(rs.getTimestamp("created_at"));
        it.setProductName(rs.getString("product_name"));
        it.setSku(rs.getString("sku"));
        return it;
    }

    // ============================================================
    // READ
    // ============================================================
    public List<Stocktake> getAll(Integer warehouseId, String status) {
        List<Stocktake> list = new ArrayList<>();
        StringBuilder sb = new StringBuilder(BASE_SELECT).append(" WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (warehouseId != null) { sb.append(" AND s.warehouse_id = ?"); params.add(warehouseId); }
        if (status != null && !status.isEmpty()) { sb.append(" AND s.status = ?"); params.add(status); }
        sb.append(" ORDER BY s.id DESC");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Stocktake getById(int id) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(BASE_SELECT + " WHERE s.id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Stocktake s = mapRow(rs);
                    s.setDetails(getDetailsByStocktakeId(id));
                    s.setItems(getItemsByStocktakeId(id));
                    return s;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public List<StocktakeDetail> getDetailsByStocktakeId(int stocktakeId) {
        List<StocktakeDetail> list = new ArrayList<>();
        String sql = "SELECT d.*, p.product_name, p.sku, p.unit, p.average_cost "
                   + "FROM Stocktake_Details d "
                   + "JOIN Products p ON p.id = d.product_id "
                   + "WHERE d.stocktake_id = ? "
                   + "ORDER BY p.product_name";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stocktakeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapDetail(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<StocktakeItem> getItemsByStocktakeId(int stocktakeId) {
        List<StocktakeItem> list = new ArrayList<>();
        String sql = "SELECT i.*, p.product_name, p.sku "
                   + "FROM Stocktake_Items i "
                   + "JOIN Products p ON p.id = i.product_id "
                   + "WHERE i.stocktake_id = ? "
                   + "ORDER BY p.product_name, i.serial_number";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stocktakeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapItem(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ============================================================
    // CREATE
    // ============================================================
    /**
     * Tạo phiếu DRAFT. Tự fill theoretical_qty từ Inventories.
     *
     * @param productIds NULL hoặc rỗng nếu scope=FULL (auto lấy mọi product có trong kho)
     */
    public boolean create(Stocktake s, List<Integer> productIds) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                if (s.getStocktakeCode() == null || s.getStocktakeCode().isEmpty()) {
                    s.setStocktakeCode(generateUniqueCode(conn));
                }

                int newId;
                String insSql = "INSERT INTO Stocktakes "
                    + "(stocktake_code, warehouse_id, scope, count_mode, status, notes, created_by) "
                    + "VALUES (?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(insSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, s.getStocktakeCode());
                    ps.setInt(2, s.getWarehouseId());
                    ps.setString(3, s.getScope() == null ? Stocktake.SCOPE_PARTIAL : s.getScope());
                    ps.setString(4, s.getCountMode() == null ? Stocktake.MODE_QUANTITY : s.getCountMode());
                    ps.setString(5, Stocktake.STATUS_DRAFT);
                    if (s.getNotes() != null) ps.setString(6, s.getNotes()); else ps.setNull(6, Types.VARCHAR);
                    ps.setInt(7, s.getCreatedBy());
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) { conn.rollback(); return false; }
                        newId = keys.getInt(1);
                        s.setId(newId);
                    }
                }

                // Lấy theoretical_qty
                String detailSelect;
                List<Object> selParams = new ArrayList<>();
                if (Stocktake.SCOPE_FULL.equals(s.getScope()) || productIds == null || productIds.isEmpty()) {
                    detailSelect = "SELECT product_id, quantity FROM Inventories WHERE warehouse_id = ?";
                    selParams.add(s.getWarehouseId());
                } else {
                    StringBuilder marks = new StringBuilder();
                    for (int i = 0; i < productIds.size(); i++) marks.append(i == 0 ? "?" : ",?");
                    detailSelect = "SELECT product_id, quantity FROM Inventories "
                                 + "WHERE warehouse_id = ? AND product_id IN (" + marks + ")";
                    selParams.add(s.getWarehouseId());
                    selParams.addAll(productIds);
                }

                List<int[]> rows = new ArrayList<>(); // [productId, qty]
                try (PreparedStatement ps = conn.prepareStatement(detailSelect)) {
                    for (int i = 0; i < selParams.size(); i++) ps.setObject(i + 1, selParams.get(i));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) rows.add(new int[]{rs.getInt(1), rs.getInt(2)});
                    }
                }

                if (rows.isEmpty()) { conn.rollback(); return false; }

                String insDet = "INSERT INTO Stocktake_Details "
                    + "(stocktake_id, product_id, theoretical_qty, actual_qty, damaged_qty, variance_reason) "
                    + "VALUES (?,?,?,0,0,'NONE')";
                try (PreparedStatement ps = conn.prepareStatement(insDet)) {
                    for (int[] r : rows) {
                        ps.setInt(1, newId);
                        ps.setInt(2, r[0]);
                        ps.setInt(3, r[1]);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                auditLogDAO.log(s.getCreatedBy(), "STOCKTAKE_CREATE",
                        "Stocktake " + s.getStocktakeCode() + " — kho " + s.getWarehouseId());

                // Thông báo cho Warehouse Staff (role 4) ĐÚNG kho này (không gửi lan sang kho khác)
                notificationDAO.createNotificationForWarehouseRole(s.getWarehouseId(), 4,
                        "Có phiếu kiểm kê mới",
                        "Phiếu " + s.getStocktakeCode() + " đang chờ đếm",
                        "/warehouse/stocktake?action=detail&id=" + newId, conn);

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
    // COUNT — lưu kết quả đếm
    // ============================================================
    /**
     * Khi nhân viên bắt đầu đếm → status DRAFT → COUNTING + set counted_by.
     */
    public boolean startCounting(int stocktakeId, int userId) {
        String sql = "UPDATE Stocktakes SET status = 'COUNTING', counted_by = ?, counted_at = NOW(), "
                   + "verification_status = 'NONE', verified_by = NULL, verified_at = NULL "
                   + "WHERE id = ? AND status IN ('DRAFT','COUNTING','REJECTED')";
        try (Connection conn = DBUtils.getConnection()) {
            // Xóa VERIFY items cũ khi bắt đầu đếm lại
            try (PreparedStatement del = conn.prepareStatement(
                    "DELETE FROM Stocktake_Items WHERE stocktake_id = ? AND phase = 'VERIFY'")) {
                del.setInt(1, stocktakeId);
                del.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ps.setInt(2, stocktakeId);
                return ps.executeUpdate() > 0;
            }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Lưu nháp kết quả đếm (mode QUANTITY).
     */
    public boolean saveQuantityCounts(int stocktakeId, List<StocktakeDetail> details) {
        String sql = "UPDATE Stocktake_Details SET actual_qty = ?, damaged_qty = ?, "
                   + "variance_reason = ?, note = ? "
                   + "WHERE stocktake_id = ? AND product_id = ?";
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (StocktakeDetail d : details) {
                    ps.setInt(1, d.getActualQty());
                    ps.setInt(2, d.getDamagedQty());
                    ps.setString(3, d.getVarianceReason() == null ? "NONE" : d.getVarianceReason());
                    if (d.getNote() != null) ps.setString(4, d.getNote()); else ps.setNull(4, Types.VARCHAR);
                    ps.setInt(5, stocktakeId);
                    ps.setInt(6, d.getProductId());
                    ps.addBatch();
                }
                ps.executeBatch();
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

    /**
     * Lưu kết quả scan serial (mode SERIAL).
     * Xóa hết item cũ rồi insert lại — đơn giản, tránh phức tạp delta.
     * Sau đó rollup vào Stocktake_Details.actual_qty và damaged_qty.
     */
    public boolean saveSerialCounts(int stocktakeId, List<StocktakeItem> items) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM Stocktake_Items WHERE stocktake_id = ?")) {
                    ps.setInt(1, stocktakeId);
                    ps.executeUpdate();
                }

                String ins = "INSERT INTO Stocktake_Items "
                    + "(stocktake_id, product_item_id, product_id, serial_number, scanned_status, new_condition, note) "
                    + "VALUES (?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(ins)) {
                    for (StocktakeItem it : items) {
                        ps.setInt(1, stocktakeId);
                        if (it.getProductItemId() != null) ps.setInt(2, it.getProductItemId());
                        else ps.setNull(2, Types.INTEGER);
                        ps.setInt(3, it.getProductId());
                        ps.setString(4, it.getSerialNumber());
                        ps.setString(5, it.getScannedStatus());
                        if (it.getNewCondition() != null) ps.setString(6, it.getNewCondition());
                        else ps.setNull(6, Types.VARCHAR);
                        if (it.getNote() != null) ps.setString(7, it.getNote());
                        else ps.setNull(7, Types.VARCHAR);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                rollupSerialCounts(stocktakeId, conn);

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
    // SUBMIT — tính variance + quyết định L1/L2
    // ============================================================
    public boolean submit(int stocktakeId) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Stocktake s = getById(stocktakeId);
                if (s == null || !s.isCounting()) { conn.rollback(); return false; }

                // SERIAL mode: tự đánh dấu MISSING cho serial chưa scan
                if (s.isSerialMode()) {
                    autoFillMissingSerials(stocktakeId, s.getWarehouseId(), conn);
                    rollupSerialCounts(stocktakeId, conn);
                    s = getById(stocktakeId);
                }

                // QUANTITY mode + đã xác minh serial: đảm bảo rollup lại từ VERIFY items
                if (s.isQuantityMode() && s.isVerificationCompleted()) {
                    rollupVerificationCounts(stocktakeId, conn);
                    s = getById(stocktakeId);
                }

                // Tính variance
                BigDecimal totalTheo = BigDecimal.ZERO;
                BigDecimal totalAbsDiff = BigDecimal.ZERO;
                BigDecimal totalValue = BigDecimal.ZERO;

                for (StocktakeDetail d : s.getDetails()) {
                    int diff = Math.abs(d.getActualQty() - d.getTheoreticalQty()) + d.getDamagedQty();
                    totalTheo  = totalTheo.add(BigDecimal.valueOf(d.getTheoreticalQty()));
                    totalAbsDiff = totalAbsDiff.add(BigDecimal.valueOf(diff));
                    totalValue = totalValue.add(BigDecimal.valueOf(diff).multiply(BigDecimal.valueOf(d.getUnitCost())));
                }

                BigDecimal percent = BigDecimal.ZERO;
                if (totalTheo.compareTo(BigDecimal.ZERO) > 0) {
                    percent = totalAbsDiff.multiply(BigDecimal.valueOf(100))
                            .divide(totalTheo, 2, RoundingMode.HALF_UP);
                }

                // Đọc ngưỡng từ config
                StocktakeConfig cfg = getConfig(conn);
                boolean needsL2 = percent.compareTo(cfg.getThresholdPercent()) >= 0
                               || totalValue.compareTo(cfg.getThresholdValue()) >= 0;

                String upd = "UPDATE Stocktakes SET status = 'SUBMITTED', submitted_at = NOW(), "
                           + "variance_percent = ?, variance_value = ?, requires_l2_approval = ? "
                           + "WHERE id = ? AND status = 'COUNTING'";
                try (PreparedStatement ps = conn.prepareStatement(upd)) {
                    ps.setBigDecimal(1, percent);
                    ps.setBigDecimal(2, totalValue);
                    ps.setBoolean(3, needsL2);
                    ps.setInt(4, stocktakeId);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }

                auditLogDAO.log(s.getCountedBy() != null ? s.getCountedBy() : s.getCreatedBy(),
                        "STOCKTAKE_SUBMIT",
                        "Stocktake " + s.getStocktakeCode() + " — variance " + percent + "% / " + totalValue + "đ");

                // Thông báo Warehouse Manager (role 3) ĐÚNG kho này duyệt L1
                notificationDAO.createNotificationForWarehouseRole(s.getWarehouseId(), 3,
                        "Có phiếu kiểm kê chờ duyệt",
                        "Phiếu " + s.getStocktakeCode() + " chênh lệch " + percent + "%"
                                + (needsL2 ? " (cần duyệt 2 cấp)" : ""),
                        "/warehouse/stocktake?action=detail&id=" + stocktakeId, conn);

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
    // APPROVE L1 — Warehouse Manager
    // ============================================================
    public boolean approveL1(int stocktakeId, int approverId) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Stocktake s = getById(stocktakeId);
                if (s == null || !s.isSubmitted()) { conn.rollback(); return false; }

                String newStatus = s.isRequiresL2Approval()
                        ? Stocktake.STATUS_L1_APPROVED
                        : Stocktake.STATUS_APPROVED;

                String upd = "UPDATE Stocktakes SET status = ?, l1_approved_by = ?, l1_approved_at = NOW() "
                           + "WHERE id = ? AND status = 'SUBMITTED'";
                try (PreparedStatement ps = conn.prepareStatement(upd)) {
                    ps.setString(1, newStatus);
                    ps.setInt(2, approverId);
                    ps.setInt(3, stocktakeId);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }

                auditLogDAO.log(approverId, "STOCKTAKE_APPROVE_L1",
                        "Stocktake " + s.getStocktakeCode() + " → " + newStatus);

                if (s.isRequiresL2Approval()) {
                    // Notify Business Admin (role 2) duyệt L2
                    notificationDAO.createNotificationForRole(2,
                            "Phiếu kiểm kê chờ duyệt cấp 2",
                            "Phiếu " + s.getStocktakeCode() + " chênh lệch lớn ("
                                    + s.getVariancePercent() + "%)",
                            "/warehouse/stocktake?action=detail&id=" + stocktakeId, conn);
                } else {
                    // Đi thẳng tới ADJUSTED
                    applyAdjustment(s, approverId, conn);
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
    // APPROVE L2 — Business Admin
    // ============================================================
    public boolean approveL2(int stocktakeId, int approverId) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Stocktake s = getById(stocktakeId);
                if (s == null || !s.isL1Approved()) { conn.rollback(); return false; }

                String upd = "UPDATE Stocktakes SET status = 'APPROVED', l2_approved_by = ?, l2_approved_at = NOW() "
                           + "WHERE id = ? AND status = 'L1_APPROVED'";
                try (PreparedStatement ps = conn.prepareStatement(upd)) {
                    ps.setInt(1, approverId);
                    ps.setInt(2, stocktakeId);
                    if (ps.executeUpdate() == 0) { conn.rollback(); return false; }
                }

                auditLogDAO.log(approverId, "STOCKTAKE_APPROVE_L2",
                        "Stocktake " + s.getStocktakeCode() + " duyệt cấp 2");

                // Đi tới ADJUSTED
                applyAdjustment(s, approverId, conn);

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
    // REJECT
    // ============================================================
    public boolean reject(int stocktakeId, int approverId, String reason) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                Stocktake s = getById(stocktakeId);
                if (s == null || (!s.isSubmitted() && !s.isL1Approved())) { conn.rollback(); return false; }

                // REJECT → cho phép đếm lại: status REJECTED, nhưng giữ counted_by để biết người đếm trước
                String upd = "UPDATE Stocktakes SET status = 'REJECTED', reject_reason = ? "
                           + "WHERE id = ?";
                try (PreparedStatement ps = conn.prepareStatement(upd)) {
                    ps.setString(1, reason);
                    ps.setInt(2, stocktakeId);
                    ps.executeUpdate();
                }

                auditLogDAO.log(approverId, "STOCKTAKE_REJECT",
                        "Stocktake " + s.getStocktakeCode() + " bị bác bỏ: " + reason);

                // Notify người đếm
                if (s.getCountedBy() != null) {
                    notificationDAO.createNotification(s.getCountedBy(),
                            "Phiếu kiểm kê bị bác bỏ",
                            "Phiếu " + s.getStocktakeCode() + " cần đếm lại: " + reason,
                            "/warehouse/stocktake?action=detail&id=" + stocktakeId, conn);
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
    // APPLY ADJUSTMENT — cập nhật Inventories, Product_Items, Ledger, Movements
    // ============================================================
    /**
     * Gọi trong transaction đã mở. KHÔNG commit/rollback bên trong.
     *
     * Cập nhật cho mỗi product trong phiếu:
     *   - Inventories.quantity = actual_qty (final, không cộng delta để tránh race với phiếu khác)
     *   - Ghi Product_Ledger với change = actual - theoretical, transaction_type=STOCKTAKE
     *
     * Nếu SERIAL mode:
     *   - MISSING → Product_Items.status = LOST
     *   - DAMAGED → Product_Items.item_condition = DAMAGED, status = QUARANTINE
     *   - EXTRA   → tạo Product_Items mới (status=IN_STOCK, condition=NEW)
     *   - Ghi Product_Item_Movements với action=STOCKTAKE_ADJUST cho mỗi serial thay đổi
     */
    private void applyAdjustment(Stocktake s, int actorId, Connection conn) throws Exception {
        List<StocktakeDetail> details = s.getDetails();
        if (details == null || details.isEmpty()) return;

        // 1. Cập nhật Inventories + Ledger cho mỗi SKU
        // actual_qty = TỔNG đếm được (bao gồm hỏng); damaged_qty = số hỏng trong đó
        //   → quantity (bán được)   = actual - damaged
        //   → quarantine_quantity  += damaged  (cộng thêm vào số đã cách ly)
        String selInv = "SELECT quantity, quarantine_quantity FROM Inventories WHERE warehouse_id = ? AND product_id = ? FOR UPDATE";
        String upsertInv = "INSERT INTO Inventories (warehouse_id, product_id, quantity, quarantine_quantity) "
                         + "VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE quantity = VALUES(quantity), quarantine_quantity = VALUES(quarantine_quantity)";
        Map<Integer, int[]> oldConditionBalances = new HashMap<>();
        Map<Integer, Integer> physicalChanges = new HashMap<>();

        for (StocktakeDetail d : details) {
            int newGoodQty = Math.max(0, d.getActualQty() - d.getDamagedQty());

            int oldGoodQty = 0;
            int oldQuarantineQty = 0;
            try (PreparedStatement ps = conn.prepareStatement(selInv)) {
                ps.setInt(1, s.getWarehouseId());
                ps.setInt(2, d.getProductId());
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        oldGoodQty = rs.getInt("quantity");
                        oldQuarantineQty = rs.getInt("quarantine_quantity");
                    }
                }
            }
            oldConditionBalances.put(d.getProductId(),
                    getConditionBalances(d.getProductId(), s.getWarehouseId(), conn));
            int newQuarantineQty = oldQuarantineQty + d.getDamagedQty();

            try (PreparedStatement ps = conn.prepareStatement(upsertInv)) {
                ps.setInt(1, s.getWarehouseId());
                ps.setInt(2, d.getProductId());
                ps.setInt(3, newGoodQty);
                ps.setInt(4, newQuarantineQty);
                ps.executeUpdate();
            }

            int change = (newGoodQty + newQuarantineQty) - (oldGoodQty + oldQuarantineQty);
            physicalChanges.put(d.getProductId(), change);
        }

        // 2. Xử lý serial: SERIAL mode hoặc QUANTITY mode có verification
        boolean hasVerifyItems = s.isQuantityMode() && s.isVerificationCompleted();
        if (s.isSerialMode() || hasVerifyItems) {
            List<StocktakeItem> items = s.getItems();
            if (items != null) {
                // QUANTITY+VERIFY: chỉ xử lý VERIFY-phase items; SERIAL: xử lý tất cả
                if (hasVerifyItems) {
                    List<StocktakeItem> verifyOnly = new ArrayList<>();
                    for (StocktakeItem vi : items) {
                        if ("VERIFY".equals(vi.getPhase())) verifyOnly.add(vi);
                    }
                    items = verifyOnly;
                }
                String updItemLost     = "UPDATE Product_Items SET status = 'LOST' WHERE id = ?";
                String updItemDamaged  = "UPDATE Product_Items SET status = 'QUARANTINE', item_condition = 'DAMAGED' WHERE id = ?";
                String insNewItem      = "INSERT INTO Product_Items (product_id, serial_number, status, item_condition, warehouse_id) "
                                       + "VALUES (?,?,'IN_STOCK','NEW',?)";
                String insMovement     = "INSERT INTO Product_Item_Movements "
                                       + "(product_item_id, ticket_id, action, from_warehouse_id, to_warehouse_id, condition_at_time, created_by) "
                                       + "VALUES (?,NULL,'STOCKTAKE_ADJUST',?,?,?,?)";

                for (StocktakeItem it : items) {
                    Integer pid = it.getProductItemId();
                    String scan = it.getScannedStatus();

                    if (StocktakeItem.STATUS_MISSING.equals(scan) && pid != null) {
                        try (PreparedStatement ps = conn.prepareStatement(updItemLost)) {
                            ps.setInt(1, pid);
                            ps.executeUpdate();
                        }
                        try (PreparedStatement ps = conn.prepareStatement(insMovement)) {
                            ps.setInt(1, pid);
                            ps.setInt(2, s.getWarehouseId());
                            ps.setInt(3, s.getWarehouseId());
                            ps.setString(4, "NEW");
                            ps.setInt(5, actorId);
                            ps.executeUpdate();
                        }
                    } else if (StocktakeItem.STATUS_DAMAGED.equals(scan) && pid != null) {
                        try (PreparedStatement ps = conn.prepareStatement(updItemDamaged)) {
                            ps.setInt(1, pid);
                            ps.executeUpdate();
                        }
                        try (PreparedStatement ps = conn.prepareStatement(insMovement)) {
                            ps.setInt(1, pid);
                            ps.setInt(2, s.getWarehouseId());
                            ps.setInt(3, s.getWarehouseId());
                            ps.setString(4, "DAMAGED");
                            ps.setInt(5, actorId);
                            ps.executeUpdate();
                        }
                    } else if (StocktakeItem.STATUS_EXTRA.equals(scan)) {
                        int newItemId;
                        try (PreparedStatement ps = conn.prepareStatement(insNewItem, Statement.RETURN_GENERATED_KEYS)) {
                            ps.setInt(1, it.getProductId());
                            ps.setString(2, it.getSerialNumber());
                            ps.setInt(3, s.getWarehouseId());
                            ps.executeUpdate();
                            try (ResultSet keys = ps.getGeneratedKeys()) {
                                if (!keys.next()) throw new Exception("Không insert được Product_Items mới");
                                newItemId = keys.getInt(1);
                            }
                        }
                        try (PreparedStatement ps = conn.prepareStatement(insMovement)) {
                            ps.setInt(1, newItemId);
                            ps.setNull(2, Types.INTEGER);   // from_warehouse_id NULL (EXTRA = không có nguồn)
                            ps.setInt(3, s.getWarehouseId());
                            ps.setString(4, "NEW");
                            ps.setInt(5, actorId);
                            ps.executeUpdate();
                        }
                    }
                }
            }
        }

        // Ghi một snapshot ledger sau khi cả tồn tổng và trạng thái serial đã được cập nhật.
        // Delta theo tình trạng giúp báo cáo phân biệt tái phân loại với nhập/xuất thật.
        String insLedger = "INSERT INTO Product_Ledger "
                + "(product_id, transaction_type, reference_id, change_quantity, balance_quantity, "
                + "change_new_quantity, change_used_quantity, change_damaged_quantity, "
                + "balance_new_quantity, balance_used_quantity, balance_damaged_quantity, "
                + "warehouse_id, created_by) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)";
        for (StocktakeDetail d : details) {
            int productId = d.getProductId();
            int physicalChange = physicalChanges.getOrDefault(productId, 0);
            int[] oldBalances = oldConditionBalances.getOrDefault(productId, new int[] {0, 0, 0});
            int[] newBalances = getConditionBalances(productId, s.getWarehouseId(), conn);
            int changeNew = newBalances[0] - oldBalances[0];
            int changeUsed = newBalances[1] - oldBalances[1];
            int changeDamaged = newBalances[2] - oldBalances[2];

            if (physicalChange == 0 && changeNew == 0 && changeUsed == 0 && changeDamaged == 0) continue;

            try (PreparedStatement ps = conn.prepareStatement(insLedger)) {
                ps.setInt(1, productId);
                ps.setString(2, "STOCKTAKE");
                ps.setInt(3, s.getId());
                ps.setInt(4, physicalChange);
                ps.setInt(5, newBalances[0] + newBalances[1] + newBalances[2]);
                ps.setInt(6, changeNew);
                ps.setInt(7, changeUsed);
                ps.setInt(8, changeDamaged);
                ps.setInt(9, newBalances[0]);
                ps.setInt(10, newBalances[1]);
                ps.setInt(11, newBalances[2]);
                ps.setInt(12, s.getWarehouseId());
                ps.setInt(13, actorId);
                ps.executeUpdate();
            }
        }

        // 3. Cuối cùng: đánh dấu ADJUSTED
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE Stocktakes SET status = 'ADJUSTED', adjusted_at = NOW() WHERE id = ?")) {
            ps.setInt(1, s.getId());
            ps.executeUpdate();
        }

        auditLogDAO.log(actorId, "STOCKTAKE_ADJUST",
                "Stocktake " + s.getStocktakeCode() + " đã cập nhật tồn kho");
    }

    // ============================================================
    // CONFIG (ngưỡng duyệt 2 cấp)
    // ============================================================
    public StocktakeConfig getConfig() {
        try (Connection conn = DBUtils.getConnection()) {
            return getConfig(conn);
        } catch (Exception e) { e.printStackTrace(); return null; }
    }

    private StocktakeConfig getConfig(Connection conn) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM Stocktake_Config ORDER BY id DESC LIMIT 1");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                StocktakeConfig c = new StocktakeConfig();
                c.setId(rs.getInt("id"));
                c.setThresholdPercent(rs.getBigDecimal("threshold_percent"));
                c.setThresholdValue(rs.getBigDecimal("threshold_value"));
                c.setUpdatedBy((Integer) rs.getObject("updated_by"));
                c.setUpdatedAt(rs.getTimestamp("updated_at"));
                return c;
            }
        }
        // Fallback nếu chưa seed
        StocktakeConfig c = new StocktakeConfig();
        c.setThresholdPercent(new BigDecimal("5.00"));
        c.setThresholdValue(new BigDecimal("10000000"));
        return c;
    }

    public boolean updateConfig(BigDecimal percent, BigDecimal value, int userId) {
        String sql = "UPDATE Stocktake_Config SET threshold_percent = ?, threshold_value = ?, "
                   + "updated_by = ?, updated_at = NOW() WHERE id = 1";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBigDecimal(1, percent);
            ps.setBigDecimal(2, value);
            ps.setInt(3, userId);
            int n = ps.executeUpdate();
            if (n == 0) {
                // chưa có row → insert
                try (PreparedStatement ins = conn.prepareStatement(
                        "INSERT INTO Stocktake_Config (id, threshold_percent, threshold_value, updated_by) VALUES (1,?,?,?)")) {
                    ins.setBigDecimal(1, percent);
                    ins.setBigDecimal(2, value);
                    ins.setInt(3, userId);
                    ins.executeUpdate();
                }
            }
            auditLogDAO.log(userId, "STOCKTAKE_CONFIG_UPDATE",
                    "Ngưỡng: " + percent + "% / " + value + "đ");
            return true;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ============================================================
    // CANCEL
    // ============================================================
    public boolean cancel(int stocktakeId, int userId) {
        String sql = "UPDATE Stocktakes SET status = 'CANCELLED' "
                   + "WHERE id = ? AND status IN ('DRAFT','COUNTING','REJECTED')";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stocktakeId);
            int n = ps.executeUpdate();
            if (n > 0) {
                auditLogDAO.log(userId, "STOCKTAKE_CANCEL", "Stocktake id=" + stocktakeId);
            }
            return n > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ============================================================
    // VERIFICATION — quét serial xác minh khi đếm số lượng bị lệch
    // ============================================================

    /**
     * Kiểm tra phiếu QUANTITY có dòng chênh lệch hay không.
     * Nếu có → đặt verification_status = REQUIRED.
     * Nếu không → verification_status = NONE (cho phép gửi duyệt bình thường).
     * Gọi sau khi saveQuantityCounts.
     */
    public boolean checkAndSetVerificationRequired(int stocktakeId) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                boolean needsVerification = false;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM Stocktake_Details "
                      + "WHERE stocktake_id = ? AND (actual_qty <> theoretical_qty OR damaged_qty > 0)")) {
                    ps.setInt(1, stocktakeId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) needsVerification = rs.getInt(1) > 0;
                    }
                }

                String newStatus = needsVerification ? "REQUIRED" : "NONE";
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Stocktakes SET verification_status = ? WHERE id = ?")) {
                    ps.setString(1, newStatus);
                    ps.setInt(2, stocktakeId);
                    ps.executeUpdate();
                }

                conn.commit();
                return needsVerification;
            } catch (Exception ex) {
                conn.rollback();
                ex.printStackTrace();
                return false;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Lưu kết quả quét serial xác minh (chỉ cho các SKU lệch, trong phiếu QUANTITY).
     * Xóa item VERIFY cũ (nếu quét lại) → insert items mới với phase=VERIFY
     * → autoFillMissing CHỈ cho SKU lệch → rollup lại actual_qty cho SKU đã xác minh
     * → đánh dấu verification_status=COMPLETED.
     */
    public boolean saveVerificationCounts(int stocktakeId, List<StocktakeItem> items, int userId) {
        try (Connection conn = DBUtils.getConnection()) {
            conn.setAutoCommit(false);
            try {
                // Xóa item VERIFY cũ
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM Stocktake_Items WHERE stocktake_id = ? AND phase = 'VERIFY'")) {
                    ps.setInt(1, stocktakeId);
                    ps.executeUpdate();
                }

                // Insert items mới với phase=VERIFY
                String ins = "INSERT INTO Stocktake_Items "
                    + "(stocktake_id, product_item_id, product_id, serial_number, scanned_status, new_condition, note, phase) "
                    + "VALUES (?,?,?,?,?,?,?,'VERIFY')";
                try (PreparedStatement ps = conn.prepareStatement(ins)) {
                    for (StocktakeItem it : items) {
                        ps.setInt(1, stocktakeId);
                        if (it.getProductItemId() != null) ps.setInt(2, it.getProductItemId());
                        else ps.setNull(2, Types.INTEGER);
                        ps.setInt(3, it.getProductId());
                        ps.setString(4, it.getSerialNumber());
                        ps.setString(5, it.getScannedStatus());
                        if (it.getNewCondition() != null) ps.setString(6, it.getNewCondition());
                        else ps.setNull(6, Types.VARCHAR);
                        if (it.getNote() != null) ps.setString(7, it.getNote());
                        else ps.setNull(7, Types.VARCHAR);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }

                // Auto-fill MISSING CHỈ cho các SKU lệch (trong phiếu QUANTITY)
                Stocktake s = getById(stocktakeId);
                if (s != null) {
                    autoFillMissingForVerification(stocktakeId, s.getWarehouseId(), conn);
                }

                // Rollup actual_qty cho các SKU đã xác minh (đè lên số đếm tay)
                rollupVerificationCounts(stocktakeId, conn);

                // Đánh dấu COMPLETED
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Stocktakes SET verification_status = 'COMPLETED', "
                      + "verified_by = ?, verified_at = NOW() WHERE id = ?")) {
                    ps.setInt(1, userId);
                    ps.setInt(2, stocktakeId);
                    ps.executeUpdate();
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

    /**
     * Auto-fill MISSING serial CHỈ cho các SKU có chênh lệch (dùng trong verification).
     * Tìm serial IN_STOCK của SKU lệch mà chưa được quét trong phase=VERIFY → thêm MISSING.
     */
    private void autoFillMissingForVerification(int stocktakeId, int warehouseId, Connection conn) throws Exception {
        String sql =
            "INSERT INTO Stocktake_Items "
          + "(stocktake_id, product_item_id, product_id, serial_number, scanned_status, note, phase) "
          + "SELECT ?, pi.id, pi.product_id, pi.serial_number, 'MISSING', 'Auto: không tìm thấy khi xác minh', 'VERIFY' "
          + "FROM Product_Items pi "
          + "JOIN Stocktake_Details sd ON sd.product_id = pi.product_id AND sd.stocktake_id = ? "
          + "WHERE pi.warehouse_id = ? "
          + "  AND pi.status = 'IN_STOCK' "
          + "  AND sd.actual_qty <> sd.theoretical_qty "
          + "  AND pi.id NOT IN ("
          + "        SELECT product_item_id FROM Stocktake_Items "
          + "        WHERE stocktake_id = ? AND phase = 'VERIFY' AND product_item_id IS NOT NULL"
          + "  )";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stocktakeId);
            ps.setInt(2, stocktakeId);
            ps.setInt(3, warehouseId);
            ps.setInt(4, stocktakeId);
            ps.executeUpdate();
        }
    }

    /**
     * Rollup: cập nhật actual_qty / damaged_qty CHỈ cho các SKU đã xác minh (có item phase=VERIFY).
     * Các SKU không lệch (không xác minh) giữ nguyên số đếm tay.
     */
    private void rollupVerificationCounts(int stocktakeId, Connection conn) throws Exception {
        String varianceSql =
            "UPDATE Stocktake_Details d "
          + "SET d.actual_qty = ("
          + "    SELECT COUNT(*) FROM Stocktake_Items i "
          + "    WHERE i.stocktake_id = d.stocktake_id AND i.product_id = d.product_id "
          + "      AND i.phase = 'VERIFY' AND i.scanned_status IN ('FOUND','DAMAGED','EXTRA')"
          + "), "
          + "d.damaged_qty = ("
          + "    SELECT COUNT(*) FROM Stocktake_Items i "
          + "    WHERE i.stocktake_id = d.stocktake_id AND i.product_id = d.product_id "
          + "      AND i.phase = 'VERIFY' AND i.scanned_status = 'DAMAGED'"
          + ") "
          + "WHERE d.stocktake_id = ? "
          + "  AND d.actual_qty <> d.theoretical_qty "
          + "  AND EXISTS ("
          + "    SELECT 1 FROM Stocktake_Items i2 "
          + "    WHERE i2.stocktake_id = d.stocktake_id AND i2.product_id = d.product_id AND i2.phase = 'VERIFY'"
          + "  )";
        try (PreparedStatement ps = conn.prepareStatement(varianceSql)) {
            ps.setInt(1, stocktakeId);
            ps.executeUpdate();
        }

        String damagedOnlySql =
            "UPDATE Stocktake_Details d "
          + "SET d.damaged_qty = ("
          + "    SELECT COUNT(*) FROM Stocktake_Items i "
          + "    WHERE i.stocktake_id = d.stocktake_id AND i.product_id = d.product_id "
          + "      AND i.phase = 'VERIFY' AND i.scanned_status = 'DAMAGED'"
          + ") "
          + "WHERE d.stocktake_id = ? "
          + "  AND d.actual_qty = d.theoretical_qty "
          + "  AND d.damaged_qty > 0 "
          + "  AND EXISTS ("
          + "    SELECT 1 FROM Stocktake_Items i2 "
          + "    WHERE i2.stocktake_id = d.stocktake_id AND i2.product_id = d.product_id AND i2.phase = 'VERIFY'"
          + "  )";
        try (PreparedStatement ps = conn.prepareStatement(damagedOnlySql)) {
            ps.setInt(1, stocktakeId);
            ps.executeUpdate();
        }
    }

    /**
     * Lấy danh sách product_id có chênh lệch trong phiếu (dùng để hiện UI xác minh).
     */
    public List<Integer> getVarianceProductIds(int stocktakeId) {
        List<Integer> ids = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT product_id FROM Stocktake_Details "
              + "WHERE stocktake_id = ? AND actual_qty <> theoretical_qty")) {
            ps.setInt(1, stocktakeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getInt(1));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return ids;
    }

    public List<Integer> getVerificationProductIds(int stocktakeId) {
        List<Integer> ids = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT product_id FROM Stocktake_Details "
              + "WHERE stocktake_id = ? AND (actual_qty <> theoretical_qty OR damaged_qty > 0)")) {
            ps.setInt(1, stocktakeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getInt(1));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return ids;
    }

    public List<Integer> getDamagedOnlyProductIds(int stocktakeId) {
        List<Integer> ids = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT product_id FROM Stocktake_Details "
              + "WHERE stocktake_id = ? AND actual_qty = theoretical_qty AND damaged_qty > 0")) {
            ps.setInt(1, stocktakeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getInt(1));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return ids;
    }

    // ============================================================
    // Warehouse freeze check
    // ============================================================
    /**
     * Trả về phiếu kiểm kê đang "khóa" kho (status chưa kết thúc), null nếu kho rảnh.
     * Các status được coi là đang chạy: DRAFT, COUNTING, SUBMITTED, L1_APPROVED, APPROVED.
     * ADJUSTED, CANCELLED và REJECTED được coi là đã kết thúc → kho mở lại
     * (REJECTED: phiếu bị bác bỏ coi như xong, không giam kho vô thời hạn).
     */
    public Stocktake getActiveStocktakeForWarehouse(int warehouseId) {
        String sql = BASE_SELECT
                   + " WHERE s.warehouse_id = ? "
                   + "   AND s.status NOT IN ('ADJUSTED','CANCELLED','REJECTED') "
                   + " ORDER BY s.id DESC LIMIT 1";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Tiện ích: trả về true nếu kho đang khóa. */
    public boolean isWarehouseFrozen(int warehouseId) {
        return getActiveStocktakeForWarehouse(warehouseId) != null;
    }

    // ============================================================
    // Helpers — auto-fill MISSING + rollup
    // ============================================================
    private int[] getConditionBalances(int productId, int warehouseId, Connection conn) throws Exception {
        String sql = "SELECT inv.quantity, inv.quarantine_quantity, "
                + "COALESCE(SUM(CASE WHEN pi.status = 'IN_STOCK' AND pi.item_condition = 'USED' THEN 1 ELSE 0 END), 0) AS used_qty "
                + "FROM Inventories inv "
                + "LEFT JOIN Product_Items pi ON pi.product_id = inv.product_id AND pi.warehouse_id = inv.warehouse_id "
                + "WHERE inv.product_id = ? AND inv.warehouse_id = ? "
                + "GROUP BY inv.quantity, inv.quarantine_quantity";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, productId);
            ps.setInt(2, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int goodQty = rs.getInt("quantity");
                    int usedQty = Math.min(goodQty, rs.getInt("used_qty"));
                    return new int[] { Math.max(0, goodQty - usedQty), usedQty,
                            rs.getInt("quarantine_quantity") };
                }
            }
        }
        return new int[] {0, 0, 0};
    }

    /**
     * Với mỗi SKU trong phiếu, tìm các serial IN_STOCK trong kho mà chưa được scan
     * → tự thêm vào Stocktake_Items với scanned_status='MISSING'.
     * Bảo vệ người đếm quên: nếu không scan thì coi như mất.
     */
    private void autoFillMissingSerials(int stocktakeId, int warehouseId, Connection conn) throws Exception {
        String sql =
            "INSERT INTO Stocktake_Items "
          + "(stocktake_id, product_item_id, product_id, serial_number, scanned_status, note) "
          + "SELECT ?, pi.id, pi.product_id, pi.serial_number, 'MISSING', 'Auto: chưa scan khi kiểm kê' "
          + "FROM Product_Items pi "
          + "JOIN Stocktake_Details sd ON sd.product_id = pi.product_id AND sd.stocktake_id = ? "
          + "WHERE pi.warehouse_id = ? "
          + "  AND pi.status = 'IN_STOCK' "
          + "  AND pi.id NOT IN ("
          + "        SELECT product_item_id FROM Stocktake_Items "
          + "        WHERE stocktake_id = ? AND product_item_id IS NOT NULL"
          + "  )";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stocktakeId);
            ps.setInt(2, stocktakeId);
            ps.setInt(3, warehouseId);
            ps.setInt(4, stocktakeId);
            ps.executeUpdate();
        }
    }

    /** Tính lại actual_qty/damaged_qty cho mọi dòng detail dựa vào Stocktake_Items. */
    private void rollupSerialCounts(int stocktakeId, Connection conn) throws Exception {
        String sql =
            "UPDATE Stocktake_Details d "
          + "SET d.actual_qty = ("
          + "    SELECT COUNT(*) FROM Stocktake_Items i "
          + "    WHERE i.stocktake_id = d.stocktake_id AND i.product_id = d.product_id "
          + "      AND i.scanned_status IN ('FOUND','DAMAGED','EXTRA')"
          + "), "
          + "d.damaged_qty = ("
          + "    SELECT COUNT(*) FROM Stocktake_Items i "
          + "    WHERE i.stocktake_id = d.stocktake_id AND i.product_id = d.product_id "
          + "      AND i.scanned_status = 'DAMAGED'"
          + ") "
          + "WHERE d.stocktake_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, stocktakeId);
            ps.executeUpdate();
        }
    }

    // ============================================================
    // Generate code
    // ============================================================
    public String generateUniqueCode(Connection conn) throws Exception {
        int year = Calendar.getInstance().get(Calendar.YEAR);
        String prefix = "STK-" + year + "-";
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT stocktake_code FROM Stocktakes WHERE stocktake_code LIKE ? ORDER BY id DESC LIMIT 1")) {
            ps.setString(1, prefix + "%");
            try (ResultSet rs = ps.executeQuery()) {
                int next = 1;
                if (rs.next()) {
                    String last = rs.getString(1);
                    try { next = Integer.parseInt(last.substring(prefix.length())) + 1; }
                    catch (Exception ignore) {}
                }
                return prefix + String.format("%04d", next);
            }
        }
    }
}
