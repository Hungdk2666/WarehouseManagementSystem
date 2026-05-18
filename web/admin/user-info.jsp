<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    User userInfo = (User) request.getAttribute("userInfo");
    if (userInfo == null) {
        response.sendRedirect("user?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>User Information</title>
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
                    <div class="card-header bg-info text-white">
                        <h4 class="mb-0">User Information</h4>
                    </div>
                    <div class="card-body">
                        <table class="table table-bordered">
                            <tr>
                                <th class="w-25 bg-light">ID</th>
                                <td><%= userInfo.getId() %></td>
                            </tr>
                            <tr>
                                <th class="bg-light">Username</th>
                                <td><%= userInfo.getUsername() %></td>
                            </tr>
                            <tr>
                                <th class="bg-light">Email</th>
                                <td><%= userInfo.getEmail() %></td>
                            </tr>
                            <tr>
                                <th class="bg-light">Full Name</th>
                                <td><%= userInfo.getFullName() %></td>
                            </tr>
                            <tr>
                                <th class="bg-light">Role ID</th>
                                <td><%= userInfo.getRoleId() %></td>
                            </tr>
                            <tr>
                                <th class="bg-light">Status</th>
                                <td>
                                    <% if (userInfo.isStatus()) { %>
                                        <span class="badge bg-success">Active</span>
                                    <% } else { %>
                                        <span class="badge bg-secondary">Deactive</span>
                                    <% } %>
                                </td>
                            </tr>
                        </table>
                        <div class="text-center mt-3">
                            <a href="user?action=update&id=<%= userInfo.getId() %>" class="btn btn-warning">Edit</a>
                            <a href="user?action=list" class="btn btn-secondary">Back to List</a>
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
