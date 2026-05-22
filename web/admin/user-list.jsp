<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2>User Management</h2>
                    <a href="user?action=add" class="btn btn-success">Add New User</a>
                </div>

                <!-- Server-Side Search and Filter Panel -->
                <form action="user" method="GET" class="row g-3 mb-4">
                    <input type="hidden" name="action" value="list">
                    <div class="col-md-6 col-lg-7">
                        <input type="text" name="search" class="form-control" placeholder="Search by username, email, full name..." value="<%= request.getParameter("search") != null ? request.getParameter("search") : "" %>">
                    </div>
                    <div class="col-md-4 col-lg-3">
                        <select name="roleFilter" class="form-select">
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
                    <div class="col-md-2 col-lg-2">
                        <button type="submit" class="btn btn-primary w-100">Filter</button>
                    </div>
                </form>

                <div class="card shadow-sm">
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-bordered table-hover align-middle text-center mb-0">
                                <thead class="table-dark">
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
                                        Map<Integer, String> roleMap = (Map<Integer, String>) request.getAttribute("roleMap");
                                        if (userList != null && !userList.isEmpty()) {
                                            for (User u : userList) {
                                                String userRoleName = roleMap != null ? roleMap.get(u.getRoleId()) : null;
                                    %>
                                    <tr>
                                        <td><%= u.getId() %></td>
                                        <td><%= u.getUsername() %></td>
                                        <td><%= u.getEmail() %></td>
                                        <td><%= u.getFullName() %></td>
                                        <td><%= userRoleName != null ? userRoleName : "" %></td>
                                        <td>
                                            <% if (u.isStatus()) { %>
                                                <span class="badge bg-success">Active</span>
                                            <% } else { %>
                                                <span class="badge bg-secondary">Deactive</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (u.getResetCode() != null) { %>
                                                <span class="badge bg-danger"><%= u.getResetCode() %></span>
                                            <% } else { %>
                                                <span class="text-muted">-</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <a href="user?action=info&id=<%= u.getId() %>" class="btn btn-sm btn-info text-white">Info</a>
                                            <a href="user?action=update&id=<%= u.getId() %>" class="btn btn-sm btn-warning">Update</a>
                                            <form action="user?action=toggle" method="POST" style="display:inline;">
                                                <input type="hidden" name="id" value="<%= u.getId() %>">
                                                <button type="submit" class="btn btn-sm <%= u.isStatus() ? "btn-danger" : "btn-primary" %>">
                                                    <%= u.isStatus() ? "Deactivate" : "Activate" %>
                                                </button>
                                            </form>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="8" class="text-center text-muted py-4">No users found.</td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="mt-3">
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-secondary">Back to Dashboard</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
