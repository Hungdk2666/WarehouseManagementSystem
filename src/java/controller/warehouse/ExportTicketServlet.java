package controller.warehouse;

import dao.ExportRequestDAO;
import dao.ExportTicketDAO;
import dao.ProductDAO;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.ExportRequest;
import model.ExportRequestDetail;
import model.ExportTicket;
import model.ExportTicketDetail;
import model.Product;
import model.User;

@WebServlet(name = "ExportTicketServlet", urlPatterns = {"/warehouse/export-ticket"})
public class ExportTicketServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        // Permission Checks
        if ("list".equals(action) || "detail".equals(action)) {
            if (!loggedInUser.hasPermission("EXPORT_TICKET_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view export tickets.");
                return;
            }
        } else if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("EXPORT_TICKET_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create export tickets.");
                return;
            }
        }

        ExportTicketDAO dao = new ExportTicketDAO();
        ExportRequestDAO rDao = new ExportRequestDAO();

        switch (action) {
            case "list":
                List<ExportTicket> list = dao.getAllExportTickets();
                request.setAttribute("ticketList", list);
                request.getRequestDispatcher("/export_ticket/ticket-list.jsp").forward(request, response);
                break;
            case "detail":
                int id = Integer.parseInt(request.getParameter("id"));
                ExportTicket ticket = dao.getExportTicketById(id);
                if (ticket == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
                    return;
                }

                dao.ProductItemDAO itemDAO = new dao.ProductItemDAO();
                if ("CONFIRMED".equals(ticket.getStatus())) {
                    List<model.ProductItem> exportedSerials = itemDAO.getItemsByExportTicketId(id);
                    request.setAttribute("exportedSerials", exportedSerials);
                } else if ("DRAFT".equals(ticket.getStatus())) {
                    java.util.Map<Integer, List<String>> availableSerials = new java.util.HashMap<>();
                    for (ExportTicketDetail d : ticket.getDetails()) {
                        List<model.ProductItem> items = itemDAO.getInStockItemsByProductId(d.getProductId());
                        List<String> serials = new ArrayList<>();
                        for (model.ProductItem item : items) {
                            serials.add(item.getSerialNumber());
                        }
                        availableSerials.put(d.getProductId(), serials);
                    }
                    request.setAttribute("availableSerials", availableSerials);
                }

                request.setAttribute("ticket", ticket);
                request.getRequestDispatcher("/export_ticket/ticket-detail.jsp").forward(request, response);
                break;
            case "add":
                // Get approved export requests
                List<ExportRequest> approvedRequests = rDao.getApprovedRequests();
                request.setAttribute("reqList", approvedRequests);

                String reqIdParam = request.getParameter("request_id");
                if (reqIdParam != null && !reqIdParam.trim().isEmpty()) {
                    int reqId = Integer.parseInt(reqIdParam);
                    ExportRequest selectedReq = rDao.getExportRequestById(reqId);

                    // Attach current inventory stock to details for frontend check helper
                    ProductDAO pDao = new ProductDAO();
                    if (selectedReq != null && selectedReq.getDetails() != null) {
                        for (ExportRequestDetail d : selectedReq.getDetails()) {
                            Product p = pDao.getProductById(d.getProductId());
                            if (p != null) {
                                // We repurpose the model's helper fields for GIN creation view
                                d.setUnit(p.getUnit());
                                d.setSku(p.getSku());
                                d.setCurrentStock(p.getQuantity());
                            }
                        }
                    }
                    request.setAttribute("selectedReq", selectedReq);
                }

                request.getRequestDispatcher("/export_ticket/ticket-add.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");

        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("EXPORT_TICKET_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create export tickets.");
                return;
            }
        }

        ExportTicketDAO dao = new ExportTicketDAO();
        ExportRequestDAO rDao = new ExportRequestDAO();

        try {
            switch (action) {
                case "add":
                    int reqId = Integer.parseInt(request.getParameter("request_id"));
                    String[] productIds = request.getParameterValues("product_id");
                    String[] quantities = request.getParameterValues("quantity");

                    ExportRequest selectedReq = rDao.getExportRequestById(reqId);
                    if (selectedReq == null || selectedReq.getCancelRequestedAt() != null || "CANCELLED".equals(selectedReq.getStatus())) {
                        response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=add&error=CancelRequested");
                        return;
                    }

                    ProductDAO pDao = new ProductDAO();
                    if (productIds != null && productIds.length > 0) {
                        List<ExportTicketDetail> details = new ArrayList<>();
                        for (int i = 0; i < productIds.length; i++) {
                            int pId = Integer.parseInt(productIds[i]);
                            int qty = Integer.parseInt(quantities[i]);

                            if (qty > 0) {
                                // Find matching request detail to validate quantity
                                ExportRequestDetail reqD = null;
                                for (ExportRequestDetail d : selectedReq.getDetails()) {
                                    if (d.getProductId() == pId) {
                                        reqD = d;
                                        break;
                                    }
                                }

                                if (reqD == null) {
                                    response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=InvalidProduct");
                                    return;
                                }

                                int remainingRequested = reqD.getQuantity() - reqD.getIssuedQuantity();
                                if (qty > remainingRequested) {
                                    response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=ExceededRemainingQuantity");
                                    return;
                                }

                                Product p = pDao.getProductById(pId);
                                if (p == null || p.getQuantity() < qty) {
                                    response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=InsufficientStock");
                                    return;
                                }

                                ExportTicketDetail d = new ExportTicketDetail();
                                d.setProductId(pId);
                                d.setQuantity(qty);
                                details.add(d);
                            }
                        }

                        if (details.isEmpty()) {
                            response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=NoItemsDispatched");
                            return;
                        }

                        ExportTicket ticket = new ExportTicket();
                        ticket.setRequestId(reqId);
                        ticket.setKeeperId(loggedInUser.getId());

                        boolean success = dao.addExportTicket(ticket, details);
                        if (!success) {
                            response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=add&request_id=" + reqId + "&error=FailedToCreate");
                            return;
                        }
                    }
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
    }
}
