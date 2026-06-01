<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUserSidebar = (User) session.getAttribute("user");
    String requestURI = request.getRequestURI();
%>
<div class="col-md-3 col-lg-2 mb-4">
    <div class="list-group list-group-custom shadow-sm bg-white p-2 rounded-3 border">
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mb-2" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
            <i class="bi bi-grid-fill me-2"></i>Navigation
        </div>
        <a href="<%= request.getContextPath() %>/index.jsp" class="list-group-item list-group-item-action <%= requestURI.endsWith("index.jsp") || requestURI.endsWith("/") || requestURI.endsWith("WareHouseManagementSystem") || requestURI.endsWith("WareHouseManagementSystem/") ? "active" : "" %>">
            <i class="bi bi-speedometer2 me-2"></i> Dashboard
        </a>
        
        <% if (loggedInUserSidebar != null && (loggedInUserSidebar.hasPermission("USER_VIEW") || loggedInUserSidebar.hasPermission("ROLE_VIEW"))) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
            <i class="bi bi-gear-fill me-2"></i> Administration
        </div>
        <% if (loggedInUserSidebar.hasPermission("USER_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/admin/user?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("user") ? "active" : "" %>">
            <i class="bi bi-people-fill me-2"></i> User Management
        </a>
        <% } %>
        <% if (loggedInUserSidebar.hasPermission("ROLE_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/admin/role?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("role") ? "active" : "" %>">
            <i class="bi bi-shield-lock-fill me-2"></i> Role Management
        </a>
        <% } %>
        <% } %>

        <% if (loggedInUserSidebar != null && (loggedInUserSidebar.hasPermission("PRODUCT_VIEW") || loggedInUserSidebar.hasPermission("CATEGORY_VIEW") || loggedInUserSidebar.hasPermission("BRAND_VIEW") || loggedInUserSidebar.hasPermission("DESTINATION_VIEW") || loggedInUserSidebar.hasPermission("SUPPLIER_VIEW"))) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
            <i class="bi bi-database-fill me-2"></i> Master Data
        </div>
        <% if (loggedInUserSidebar.hasPermission("PRODUCT_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/warehouse/product?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("product") ? "active" : "" %>">
            <i class="bi bi-box-seam-fill me-2"></i> Products Catalog
        </a>
        <% } %>
        <% if (loggedInUserSidebar.hasPermission("CATEGORY_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/warehouse/category?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("category") ? "active" : "" %>">
            <i class="bi bi-tags-fill me-2"></i> Category List
        </a>
        <% } %>
        <% if (loggedInUserSidebar.hasPermission("BRAND_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/warehouse/brand?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("brand") ? "active" : "" %>">
            <i class="bi bi-award-fill me-2"></i> Brand List
        </a>
        <% } %>
        <% if (loggedInUserSidebar.hasPermission("SUPPLIER_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/warehouse/supplier?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("supplier") ? "active" : "" %>">
            <i class="bi bi-truck me-2"></i> Suppliers List
        </a>
        <% } %>
        <% if (loggedInUserSidebar.hasPermission("DESTINATION_VIEW")) { %>
        <a href="<%= request.getContextPath() %>/warehouse/destination?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("destination") ? "active" : "" %>">
            <i class="bi bi-geo-alt-fill me-2"></i> Destinations
        </a>
        <% } %>
        <% } %>
    </div>
</div>

