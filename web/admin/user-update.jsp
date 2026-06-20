<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("USER_EDIT")) {
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
    <title>Cập nhật người dùng</title>
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
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-warning bg-opacity-10 py-3 border-0">
                                <h4 class="mb-0 fw-bold text-warning-emphasis"><i class="bi bi-pencil-square me-2"></i>Cập nhật thông tin người dùng</h4>
                            </div>
                            <div class="card-body p-4">
                                <form action="user?action=update" method="POST">
                                    <input type="hidden" name="id" value="<%= userInfo.getId() %>">
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-person me-1 text-muted"></i> Tên đăng nhập (Chỉ đọc)</label>
                                        <input type="text" class="form-control text-muted bg-light" value="<%= userInfo.getUsername() %>" disabled>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-envelope me-1 text-muted"></i> Email</label>
                                        <input type="email" name="email" class="form-control" value="<%= userInfo.getEmail() %>" required autocomplete="email">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-card-text me-1 text-muted"></i> Họ và tên</label>
                                        <input type="text" name="full_name" class="form-control" value="<%= userInfo.getFullName() %>" required>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label"><i class="bi bi-shield-check me-1 text-muted"></i> Vai trò</label>
                                        <select name="role_id" class="form-select" required>
                                        <%
                                            List<Role> roleList = (List<Role>) request.getAttribute("roleList");
                                            if(roleList != null) {
                                                for(Role role : roleList) {
                                        %>
                                            <option value="<%= role.getId() %>" <%= userInfo.getRoleId() == role.getId() ? "selected" : "" %>><%= role.getRoleName() %></option>
                                        <%
                                                }
                                            }
                                        %>
                                        </select>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label"><i class="bi bi-geo-alt me-1 text-muted"></i> Kho làm việc</label>
                                        <select name="warehouse_id" class="form-select">
                                            <option value="" <%= userInfo.getWarehouseId() == null ? "selected" : "" %>>Toàn cầu / Tất cả các kho</option>
                                            <%
                                                List<model.Warehouse> warehouseList = (List<model.Warehouse>) request.getAttribute("warehouseList");
                                                if(warehouseList != null) {
                                                    for(model.Warehouse w : warehouseList) {
                                                        boolean isSelected = userInfo.getWarehouseId() != null && userInfo.getWarehouseId().equals(w.getId());
                                            %>
                                                <option value="<%= w.getId() %>" <%= isSelected ? "selected" : "" %>><%= w.getWarehouseName() %></option>
                                            <%
                                                    }
                                                }
                                            %>
                                        </select>
                                    </div>
                                    <div class="d-grid mb-3 mt-4">
                                        <button type="submit" class="btn btn-warning fw-semibold"><i class="bi bi-check-circle me-1"></i> Cập nhật thông tin</button>
                                    </div>
                                    <div class="text-center">
                                        <a href="user?action=list" class="btn btn-outline-secondary w-100"><i class="bi bi-x-circle me-1"></i> Hủy</a>
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
