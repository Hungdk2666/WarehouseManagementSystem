<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("USER_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Thêm người dùng mới</title>
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
                    <div class="col-md-6">
                        <div class="card form-card">
                            <div class="card-header bg-white py-3">
                                <h4 class="mb-0 fw-bold text-slate-800"><i class="bi bi-person-plus-fill me-2 text-primary"></i>Thêm người dùng mới</h4>
                            </div>
                            <div class="card-body p-4">
                                <div class="alert alert-info border-0 bg-info bg-opacity-10 text-dark py-2.5 px-3 rounded-3 small mb-4">
                                    <i class="bi bi-info-circle-fill me-1"></i> Mật khẩu mặc định cho người dùng mới là <strong>123456</strong> (sẽ được tự động băm).
                                </div>
                                <form action="user?action=add" method="POST">
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-person me-1 text-muted"></i> Tên đăng nhập</label>
                                        <input type="text" name="username" class="form-control" placeholder="Nhập tên đăng nhập" required>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-envelope me-1 text-muted"></i> Email</label>
                                        <input type="email" name="email" class="form-control" placeholder="Nhập địa chỉ email" required>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-card-text me-1 text-muted"></i> Họ và tên</label>
                                        <input type="text" name="full_name" class="form-control" placeholder="Nhập họ và tên" required>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label"><i class="bi bi-shield-check me-1 text-muted"></i> Vai trò</label>
                                        <select name="role_id" class="form-select" required>
                                        <%
                                            List<Role> roleList = (List<Role>) request.getAttribute("roleList");
                                            if(roleList != null) {
                                                for(Role role : roleList) {
                                        %>
                                            <option value="<%= role.getId() %>"><%= role.getRoleName() %></option>
                                        <%
                                                }
                                            }
                                        %>
                                        </select>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label"><i class="bi bi-geo-alt me-1 text-muted"></i> Kho làm việc</label>
                                        <select name="warehouse_id" class="form-select">
                                            <option value="">Toàn cầu / Tất cả các kho</option>
                                            <%
                                                List<model.Warehouse> warehouseList = (List<model.Warehouse>) request.getAttribute("warehouseList");
                                                if(warehouseList != null) {
                                                    for(model.Warehouse w : warehouseList) {
                                            %>
                                                <option value="<%= w.getId() %>"><%= w.getWarehouseName() %></option>
                                            <%
                                                    }
                                                }
                                            %>
                                        </select>
                                    </div>
                                    <div class="form-actions">
                                        <a href="user?action=list" class="btn btn-outline-secondary">Hủy</a>
                                        <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Lưu người dùng</button>
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
