<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("BRAND_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo thương hiệu mới - WMS</title>
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
                                <span class="fw-bold text-slate-800"><i class="bi bi-plus-circle-fill me-2 text-primary"></i>Tạo thương hiệu mới</span>
                            </div>
                            <div class="card-body p-4">
                                <form action="brand?action=add" method="POST">
                                    <div class="mb-3">
                                        <label for="brandName" class="form-label fw-semibold text-muted">Tên thương hiệu <span class="text-danger">*</span></label>
                                        <input type="text" class="form-control" id="brandName" name="brand_name" placeholder="Nhập tên thương hiệu (ví dụ: Daikin)" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="description" class="form-label fw-semibold text-muted">Mô tả/Xuất xứ</label>
                                        <textarea class="form-control" id="description" name="description" placeholder="Nhập xuất xứ hoặc mô tả..." rows="3"></textarea>
                                    </div>
                                    <div class="mb-4">
                                        <label for="status" class="form-label fw-semibold text-muted">Trạng thái ban đầu</label>
                                        <select class="form-select" id="status" name="status">
                                            <option value="true" selected>Hoạt động</option>
                                            <option value="false">Không hoạt động</option>
                                        </select>
                                    </div>
                                    <div class="form-actions">
                                        <a href="brand?action=list" class="btn btn-outline-secondary">Hủy</a>
                                        <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Tạo thương hiệu</button>
                                    </div>
                                </form>
                            </div>
                        </div>
            </div>
        </div>
    </div>
</body>
</html>
