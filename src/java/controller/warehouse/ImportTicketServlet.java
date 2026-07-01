package controller.warehouse;

import service.RequestService;
import service.TicketService;
import service.ProductItemService;
import service.ManufacturerSerialExcelService;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import model.ProductItem;
import model.Request;
import model.Ticket;
import model.TicketDetail;
import model.User;

@WebServlet(name = "ImportTicketServlet", urlPatterns = { "/warehouse/import-ticket", "/warehouse/import" })
@MultipartConfig(maxFileSize = 5 * 1024 * 1024)
public class ImportTicketServlet extends HttpServlet {

    private static final String TYPE = Ticket.TYPE_IN;

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

        if (("list".equals(action) || "detail".equals(action)) && !loggedInUser.hasPermission("TICKET_VIEW_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem phiếu nhập.");
            return;
        }
        if ("add".equals(action) && !loggedInUser.hasPermission("TICKET_ADD_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo phiếu nhập.");
            return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();

        switch (action) {
            case "list":
                httpReq.setAttribute("ticketList", ticketService.getAll(TYPE));
                httpReq.getRequestDispatcher("/import/import-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Ticket ticket = ticketService.getById(id);
                if (ticket == null) {
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
                    return;
                }
                if (Ticket.STATUS_CONFIRMED.equals(ticket.getStatus())
                        || Ticket.STATUS_COMPLETED.equals(ticket.getStatus())) {
                    List<ProductItem> serials = new ProductItemService().getItemsByTicketId(id);
                    httpReq.setAttribute("importedSerials", serials);
                } else if (Ticket.STATUS_DRAFT.equals(ticket.getStatus())
                        && Request.REASON_RETURN.equals(ticket.getRequestReason()) && ticket.getDetails() != null) {
                    java.util.Map<Integer, List<String>> availableSerials = new java.util.HashMap<>();
                    Request req = requestService.getById(ticket.getRequestId());
                    String expectedSerialsStr = req != null ? req.getExpectedSerials() : null;
                    List<String> expectedSerialsList = new ArrayList<>();
                    if (expectedSerialsStr != null && !expectedSerialsStr.trim().isEmpty()) {
                        for (String s : expectedSerialsStr.split(",")) {
                            if (s != null && !s.trim().isEmpty()) expectedSerialsList.add(s.trim());
                        }
                    }
                    
                    for (TicketDetail d : ticket.getDetails()) {
                        List<String> serials = new ArrayList<>();
                        for (String s : expectedSerialsList) {
                            try (java.sql.Connection conn = utils.DBUtils.getConnection();
                                 PreparedStatement ps = conn.prepareStatement(
                                         "SELECT COUNT(*) FROM Product_Items WHERE serial_number = ? AND product_id = ?")) {
                                ps.setString(1, s);
                                ps.setInt(2, d.getProductId());
                                try (java.sql.ResultSet rs = ps.executeQuery()) {
                                    if (rs.next() && rs.getInt(1) > 0) {
                                        serials.add(s);
                                    }
                                }
                            } catch (Exception ex) {
                                ex.printStackTrace();
                            }
                        }
                        availableSerials.put(d.getProductId(), serials);
                    }
                    httpReq.setAttribute("availableSerials", availableSerials);
                }
                httpReq.setAttribute("ticket", ticket);
                httpReq.getRequestDispatcher("/import/import-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                // Lá»c theo kho cá»§a user: staff_hcm chá»‰ tháº¥y yĂªu cáº§u nháº­p cá»§a TPHCM, staff_hn
                // chá»‰ tháº¥y HN
                Integer userWh = loggedInUser.getWarehouseId();
                // Block khi kho đang có phiếu kiểm kê chạy
                if (userWh != null) {
                    model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(userWh);
                    if (active != null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list"
                                + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                        return;
                    }
                }
                List<Request> pendingRequests = requestService.getPendingOrApproved(Request.TYPE_IN, userWh);
                httpReq.setAttribute("requestList", pendingRequests);
                String reqIdParam = httpReq.getParameter("request_id");
                if (reqIdParam != null && !reqIdParam.trim().isEmpty()) {
                    int reqId = Integer.parseInt(reqIdParam);
                    httpReq.setAttribute("selectedRequest", requestService.getById(reqId));
                }
                httpReq.getRequestDispatcher("/import/import-add.jsp").forward(httpReq, response);
                break;
            }
            default:
                response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
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
            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
            return;
        }

        if ("add".equals(action) && !loggedInUser.hasPermission("TICKET_ADD_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo.");
            return;
        }
        if ("confirm".equals(action) && !loggedInUser.hasPermission("TICKET_CONFIRM_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xác nhận.");
            return;
        }
        if ("cancel".equals(action) && !loggedInUser.hasPermission("TICKET_CANCEL_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền hủy.");
            return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();

        try {
            switch (action) {
                case "add": {
                    int reqId = Integer.parseInt(httpReq.getParameter("request_id"));
                    Request req = requestService.getById(reqId);
                    if (req == null || req.getCancelRequestedAt() != null
                            || Request.STATUS_CANCELLED.equals(req.getStatus())) {
                        response.sendRedirect(
                                httpReq.getContextPath() + "/warehouse/import-ticket?action=add&error=CancelRequested");
                        return;
                    }
                    // Block khi kho đang kiểm kê
                    if (loggedInUser.getWarehouseId() != null) {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(loggedInUser.getWarehouseId());
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
                    }
                    if (loggedInUser.getWarehouseId() == null) {
                        response.sendRedirect(
                                httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId
                                        + "&error=RequiresWarehouseAssignment");
                        return;
                    }
                    // Check: user pháº£i cĂ¹ng kho vá»›i Request (Request.warehouseId = kho Ä‘Ă­ch nháº­p
                    // hĂ ng)
                    if (loggedInUser.getWarehouseId() != req.getWarehouseId()) {
                        response.sendRedirect(httpReq.getContextPath()
                                + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=WrongWarehouse");
                        return;
                    }
                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    String[] unitPrices = httpReq.getParameterValues("unit_price");
                    String[] conditions = httpReq.getParameterValues("item_condition");
                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(httpReq.getContextPath()
                                + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=NoItems");
                        return;
                    }
                    List<TicketDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0)
                            continue;
                        TicketDetail d = new TicketDetail();
                        d.setProductId(Integer.parseInt(productIds[i]));
                        d.setQuantity(qty);
                        d.setUnitCost(new java.math.BigDecimal(unitPrices[i]));
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath()
                                + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=NoItemsReceived");
                        return;
                    }
                    Ticket ticket = new Ticket();
                    ticket.setType(Ticket.TYPE_IN);
                    ticket.setRequestId(reqId);
                    ticket.setWarehouseId(loggedInUser.getWarehouseId());
                    ticket.setKeeperId(loggedInUser.getId());
                    if (!ticketService.add(ticket, details)) {
                        response.sendRedirect(httpReq.getContextPath()
                                + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=Failed");
                        return;
                    }
                    break;
                }
                case "confirm": {
                    int confirmId = Integer.parseInt(httpReq.getParameter("id"));
                    // Block khi kho đang kiểm kê
                    {
                        Ticket ticketForConfirm = ticketService.getById(confirmId);
                        if (ticketForConfirm != null) {
                            model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(ticketForConfirm.getWarehouseId());
                            if (active != null) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=detail&id=" + confirmId
                                        + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                                return;
                            }
                        }
                    }
                    String[] scannedSerials = httpReq.getParameterValues("scanned_serials");
                    List<String> serials = null;
                    if (scannedSerials != null && scannedSerials.length > 0) {
                        serials = new ArrayList<>();
                        for (String s : scannedSerials) {
                            if (s != null && !s.trim().isEmpty())
                                serials.add(s.trim());
                        }
                    }
                    @SuppressWarnings("unchecked")
                    Map<String, List<String>> mfrSerials = (Map<String, List<String>>) session.getAttribute("mfrSerials_" + confirmId);

                    // Nếu chưa có Excel serials trong session, kiểm tra xem người dùng có quét mã vạch NSX không
                    if (mfrSerials == null) {
                        String[] scanParams = httpReq.getParameterValues("manufacturer_serial_scan");
                        if (scanParams != null && scanParams.length > 0) {
                            mfrSerials = new LinkedHashMap<>();
                            for (String param : scanParams) {
                                if (param == null || !param.contains("|")) continue;
                                int sep = param.indexOf('|');
                                String sku = param.substring(0, sep).trim();
                                String serial = param.substring(sep + 1).trim();
                                if (!sku.isEmpty() && !serial.isEmpty()) {
                                    mfrSerials.computeIfAbsent(sku, k -> new ArrayList<>()).add(serial);
                                }
                            }
                            if (mfrSerials.isEmpty()) mfrSerials = null;
                        }
                    }

                    ticketService.confirm(confirmId, loggedInUser.getId(), serials, mfrSerials);
                    session.removeAttribute("mfrSerials_" + confirmId);
                    break;
                }
                case "cancel":
                    ticketService.cancel(Integer.parseInt(httpReq.getParameter("id")));
                    break;
                case "uploadSerials": {
                    int ticketId = Integer.parseInt(httpReq.getParameter("id"));
                    Ticket ticket = ticketService.getById(ticketId);
                    response.setContentType("application/json;charset=UTF-8");
                    PrintWriter out = response.getWriter();

                    if (ticket == null || !Ticket.STATUS_DRAFT.equals(ticket.getStatus())) {
                        out.print("{\"valid\":false,\"errors\":[\"Phiếu không tồn tại hoặc không ở trạng thái DRAFT.\"]}");
                        return;
                    }
                    if (!Request.REASON_PURCHASE.equals(ticket.getRequestReason())) {
                        out.print("{\"valid\":false,\"errors\":[\"Upload serial NSX chỉ áp dụng cho phiếu nhập mua hàng (PURCHASE).\"]}");
                        return;
                    }

                    Part filePart = httpReq.getPart("excelFile");
                    if (filePart == null || filePart.getSize() == 0) {
                        out.print("{\"valid\":false,\"errors\":[\"Chưa chọn file.\"]}");
                        return;
                    }

                    Map<String, Integer> expectedBySku = new LinkedHashMap<>();
                    if (ticket.getDetails() != null) {
                        for (TicketDetail d : ticket.getDetails()) {
                            expectedBySku.put(d.getSku(), d.getQuantity());
                        }
                    }

                    ManufacturerSerialExcelService excelService = new ManufacturerSerialExcelService();
                    ManufacturerSerialExcelService.ParseResult result;
                    try (InputStream is = filePart.getInputStream()) {
                        result = excelService.parseAndValidate(is, expectedBySku);
                    }

                    if (result.isValid()) {
                        session.setAttribute("mfrSerials_" + ticketId, result.getSerialsBySku());
                    }

                    StringBuilder json = new StringBuilder();
                    json.append("{\"valid\":").append(result.isValid());
                    json.append(",\"totalSerials\":").append(result.getTotalSerials());
                    json.append(",\"errors\":[");
                    for (int i = 0; i < result.getErrors().size(); i++) {
                        if (i > 0) json.append(",");
                        json.append("\"").append(result.getErrors().get(i).replace("\"", "\\\"")).append("\"");
                    }
                    json.append("],\"serialsBySku\":{");
                    int skuIdx = 0;
                    for (Map.Entry<String, List<String>> entry : result.getSerialsBySku().entrySet()) {
                        if (skuIdx++ > 0) json.append(",");
                        json.append("\"").append(entry.getKey()).append("\":[");
                        for (int i = 0; i < entry.getValue().size(); i++) {
                            if (i > 0) json.append(",");
                            json.append("\"").append(entry.getValue().get(i).replace("\"", "\\\"")).append("\"");
                        }
                        json.append("]");
                    }
                    json.append("}}");
                    out.print(json);
                    return;
                }
                case "clearSerials": {
                    int ticketId = Integer.parseInt(httpReq.getParameter("id"));
                    session.removeAttribute("mfrSerials_" + ticketId);
                    response.setContentType("application/json;charset=UTF-8");
                    response.getWriter().print("{\"ok\":true}");
                    return;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
    }
}
