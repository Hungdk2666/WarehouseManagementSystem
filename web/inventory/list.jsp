<%@page import="model.InventoryRow"%>
<%@page import="model.InventoryGroupedRow"%>
<%@page import="model.Warehouse"%>
<%@page import="dao.InventoryDAO.InventoryKpi"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("INVENTORY_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Integer filterWh = (Integer) request.getAttribute("filterWarehouseId");
    List<InventoryRow> rows = (List<InventoryRow>) request.getAttribute("rows");
    List<InventoryGroupedRow> groupedRows = (List<InventoryGroupedRow>) request.getAttribute("groupedRows");
    boolean isGroupedView = (filterWh == null && groupedRows != null);
    InventoryKpi kpi = (InventoryKpi) request.getAttribute("kpi");
    List<Warehouse> warehouseList = (List<Warehouse>) request.getAttribute("warehouseList");
    String filterKw = (String) request.getAttribute("filterKeyword");
    boolean filterLow = Boolean.TRUE.equals(request.getAttribute("filterLow"));
    boolean filterDmg = Boolean.TRUE.equals(request.getAttribute("filterDamaged"));
    boolean bound = Boolean.TRUE.equals(request.getAttribute("userBoundToWarehouse"));
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tồn kho - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=inventory-layout-20260714">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="page-header">
                    <div>
                        <h2 class="page-title">Tồn kho</h2>
                        <p class="page-subtitle">Số lượng hàng hiện có theo từng kho. Không phải danh mục sản phẩm.</p>
                    </div>
                </div>

                
                <% if (kpi != null) { %>
                <div class="row g-3 mb-3">
                    <div class="col-xl-3 col-sm-6">
                        <div class="card h-100 border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-boxes"></i></div>
                            <div><div class="stat-label">Tổng hàng trong kho</div><h3 class="stat-value"><%= kpi.totalOnHand %></h3></div>
                        </div></div>
                    </div>
                    <div class="col-xl-3 col-sm-6">
                        <div class="card h-100 border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-seam"></i></div>
                            <div><div class="stat-label">Hàng mới</div><h3 class="stat-value"><%= kpi.totalNew %></h3></div>
                        </div></div>
                    </div>
                    <div class="col-xl-3 col-sm-6">
                        <div class="card h-100 border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-arrow-repeat"></i></div>
                            <div><div class="stat-label">Hàng cũ</div><h3 class="stat-value"><%= kpi.totalUsed %></h3></div>
                        </div></div>
                    </div>
                    <div class="col-xl-3 col-sm-6">
                        <div class="card h-100 border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-danger bg-opacity-10 text-danger"><i class="bi bi-shield-exclamation"></i></div>
                            <div><div class="stat-label">Hàng hỏng</div><h3 class="stat-value"><%= kpi.totalQuarantine %></h3></div>
                        </div></div>
                    </div>
                    <div class="col-12">
                        <div class="d-flex flex-wrap align-items-center gap-3 px-3 py-2 rounded-3 bg-light border small">
                            <span class="text-warning-emphasis"><i class="bi bi-exclamation-triangle-fill me-1"></i>Sắp hết: <strong><%= kpi.lowStockSkus %> SKU</strong></span>
                            <span class="text-secondary"><i class="bi bi-dash-circle-fill me-1"></i>Thất thoát: <strong><%= kpi.totalLost %></strong></span>
                            <% if (kpi.totalValue != null) { %>
                            <span class="ms-xl-auto text-primary"><i class="bi bi-cash-stack me-1"></i>Giá trị hàng mới và cũ: <strong><%= kpi.totalValue %>đ</strong></span>
                            <% } %>
                        </div>
                    </div>
                </div>
                <% } %>
                
                <div class="card mb-3">
                    <div class="card-body">
                        <form method="GET" action="<%= request.getContextPath() %>/warehouse/inventory" class="row g-2">
                            <% if (!bound) { %>
                            <div class="col-md-3">
                                <label class="form-label small fw-semibold">Kho</label>
                                <select class="form-select form-select-sm" name="warehouse_id">
                                    <option value="">— Tất cả —</option>
                                    <% if (warehouseList != null) for (Warehouse w : warehouseList) { %>
                                        <option value="<%= w.getId() %>" <%= filterWh != null && filterWh == w.getId() ? "selected" : "" %>>
                                            <%= w.getWarehouseName() %>
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            <% } %>
                            <div class="col-md-4">
                                <label class="form-label small fw-semibold">Tìm kiếm</label>
                                <input type="text" class="form-control form-control-sm" name="keyword"
                                       value="<%= filterKw == null ? "" : filterKw %>" placeholder="Tên sản phẩm hoặc SKU...">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small fw-semibold">&nbsp;</label>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" name="low_stock" value="1" id="lowStock" <%= filterLow ? "checked" : "" %>>
                                    <label class="form-check-label small" for="lowStock">Sắp hết hàng</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" name="has_damaged" value="1" id="hasDmg" <%= filterDmg ? "checked" : "" %>>
                                    <label class="form-check-label small" for="hasDmg">Có hàng hỏng</label>
                                </div>
                            </div>
                            <div class="col-md-3 d-flex align-items-end gap-1">
                                <button type="submit" class="btn btn-primary btn-sm"><i class="bi bi-funnel"></i> Lọc</button>
                                <a href="<%= request.getContextPath() %>/warehouse/inventory" class="btn btn-outline-secondary btn-sm" title="Làm mới"><i class="bi bi-arrow-counterclockwise"></i></a>
                            </div>
                        </form>
                    </div>
                </div>

                
                <div class="card border-0 shadow-sm">
                    <div class="card-header bg-white border-bottom py-3 d-flex justify-content-between align-items-center">
                        <div><h5 class="mb-1 fw-bold">Ma trận tồn kho</h5><div class="small text-muted">Tổng hàng = hàng mới + hàng cũ + hàng hỏng</div></div>
                        <span class="badge bg-primary bg-opacity-10 text-primary"><i class="bi bi-grid-3x3-gap me-1"></i>Theo tình trạng</span>
                    </div>
                    <div class="card-body p-0 table-responsive">
                    <% if (isGroupedView) { %>
                        <table id="inventoryTable" class="table table-hover mb-0 align-middle inventory-table" style="min-width:1120px">
                            <thead class="table-light">
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>SKU</th>
                                    <th class="text-end">Hàng mới</th>
                                    <th class="text-end">Hàng cũ</th>
                                    <th class="text-end">Hàng hỏng</th>
                                    <th class="text-end">Tổng hàng</th>
                                    <th class="text-end">Đang chuyển</th>
                                    <th class="text-end">Thất thoát</th>
                                    <th>Cảnh báo</th>
                                    <th class="text-center">Chi tiết</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (groupedRows.isEmpty()) { %>
                                <tr><td colspan="10" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không có dữ liệu tồn kho phù hợp.</p></div></td></tr>
                            <% } else { int idx = 0; for (InventoryGroupedRow g : groupedRows) { idx++; %>
                                <tr class="grouped-row" style="cursor:pointer" onclick="toggleDetail(<%= idx %>)">
                                    <td>
                                        <i class="bi bi-chevron-right text-muted me-1 toggle-icon" id="icon-<%= idx %>" style="transition:transform .2s; font-size:.75rem"></i>
                                        <strong><%= g.getProductName() %></strong>
                                        <% if (g.getCategoryName() != null) { %><br><small class="text-muted ms-3"><%= g.getCategoryName() %><%= g.getBrandName() != null ? " · " + g.getBrandName() : "" %></small><% } %>
                                    </td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= g.getSku() %></span></td>
                                    <td class="text-end text-success fw-semibold"><%= g.getTotalNew() %></td>
                                    <td class="text-end text-info-emphasis fw-semibold"><%= g.getTotalUsed() %></td>
                                    <td class="text-end <%= g.getTotalQuarantine() > 0 ? "text-danger fw-bold" : "text-muted" %>"><%= g.getTotalQuarantine() %></td>
                                    <td class="text-end fw-bold"><%= g.getTotalOnHand() %> <small class="text-muted"><%= g.getUnit() %></small></td>
                                    <td class="text-end text-muted"><%= g.getTotalInTransit() %></td>
                                    <td class="text-end text-muted"><%= g.getTotalLost() %></td>
                                    <td>
                                        <% if (g.isAnyLowStock()) { %><span class="status-chip chip-warning">Sắp hết</span><% } %>
                                        <% if (g.hasAnyDamaged()) { %><span class="status-chip chip-danger ms-1">Có hỏng</span><% } %>
                                        <% if (g.hasAnyInTransit()) { %><span class="status-chip chip-info ms-1">Đang chuyển</span><% } %>
                                    </td>
                                    <td></td>
                                </tr>
                                <tr id="detail-<%= idx %>" style="display:none">
                                    <td colspan="10" class="p-0">
                                        <div class="bg-light py-1">
                                            <table class="table table-sm mb-0 align-middle inventory-breakdown">
                                                <tbody>
                                                <% for (InventoryRow w : g.getWarehouses()) { %>
                                                    <tr>
                                                        <td><i class="bi bi-building me-2 text-slate-400"></i><%= w.getWarehouseName() %></td>
                                                        <td></td>
                                                        <td class="text-end text-success"><%= w.getNewQuantity() %></td>
                                                        <td class="text-end text-info-emphasis"><%= w.getUsedQuantity() %></td>
                                                        <td class="text-end <%= w.getQuarantineQuantity() > 0 ? "text-danger" : "text-muted" %>"><%= w.getQuarantineQuantity() %></td>
                                                        <td class="text-end fw-semibold"><%= w.getTotalQuantity() %></td>
                                                        <td class="text-end text-muted"><%= w.getInTransitQuantity() %></td>
                                                        <td class="text-end text-muted"><%= w.getLostQuantity() %></td>
                                                        <td><% if (w.isLowStock()) { %><span class="status-chip chip-warning">Sắp hết</span><% } %></td>
                                                        <td class="text-center"><a href="<%= request.getContextPath() %>/warehouse/inventory?action=detail&warehouse_id=<%= w.getWarehouseId() %>&product_id=<%= w.getProductId() %>" class="btn btn-table btn-outline-primary" title="Xem chi tiết"><i class="bi bi-eye"></i></a></td>
                                                    </tr>
                                                <% } %>
                                                </tbody>
                                            </table>
                                        </div>
                                    </td>
                                </tr>
                            <% } } %>
                            </tbody>
                        </table>
                    <% } else { %>
                        <table id="inventoryTable" class="table table-hover mb-0 align-middle" style="min-width:1180px">
                            <thead class="table-light">
                                <tr>
                                    <th>Sản phẩm</th><th>SKU</th><th>Kho</th>
                                    <th class="text-end">Hàng mới</th><th class="text-end">Hàng cũ</th><th class="text-end">Hàng hỏng</th><th class="text-end">Tổng hàng</th>
                                    <th class="text-end">Đang chuyển</th><th class="text-end">Thất thoát</th><th>Cảnh báo</th><th></th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (rows == null || rows.isEmpty()) { %>
                                <tr><td colspan="11" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không có dữ liệu tồn kho phù hợp.</p></div></td></tr>
                            <% } else { for (InventoryRow r : rows) { %>
                                <tr>
                                    <td><strong><%= r.getProductName() %></strong><% if (r.getCategoryName() != null) { %><br><small class="text-muted"><%= r.getCategoryName() %><%= r.getBrandName() != null ? " · " + r.getBrandName() : "" %></small><% } %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= r.getSku() %></span></td>
                                    <td><%= r.getWarehouseName() %></td>
                                    <td class="text-end text-success fw-semibold"><%= r.getNewQuantity() %></td>
                                    <td class="text-end text-info-emphasis fw-semibold"><%= r.getUsedQuantity() %></td>
                                    <td class="text-end <%= r.getQuarantineQuantity() > 0 ? "text-danger fw-bold" : "text-muted" %>"><%= r.getQuarantineQuantity() %></td>
                                    <td class="text-end fw-bold"><%= r.getTotalQuantity() %> <small class="text-muted"><%= r.getUnit() %></small></td>
                                    <td class="text-end text-muted"><%= r.getInTransitQuantity() %></td>
                                    <td class="text-end text-muted"><%= r.getLostQuantity() %></td>
                                    <td><% if (r.isLowStock()) { %><span class="status-chip chip-warning">Sắp hết</span><% } %><% if (r.hasDamaged()) { %><span class="status-chip chip-danger ms-1">Có hỏng</span><% } %></td>
                                    <td><a href="<%= request.getContextPath() %>/warehouse/inventory?action=detail&warehouse_id=<%= r.getWarehouseId() %>&product_id=<%= r.getProductId() %>" class="btn btn-sm btn-outline-primary"><i class="bi bi-eye"></i></a></td>
                                </tr>
                            <% } } %>
                            </tbody>
                        </table>
                    <% } %>
                    </div>                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                            <label class="text-muted small mb-0 flex-shrink-0">Hiển thị</label>
                            <select id="entriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;">
                                <option value="10" selected>10</option>
                                <option value="25">25</option>
                                <option value="100">100</option>
                            </select>
                            <span class="text-muted small">dòng</span>
                        </div>
                        <div id="paginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto"></div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
    function toggleDetail(idx) {
        var row = document.getElementById('detail-' + idx);
        var icon = document.getElementById('icon-' + idx);
        if (row.style.display === 'none') {
            row.style.display = '';
            icon.style.transform = 'rotate(90deg)';
        } else {
            row.style.display = 'none';
            icon.style.transform = 'rotate(0deg)';
        }
    }

    document.addEventListener("DOMContentLoaded", function() {
        var isGrouped = <%= isGroupedView %>;
        if (isGrouped) {
            initGroupedPagination("inventoryTable", "paginationContainer", "entriesPerPage");
        } else {
            initPagination("inventoryTable", "paginationContainer", "entriesPerPage", null);
        }
    });

    function initGroupedPagination(tableId, containerId, selectId) {
        var table = document.getElementById(tableId);
        if (!table) return;
        var tbody = table.querySelector("tbody");
        if (!tbody) return;
        var allRows = Array.from(tbody.querySelectorAll("tr"));
        if (allRows.length === 1 && allRows[0].querySelector("td[colspan]")) return;

        var groups = [];
        for (var i = 0; i < allRows.length; i++) {
            var row = allRows[i];
            if (row.classList.contains("grouped-row")) {
                var detailRow = (i + 1 < allRows.length && allRows[i + 1].id && allRows[i + 1].id.startsWith("detail-")) ? allRows[i + 1] : null;
                groups.push({ main: row, detail: detailRow });
                if (detailRow) i++;
            }
        }
        if (groups.length === 0) return;

        var container = document.getElementById(containerId);
        var select = document.getElementById(selectId);
        if (!container || !select) return;
        var currentPage = 1;
        var pageSize = parseInt(select.value) || 10;

        function updateTable() {
            var totalItems = groups.length;
            var totalPages = Math.ceil(totalItems / pageSize) || 1;
            if (currentPage > totalPages) currentPage = Math.max(1, totalPages);
            var start = (currentPage - 1) * pageSize;
            var end = Math.min(start + pageSize, totalItems);
            groups.forEach(function(g, index) {
                if (index >= start && index < end) {
                    g.main.style.display = "";
                } else {
                    g.main.style.display = "none";
                    if (g.detail) {
                        g.detail.style.display = "none";
                        var idx = g.main.getAttribute("onclick").match(/\d+/)[0];
                        var icon = document.getElementById("icon-" + idx);
                        if (icon) icon.style.transform = "rotate(0deg)";
                    }
                }
            });
            renderControls(totalItems, totalPages);
        }

        function renderControls(totalRows, totalPages) {
            container.innerHTML = "";
            var startNum = totalRows === 0 ? 0 : (currentPage - 1) * pageSize + 1;
            var endNum = Math.min(startNum + pageSize - 1, totalRows);
            var infoDiv = document.createElement("div");
            infoDiv.className = "text-muted small my-2 my-sm-0";
            infoDiv.textContent = "Hiển thị " + startNum + " đến " + endNum + " của " + totalRows + " SKU";
            container.appendChild(infoDiv);
            if (totalPages <= 1) return;
            var nav = document.createElement("nav");
            var ul = document.createElement("ul");
            ul.className = "pagination pagination-sm mb-0 gap-1";
            var prevLi = document.createElement("li");
            prevLi.className = "page-item " + (currentPage === 1 ? "disabled" : "");
            var prevBtn = document.createElement("a");
            prevBtn.className = "page-link border-0 rounded-2 shadow-none px-2 py-1";
            prevBtn.href = "javascript:void(0)";
            prevBtn.innerHTML = '<i class="bi bi-chevron-left"></i>';
            prevBtn.addEventListener("click", function() { if (currentPage > 1) { currentPage--; updateTable(); } });
            prevLi.appendChild(prevBtn);
            ul.appendChild(prevLi);
            var startPage = Math.max(1, currentPage - 2);
            var endPage = Math.min(totalPages, startPage + 4);
            if (endPage - startPage < 4) startPage = Math.max(1, endPage - 4);
            for (var i = startPage; i <= endPage; i++) {
                var li = document.createElement("li");
                li.className = "page-item " + (currentPage === i ? "active" : "");
                var btn = document.createElement("a");
                btn.className = "page-link border-0 rounded-2 shadow-none px-3 py-1";
                btn.href = "javascript:void(0)";
                btn.textContent = i;
                (function(p) { btn.addEventListener("click", function() { currentPage = p; updateTable(); }); })(i);
                li.appendChild(btn);
                ul.appendChild(li);
            }
            var nextLi = document.createElement("li");
            nextLi.className = "page-item " + (currentPage === totalPages ? "disabled" : "");
            var nextBtn = document.createElement("a");
            nextBtn.className = "page-link border-0 rounded-2 shadow-none px-2 py-1";
            nextBtn.href = "javascript:void(0)";
            nextBtn.innerHTML = '<i class="bi bi-chevron-right"></i>';
            nextBtn.addEventListener("click", function() { if (currentPage < totalPages) { currentPage++; updateTable(); } });
            nextLi.appendChild(nextBtn);
            ul.appendChild(nextLi);
            nav.appendChild(ul);
            container.appendChild(nav);
        }

        select.addEventListener("change", function() { pageSize = parseInt(select.value) || 10; currentPage = 1; updateTable(); });
        updateTable();
    }

    function initPagination(tableId, containerId, selectId, searchInputId) {
        var table = document.getElementById(tableId);
        if (!table) return;
        var tbody = table.querySelector("tbody");
        if (!tbody) return;
        var allRows = Array.from(tbody.querySelectorAll("tr"));
        if (allRows.length === 1 && allRows[0].querySelector("td[colspan]")) return;
        var container = document.getElementById(containerId);
        var select = document.getElementById(selectId);
        var searchInput = searchInputId ? document.getElementById(searchInputId) : null;
        if (!container || !select) return;
        var currentPage = 1;
        var pageSize = parseInt(select.value) || 10;
        var filteredRows = allRows;

        function updateTable() {
            if (searchInput) {
                var query = searchInput.value.toLowerCase().trim();
                filteredRows = allRows.filter(function(row) { return row.textContent.toLowerCase().includes(query); });
            } else {
                filteredRows = allRows;
            }
            var totalRows = filteredRows.length;
            var totalPages = Math.ceil(totalRows / pageSize) || 1;
            if (currentPage > totalPages) currentPage = Math.max(1, totalPages);
            var start = (currentPage - 1) * pageSize;
            var end = Math.min(start + pageSize, totalRows);
            allRows.forEach(function(row) { row.style.display = "none"; });
            filteredRows.forEach(function(row, index) {
                if (index >= start && index < end) row.style.display = "";
            });
            renderControls(totalRows, totalPages);
        }

        function renderControls(totalRows, totalPages) {
            container.innerHTML = "";
            var startNum = totalRows === 0 ? 0 : (currentPage - 1) * pageSize + 1;
            var endNum = Math.min(startNum + pageSize - 1, totalRows);
            var infoDiv = document.createElement("div");
            infoDiv.className = "text-muted small my-2 my-sm-0";
            infoDiv.textContent = "Hiển thị " + startNum + " đến " + endNum + " của " + totalRows + " dòng";
            container.appendChild(infoDiv);
            if (totalPages <= 1) return;
            var nav = document.createElement("nav");
            var ul = document.createElement("ul");
            ul.className = "pagination pagination-sm mb-0 gap-1";
            var prevLi = document.createElement("li");
            prevLi.className = "page-item " + (currentPage === 1 ? "disabled" : "");
            var prevBtn = document.createElement("a");
            prevBtn.className = "page-link border-0 rounded-2 shadow-none px-2 py-1";
            prevBtn.href = "javascript:void(0)";
            prevBtn.innerHTML = '<i class="bi bi-chevron-left"></i>';
            prevBtn.addEventListener("click", function() { if (currentPage > 1) { currentPage--; updateTable(); } });
            prevLi.appendChild(prevBtn);
            ul.appendChild(prevLi);
            var startPage = Math.max(1, currentPage - 2);
            var endPage = Math.min(totalPages, startPage + 4);
            if (endPage - startPage < 4) startPage = Math.max(1, endPage - 4);
            for (var i = startPage; i <= endPage; i++) {
                var li = document.createElement("li");
                li.className = "page-item " + (currentPage === i ? "active" : "");
                var btn = document.createElement("a");
                btn.className = "page-link border-0 rounded-2 shadow-none px-3 py-1";
                btn.href = "javascript:void(0)";
                btn.textContent = i;
                (function(p) { btn.addEventListener("click", function() { currentPage = p; updateTable(); }); })(i);
                li.appendChild(btn);
                ul.appendChild(li);
            }
            var nextLi = document.createElement("li");
            nextLi.className = "page-item " + (currentPage === totalPages ? "disabled" : "");
            var nextBtn = document.createElement("a");
            nextBtn.className = "page-link border-0 rounded-2 shadow-none px-2 py-1";
            nextBtn.href = "javascript:void(0)";
            nextBtn.innerHTML = '<i class="bi bi-chevron-right"></i>';
            nextBtn.addEventListener("click", function() { if (currentPage < totalPages) { currentPage++; updateTable(); } });
            nextLi.appendChild(nextBtn);
            ul.appendChild(nextLi);
            nav.appendChild(ul);
            container.appendChild(nav);
        }

        select.addEventListener("change", function() { pageSize = parseInt(select.value) || 10; currentPage = 1; updateTable(); });
        if (searchInput) searchInput.addEventListener("input", function() { currentPage = 1; updateTable(); });
        updateTable();
    }
    </script>
</body>
</html>
