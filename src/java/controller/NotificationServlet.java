package controller;

import dao.NotificationDAO;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import model.Notification;

@WebServlet(name = "NotificationServlet", urlPatterns = {"/notifications", "/api/notifications"})
public class NotificationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        if (loggedInUser == null) {
            if (request.getRequestURI().contains("/api/")) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("{\"error\":\"Unauthorized\"}");
            } else {
                response.sendRedirect(request.getContextPath() + "/login");
            }
            return;
        }

        String servletPath = request.getServletPath();
        NotificationDAO dao = new NotificationDAO();

        if ("/api/notifications".equals(servletPath)) {
            String action = request.getParameter("action");
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();

            if ("getRecent".equals(action)) {
                int unreadCount = dao.getUnreadCount(loggedInUser.getId());
                List<Notification> list = dao.getRecentNotifications(loggedInUser.getId(), 5);

                StringBuilder json = new StringBuilder();
                json.append("{");
                json.append("\"unreadCount\":").append(unreadCount).append(",");
                json.append("\"notifications\":[");
                for (int i = 0; i < list.size(); i++) {
                    Notification n = list.get(i);
                    json.append("{");
                    json.append("\"id\":").append(n.getId()).append(",");
                    json.append("\"title\":\"").append(escapeJson(n.getTitle())).append("\",");
                    json.append("\"message\":\"").append(escapeJson(n.getMessage())).append("\",");
                    json.append("\"link\":\"").append(n.getLink() != null ? escapeJson(n.getLink()) : "").append("\",");
                    json.append("\"isRead\":").append(n.isRead()).append(",");
                    json.append("\"createdAt\":\"").append(n.getCreatedAt().toString()).append("\"");
                    json.append("}");
                    if (i < list.size() - 1) {
                        json.append(",");
                    }
                }
                json.append("]");
                json.append("}");
                out.write(json.toString());
            } else {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.write("{\"error\":\"Invalid action\"}");
            }
            return;
        }

        // View full notifications page
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
        int totalNotifications = dao.getNotificationsCount(loggedInUser.getId());
        int totalPages = (int) Math.ceil((double) totalNotifications / pageSize);
        if (totalPages == 0) {
            totalPages = 1;
        }
        
        List<Notification> list = dao.getNotifications(loggedInUser.getId(), pageSize, (page - 1) * pageSize);
        
        request.setAttribute("notifications", list);
        request.setAttribute("currentPage", page);
        request.setAttribute("totalPages", totalPages);
        request.setAttribute("totalCount", totalNotifications);
        
        request.getRequestDispatcher("/notifications.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Unauthorized\"}");
            return;
        }

        String servletPath = request.getServletPath();
        NotificationDAO dao = new NotificationDAO();

        if ("/api/notifications".equals(servletPath)) {
            String action = request.getParameter("action");
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();

            if ("markRead".equals(action)) {
                try {
                    int id = Integer.parseInt(request.getParameter("id"));
                    boolean success = dao.markAsRead(id, loggedInUser.getId());
                    out.write("{\"success\":" + success + "}");
                } catch (NumberFormatException e) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    out.write("{\"error\":\"Invalid notification ID\"}");
                }
            } else if ("markAllRead".equals(action)) {
                boolean success = dao.markAllAsRead(loggedInUser.getId());
                out.write("{\"success\":" + success + "}");
            } else {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                out.write("{\"error\":\"Invalid action\"}");
            }
        }
    }

    private String escapeJson(String input) {
        if (input == null) return "";
        return input.replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\b", "\\b")
                    .replace("\f", "\\f")
                    .replace("\n", "\\n")
                    .replace("\r", "\\r")
                    .replace("\t", "\\t");
    }
}
