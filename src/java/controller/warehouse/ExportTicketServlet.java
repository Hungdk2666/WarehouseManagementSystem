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

    private boolean canAccessWarehouse(User user, int warehouseId) {
        return user.getWarehouseId() == null || user.getWarehouseId() == warehouseId;
    }

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
                httpReq.setAttribute("ticketList", ticketService.getAll(TYPE, loggedInUser.getWarehouseId()));
                httpReq.getRequestDispatcher("/export_ticket/ticket-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Ticket ticket = ticketService.getById(id);
                if (ticket == null) {
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list"); return;
                }
                if (!canAccessWarehouse(loggedInUser, ticket.getWarehouseId())) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Ticket belongs to another warehouse.");
                    return;
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
                    if (selectedReq == null || !canAccessWarehouse(loggedInUser, selectedReq.getWarehouseId())) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Request belongs to another warehouse.");
                        return;
                    }
                    ProductService pService = new ProductService();
                    if (selectedReq.getDetails() != null) {
                        for (RequestDetail d : selectedReq.getDetails()) {
                            Product p = pService.getProductById(d.getProductId(), selectedReq.getWarehouseId());
                            if (p != null) {
                                d.setUnit(p.getUnit());
                                d.setSku(p.getSku());
                            }
                        }
                    }
                    // Serial hợp lệ để xuất và tình trạng của các serial hiện có trong kho nguồn.
                    Map<Integer, List<String>> availableSerials = new HashMap<>();
                    Map<String, String> serialConditions = new HashMap<>();
                    if (selectedReq != null && selectedReq.getDetails() != null) {
                        String requestedCondition = selectedReq.getRequestedCondition() == null
                                ? "NEW" : selectedReq.getRequestedCondition();
                        String[] conditions = {"NEW", "USED", "DAMAGED"};
                        for (RequestDetail d : selectedReq.getDetails()) {
                            List<String> serials = new ArrayList<>();
                            for (String condition : conditions) {
                                List<ProductItem> items = itemService.getInStockItemsByProductId(
                                        d.getProductId(), selectedReq.getWarehouseId(), condition);
                                for (ProductItem it : items) {
                                    serialConditions.put(it.getSerialNumber(), condition);
                                    if (requestedCondition.equals(condition)) {
                                        serials.add(it.getSerialNumber());
                                    }
                                }
                            }
                            availableSerials.put(d.getProductId(), serials);
                        }
                    }

                    httpReq.setAttribute("selectedReq", selectedReq);
                    httpReq.setAttribute("availableSerials", availableSerials);
                    httpReq.setAttribute("serialConditions", serialConditions);
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
                    // Nhất quán với luồng nhập: user phải được gán kho mới được xuất.
                    if (userWh == null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=RequiresWarehouseAssignment"); return;
                    }
                    if (userWh != sourceWh) {
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
