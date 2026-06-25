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

                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold mb-1">Phiếu kiểm kê</h2>
                        <p class="text-muted small mb-0">Quản lý phiếu kiểm kê tồn kho</p>
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

                <div class="card shadow-sm border-0">
                    <div class="card-header bg-primary bg-opacity-10 py-3">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-clipboard-check me-2"></i>Danh sách</h5>
                    </div>
                    <div class="card-body p-0">
                        <table id="stocktakeTable" class="table table-hover mb-0 align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Mã phiếu</th>
                                    <th>Kho</th>
                                    <th>Phạm vi</th>
                                    <th>Cách đếm</th>
                                    <th>Trạng thái</th>
                                    <th>Chênh lệch</th>
                                    <th>Người tạo</th>
                                    <th>Ngày tạo</th>
                                    <th></th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (stocktakeList == null || stocktakeList.isEmpty()) { %>
                                <tr><td colspan="9" class="text-center text-muted p-4">Chưa có phiếu nào.</td></tr>
                            <% } else { for (Stocktake s : stocktakeList) {
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
                            %>
                                <tr>
                                    <td><strong><%= s.getStocktakeCode() %></strong></td>
                                    <td><%= s.getWarehouseName() %></td>
                                    <td><%= s.isFullScope() ? "Toàn kho" : "Một phần" %></td>
                                    <td><%= s.isSerialMode() ? "Scan serial" : "Theo số lượng" %></td>
                                    <td><span class="badge bg-<%= badge %>"><%= s.getStatus() %></span>
                                        <% if (s.isRequiresL2Approval() && !s.isAdjusted() && !s.isCancelled()) { %>
                                            <span class="badge bg-warning text-dark ms-1">L2</span>
                                        <% } %>
                                    </td>
                                    <td><%= s.getVariancePercent() == null ? "—" : s.getVariancePercent() + "%" %></td>
                                    <td><%= s.getCreatedByFullName() %></td>
                                    <td><%= s.getCreatedAt() %></td>
                                    <td>
                                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=detail&id=<%= s.getId() %>"
                                           class="btn btn-sm btn-outline-primary">
                                            <i class="bi bi-eye"></i>
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
        initPagination("stocktakeTable", "paginationContainer", "entriesPerPage", null);
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
