<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Role> roleList = (List<Role>) request.getAttribute("roleList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Roles</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h2>Role Management</h2>
        </div>
        <div class="card shadow-sm">
            <div class="card-body">
                <table class="table table-bordered table-hover align-middle text-center">
                    <thead class="table-dark">
                        <tr>
                            <th>ID</th>
                            <th>Role Name</th>
                            <th>Status</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            if (roleList != null) {
                                for (Role r : roleList) {
                        %>
                        <tr>
                            <td><%= r.getId() %></td>
                            <td><%= r.getRoleName() %></td>
                            <td>
                                <% if (r.isStatus()) { %>
                                    <span class="badge bg-success">Active</span>
                                <% } else { %>
                                    <span class="badge bg-secondary">Deactive</span>
                                <% } %>
                            </td>
                            <td>
                                <a href="role?action=permissions&id=<%= r.getId() %>" class="btn btn-sm btn-info text-white">Permissions</a>
                                <a href="role?action=update&id=<%= r.getId() %>" class="btn btn-sm btn-warning">Edit</a>
                                <form action="role?action=toggle" method="POST" style="display:inline;">
                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                    <button type="submit" class="btn btn-sm <%= r.isStatus() ? "btn-danger" : "btn-primary" %>">
                                        <%= r.isStatus() ? "Deactivate" : "Activate" %>
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
