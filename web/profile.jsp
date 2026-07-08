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
    <title>Trang cá nhân - WMS</title>
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
                        <div class="card form-card-narrow bg-white">
                             <div class="card-header bg-white py-3">
                                <span class="fw-bold text-slate-800"><i class="bi bi-person-fill me-2 text-primary"></i>Thông tin cá nhân</span>
                            </div>
                            <div class="card-body p-4 text-center">
                                <div class="mb-4">
                                    <div class="bg-primary bg-opacity-10 text-primary rounded-circle d-inline-flex align-items-center justify-content-center mb-3" style="width: 92px; height: 92px;">
                                        <i class="bi bi-person-badge fs-1"></i>
                                    </div>
                                    <h4 class="fw-bold text-slate-800 mb-0"><%= user.getFullName() %></h4>
                                    <p class="text-muted small"><i class="bi bi-shield-check me-1"></i>Vai trò: <%= user.getRoleName() != null ? user.getRoleName() : "Mã vai trò: " + user.getRoleId() %></p>
                                </div>

                                <div class="text-start">
                                    <div class="detail-row"><div class="detail-label"><i class="bi bi-person-fill me-1 text-primary"></i>Tên đăng nhập</div><div class="detail-value"><%= user.getUsername() %></div></div>
                                    <div class="detail-row"><div class="detail-label"><i class="bi bi-envelope-fill me-1 text-primary"></i>Địa chỉ Email</div><div class="detail-value"><%= user.getEmail() %></div></div>
                                    <div class="detail-row"><div class="detail-label"><i class="bi bi-toggle-on me-1 text-primary"></i>Trạng thái tài khoản</div>
                                        <div class="detail-value">
                                            <% if (user.isStatus()) { %>
                                                <span class="status-chip chip-success">Hoạt động</span>
                                            <% } else { %>
                                                <span class="status-chip chip-danger">Không hoạt động</span>
                                            <% } %>
                                        </div>
                                    </div>
                                </div>
                                <div class="d-flex justify-content-center gap-2 mt-4">
                                    <a href="index.jsp" class="btn btn-outline-secondary px-4"><i class="bi bi-speedometer2 me-1"></i> Trang chủ</a>
                                    <a href="change-password" class="btn btn-primary px-4"><i class="bi bi-shield-lock-fill me-1"></i> Đổi mật khẩu</a>
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
