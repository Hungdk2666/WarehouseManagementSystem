<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String resetEmail = (String) session.getAttribute("resetEmail");
    if (resetEmail == null) {
        resetEmail = "";
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Verify Code - WMS</title>
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
            <h4 class="text-center mb-4 card-title">Verify Code</h4>
            
            <div class="alert alert-info py-2 border-0 bg-info bg-opacity-25 text-white text-center small mb-4">
                <i class="bi bi-info-circle-fill me-1"></i> A reset request has been sent to Admin.<br>Please contact the Admin to get your reset code.
            </div>
            
            <% 
                String error = (String) request.getAttribute("error");
                if (error != null) {
            %>
                <div class="alert alert-danger py-2 border-0 bg-danger bg-opacity-25 text-white" style="font-size: 0.9rem;">
                    <i class="bi bi-exclamation-triangle-fill me-2"></i> <%= error %>
                </div>
            <% } %>
            
            <form action="verify-code" method="POST">
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-envelope-fill me-1"></i> Email Address</label>
                    <input type="email" name="email" class="form-control text-white-50 bg-transparent" value="<%= resetEmail %>" required <%= resetEmail.isEmpty() ? "" : "readonly" %>>
                </div>
                <div class="mb-3">
                    <label class="form-label"><i class="bi bi-key-fill me-1"></i> Admin Code</label>
                    <input type="text" name="code" class="form-control text-center fs-5" placeholder="Enter 6-digit code" required style="letter-spacing: 0.1em;">
                </div>
                <div class="d-grid mb-3 mt-4">
                    <button type="submit" class="btn btn-primary btn-lg fs-6"><i class="bi bi-check-circle me-1"></i> Verify Code</button>
                </div>
                <div class="text-center mt-3">
                    <a href="login" class="text-decoration-none small"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
