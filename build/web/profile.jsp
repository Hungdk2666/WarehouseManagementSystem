<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Profile - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="card shadow-sm">
                    <div class="card-header bg-primary text-white">
                        <h4 class="mb-0">User Profile</h4>
                    </div>
                    <div class="card-body">
                        <table class="table table-borderless">
                            <tr>
                                <th>Username:</th>
                                <td><%= user.getUsername() %></td>
                            </tr>
                            <tr>
                                <th>Full Name:</th>
                                <td><%= user.getFullName() %></td>
                            </tr>
                            <tr>
                                <th>Email:</th>
                                <td><%= user.getEmail() %></td>
                            </tr>
                            <tr>
                                <th>Status:</th>
                                <td>
                                    <% if (user.isStatus()) { %>
                                        <span class="badge bg-success">Active</span>
                                    <% } else { %>
                                        <span class="badge bg-danger">Inactive</span>
                                    <% } %>
                                </td>
                            </tr>
                            <tr>
                                <th>Role ID:</th>
                                <td><%= user.getRoleId() %></td>
                            </tr>
                        </table>
                        <div class="text-center mt-3">
                            <a href="index.jsp" class="btn btn-secondary">Back to Dashboard</a>
                            <a href="change-password" class="btn btn-warning">Change Password</a>
                        </div>
                    </div>
                </div>
            </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
