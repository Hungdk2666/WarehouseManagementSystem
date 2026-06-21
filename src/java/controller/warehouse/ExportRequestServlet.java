package controller.warehouse;

import service.RequestService;
import service.TicketService;
import service.InternalDestinationService;
import service.ProductService;
import service.WarehouseService;
import service.CustomerService;
import java.io.IOException;
import java.sql.Date;
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
import model.Customer;
import model.InternalDestination;
import model.Product;
import model.Request;
import model.RequestDetail;
import model.Ticket;
import model.User;
import model.Warehouse;

@WebServlet(name = "ExportRequestServlet", urlPatterns = {"/warehouse/export-request"})
public class ExportRequestServlet extends HttpServlet {

    private static final String TYPE = Request.TYPE_OUT;

    @Override
    protected void doGet(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) { response.sendRedirect(httpReq.getContextPath() + "/login"); return; }

        String action = httpReq.getParameter("action");
        if (action == null) action = "list";

        if (("list".equals(action) || "detail".equals(action)) && !loggedInUser.hasPermission("REQUEST_VIEW_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n xem yĂªu cáº§u xuáº¥t."); return;
        }
        if ("add".equals(action) && !loggedInUser.hasPermission("REQUEST_ADD_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n táº¡o yĂªu cáº§u xuáº¥t."); return;
        }

        RequestService dao = new RequestService();
        TicketService ticketService = new TicketService();

