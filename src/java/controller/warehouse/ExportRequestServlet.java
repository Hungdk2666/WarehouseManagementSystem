package controller.warehouse;

import dao.ExportRequestDAO;
import dao.ExportTicketDAO;
import dao.InternalDestinationDAO;
import dao.ProductDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.sql.Date;
import java.util.ArrayList;
import model.ExportRequest;
import model.ExportRequestDetail;
import model.InternalDestination;
import model.Product;
import model.User;

@WebServlet(name = "ExportRequestServlet", urlPatterns = {"/warehouse/export-request"})
public class ExportRequestServlet extends HttpServlet {

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

        if ("list".equals(action) || "detail".equals(action)) {
            if (!loggedInUser.hasPermission("EXPORT_REQ_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view Export Requests.");
                return;
            }
        } else if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("EXPORT_REQ_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create Export Requests.");
                return;
            }
        }

        ExportRequestDAO dao = new ExportRequestDAO();

        switch (action) {
            case "list":
                List<ExportRequest> list = dao.getAllExportRequests();
                request.setAttribute("requestList", list);
                request.getRequestDispatcher("/export_request/request-list.jsp").forward(request, response);
                break;
            case "detail":
                int id = Integer.parseInt(request.getParameter("id"));
                ExportRequest req = dao.getExportRequestById(id);
                if (req == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
                    return;
                }
                ExportTicketDAO ticketDao = new ExportTicketDAO();
                List<model.ExportTicket> tickets = ticketDao.getExportTicketsByRequestId(id);

                request.setAttribute("req", req);
                request.setAttribute("ticketList", tickets);
                request.getRequestDispatcher("/export_request/request-detail.jsp").forward(request, response);
                break;
            case "add":
                InternalDestinationDAO dDao = new InternalDestinationDAO();
                ProductDAO pDao = new ProductDAO();

                List<InternalDestination> destinations = dDao.getAllDestinations();
                List<Product> products = pDao.getAllProducts();

                request.setAttribute("destinationList", destinations);
                request.setAttribute("productList", products);
                request.getRequestDispatcher("/export_request/request-add.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
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
            response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
            return;
        }

        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("EXPORT_REQ_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create Export Requests.");
                return;
            }
        }

        ExportRequestDAO dao = new ExportRequestDAO();

        try {
            switch (action) {
                case "add":
                    int destinationId = Integer.parseInt(request.getParameter("destination_id"));
                    String exportReason = request.getParameter("export_reason");
                    Date expectedDate = Date.valueOf(request.getParameter("expected_date"));

                    String[] productIds = request.getParameterValues("product_id");
                    String[] quantities = request.getParameterValues("quantity");

                    if (productIds != null && productIds.length > 0) {
                        List<ExportRequestDetail> details = new ArrayList<>();
                        for (int i = 0; i < productIds.length; i++) {
                            if (productIds[i] == null || productIds[i].trim().isEmpty()) {
                                continue;
                            }
                            int pId = Integer.parseInt(productIds[i]);
                            int qty = Integer.parseInt(quantities[i]);

                            ExportRequestDetail d = new ExportRequestDetail();
                            d.setProductId(pId);
                            d.setQuantity(qty);
                            details.add(d);
                        }

                        ExportRequest req = new ExportRequest();
                        req.setDestinationId(destinationId);
                        req.setExportReason(exportReason);
                        req.setCreatorId(loggedInUser.getId());
                        req.setExpectedDate(expectedDate);

                        boolean success = dao.addExportRequest(req, details);
                        if (!success) {
                            request.setAttribute("error", "Failed to save Export Request. Please try again.");
                            response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=add");
                            return;
                        }
                    }
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
    }
}
