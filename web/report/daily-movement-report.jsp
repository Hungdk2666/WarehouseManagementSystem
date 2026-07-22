<%@page import="model.User"%>
<%@page import="model.DailyMovementRow"%>
<%@page import="model.Warehouse"%>
<%@page import="java.util.List"%>
<%@page import="java.text.NumberFormat"%>
<%@page import="java.util.Locale"%>
<%@page import="java.net.URLEncoder"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("STOCK_LEDGER_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<DailyMovementRow> rows = (List<DailyMovementRow>) request.getAttribute("dailyRows");
    List<Warehouse> warehouses = (List<Warehouse>) request.getAttribute("warehouses");

    String fromDate = (String) request.getAttribute("fromDate");
    String toDate = (String) request.getAttribute("toDate");
    String search = (String) request.getAttribute("search");
    Integer warehouseId = (Integer) request.getAttribute("warehouseId");
    Boolean boundObj = (Boolean) request.getAttribute("userBoundToWarehouse");
    boolean userBoundToWarehouse = boundObj != null && boundObj;

    if (fromDate == null) fromDate = "";
    if (toDate == null) toDate = "";
    if (search == null) search = "";

    NumberFormat nf = NumberFormat.getInstance(new Locale("vi", "VN"));

    String filterParams = "&fromDate=" + URLEncoder.encode(fromDate, "UTF-8")
            + "&toDate=" + URLEncoder.encode(toDate, "UTF-8")
            + "&search=" + URLEncoder.encode(search, "UTF-8")
            + (warehouseId != null ? "&warehouseId=" + warehouseId : "");

    int totalRows = (rows != null) ? rows.size() : 0;
    long totalImport = 0, totalExport = 0, totalAdjustment = 0;
    if (rows != null) { for (DailyMovementRow r : rows) {
        totalImport += r.getImportQuantity();
        totalExport += r.getExportQuantity();
        totalAdjustment += r.getAdjustmentQuantity();
    } }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Báo cáo chi tiết xuất - nhập vật tư theo ngày - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .nav.nav-pills{gap:.55rem;padding:0;background:transparent!important;border:0!important;box-shadow:none!important;overflow:visible}
        .nav.nav-pills .nav-item{flex:0 0 auto}
        .nav.nav-pills .nav-link{min-height:2.45rem;padding:.5rem 1rem!important;color:#0f172a!important;background:#fff!important;border:1px solid #cbd5e1!important;border-radius:8px!important;font-size:.88rem;font-weight:800;box-shadow:0 1px 2px rgba(15,23,42,.04)}
        .nav.nav-pills .nav-link:hover{color:#0f172a!important;background:#f8fafc!important;border-color:#94a3b8!important}
        .nav.nav-pills .nav-link.active{color:#fff!important;background:#0f172a!important;border-color:#0f172a!important;box-shadow:0 3px 8px rgba(15,23,42,.16)!important}
        .nav.nav-pills .nav-link.active:hover{color:#fff!important;background:#1e293b!important}
        @media (max-width:767.98px){.nav.nav-pills{gap:.4rem;overflow-x:auto}.nav.nav-pills .nav-link{padding:.45rem .8rem!important;font-size:.82rem}}
    </style>
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
                        <h2 class="page-title">Báo cáo chi tiết xuất - nhập vật tư theo ngày</h2>
                        <p class="page-subtitle">Phân tách nhập, xuất và điều chỉnh kiểm kê của từng vật tư theo ngày</p>
                    </div>
                    <% if (!fromDate.isEmpty() && !toDate.isEmpty()) { %>
                    <a href="<%= request.getContextPath() %>/warehouse/movement-report?type=daily&action=export<%= filterParams %>"
                       class="btn btn-success btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-file-earmark-excel"></i> Xuất Excel
                    </a>
                    <% } %>
                </div>

                <ul class="nav nav-pills mb-3">
                    <li class="nav-item">
                        <a class="nav-link active" href="<%= request.getContextPath() %>/warehouse/movement-report?type=daily">Chi tiết theo ngày</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath() %>/warehouse/movement-report?type=import">Nhập hàng</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath() %>/warehouse/movement-report?type=export">Xuất kho</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="<%= request.getContextPath() %>/warehouse/movement-report?type=period">Tổng hợp Nhập - Xuất - Tồn</a>
                    </li>
                </ul>

                
                <div class="card mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <form id="filterForm" action="movement-report" method="GET" class="row g-2 align-items-end">
                            <input type="hidden" name="type" value="daily">
                            <div class="col-6 col-md-auto">
                                <label class="form-label small fw-semibold mb-1">Từ ngày</label>
                                <input type="date" name="fromDate" class="form-control form-control-sm" value="<%= fromDate %>" required>
                            </div>
                            <div class="col-6 col-md-auto">
                                <label class="form-label small fw-semibold mb-1">Đến ngày</label>
                                <input type="date" name="toDate" class="form-control form-control-sm" value="<%= toDate %>" required>
                            </div>
                            <div class="col-6 col-md-3">
                                <label class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" name="search" class="form-control form-control-sm"
                                       placeholder="SKU, tên vật tư..." value="<%= search %>">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Kho</label>
                                <select name="warehouseId" class="form-select form-select-sm" <%= userBoundToWarehouse ? "disabled" : "" %>>
                                    <option value="">-- Tất cả kho --</option>
                                    <% if (warehouses != null) { for (Warehouse wh : warehouses) { %>
                                    <option value="<%= wh.getId() %>" <%= (warehouseId != null && warehouseId == wh.getId()) ? "selected" : "" %>><%= wh.getWarehouseName() %></option>
                                    <% } } %>
                                </select>
                            </div>
                            <div class="col-12 col-md-auto ms-md-auto d-flex gap-2">
                                <button type="submit" class="btn btn-primary btn-sm px-3">
                                    <i class="bi bi-funnel-fill me-1"></i>Xem báo cáo
                                </button>
                                <a href="movement-report?type=daily" class="btn btn-outline-secondary btn-sm px-3">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>Đặt lại
                                </a>
                            </div>
                        </form>
                    </div>
                </div>

                <% if (fromDate.isEmpty() || toDate.isEmpty()) { %>
                <div class="empty-state">
                    <i class="bi bi-calendar-range"></i>
                    <p>Vui lòng chọn ngày bắt đầu và ngày kết thúc để xem báo cáo.</p>
                </div>
                <% } else { %>

                
                <div class="row g-2 mb-3">
                    <div class="col-xl-3 col-6"><div class="card border-0 shadow-sm px-3 py-2"><div class="small text-muted">Tổng nhập kho</div><div class="fs-5 fw-bold text-success"><%= nf.format(totalImport) %></div></div></div>
                    <div class="col-xl-3 col-6"><div class="card border-0 shadow-sm px-3 py-2"><div class="small text-muted">Tổng xuất kho</div><div class="fs-5 fw-bold text-danger"><%= nf.format(totalExport) %></div></div></div>
                    <div class="col-xl-3 col-6"><div class="card border-0 shadow-sm px-3 py-2"><div class="small text-muted">Điều chỉnh kiểm kê</div><div class="fs-5 fw-bold text-secondary"><%= totalAdjustment > 0 ? "+" : "" %><%= nf.format(totalAdjustment) %></div></div></div>
                </div>

                
                <div class="card bg-white">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                        <span class="fw-bold text-slate-800">
                            <i class="bi bi-clipboard-data me-2 text-primary"></i>
                            Từ <%= fromDate %> đến <%= toDate %> (<%= nf.format(totalRows) %> dòng)
                        </span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="dailyMovementReportTable" class="table table-hover align-middle mb-0" style="min-width: 1100px;">
                                <thead class="table-light" style="position: sticky; top: 0; z-index: 1;">
                                    <tr>
                                        <th class="ps-3">TT</th>
                                        <th>Mã vật tư</th>
                                        <th>Tên vật tư</th>
                                        <th>Đơn vị tính</th>
                                        <th>Ngày</th>
                                        <th class="text-end">Nhập kho</th>
                                        <th class="text-end">Xuất kho</th>
                                        <th class="text-end">Điều chỉnh kiểm kê</th>
                                        <th>Kho</th>
                                        <th>Ghi chú</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (rows != null && !rows.isEmpty()) {
                                            int tt = 1;
                                            for (DailyMovementRow r : rows) {
                                    %>
                                    <tr>
                                        <td class="ps-3 small text-muted"><%= tt++ %></td>
                                        <td class="font-monospace small"><%= r.getSku() != null ? r.getSku() : "" %></td>
                                        <td class="fw-semibold small"><%= r.getProductName() != null ? r.getProductName() : "" %></td>
                                        <td class="small text-muted"><%= r.getUnit() != null ? r.getUnit() : "" %></td>
                                        <td class="small"><%= r.getDate() %></td>
                                        <td class="text-end <%= r.getImportQuantity() > 0 ? "text-success fw-semibold" : "text-muted" %>"><%= nf.format(r.getImportQuantity()) %></td>
                                        <td class="text-end <%= r.getExportQuantity() > 0 ? "text-danger fw-semibold" : "text-muted" %>"><%= nf.format(r.getExportQuantity()) %></td>
                                        <td class="text-end <%= r.getAdjustmentQuantity() != 0 ? "text-secondary fw-semibold" : "text-muted" %>"><%= r.getAdjustmentQuantity() > 0 ? "+" : "" %><%= nf.format(r.getAdjustmentQuantity()) %></td>
                                        <td class="small"><%= r.getWarehouseName() != null ? r.getWarehouseName() : "" %></td>
                                        <td class="small text-muted"><%= r.getNote() != null ? r.getNote() : "" %></td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="10" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-clipboard-data"></i>
                                                <p>Không có biến động kho nào trong khoảng ngày đã chọn.</p>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                            <label class="text-muted small mb-0 flex-shrink-0">Hiển thị</label>
                            <select id="dailyMovementEntriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;">
                                <option value="10" selected>10</option>
                                <option value="25">25</option>
                                <option value="100">100</option>
                            </select>
                            <span class="text-muted small">dòng</span>
                        </div>
                        <div id="dailyMovementPaginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto"></div>
                    </div>
                </div>
                <% } %>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            initPagination("dailyMovementReportTable", "dailyMovementPaginationContainer", "dailyMovementEntriesPerPage");
        });

        function initPagination(tableId, containerId, selectId) {
            const table = document.getElementById(tableId);
            if (!table) return;
            const tbody = table.querySelector("tbody");
            if (!tbody) return;

            const rows = Array.from(tbody.querySelectorAll("tr"));
            if (rows.length === 1 && rows[0].querySelector("td[colspan]")) return;

            const container = document.getElementById(containerId);
            const select = document.getElementById(selectId);
            if (!container || !select) return;

            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;

            function updateTable() {
                const totalRows = rows.length;
                const totalPages = Math.ceil(totalRows / pageSize);
                if (currentPage > totalPages) currentPage = Math.max(1, totalPages);

                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, totalRows);
                rows.forEach((row, index) => {
                    row.style.display = index >= start && index < end ? "" : "none";
                });
                renderControls(totalRows, totalPages);
            }

            function renderControls(totalRows, totalPages) {
                container.innerHTML = "";

                const start = totalRows === 0 ? 0 : (currentPage - 1) * pageSize + 1;
                const end = Math.min(start + pageSize - 1, totalRows);
                const infoDiv = document.createElement("div");
                infoDiv.className = "text-muted small my-2 my-sm-0";
                infoDiv.textContent = "Hiển thị từ " + start + " đến " + end + " trong số " + totalRows + " dòng";
                container.appendChild(infoDiv);

                const nav = document.createElement("nav");
                const ul = document.createElement("ul");
                ul.className = "pagination pagination-sm mb-0 gap-1";
                addButton(ul, "<i class='bi bi-chevron-left'></i>", currentPage === 1, () => {
                    currentPage--;
                    updateTable();
                });

                let startPage = Math.max(1, currentPage - 2);
                let endPage = Math.min(totalPages, startPage + 4);
                if (endPage - startPage < 4) startPage = Math.max(1, endPage - 4);
                for (let i = startPage; i <= endPage; i++) {
                    const page = i;
                    addButton(ul, page, false, () => {
                        currentPage = page;
                        updateTable();
                    }, currentPage === page);
                }

                addButton(ul, "<i class='bi bi-chevron-right'></i>", currentPage === totalPages || totalPages === 0, () => {
                    currentPage++;
                    updateTable();
                });
                nav.appendChild(ul);
                container.appendChild(nav);
            }

            function addButton(list, label, disabled, onClick, active) {
                const item = document.createElement("li");
                item.className = "page-item " + (disabled ? "disabled" : "") + (active ? " active" : "");
                const button = document.createElement("a");
                button.className = "page-link border-0 rounded-2 shadow-none "
                        + (typeof label === "number" ? "px-3 py-1.5" : "px-2.5 py-1.5");
                button.href = "javascript:void(0)";
                button.innerHTML = label;
                button.addEventListener("click", () => {
                    if (!disabled) onClick();
                });
                item.appendChild(button);
                list.appendChild(item);
            }

            select.addEventListener("change", () => {
                pageSize = parseInt(select.value) || 10;
                currentPage = 1;
                updateTable();
            });
            updateTable();
        }
    </script>
</body>
</html>
