<%@page import="model.Warehouse"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("WAREHOUSE_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    Warehouse warehouse = (Warehouse) request.getAttribute("warehouse");
    boolean isEdit = (warehouse != null);
    if (isEdit && !loggedInUser.hasPermission("WAREHOUSE_EDIT")) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
    }
    if (!isEdit && !loggedInUser.hasPermission("WAREHOUSE_ADD")) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN); return;
    }
    String error = (String) request.getAttribute("error");
    Integer staffCount = (Integer) request.getAttribute("staffCount");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isEdit ? "Chỉnh sửa kho" : "Thêm kho mới" %> - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1"><%= isEdit ? "Chỉnh sửa kho" : "Thêm kho mới" %></h2>
                        <p class="text-muted small mb-0">
                            <a href="<%= request.getContextPath() %>/warehouse/warehouse" class="text-decoration-none text-muted">Quản lý kho</a>
                            <i class="bi bi-chevron-right mx-1 small"></i>
                            <%= isEdit ? "Chỉnh sửa" : "Thêm mới" %>
                        </p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/warehouse" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại
                    </a>
                </div>

                <div class="row justify-content-center">
                    <div class="col-lg-6 col-md-8">
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                <h5 class="mb-0 fw-bold text-primary">
                                    <i class="bi bi-<%= isEdit ? "pencil-square" : "plus-circle" %> me-2"></i>
                                    <%= isEdit ? "Thông tin kho" : "Nhập thông tin kho mới" %>
                                </h5>
                            </div>
                            <div class="card-body p-4">

                                <% if (error != null) { %>
                                <div class="alert alert-danger border-0 mb-4">
                                    <i class="bi bi-exclamation-triangle-fill me-2"></i><%= error %>
                                </div>
                                <% } %>

                                <% if (isEdit && staffCount != null) { %>
                                <div class="alert alert-info border-0 mb-4 py-2">
                                    <i class="bi bi-people-fill me-2"></i>
                                    Kho này đang có <strong><%= staffCount %></strong> nhân viên đang hoạt động.
                                </div>
                                <% } %>

                                <form action="<%= request.getContextPath() %>/warehouse/warehouse?action=<%= isEdit ? "edit" : "add" %>" method="POST">
                                    <% if (isEdit) { %>
                                    <input type="hidden" name="id" value="<%= warehouse.getId() %>">
                                    <% } %>

                                    <div class="mb-4">
                                        <label for="warehouse_name" class="form-label fw-semibold">
                                            Tên kho <span class="text-danger">*</span>
                                        </label>
                                        <input type="text"
                                               class="form-control"
                                               id="warehouse_name"
                                               name="warehouse_name"
                                               value="<%= isEdit ? warehouse.getWarehouseName() : "" %>"
                                               placeholder="VD: Kho Hà Nội, Kho Miền Nam..."
                                               maxlength="100"
                                               required
                                               autofocus>
                                        <div class="form-text text-muted">Tên kho phải là duy nhất trong hệ thống.</div>
                                    </div>

                                    <div class="mb-4">
                                        <label for="address" class="form-label fw-semibold">Địa chỉ</label>
                                        <textarea class="form-control"
                                                  id="address"
                                                  name="address"
                                                  rows="3"
                                                  placeholder="VD: 123 Đường ABC, Quận 1, TP.HCM"
                                                  maxlength="255"><%= isEdit && warehouse.getAddress() != null ? warehouse.getAddress() : "" %></textarea>
                                    </div>

                                    <% if (isEdit) { %>
                                    <div class="mb-4">
                                        <label class="form-label fw-semibold">Trạng thái</label>
                                        <div class="p-2 rounded border bg-light d-flex align-items-center gap-2">
                                            <% if (warehouse.isStatus()) { %>
                                            <span class="badge bg-success">Hoạt động</span>
                                            <span class="text-muted small">Để thay đổi trạng thái, dùng nút Ngừng/Kích hoạt trên trang danh sách.</span>
                                            <% } else { %>
                                            <span class="badge bg-secondary">Ngừng hoạt động</span>
                                            <span class="text-muted small">Để thay đổi trạng thái, dùng nút Ngừng/Kích hoạt trên trang danh sách.</span>
                                            <% } %>
                                        </div>
                                    </div>
                                    <% } %>

                                    <div class="d-flex justify-content-end gap-2 pt-2">
                                        <a href="<%= request.getContextPath() %>/warehouse/warehouse" class="btn btn-outline-secondary px-4">
                                            <i class="bi bi-x-circle me-1"></i> Hủy
                                        </a>
                                        <button type="submit" class="btn btn-primary px-4">
                                            <i class="bi bi-check-circle-fill me-1"></i>
                                            <%= isEdit ? "Lưu thay đổi" : "Thêm kho" %>
                                        </button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
