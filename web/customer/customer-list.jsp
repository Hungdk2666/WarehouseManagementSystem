<%@page import="model.Customer"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("CUSTOMER_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Customer> customerList = (List<Customer>) request.getAttribute("customerList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Danh Sách Khách Hàng - WMS</title>
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
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Danh Sách Khách Hàng</h2>
                        <p class="page-subtitle">Quản lý thông tin khách hàng</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (loggedInUser.hasPermission("CUSTOMER_ADD")) { %>
                        <a href="<%= request.getContextPath() %>/warehouse/customer?action=add" class="btn btn-primary">
                            <i class="bi bi-plus-lg me-1"></i> Thêm Khách Hàng
                        </a>
                        <% } %>
                    </div>
                </div>

                <div class="card">
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0" style="font-size: 0.9rem;">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-center">#</th>
                                        <th>Tên khách hàng</th>
                                        <th>Số điện thoại</th>
                                        <th>Email</th>
                                        <th>Địa chỉ</th>
                                        <th>Mã ngoài</th>
                                        <th class="text-center">Trạng thái</th>
                                        <th class="text-center">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% if (customerList == null || customerList.isEmpty()) { %>
                                    <tr>
                                        <td colspan="8" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Chưa có khách hàng nào.</p>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } else { int idx = 1; for (Customer c : customerList) { %>
                                    <tr>
                                        <td class="text-center text-muted"><%= idx++ %></td>
                                        <td class="fw-semibold"><%= c.getCustomerName() %></td>
                                        <td><%= c.getPhone() != null ? c.getPhone() : "-" %></td>
                                        <td><%= c.getEmail() != null ? c.getEmail() : "-" %></td>
                                        <td><%= c.getAddress() != null ? c.getAddress() : "-" %></td>
                                        <td><%= c.getExternalRef() != null ? c.getExternalRef() : "-" %></td>
                                        <td class="text-center">
                                            <span class="badge bg-<%= c.isStatus() ? "success" : "secondary" %>"><%= c.isStatus() ? "Hoạt động" : "Vô hiệu" %></span>
                                        </td>
                                        <td class="text-center">
                                            <a href="<%= request.getContextPath() %>/warehouse/customer?action=detail&id=<%= c.getId() %>" class="btn btn-table btn-outline-secondary me-1" title="Xem chi tiết"><i class="bi bi-eye"></i></a>
                                            <% if (loggedInUser.hasPermission("CUSTOMER_EDIT")) { %>
                                            <a href="<%= request.getContextPath() %>/warehouse/customer?action=edit&id=<%= c.getId() %>" class="btn btn-table btn-outline-primary me-1" title="Chỉnh sửa"><i class="bi bi-pencil-square"></i></a>
                                            <% } %>
                                            <% if (loggedInUser.hasPermission("CUSTOMER_DELETE")) { %>
                                            <form method="post" action="<%= request.getContextPath() %>/warehouse/customer" style="display:inline" onsubmit="return confirm('<%= c.isStatus() ? "Vô hiệu hóa" : "Kích hoạt" %> khách hàng này?')">
                                                <input type="hidden" name="action" value="toggle">
                                                <input type="hidden" name="id" value="<%= c.getId() %>">
                                                <button type="submit" class="btn btn-table <%= c.isStatus() ? "btn-outline-warning" : "btn-outline-success" %>" title="<%= c.isStatus() ? "Vô hiệu hóa" : "Kích hoạt" %>">
                                                    <i class="bi <%= c.isStatus() ? "bi-toggle-on" : "bi-toggle-off" %>"></i>
                                                </button>
                                            </form>
                                            <% } %>
                                        </td>
                                    </tr>
                                    <% } } %>
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
