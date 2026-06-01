<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("DESTINATION_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create New Destination - WMS</title>
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
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                <h4 class="mb-0 fw-bold text-primary"><i class="bi bi-plus-circle-fill me-2"></i>Create New Destination</h4>
                            </div>
                            <div class="card-body p-4">
                                <form action="destination?action=add" method="POST">
                                    <div class="mb-3">
                                        <label for="destinationName" class="form-label fw-semibold text-muted">Destination Name <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control" id="destinationName" name="destination_name" placeholder="Enter target name (e.g. Cửa hàng Cầu Giấy)" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="destinationType" class="form-label fw-semibold text-muted">Destination Type <span class="text-danger">*</span></label>
                                        <select class="form-select" id="destinationType" name="destination_type" required>
                                            <option value="STORE" selected>Store (Cửa hàng)</option>
                                            <option value="WARRANTY_CENTER">Warranty Center (Trung tâm Bảo hành)</option>
                                            <option value="OTHER">Other (Khác)</option>
                                        </select>
                                    </div>
                                    <div class="mb-3">
                                        <label for="address" class="form-label fw-semibold text-muted">Address</label>
                                        <textarea class="form-control" id="address" name="address" placeholder="Enter full address..." rows="2"></textarea>
                                    </div>
                                    <div class="mb-4">
                                        <label for="status" class="form-label fw-semibold text-muted">Initial Status</label>
                                        <select class="form-select" id="status" name="status">
                                            <option value="true" selected>Active</option>
                                            <option value="false">Inactive</option>
                                        </select>
                                    </div>
                                    <div class="d-grid mb-3 mt-4">
                                        <button type="submit" class="btn btn-primary fw-semibold"><i class="bi bi-check-circle me-1"></i> Create Destination</button>
                                    </div>
                                    <div class="text-center">
                                        <a href="destination?action=list" class="btn btn-outline-secondary w-100"><i class="bi bi-x-circle me-1"></i> Cancel</a>
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
