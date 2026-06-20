package controller.admin;

import dao.AuditLogDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import model.AuditLog;

@WebServlet(name = "AuditLogServlet", urlPatterns = {"/admin/audit-log"})
public class AuditLogServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        
        // RBAC Check
        if (!loggedInUser.hasPermission("AUDIT_LOG_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view audit logs.");
            return;
        }

        String search = request.getParameter("search");
        String actionFilter = request.getParameter("actionFilter");
        String startDate = request.getParameter("startDate");
        String endDate = request.getParameter("endDate");
        
        int page = 1;
        String pageStr = request.getParameter("page");
        if (pageStr != null && !pageStr.isEmpty()) {
            try {
                page = Integer.parseInt(pageStr);
            } catch (NumberFormatException e) {
                page = 1;
            }
        }
        
        int pageSize = 15;
        
        AuditLogDAO dao = new AuditLogDAO();
        List<AuditLog> list = dao.getLogs(search, actionFilter, startDate, endDate, page, pageSize);
        int totalLogs = dao.getLogsCount(search, actionFilter, startDate, endDate);
        int totalPages = (int) Math.ceil((double) totalLogs / pageSize);
        if (totalPages == 0) {
            totalPages = 1;
        }
        
        List<String> actions = dao.getAllUniqueActions();

        request.setAttribute("logs", list);
        request.setAttribute("actions", actions);
        request.setAttribute("currentPage", page);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("totalCount", totalLogs);
        
        request.setAttribute("search", search);
        request.setAttribute("actionFilter", actionFilter);
        request.setAttribute("startDate", startDate);
        request.setAttribute("endDate", endDate);

        request.getRequestDispatcher("/admin/audit-log-list.jsp").forward(request, response);
    }
}
