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
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=1.2">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
                    <div class="col-md-6">
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                <h4 class="mb-0 fw-bold text-primary"><i class="bi bi-person-fill me-2"></i>User Profile</h4>
                            </div>
                            <div class="card-body p-4 text-center">
                                <div class="mb-4">
                                    <div class="bg-primary bg-opacity-10 text-primary rounded-circle d-inline-flex align-items-center justify-content-center mb-3 shadow-sm" style="width: 100px; height: 100px; border: 4px solid #fff;">
                                        <i class="bi bi-person-badge fs-1"></i>
                                    </div>
                                    <h4 class="fw-bold text-slate-800 mb-0"><%= user.getFullName() %></h4>
                                    <p class="text-muted small"><i class="bi bi-shield-check me-1"></i>Role: <%= user.getRoleName() != null ? user.getRoleName() : "Role ID: " + user.getRoleId() %></p>
                                </div>
                                
                                <div class="table-responsive border-0">
                                    <table class="table table-borderless text-start align-middle mb-0">
                                        <tbody>
                                            <tr class="border-bottom border-light">
                                                <th class="text-muted fw-semibold py-3 ps-0" style="width: 35%;"><i class="bi bi-person-fill me-2 text-primary"></i>Username:</th>
                                                <td class="fw-bold text-slate-800 py-3 pe-0"><%= user.getUsername() %></td>
                                            </tr>
                                            <tr class="border-bottom border-light">
                                                <th class="text-muted fw-semibold py-3 ps-0"><i class="bi bi-envelope-fill me-2 text-primary"></i>Email Address:</th>
                                                <td class="text-slate-800 py-3 pe-0"><%= user.getEmail() %></td>
                                            </tr>
                                            <tr>
                                                <th class="text-muted fw-semibold py-3 ps-0"><i class="bi bi-toggle-on me-2 text-primary"></i>Account Status:</th>
                                                <td class="py-3 pe-0">
                                                    <% if (user.isStatus()) { %>
                                                        <span class="badge bg-success bg-opacity-10 text-success px-3 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.5rem; vertical-align: middle;"></i> Active</span>
                                                    <% } else { %>
                                                        <span class="badge bg-danger bg-opacity-10 text-danger px-3 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.5rem; vertical-align: middle;"></i> Inactive</span>
                                                    <% } %>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <div class="d-flex justify-content-center gap-3 mt-4">
                                    <a href="index.jsp" class="btn btn-outline-secondary px-4"><i class="bi bi-speedometer2 me-1"></i> Dashboard</a>
                                    <a href="change-password" class="btn btn-warning px-4"><i class="bi bi-shield-lock-fill me-1"></i> Change Password</a>
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
