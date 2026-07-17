package controller.warehouse;

import service.RequestService;
import service.TicketService;
import service.SupplierService;
import service.ProductService;
import service.WarehouseService;
import java.io.IOException;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Request;
import model.RequestDetail;
import model.Ticket;
import model.TicketDetail;
import model.Supplier;
import model.Product;
import model.User;
import model.Warehouse;

@WebServlet(name = "ImportRequestServlet", urlPatterns = { "/warehouse/import-request" })
public class ImportRequestServlet extends HttpServlet {

    private static final String TYPE = Request.TYPE_IN;

    private boolean canAccessWarehouse(User user, int warehouseId) {
        return isSalesUser(user) || user.getWarehouseId() == null || user.getWarehouseId() == warehouseId;
    }

    private List<Warehouse> getAccessibleWarehouses(User user) {
        List<Warehouse> warehouses = new ArrayList<>(new WarehouseService().getAllActiveWarehouses());
        if (user.getWarehouseId() != null) {
            warehouses.removeIf(warehouse -> warehouse.getId() != user.getWarehouseId());
        }
        return warehouses;
    }

    private boolean isSalesUser(User user) {
        return user.getRoleId() == 5 || "Sales Staff".equalsIgnoreCase(user.getRoleName());
    }

    @Override
    protected void doGet(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) {
            response.sendRedirect(httpReq.getContextPath() + "/login");
            return;
        }

        String action = httpReq.getParameter("action");
        if (action == null)
            action = "list";

        if (("list".equals(action) || "detail".equals(action)) && !loggedInUser.hasPermission("REQUEST_VIEW_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem yêu cầu nhập.");
            return;
        }
        if (("add".equals(action) || "addReturn".equals(action) || "lookupSerial".equals(action)) && !loggedInUser.hasPermission("REQUEST_ADD_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo yêu cầu nhập.");
            return;
        }

        RequestService dao = new RequestService();
        TicketService ticketService = new TicketService();

