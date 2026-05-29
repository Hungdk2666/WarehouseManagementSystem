<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("USER_VIEW")) {
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
                            <div class="card-header bg-info bg-opacity-10 py-3 border-0">
                                <h4 class="mb-0 fw-bold text-info"><i class="bi bi-person-lines-fill me-2"></i>User Information</h4>
                            </div>
                            <div class="card-body p-4 text-center">
                                <div class="mb-4">
                                    <div class="bg-info bg-opacity-10 text-info rounded-circle d-inline-flex align-items-center justify-content-center mb-3 shadow-sm" style="width: 90px; height: 90px; border: 4px solid #fff;">
                                        <i class="bi bi-person-fill-gear fs-1"></i>
                                    </div>
                                    <h4 class="fw-bold text-slate-800 mb-0"><%= userInfo.getFullName() %></h4>
                                    <p class="text-muted small mb-0"><i class="bi bi-envelope-fill me-1"></i><%= userInfo.getEmail() %></p>
                                </div>
                                
                                <div class="table-responsive border-0">
                                    <table class="table table-borderless text-start align-middle mb-0">
                                        <tbody>
                                            <tr class="border-bottom border-light">
                                                <th class="text-muted fw-semibold py-3 ps-0" style="width: 35%;"><i class="bi bi-hash me-2 text-info"></i>User ID:</th>
                                                <td class="fw-bold text-slate-800 py-3 pe-0">#<%= userInfo.getId() %></td>
                                            </tr>
                                            <tr class="border-bottom border-light">
                                                <th class="text-muted fw-semibold py-3 ps-0"><i class="bi bi-person-fill me-2 text-info"></i>Username:</th>
                                                <td class="fw-bold text-slate-800 py-3 pe-0"><%= userInfo.getUsername() %></td>
                                            </tr>
                                            <tr class="border-bottom border-light">
                                                <th class="text-muted fw-semibold py-3 ps-0"><i class="bi bi-shield-check me-2 text-info"></i>Role Name:</th>
                                                <td class="text-slate-800 py-3 pe-0"><%= userInfo.getRoleName() != null ? userInfo.getRoleName() : "Role ID: " + userInfo.getRoleId() %></td>
                                            </tr>
                                            <tr>
                                                <th class="text-muted fw-semibold py-3 ps-0"><i class="bi bi-toggle-on me-2 text-info"></i>Status:</th>
                                                <td class="py-3 pe-0">
                                                    <% if (userInfo.isStatus()) { %>
                                                        <span class="badge bg-success bg-opacity-10 text-success px-3 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.5rem; vertical-align: middle;"></i> Active</span>
                                                    <% } else { %>
                                                        <span class="badge bg-secondary bg-opacity-10 text-secondary px-3 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.5rem; vertical-align: middle;"></i> Inactive</span>
                                                    <% } %>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <div class="d-flex justify-content-center gap-3 mt-4">
                                    <% if (loggedInUser.hasPermission("USER_EDIT")) { %>
                                    <a href="user?action=update&id=<%= userInfo.getId() %>" class="btn btn-warning px-4"><i class="bi bi-pencil-square me-1"></i> Edit User</a>
                                    <% } %>
                                    <a href="user?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-arrow-left me-1"></i> Back to List</a>
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
