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
                <div class="page-header">
                    <div>
                        <h1 class="page-title">Chào mừng, <%= user.getFullName() %>!</h1>
                        <div class="d-flex align-items-center gap-2">
                            <span class="badge bg-primary bg-opacity-10 text-primary px-3 py-2" style="font-weight: 600;">
                                <i class="bi bi-shield-check me-1"></i> <%= user.getRoleName() != null ? user.getRoleName() : ((user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) ? "Quản trị" : "Nhân viên") %>
                            </span>
                            <span class="badge bg-success bg-opacity-10 text-success px-3 py-2" style="font-weight: 600;">
                                <i class="bi bi-circle-fill me-1" style="font-size: 0.45rem; vertical-align: middle;"></i> <%= user.isStatus() ? "Hoạt động" : "Ngừng hoạt động" %>
                            </span>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    <div class="col-12">
                        <% if (user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) { %>
                        <div class="alert alert-info border-0 bg-info bg-opacity-10 text-dark p-4 rounded-3">
                            <h5 class="alert-heading fw-bold text-info-emphasis d-flex align-items-center gap-2 mb-2">
                                <i class="bi bi-shield-lock-fill fs-4"></i> Hạn chế truy cập
                            </h5>
                            <p class="mb-0 text-muted">Bạn đang đăng nhập dưới quyền <strong>Quản trị hệ thống</strong>. Theo chính sách phân chia nhiệm vụ (SoD), bạn không có quyền xem dữ liệu kinh doanh hoặc báo cáo tài chính.</p>
                        </div>
                        <% } else { %>
                        
                        <%-- Stats cards: show warehouse-scoped data if user has a warehouse --%>
                        <% if (user.getWarehouseId() != null) { %>
                        <%-- Warehouse-specific stats --%>
                        <div class="d-inline-flex align-items-center gap-2 mb-3 px-3 py-2 rounded-3 bg-white border" style="box-shadow: var(--card-shadow);">
                            <i class="bi bi-building-fill text-primary"></i>
                            <span class="small fw-semibold text-slate-800">Kho của bạn: <%= user.getWarehouseName() != null ? user.getWarehouseName() : "Kho #" + user.getWarehouseId() %></span>
                        </div>
                        <div class="row g-3 mb-4">
                            <div class="col-md-4 col-sm-6">
                                <div class="card h-100">
                                    <div class="card-body p-4 d-flex align-items-center gap-3">
                                        <div class="bg-primary bg-opacity-10 text-primary d-flex align-items-center justify-content-center flex-shrink-0" style="width:52px;height:52px;border-radius:12px;">
                                            <i class="bi bi-box-seam-fill fs-4"></i>
                                        </div>
                                        <div>
                                            <div class="text-uppercase fw-semibold text-muted mb-1" style="font-size:0.72rem;letter-spacing:0.05em;">SKU trong kho</div>
                                            <h3 class="fw-bold text-slate-800 mb-0"><%= myProducts %></h3>
                                            <small class="text-muted">Tổng cộng <%= myTotalStock %> sản phẩm</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 col-sm-6">
                                <div class="card h-100">
                                    <div class="card-body p-4 d-flex align-items-center gap-3">
                                        <div class="bg-success bg-opacity-10 text-success d-flex align-items-center justify-content-center flex-shrink-0" style="width:52px;height:52px;border-radius:12px;">
                                            <i class="bi bi-clipboard2-check-fill fs-4"></i>
                                        </div>
                                        <div>
                                            <div class="text-uppercase fw-semibold text-muted mb-1" style="font-size:0.72rem;letter-spacing:0.05em;">Phiếu chờ xử lý</div>
                                            <h3 class="fw-bold text-slate-800 mb-0"><%= myPendingImport + myPendingExport %></h3>
                                            <small class="text-muted"><%= myPendingImport %> nhập · <%= myPendingExport %> xuất</small>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <div class="col-md-4 col-sm-6">
                                <div class="card h-100">
                                    <div class="card-body p-4 d-flex align-items-center gap-3">
                                        <div class="bg-warning bg-opacity-10 text-warning d-flex align-items-center justify-content-center flex-shrink-0" style="width:52px;height:52px;border-radius:12px;">
                                            <i class="bi bi-truck fs-4"></i>
                                        </div>
                                        <div>
                                            <div class="text-uppercase fw-semibold text-muted mb-1" style="font-size:0.72rem;letter-spacing:0.05em;">Hàng đang chuyển đến</div>
                                            <h3 class="fw-bold text-slate-800 mb-0"><%= myIncoming %></h3>
                                            <small class="text-muted">yêu cầu chuyển kho đang vận chuyển</small>
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
                                    <div class="card-header border-0 bg-light py-2 px-3 d-flex align-items-center gap-2">
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
                        
                        <div class="row g-3 mb-4">
                            <% if (user.hasPermission("INVENTORY_VIEW")) { %>
                            <div class="col-xl-3 col-md-6">
                                <a href="<%= request.getContextPath() %>/warehouse/inventory" class="card h-100 text-decoration-none">
                                    <div class="card-body p-3 stat-tile">
                                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-clipboard-data"></i></div>
                                        <div>
                                            <div class="stat-label">Inventory</div>
                                            <h3 class="stat-value fs-6">Tồn kho</h3>
                                            <small class="text-muted">Kiểm tra số liệu hiện tại</small>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                            <% if (user.hasPermission("REQUEST_VIEW_IN")) { %>
                            <div class="col-xl-3 col-md-6">
                                <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="card h-100 text-decoration-none">
                                    <div class="card-body p-3 stat-tile">
                                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-arrow-in-down-left"></i></div>
                                        <div>
                                            <div class="stat-label">Inbound</div>
                                            <h3 class="stat-value fs-6">Nhập kho</h3>
                                            <small class="text-muted">Xử lý yêu cầu nhập</small>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                            <% if (user.hasPermission("REQUEST_VIEW_OUT")) { %>
                            <div class="col-xl-3 col-md-6">
                                <a href="<%= request.getContextPath() %>/warehouse/export-request?action=list" class="card h-100 text-decoration-none">
                                    <div class="card-body p-3 stat-tile">
                                        <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-box-arrow-up-right"></i></div>
                                        <div>
                                            <div class="stat-label">Outbound</div>
                                            <h3 class="stat-value fs-6">Xuất kho</h3>
                                            <small class="text-muted">Theo dõi yêu cầu xuất</small>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                            <% if (user.hasPermission("STOCKTAKE_VIEW")) { %>
                            <div class="col-xl-3 col-md-6">
                                <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=list" class="card h-100 text-decoration-none">
                                    <div class="card-body p-3 stat-tile">
                                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-clipboard-check"></i></div>
                                        <div>
                                            <div class="stat-label">Control</div>
                                            <h3 class="stat-value fs-6">Kiểm kê</h3>
                                            <small class="text-muted">Quản lý phiếu kiểm kê</small>
                                        </div>
                                    </div>
                                </a>
                            </div>
                            <% } %>
                        </div>
                    </div>
                    <div class="col-12">
                        <div class="card mb-4 bg-white">
                            <div class="card-header bg-white py-3">
                                <span class="fw-bold text-slate-800"><i class="bi bi-activity me-2 text-primary"></i>Hoạt động gần đây</span>
                            </div>
                            <div class="card-body p-0">
                                <div class="empty-state">
                                    <i class="bi bi-inbox"></i>
                                    <p>Không có hoạt động gần đây để hiển thị.</p>
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