        switch (action) {
            case "list":
                httpReq.setAttribute("requestList", dao.getAll(TYPE));
                httpReq.getRequestDispatcher("/export_request/request-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Request req = dao.getById(id);
                if (req == null) { response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list"); return; }
                List<Ticket> tickets = ticketService.getByRequestId(id);
                httpReq.setAttribute("req", req);
                httpReq.setAttribute("ticketList", tickets);
                httpReq.getRequestDispatcher("/export_request/request-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                ProductService pService = new ProductService();
                List<Warehouse> warehouses = new WarehouseService().getAllActiveWarehouses();
                httpReq.setAttribute("destinationList", new InternalDestinationService().getAllDestinations());
                httpReq.setAttribute("productList",    pService.getAllProducts());
                httpReq.setAttribute("warehouseList",  warehouses);
                httpReq.setAttribute("customerList",   new CustomerService().getAllCustomers());
                // Map kho -> map product -> available qty (NEW/USED)
                Map<Integer, Map<Integer, Integer>> stockMapNew = new HashMap<>();
                Map<Integer, Map<Integer, Integer>> stockMapUsed = new HashMap<>();
                for (Warehouse w : warehouses) {
                    Map<Integer, Integer> wStockNew = new HashMap<>();
                    Map<Integer, Integer> wStockUsed = new HashMap<>();
                    for (Product p : pService.getAllProducts(w.getId())) {
                        wStockNew.put(p.getId(), p.getAvailableNewQty());
                        wStockUsed.put(p.getId(), p.getAvailableUsedQty());
                    }
                    stockMapNew.put(w.getId(), wStockNew);
                    stockMapUsed.put(w.getId(), wStockUsed);
                }
                httpReq.setAttribute("warehouseProductStockNew", stockMapNew);
                httpReq.setAttribute("warehouseProductStockUsed", stockMapUsed);
                httpReq.getRequestDispatcher("/export_request/request-add.jsp").forward(httpReq, response);
                break;
            }
            default:
                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) { response.sendRedirect(httpReq.getContextPath() + "/login"); return; }

        String action = httpReq.getParameter("action");
        if (action == null) { response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list"); return; }

        if ("add".equals(action) && !loggedInUser.hasPermission("REQUEST_ADD_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n táº¡o yĂªu cáº§u xuáº¥t."); return;
        }
        if (("approve".equals(action) || "reject".equals(action)) && !loggedInUser.hasPermission("REQUEST_APPROVE_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n duyá»‡t."); return;
        }
        if (("approveCancel".equals(action) || "rejectCancel".equals(action))
                && !loggedInUser.hasPermission("REQUEST_APPROVE_CANCEL_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n duyá»‡t há»§y."); return;
        }

        RequestService dao = new RequestService();

        try {
            switch (action) {
                case "add": {
                    String reasonStr = httpReq.getParameter("export_reason");
                    Date expectedDate = Date.valueOf(httpReq.getParameter("expected_date"));
                    String requestedCondition = httpReq.getParameter("requested_condition");
                    if (reasonStr == null || reasonStr.trim().isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoReason"); return;
                    }
                    if (requestedCondition == null || requestedCondition.trim().isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoCondition"); return;
                    }

                    int sourceWh;
                    String sourceWhStr = httpReq.getParameter("source_warehouse_id");
                    if (sourceWhStr != null && !sourceWhStr.trim().isEmpty()) {
                        sourceWh = Integer.parseInt(sourceWhStr);
                    } else {
                        sourceWh = loggedInUser.getWarehouseId() != null ? loggedInUser.getWarehouseId() : 1;
                    }

                    String partnerType;
                    Integer partnerId = null;
                    String shippingAddress = null;

                    switch (reasonStr) {
                        case "TRANSFER": {
                            String twIdStr = httpReq.getParameter("target_warehouse_id");
                            if (twIdStr == null || twIdStr.trim().isEmpty()) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoTarget"); return;
                            }
                            int targetWh = Integer.parseInt(twIdStr);
                            if (sourceWh == targetWh) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=SameWarehouse"); return;
                            }
                            partnerType = Request.PARTNER_WAREHOUSE;
                            partnerId = targetWh;
                            break;
                        }
                        case "CUSTOMER_SALE": {
                            String cIdStr = httpReq.getParameter("customer_id");
                            if (cIdStr == null || cIdStr.trim().isEmpty()) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoCustomer"); return;
                            }
                            partnerType = Request.PARTNER_CUSTOMER;
                            partnerId = Integer.parseInt(cIdStr);
                            shippingAddress = httpReq.getParameter("shipping_address");
                            break;
                        }
                        case "DISPOSAL":
                            partnerType = Request.PARTNER_NONE;
                            break;
                        default: { // DISPLAY, WARRANTY, OTHER
                            String destIdStr = httpReq.getParameter("destination_id");
                            if (destIdStr == null || destIdStr.trim().isEmpty()) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoDestination"); return;
                            }
                            partnerType = Request.PARTNER_INTERNAL_DEST;
                            partnerId = Integer.parseInt(destIdStr);
                            break;
                        }
                    }

                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoProducts"); return;
                    }
                    List<RequestDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        if (productIds[i] == null || productIds[i].trim().isEmpty()) continue;
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0) continue;
                        RequestDetail d = new RequestDetail();
                        d.setProductId(Integer.parseInt(productIds[i]));
                        d.setQuantity(qty);
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoValidDetails"); return;
                    }

                    Request req = new Request();
                    req.setType(Request.TYPE_OUT);
                    req.setReason(reasonStr);
                    req.setWarehouseId(sourceWh);
                    req.setPartnerType(partnerType);
                    req.setPartnerId(partnerId);
                    req.setShippingAddress(shippingAddress);
                    req.setStaffId(loggedInUser.getId());
                    req.setExpectedDate(expectedDate);
                    req.setRequestedCondition(requestedCondition);
                    if (!dao.add(req, details)) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=Failed"); return;
                    }
                    break;
                }
                case "approve":
                    dao.updateStatus(Integer.parseInt(httpReq.getParameter("id")), Request.STATUS_APPROVED, loggedInUser.getId());
                    break;
                case "reject":
                    dao.updateStatus(Integer.parseInt(httpReq.getParameter("id")), Request.STATUS_REJECTED, loggedInUser.getId());
                    break;
                case "cancel": {
                    int cancelId = Integer.parseInt(httpReq.getParameter("id"));
                    Request req = dao.getById(cancelId);
                    if (req == null) break;
                    if (Request.STATUS_PENDING.equals(req.getStatus())) {
                        if (!loggedInUser.hasPermission("REQUEST_CANCEL_OUT")) {
                            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n há»§y."); return;
                        }
                        dao.cancelRequest(cancelId, loggedInUser.getId());
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list"); return;
                    } else if (Request.STATUS_APPROVED.equals(req.getStatus())) {
                        if (!loggedInUser.hasPermission("REQUEST_REQUEST_CANCEL_OUT")) {
                            response.sendError(HttpServletResponse.SC_FORBIDDEN, "KhĂ´ng cĂ³ quyá»n Ä‘á» xuáº¥t há»§y."); return;
                        }
                        dao.requestCancel(cancelId, loggedInUser.getId(), httpReq.getParameter("reason"));
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=detail&id=" + cancelId); return;
                    }
                    break;
                }
                case "approveCancel": {
                    int id = Integer.parseInt(httpReq.getParameter("id"));
                    dao.approveCancel(id, loggedInUser.getId());
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=detail&id=" + id); return;
                }
                case "rejectCancel": {
                    int id = Integer.parseInt(httpReq.getParameter("id"));
                    dao.rejectCancel(id);
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=detail&id=" + id); return;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list");
    }
}