        switch (action) {
            case "list":
                Integer importOwnerId = isSalesUser(loggedInUser) ? loggedInUser.getId() : null;
                Integer importWarehouseId = isSalesUser(loggedInUser) ? null : loggedInUser.getWarehouseId();
                httpReq.setAttribute("requestList", dao.getForList(TYPE, importWarehouseId, importOwnerId));
                httpReq.getRequestDispatcher("/import_request/request-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Request req = dao.getById(id);
                if (req == null) {
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list");
                    return;
                }
                if (!canAccessWarehouse(loggedInUser, req.getWarehouseId())) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Request belongs to another warehouse.");
                    return;
                }
                List<Ticket> tickets = ticketService.getByRequestId(id);
                httpReq.setAttribute("req", req);
                httpReq.setAttribute("ticketList", tickets);
                httpReq.getRequestDispatcher("/import_request/request-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                httpReq.setAttribute("supplierList", new SupplierService().getActiveSuppliers());
                httpReq.setAttribute("productList", new ProductService().getAllProducts());
                httpReq.setAttribute("warehouseList", getAccessibleWarehouses(loggedInUser));
                httpReq.getRequestDispatcher("/import_request/request-add.jsp").forward(httpReq, response);
                break;
            }
            case "addReturn": {
                httpReq.setAttribute("warehouseList", getAccessibleWarehouses(loggedInUser));
                httpReq.getRequestDispatcher("/import_request/return-add.jsp").forward(httpReq, response);
                break;
            }
            case "lookupSerial": {
                String serial = httpReq.getParameter("serial");
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");
                java.io.PrintWriter out = response.getWriter();
                
                if (serial == null || serial.trim().isEmpty()) {
                    out.print("{\"success\":false,\"message\":\"Thiếu số Serial.\"}");
                    out.flush();
                    return;
                }
                
                String sql = 
                    "SELECT pi.id AS item_id, pi.product_id, p.product_name, p.sku, p.unit, "
                  + "       t.id AS ticket_id, t.ticket_code, r.partner_type, r.partner_id, "
                  + "       CASE r.partner_type "
                  + "           WHEN 'SUPPLIER' THEN (SELECT supplier_name FROM Suppliers WHERE id = r.partner_id) "
                  + "           WHEN 'CUSTOMER' THEN (SELECT customer_name FROM Customers WHERE id = r.partner_id) "
                  + "           WHEN 'WAREHOUSE' THEN (SELECT warehouse_name FROM Warehouses WHERE id = r.partner_id) "
                  + "           WHEN 'INTERNAL_DEST' THEN (SELECT destination_name FROM Internal_Destinations WHERE id = r.partner_id) "
                  + "           ELSE NULL END AS partner_name "
                  + "FROM Product_Items pi "
                  + "JOIN Products p ON p.id = pi.product_id "
                  + "LEFT JOIN Product_Item_Movements m ON m.product_item_id = pi.id AND m.action IN ('EXPORT_OUT','TRANSFER_OUT') "
                  + "LEFT JOIN Tickets t ON t.id = m.ticket_id "
                  + "LEFT JOIN Requests r ON r.id = t.request_id "
                  + "WHERE pi.serial_number = ? AND pi.status = 'EXPORTED' "
                  + "ORDER BY m.id DESC LIMIT 1";
                  
                try (java.sql.Connection conn = utils.DBUtils.getConnection();
                     PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, serial.trim());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            StringBuilder json = new StringBuilder();
                            json.append("{\"success\":true,")
                                .append("\"productId\":").append(rs.getInt("product_id")).append(",")
                                .append("\"productName\":\"").append(rs.getString("product_name").replace("\"", "\\\"")).append("\",")
                                .append("\"sku\":\"").append(rs.getString("sku")).append("\",")
                                .append("\"unit\":\"").append(rs.getString("unit")).append("\",")
                                .append("\"ticketId\":").append(rs.getInt("ticket_id")).append(",")
                                .append("\"ticketCode\":\"").append(rs.getString("ticket_code")).append("\",")
                                .append("\"partnerName\":\"").append(rs.getString("partner_name") != null ? rs.getString("partner_name").replace("\"", "\\\"") : "").append("\"")
                                .append("}");
                            out.print(json.toString());
                        } else {
                            String checkSql = "SELECT status FROM Product_Items WHERE serial_number = ?";
                            try (PreparedStatement ps2 = conn.prepareStatement(checkSql)) {
                                ps2.setString(1, serial.trim());
                                try (ResultSet rs2 = ps2.executeQuery()) {
                                    if (rs2.next()) {
                                        String status = rs2.getString("status");
                                        String msg = "Mã Serial đang ở trạng thái '" + status + "' (Không thể trả lại).";
                                        out.print("{\"success\":false,\"message\":\"" + msg + "\"}");
                                    } else {
                                        out.print("{\"success\":false,\"message\":\"Mã Serial không tồn tại trên hệ thống.\"}");
                                    }
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    out.print("{\"success\":false,\"message\":\"Lỗi truy vấn cơ sở dữ liệu.\"}");
                }
                out.flush();
                return;
            }
            default:
                response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) {
            response.sendRedirect(httpReq.getContextPath() + "/login");
            return;
        }

        String action = httpReq.getParameter("action");
        if (action == null) {
            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list");
            return;
        }

        if (("add".equals(action) || "addReturn".equals(action)) && !loggedInUser.hasPermission("REQUEST_ADD_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo yêu cầu nhập.");
            return;
        }
        if (("approve".equals(action) || "reject".equals(action))
                && !loggedInUser.hasPermission("REQUEST_APPROVE_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền duyệt yêu cầu nhập.");
            return;
        }
        if (("approveCancel".equals(action) || "rejectCancel".equals(action))
                && !loggedInUser.hasPermission("REQUEST_APPROVE_CANCEL_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền duyệt hủy.");
            return;
        }

        // Chống thao tác nhầm loại: mọi hành động trên 1 yêu cầu cụ thể phải đúng loại NHẬP (IN).
        if ("approve".equals(action) || "reject".equals(action) || "cancel".equals(action)
                || "approveCancel".equals(action) || "rejectCancel".equals(action)) {
            String idStr = httpReq.getParameter("id");
            if (idStr != null && !idStr.isEmpty()) {
                try {
                    Request guardReq = new RequestService().getById(Integer.parseInt(idStr));
                    if (guardReq == null || !TYPE.equals(guardReq.getType())
                            || !canAccessWarehouse(loggedInUser, guardReq.getWarehouseId())) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Yêu cầu không hợp lệ cho luồng nhập kho.");
                        return;
                    }
                } catch (NumberFormatException ignore) {}
            }
        }

