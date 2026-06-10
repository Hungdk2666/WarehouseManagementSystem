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
import model.ExportTicket;
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
        }

        ExportTicketDAO dao = new ExportTicketDAO();
        ExportRequestDAO rDao = new ExportRequestDAO();

        switch (action) {
            case "list":
                List<ExportTicket> list = dao.getAllExportTickets();
                request.setAttribute("ticketList", list);
                request.getRequestDispatcher("/export_ticket/ticket-list.jsp").forward(request, response);
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
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
            return;
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
    }
}
