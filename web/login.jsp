<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login - WMS</title>
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
            <i class="bi bi-box-seam-fill"></i> WMS SYSTEM
        </div>
        
        <div class="auth-card">
            <h3 class="text-center mb-4 card-title">Login</h3>
            
            <% 
                String error = (String) request.getAttribute("error");
                String message = (String) request.getAttribute("message");
                if (error != null) {
            %>
                <div class="alert alert-danger py-2 border-0 bg-danger bg-opacity-25 text-white" style="font-size: 0.9rem;">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i> <%= error %>
                </div>
            <% } %>
            <% 
                if (message != null) {
            %>
                <div class="alert alert-success py-2 border-0 bg-success bg-opacity-25 text-white" style="font-size: 0.9rem;">
                    <i class="bi bi-check-circle-fill me-2"></i> <%= message %>
                </div>
            <% } %>
            
            <form action="login" method="POST">
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-person-fill me-1"></i> Username</label>
                    <input type="text" name="username" class="form-control" placeholder="Enter username" required autocomplete="username">
                </div>
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-lock-fill me-1"></i> Password</label>
                    <input type="password" name="password" class="form-control" placeholder="Enter password" required autocomplete="current-password">
                </div>
                <div class="d-grid mb-3 mt-4">
                    <button type="submit" class="btn btn-primary btn-lg fs-6"><i class="bi bi-box-arrow-in-right me-1"></i> Sign In</button>
                </div>
                <div class="text-center mt-3">
                    <a href="forgot-password" class="text-decoration-none small"><i class="bi bi-question-circle me-1"></i>Forgot password?</a>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
