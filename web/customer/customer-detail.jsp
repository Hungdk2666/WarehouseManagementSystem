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
                <div class="card form-card-narrow">
                        <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                                <span class="fw-bold text-slate-800"><i class="bi bi-person-fill me-2 text-primary"></i>Chi Tiết Khách Hàng</span>
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
                                <div class="detail-row">
                                    <div class="detail-label">ID</div>
                                    <div class="detail-value"><%= customer.getId() %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Tên khách hàng</div>
                                    <div class="detail-value fw-bold"><%= customer.getCustomerName() %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Số điện thoại</div>
                                    <div class="detail-value"><%= customer.getPhone() != null ? customer.getPhone() : "-" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Email</div>
                                    <div class="detail-value"><%= customer.getEmail() != null ? customer.getEmail() : "-" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Địa chỉ</div>
                                    <div class="detail-value"><%= customer.getAddress() != null ? customer.getAddress() : "-" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Mã đối chiếu ngoài</div>
                                    <div class="detail-value"><%= customer.getExternalRef() != null ? customer.getExternalRef() : "-" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Ngày tạo</div>
                                    <div class="detail-value"><%= customer.getCreatedAt() != null ? customer.getCreatedAt().toString() : "-" %></div>
                                </div>
                            </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
