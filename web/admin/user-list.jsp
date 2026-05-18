<%@page import="model.User"%>
<%@page import="java.util.List"%>
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
    <title>Manage Users</title>
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
        <div class="card shadow-sm">
            <div class="card-body">
                <table class="table table-bordered table-hover align-middle text-center">
                    <thead class="table-dark">
                        <tr>
                            <th>ID</th>
                            <th>Username</th>
                            <th>Email</th>
                            <th>Full Name</th>
                            <th>Role ID</th>
                            <th>Status</th>
                            <th>Reset Code</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            if (userList != null) {
                                for (User u : userList) {
                        %>
                        <tr>
                            <td><%= u.getId() %></td>
                            <td><%= u.getUsername() %></td>
                            <td><%= u.getEmail() %></td>
                            <td><%= u.getFullName() %></td>
                            <td><%= u.getRoleId() %></td>
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
                            }
                        %>
                    </tbody>
                </table>
            </div>
        </div>
        <div class="mt-3">
            <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-secondary">Back to Dashboard</a>
        </div>
        </div>
            </div>
        </div>
    </div>
</body>
</html>
