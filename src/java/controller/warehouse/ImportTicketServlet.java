package controller.warehouse;

import service.RequestService;
import service.TicketService;
import service.ProductItemService;
import service.ProductService;
import service.ManufacturerSerialExcelService;
import model.Product;
import java.io.IOException;
import java.io.InputStream;
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

        if ("addAndConfirm".equals(action)
                && !(loggedInUser.hasPermission("TICKET_ADD_IN") && loggedInUser.hasPermission("TICKET_CONFIRM_IN"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo và nhập kho.");
            return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();

        try {
            switch (action) {
                case "addAndConfirm": {
                    // GỘP 1 MÀN HÌNH: tạo phiếu nhập + nhập kho trong 1 bước, không để lại phiếu nháp.
                    int reqId = Integer.parseInt(httpReq.getParameter("request_id"));
                    Request req = requestService.getById(reqId);
                    if (req == null || req.getCancelRequestedAt() != null
                            || !(Request.STATUS_APPROVED.equals(req.getStatus())
                                || Request.STATUS_PARTIALLY_COMPLETED.equals(req.getStatus()))) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&error=RequestNotApproved");
                        return;
                    }
                    if (loggedInUser.getWarehouseId() != null) {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(loggedInUser.getWarehouseId());
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
                    }
                    if (loggedInUser.getWarehouseId() == null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=RequiresWarehouseAssignment");
                        return;
                    }
                    if (loggedInUser.getWarehouseId() != req.getWarehouseId()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=WrongWarehouse");
                        return;
                    }

                    boolean isTransfer = Request.REASON_TRANSFER.equals(req.getReason());
                    boolean isReturn = Request.REASON_RETURN.equals(req.getReason());
                    boolean isPurchase = Request.REASON_PURCHASE.equals(req.getReason());

                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    String[] unitPrices = httpReq.getParameterValues("unit_price");
                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=NoItems");
                        return;
                    }
                    List<TicketDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0) continue;
                        // Giá: chỉ BẮT BUỘC > 0 với nhập MUA (PURCHASE). Chuyển kho/Trả hàng không cần giá.
                        java.math.BigDecimal price = java.math.BigDecimal.ZERO;
                        if (unitPrices != null && i < unitPrices.length && unitPrices[i] != null && !unitPrices[i].trim().isEmpty()) {
                            price = new java.math.BigDecimal(unitPrices[i].trim());
                        }
                        if (isPurchase && price.compareTo(java.math.BigDecimal.ZERO) <= 0) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=InvalidPrice");
                            return;
                        }
                        TicketDetail d = new TicketDetail();
                        d.setProductId(Integer.parseInt(productIds[i]));
                        d.setQuantity(qty);
                        d.setUnitCost(price);
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=NoItemsReceived");
                        return;
                    }

                    // RETURN/TRANSFER: serial được xác định từ hàng đã xuất / đang trên đường (không cần quét ở đây,
                    // DAO tự lấy). Ở đây chỉ truyền serial nếu người dùng có nhập tay cho RETURN.
                    String[] scanned = httpReq.getParameterValues("scanned_serials");
                    List<String> serials = null;
                    if (scanned != null && scanned.length > 0) {
                        serials = new ArrayList<>();
                        for (String s : scanned) if (s != null && !s.trim().isEmpty()) serials.add(s.trim());
                    }

                    // PURCHASE: (tùy chọn) đính kèm file Excel serial nhà sản xuất — parse ngay tại đây.
                    Map<String, List<String>> mfrSerials = null;
                    if (isPurchase) {
                        Part filePart = null;
                        try { filePart = httpReq.getPart("excelFile"); } catch (Exception ignore) {}
                        if (filePart != null && filePart.getSize() > 0) {
                            Map<String, Integer> expectedBySku = new LinkedHashMap<>();
                            ProductService pService = new ProductService();
                            for (TicketDetail d : details) {
                                Product p = pService.getProductById(d.getProductId(), req.getWarehouseId());
                                if (p != null) expectedBySku.put(p.getSku(), d.getQuantity());
                            }
                            ManufacturerSerialExcelService excelService = new ManufacturerSerialExcelService();
                            ManufacturerSerialExcelService.ParseResult result;
                            try (InputStream is = filePart.getInputStream()) {
                                result = excelService.parseAndValidate(is, expectedBySku);
                            }
                            if (!result.isValid()) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=InvalidSerialFile");
                                return;
                            }
                            mfrSerials = result.getSerialsBySku();
                        }
                    }

                    Ticket ticket = new Ticket();
                    ticket.setType(Ticket.TYPE_IN);
                    ticket.setRequestId(reqId);
                    ticket.setWarehouseId(loggedInUser.getWarehouseId());
                    ticket.setKeeperId(loggedInUser.getId());
                    boolean ok = ticketService.addAndConfirm(ticket, details, serials, loggedInUser.getId(), mfrSerials);
                    if (!ok) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=ReceiveFailed");
                        return;
                    }
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
    }
}
