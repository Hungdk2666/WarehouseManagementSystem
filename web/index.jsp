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
    <title>Dashboard - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <!-- Left Sidebar -->
            <jsp:include page="/includes/sidebar.jsp" />

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <h2>Welcome, <%= user.getFullName() %>!</h2>
                <p>Your Role ID is: <%= user.getRoleId() %> | Status: <%= user.isStatus() ? "Active" : "Inactive" %></p>
                <hr>
                <div class="row mt-4">
                    <div class="col-12">
                        <div class="card shadow-sm mb-4">
                            <div class="card-header bg-white">
                                <h5 class="mb-0">System Overview</h5>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-4 text-center border-end">
                                        <h3 class="text-primary">150</h3>
                                        <p class="text-muted mb-0">Total Products</p>
                                    </div>
                                    <div class="col-md-4 text-center border-end">
                                        <h3 class="text-success">24</h3>
                                        <p class="text-muted mb-0">Active Orders</p>
                                    </div>
                                    <div class="col-md-4 text-center">
                                        <h3 class="text-warning">5</h3>
                                        <p class="text-muted mb-0">Pending Alerts</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-12">
                        <div class="card shadow-sm">
                            <div class="card-header bg-white">
                                <h5 class="mb-0">Recent Activities</h5>
                            </div>
                            <div class="card-body">
                                <p class="text-muted text-center my-4">No recent activities to display.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
