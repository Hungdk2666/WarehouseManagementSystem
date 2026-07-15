<%@page import="model.User"%>
<%@page import="model.Stocktake"%>
<%@page import="model.DailyMovementRow"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.LinkedHashMap"%>
<%@page import="dao.WarehouseDAO"%>
<%@page import="dao.StocktakeDAO"%>
<%@page import="dao.MovementReportDAO"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !(user.hasPermission("TICKET_CONFIRM_IN") || user.hasPermission("TICKET_CONFIRM_OUT"))) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Integer warehouseId = user.getWarehouseId();

    int pendingImport = 0, pendingExport = 0, incoming = 0;
    Stocktake activeStocktake = null;
    Map<String, int[]> dailyTotals = new LinkedHashMap<>();
    if (warehouseId != null) {
        WarehouseDAO whDao = new WarehouseDAO();
        pendingImport = whDao.countPendingInTickets(warehouseId);
        pendingExport = whDao.countPendingOutTickets(warehouseId);
        incoming      = whDao.countIncomingTransfers(warehouseId);
        activeStocktake = new StocktakeDAO().getActiveStocktakeForWarehouse(warehouseId);

        String today = java.time.LocalDate.now().toString();
        String sevenDaysAgo = java.time.LocalDate.now().minusDays(6).toString();
        for (int i = 6; i >= 0; i--) {
            dailyTotals.put(java.time.LocalDate.now().minusDays(i).toString(), new int[]{0, 0});
        }
        List<DailyMovementRow> movementRows = new MovementReportDAO().getDailyMovement(sevenDaysAgo, today, warehouseId, null);
        for (DailyMovementRow row : movementRows) {
            int[] totals = dailyTotals.get(row.getDate());
            if (totals != null) {
                totals[0] += row.getImportQuantity();
                totals[1] += row.getExportQuantity();
            }
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
    <title>Dashboard Thủ kho - WMS</title>
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
                            Dashboard Thủ kho —
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

                <% if (activeStocktake != null) { %>
                <div class="alert border-0 bg-warning bg-opacity-10 text-dark p-3 rounded-3 mb-4 d-flex align-items-center gap-3">
                    <i class="bi bi-clipboard-check-fill fs-3 text-warning"></i>
                    <div class="flex-grow-1">
                        <strong>Kho đang có phiếu kiểm kê #<%= activeStocktake.getStocktakeCode() %> đang xử lý.</strong>
                        <div class="small text-muted">Nhập/xuất kho sẽ bị tạm khóa cho tới khi kiểm kê hoàn tất.</div>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=detail&id=<%= activeStocktake.getId() %>" class="btn btn-warning btn-sm">Vào đếm ngay</a>
                </div>
                <% } %>

                <div class="row g-3 mb-4">
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath() %>/warehouse/import-ticket?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-4 d-flex align-items-center gap-3">
                                <div class="bg-primary bg-opacity-10 text-primary d-flex align-items-center justify-content-center flex-shrink-0" style="width:52px;height:52px;border-radius:12px;">
                                    <i class="bi bi-box-seam-fill fs-4"></i>
                                </div>
                                <div>
                                    <div class="text-uppercase fw-semibold text-muted mb-1" style="font-size:0.72rem;letter-spacing:0.05em;">Phiếu nhập chờ xử lý</div>
                                    <h3 class="fw-bold text-slate-800 mb-0"><%= pendingImport %></h3>
                                </div>
                            </div>
                        </a>
                    </div>
                    <div class="col-md-4 col-sm-6">
                        <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-4 d-flex align-items-center gap-3">
                                <div class="bg-success bg-opacity-10 text-success d-flex align-items-center justify-content-center flex-shrink-0" style="width:52px;height:52px;border-radius:12px;">
                                    <i class="bi bi-clipboard2-check-fill fs-4"></i>
                                </div>
                                <div>
                                    <div class="text-uppercase fw-semibold text-muted mb-1" style="font-size:0.72rem;letter-spacing:0.05em;">Phiếu xuất chờ xử lý</div>
                                    <h3 class="fw-bold text-slate-800 mb-0"><%= pendingExport %></h3>
                                </div>
                            </div>
                        </a>
                    </div>
                    <div class="col-md-4 col-sm-6">
                        <div class="card h-100">
                            <div class="card-body p-4 d-flex align-items-center gap-3">
                                <div class="bg-warning bg-opacity-10 text-warning d-flex align-items-center justify-content-center flex-shrink-0" style="width:52px;height:52px;border-radius:12px;">
                                    <i class="bi bi-truck fs-4"></i>
                                </div>
                                <div>
                                    <div class="text-uppercase fw-semibold text-muted mb-1" style="font-size:0.72rem;letter-spacing:0.05em;">Hàng đang chuyển đến</div>
                                    <h3 class="fw-bold text-slate-800 mb-0"><%= incoming %></h3>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-12">
                        <div class="card border-0 shadow-sm">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-graph-up me-2 text-primary"></i>Nhịp độ xử lý 7 ngày gần nhất</span></div>
                            <div class="card-body" style="height: 260px;"><canvas id="movementChart"></canvas></div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/import-ticket?action=list" class="btn btn-primary w-100 py-3 d-flex align-items-center justify-content-center gap-2 fs-5">
                            <i class="bi bi-box-arrow-in-down"></i> Tạo phiếu nhập
                        </a>
                    </div>
                    <div class="col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=list" class="btn btn-outline-primary w-100 py-3 d-flex align-items-center justify-content-center gap-2 fs-5">
                            <i class="bi bi-box-arrow-up"></i> Tạo phiếu xuất
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
    </script>
    <% } %>
</body>
</html>
