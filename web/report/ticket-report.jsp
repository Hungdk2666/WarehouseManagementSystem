<%@page import="model.User"%>
<%@page import="model.TicketReportRow"%>
<%@page import="model.Warehouse"%>
<%@page import="java.util.List"%>
<%@page import="java.math.BigDecimal"%>
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
    List<TicketReportRow> rows = (List<TicketReportRow>) request.getAttribute("ticketRows");
    List<Warehouse> warehouses = (List<Warehouse>) request.getAttribute("warehouses");
    String reportType = (String) request.getAttribute("ticketReportType");
    boolean importReport = "import".equals(reportType);
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
    int totalRows = rows == null ? 0 : rows.size();
    long totalQuantity = 0;
    BigDecimal totalPurchaseValue = BigDecimal.ZERO;
    if (rows != null) for (TicketReportRow row : rows) {
        totalQuantity += row.getQuantity();
        if (row.hasCost()) totalPurchaseValue = totalPurchaseValue.add(row.getTotalCost());
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= importReport ? "Báo cáo nhập hàng" : "Báo cáo xuất kho" %> - WMS</title>
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
                        <h2 class="page-title"><%= importReport ? "Báo cáo nhập hàng" : "Báo cáo xuất kho" %></h2>
                        <p class="page-subtitle"><%= importReport
                                ? "Chi tiết vật tư đã nhận vào kho; giá trị chỉ áp dụng cho phiếu nhập mua."
                                : "Chi tiết vật tư đã xuất khỏi kho theo phiếu kho nội bộ; không bao gồm giá bán." %></p>
                    </div>
                    <% if (!fromDate.isEmpty() && !toDate.isEmpty()) { %>
                    <a href="<%= request.getContextPath() %>/warehouse/movement-report?type=<%= reportType %>&action=export<%= filterParams %>"
                       class="btn btn-success btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-file-earmark-excel"></i> Xuất Excel
                    </a>
                    <% } %>
                </div>

                <ul class="nav nav-pills mb-3 flex-wrap gap-1">
                    <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/warehouse/movement-report?type=daily">Chi tiết theo ngày</a></li>
                    <li class="nav-item"><a class="nav-link <%= importReport ? "active" : "" %>" href="<%= request.getContextPath() %>/warehouse/movement-report?type=import">Nhập hàng</a></li>
                    <li class="nav-item"><a class="nav-link <%= !importReport ? "active" : "" %>" href="<%= request.getContextPath() %>/warehouse/movement-report?type=export">Xuất kho</a></li>
                    <li class="nav-item"><a class="nav-link" href="<%= request.getContextPath() %>/warehouse/movement-report?type=period">Tổng hợp Nhập - Xuất - Tồn</a></li>
                </ul>

                <div class="card mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <form action="movement-report" method="GET" class="row g-2 align-items-end">
                            <input type="hidden" name="type" value="<%= reportType %>">
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
                                <input type="text" name="search" class="form-control form-control-sm" placeholder="Mã phiếu, SKU, tên vật tư..." value="<%= search %>">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Kho</label>
                                <select name="warehouseId" class="form-select form-select-sm" <%= userBoundToWarehouse ? "disabled" : "" %>>
                                    <option value="">-- Tất cả kho --</option>
                                    <% if (warehouses != null) for (Warehouse wh : warehouses) { %>
                                    <option value="<%= wh.getId() %>" <%= warehouseId != null && warehouseId == wh.getId() ? "selected" : "" %>><%= wh.getWarehouseName() %></option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="col-12 col-md-auto ms-md-auto d-flex gap-2">
                                <button type="submit" class="btn btn-primary btn-sm px-3"><i class="bi bi-funnel-fill me-1"></i>Xem báo cáo</button>
                                <a href="movement-report?type=<%= reportType %>" class="btn btn-outline-secondary btn-sm px-3"><i class="bi bi-arrow-counterclockwise me-1"></i>Đặt lại</a>
                            </div>
                        </form>
                    </div>
                </div>

                <% if (fromDate.isEmpty() || toDate.isEmpty()) { %>
                <div class="empty-state"><i class="bi bi-calendar-range"></i><p>Vui lòng chọn khoảng ngày để xem báo cáo.</p></div>
                <% } else { %>
                <div class="row g-2 mb-3">
                    <div class="col-md-4 col-6"><div class="card border-0 shadow-sm px-3 py-2"><div class="small text-muted">Số dòng phiếu</div><div class="fs-5 fw-bold text-primary"><%= nf.format(totalRows) %></div></div></div>
                    <div class="col-md-4 col-6"><div class="card border-0 shadow-sm px-3 py-2"><div class="small text-muted">Tổng số lượng <%= importReport ? "nhập" : "xuất" %></div><div class="fs-5 fw-bold <%= importReport ? "text-success" : "text-danger" %>"><%= nf.format(totalQuantity) %></div></div></div>
                    <% if (importReport) { %>
                    <div class="col-md-4 col-12"><div class="card border-0 shadow-sm px-3 py-2"><div class="small text-muted">Giá trị nhập mua</div><div class="fs-5 fw-bold text-success"><%= nf.format(totalPurchaseValue) %> đ</div></div></div>
                    <% } %>
                </div>

                <div class="card bg-white">
                    <div class="card-header bg-white py-3 border-bottom"><span class="fw-bold text-slate-800"><i class="bi bi-<%= importReport ? "box-arrow-in-down" : "box-arrow-up-right" %> me-2 text-primary"></i>Từ <%= fromDate %> đến <%= toDate %> (<%= nf.format(totalRows) %> dòng)</span></div>
                    <div class="card-body p-0"><div class="table-responsive">
                        <table id="ticketReportTable" class="table table-hover align-middle mb-0" style="min-width: <%= importReport ? "1280" : "1080" %>px;">
                            <thead class="table-light"><tr>
                                <th class="ps-3">TT</th><th>Ngày <%= importReport ? "nhập" : "xuất" %></th><th>Số phiếu</th><th>Loại</th><th>Mã vật tư</th><th>Tên vật tư</th><th>Đơn vị tính</th><th class="text-end">Số lượng</th>
                                <% if (importReport) { %><th class="text-end">Đơn giá nhập</th><th class="text-end">Thành tiền</th><% } %>
                                <th>Kho <%= importReport ? "nhận" : "xuất" %></th><th><%= importReport ? "Nguồn hàng" : "Điểm đến" %></th>
                            </tr></thead>
                            <tbody>
                            <% if (rows != null && !rows.isEmpty()) { int tt = 1; for (TicketReportRow row : rows) { %>
                                <tr>
                                    <td class="ps-3 small text-muted"><%= tt++ %></td><td class="small"><%= row.getTransactionDate() %></td><td class="font-monospace small"><%= row.getTicketCode() %></td><td class="small"><%= row.getReasonLabel() %></td><td class="font-monospace small"><%= row.getSku() %></td><td class="fw-semibold small"><%= row.getProductName() %></td><td class="small text-muted"><%= row.getUnit() %></td><td class="text-end fw-semibold"><%= nf.format(row.getQuantity()) %></td>
                                    <% if (importReport) { %><td class="text-end"><%= row.hasCost() ? nf.format(row.getUnitCost()) : "—" %></td><td class="text-end fw-semibold text-success"><%= row.hasCost() ? nf.format(row.getTotalCost()) : "—" %></td><% } %>
                                    <td class="small"><%= row.getWarehouseName() == null ? "" : row.getWarehouseName() %></td><td class="small text-muted"><%= row.getPartnerName() == null ? "" : row.getPartnerName() %></td>
                                </tr>
                            <% } } else { %>
                                <tr><td colspan="<%= importReport ? 12 : 10 %>" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không có phiếu <%= importReport ? "nhập" : "xuất" %> đã xác nhận trong khoảng ngày đã chọn.</p></div></td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div></div>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2"><label class="text-muted small mb-0">Hiển thị</label><select id="ticketReportEntriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width:80px;border-radius:8px;"><option value="10" selected>10</option><option value="25">25</option><option value="100">100</option></select><span class="text-muted small">dòng</span></div>
                        <div id="ticketReportPaginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto"></div>
                    </div>
                </div>
                <% } %>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const table = document.getElementById("ticketReportTable"); if (!table) return;
            const rows = Array.from(table.querySelectorAll("tbody tr"));
            if (rows.length === 1 && rows[0].querySelector("td[colspan]")) return;
            const select = document.getElementById("ticketReportEntriesPerPage"), container = document.getElementById("ticketReportPaginationContainer");
            let currentPage = 1, pageSize = parseInt(select.value) || 10;
            function render() {
                const total = rows.length, pages = Math.ceil(total / pageSize); currentPage = Math.min(currentPage, Math.max(1, pages));
                const start = (currentPage - 1) * pageSize, end = Math.min(start + pageSize, total);
                rows.forEach((row, i) => row.style.display = i >= start && i < end ? "" : "none");
                container.innerHTML = "<div class='text-muted small'>Hiển thị từ " + (total ? start + 1 : 0) + " đến " + end + " trong số " + total + " dòng</div>";
                const nav = document.createElement("ul"); nav.className = "pagination pagination-sm mb-0 gap-1";
                function button(label, disabled, action, active) { const li = document.createElement("li"); li.className = "page-item " + (disabled ? "disabled" : "") + (active ? " active" : ""); const a = document.createElement("a"); a.className = "page-link border-0 rounded-2 shadow-none px-3 py-1"; a.href = "javascript:void(0)"; a.innerHTML = label; a.onclick = function(){ if(!disabled){ action(); render(); } }; li.appendChild(a); nav.appendChild(li); }
                button("<i class='bi bi-chevron-left'></i>", currentPage === 1, () => currentPage--, false);
                for (let page = Math.max(1, currentPage - 2); page <= Math.min(pages, Math.max(1, currentPage - 2) + 4); page++) { const p = page; button(p, false, () => currentPage = p, p === currentPage); }
                button("<i class='bi bi-chevron-right'></i>", currentPage === pages || pages === 0, () => currentPage++, false); container.appendChild(nav);
            }
            select.onchange = function(){ pageSize = parseInt(select.value) || 10; currentPage = 1; render(); }; render();
        });
    </script>
</body>
</html>
