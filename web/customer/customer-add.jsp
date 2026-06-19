<%@page import="model.Customer"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Customer customer = (Customer) request.getAttribute("customer");
    boolean isEdit = (customer != null);
    if (isEdit && !loggedInUser.hasPermission("CUSTOMER_EDIT")) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN);
        return;
    }
    if (!isEdit && !loggedInUser.hasPermission("CUSTOMER_ADD")) {
        response.sendError(HttpServletResponse.SC_FORBIDDEN);
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= isEdit ? "Chỉnh sửa" : "Thêm" %> Khách Hàng - WMS</title>
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
                        <form method="post" action="<%= request.getContextPath() %>/warehouse/customer">
                            <input type="hidden" name="action" value="<%= isEdit ? "edit" : "add" %>">
                            <% if (isEdit) { %><input type="hidden" name="id" value="<%= customer.getId() %>"><% } %>
                            <div class="card shadow-sm border-0">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                    <h4 class="mb-0 fw-bold text-primary">
                                        <i class="bi bi-person-<%= isEdit ? "gear" : "plus" %>-fill me-2"></i>
                                        <%= isEdit ? "Chỉnh Sửa Khách Hàng" : "Thêm Khách Hàng Mới" %>
                                    </h4>
                                </div>
                                <div class="card-body p-4">
                                    <% if (request.getAttribute("error") != null) { %>
                                    <div class="alert alert-danger mb-3"><i class="bi bi-exclamation-triangle-fill me-2"></i><%= request.getAttribute("error") %></div>
                                    <% } %>

                                    <div class="mb-3">
                                        <label class="form-label fw-semibold small text-muted">Tên khách hàng <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control" name="customer_name" required
                                               value="<%= isEdit && customer.getCustomerName() != null ? customer.getCustomerName() : "" %>">
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold small text-muted">Số điện thoại</label>
                                            <input type="text" class="form-control" name="phone"
                                                   value="<%= isEdit && customer.getPhone() != null ? customer.getPhone() : "" %>">
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold small text-muted">Email</label>
                                            <input type="email" class="form-control" name="email"
                                                   value="<%= isEdit && customer.getEmail() != null ? customer.getEmail() : "" %>">
                                        </div>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label fw-semibold small text-muted">Địa chỉ</label>
                                        <input type="text" class="form-control" name="address"
                                               value="<%= isEdit && customer.getAddress() != null ? customer.getAddress() : "" %>">
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label fw-semibold small text-muted">Mã đối chiếu ngoài (ERP/CRM ref)</label>
                                        <input type="text" class="form-control" name="external_ref"
                                               value="<%= isEdit && customer.getExternalRef() != null ? customer.getExternalRef() : "" %>">
                                    </div>
                                </div>
                                <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                                    <a href="<%= request.getContextPath() %>/warehouse/customer?action=list" class="btn btn-outline-secondary px-4">
                                        <i class="bi bi-x-circle me-1"></i> Hủy
                                    </a>
                                    <button type="submit" class="btn btn-primary px-4">
                                        <i class="bi bi-check-circle-fill me-1"></i> <%= isEdit ? "Cập nhật" : "Lưu" %>
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
