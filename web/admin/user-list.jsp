<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("USER_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<User> userList = (List<User>) request.getAttribute("userList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Users - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">User Management</h2>
                        <p class="text-muted small mb-0">Manage system users, roles, and account statuses</p>
                    </div>
                    <% if (loggedInUser.hasPermission("USER_ADD")) { %>
                    <a href="user?action=add" class="btn btn-success d-flex align-items-center gap-2">
                        <i class="bi bi-person-plus-fill fs-5"></i> Add New User
                    </a>
                    <% } %>
                </div>

                <!-- Server-Side Search and Filter Panel -->
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-body p-3">
                        <form action="user" method="GET" class="row g-2 align-items-center">
                            <input type="hidden" name="action" value="list">
                            <div class="col-md-6 col-lg-7">
                                <div class="input-group">
                                    <span class="input-group-text bg-transparent border-end-0 text-muted"><i class="bi bi-search"></i></span>
                                    <input type="text" name="search" class="form-control border-start-0 ps-0" placeholder="Search by username, email, full name..." value="<%= request.getParameter("search") != null ? request.getParameter("search") : "" %>">
                                </div>
                            </div>
                            <div class="col-md-4 col-lg-3">
                                <div class="input-group">
                                    <span class="input-group-text bg-transparent border-end-0 text-muted"><i class="bi bi-funnel"></i></span>
                                    <select name="roleFilter" class="form-select border-start-0 ps-0">
                                        <option value="">All Roles</option>
                                        <%
                                            List<Role> roleList = (List<Role>) request.getAttribute("roleList");
                                            String selectedRole = request.getParameter("roleFilter");
                                            if (roleList != null) {
                                                for (Role r : roleList) {
                                                    boolean isSelected = r.getRoleName().equals(selectedRole);
                                        %>
                                            <option value="<%= r.getRoleName() %>" <%= isSelected ? "selected" : "" %>><%= r.getRoleName() %></option>
                                        <%
                                                }
                                            }
                                        %>
                                    </select>
                                </div>
                            </div>
                            <div class="col-md-2 col-lg-2">
                                <button type="submit" class="btn btn-primary w-100 d-flex align-items-center justify-content-center gap-2">
                                    <i class="bi bi-sliders"></i> Filter
                                </button>
                            </div>
                        </form>
                    </div>
                </div>

                <div class="card shadow-sm border-0 bg-white">
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Username</th>
                                        <th>Email</th>
                                        <th>Full Name</th>
                                        <th>Role Name</th>
                                        <th>Status</th>
                                        <th>Reset Code</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (userList != null && !userList.isEmpty()) {
                                            for (User u : userList) {
                                    %>
                                    <tr>
                                        <td class="fw-semibold text-muted">#<%= u.getId() %></td>
                                        <td class="fw-bold text-slate-800"><%= u.getUsername() %></td>
                                        <td><%= u.getEmail() %></td>
                                        <td><%= u.getFullName() %></td>
                                        <td>
                                            <span class="badge bg-primary bg-opacity-10 text-primary px-2.5 py-1.5"><%= u.getRoleName() != null ? u.getRoleName() : "No Role" %></span>
                                        </td>
                                        <td>
                                            <% if (u.isStatus()) { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Active</span>
                                            <% } else { %>
                                                <span class="badge bg-secondary bg-opacity-10 text-secondary px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Inactive</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (u.getResetCode() != null) { %>
                                                <span class="badge bg-danger bg-opacity-10 text-danger px-2.5 py-1.5"><%= u.getResetCode() %></span>
                                            <% } else { %>
                                                <span class="text-muted">-</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="user?action=info&id=<%= u.getId() %>" class="btn btn-sm btn-info text-white d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Details">
                                                    <i class="bi bi-info-circle"></i> Info
                                                </a>
                                                <% if (loggedInUser.hasPermission("USER_EDIT")) { %>
                                                <a href="user?action=update&id=<%= u.getId() %>" class="btn btn-sm btn-warning d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Edit">
                                                    <i class="bi bi-pencil-square"></i> Edit
                                                </a>
                                                <% } %>
                                                <% if (loggedInUser.hasPermission("USER_TOGGLE")) { %>
                                                <form action="user?action=toggle" method="POST" style="display:inline;" class="m-0">
                                                    <input type="hidden" name="id" value="<%= u.getId() %>">
                                                    <button type="submit" class="btn btn-sm <%= u.isStatus() ? "btn-outline-danger" : "btn-primary" %> d-inline-flex align-items-center gap-1 py-1 px-2.5" title="<%= u.isStatus() ? "Deactivate Account" : "Activate Account" %>">
                                                        <i class="bi bi-power"></i> <%= u.isStatus() ? "Disable" : "Enable" %>
                                                    </button>
                                                </form>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="8" class="text-center text-muted py-5">
                                            <i class="bi bi-people text-muted display-4 d-block mb-3"></i>
                                            No users found matching the search criteria.
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="mt-4">
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary">
                        <i class="bi bi-arrow-left me-1"></i> Back to Dashboard
                    </a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
