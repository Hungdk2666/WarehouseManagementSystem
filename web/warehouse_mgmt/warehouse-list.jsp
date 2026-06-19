<%@page import="model.Warehouse"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("WAREHOUSE_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }
    List<Warehouse> warehouseList = (List<Warehouse>) request.getAttribute("warehouseList");
    String success = request.getParameter("success");
    boolean canAdd  = loggedInUser.hasPermission("WAREHOUSE_ADD");
    boolean canEdit = loggedInUser.hasPermission("WAREHOUSE_EDIT");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quản lý Kho hàng - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Quản lý Kho hàng</h2>
                        <p class="text-muted small mb-0">Danh sách các kho trong hệ thống</p>
                    </div>
                    <% if (canAdd) { %>
                    <a href="<%= request.getContextPath() %>/warehouse/warehouse?action=add" class="btn btn-primary d-inline-flex align-items-center gap-2">
                        <i class="bi bi-plus-circle-fill"></i> Thêm kho mới
                    </a>
                    <% } %>
                </div>

                <% if ("added".equals(success)) { %>
                <div class="alert alert-success border-0 shadow-sm mb-4"><i class="bi bi-check-circle-fill me-2"></i>Thêm kho thành công.</div>
                <% } else if ("updated".equals(success)) { %>
                <div class="alert alert-success border-0 shadow-sm mb-4"><i class="bi bi-check-circle-fill me-2"></i>Cập nhật kho thành công.</div>
                <% } %>

                <div class="card shadow-sm border-0 bg-white">
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0" style="font-size: 0.9rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th class="ps-4">#</th>
                                        <th>Tên kho</th>
                                        <th>Địa chỉ</th>
                                        <th class="text-center">Nhân viên</th>
                                        <th class="text-center">Trạng thái</th>
                                        <th class="text-center">Ngày tạo</th>
                                        <% if (canEdit) { %><th class="text-center">Thao tác</th><% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (warehouseList != null && !warehouseList.isEmpty()) {
                                            dao.WarehouseDAO dao = new dao.WarehouseDAO();
                                            for (Warehouse w : warehouseList) {
                                                int staffCount = dao.countStaff(w.getId());
                                    %>
                                    <tr>
                                        <td class="ps-4 text-muted">#<%= w.getId() %></td>
                                        <td>
                                            <div class="d-flex align-items-center gap-2">
                                                <div class="rounded-circle d-flex align-items-center justify-content-center bg-primary bg-opacity-10 text-primary"
                                                     style="width:36px;height:36px;font-size:1rem;">
                                                    <i class="bi bi-building"></i>
                                                </div>
                                                <span class="fw-semibold text-slate-800"><%= w.getWarehouseName() %></span>
                                                <% if (loggedInUser.getWarehouseId() != null && loggedInUser.getWarehouseId() == w.getId()) { %>
                                                <span class="badge bg-primary bg-opacity-10 text-primary" style="font-size:0.7rem;">Kho của bạn</span>
                                                <% } %>
                                            </div>
                                        </td>
                                        <td class="text-muted"><%= w.getAddress() != null ? w.getAddress() : "-" %></td>
                                        <td class="text-center">
                                            <span class="badge bg-secondary bg-opacity-10 text-secondary"><i class="bi bi-people me-1"></i><%= staffCount %></span>
                                        </td>
                                        <td class="text-center">
                                            <% if (w.isStatus()) { %>
                                            <span class="badge bg-success bg-opacity-10 text-success px-3 py-1">Hoạt động</span>
                                            <% } else { %>
                                            <span class="badge bg-secondary bg-opacity-10 text-secondary px-3 py-1">Ngừng hoạt động</span>
                                            <% } %>
                                        </td>
                                        <td class="text-center text-muted small"><%= w.getCreatedAt() != null ? w.getCreatedAt().toString().substring(0, 10) : "-" %></td>
                                        <% if (canEdit) { %>
                                        <td class="text-center">
                                            <div class="d-flex justify-content-center gap-1">
                                                <a href="<%= request.getContextPath() %>/warehouse/warehouse?action=edit&id=<%= w.getId() %>"
                                                   class="btn btn-sm btn-outline-primary py-1 px-2">
                                                    <i class="bi bi-pencil"></i>
                                                </a>
                                                <form action="<%= request.getContextPath() %>/warehouse/warehouse?action=toggle" method="POST" class="m-0"
                                                      onsubmit="return confirm('<%= w.isStatus() ? "Ngừng hoạt động kho này?" : "Kích hoạt lại kho này?" %>');">
                                                    <input type="hidden" name="id" value="<%= w.getId() %>">
                                                    <button type="submit" class="btn btn-sm <%= w.isStatus() ? "btn-outline-warning" : "btn-outline-success" %> py-1 px-2">
                                                        <i class="bi bi-<%= w.isStatus() ? "pause-circle" : "play-circle" %>"></i>
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                        <% } %>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="7" class="text-center py-5 text-muted">
                                            <i class="bi bi-building d-block mb-2 fs-3 opacity-25"></i>
                                            Chưa có kho nào trong hệ thống.
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
