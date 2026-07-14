<%@page import="model.Stocktake"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("STOCKTAKE_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Stocktake> stocktakeList = (List<Stocktake>) request.getAttribute("stocktakeList");
    boolean canCreate = loggedInUser.hasPermission("STOCKTAKE_CREATE");
    boolean canConfig = loggedInUser.hasPermission("STOCKTAKE_CONFIG");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Phiếu kiểm kê - WMS</title>
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
                        <h2 class="page-title">Phiếu kiểm kê</h2>
                        <p class="page-subtitle">Quản lý phiếu kiểm kê tồn kho</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (canConfig) { %>
                            <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=config" class="btn btn-outline-secondary btn-sm">
                                <i class="bi bi-gear"></i> Ngưỡng duyệt
                            </a>
                        <% } %>
                        <% if (canCreate) { %>
                            <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=add" class="btn btn-primary btn-sm">
                                <i class="bi bi-plus-circle"></i> Tạo phiếu kiểm kê
                            </a>
                        <% } %>
                    </div>
                </div>

                
                <div class="card mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-12 col-md-3">
                                <label for="stocktakeSearch" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" id="stocktakeSearch" class="form-control form-control-sm" placeholder="Mã phiếu, kho, người tạo...">
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="startDateFilter" class="form-label small fw-semibold mb-1">Từ ngày</label>
                                <input type="date" id="startDateFilter" class="form-control form-control-sm">
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="endDateFilter" class="form-label small fw-semibold mb-1">Đến ngày</label>
                                <input type="date" id="endDateFilter" class="form-control form-control-sm">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Trạng thái</label>
                                <div class="dropdown">
                                    <button type="button" id="statusDropdownBtn" class="btn btn-outline-secondary btn-sm dropdown-toggle w-100 text-start fw-normal"
                                            data-bs-toggle="dropdown" data-bs-auto-close="outside" style="background:#fff; font-size:0.875rem;">
                                        <span id="statusLabel">-- Tất cả --</span>
                                    </button>
                                    <ul class="dropdown-menu p-2 shadow-sm" id="statusDropdownMenu" style="min-width:180px;">
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="DRAFT"> Bản nháp</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="COUNTING"> Đang kiểm</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="SUBMITTED"> Chờ duyệt</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="L1_APPROVED"> Duyệt cấp 1</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="APPROVED"> Đã duyệt</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="ADJUSTED"> Đã điều chỉnh</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="REJECTED"> Từ chối</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="CANCELLED"> Đã hủy</label></li>
                                        <li><hr class="dropdown-divider my-1"></li>
                                        <li><button type="button" id="clearStatusBtn" class="btn btn-link btn-sm w-100 text-muted text-decoration-none py-1" style="font-size:0.8rem;"><i class="bi bi-x-circle me-1"></i>Xóa chọn</button></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-12 col-md-auto ms-md-auto d-flex gap-2">
                                <button type="button" id="filterBtn" class="btn btn-primary btn-sm px-3">
                                    <i class="bi bi-funnel-fill me-1"></i>Lọc
                                </button>
                                <button type="button" id="resetBtn" class="btn btn-outline-secondary btn-sm px-3" title="Đặt lại bộ lọc">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>Đặt lại
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-clipboard-check me-2 text-primary"></i>Danh sách</span>
                    </div>
                    <div class="card-body p-0">
                        <table id="stocktakeTable" class="table table-hover mb-0 align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Mã phiếu</th>
                                    <th>Kho</th>
                                    <th>Phạm vi kiểm kê</th>
                                    <th>Hình thức kiểm</th>
                                    <th>Trạng thái</th>
                                    <th>Tỷ lệ chênh lệch</th>
                                    <th>Người tạo</th>
                                    <th>Ngày tạo</th>
                                    <th class="text-center">Thao tác</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (stocktakeList == null || stocktakeList.isEmpty()) { %>
                                <tr><td colspan="9" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Chưa có phiếu nào.</p></div></td></tr>
                            <% } else { for (Stocktake s : stocktakeList) {
                                String badge = "chip-muted";
                                switch (s.getStatus()) {
                                    case "DRAFT":       badge = "chip-muted"; break;
                                    case "COUNTING":    badge = "chip-info"; break;
                                    case "SUBMITTED":   badge = "chip-warning"; break;
                                    case "L1_APPROVED": badge = "chip-primary"; break;
                                    case "APPROVED":    badge = "chip-success"; break;
                                    case "REJECTED":    badge = "chip-danger"; break;
                                    case "ADJUSTED":    badge = "chip-success"; break;
                                    case "CANCELLED":   badge = "chip-muted"; break;
                                }
                            %>
                                <tr>
                                    <td><strong><%= s.getStocktakeCode() %></strong></td>
                                    <td><%= s.getWarehouseName() %></td>
                                    <td><%= s.isFullScope() ? "Toàn kho" : "Một phần" %></td>
                                    <td><%= s.isSerialMode() ? "Quét mã serial" : "Theo số lượng" %></td>
                                    <td><span class="status-chip <%= badge %>"><%
                                        String displaySt = s.getStatus();
                                        if ("DRAFT".equals(displaySt)) displaySt = "Bản nháp";
                                        else if ("COUNTING".equals(displaySt)) displaySt = "Đang kiểm";
                                        else if ("SUBMITTED".equals(displaySt)) displaySt = "Chờ duyệt";
                                        else if ("L1_APPROVED".equals(displaySt)) displaySt = "Duyệt cấp 1";
                                        else if ("APPROVED".equals(displaySt)) displaySt = "Đã duyệt";
                                        else if ("REJECTED".equals(displaySt)) displaySt = "Từ chối";
                                        else if ("ADJUSTED".equals(displaySt)) displaySt = "Đã điều chỉnh";
                                        else if ("CANCELLED".equals(displaySt)) displaySt = "Đã hủy";
                                    %><%= displaySt %></span>
                                        <% if (s.isRequiresL2Approval() && !s.isAdjusted() && !s.isCancelled()) { %>
                                            <span class="badge bg-warning text-dark ms-1">L2</span>
                                        <% } %>
                                    </td>
                                    <td><%= s.getVariancePercent() == null ? "—" : s.getVariancePercent() + "%" %></td>
                                    <td><%= s.getCreatedByFullName() %></td>
                                    <td><%= s.getCreatedAt() %></td>
                                    <td class="text-center">
                                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=detail&id=<%= s.getId() %>"
                                           class="btn btn-table btn-outline-secondary" title="Xem chi tiết" aria-label="Xem chi tiết phiếu kiểm kê">
                                            <i class="bi bi-eye" aria-hidden="true"></i>
                                        </a>
                                    </td>
                                </tr>
                            <% } } %>
                            </tbody>
                        </table>
                    </div>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
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
    document.addEventListener("DOMContentLoaded", function() {
        initPagination("stocktakeTable", "paginationContainer", "entriesPerPage", "stocktakeSearch");


        function getSelectedStatuses() {
            return Array.from(document.querySelectorAll('#statusDropdownMenu .status-cb:checked')).map(function(cb) { return cb.value; });
        }
        function updateStatusLabel() {
            var checked = document.querySelectorAll('#statusDropdownMenu .status-cb:checked');
            var label = document.getElementById('statusLabel');
            if (checked.length === 0) label.textContent = '-- Tất cả --';
            else if (checked.length === 1) label.textContent = checked[0].closest('label').textContent.trim();
            else label.textContent = checked.length + ' đã chọn';
        }
        document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(function(cb) { cb.addEventListener('change', updateStatusLabel); });
        document.getElementById('clearStatusBtn').addEventListener('click', function(e) {
            e.stopPropagation();
            document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(function(cb) { cb.checked = false; });
            updateStatusLabel();
        });
        new bootstrap.Dropdown(document.getElementById('statusDropdownBtn'), { popperConfig: { strategy: 'fixed' } });

        var startDateFilter = document.getElementById("startDateFilter");
        var endDateFilter = document.getElementById("endDateFilter");
        startDateFilter.addEventListener("change", function() {
            endDateFilter.min = startDateFilter.value;
            if (endDateFilter.value && endDateFilter.value < startDateFilter.value) endDateFilter.value = startDateFilter.value;
        });
        endDateFilter.addEventListener("change", function() {
            startDateFilter.max = endDateFilter.value;
            if (startDateFilter.value && startDateFilter.value > endDateFilter.value) startDateFilter.value = endDateFilter.value;
        });

        var tbody = document.querySelector("#stocktakeTable tbody");
        var allRows = tbody ? Array.from(tbody.querySelectorAll("tr")) : [];

        function applyFilters() {
            var q = (document.getElementById("stocktakeSearch").value || "").toLowerCase();
            var selectedStatuses = getSelectedStatuses();
            var from = document.getElementById("startDateFilter").value;
            var to = document.getElementById("endDateFilter").value;
            allRows.forEach(function(row) {
                if (row.querySelector("td[colspan]")) return;
                var text = row.textContent.toLowerCase();
                var cells = row.querySelectorAll("td");
                var rowDate = cells[7] ? cells[7].textContent.trim().substring(0, 10) : "";
                var rowStatus = cells[4] ? cells[4].querySelector(".status-chip") ? cells[4].querySelector(".status-chip").textContent.trim() : "" : "";
                var ok = (!q || text.includes(q))
                    && (selectedStatuses.length === 0 || selectedStatuses.includes(rowStatus))
                    && (!from || rowDate >= from)
                    && (!to || rowDate <= to);
                row.style.display = ok ? "" : "none";
            });
        }

        ["stocktakeSearch","statusFilter","startDateFilter","endDateFilter"].forEach(function(id) {
            var el = document.getElementById(id);
            if (el) el.addEventListener("input", applyFilters);
        });
        document.getElementById("filterBtn").addEventListener("click", applyFilters);
        document.getElementById("resetBtn").addEventListener("click", function() {
            document.getElementById("stocktakeSearch").value = "";
            document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(function(cb) { cb.checked = false; });
            updateStatusLabel();
            document.getElementById("startDateFilter").value = "";
            document.getElementById("startDateFilter").max = "";
            document.getElementById("endDateFilter").value = "";
            document.getElementById("endDateFilter").min = "";
            applyFilters();
        });
    });

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
