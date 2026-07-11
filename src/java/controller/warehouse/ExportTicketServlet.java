package controller.warehouse;

import service.RequestService;
import service.TicketService;
import service.ProductService;
import service.ProductItemService;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Product;
import model.ProductItem;
import model.Request;
import model.RequestDetail;
import model.Ticket;
import model.TicketDetail;
import model.User;

@WebServlet(name = "ExportTicketServlet", urlPatterns = {"/warehouse/export-ticket"})
public class ExportTicketServlet extends HttpServlet {

    private static final String TYPE = Ticket.TYPE_OUT;

    @Override
    protected void doGet(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) { response.sendRedirect(httpReq.getContextPath() + "/login"); return; }

        String action = httpReq.getParameter("action");
        if (action == null) action = "list";

        if (("list".equals(action) || "detail".equals(action)) && !loggedInUser.hasPermission("TICKET_VIEW_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem phiếu xuất."); return;
        }
        if ("add".equals(action) && !loggedInUser.hasPermission("TICKET_ADD_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo phiếu xuất."); return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();
        ProductItemService itemService = new ProductItemService();

        switch (action) {
            case "list":
                httpReq.setAttribute("ticketList", ticketService.getAll(TYPE));
                // Phiếu OUT-TRANSFER đang đến kho hiện tại (FYI only — luồng mới: tạo Ticket IN)
                if (loggedInUser.getWarehouseId() != null) {
                    httpReq.setAttribute("incomingTransfers",
                            ticketService.getIncomingTransfersForWarehouse(loggedInUser.getWarehouseId()));
                }
                httpReq.getRequestDispatcher("/export_ticket/ticket-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Ticket ticket = ticketService.getById(id);
                if (ticket == null) {
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list"); return;
                }
                String s = ticket.getStatus();
                if (Ticket.STATUS_CONFIRMED.equals(s) || Ticket.STATUS_IN_TRANSIT.equals(s) || Ticket.STATUS_COMPLETED.equals(s)) {
                    httpReq.setAttribute("exportedSerials", itemService.getItemsByTicketId(id));
                }
                httpReq.setAttribute("ticket", ticket);
                httpReq.getRequestDispatcher("/export_ticket/ticket-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                Integer userWh = loggedInUser.getWarehouseId();
                // Block khi kho đang có phiếu kiểm kê chạy
                if (userWh != null) {
                    model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(userWh);
                    if (active != null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list"
                                + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                        return;
                    }
                }
                List<Request> approved = requestService.getPendingOrApproved(Request.TYPE_OUT, userWh);
                httpReq.setAttribute("reqList", approved);
                String reqIdParam = httpReq.getParameter("request_id");
                if (reqIdParam != null && !reqIdParam.trim().isEmpty()) {
                    int reqId = Integer.parseInt(reqIdParam);
                    Request selectedReq = requestService.getById(reqId);
                    ProductService pService = new ProductService();
                    Map<Integer, Integer> stockMap = new HashMap<>();
                    Map<Integer, Integer> newStockMap = new HashMap<>();
                    Map<Integer, Integer> usedStockMap = new HashMap<>();
                    Map<Integer, Integer> damagedStockMap = new HashMap<>();
                    Map<Integer, Integer> totalStockMap = new HashMap<>();
                    if (selectedReq != null && selectedReq.getDetails() != null) {
                        for (RequestDetail d : selectedReq.getDetails()) {
                            Product p = pService.getProductById(d.getProductId(), selectedReq.getWarehouseId());
                            if (p != null) {
                                d.setUnit(p.getUnit());
                                d.setSku(p.getSku());
                                boolean isUsed = "USED".equals(selectedReq.getRequestedCondition());
                                boolean isDamaged = "DAMAGED".equals(selectedReq.getRequestedCondition());
                                stockMap.put(d.getProductId(), isDamaged ? p.getDamagedQty() : (isUsed ? p.getAvailableUsedQty() : p.getAvailableNewQty()));
                                newStockMap.put(d.getProductId(), p.getAvailableNewQty());
                                usedStockMap.put(d.getProductId(), p.getAvailableUsedQty());
                                damagedStockMap.put(d.getProductId(), p.getDamagedQty());
                                totalStockMap.put(d.getProductId(), p.getAvailableQty() + p.getDamagedQty());
                            } else {
                                stockMap.put(d.getProductId(), 0);
                                newStockMap.put(d.getProductId(), 0);
                                usedStockMap.put(d.getProductId(), 0);
                                damagedStockMap.put(d.getProductId(), 0);
                                totalStockMap.put(d.getProductId(), 0);
                            }
                        }
                    }
                    // Danh sách serial khả dụng cho từng sản phẩm — để quét ngay trên màn hình gộp
                    Map<Integer, List<String>> availableSerials = new HashMap<>();
                    if (selectedReq != null && selectedReq.getDetails() != null) {
                        String cond = selectedReq.getRequestedCondition();
                        for (RequestDetail d : selectedReq.getDetails()) {
                            List<ProductItem> items = itemService.getInStockItemsByProductId(
                                    d.getProductId(), selectedReq.getWarehouseId(), cond);
                            List<String> serials = new ArrayList<>();
                            for (ProductItem it : items) serials.add(it.getSerialNumber());
                            availableSerials.put(d.getProductId(), serials);
                        }
                    }

                    httpReq.setAttribute("selectedReq", selectedReq);
                    httpReq.setAttribute("stockMap", stockMap);
                    httpReq.setAttribute("newStockMap", newStockMap);
                    httpReq.setAttribute("usedStockMap", usedStockMap);
                    httpReq.setAttribute("damagedStockMap", damagedStockMap);
                    httpReq.setAttribute("totalStockMap", totalStockMap);
                    httpReq.setAttribute("availableSerials", availableSerials);
                }
                httpReq.getRequestDispatcher("/export_ticket/ticket-add.jsp").forward(httpReq, response);
                break;
            }
            default:
                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) { response.sendRedirect(httpReq.getContextPath() + "/login"); return; }

        String action = httpReq.getParameter("action");
        if (action == null) { response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list"); return; }

        if ("addAndConfirm".equals(action)
                && !(loggedInUser.hasPermission("TICKET_ADD_OUT") && loggedInUser.hasPermission("TICKET_CONFIRM_OUT"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo và xuất kho."); return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();

        try {
            switch (action) {
                case "addAndConfirm": {
                    // GỘP 1 MÀN HÌNH: tạo phiếu + xuất kho (quét serial) trong 1 bước, không để lại phiếu nháp.
                    int reqId = Integer.parseInt(httpReq.getParameter("request_id"));
                    Request selectedReq = requestService.getById(reqId);
                    if (selectedReq == null
                            || (!(Request.STATUS_APPROVED.equals(selectedReq.getStatus())
                                || Request.STATUS_PARTIALLY_COMPLETED.equals(selectedReq.getStatus())))
                            || selectedReq.getCancelRequestedAt() != null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&error=RequestNotApproved"); return;
                    }
                    Integer userWh = loggedInUser.getWarehouseId();
                    int sourceWh = selectedReq.getWarehouseId();
                    {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(sourceWh);
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
                    }
                    if (userWh != null && userWh != sourceWh) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=WrongWarehouse"); return;
                    }

                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=NoItems"); return;
                    }
                    List<TicketDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        int pId = Integer.parseInt(productIds[i]);
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0) continue;
                        TicketDetail d = new TicketDetail();
                        d.setProductId(pId);
                        d.setQuantity(qty);
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=NoValidItems"); return;
                    }

                    String[] scanned = httpReq.getParameterValues("scanned_serials");
                    List<String> serials = new ArrayList<>();
                    if (scanned != null) {
                        for (String s : scanned) if (s != null && !s.trim().isEmpty()) serials.add(s.trim());
                    }

                    Ticket ticket = new Ticket();
                    ticket.setType(Ticket.TYPE_OUT);
                    ticket.setRequestId(reqId);
                    ticket.setWarehouseId(sourceWh);
                    ticket.setKeeperId(loggedInUser.getId());
                    boolean ok = ticketService.addAndConfirm(ticket, details, serials, loggedInUser.getId(), null);
                    if (!ok) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=DispatchFailed"); return;
                    }
                    break;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list");
    }
}
