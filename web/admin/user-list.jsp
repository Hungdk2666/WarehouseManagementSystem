<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("USER_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<User> userList = (List<User>) request.getAttribute("userList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quản lý người dùng - WMS</title>
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
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Quản lý người dùng</h2>
                        <p class="page-subtitle">Quản lý người dùng, vai trò và trạng thái tài khoản của hệ thống</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (loggedInUser.hasPermission("USER_ADD")) { %>
                        <a href="user?action=add" class="btn btn-primary d-flex align-items-center gap-2">
                            <i class="bi bi-person-plus-fill"></i> Thêm người dùng mới
                        </a>
                        <% } %>
                    </div>
                </div>

                <!-- Server-Side Search and Filter Panel -->
                <div class="card mb-3">
                    <div class="card-body">
                        <form action="user" method="GET" class="row g-2">
                            <input type="hidden" name="action" value="list">
                            <div class="col-md-5">
                                <label class="form-label small fw-semibold">Tìm kiếm</label>
                                <input type="text" name="search" class="form-control form-control-sm" placeholder="Tìm theo tên đăng nhập, email, họ tên..." value="<%= request.getParameter("search") != null ? request.getParameter("search") : "" %>">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small fw-semibold">Vai trò</label>
                                <select name="roleFilter" class="form-select form-select-sm">
                                    <option value="">Tất cả</option>
                                    <%
                                        List<Role> roleList = (List<Role>) request.getAttribute("roleList");
                                        String selectedRole = request.getParameter("roleFilter");
                                        if (roleList != null) {
                                            for (Role r : roleList) {
                                                boolean isSelected = r.getRoleName().equals(selectedRole);
                                    %>
                                        <option value="<%= r.getRoleName() %>" <%= isSelected ? "selected" : "" %>><%= r.getRoleName() %></option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-2 d-flex align-items-end gap-1">
                                <button type="submit" class="btn btn-primary btn-sm flex-grow-1"><i class="bi bi-funnel"></i> Lọc</button>
                                <a href="user?action=list" class="btn btn-outline-secondary btn-sm" title="Làm mới"><i class="bi bi-arrow-counterclockwise"></i></a>
                            </div>
                        </form>
                    </div>
                </div>

                <div class="card mb-4">
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="ps-4">ID</th>
                                        <th>Tên đăng nhập</th>
                                        <th>Email</th>
                                        <th>Họ và tên</th>
                                        <th>Tên vai trò</th>
                                        <th>Trạng thái</th>
                                        <th class="text-center">Mã đặt lại</th>
                                        <th class="text-center">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (userList != null && !userList.isEmpty()) {
                                            for (User u : userList) {
                                    %>
                                    <tr>
                                        <td class="ps-4 fw-semibold text-muted">#<%= u.getId() %></td>
                                        <td class="fw-bold text-slate-800"><%= u.getUsername() %></td>
                                        <td><%= u.getEmail() %></td>
                                        <td><%= u.getFullName() %></td>
                                        <td>
                                            <span class="badge bg-light text-primary"><%= u.getRoleName() != null ? u.getRoleName() : "Chưa có vai trò" %></span>
                                        </td>
                                        <td>
                                            <% if (u.isStatus()) { %>
                                                <span class="status-chip chip-success">Hoạt động</span>
                                            <% } else { %>
                                                <span class="status-chip chip-muted">Ngừng hoạt động</span>
                                            <% } %>
                                        </td>
                                        <td class="text-center">
                                            <% if (u.getResetCode() != null) { %>
                                                <span class="badge bg-light text-danger"><%= u.getResetCode() %></span>
                                            <% } else { %>
                                                <span class="text-muted">-</span>
                                            <% } %>
                                        </td>
                                        <td class="text-center">
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="user?action=info&id=<%= u.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết">
                                                    <i class="bi bi-eye"></i>
                                                </a>
                                                <% if (loggedInUser.hasPermission("USER_EDIT")) { %>
                                                <a href="user?action=update&id=<%= u.getId() %>" class="btn btn-table btn-outline-primary" title="Sửa">
                                                    <i class="bi bi-pencil-square"></i>
                                                </a>
                                                <% } %>
                                                <% if (loggedInUser.hasPermission("USER_TOGGLE")) { %>
                                                <form action="user?action=toggle" method="POST" style="display:inline;" class="m-0">
                                                    <input type="hidden" name="id" value="<%= u.getId() %>">
                                                    <button type="submit" class="btn btn-table <%= u.isStatus() ? "btn-outline-danger" : "btn-outline-success" %>" title="<%= u.isStatus() ? "Vô hiệu hóa tài khoản" : "Kích hoạt tài khoản" %>">
                                                        <i class="bi bi-power"></i>
                                                    </button>
                                                </form>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="8" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không tìm thấy người dùng nào phù hợp với tiêu chí tìm kiếm.</p></div></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <div class="mt-4">
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary">
                        <i class="bi bi-arrow-left me-1"></i> Quay lại Trang chủ
                    </a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
