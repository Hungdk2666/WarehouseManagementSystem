package controller.warehouse;

import dao.ImportRequestDAO;
import dao.ImportTicketDAO;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.ImportRequest;
import model.ImportTicket;
import model.ImportTicketDetail;
import model.User;

@WebServlet(name = "ImportTicketServlet", urlPatterns = {"/warehouse/import"})
public class ImportTicketServlet extends HttpServlet {

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
            if (!loggedInUser.hasPermission("IMPORT_TICKET_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view import tickets.");
                return;
            }
        } else if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("IMPORT_TICKET_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create import tickets.");
                return;
            }
        }

        ImportTicketDAO dao = new ImportTicketDAO();
        ImportRequestDAO rDao = new ImportRequestDAO();

        switch (action) {
            case "list":
                List<ImportTicket> list = dao.getAllImportTickets();
                request.setAttribute("ticketList", list);
                request.getRequestDispatcher("/import/import-list.jsp").forward(request, response);
                break;
            case "detail":
                int id = Integer.parseInt(request.getParameter("id"));
                ImportTicket ticket = dao.getImportTicketById(id);
                if (ticket == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/import?action=list");
                    return;
                }
                request.setAttribute("ticket", ticket);
                request.getRequestDispatcher("/import/import-detail.jsp").forward(request, response);
                break;
            case "add":
                // Get POs that are approved or partially received
                List<ImportRequest> pendingRequests = rDao.getApprovedRequests();
                request.setAttribute("poList", pendingRequests);

                String reqIdParam = request.getParameter("request_id");
                if (reqIdParam != null && !reqIdParam.trim().isEmpty()) {
                    int reqId = Integer.parseInt(reqIdParam);
                    ImportRequest selectedPO = rDao.getImportRequestById(reqId);
                    request.setAttribute("selectedPO", selectedPO);
                }

                request.getRequestDispatcher("/import/import-add.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/import?action=list");
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
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/warehouse/import?action=list");
            return;
        }

        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("IMPORT_TICKET_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create import tickets.");
                return;
            }
        } else if ("confirm".equals(action)) {
            if (!loggedInUser.hasPermission("IMPORT_TICKET_CONFIRM")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to confirm import tickets.");
                return;
            }
        } else if ("cancel".equals(action)) {
            if (!loggedInUser.hasPermission("IMPORT_TICKET_CANCEL")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to cancel import tickets.");
                return;
            }
        }
        
        ImportTicketDAO dao = new ImportTicketDAO();

        try {
            switch (action) {
                case "add":
                    int poId = Integer.parseInt(request.getParameter("po_id"));
                    ImportRequestDAO poDAO = new ImportRequestDAO();
                    model.ImportRequest po = poDAO.getImportRequestById(poId);
                    if (po == null || po.getCancelRequestedAt() != null || "CANCELLED".equals(po.getStatus())) {
                        response.sendRedirect(request.getContextPath() + "/warehouse/import?action=add&error=CancelRequested");
                        return;
                    }
                    String[] productIds = request.getParameterValues("product_id");
                    String[] quantities = request.getParameterValues("quantity");
                    String[] unitPrices = request.getParameterValues("unit_price");
                    
                    if (productIds != null && productIds.length > 0) {
                        List<ImportTicketDetail> details = new ArrayList<>();
                        for (int i = 0; i < productIds.length; i++) {
                            int pId = Integer.parseInt(productIds[i]);
                            int qty = Integer.parseInt(quantities[i]);
                            double price = Double.parseDouble(unitPrices[i]);
                            
                            // Only add items where actual quantity received is greater than 0
                            if (qty > 0) {
                                ImportTicketDetail d = new ImportTicketDetail();
                                d.setProductId(pId);
                                d.setQuantity(qty);
                                d.setUnitPrice(price);
                                details.add(d);
                            }
                        }
                        
                        if (details.isEmpty()) {
                            response.sendRedirect(request.getContextPath() + "/warehouse/import?action=add&request_id=" + poId + "&error=NoItemsReceived");
                            return;
                        }
                        
                        ImportTicket ticket = new ImportTicket();
                        ticket.setRequestId(poId);
                        ticket.setKeeperId(loggedInUser.getId());
                        
                        boolean success = dao.addImportTicket(ticket, details);
                        if (!success) {
                            response.sendRedirect(request.getContextPath() + "/warehouse/import?action=add&request_id=" + poId + "&error=FailedToCreate");
                            return;
                        }
                    }
                    break;
                case "confirm":
                    int confirmId = Integer.parseInt(request.getParameter("id"));
                    dao.confirmTicket(confirmId, loggedInUser.getId());
                    break;
                case "cancel":
                    int cancelId = Integer.parseInt(request.getParameter("id"));
                    dao.cancelTicket(cancelId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.sendRedirect(request.getContextPath() + "/warehouse/import?action=list");
    }
}
