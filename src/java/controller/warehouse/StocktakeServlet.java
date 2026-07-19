package controller.warehouse;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import model.Product;
import model.Stocktake;
import model.StocktakeDetail;
import model.StocktakeItem;
import model.User;
import service.ProductService;
import service.StocktakeService;
import service.WarehouseService;

@WebServlet(name = "StocktakeServlet", urlPatterns = { "/warehouse/stocktake" })
public class StocktakeServlet extends HttpServlet {

    private final StocktakeService service = new StocktakeService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        if (!user.hasPermission("STOCKTAKE_VIEW")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem kiểm kê.");
            return;
        }

        switch (action) {
            case "list": {
                Integer wid = user.getWarehouseId();   // null = xem toàn hệ thống (Business Admin)
                String status = req.getParameter("status");
                req.setAttribute("stocktakeList", service.getAll(wid, status));
                req.getRequestDispatcher("/stocktake/list.jsp").forward(req, resp);
                break;
            }
            case "detail": {
                int id = Integer.parseInt(req.getParameter("id"));
                Stocktake s = service.getById(id);
                if (s == null) { resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake"); return; }
                req.setAttribute("stocktake", s);
                req.setAttribute("config", service.getConfig());
                req.getRequestDispatcher("/stocktake/detail.jsp").forward(req, resp);
                break;
            }
            case "add": {
                if (!user.hasPermission("STOCKTAKE_CREATE")) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo phiếu.");
                    return;
                }
                req.setAttribute("productList", new ProductService().getAllProducts());
                req.setAttribute("warehouseList", new WarehouseService().getAllActiveWarehouses());
                req.getRequestDispatcher("/stocktake/create.jsp").forward(req, resp);
                break;
            }
            case "count": {
                if (!user.hasPermission("STOCKTAKE_COUNT")) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền đếm.");
                    return;
                }
                int id = Integer.parseInt(req.getParameter("id"));
                Stocktake s = service.getById(id);
                if (s == null) { resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake"); return; }
                // Chỉ cho đếm khi DRAFT/COUNTING/REJECTED
                if (!(s.isDraft() || s.isCounting() || s.isRejected())) {
                    resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id);
                    return;
                }
                // Lần đầu mở → tự chuyển sang COUNTING
                if (s.isDraft() || s.isRejected()) {
                    service.startCounting(id, user.getId());
                    s = service.getById(id);
                }
                req.setAttribute("stocktake", s);
                req.getRequestDispatcher("/stocktake/count.jsp").forward(req, resp);
                break;
            }
            case "config": {
                if (!user.hasPermission("STOCKTAKE_CONFIG")) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền sửa ngưỡng.");
                    return;
                }
                req.setAttribute("config", service.getConfig());
                req.getRequestDispatcher("/stocktake/config.jsp").forward(req, resp);
                break;
            }
            case "verify": {
                if (!user.hasPermission("STOCKTAKE_COUNT")) {
                    resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xác minh.");
                    return;
                }
                int vid = Integer.parseInt(req.getParameter("id"));
                Stocktake vs = service.getById(vid);
                if (vs == null || !vs.isCounting() || !vs.isQuantityMode()) {
                    resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + vid);
                    return;
                }
                req.setAttribute("stocktake", vs);
                req.setAttribute("varianceProductIds", service.getVarianceProductIds(vid));
                req.setAttribute("verificationProductIds", service.getVerificationProductIds(vid));
                req.setAttribute("damagedOnlyProductIds", service.getDamagedOnlyProductIds(vid));
                req.getRequestDispatcher("/stocktake/verify.jsp").forward(req, resp);
                break;
            }
            case "lookupSerial": {
                handleLookupSerial(req, resp);
                break;
            }
            default:
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return; }

        String action = req.getParameter("action");
        if (action == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake");
            return;
        }

        switch (action) {
            case "add":         handleCreate(req, resp, user); break;
            case "saveCount":   handleSaveCount(req, resp, user); break;
            case "saveVerification": handleSaveVerification(req, resp, user); break;
            case "submit":      handleSubmit(req, resp, user); break;
            case "approveL1":   handleApproveL1(req, resp, user); break;
            case "approveL2":   handleApproveL2(req, resp, user); break;
            case "reject":      handleReject(req, resp, user); break;
            case "cancel":      handleCancel(req, resp, user); break;
            case "saveConfig":  handleSaveConfig(req, resp, user); break;
            default:
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake");
        }
    }

    // ===== CREATE =====
    private void handleCreate(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        if (!user.hasPermission("STOCKTAKE_CREATE")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo phiếu.");
            return;
        }
        try {
            int warehouseId = user.getWarehouseId() != null
                    ? user.getWarehouseId()
                    : Integer.parseInt(req.getParameter("warehouse_id"));
            String scope = req.getParameter("scope");
            String mode = req.getParameter("count_mode");
            String notes = req.getParameter("notes");

            Stocktake s = new Stocktake();
            s.setWarehouseId(warehouseId);
            s.setScope(scope == null ? Stocktake.SCOPE_PARTIAL : scope);
            s.setCountMode(mode == null ? Stocktake.MODE_QUANTITY : mode);
            s.setNotes(notes);
            s.setCreatedBy(user.getId());

            List<Integer> productIds = new ArrayList<>();
            if (Stocktake.SCOPE_PARTIAL.equals(s.getScope())) {
                String[] pids = req.getParameterValues("product_id");
                if (pids != null) {
                    for (String p : pids) {
                        if (p != null && !p.isEmpty()) productIds.add(Integer.parseInt(p));
                    }
                }
            }

            if (service.create(s, productIds)) {
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + s.getId());
            } else {
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=add&error=CreateFailed");
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=add&error=Invalid");
        }
    }

    // ===== SAVE COUNT (lưu nháp khi đếm) =====
    private void handleSaveCount(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        if (!user.hasPermission("STOCKTAKE_COUNT")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền đếm.");
            return;
        }
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            Stocktake s = service.getById(id);
            if (s == null || !s.isCounting()) {
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake");
                return;
            }

            if (s.isQuantityMode()) {
                List<StocktakeDetail> details = new ArrayList<>();
                String[] pids = req.getParameterValues("product_id");
                if (pids != null) {
                    for (String pidStr : pids) {
                        int pid = Integer.parseInt(pidStr);
                        StocktakeDetail d = new StocktakeDetail();
                        d.setProductId(pid);
                        d.setActualQty(parseIntSafe(req.getParameter("actual_" + pid), 0));
                        d.setDamagedQty(parseIntSafe(req.getParameter("damaged_" + pid), 0));
                        d.setVarianceReason(req.getParameter("reason_" + pid));
                        d.setNote(req.getParameter("note_" + pid));
                        details.add(d);
                    }
                }
                service.saveQuantityCounts(id, details);
                service.checkAndSetVerificationRequired(id);
            } else {
                // SERIAL mode — payload: arrays serial_number[], product_id[], scanned_status[], etc.
                List<StocktakeItem> items = new ArrayList<>();
                String[] serials = req.getParameterValues("serial_number");
                String[] productIds = req.getParameterValues("item_product_id");
                String[] statuses = req.getParameterValues("scanned_status");
                String[] itemIds = req.getParameterValues("product_item_id");
                String[] conditions = req.getParameterValues("new_condition");
                String[] notes = req.getParameterValues("item_note");
                if (serials != null) {
                    for (int i = 0; i < serials.length; i++) {
                        if (serials[i] == null || serials[i].trim().isEmpty()) continue;
                        StocktakeItem it = new StocktakeItem();
                        it.setSerialNumber(serials[i].trim());
                        it.setProductId(parseIntSafe(productIds != null && i < productIds.length ? productIds[i] : null, 0));
                        it.setScannedStatus(statuses != null && i < statuses.length ? statuses[i] : "FOUND");
                        String pidStr = itemIds != null && i < itemIds.length ? itemIds[i] : null;
                        if (pidStr != null && !pidStr.isEmpty() && !"null".equals(pidStr)) {
                            it.setProductItemId(Integer.parseInt(pidStr));
                        }
                        it.setNewCondition(conditions != null && i < conditions.length ? conditions[i] : null);
                        it.setNote(notes != null && i < notes.length ? notes[i] : null);
                        items.add(it);
                    }
                }
                service.saveSerialCounts(id, items);
            }

            String submit = req.getParameter("submit_after_save");
            if ("1".equals(submit)) {
                // Nếu QUANTITY mode và có chênh lệch chưa xác minh → chặn submit, redirect sang verify
                Stocktake updated = service.getById(id);
                if (updated.isQuantityMode() && updated.isVerificationRequired()) {
                    resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=verify&id=" + id
                            + "&msg=VerificationRequired");
                    return;
                }
                service.submit(id);
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id + "&msg=Submitted");
            } else {
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=count&id=" + id + "&msg=Saved");
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?error=SaveFailed");
        }
    }

    // ===== SAVE VERIFICATION (quét serial xác minh) =====
    private void handleSaveVerification(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        if (!user.hasPermission("STOCKTAKE_COUNT")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xác minh.");
            return;
        }
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            Stocktake s = service.getById(id);
            if (s == null || !s.isCounting() || !s.isQuantityMode()) {
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake");
                return;
            }

            List<StocktakeItem> items = new ArrayList<>();
            Set<Integer> damagedOnlyProductIds = new HashSet<>(service.getDamagedOnlyProductIds(id));
            String[] serials = req.getParameterValues("serial_number");
            String[] productIds = req.getParameterValues("item_product_id");
            String[] statuses = req.getParameterValues("scanned_status");
            String[] itemIds = req.getParameterValues("product_item_id");
            String[] conditions = req.getParameterValues("new_condition");
            String[] notes = req.getParameterValues("item_note");
            if (serials != null) {
                for (int i = 0; i < serials.length; i++) {
                    if (serials[i] == null || serials[i].trim().isEmpty()) continue;
                    StocktakeItem it = new StocktakeItem();
                    it.setSerialNumber(serials[i].trim());
                    it.setProductId(parseIntSafe(productIds != null && i < productIds.length ? productIds[i] : null, 0));
                    it.setScannedStatus(statuses != null && i < statuses.length ? statuses[i] : "FOUND");
                    String pidStr = itemIds != null && i < itemIds.length ? itemIds[i] : null;
                    if (pidStr != null && !pidStr.isEmpty() && !"null".equals(pidStr)) {
                        it.setProductItemId(Integer.parseInt(pidStr));
                    }
                    it.setNewCondition(conditions != null && i < conditions.length ? conditions[i] : null);
                    it.setNote(notes != null && i < notes.length ? notes[i] : null);
                    it.setPhase(StocktakeItem.PHASE_VERIFY);
                    if (damagedOnlyProductIds.contains(it.getProductId())
                            && !StocktakeItem.STATUS_DAMAGED.equals(it.getScannedStatus())) {
                        resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=verify&id=" + id
                                + "&error=DamagedOnlyRequiresDamagedSerials");
                        return;
                    }
                    items.add(it);
                }
            }

            service.saveVerificationCounts(id, items, user.getId());

            String submit = req.getParameter("submit_after_save");
            if ("1".equals(submit)) {
                service.submit(id);
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id + "&msg=Submitted");
            } else {
                resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=verify&id=" + id + "&msg=Saved");
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?error=VerifySaveFailed");
        }
    }

    // ===== SUBMIT =====
    private void handleSubmit(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        if (!user.hasPermission("STOCKTAKE_SUBMIT")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền gửi duyệt.");
            return;
        }
        Stocktake check = service.getById(id);
        if (check != null && check.isQuantityMode() && check.isVerificationRequired()) {
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=verify&id=" + id
                    + "&msg=VerificationRequired");
            return;
        }
        service.submit(id);
        resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id);
    }

    // ===== APPROVE L1 =====
    private void handleApproveL1(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        if (!user.hasPermission("STOCKTAKE_APPROVE_L1")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền duyệt cấp 1.");
            return;
        }
        boolean ok = service.approveL1(id, user.getId());
        resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id
                + (ok ? "&msg=ApprovedL1" : "&error=ApproveFailed"));
    }

    // ===== APPROVE L2 =====
    private void handleApproveL2(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        if (!user.hasPermission("STOCKTAKE_APPROVE_L2")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền duyệt cấp 2.");
            return;
        }
        boolean ok = service.approveL2(id, user.getId());
        resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id
                + (ok ? "&msg=Adjusted" : "&error=ApproveFailed"));
    }

    // ===== REJECT =====
    private void handleReject(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        String reason = req.getParameter("reject_reason");
        if (!user.hasPermission("STOCKTAKE_REJECT")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền bác bỏ.");
            return;
        }
        if (reason == null || reason.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id + "&error=NoReason");
            return;
        }
        service.reject(id, user.getId(), reason);
        resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id);
    }

    // ===== CANCEL =====
    private void handleCancel(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        if (!user.hasPermission("STOCKTAKE_CREATE")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền hủy.");
            return;
        }
        service.cancel(id, user.getId());
        resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=detail&id=" + id);
    }

    // ===== SAVE CONFIG =====
    private void handleSaveConfig(HttpServletRequest req, HttpServletResponse resp, User user)
            throws IOException {
        if (!user.hasPermission("STOCKTAKE_CONFIG")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền sửa ngưỡng.");
            return;
        }
        try {
            BigDecimal percent = new BigDecimal(req.getParameter("threshold_percent"));
            BigDecimal value = new BigDecimal(req.getParameter("threshold_value"));
            service.updateConfig(percent, value, user.getId());
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=config&msg=Saved");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse/stocktake?action=config&error=Invalid");
        }
    }

    // ===== AJAX LOOKUP SERIAL =====
    private void handleLookupSerial(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String serial = req.getParameter("serial");
        Integer warehouseIdParam = parseIntegerOrNull(req.getParameter("warehouse_id"));
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        if (serial == null || serial.trim().isEmpty()) {
            out.print("{\"success\":false,\"message\":\"Thiếu serial\"}");
            return;
        }
        try (java.sql.Connection conn = utils.DBUtils.getConnection();
             java.sql.PreparedStatement ps = conn.prepareStatement(
                "SELECT i.id, i.product_id, i.status, i.item_condition, i.warehouse_id, p.product_name, p.sku "
              + "FROM Product_Items i JOIN Products p ON p.id = i.product_id "
              + "WHERE i.serial_number = ?")) {
            ps.setString(1, serial.trim());
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    int wh = rs.getInt("warehouse_id");
                    if (warehouseIdParam != null && wh != warehouseIdParam) {
                        out.print("{\"success\":false,\"message\":\"Serial này thuộc kho khác.\"}");
                        return;
                    }
                    out.print("{\"success\":true,"
                            + "\"productItemId\":" + rs.getInt("id") + ","
                            + "\"productId\":" + rs.getInt("product_id") + ","
                            + "\"productName\":\"" + escapeJson(rs.getString("product_name")) + "\","
                            + "\"sku\":\"" + escapeJson(rs.getString("sku")) + "\","
                            + "\"status\":\"" + rs.getString("status") + "\","
                            + "\"itemCondition\":\"" + rs.getString("item_condition") + "\"}");
                } else {
                    out.print("{\"success\":false,\"message\":\"Serial này chưa có trong hệ thống — sẽ được lưu là EXTRA.\"}");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\":false,\"message\":\"Lỗi tra cứu\"}");
        }
    }

    private int parseIntSafe(String v, int def) {
        if (v == null || v.isEmpty()) return def;
        try { return Integer.parseInt(v); } catch (Exception e) { return def; }
    }

    private Integer parseIntegerOrNull(String v) {
        if (v == null || v.isEmpty()) return null;
        try { return Integer.parseInt(v); } catch (Exception e) { return null; }
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
