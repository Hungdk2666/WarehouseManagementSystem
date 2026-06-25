<%@page import="model.User"%>
<%@page import="model.Warehouse"%>
<%@page import="java.util.List"%>
<%@page import="dao.WarehouseDAO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
    // Per-warehouse stats (only for non-sysadmin users)
    WarehouseDAO whDao = new WarehouseDAO();
    List<Warehouse> activeWarehouses = null;
    int myTotalStock = 0, myProducts = 0, myPendingImport = 0, myPendingExport = 0, myIncoming = 0;
    boolean showWarehouseStats = !user.hasPermission("USER_VIEW") && !user.hasPermission("ROLE_VIEW");
    if (showWarehouseStats) {
        if (user.getWarehouseId() != null) {
            int wid = user.getWarehouseId();
            myTotalStock   = whDao.getTotalStockQty(wid);
            myProducts     = whDao.countProductsInStock(wid);
            myPendingImport = whDao.countPendingInTickets(wid);
            myPendingExport = whDao.countPendingOutTickets(wid);
            myIncoming     = whDao.countIncomingTransfers(wid);
        } else {
            // Global admin/manager — show all warehouses
            activeWarehouses = whDao.getAllActiveWarehouses();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bảng điều khiển - WMS</title>
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
            <!-- Left Sidebar -->
            <jsp:include page="/includes/sidebar.jsp" />

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Chào mừng, <%= user.getFullName() %>!</h2>
                        <p class="text-muted small mb-0">
                            <span class="badge bg-primary bg-opacity-10 text-primary px-3 py-1.5 fs-7">
                                <i class="bi bi-shield-check me-1"></i> Vai trò: <%= user.getRoleName() != null ? user.getRoleName() : ((user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) ? "Quản trị" : "Nhân viên") %>
                            </span>
                            <span class="badge bg-success bg-opacity-10 text-success px-3 py-1.5 fs-7 ms-2">
                                <i class="bi bi-circle-fill me-1" style="font-size: 0.5rem; vertical-align: middle;"></i> Trạng thái: <%= user.isStatus() ? "Hoạt động" : "Ngừng hoạt động" %>
                            </span>
                        </p>
                    </div>
                </div>
                <hr class="text-muted opacity-25">
                
                <div class="row mt-4">
                    <div class="col-12">
                        <% if (user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) { %>
                        <div class="alert alert-info shadow-sm border-0 bg-info bg-opacity-10 text-dark p-4 rounded-3">
                            <h5 class="alert-heading fw-bold text-info-emphasis d-flex align-items-center gap-2 mb-2">
                                <i class="bi bi-shield-lock-fill fs-4"></i> Hạn chế truy cập
                            </h5>
                            <p class="mb-0 text-muted">Bạn đang đăng nhập dưới quyền <strong>Quản trị hệ thống</strong>. Theo chính sách phân chia nhiệm vụ (SoD), bạn không có quyền xem dữ liệu kinh doanh hoặc báo cáo tài chính.</p>
                        </div>
                        <% } else { %>
                        
                        <%-- Stats cards: show warehouse-scoped data if user has a warehouse --%>
                        <% if (user.getWarehouseId() != null) { %>
                        <%-- Warehouse-specific stats --%>
                        <div class="alert alert-primary border-0 shadow-sm py-2 px-3 mb-3 d-inline-flex align-items-center gap-2">
                            <i class="bi bi-building-fill"></i>
                            <span class="small fw-semibold">Kho của bạn: <%= user.getWarehouseName() != null ? user.getWarehouseName() : "Kho #" + user.getWarehouseId() %></span>
                        </div>
                        <div class="row g-3 mb-4">
                            <div class="col-md-4 col-sm-6">
                                <div class="card h-100 border-0 shadow-sm" style="background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);">
                                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                                        <div>
                                            <h6 class="text-uppercase fw-bold text-primary-emphasis small mb-1" style="letter-spacing: 0.05em;">SKU trong kho</h6>
                                            <h2 class="fw-bold text-primary mb-0"><%= myProducts %></h2>
                                            <small class="text-muted">Tổng cộng <%= myTotalStock %> sản phẩm</small>
                                        </div>
                                        <div class="bg-primary bg-opacity-10 text-primary rounded-circle p-3 d-flex align-items-center justify-content-center" style="width:56px;height:56px;">
                                            <i class="bi bi-box-seam-fill fs-3"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 col-sm-6">
                                <div class="card h-100 border-0 shadow-sm" style="background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);">
                                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                                        <div>
                                            <h6 class="text-uppercase fw-bold text-success-emphasis small mb-1" style="letter-spacing: 0.05em;">Phiếu chờ xử lý</h6>
                                            <h2 class="fw-bold text-success mb-0"><%= myPendingImport + myPendingExport %></h2>
                                            <small class="text-muted"><%= myPendingImport %> nhập · <%= myPendingExport %> xuất</small>
                                        </div>
                                        <div class="bg-success bg-opacity-10 text-success rounded-circle p-3 d-flex align-items-center justify-content-center" style="width:56px;height:56px;">
                                            <i class="bi bi-clipboard2-check-fill fs-3"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 col-sm-6">
                                <div class="card h-100 border-0 shadow-sm" style="background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);">
                                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                                        <div>
                                            <h6 class="text-uppercase fw-bold text-warning-emphasis small mb-1" style="letter-spacing: 0.05em;">Hàng đang chuyển đến</h6>
                                            <h2 class="fw-bold text-warning mb-0"><%= myIncoming %></h2>
                                            <small class="text-muted">yêu cầu chuyển kho đang vận chuyển</small>
                                        </div>
                                        <div class="bg-warning bg-opacity-10 text-warning rounded-circle p-3 d-flex align-items-center justify-content-center" style="width:56px;height:56px;">
                                            <i class="bi bi-truck fs-3"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        <% } else if (activeWarehouses != null && !activeWarehouses.isEmpty()) { %>
                        <%-- Global manager/BA: show per-warehouse overview grid --%>
                        <h5 class="fw-bold text-slate-800 mb-3"><i class="bi bi-building me-2 text-primary"></i>Tổng quan theo kho</h5>
                        <div class="row g-3 mb-4">
                            <%
                                for (Warehouse wh : activeWarehouses) {
                                    int whStock  = whDao.getTotalStockQty(wh.getId());
                                    int whSKUs   = whDao.countProductsInStock(wh.getId());
                                    int whDraft  = whDao.countPendingInTickets(wh.getId()) + whDao.countPendingOutTickets(wh.getId());
                                    int whTrans  = whDao.countIncomingTransfers(wh.getId());
                                    int whStaff  = whDao.countStaff(wh.getId());
                            %>
                            <div class="col-xl-4 col-md-6">
                                <div class="card border-0 shadow-sm h-100">
                                    <div class="card-header border-0 bg-primary bg-opacity-10 py-2 px-3 d-flex align-items-center gap-2">
                                        <i class="bi bi-building-fill text-primary"></i>
                                        <span class="fw-semibold text-primary"><%= wh.getWarehouseName() %></span>
                                        <span class="ms-auto badge bg-secondary bg-opacity-10 text-secondary small"><%= whStaff %> NV</span>
                                    </div>
                                    <div class="card-body p-3">
                                        <div class="row g-2 text-center">
                                            <div class="col-4">
                                                <div class="fw-bold fs-5 text-primary"><%= whSKUs %></div>
                                                <div class="text-muted" style="font-size:0.72rem;">SKU</div>
                                            </div>
                                            <div class="col-4">
                                                <div class="fw-bold fs-5 text-dark"><%= whStock %></div>
                                                <div class="text-muted" style="font-size:0.72rem;">Số lượng</div>
                                            </div>
                                            <div class="col-4">
                                                <div class="fw-bold fs-5 <%= whDraft > 0 ? "text-warning" : "text-success" %>"><%= whDraft %></div>
                                                <div class="text-muted" style="font-size:0.72rem;">NHÁP</div>
                                            </div>
                                        </div>
                                        <% if (whTrans > 0) { %>
                                        <div class="mt-2 px-2 py-1 rounded bg-warning bg-opacity-10 text-warning small d-flex align-items-center gap-1">
                                            <i class="bi bi-truck"></i> <%= whTrans %> phiếu chuyển kho đến
                                        </div>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                            <% } %>
                        </div>
                        <% } %>
                        
                    </div>
                    <div class="col-12">
                        <div class="card shadow-sm border-0 mb-4 bg-white">
                            <div class="card-header bg-transparent py-3 border-0">
                                <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-activity me-2 text-primary"></i>Hoạt động gần đây</h5>
                            </div>
                            <div class="card-body p-4">
                                <div class="text-center py-5">
                                    <i class="bi bi-inbox text-muted display-4 d-block mb-3"></i>
                                    <p class="text-muted mb-0">Không có hoạt động gần đây để hiển thị.</p>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
