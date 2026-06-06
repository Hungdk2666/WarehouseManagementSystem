package controller.warehouse;

import dao.ImportRequestDAO;
import dao.SupplierDAO;
import dao.ProductDAO;
import java.io.IOException;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.ImportRequest;
import model.ImportRequestDetail;
import model.Supplier;
import model.Product;
import model.User;

@WebServlet(name = "ImportRequestServlet", urlPatterns = {"/warehouse/po"})
public class ImportRequestServlet extends HttpServlet {

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
            if (!loggedInUser.hasPermission("PO_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view POs.");
                return;
            }
        } else if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("PO_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create POs.");
                return;
            }
        }

        ImportRequestDAO dao = new ImportRequestDAO();

        switch (action) {
            case "list":
                List<ImportRequest> list = dao.getAllImportRequests();
                request.setAttribute("poList", list);
                request.getRequestDispatcher("/po/po-list.jsp").forward(request, response);
                break;
            case "detail":
                int id = Integer.parseInt(request.getParameter("id"));
                ImportRequest req = dao.getImportRequestById(id);
                if (req == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
                    return;
                }
                dao.ImportTicketDAO ticketDao = new dao.ImportTicketDAO();
                List<model.ImportTicket> tickets = ticketDao.getImportTicketsByRequestId(id);
                
                request.setAttribute("po", req);
                request.setAttribute("ticketList", tickets);
                request.getRequestDispatcher("/po/po-detail.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
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
            response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
            return;
        }
        
        response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
    }
}
