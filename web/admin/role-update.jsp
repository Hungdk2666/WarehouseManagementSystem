<%@page import="model.Role"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("ROLE_EDIT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Role roleInfo = (Role) request.getAttribute("roleInfo");
    if (roleInfo == null) {
        response.sendRedirect("role?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Sửa thông tin vai trò</title>
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
                        <div class="card form-card">
                            <div class="card-header bg-white py-3">
                                <h4 class="mb-0 fw-bold text-slate-800"><i class="bi bi-pencil-square me-2 text-primary"></i>Sửa thông tin vai trò</h4>
                            </div>
                            <div class="card-body p-4">
                                <form action="role?action=update" method="POST">
                                    <input type="hidden" name="id" value="<%= roleInfo.getId() %>">
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-hash me-1 text-muted"></i> ID vai trò (Chỉ đọc)</label>
                                        <input type="text" class="form-control text-muted bg-light" value="<%= roleInfo.getId() %>" disabled>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label"><i class="bi bi-shield-check me-1 text-muted"></i> Tên vai trò</label>
                                        <input type="text" name="role_name" class="form-control" value="<%= roleInfo.getRoleName() %>" placeholder="Nhập tên vai trò" required>
                                    </div>
                                    <div class="form-actions">
                                        <a href="role?action=list" class="btn btn-outline-secondary">Hủy</a>
                                        <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Lưu thay đổi</button>
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
