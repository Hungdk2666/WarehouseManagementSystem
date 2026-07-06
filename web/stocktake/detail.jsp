<%@page import="model.Stocktake"%>
<%@page import="model.StocktakeDetail"%>
<%@page import="model.StocktakeItem"%>
<%@page import="model.StocktakeConfig"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("STOCKTAKE_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Stocktake s = (Stocktake) request.getAttribute("stocktake");
    StocktakeConfig cfg = (StocktakeConfig) request.getAttribute("config");
    if (s == null) { response.sendRedirect(request.getContextPath() + "/warehouse/stocktake"); return; }

    boolean canCount    = loggedInUser.hasPermission("STOCKTAKE_COUNT");
    boolean canSubmit   = loggedInUser.hasPermission("STOCKTAKE_SUBMIT");
    boolean canApproveL1 = loggedInUser.hasPermission("STOCKTAKE_APPROVE_L1");
    boolean canApproveL2 = loggedInUser.hasPermission("STOCKTAKE_APPROVE_L2");
    boolean canReject   = loggedInUser.hasPermission("STOCKTAKE_REJECT");
    boolean canCancel   = loggedInUser.hasPermission("STOCKTAKE_CREATE");

    String badge = "secondary";
    switch (s.getStatus()) {
        case "DRAFT":       badge = "secondary"; break;
        case "COUNTING":    badge = "info"; break;
        case "SUBMITTED":   badge = "warning"; break;
        case "L1_APPROVED": badge = "primary"; break;
        case "APPROVED":    badge = "success"; break;
        case "REJECTED":    badge = "danger"; break;
        case "ADJUSTED":    badge = "success"; break;
        case "CANCELLED":   badge = "dark"; break;
    }
    List<StocktakeDetail> details = s.getDetails();
    List<StocktakeItem> items = s.getItems();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Phiếu <%= s.getStocktakeCode() %> - WMS</title>
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
                        <h2 class="page-title"><%= s.getStocktakeCode() %>
                            <%
                                String detailStatusVn = s.getStatus();
                                String detailChipCls = "chip-muted";
                                if ("DRAFT".equals(detailStatusVn)) { detailStatusVn = "Bản nháp"; detailChipCls = "chip-muted"; }
                                else if ("COUNTING".equals(detailStatusVn)) { detailStatusVn = "Đang kiểm"; detailChipCls = "chip-info"; }
                                else if ("SUBMITTED".equals(detailStatusVn)) { detailStatusVn = "Chờ duyệt"; detailChipCls = "chip-warning"; }
                                else if ("L1_APPROVED".equals(detailStatusVn)) { detailStatusVn = "Duyệt cấp 1"; detailChipCls = "chip-primary"; }
                                else if ("APPROVED".equals(detailStatusVn)) { detailStatusVn = "Đã duyệt"; detailChipCls = "chip-success"; }
                                else if ("REJECTED".equals(detailStatusVn)) { detailStatusVn = "Từ chối"; detailChipCls = "chip-danger"; }
                                else if ("ADJUSTED".equals(detailStatusVn)) { detailStatusVn = "Đã điều chỉnh"; detailChipCls = "chip-success"; }
                                else if ("CANCELLED".equals(detailStatusVn)) { detailStatusVn = "Đã hủy"; detailChipCls = "chip-muted"; }
                            %>
                            <span class="status-chip <%= detailChipCls %> ms-2" style="vertical-align: middle;"><%= detailStatusVn %></span>
                            <% if (s.isRequiresL2Approval() && !s.isAdjusted() && !s.isCancelled()) { %>
                                <span class="status-chip chip-warning">Cần duyệt 2 cấp</span>
                            <% } %>
                        </h2>
                        <p class="page-subtitle">
                            Kho: <strong><%= s.getWarehouseName() %></strong> ·
                            Phạm vi kiểm kê: <%= s.isFullScope() ? "Toàn kho" : "Một phần" %> ·
                            Hình thức kiểm: <%= s.isSerialMode() ? "Quét mã serial" : "Theo số lượng" %>
                        </p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/stocktake" class="btn btn-outline-secondary btn-sm">
                        <i class="bi bi-arrow-left"></i> Danh sách
                    </a>
                </div>

                <% if (request.getParameter("msg") != null) { %>
                    <div class="alert alert-success alert-dismissible fade show">
                        <i class="bi bi-check-circle"></i> Thao tác thành công.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>
                <% if (request.getParameter("error") != null) { %>
                    <div class="alert alert-danger alert-dismissible fade show">
                        <i class="bi bi-exclamation-circle"></i> Có lỗi: <%= request.getParameter("error") %>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                <!-- Thông tin chung -->
                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-body">
                                <h6 class="text-muted small fw-semibold mb-3">THÔNG TIN PHIẾU</h6>
                                <dl class="row mb-0 small">
                                    <dt class="col-5">Người tạo:</dt><dd class="col-7"><%= s.getCreatedByFullName() %></dd>
                                    <dt class="col-5">Ngày tạo:</dt><dd class="col-7"><%= s.getCreatedAt() %></dd>
                                    <dt class="col-5">Người kiểm:</dt><dd class="col-7"><%= s.getCountedByFullName() == null ? "—" : s.getCountedByFullName() %></dd>
                                    <dt class="col-5">Nộp lúc:</dt><dd class="col-7"><%= s.getSubmittedAt() == null ? "—" : s.getSubmittedAt() %></dd>
                                    <% if (s.getNotes() != null && !s.getNotes().isEmpty()) { %>
                                        <dt class="col-5">Ghi chú:</dt><dd class="col-7"><%= s.getNotes() %></dd>
                                    <% } %>
                                </dl>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-body">
                                <h6 class="text-muted small fw-semibold mb-3">CHÊNH LỆCH</h6>
                                <% if (s.getVariancePercent() == null) { %>
                                    <p class="text-muted mb-0">Chưa có (chưa nộp duyệt)</p>
                                <% } else { %>
                                    <dl class="row mb-0 small">
                                        <dt class="col-5">% chênh lệch:</dt>
                                        <dd class="col-7"><strong><%= s.getVariancePercent() %>%</strong>
                                            <% if (cfg != null) { %>
                                                <small class="text-muted">(ngưỡng <%= cfg.getThresholdPercent() %>%)</small>
                                            <% } %>
                                        </dd>
                                        <dt class="col-5">Giá trị chênh:</dt>
                                        <dd class="col-7"><strong><%= s.getVarianceValue() %>đ</strong>
                                            <% if (cfg != null) { %>
                                                <small class="text-muted">(ngưỡng <%= cfg.getThresholdValue() %>đ)</small>
                                            <% } %>
                                        </dd>
                                    </dl>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Lịch sử duyệt -->
                <% if (s.getL1ApprovedAt() != null || s.getL2ApprovedAt() != null || s.getRejectReason() != null) { %>
                    <div class="card mb-4">
                        <div class="card-header bg-light">
                            <h6 class="mb-0 fw-bold"><i class="bi bi-clock-history me-2 text-primary"></i>Lịch sử duyệt</h6>
                        </div>
                        <ul class="list-group list-group-flush small">
                            <% if (s.getL1ApprovedAt() != null) { %>
                                <li class="list-group-item">
                                    <i class="bi bi-check-circle-fill text-primary"></i>
                                    <strong>Cấp 1:</strong> <%= s.getL1ApprovedByFullName() %> — <%= s.getL1ApprovedAt() %>
                                </li>
                            <% } %>
                            <% if (s.getL2ApprovedAt() != null) { %>
                                <li class="list-group-item">
                                    <i class="bi bi-check-circle-fill text-success"></i>
                                    <strong>Cấp 2:</strong> <%= s.getL2ApprovedByFullName() %> — <%= s.getL2ApprovedAt() %>
                                </li>
                            <% } else if (s.isL1Approved()) { %>
                                <li class="list-group-item text-warning">
                                    <i class="bi bi-hourglass-split"></i> <strong>Chờ cấp 2 duyệt (Business Admin)</strong>
                                </li>
                            <% } %>
                            <% if (s.getRejectReason() != null && !s.getRejectReason().isEmpty()) { %>
                                <li class="list-group-item text-danger">
                                    <i class="bi bi-x-circle-fill"></i> <strong>Đã bị bác bỏ:</strong> <%= s.getRejectReason() %>
                                </li>
                            <% } %>
                            <% if (s.getAdjustedAt() != null) { %>
                                <li class="list-group-item text-success">
                                    <i class="bi bi-database-check"></i> <strong>Đã cập nhật tồn kho lúc:</strong> <%= s.getAdjustedAt() %>
                                </li>
                            <% } %>
                        </ul>
                    </div>
                <% } %>

                <!-- Bảng chi tiết -->
                <div class="card mb-4">
                    <div class="card-header bg-white py-3">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-ul me-2 text-primary"></i>Chi tiết kiểm kê</h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table table-sm mb-0 align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>SKU</th>
                                    <th class="text-end">Lý thuyết</th>
                                    <th class="text-end">Thực tế</th>
                                    <th class="text-end">Lỗi</th>
                                    <th class="text-end">Chênh lệch</th>
                                    <th>Lý do</th>
                                    <th>Ghi chú</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (details != null) for (StocktakeDetail d : details) {
                                int diff = d.getVariance();
                                String diffCls = diff < 0 ? "text-danger" : (diff > 0 ? "text-warning" : "text-muted");
                            %>
                                <tr>
                                    <td><%= d.getProductName() %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                    <td class="text-end"><%= d.getTheoreticalQty() %></td>
                                    <td class="text-end"><strong><%= d.getActualQty() %></strong></td>
                                    <td class="text-end"><%= d.getDamagedQty() %></td>
                                    <td class="text-end <%= diffCls %>"><strong><%= diff > 0 ? "+" + diff : diff %></strong></td>
                                    <td><%= d.getVarianceReason() %></td>
                                    <td><%= d.getNote() == null ? "" : d.getNote() %></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Serial items (nếu SERIAL mode) -->
                <% if (s.isSerialMode() && items != null && !items.isEmpty()) { %>
                <div class="card mb-4">
                    <div class="card-header bg-info bg-opacity-10">
                        <h5 class="mb-0 fw-bold text-info"><i class="bi bi-upc me-2"></i>Chi tiết serial (<%= items.size() %>)</h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table table-sm mb-0 align-middle">
                            <thead class="table-light">
                                <tr><th>Serial</th><th>Sản phẩm</th><th>Tình trạng scan</th><th>Tình trạng vật lý</th><th>Ghi chú</th></tr>
                            </thead>
                            <tbody>
                            <% for (StocktakeItem it : items) {
                                String b = "chip-muted";
                                if ("FOUND".equals(it.getScannedStatus())) b = "chip-success";
                                else if ("MISSING".equals(it.getScannedStatus())) b = "chip-warning";
                                else if ("DAMAGED".equals(it.getScannedStatus())) b = "chip-danger";
                                else if ("EXTRA".equals(it.getScannedStatus())) b = "chip-info";
                            %>
                                <tr>
                                    <td><strong><%= it.getSerialNumber() %></strong></td>
                                    <td><%= it.getProductName() %> <span class="badge bg-secondary bg-opacity-10 text-secondary"><%= it.getSku() %></span></td>
                                    <td><span class="status-chip <%= b %>"><%
                                        if ("FOUND".equals(it.getScannedStatus())) out.print("Tìm thấy");
                                        else if ("MISSING".equals(it.getScannedStatus())) out.print("Thiếu");
                                        else if ("DAMAGED".equals(it.getScannedStatus())) out.print("Hàng lỗi");
                                        else if ("EXTRA".equals(it.getScannedStatus())) out.print("Phát hiện thêm");
                                        else out.print(it.getScannedStatus());
                                    %></span></td>
                                    <td><%
                                        String condVn = it.getNewCondition();
                                        if (condVn == null) condVn = "—";
                                        else if ("NEW".equals(condVn)) condVn = "Mới";
                                        else if ("USED".equals(condVn)) condVn = "Đã dùng";
                                        else if ("DAMAGED".equals(condVn)) condVn = "Lỗi";
                                    %><%= condVn %></td>
                                    <td><%= it.getNote() == null ? "" : it.getNote() %></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <% } %>

                <!-- Action buttons -->
                <div class="card mb-4">
                    <div class="card-body d-flex flex-wrap gap-2">
                    <% if ((s.isDraft() || s.isCounting() || s.isRejected()) && canCount) { %>
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=count&id=<%= s.getId() %>" class="btn btn-primary">
                            <i class="bi bi-input-cursor-text"></i> <%= s.isDraft() ? "Bắt đầu kiểm" : (s.isRejected() ? "Kiểm lại" : "Tiếp tục kiểm") %>
                        </a>
                    <% } %>

                    <% if (s.isSubmitted() && canApproveL1) { %>
                        <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" class="d-inline">
                            <input type="hidden" name="action" value="approveL1">
                            <input type="hidden" name="id" value="<%= s.getId() %>">
                            <button type="submit" class="btn btn-primary" onclick="return confirm('Duyệt cấp 1?');">
                                <i class="bi bi-check2"></i> Duyệt cấp 1
                            </button>
                        </form>
                    <% } %>

                    <% if (s.isL1Approved() && canApproveL2) { %>
                        <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" class="d-inline">
                            <input type="hidden" name="action" value="approveL2">
                            <input type="hidden" name="id" value="<%= s.getId() %>">
                            <button type="submit" class="btn btn-success" onclick="return confirm('Duyệt cấp 2 và cập nhật tồn kho?');">
                                <i class="bi bi-check2-all"></i> Duyệt cấp 2
                            </button>
                        </form>
                    <% } %>

                    <% if ((s.isSubmitted() || s.isL1Approved()) && canReject) { %>
                        <button type="button" class="btn btn-outline-danger" data-bs-toggle="modal" data-bs-target="#rejectModal">
                            <i class="bi bi-x-circle"></i> Bác bỏ
                        </button>
                    <% } %>

                    <% if ((s.isDraft() || s.isCounting() || s.isRejected()) && canCancel) { %>
                        <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" class="d-inline">
                            <input type="hidden" name="action" value="cancel">
                            <input type="hidden" name="id" value="<%= s.getId() %>">
                            <button type="submit" class="btn btn-outline-dark" onclick="return confirm('Hủy phiếu này?');">
                                <i class="bi bi-trash"></i> Hủy phiếu
                            </button>
                        </form>
                    <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Reject modal -->
    <div class="modal fade" id="rejectModal" tabindex="-1">
        <div class="modal-dialog">
            <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" class="modal-content">
                <input type="hidden" name="action" value="reject">
                <input type="hidden" name="id" value="<%= s.getId() %>">
                <div class="modal-header"><h5 class="modal-title">Bác bỏ phiếu</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <label class="form-label fw-semibold">Lý do bác bỏ <span class="text-danger">*</span></label>
                    <textarea name="reject_reason" class="form-control" rows="3" required placeholder="Ví dụ: đếm chưa kỹ, lệch quá lớn so với thực tế..."></textarea>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Hủy</button>
                    <button type="submit" class="btn btn-danger">Bác bỏ</button>
                </div>
            </form>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
