<%@page import="model.User"%>
<%@page import="model.Warehouse"%>
<%@page import="model.AuditLog"%>
<%@page import="model.Product"%>
<%@page import="model.DailyMovementRow"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.LinkedHashMap"%>
<%@page import="dao.WarehouseDAO"%>
<%@page import="dao.AuditLogDAO"%>
<%@page import="dao.InventoryDAO"%>
<%@page import="dao.ProductDAO"%>
<%@page import="dao.RequestDAO"%>
<%@page import="dao.StocktakeDAO"%>
<%@page import="dao.MovementReportDAO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.text.NumberFormat"%>
<%@page import="java.util.Locale"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !user.hasPermission("DASHBOARD_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    WarehouseDAO whDao = new WarehouseDAO();
    List<Warehouse> activeWarehouses = whDao.getAllActiveWarehouses();


    Map<Integer, int[]> whStatsCache = new LinkedHashMap<>();
    int sysWarehouseCount = 0, sysTotalSKU = 0, sysTotalStock = 0, sysPendingTickets = 0;
    for (Warehouse wh : activeWarehouses) {
        int whStock  = whDao.getTotalStockQty(wh.getId());
        int whSKUs   = whDao.countProductsInStock(wh.getId());
        int whDraft  = whDao.countPendingInTickets(wh.getId()) + whDao.countPendingOutTickets(wh.getId());
        int whTrans  = whDao.countIncomingTransfers(wh.getId());
        int whStaff  = whDao.countStaff(wh.getId());
        whStatsCache.put(wh.getId(), new int[]{ whStock, whSKUs, whDraft, whTrans, whStaff });
        sysWarehouseCount++;
        sysTotalSKU += whSKUs;
        sysTotalStock += whStock;
        sysPendingTickets += whDraft;
    }

    InventoryDAO.InventoryKpi kpi = new InventoryDAO().getKpi(null);
    NumberFormat currencyFmt = NumberFormat.getInstance(new Locale("vi", "VN"));

    List<Product> lowStockTop5 = new ProductDAO().searchAndFilterProducts(null, null, null, true, null);
    if (lowStockTop5.size() > 5) lowStockTop5 = lowStockTop5.subList(0, 5);

    RequestDAO requestDAO = new RequestDAO();
    int pendingRequests = 0;
    for (model.Request r : requestDAO.getAll("IN")) { if ("PENDING".equals(r.getStatus())) pendingRequests++; }
    for (model.Request r : requestDAO.getAll("OUT")) { if ("PENDING".equals(r.getStatus())) pendingRequests++; }

    int pendingStocktakeL2 = new StocktakeDAO().getAll(null, "L1_APPROVED").size();

    AuditLogDAO auditLogDAO = new AuditLogDAO();
    List<AuditLog> recentActivity = auditLogDAO.getLogs("BUSINESS", null, null, null, null, 1, 8);
    SimpleDateFormat activityFmt = new SimpleDateFormat("dd/MM/yyyy HH:mm");


    String today = java.time.LocalDate.now().toString();
    String sevenDaysAgo = java.time.LocalDate.now().minusDays(6).toString();
    Map<String, int[]> dailyTotals = new LinkedHashMap<>();
    for (int i = 6; i >= 0; i--) {
        dailyTotals.put(java.time.LocalDate.now().minusDays(i).toString(), new int[]{0, 0});
    }
    List<DailyMovementRow> movementRows = new MovementReportDAO().getDailyMovement(sevenDaysAgo, today, null, null);
    for (DailyMovementRow row : movementRows) {
        int[] totals = dailyTotals.get(row.getDate());
        if (totals != null) {
            totals[0] += row.getImportQuantity();
            totals[1] += row.getExportQuantity();
        }
    }
    StringBuilder dayLabelsJson = new StringBuilder("[");
    StringBuilder importDataJson = new StringBuilder("[");
    StringBuilder exportDataJson = new StringBuilder("[");
    boolean first = true;
    for (Map.Entry<String, int[]> e : dailyTotals.entrySet()) {
        if (!first) { dayLabelsJson.append(","); importDataJson.append(","); exportDataJson.append(","); }
        dayLabelsJson.append("\"").append(e.getKey().substring(5)).append("\"");
        importDataJson.append(e.getValue()[0]);
        exportDataJson.append(e.getValue()[1]);
        first = false;
    }
    dayLabelsJson.append("]"); importDataJson.append("]"); exportDataJson.append("]");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard Giám đốc - WMS</title>
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
                        <p class="page-subtitle mb-0">Dashboard Giám đốc — toàn cảnh hoạt động kho toàn hệ thống</p>
                    </div>
                </div>

                <h5 class="fw-bold text-slate-800 mb-3"><i class="bi bi-globe2 me-2 text-primary"></i>Tổng quan toàn hệ thống</h5>
                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-building"></i></div>
                        <div><div class="stat-label">Kho đang hoạt động</div><h3 class="stat-value"><%= sysWarehouseCount %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-upc-scan"></i></div>
                        <div><div class="stat-label">Tổng SKU</div><h3 class="stat-value"><%= sysTotalSKU %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-boxes"></i></div>
                        <div><div class="stat-label">Tổng số lượng tồn</div><h3 class="stat-value"><%= sysTotalStock %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-hourglass-split"></i></div>
                        <div><div class="stat-label">Phiếu chờ xử lý</div><h3 class="stat-value"><%= sysPendingTickets %></h3></div>
                    </div></div></div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-cash-stack"></i></div>
                        <div><div class="stat-label">Giá trị tồn kho</div><h3 class="stat-value fs-5"><%= currencyFmt.format(kpi.totalValue) %> đ</h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-danger bg-opacity-10 text-danger"><i class="bi bi-exclamation-triangle-fill"></i></div>
                        <div><div class="stat-label">SKU dưới mức tồn tối thiểu</div><h3 class="stat-value"><%= kpi.lowStockSkus %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-inboxes-fill"></i></div>
                        <div><div class="stat-label">Yêu cầu chờ duyệt</div><h3 class="stat-value"><%= pendingRequests %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-clipboard-check-fill"></i></div>
                        <div><div class="stat-label">Kiểm kê chờ duyệt cấp 2</div><h3 class="stat-value"><%= pendingStocktakeL2 %></h3></div>
                    </div></div></div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-lg-7">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-graph-up me-2 text-primary"></i>Xu hướng nhập - xuất 7 ngày gần nhất</span></div>
                            <div class="card-body" style="height: 300px;"><canvas id="movementChart"></canvas></div>
                        </div>
                    </div>
                    <div class="col-lg-5">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-pie-chart-fill me-2 text-primary"></i>Tỷ lệ tồn kho theo tình trạng</span></div>
                            <div class="card-body d-flex align-items-center justify-content-center" style="height: 300px;"><canvas id="conditionChart"></canvas></div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-12">
                        <div class="card border-0 shadow-sm">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-exclamation-triangle me-2 text-danger"></i>Top 5 sản phẩm tồn thấp nhất</span></div>
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
                </div>

                <h5 class="fw-bold text-slate-800 mb-3"><i class="bi bi-building me-2 text-primary"></i>Tổng quan theo kho</h5>
                <div class="row g-3 mb-4">
                    <% for (Warehouse wh : activeWarehouses) {
                        int[] whStats = whStatsCache.get(wh.getId());
                        int whStock  = whStats[0];
                        int whSKUs   = whStats[1];
                        int whDraft  = whStats[2];
                        int whTrans  = whStats[3];
                        int whStaff  = whStats[4];
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
                                    <div class="col-4"><div class="fw-bold fs-5 text-primary"><%= whSKUs %></div><div class="text-muted" style="font-size:0.72rem;">SKU</div></div>
                                    <div class="col-4"><div class="fw-bold fs-5 text-dark"><%= whStock %></div><div class="text-muted" style="font-size:0.72rem;">Số lượng</div></div>
                                    <div class="col-4"><div class="fw-bold fs-5 <%= whDraft > 0 ? "text-warning" : "text-success" %>"><%= whDraft %></div><div class="text-muted" style="font-size:0.72rem;">NHÁP</div></div>
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

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/inventory" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-clipboard-data"></i></div>
                            <div><div class="stat-label">Số liệu</div><h3 class="stat-value fs-6">Tồn kho</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-arrow-in-down-left"></i></div>
                            <div><div class="stat-label">Đầu vào</div><h3 class="stat-value fs-6">Yêu cầu nhập</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/export-request?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-box-arrow-up-right"></i></div>
                            <div><div class="stat-label">Đầu ra</div><h3 class="stat-value fs-6">Yêu cầu xuất</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-clipboard-check"></i></div>
                            <div><div class="stat-label">Kiểm soát</div><h3 class="stat-value fs-6">Kiểm kê</h3></div></div>
                        </a>
                    </div>
                </div>

                <div class="card mb-4 bg-white">
                    <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-activity me-2 text-primary"></i>Hoạt động gần đây</span></div>
                    <div class="card-body p-0">
                        <% if (recentActivity != null && !recentActivity.isEmpty()) { %>
                        <ul class="list-group list-group-flush">
                            <% for (AuditLog log : recentActivity) { %>
                            <li class="list-group-item d-flex justify-content-between align-items-center px-4 py-2">
                                <span class="small">
                                    <strong><%= log.getUsername() != null ? log.getUsername() : "Hệ thống" %></strong>
                                    <span class="text-muted">— <%= log.getAction() %></span>
                                </span>
                                <span class="text-muted small"><%= activityFmt.format(log.getCreatedAt()) %></span>
                            </li>
                            <% } %>
                        </ul>
                        <% } else { %>
                        <div class="empty-state"><i class="bi bi-inbox"></i><p>Không có hoạt động gần đây để hiển thị.</p></div>
                        <% } %>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        new Chart(document.getElementById('movementChart'), {
            type: 'bar',
            data: {
                labels: <%= dayLabelsJson.toString() %>,
                datasets: [
                    { label: 'Nhập kho', data: <%= importDataJson.toString() %>, backgroundColor: '#22c55e' },
                    { label: 'Xuất kho', data: <%= exportDataJson.toString() %>, backgroundColor: '#ef4444' }
                ]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } }, scales: { y: { beginAtZero: true } } }
        });
        new Chart(document.getElementById('conditionChart'), {
            type: 'doughnut',
            data: {
                labels: ['Hàng mới', 'Hàng cũ', 'Hàng hỏng'],
                datasets: [{ data: [<%= kpi.totalNew %>, <%= kpi.totalUsed %>, <%= kpi.totalQuarantine %>], backgroundColor: ['#22c55e', '#0ea5e9', '#ef4444'] }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
        });
    </script>
</body>
</html>
