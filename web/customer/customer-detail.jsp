<%@page import="model.Customer"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("CUSTOMER_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Customer customer = (Customer) request.getAttribute("customer");
    if (customer == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/customer?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi Tiết Khách Hàng - WMS</title>
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
                <div class="row justify-content-center">
                    <div class="col-md-8">
                        <div class="card shadow-sm border-0">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                                <h4 class="mb-0 fw-bold text-primary"><i class="bi bi-person-fill me-2"></i>Chi Tiết Khách Hàng</h4>
                                <div class="d-flex gap-2">
                                    <% if (loggedInUser.hasPermission("CUSTOMER_EDIT")) { %>
                                    <a href="<%= request.getContextPath() %>/warehouse/customer?action=edit&id=<%= customer.getId() %>" class="btn btn-sm btn-outline-secondary">
                                        <i class="bi bi-pencil me-1"></i> Chỉnh sửa
                                    </a>
                                    <% } %>
                                    <a href="<%= request.getContextPath() %>/warehouse/customer?action=list" class="btn btn-sm btn-outline-primary">
                                        <i class="bi bi-arrow-left me-1"></i> Danh sách
                                    </a>
                                </div>
                            </div>
                            <div class="card-body p-4">
                                <table class="table table-borderless" style="font-size: 0.95rem;">
                                    <tbody>
                                        <tr>
                                            <td class="fw-semibold text-muted" style="width: 35%;">ID</td>
                                            <td><%= customer.getId() %></td>
                                        </tr>
                                        <tr>
                                            <td class="fw-semibold text-muted">Tên khách hàng</td>
                                            <td class="fw-bold"><%= customer.getCustomerName() %></td>
                                        </tr>
                                        <tr>
                                            <td class="fw-semibold text-muted">Số điện thoại</td>
                                            <td><%= customer.getPhone() != null ? customer.getPhone() : "-" %></td>
                                        </tr>
                                        <tr>
                                            <td class="fw-semibold text-muted">Email</td>
                                            <td><%= customer.getEmail() != null ? customer.getEmail() : "-" %></td>
                                        </tr>
                                        <tr>
                                            <td class="fw-semibold text-muted">Địa chỉ</td>
                                            <td><%= customer.getAddress() != null ? customer.getAddress() : "-" %></td>
                                        </tr>
                                        <tr>
                                            <td class="fw-semibold text-muted">Mã đối chiếu ngoài</td>
                                            <td><%= customer.getExternalRef() != null ? customer.getExternalRef() : "-" %></td>
                                        </tr>
                                        <tr>
                                            <td class="fw-semibold text-muted">Ngày tạo</td>
                                            <td><%= customer.getCreatedAt() != null ? customer.getCreatedAt().toString() : "-" %></td>
                                        </tr>
                                    </tbody>
                                </table>
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
