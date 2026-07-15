<%@page import="model.User"%>
<%@page import="model.Product"%>
<%@page import="java.util.List"%>
<%@page import="dao.WarehouseDAO"%>
<%@page import="dao.InventoryDAO"%>
<%@page import="dao.ProductDAO"%>
<%@page import="dao.StocktakeDAO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !(user.hasPermission("STOCKTAKE_APPROVE_L1") || user.hasPermission("WAREHOUSE_EDIT"))) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Integer warehouseId = user.getWarehouseId();

    InventoryDAO.InventoryKpi kpi = null;
    List<Product> lowStockTop5 = java.util.Collections.emptyList();
    int pendingStocktakeL1 = 0, pendingInTickets = 0, pendingOutTickets = 0, incomingTransfers = 0;
    if (warehouseId != null) {
        kpi = new InventoryDAO().getKpi(warehouseId);
        lowStockTop5 = new ProductDAO().searchAndFilterProducts(null, null, null, true, warehouseId);
        if (lowStockTop5.size() > 5) lowStockTop5 = lowStockTop5.subList(0, 5);
        pendingStocktakeL1 = new StocktakeDAO().getAll(warehouseId, "SUBMITTED").size();
        WarehouseDAO whDao = new WarehouseDAO();
        pendingInTickets = whDao.countPendingInTickets(warehouseId);
        pendingOutTickets = whDao.countPendingOutTickets(warehouseId);
        incomingTransfers = whDao.countIncomingTransfers(warehouseId);
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard Quản lý kho - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="page-header">
                    <div>
                        <h1 class="page-title">Chào mừng, <%= user.getFullName() %>!</h1>
                        <p class="page-subtitle mb-0">
                            Dashboard Quản lý kho —
                            <% if (warehouseId != null) { %>
                                <strong><%= user.getWarehouseName() != null ? user.getWarehouseName() : "Kho #" + warehouseId %></strong>
                            <% } else { %>
                                chưa được gán kho
                            <% } %>
                        </p>
                    </div>
                </div>

                <% if (warehouseId == null) { %>
                <div class="empty-state"><i class="bi bi-building-fill-exclamation"></i><p>Tài khoản của bạn chưa được gán vào kho nào. Liên hệ Quản trị hệ thống để được gán kho.</p></div>
                <% } else { %>

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-upc-scan"></i></div>
                        <div><div class="stat-label">Tổng SKU</div><h3 class="stat-value"><%= kpi.totalSkus %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-seam-fill"></i></div>
                        <div><div class="stat-label">SKU đang có hàng</div><h3 class="stat-value"><%= kpi.skusInStock %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-danger bg-opacity-10 text-danger"><i class="bi bi-exclamation-triangle-fill"></i></div>
                        <div><div class="stat-label">SKU dưới tồn tối thiểu</div><h3 class="stat-value"><%= kpi.lowStockSkus %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-boxes"></i></div>
                        <div><div class="stat-label">Tổng số lượng tồn</div><h3 class="stat-value"><%= kpi.totalOnHand %></h3></div>
                    </div></div></div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-4 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-clipboard-check-fill"></i></div>
                        <div><div class="stat-label">Kiểm kê chờ duyệt cấp 1</div><h3 class="stat-value"><%= pendingStocktakeL1 %></h3></div>
                    </div></div></div>
                    <div class="col-xl-4 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-clipboard2-check-fill"></i></div>
                        <div><div class="stat-label">Phiếu chờ xử lý</div><h3 class="stat-value"><%= pendingInTickets + pendingOutTickets %></h3><small class="text-muted"><%= pendingInTickets %> nhập · <%= pendingOutTickets %> xuất</small></div>
                    </div></div></div>
                    <div class="col-xl-4 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-truck"></i></div>
                        <div><div class="stat-label">Hàng đang chuyển đến</div><h3 class="stat-value"><%= incomingTransfers %></h3></div>
                    </div></div></div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-lg-7">
                        <div class="card border-0 shadow-sm">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-exclamation-triangle me-2 text-danger"></i>Top 5 sản phẩm tồn thấp tại kho</span></div>
                            <div class="card-body p-0">
                                <% if (!lowStockTop5.isEmpty()) { %>
                                <div class="table-responsive">
                                    <table class="table align-middle mb-0">
                                        <thead class="table-light"><tr><th class="ps-3">SKU</th><th>Tên sản phẩm</th><th>Đơn vị</th><th class="text-end">Đang tồn</th><th class="text-end">Tồn tối thiểu</th></tr></thead>
                                        <tbody>
                                        <% for (Product p : lowStockTop5) { %>
                                        <tr>
                                            <td class="ps-3 font-monospace small"><%= p.getSku() %></td>
                                            <td class="fw-semibold small"><%= p.getProductName() %></td>
                                            <td class="small text-muted"><%= p.getUnit() %></td>
                                            <td class="text-end text-danger fw-bold"><%= p.getQuantity() %></td>
                                            <td class="text-end text-muted"><%= p.getMinStock() %></td>
                                        </tr>
                                        <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                <% } else { %>
                                <div class="empty-state"><i class="bi bi-check-circle"></i><p>Không có sản phẩm nào dưới mức tồn tối thiểu.</p></div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-5">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-pie-chart-fill me-2 text-primary"></i>Tỷ lệ tồn kho theo tình trạng</span></div>
                            <div class="card-body d-flex align-items-center justify-content-center" style="height: 280px;"><canvas id="conditionChart"></canvas></div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-clipboard-check"></i></div>
                            <div><div class="stat-label">Kiểm soát</div><h3 class="stat-value fs-6">Kiểm kê</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/inventory" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-clipboard-data"></i></div>
                            <div><div class="stat-label">Số liệu</div><h3 class="stat-value fs-6">Tồn kho</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/product?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-seam"></i></div>
                            <div><div class="stat-label">Danh mục</div><h3 class="stat-value fs-6">Sản phẩm</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/supplier?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-truck"></i></div>
                            <div><div class="stat-label">Danh mục</div><h3 class="stat-value fs-6">Nhà cung cấp</h3></div></div>
                        </a>
                    </div>
                </div>

                <% } %>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <% if (warehouseId != null) { %>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        new Chart(document.getElementById('conditionChart'), {
            type: 'doughnut',
            data: {
                labels: ['Hàng mới', 'Hàng cũ', 'Hàng hỏng'],
                datasets: [{ data: [<%= kpi.totalNew %>, <%= kpi.totalUsed %>, <%= kpi.totalQuarantine %>], backgroundColor: ['#22c55e', '#0ea5e9', '#ef4444'] }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
        });
    </script>
    <% } %>
</body>
</html>
