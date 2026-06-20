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
    <title>Đổi mật khẩu - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
                    <div class="col-md-5">
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-warning bg-opacity-10 py-3 border-0">
                                <h4 class="mb-0 fw-bold text-warning-emphasis"><i class="bi bi-shield-lock-fill me-2"></i>Đổi mật khẩu</h4>
                            </div>
                            <div class="card-body p-4">
                                <% 
                                    String error = (String) request.getAttribute("error");
                                    String message = (String) request.getAttribute("message");
                                    if (error != null) {
                                %>
                                    <div class="alert alert-danger py-2 border-0 bg-danger bg-opacity-10 text-danger" style="font-size: 0.9rem;">
                                        <i class="bi bi-exclamation-triangle-fill me-2"></i> <%= error %>
                                    </div>
                                <% } %>
                                <% 
                                    if (message != null) {
                                %>
                                    <div class="alert alert-success py-2 border-0 bg-success bg-opacity-10 text-success" style="font-size: 0.9rem;">
                                        <i class="bi bi-check-circle-fill me-2"></i> <%= message %>
                                    </div>
                                <% } %>
                                <form action="change-password" method="POST">
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-key me-1 text-muted"></i> Mật khẩu cũ</label>
                                        <input type="password" name="oldPassword" class="form-control" placeholder="Nhập mật khẩu cũ" required autocomplete="current-password">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-lock me-1 text-muted"></i> Mật khẩu mới</label>
                                        <input type="password" name="newPassword" class="form-control" placeholder="Nhập mật khẩu mới" required autocomplete="new-password">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-lock-check me-1 text-muted"></i> Xác nhận mật khẩu mới</label>
                                        <input type="password" name="confirmPassword" class="form-control" placeholder="Xác nhận mật khẩu mới" required autocomplete="new-password">
                                    </div>
                                    <div class="d-grid mb-3 mt-4">
                                        <button type="submit" class="btn btn-warning fw-semibold"><i class="bi bi-shield-check me-1"></i> Cập nhật mật khẩu</button>
                                    </div>
                                    <div class="text-center">
                                        <a href="profile.jsp" class="text-decoration-none small"><i class="bi bi-arrow-left me-1"></i> Hủy & Quay lại</a>
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
