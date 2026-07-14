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
    boolean hasBeenCounted = s.getCountedAt() != null;
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
                                    <p class="text-muted mb-0">Chưa nộp duyệt</p>
                                <% } else { %>
                                    <dl class="row mb-0 small">
                                        <dt class="col-5">% chênh lệch:</dt>
                                        <dd class="col-7"><strong><%= s.getVariancePercent() %>%</strong>
                                            <% if (cfg != null) { %>
                                                <small class="text-muted">· Ngưỡng <%= cfg.getThresholdPercent() %>%</small>
                                            <% } %>
                                        </dd>
                                        <dt class="col-5">Giá trị chênh:</dt>
                                        <dd class="col-7"><strong><%= s.getVarianceValue() %>đ</strong>
                                            <% if (cfg != null) { %>
                                                <small class="text-muted">· Ngưỡng <%= cfg.getThresholdValue() %>đ</small>
                                            <% } %>
                                        </dd>
                                    </dl>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                
                <% if (s.getL1ApprovedAt() != null || s.getL2ApprovedAt() != null || s.getRejectReason() != null || s.isVerificationCompleted()) { %>
                    <div class="card mb-4">
                        <div class="card-header bg-light">
                            <h6 class="mb-0 fw-bold"><i class="bi bi-clock-history me-2 text-primary"></i>Lịch sử duyệt</h6>
                        </div>
                        <ul class="list-group list-group-flush small">
                            <% if (s.isVerificationCompleted()) { %>
                                <li class="list-group-item">
                                    <i class="bi bi-upc-scan text-warning"></i>
                                    <strong>Xác minh serial:</strong> <%= s.getVerifiedByFullName() %> — <%= s.getVerifiedAt() %>
                                </li>
                            <% } %>
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
                                    <i class="bi bi-hourglass-split"></i> <strong>Chờ Quản trị nghiệp vụ duyệt</strong>
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
                                String diffCls = !hasBeenCounted ? "text-muted" : (diff < 0 ? "text-danger" : (diff > 0 ? "text-warning" : "text-muted"));
                            %>
                                <tr>
                                    <td><%= d.getProductName() %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                    <td class="text-end"><%= d.getTheoreticalQty() %></td>
                                    <td class="text-end"><strong><%= hasBeenCounted ? String.valueOf(d.getActualQty()) : "—" %></strong></td>
                                    <td class="text-end"><%= hasBeenCounted ? String.valueOf(d.getDamagedQty()) : "—" %></td>
                                    <td class="text-end <%= diffCls %>"><strong><%= hasBeenCounted ? (diff > 0 ? "+" + diff : String.valueOf(diff)) : "—" %></strong></td>
                                    <td><%= hasBeenCounted ? d.getVarianceReason() : "—" %></td>
                                    <td><%= d.getNote() == null ? "" : d.getNote() %></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                
                <% if (s.isQuantityMode() && s.isVerificationCompleted() && items != null && !items.isEmpty()) {

                    java.util.List<StocktakeItem> verifyItems = new java.util.ArrayList<>();
                    java.util.Set<Integer> damagedOnlyPids = new java.util.HashSet<>();
                    java.util.Set<Integer> variancePids = new java.util.HashSet<>();
                    if (details != null) {
                        for (StocktakeDetail d : details) {
                            if (d.getVariance() != 0) variancePids.add(d.getProductId());
                            else if (d.getDamagedQty() > 0) damagedOnlyPids.add(d.getProductId());
                        }
                    }
                    for (StocktakeItem it : items) {
                        if ("VERIFY".equals(it.getPhase())) verifyItems.add(it);
                    }
                    if (!verifyItems.isEmpty()) {
                %>
                <div class="card mb-4">
                    <div class="card-header bg-warning bg-opacity-10">
                        <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-upc me-2"></i>Kết quả xác minh serial · <%= verifyItems.size() %>
                            <small class="text-muted fw-normal ms-2">Người xác minh: <%= s.getVerifiedByFullName() %> · <%= s.getVerifiedAt() %></small>
                        </h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="p-3 border-bottom">
                            <div class="row g-2 align-items-end">
                                <div class="col-12 col-md-4">
                                    <label for="verificationSearch" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                    <div class="input-group input-group-sm">
                                        <span class="input-group-text bg-white"><i class="bi bi-search"></i></span>
                                        <input type="search" id="verificationSearch" class="form-control" placeholder="Serial, sản phẩm, SKU, ghi chú...">
                                    </div>
                                </div>
                                <div class="col-6 col-md-2">
                                    <label for="verificationTypeFilter" class="form-label small fw-semibold mb-1">Loại xác minh</label>
                                    <select id="verificationTypeFilter" class="form-select form-select-sm">
                                        <option value="">Tất cả</option>
                                        <option value="VARIANCE">Chênh lệch</option>
                                        <option value="DAMAGED_ONLY">Hỏng</option>
                                    </select>
                                </div>
                                <div class="col-6 col-md-2">
                                    <label for="verificationStatusFilter" class="form-label small fw-semibold mb-1">Tình trạng quét</label>
                                    <select id="verificationStatusFilter" class="form-select form-select-sm">
                                        <option value="">Tất cả</option>
                                        <option value="FOUND">Tìm thấy</option>
                                        <option value="MISSING">Thiếu</option>
                                        <option value="DAMAGED">Hàng hỏng</option>
                                        <option value="EXTRA">Phát hiện thêm</option>
                                    </select>
                                </div>
                                <div class="col-6 col-md-2">
                                    <label for="verificationConditionFilter" class="form-label small fw-semibold mb-1">Tình trạng vật lý</label>
                                    <select id="verificationConditionFilter" class="form-select form-select-sm">
                                        <option value="">Tất cả</option>
                                        <option value="NEW">Mới</option>
                                        <option value="USED">Hàng cũ</option>
                                        <option value="DAMAGED">Lỗi</option>
                                        <option value="NONE">Chưa ghi nhận</option>
                                    </select>
                                </div>
                                <div class="col-6 col-md-2 d-flex gap-2">
                                    <button type="button" id="verificationFilterBtn" class="btn btn-warning btn-sm flex-grow-1">
                                        <i class="bi bi-funnel-fill me-1"></i>Lọc
                                    </button>
                                    <button type="button" id="verificationResetBtn" class="btn btn-outline-secondary btn-sm" title="Đặt lại bộ lọc" aria-label="Đặt lại bộ lọc">
                                        <i class="bi bi-arrow-counterclockwise"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table id="verificationResultTable" class="table table-sm mb-0 align-middle">
                                <thead class="table-light">
                                    <tr><th>Serial</th><th>Sản phẩm</th><th>Loại xác minh</th><th>Tình trạng quét</th><th>Tình trạng vật lý</th><th>Ghi chú</th></tr>
                                </thead>
                                <tbody>
                            <% for (StocktakeItem vit : verifyItems) {
                                String vb = "chip-muted";
                                if ("FOUND".equals(vit.getScannedStatus())) vb = "chip-success";
                                else if ("MISSING".equals(vit.getScannedStatus())) vb = "chip-warning";
                                else if ("DAMAGED".equals(vit.getScannedStatus())) vb = "chip-danger";
                                else if ("EXTRA".equals(vit.getScannedStatus())) vb = "chip-info";

                                String verifyType = "GENERAL";
                                if (damagedOnlyPids.contains(vit.getProductId())) verifyType = "DAMAGED_ONLY";
                                else if (variancePids.contains(vit.getProductId())) verifyType = "VARIANCE";

                                String verificationCondition = vit.getNewCondition() == null ? "NONE" : vit.getNewCondition();
                            %>
                                <tr data-verification-type="<%= verifyType %>" data-scan-status="<%= vit.getScannedStatus() %>" data-physical-condition="<%= verificationCondition %>"<%= "MISSING".equals(vit.getScannedStatus()) ? " class=\"table-warning\"" : "" %>>
                                    <td><strong><%= vit.getSerialNumber() %></strong></td>
                                    <td><%= vit.getProductName() %> <span class="badge bg-secondary bg-opacity-10 text-secondary"><%= vit.getSku() %></span></td>
                                    <td>
                                        <% if (damagedOnlyPids.contains(vit.getProductId())) { %>
                                            <span class="status-chip chip-danger">Hỏng</span>
                                        <% } else if (variancePids.contains(vit.getProductId())) { %>
                                            <span class="status-chip chip-warning">Toàn bộ</span>
                                        <% } else { %>
                                            <span class="status-chip chip-muted">Toàn bộ</span>
                                        <% } %>
                                    </td>
                                    <td><span class="status-chip <%= vb %>"><%
                                        if ("FOUND".equals(vit.getScannedStatus())) out.print("Tìm thấy");
                                        else if ("MISSING".equals(vit.getScannedStatus())) out.print("Thiếu");
                                        else if ("DAMAGED".equals(vit.getScannedStatus())) out.print("Hàng hỏng");
                                        else if ("EXTRA".equals(vit.getScannedStatus())) out.print("Phát hiện thêm");
                                        else out.print(vit.getScannedStatus());
                                    %></span></td>
                                    <td><%
                                        String vcondVn = vit.getNewCondition();
                                        if (vcondVn == null) vcondVn = "—";
                                        else if ("NEW".equals(vcondVn)) vcondVn = "Mới";
                                        else if ("USED".equals(vcondVn)) vcondVn = "Hàng cũ";
                                        else if ("DAMAGED".equals(vcondVn)) vcondVn = "Hàng hỏng";
                                    %><%= vcondVn %></td>
                                    <td><%= vit.getNote() == null ? "" : vit.getNote() %></td>
                                </tr>
                            <% } %>
                                <tr id="verificationNoResults" class="d-none">
                                    <td colspan="6" class="text-center text-muted py-4">Không tìm thấy kết quả xác minh phù hợp.</td>
                                </tr>
                            </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                            <label for="verificationEntriesPerPage" class="text-muted small mb-0 flex-shrink-0">Hiển thị</label>
                            <select id="verificationEntriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;">
                                <option value="10" selected>10</option>
                                <option value="25">25</option>
                                <option value="100">100</option>
                            </select>
                            <span class="text-muted small">dòng</span>
                        </div>
                        <div id="verificationPaginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto"></div>
                    </div>
                </div>
                <% } } %>

                
                <% if (s.isSerialMode() && items != null && !items.isEmpty()) { %>
                <div class="card mb-4">
                    <div class="card-header bg-info bg-opacity-10">
                        <h5 class="mb-0 fw-bold text-info"><i class="bi bi-upc me-2"></i>Chi tiết serial · <%= items.size() %></h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table table-sm mb-0 align-middle">
                            <thead class="table-light">
                                <tr><th>Serial</th><th>Sản phẩm</th><th>Tình trạng quét</th><th>Tình trạng vật lý</th><th>Ghi chú</th></tr>
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
                                        else if ("DAMAGED".equals(it.getScannedStatus())) out.print("Hàng hỏng");
                                        else if ("EXTRA".equals(it.getScannedStatus())) out.print("Phát hiện thêm");
                                        else out.print(it.getScannedStatus());
                                    %></span></td>
                                    <td><%
                                        String condVn = it.getNewCondition();
                                        if (condVn == null) condVn = "—";
                                        else if ("NEW".equals(condVn)) condVn = "Mới";
                                        else if ("USED".equals(condVn)) condVn = "Hàng cũ";
                                        else if ("DAMAGED".equals(condVn)) condVn = "Hàng hỏng";
                                    %><%= condVn %></td>
                                    <td><%= it.getNote() == null ? "" : it.getNote() %></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                <% } %>

                
                <div class="card mb-4">
                    <div class="card-body d-flex flex-wrap gap-2">
                    <% if ((s.isDraft() || s.isCounting() || s.isRejected()) && canCount) { %>
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=count&id=<%= s.getId() %>" class="btn btn-primary">
                            <i class="bi bi-input-cursor-text"></i> <%= s.isDraft() ? "Bắt đầu kiểm" : (s.isRejected() ? "Kiểm lại" : "Tiếp tục kiểm") %>
                        </a>
                        <% if (s.isCounting() && s.isQuantityMode() && s.isVerificationRequired()) { %>
                            <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=verify&id=<%= s.getId() %>" class="btn btn-warning">
                                <i class="bi bi-upc-scan"></i> Xác minh serial
                            </a>
                        <% } %>
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
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            var table = document.getElementById("verificationResultTable");
            if (!table) return;

            var tbody = table.querySelector("tbody");
            var rows = Array.from(tbody.querySelectorAll("tr[data-verification-type]"));
            var noResultsRow = document.getElementById("verificationNoResults");
            var searchInput = document.getElementById("verificationSearch");
            var typeFilter = document.getElementById("verificationTypeFilter");
            var statusFilter = document.getElementById("verificationStatusFilter");
            var conditionFilter = document.getElementById("verificationConditionFilter");
            var entriesSelect = document.getElementById("verificationEntriesPerPage");
            var paginationContainer = document.getElementById("verificationPaginationContainer");
            var currentPage = 1;
            var pageSize = parseInt(entriesSelect.value, 10) || 10;

            function matchingRows() {
                var query = (searchInput.value || "").toLowerCase().trim();
                return rows.filter(function(row) {
                    return (!query || row.textContent.toLowerCase().includes(query))
                        && (!typeFilter.value || row.dataset.verificationType === typeFilter.value)
                        && (!statusFilter.value || row.dataset.scanStatus === statusFilter.value)
                        && (!conditionFilter.value || row.dataset.physicalCondition === conditionFilter.value);
                });
            }

            function createPageButton(label, page, disabled, active, ariaLabel) {
                var item = document.createElement("li");
                item.className = "page-item" + (disabled ? " disabled" : "") + (active ? " active" : "");
                var button = document.createElement("button");
                button.type = "button";
                button.className = "page-link border-0 rounded-2 shadow-none px-2 py-1";
                button.innerHTML = label;
                if (ariaLabel) button.setAttribute("aria-label", ariaLabel);
                button.disabled = disabled;
                button.addEventListener("click", function() {
                    if (!disabled) {
                        currentPage = page;
                        updateTable();
                    }
                });
                item.appendChild(button);
                return item;
            }

            function renderPagination(totalRows, totalPages) {
                paginationContainer.innerHTML = "";
                var firstRow = totalRows === 0 ? 0 : (currentPage - 1) * pageSize + 1;
                var lastRow = Math.min(firstRow + pageSize - 1, totalRows);
                var info = document.createElement("div");
                info.className = "text-muted small my-2 my-sm-0";
                info.textContent = "Hiển thị " + firstRow + " đến " + lastRow + " của " + totalRows + " dòng";
                paginationContainer.appendChild(info);

                if (totalPages <= 1) return;

                var nav = document.createElement("nav");
                nav.setAttribute("aria-label", "Phân trang kết quả xác minh");
                var list = document.createElement("ul");
                list.className = "pagination pagination-sm mb-0 gap-1";
                list.appendChild(createPageButton('<i class="bi bi-chevron-left"></i>', currentPage - 1, currentPage === 1, false, "Trang trước"));

                var startPage = Math.max(1, currentPage - 2);
                var endPage = Math.min(totalPages, startPage + 4);
                if (endPage - startPage < 4) startPage = Math.max(1, endPage - 4);
                for (var page = startPage; page <= endPage; page++) {
                    list.appendChild(createPageButton(String(page), page, false, currentPage === page, "Trang " + page));
                }

                list.appendChild(createPageButton('<i class="bi bi-chevron-right"></i>', currentPage + 1, currentPage === totalPages, false, "Trang sau"));
                nav.appendChild(list);
                paginationContainer.appendChild(nav);
            }

            function updateTable() {
                var filteredRows = matchingRows();
                var totalPages = Math.max(1, Math.ceil(filteredRows.length / pageSize));
                if (currentPage > totalPages) currentPage = totalPages;

                var firstIndex = (currentPage - 1) * pageSize;
                var lastIndex = firstIndex + pageSize;
                rows.forEach(function(row) { row.style.display = "none"; });
                filteredRows.slice(firstIndex, lastIndex).forEach(function(row) { row.style.display = ""; });
                noResultsRow.classList.toggle("d-none", filteredRows.length !== 0);
                renderPagination(filteredRows.length, totalPages);
            }

            function applyFilters() {
                currentPage = 1;
                updateTable();
            }

            searchInput.addEventListener("input", applyFilters);
            [typeFilter, statusFilter, conditionFilter].forEach(function(filter) {
                filter.addEventListener("change", applyFilters);
            });
            document.getElementById("verificationFilterBtn").addEventListener("click", applyFilters);
            document.getElementById("verificationResetBtn").addEventListener("click", function() {
                searchInput.value = "";
                typeFilter.value = "";
                statusFilter.value = "";
                conditionFilter.value = "";
                applyFilters();
            });
            entriesSelect.addEventListener("change", function() {
                pageSize = parseInt(entriesSelect.value, 10) || 10;
                currentPage = 1;
                updateTable();
            });

            updateTable();
        });
    </script>
</body>
</html>
