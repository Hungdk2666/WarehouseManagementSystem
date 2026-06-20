<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("resetUserId") == null) {
        response.sendRedirect("forgot-password");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Đặt mật khẩu mới - WMS</title>
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
<body class="auth-body">
    <div class="auth-container animated-fade-in">
        <!-- Brand Logo -->
        <div class="auth-logo">
            <i class="bi bi-box-seam-fill"></i> HỆ THỐNG WMS
        </div>

        <div class="auth-card">
            <h4 class="text-center mb-4 card-title">Đặt mật khẩu mới</h4>
            <% 
                String error = (String) request.getAttribute("error");
                if (error != null) {
            %>
                <div class="alert alert-danger py-2 border-0 bg-danger bg-opacity-25 text-white" style="font-size: 0.9rem;">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i> <%= error %>
                </div>
            <% } %>
            <form action="reset-password" method="POST">
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-lock-fill me-1"></i> Mật khẩu mới</label>
                    <input type="password" name="newPassword" class="form-control" placeholder="Nhập mật khẩu mới" required autocomplete="new-password">
                </div>
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-lock-check-fill me-1"></i> Xác nhận mật khẩu mới</label>
                    <input type="password" name="confirmPassword" class="form-control" placeholder="Xác nhận mật khẩu mới" required autocomplete="new-password">
                </div>
                <div class="d-grid mb-3 mt-4">
                    <button type="submit" class="btn btn-success btn-lg fs-6"><i class="bi bi-shield-check me-1"></i> Lưu mật khẩu</button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
