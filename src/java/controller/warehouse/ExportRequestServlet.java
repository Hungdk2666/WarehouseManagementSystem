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
import utils.ItemConditionUtils;

@WebServlet(name = "ExportRequestServlet", urlPatterns = {"/warehouse/export-request"})
public class ExportRequestServlet extends HttpServlet {

    private static final String TYPE = Request.TYPE_OUT;

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
        if (loggedInUser == null) { response.sendRedirect(httpReq.getContextPath() + "/login"); return; }

        String action = httpReq.getParameter("action");
        if (action == null) action = "list";

        if (("list".equals(action) || "detail".equals(action)) && !loggedInUser.hasPermission("REQUEST_VIEW_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem yêu cầu xuất."); return;
        }
        if ("add".equals(action) && !loggedInUser.hasPermission("REQUEST_ADD_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo yêu cầu xuất."); return;
        }

        RequestService dao = new RequestService();
        TicketService ticketService = new TicketService();

        switch (action) {
            case "list":
                Integer exportOwnerId = isSalesUser(loggedInUser) ? loggedInUser.getId() : null;
                Integer exportWarehouseId = isSalesUser(loggedInUser) ? null : loggedInUser.getWarehouseId();
                httpReq.setAttribute("requestList", dao.getForList(TYPE, exportWarehouseId, exportOwnerId));
                httpReq.getRequestDispatcher("/export_request/request-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Request req = dao.getById(id);
                if (req == null) { response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list"); return; }
                if (!canAccessWarehouse(loggedInUser, req.getWarehouseId())) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Request belongs to another warehouse.");
                    return;
                }
                List<Ticket> tickets = ticketService.getByRequestId(id);
                httpReq.setAttribute("req", req);
                httpReq.setAttribute("ticketList", tickets);
                httpReq.getRequestDispatcher("/export_request/request-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                ProductService pService = new ProductService();
                List<Warehouse> warehouses = getAccessibleWarehouses(loggedInUser);
                httpReq.setAttribute("destinationList", new InternalDestinationService().getAllDestinations());
                httpReq.setAttribute("productList",    pService.getAllProducts());
                httpReq.setAttribute("warehouseList",  warehouses);
                httpReq.setAttribute("customerList",   new CustomerService().getActiveCustomers());
                // Map warehouse -> product -> available quantity by condition.
                Map<Integer, Map<Integer, Integer>> stockMapNew = new HashMap<>();
                Map<Integer, Map<Integer, Integer>> stockMapUsed = new HashMap<>();
                Map<Integer, Map<Integer, Integer>> stockMapDamaged = new HashMap<>();
                for (Warehouse w : warehouses) {
                    Map<Integer, Integer> wStockNew = new HashMap<>();
                    Map<Integer, Integer> wStockUsed = new HashMap<>();
                    Map<Integer, Integer> wStockDamaged = new HashMap<>();
                    for (Product p : pService.getAllProducts(w.getId())) {
                        wStockNew.put(p.getId(), p.getAvailableNewQty());
                        wStockUsed.put(p.getId(), p.getAvailableUsedQty());
                        wStockDamaged.put(p.getId(), p.getAvailableDamagedQty());
                    }
                    stockMapNew.put(w.getId(), wStockNew);
                    stockMapUsed.put(w.getId(), wStockUsed);
                    stockMapDamaged.put(w.getId(), wStockDamaged);
                }
                httpReq.setAttribute("warehouseProductStockNew", stockMapNew);
                httpReq.setAttribute("warehouseProductStockUsed", stockMapUsed);
                httpReq.setAttribute("warehouseProductStockDamaged", stockMapDamaged);
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
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo yêu cầu xuất."); return;
        }
        if (("approve".equals(action) || "reject".equals(action)) && !loggedInUser.hasPermission("REQUEST_APPROVE_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền duyệt."); return;
        }
        if (("approveCancel".equals(action) || "rejectCancel".equals(action))
                && !loggedInUser.hasPermission("REQUEST_APPROVE_CANCEL_OUT")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền duyệt hủy."); return;
        }

        // Chống thao tác nhầm loại: mọi hành động trên 1 yêu cầu cụ thể phải đúng loại XUẤT (OUT).
        if ("approve".equals(action) || "reject".equals(action) || "cancel".equals(action)
                || "approveCancel".equals(action) || "rejectCancel".equals(action)) {
            String idStr = httpReq.getParameter("id");
            if (idStr != null && !idStr.isEmpty()) {
                try {
                    Request guardReq = new RequestService().getById(Integer.parseInt(idStr));
                    if (guardReq == null || !TYPE.equals(guardReq.getType())
                            || !canAccessWarehouse(loggedInUser, guardReq.getWarehouseId())) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Yêu cầu không hợp lệ cho luồng xuất kho.");
                        return;
                    }
                } catch (NumberFormatException ignore) {}
            }
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
                    if (!Request.REASON_TRANSFER.equals(reasonStr)
                            && !Request.REASON_CUSTOMER_SALE.equals(reasonStr)
                            && !Request.REASON_DISPLAY.equals(reasonStr)
                            && !Request.REASON_WARRANTY.equals(reasonStr)) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=InvalidReason"); return;
                    }
                    if (!ItemConditionUtils.isValid(requestedCondition)) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=InvalidCondition"); return;
                    }
                    if (!ItemConditionUtils.isAllowedForExportReason(reasonStr, requestedCondition)) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=ConditionNotAllowed"); return;
                    }

                    int sourceWh;
                    String sourceWhStr = httpReq.getParameter("source_warehouse_id");
                    if (loggedInUser.getWarehouseId() != null) {
                        sourceWh = loggedInUser.getWarehouseId();
                    } else if (sourceWhStr != null && !sourceWhStr.trim().isEmpty()) {
                        sourceWh = Integer.parseInt(sourceWhStr);
                    } else {
                        if (loggedInUser.getWarehouseId() == null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoWarehouse"); return;
                        }
                        sourceWh = loggedInUser.getWarehouseId();
                    }
                    // Block khi kho nguồn đang kiểm kê
                    {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(sourceWh);
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
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
                        case "DISPLAY":
                        case "WARRANTY": {
                            String destIdStr = httpReq.getParameter("destination_id");
                            if (destIdStr == null || destIdStr.trim().isEmpty()) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=NoDestination"); return;
                            }
                            int destId = Integer.parseInt(destIdStr);
                            InternalDestination dest = new InternalDestinationService().getDestinationById(destId);
                            String requiredType = "WARRANTY".equals(reasonStr) ? "WARRANTY_CENTER" : "SHOWROOM";
                            if (dest == null || !requiredType.equals(dest.getDestinationType())) {
                                response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=DestinationPurposeMismatch"); return;
                            }
                            partnerType = Request.PARTNER_INTERNAL_DEST;
                            partnerId = destId;
                            break;
                        }
                        default:
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=InvalidReason"); return;
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

                    ProductService productService = new ProductService();
                    for (RequestDetail detail : details) {
                        Product product = productService.getProductById(detail.getProductId(), sourceWh);
                        if (product == null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=InvalidProduct"); return;
                        }
                        int available;
                        if (ItemConditionUtils.DAMAGED.equals(requestedCondition)) {
                            available = product.getAvailableDamagedQty();
                        } else if (ItemConditionUtils.USED.equals(requestedCondition)) {
                            available = product.getAvailableUsedQty();
                        } else {
                            available = product.getAvailableNewQty();
                        }
                        if (detail.getQuantity() > available) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=add&error=InsufficientStock&productId=" + detail.getProductId()); return;
                        }
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
                            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền hủy."); return;
                        }
                        dao.cancelRequest(cancelId, loggedInUser.getId());
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=list"); return;
                    } else if (Request.STATUS_APPROVED.equals(req.getStatus())
                            || Request.STATUS_PARTIALLY_COMPLETED.equals(req.getStatus())) {
                        if (!loggedInUser.hasPermission("REQUEST_REQUEST_CANCEL_OUT")) {
                            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền đề xuất hủy."); return;
                        }
                        dao.requestCancel(cancelId, loggedInUser.getId(), httpReq.getParameter("reason"));
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=detail&id=" + cancelId); return;
                    }
                    break;
                }
                case "approveCancel": {
                    int id = Integer.parseInt(httpReq.getParameter("id"));
                    boolean approved = dao.approveCancel(id, loggedInUser.getId());
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/export-request?action=detail&id=" + id
                            + (approved ? "&success=CancelApproved" : "&error=CancelApprovalFailed")); return;
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
