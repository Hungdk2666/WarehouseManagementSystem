<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("user") == null) {
        response.sendRedirect("login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Change Password - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
            <div class="col-md-5">
                <div class="card shadow-sm">
                    <div class="card-header bg-warning">
                        <h4 class="mb-0">Change Password</h4>
                    </div>
                    <div class="card-body">
                        <% 
                            String error = (String) request.getAttribute("error");
                            String message = (String) request.getAttribute("message");
                            if (error != null) {
                        %>
                            <div class="alert alert-danger"><%= error %></div>
                        <% } %>
                        <% 
                            if (message != null) {
                        %>
                            <div class="alert alert-success"><%= message %></div>
                        <% } %>
                        <form action="change-password" method="POST">
                            <div class="mb-3">
                                <label class="form-label">Old Password</label>
                                <input type="password" name="oldPassword" class="form-control" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">New Password</label>
                                <input type="password" name="newPassword" class="form-control" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Confirm New Password</label>
                                <input type="password" name="confirmPassword" class="form-control" required>
                            </div>
                            <div class="d-grid mb-3">
                                <button type="submit" class="btn btn-warning">Update Password</button>
                            </div>
                            <div class="text-center">
                                <a href="index.jsp" class="text-decoration-none">Cancel & Go Back</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
