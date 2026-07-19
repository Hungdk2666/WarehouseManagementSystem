package controller.admin;

import service.AuditLogService;
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
        
        // RBAC: System Admin (SYSTEM_LOG_VIEW) chỉ xem nhật ký hệ thống;
        // Business Admin (AUDIT_LOG_VIEW) chỉ xem nhật ký nghiệp vụ.
        boolean canSystem = loggedInUser.hasPermission("SYSTEM_LOG_VIEW");
        boolean canBusiness = loggedInUser.hasPermission("AUDIT_LOG_VIEW");
        if (!canSystem && !canBusiness) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền xem nhật ký.");
            return;
        }
        // Nếu (hiếm) có cả hai quyền, ưu tiên nhật ký hệ thống.
        String category = canSystem ? "SYSTEM" : "BUSINESS";
        String pageTitle = canSystem ? "Nhật ký hệ thống" : "Nhật ký nghiệp vụ";
        String pageSubtitle = canSystem
                ? "Theo dõi thay đổi người dùng, vai trò, phân quyền và mật khẩu"
                : "Giám sát hoạt động nghiệp vụ và dấu vết các giao dịch quan trọng";

        String search = request.getParameter("search");
        String[] actionFilters = request.getParameterValues("actionFilter");
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
        
        int pageSize = 10;
        String pageSizeStr = request.getParameter("pageSize");
        if (pageSizeStr != null && !pageSizeStr.isEmpty()) {
            try {
                pageSize = Integer.parseInt(pageSizeStr);
            } catch (NumberFormatException e) {
                pageSize = 10;
            }
        }
        
        AuditLogService dao = new AuditLogService();
        List<AuditLog> list = dao.getLogs(category, search, actionFilters, startDate, endDate, page, pageSize);
        int totalLogs = dao.getLogsCount(category, search, actionFilters, startDate, endDate);
        int totalPages = (int) Math.ceil((double) totalLogs / pageSize);
        if (totalPages == 0) {
            totalPages = 1;
        }

        List<String> actions = dao.getAllUniqueActions(category);

        request.setAttribute("logs", list);
        request.setAttribute("actions", actions);
        request.setAttribute("pageTitle", pageTitle);
        request.setAttribute("pageSubtitle", pageSubtitle);
        request.setAttribute("currentPage", page);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("totalCount", totalLogs);
        request.setAttribute("pageSize", pageSize);
        
        request.setAttribute("search", search);
        request.setAttribute("actionFilters", actionFilters);
        request.setAttribute("startDate", startDate);
        request.setAttribute("endDate", endDate);

        request.getRequestDispatcher("/admin/audit-log-list.jsp").forward(request, response);
    }
}
