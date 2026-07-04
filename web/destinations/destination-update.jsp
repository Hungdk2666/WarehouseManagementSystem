<%@page import="model.InternalDestination"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("DESTINATION_EDIT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    InternalDestination destination = (InternalDestination) request.getAttribute("destination");
    if (destination == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/destination?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chỉnh sửa điểm đến - WMS</title>
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
                <div class="card form-card-narrow">
                     <div class="card-header bg-white py-3">
                        <span class="fw-bold text-slate-800"><i class="bi bi-pencil-square me-2 text-primary"></i>Chỉnh sửa điểm đến</span>
                    </div>
                            <div class="card-body p-4">
                                <form action="destination?action=update" method="POST">
                                    <input type="hidden" name="id" value="<%= destination.getId() %>">
                                    <div class="mb-3">
                                        <label for="destinationName" class="form-label fw-semibold text-muted">Tên điểm đến <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control" id="destinationName" name="destination_name" value="<%= destination.getDestinationName() %>" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="destinationType" class="form-label fw-semibold text-muted">Loại điểm đến <span class="text-danger">*</span></label>
                                        <select class="form-select" id="destinationType" name="destination_type" required>
                                            <option value="STORE" <%= "STORE".equals(destination.getDestinationType()) ? "selected" : "" %>>Cửa hàng</option>
                                            <option value="WARRANTY_CENTER" <%= "WARRANTY_CENTER".equals(destination.getDestinationType()) ? "selected" : "" %>>Trung tâm Bảo hành</option>
                                            <option value="OTHER" <%= "OTHER".equals(destination.getDestinationType()) ? "selected" : "" %>>Khác</option>
                                        </select>
                                    </div>
                                    <div class="mb-4">
                                        <label for="address" class="form-label fw-semibold text-muted">Địa chỉ</label>
                                        <textarea class="form-control" id="address" name="address" rows="2"><%= destination.getAddress() != null ? destination.getAddress() : "" %></textarea>
                                    </div>
                                    <div class="form-actions">
                                        <a href="destination?action=list" class="btn btn-outline-secondary">Hủy</a>
                                        <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Lưu thay đổi</button>
                                    </div>
                                </form>
                            </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
