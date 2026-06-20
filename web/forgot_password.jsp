<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quên mật khẩu - WMS</title>
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
            <h4 class="text-center mb-4 card-title">Tìm tài khoản</h4>
            <% 
                String error = (String) request.getAttribute("error");
                if (error != null) {
            %>
                <div class="alert alert-danger py-2 border-0 bg-danger bg-opacity-25 text-white" style="font-size: 0.9rem;">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i> <%= error %>
                </div>
            <% } %>
            <form action="forgot-password" method="POST">
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-envelope-fill me-1"></i> Địa chỉ Email</label>
                    <input type="email" name="email" class="form-control" placeholder="Nhập email đã đăng ký" required autocomplete="email">
                </div>
                <div class="d-grid mb-3 mt-4">
                    <button type="submit" class="btn btn-primary btn-lg fs-6"><i class="bi bi-search me-1"></i> Kiểm tra Email</button>
                </div>
                <div class="text-center mt-3">
                    <a href="login" class="text-decoration-none small"><i class="bi bi-arrow-left me-1"></i> Quay lại đăng nhập</a>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
