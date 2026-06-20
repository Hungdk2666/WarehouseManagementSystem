<%@page import="model.Category"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("CATEGORY_EDIT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Category category = (Category) request.getAttribute("category");
    if (category == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/category?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chỉnh sửa danh mục - WMS</title>
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
                                <h4 class="mb-0 fw-bold text-warning-emphasis"><i class="bi bi-pencil-square me-2"></i>Chỉnh sửa danh mục</h4>
                            </div>
                            <div class="card-body p-4">
                                <form action="category?action=update" method="POST">
                                    <input type="hidden" name="id" value="<%= category.getId() %>">
                                    <div class="mb-3">
                                        <label for="categoryName" class="form-label fw-semibold text-muted">Tên danh mục <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control" id="categoryName" name="category_name" value="<%= category.getCategoryName() %>" required>
                                    </div>
                                    <div class="mb-4">
                                        <label for="description" class="form-label fw-semibold text-muted">Mô tả</label>
                                        <textarea class="form-control" id="description" name="description" rows="3"><%= category.getDescription() != null ? category.getDescription() : "" %></textarea>
                                    </div>
                                    <div class="d-grid mb-3 mt-4">
                                        <button type="submit" class="btn btn-warning text-dark fw-semibold"><i class="bi bi-check-circle-fill me-1"></i> Lưu thay đổi</button>
                                    </div>
                                    <div class="text-center">
                                        <a href="category?action=list" class="btn btn-outline-secondary w-100"><i class="bi bi-x-circle me-1"></i> Hủy</a>
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
