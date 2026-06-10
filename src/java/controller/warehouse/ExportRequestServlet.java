package controller.warehouse;

import dao.ExportRequestDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.ExportRequest;
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

        response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
    }
}
