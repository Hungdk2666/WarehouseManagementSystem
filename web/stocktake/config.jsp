<%@page import="model.StocktakeConfig"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("STOCKTAKE_CONFIG")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    StocktakeConfig cfg = (StocktakeConfig) request.getAttribute("config");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ngưỡng duyệt kiểm kê - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="page-header">
                    <div>
                        <h2 class="page-title">Ngưỡng duyệt 2 cấp</h2>
                        <p class="page-subtitle">Phiếu kiểm kê vượt ngưỡng sẽ cần Giám đốc duyệt thêm cấp 2</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake" class="btn btn-outline-secondary btn-sm">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                    </div>
                </div>

                <% if ("Saved".equals(request.getParameter("msg"))) { %>
                    <div class="alert alert-success alert-dismissible fade show">
                        Đã lưu ngưỡng mới.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST">
                    <input type="hidden" name="action" value="saveConfig">
                    <div class="card form-card">
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Ngưỡng % chênh lệch</label>
                                    <div class="input-group">
                                        <input type="number" step="0.01" min="0" max="100" class="form-control"
                                               name="threshold_percent"
                                               value="<%= cfg == null ? "5.00" : cfg.getThresholdPercent() %>" required>
                                        <span class="input-group-text">%</span>
                                    </div>
                                    <small class="text-muted">Phiếu có % chênh ≥ ngưỡng này → cần duyệt cấp 2</small>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label fw-semibold">Ngưỡng giá trị chênh lệch</label>
                                    <div class="input-group">
                                        <input type="number" step="1000" min="0" class="form-control"
                                               name="threshold_value"
                                               value="<%= cfg == null ? "10000000" : cfg.getThresholdValue() %>" required>
                                        <span class="input-group-text">đ</span>
                                    </div>
                                    <small class="text-muted">Phiếu có giá trị chênh ≥ ngưỡng này → cần duyệt cấp 2</small>
                                </div>
                                <% if (cfg != null && cfg.getUpdatedAt() != null) { %>
                                    <div class="col-12">
                                        <small class="text-muted">Cập nhật lần cuối: <%= cfg.getUpdatedAt() %></small>
                                    </div>
                                <% } %>
                            </div>
                            <div class="form-actions">
                                <a href="<%= request.getContextPath() %>/warehouse/stocktake" class="btn btn-outline-secondary">Hủy</a>
                                <button type="submit" class="btn btn-primary">
                                    <i class="bi bi-check-lg me-1"></i>Lưu ngưỡng
                                </button>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
