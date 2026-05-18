<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUserSidebar = (User) session.getAttribute("user");
    String requestURI = request.getRequestURI();
%>
<div class="col-md-3 col-lg-2 mb-4">
    <div class="list-group shadow-sm">
        <div class="list-group-item list-group-item-secondary fw-bold text-uppercase" style="font-size: 0.85rem;">
            <i class="bi bi-folder-fill me-2"></i>Categories
        </div>
        <a href="<%= request.getContextPath() %>/index.jsp" class="list-group-item list-group-item-action <%= requestURI.endsWith("index.jsp") || requestURI.endsWith("/") ? "active" : "" %>">Dashboard</a>
        <a href="<%= request.getContextPath() %>/profile" class="list-group-item list-group-item-action <%= requestURI.contains("profile") ? "active" : "" %>">Profile</a>
        <a href="<%= request.getContextPath() %>/change-password" class="list-group-item list-group-item-action <%= requestURI.contains("change-password") || requestURI.contains("change_password") ? "active" : "" %>">Change Password</a>
        <% if (loggedInUserSidebar != null && loggedInUserSidebar.getRoleId() == 1) { %>
        <a href="<%= request.getContextPath() %>/admin/user?action=list" class="list-group-item list-group-item-action d-flex justify-content-between align-items-center <%= requestURI.contains("user") ? "active" : "" %>">
            User Management
        </a>
    </div>
</div>
