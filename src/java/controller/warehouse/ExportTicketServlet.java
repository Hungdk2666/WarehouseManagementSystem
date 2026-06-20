package controller.warehouse;

import dao.RequestDAO;
import dao.TicketDAO;
import dao.ProductDAO;
import dao.ProductItemDAO;
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

        TicketDAO ticketDao = new TicketDAO();
        RequestDAO requestDao = new RequestDAO();
        ProductItemDAO itemDao = new ProductItemDAO();

        switch (action) {
            case "list":
                httpReq.setAttribute("ticketList", ticketDao.getAll(TYPE));
                // Phiếu OUT-TRANSFER đang đến kho hiện tại (FYI only — luồng mới: tạo Ticket IN)
                if (loggedInUser.getWarehouseId() != null) {
                    httpReq.setAttribute("incomingTransfers",
                            ticketDao.getIncomingTransfersForWarehouse(loggedInUser.getWarehouseId()));
                }
                httpReq.getRequestDispatcher("/export_ticket/ticket-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Ticket ticket = ticketDao.getById(id);
                if (ticket == null) {
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list"); return;
                }
                String s = ticket.getStatus();
                if (Ticket.STATUS_CONFIRMED.equals(s) || Ticket.STATUS_IN_TRANSIT.equals(s) || Ticket.STATUS_COMPLETED.equals(s)) {
                    httpReq.setAttribute("exportedSerials", itemDao.getItemsByTicketId(id));
                } else if (Ticket.STATUS_DRAFT.equals(s) && ticket.getDetails() != null) {
                    Map<Integer, List<String>> availableSerials = new HashMap<>();
                    for (TicketDetail d : ticket.getDetails()) {
                        String cond = ticket.getRequestedCondition();
                        List<ProductItem> items = itemDao.getInStockItemsByProductId(d.getProductId(), ticket.getWarehouseId(), cond);
                        List<String> serials = new ArrayList<>();
                        for (ProductItem it : items) serials.add(it.getSerialNumber());
                        availableSerials.put(d.getProductId(), serials);
                    }
                    httpReq.setAttribute("availableSerials", availableSerials);
                }
                httpReq.setAttribute("ticket", ticket);
                httpReq.getRequestDispatcher("/export_ticket/ticket-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                Integer userWh = loggedInUser.getWarehouseId();
                List<Request> approved = requestDao.getPendingOrApproved(Request.TYPE_OUT, userWh);
                httpReq.setAttribute("reqList", approved);
                String reqIdParam = httpReq.getParameter("request_id");
                if (reqIdParam != null && !reqIdParam.trim().isEmpty()) {
                    int reqId = Integer.parseInt(reqIdParam);
                    Request selectedReq = requestDao.getById(reqId);
                    ProductDAO pDao = new ProductDAO();
                    Map<Integer, Integer> stockMap = new HashMap<>();
                    Map<Integer, Integer> newStockMap = new HashMap<>();
                    Map<Integer, Integer> usedStockMap = new HashMap<>();
                    Map<Integer, Integer> totalStockMap = new HashMap<>();
                    if (selectedReq != null && selectedReq.getDetails() != null) {
                        for (RequestDetail d : selectedReq.getDetails()) {
                            Product p = pDao.getProductById(d.getProductId(), selectedReq.getWarehouseId());
                            if (p != null) {
                                d.setUnit(p.getUnit());
                                d.setSku(p.getSku());
                                boolean isUsed = "USED".equals(selectedReq.getRequestedCondition());
                                stockMap.put(d.getProductId(), isUsed ? p.getAvailableUsedQty() : p.getAvailableNewQty());
                                newStockMap.put(d.getProductId(), p.getAvailableNewQty());
                                usedStockMap.put(d.getProductId(), p.getAvailableUsedQty());
                                totalStockMap.put(d.getProductId(), p.getAvailableQty());
                            } else {
                                stockMap.put(d.getProductId(), 0);
                                newStockMap.put(d.getProductId(), 0);
                                usedStockMap.put(d.getProductId(), 0);
                                totalStockMap.put(d.getProductId(), 0);
                            }
                        }
                    }
                    httpReq.setAttribute("selectedReq", selectedReq);
                    httpReq.setAttribute("stockMap", stockMap);
                    httpReq.setAttribute("newStockMap", newStockMap);
                    httpReq.setAttribute("usedStockMap", usedStockMap);
                    httpReq.setAttribute("totalStockMap", totalStockMap);
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

        if ("add".equals(action) && !loggedInUser.hasPermission("TICKET_ADD_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo."); return;
        }
        if ("confirm".equals(action) && !loggedInUser.hasPermission("TICKET_CONFIRM_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền confirm."); return;
        }
        if ("cancel".equals(action) && !loggedInUser.hasPermission("TICKET_CANCEL_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền hủy."); return;
        }

        TicketDAO ticketDao = new TicketDAO();
        RequestDAO requestDao = new RequestDAO();

        try {
            switch (action) {
                case "add": {
                    int reqId = Integer.parseInt(httpReq.getParameter("request_id"));
                    Request selectedReq = requestDao.getById(reqId);
                    if (selectedReq == null
                            || (!(Request.STATUS_APPROVED.equals(selectedReq.getStatus())
                                || Request.STATUS_PARTIALLY_COMPLETED.equals(selectedReq.getStatus())))
                            || selectedReq.getCancelRequestedAt() != null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&error=RequestNotApproved"); return;
                    }
                    Integer userWh = loggedInUser.getWarehouseId();
                    int sourceWh = selectedReq.getWarehouseId();
                    if (userWh != null && userWh != sourceWh) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=WrongWarehouse"); return;
                    }

                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=NoItems"); return;
                    }

                    ProductDAO pDao = new ProductDAO();
                    List<TicketDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        int pId = Integer.parseInt(productIds[i]);
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0) continue;
                        Product p = pDao.getProductById(pId, sourceWh);
                        boolean isUsed = "USED".equals(selectedReq.getRequestedCondition());
                        int avail = (p != null) ? (isUsed ? p.getAvailableUsedQty() : p.getAvailableNewQty()) : 0;
                        if (p == null || avail < qty) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=InsufficientStock"); return;
                        }
                        TicketDetail d = new TicketDetail();
                        d.setProductId(pId);
                        d.setQuantity(qty);
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=NoValidItems"); return;
                    }
                    Ticket ticket = new Ticket();
                    ticket.setType(Ticket.TYPE_OUT);
                    ticket.setRequestId(reqId);
                    ticket.setWarehouseId(sourceWh);
                    ticket.setKeeperId(loggedInUser.getId());
                    if (!ticketDao.add(ticket, details)) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=Failed"); return;
                    }
                    break;
                }
                case "confirm": {
                    int confirmId = Integer.parseInt(httpReq.getParameter("id"));
                    String[] scanned = httpReq.getParameterValues("scanned_serials");
                    List<String> serials = new ArrayList<>();
                    if (scanned != null) {
                        for (String s : scanned) if (s != null && !s.trim().isEmpty()) serials.add(s.trim());
                    }
                    boolean ok = ticketDao.confirm(confirmId, loggedInUser.getId(), serials);
                    if (!ok) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=detail&id=" + confirmId + "&error=ConfirmFailed"); return;
                    }
                    break;
                }
                case "cancel":
                    ticketDao.cancel(Integer.parseInt(httpReq.getParameter("id")));
                    break;
            }
        } catch (Exception e) { e.printStackTrace(); }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-ticket?action=list");
    }
}