        RequestService dao = new RequestService();

        try {
            switch (action) {
                case "add": {
                    int supplierId = Integer.parseInt(httpReq.getParameter("supplier_id"));
                    int warehouseId = parseWarehouseId(httpReq, loggedInUser);
                    // Block khi kho đang kiểm kê
                    {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(warehouseId);
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
                    }
                    Date expectedDate = Date.valueOf(httpReq.getParameter("expected_date"));
                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    String[] unitPrices = httpReq.getParameterValues("unit_price");

                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(
                                httpReq.getContextPath() + "/warehouse/import-request?action=add&error=NoProducts");
                        return;
                    }
                    List<RequestDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        if (productIds[i] == null || productIds[i].trim().isEmpty())
                            continue;
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0)
                            continue;
                        java.math.BigDecimal price = new java.math.BigDecimal(unitPrices[i]);
                        if (price.compareTo(java.math.BigDecimal.ZERO) <= 0) {
                            response.sendRedirect(
                                    httpReq.getContextPath() + "/warehouse/import-request?action=add&error=InvalidPrice");
                            return;
                        }
                        RequestDetail d = new RequestDetail();
                        d.setProductId(Integer.parseInt(productIds[i]));
                        d.setQuantity(qty);
                        d.setUnitPrice(price);
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(
                                httpReq.getContextPath() + "/warehouse/import-request?action=add&error=NoValidDetails");
                        return;
                    }
                    Request req = new Request();
                    req.setType(Request.TYPE_IN);
                    req.setReason(Request.REASON_PURCHASE);
                    req.setWarehouseId(warehouseId);
                    req.setPartnerType(Request.PARTNER_SUPPLIER);
                    req.setPartnerId(supplierId);
                    req.setStaffId(loggedInUser.getId());
                    req.setExpectedDate(expectedDate);
                    if (!dao.add(req, details)) {
                        response.sendRedirect(
                                httpReq.getContextPath() + "/warehouse/import-request?action=add&error=Failed");
                        return;
                    }
                    break;
                }
                case "addReturn": {
                    String returnReason = httpReq.getParameter("return_reason");
                    Date expectedDate = Date.valueOf(httpReq.getParameter("expected_date"));
                    int warehouseId = parseWarehouseId(httpReq, loggedInUser);
                    // Block khi kho đang kiểm kê
                    {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(warehouseId);
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
                    }
                    String requestedCondition = httpReq.getParameter("requested_condition");

                    String refTicketIdStr = httpReq.getParameter("ref_ticket_id");
                    if (refTicketIdStr == null || refTicketIdStr.trim().isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=NoRefTicket"); return;
                    }
                    int refTicketId = Integer.parseInt(refTicketIdStr);
                    Ticket refTicket = new TicketService().getById(refTicketId);
                    if (refTicket == null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=InvalidTicket"); return;
                    }
                    Request refTicketReq = dao.getById(refTicket.getRequestId());
                    if (refTicketReq == null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=InvalidTicketRequest"); return;
                    }

                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] scannedSerials = httpReq.getParameterValues("scanned_serials");

                    if (returnReason == null || returnReason.trim().isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=NoReason"); return;
                    }
                    if (productIds == null || productIds.length == 0 || scannedSerials == null || scannedSerials.length == 0) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=NoProducts"); return;
                    }

                    // Group and sum product quantities
                    java.util.Map<Integer, Integer> prodQtyMap = new java.util.HashMap<>();
                    for (String pidStr : productIds) {
                        if (pidStr == null || pidStr.trim().isEmpty()) continue;
                        int pid = Integer.parseInt(pidStr);
                        prodQtyMap.put(pid, prodQtyMap.getOrDefault(pid, 0) + 1);
                    }

                    List<RequestDetail> details = new ArrayList<>();
                    for (java.util.Map.Entry<Integer, Integer> entry : prodQtyMap.entrySet()) {
                        RequestDetail d = new RequestDetail();
                        d.setProductId(entry.getKey());
                        d.setQuantity(entry.getValue());
                        details.add(d);
                    }

                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=NoValidDetails"); return;
                    }

                    // Build expected serials string
                    List<String> serialList = new ArrayList<>();
                    for (String s : scannedSerials) {
                        if (s != null && !s.trim().isEmpty()) {
                            serialList.add(s.trim());
                        }
                    }
                    String expectedSerialsStr = String.join(",", serialList);

                    Request req = new Request();
                    req.setType(Request.TYPE_IN);
                    req.setReason(Request.REASON_RETURN);
                    req.setWarehouseId(warehouseId);
                    req.setPartnerType(refTicketReq.getPartnerType());
                    req.setPartnerId(refTicketReq.getPartnerId());
                    req.setRefTicketId(refTicketId);
                    req.setReturnReason(returnReason.trim());
                    req.setRequestedCondition(requestedCondition);
                    req.setExpectedSerials(expectedSerialsStr);
                    req.setStaffId(loggedInUser.getId());
                    req.setExpectedDate(expectedDate);

                    if (!dao.add(req, details)) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=addReturn&error=Failed"); return;
                    }
                    break;
                }
                case "approve":
                    dao.updateStatus(Integer.parseInt(httpReq.getParameter("id")), Request.STATUS_APPROVED,
                            loggedInUser.getId());
                    break;
                case "reject":
                    dao.updateStatus(Integer.parseInt(httpReq.getParameter("id")), Request.STATUS_REJECTED,
                            loggedInUser.getId());
                    break;
                case "cancel": {
                    int cancelId = Integer.parseInt(httpReq.getParameter("id"));
                    Request req = dao.getById(cancelId);
                    if (req == null)
                        break;
                    if (Request.STATUS_PENDING.equals(req.getStatus())) {
                        if (!loggedInUser.hasPermission("REQUEST_CANCEL_IN")) {
                            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền hủy.");
                            return;
                        }
                        dao.cancelRequest(cancelId, loggedInUser.getId());
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list");
                        return;
                    } else if (Request.STATUS_APPROVED.equals(req.getStatus())
                            || Request.STATUS_PARTIALLY_COMPLETED.equals(req.getStatus())) {
                        if (!loggedInUser.hasPermission("REQUEST_REQUEST_CANCEL_IN")) {
                            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền đề xuất hủy.");
                            return;
                        }
                        dao.requestCancel(cancelId, loggedInUser.getId(), httpReq.getParameter("reason"));
                        response.sendRedirect(
                                httpReq.getContextPath() + "/warehouse/import-request?action=detail&id=" + cancelId);
                        return;
                    }
                    break;
                }
                case "approveCancel": {
                    int id = Integer.parseInt(httpReq.getParameter("id"));
                    boolean approved = dao.approveCancel(id, loggedInUser.getId());
                    response.sendRedirect(
                            httpReq.getContextPath() + "/warehouse/import-request?action=detail&id=" + id
                                    + (approved ? "&success=CancelApproved" : "&error=CancelApprovalFailed"));
                    return;
                }
                case "rejectCancel": {
                    int id = Integer.parseInt(httpReq.getParameter("id"));
                    dao.rejectCancel(id);
                    response.sendRedirect(
                            httpReq.getContextPath() + "/warehouse/import-request?action=detail&id=" + id);
                    return;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-request?action=list");
    }

    /**
     * Láº¥y warehouse_id: form param Æ°u tiĂªn, fallback vá» user.warehouseId, cuá»‘i cĂ¹ng
     * 1.
     */
    private int parseWarehouseId(HttpServletRequest httpReq, User user) {
        if (user.getWarehouseId() != null) return user.getWarehouseId();
        String p = httpReq.getParameter("warehouse_id");
        if (p != null && !p.trim().isEmpty()) {
            try {
                return Integer.parseInt(p);
            } catch (NumberFormatException ignored) {
            }
        }
        if (user.getWarehouseId() != null) return user.getWarehouseId();
        throw new IllegalStateException("Chưa chọn kho nhận hàng");
    }
}
