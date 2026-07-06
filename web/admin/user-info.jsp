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
    <title>Thông tin người dùng</title>
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
                        <div class="card">
                            <div class="card-header bg-white py-3">
                                <h4 class="mb-0 fw-bold text-slate-800"><i class="bi bi-person-lines-fill me-2 text-primary"></i>Thông tin người dùng</h4>
                            </div>
                            <div class="card-body p-4 text-center">
                                <div class="mb-4">
                                    <div class="bg-primary bg-opacity-10 text-primary rounded-circle d-inline-flex align-items-center justify-content-center mb-3 shadow-sm" style="width: 90px; height: 90px; border: 4px solid #fff;">
                                        <i class="bi bi-person-fill-gear fs-1"></i>
                                    </div>
                                    <h4 class="fw-bold text-slate-800 mb-0"><%= userInfo.getFullName() %></h4>
                                    <p class="text-muted small mb-0"><i class="bi bi-envelope-fill me-1"></i><%= userInfo.getEmail() %></p>
                                </div>
                                
                                <div class="text-start">
                                    <div class="detail-row"><div class="detail-label">ID người dùng</div><div class="detail-value">#<%= userInfo.getId() %></div></div>
                                    <div class="detail-row"><div class="detail-label">Tên đăng nhập</div><div class="detail-value"><%= userInfo.getUsername() %></div></div>
                                    <div class="detail-row"><div class="detail-label">Tên vai trò</div><div class="detail-value"><%= userInfo.getRoleName() != null ? userInfo.getRoleName() : "ID vai trò: " + userInfo.getRoleId() %></div></div>
                                    <div class="detail-row"><div class="detail-label">Trạng thái</div><div class="detail-value">
                                        <% if (userInfo.isStatus()) { %>
                                            <span class="status-chip chip-success">Hoạt động</span>
                                        <% } else { %>
                                            <span class="status-chip chip-muted">Ngừng hoạt động</span>
                                        <% } %>
                                    </div></div>
                                </div>
                                <div class="d-flex justify-content-center gap-3 mt-4">
                                    <% if (loggedInUser.hasPermission("USER_EDIT")) { %>
                                    <a href="user?action=update&id=<%= userInfo.getId() %>" class="btn btn-primary px-4"><i class="bi bi-pencil-square me-1"></i> Sửa người dùng</a>
                                    <% } %>
                                    <a href="user?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-arrow-left me-1"></i> Quay lại danh sách</a>
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
