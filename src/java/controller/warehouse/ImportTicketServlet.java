package controller.warehouse;

import dao.ImportRequestDAO;
import dao.ImportTicketDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.ImportTicket;
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

        response.sendRedirect(request.getContextPath() + "/warehouse/import?action=list");
    }
}
