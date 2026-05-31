<%@page import="model.Brand"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("BRAND_EDIT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Brand brand = (Brand) request.getAttribute("brand");
    if (brand == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/brand?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Brand - WMS</title>
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
                                <h4 class="mb-0 fw-bold text-warning-emphasis"><i class="bi bi-pencil-square me-2"></i>Edit Brand</h4>
                            </div>
                            <div class="card-body p-4">
                                <form action="brand?action=update" method="POST">
                                    <input type="hidden" name="id" value="<%= brand.getId() %>">
                                    <div class="mb-3">
                                        <label for="brandName" class="form-label fw-semibold text-muted">Brand Name <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control" id="brandName" name="brand_name" value="<%= brand.getBrandName() %>" required>
                                    </div>
                                    <div class="mb-4">
                                        <label for="description" class="form-label fw-semibold text-muted">Description/Origin</label>
                                        <textarea class="form-control" id="description" name="description" rows="3"><%= brand.getDescription() != null ? brand.getDescription() : "" %></textarea>
                                    </div>
                                    <div class="d-grid mb-3 mt-4">
                                        <button type="submit" class="btn btn-warning text-dark fw-semibold"><i class="bi bi-check-circle-fill me-1"></i> Save Changes</button>
                                    </div>
                                    <div class="text-center">
                                        <a href="brand?action=list" class="btn btn-outline-secondary w-100"><i class="bi bi-x-circle me-1"></i> Cancel</a>
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
