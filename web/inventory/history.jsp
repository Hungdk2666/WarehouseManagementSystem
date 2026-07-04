<%@page import="model.User"%>
<%@page import="model.HistoryEntry"%>
<%@page import="model.Warehouse"%>
<%@page import="java.util.List"%>
<%@page import="java.text.SimpleDateFormat"%>
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
    List<HistoryEntry> entries = (List<HistoryEntry>) request.getAttribute("entries");
    List<Warehouse> warehouses = (List<Warehouse>) request.getAttribute("warehouses");
    int currentPage = (int) request.getAttribute("currentPage");
    int totalPages = (int) request.getAttribute("totalPages");
    int totalCount = (int) request.getAttribute("totalCount");
    int pageSize = (int) request.getAttribute("pageSize");

    String search = (String) request.getAttribute("search");
    String transactionType = (String) request.getAttribute("transactionType");
    Integer warehouseId = (Integer) request.getAttribute("warehouseId");
    String startDate = (String) request.getAttribute("startDate");
    String endDate = (String) request.getAttribute("endDate");

    if (search == null) search = "";
    if (transactionType == null) transactionType = "";
    if (startDate == null) startDate = "";
    if (endDate == null) endDate = "";

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    NumberFormat nf = NumberFormat.getInstance(new Locale("vi", "VN"));

    String filterParams = "&search=" + URLEncoder.encode(search, "UTF-8")
            + "&transactionType=" + URLEncoder.encode(transactionType, "UTF-8")
            + (warehouseId != null ? "&warehouseId=" + warehouseId : "")
            + "&startDate=" + URLEncoder.encode(startDate, "UTF-8")
            + "&endDate=" + URLEncoder.encode(endDate, "UTF-8");
    String paginationParams = "&pageSize=" + pageSize + filterParams;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lịch sử xuất nhập kho - WMS</title>
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
                        <h2 class="page-title">Lịch sử xuất nhập kho</h2>
                        <p class="page-subtitle">Theo dõi toàn bộ giao dịch nhập, xuất, chuyển kho và truy vết lịch sử hàng hóa</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/inventory-history?action=export<%= filterParams %>"
                       class="btn btn-success btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-file-earmark-excel"></i> Xuất Excel
                    </a>
                </div>

                <!-- Filters -->
                <div class="card mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <form id="filterForm" action="inventory-history" method="GET" class="row g-2 align-items-end">
                            <div class="col-12 col-md-3">
                                <label class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" name="search" class="form-control form-control-sm"
                                       placeholder="Mã phiếu, mã YC, SKU, tên SP..."
                                       value="<%= search %>">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Loại giao dịch</label>
                                <select name="transactionType" class="form-select form-select-sm">
                                    <option value="">-- Tất cả --</option>
                                    <option value="IMPORT" <%= "IMPORT".equals(transactionType) ? "selected" : "" %>>Nhập mua</option>
                                    <option value="EXPORT" <%= "EXPORT".equals(transactionType) ? "selected" : "" %>>Xuất bán</option>
                                    <option value="TRANSFER_IN" <%= "TRANSFER_IN".equals(transactionType) ? "selected" : "" %>>Nhận chuyển kho</option>
                                    <option value="TRANSFER_OUT" <%= "TRANSFER_OUT".equals(transactionType) ? "selected" : "" %>>Chuyển kho đi</option>
                                    <option value="RETURN" <%= "RETURN".equals(transactionType) ? "selected" : "" %>>Trả hàng</option>
                                    <option value="STOCKTAKE" <%= "STOCKTAKE".equals(transactionType) ? "selected" : "" %>>Kiểm kê điều chỉnh</option>
                                </select>
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Kho</label>
                                <select name="warehouseId" class="form-select form-select-sm">
                                    <option value="">-- Tất cả kho --</option>
                                    <% if (warehouses != null) { for (Warehouse wh : warehouses) { %>
                                    <option value="<%= wh.getId() %>" <%= (warehouseId != null && warehouseId == wh.getId()) ? "selected" : "" %>><%= wh.getWarehouseName() %></option>
                                    <% } } %>
                                </select>
                            </div>
                            <div class="col-6 col-md-auto">
                                <label class="form-label small fw-semibold mb-1">Từ ngày</label>
                                <input type="date" name="startDate" class="form-control form-control-sm" value="<%= startDate %>">
                            </div>
                            <div class="col-6 col-md-auto">
                                <label class="form-label small fw-semibold mb-1">Đến ngày</label>
                                <input type="date" name="endDate" class="form-control form-control-sm" value="<%= endDate %>"
                                       <%= !startDate.isEmpty() ? "min=\"" + startDate + "\"" : "" %>>
                            </div>
                            <div class="col-12 col-md-auto ms-md-auto d-flex gap-2">
                                <button type="submit" class="btn btn-primary btn-sm px-3">
                                    <i class="bi bi-funnel-fill me-1"></i>Lọc
                                </button>
                                <a href="inventory-history" class="btn btn-outline-secondary btn-sm px-3">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>Đặt lại
                                </a>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Summary Cards -->
                <% if (entries != null && !entries.isEmpty()) {
                    int totalIn = 0, totalOut = 0, totalTransfer = 0, totalReturn = 0, totalStocktake = 0;
                    for (HistoryEntry e : entries) {
                        String tt = e.getTransactionType();
                        if ("IMPORT".equals(tt)) totalIn += e.getChangeQuantity();
                        else if ("EXPORT".equals(tt)) totalOut += Math.abs(e.getChangeQuantity());
                        else if ("TRANSFER_IN".equals(tt) || "TRANSFER_OUT".equals(tt)) totalTransfer++;
                        else if ("RETURN".equals(tt)) totalReturn++;
                        else if ("STOCKTAKE".equals(tt)) totalStocktake++;
                    }
                %>
                <div class="row g-2 mb-3">
                    <div class="col-auto">
                        <div class="card text-center px-4 py-2">
                            <div class="small text-muted">Tổng GD</div>
                            <div class="fw-bold text-slate-800"><%= totalCount %></div>
                        </div>
                    </div>
                </div>
                <% } %>

                <!-- Table -->
                <div class="card bg-white">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                        <span class="fw-bold text-slate-800">
                            <i class="bi bi-clock-history me-2 text-primary"></i>Lịch sử giao dịch (<%= totalCount %> bản ghi)
                        </span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light" style="position: sticky; top: 0; z-index: 1;">
                                    <tr>
                                        <th class="ps-3">Thời gian</th>
                                        <th>Loại</th>
                                        <th>Mã phiếu</th>
                                        <th>Mã YC</th>
                                        <th>Sản phẩm</th>
                                        <th class="text-center">SL thay đổi</th>
                                        <th class="text-center">Tồn sau GD</th>
                                        <th>Kho</th>
                                        <th>Đối tác</th>
                                        <th>Người thực hiện</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (entries != null && !entries.isEmpty()) {
                                            for (HistoryEntry e : entries) {
                                                String ticketUrl = "";
                                                if (e.getTicketCode() != null) {
                                                    if ("IN".equals(e.getTicketType())) {
                                                        ticketUrl = request.getContextPath() + "/warehouse/import-ticket?action=detail&id=" + e.getReferenceId();
                                                    } else if ("OUT".equals(e.getTicketType())) {
                                                        ticketUrl = request.getContextPath() + "/warehouse/export-ticket?action=detail&id=" + e.getReferenceId();
                                                    }
                                                }
                                    %>
                                    <tr>
                                        <td class="ps-3 text-muted small"><%= e.getCreatedAt() != null ? sdf.format(e.getCreatedAt()) : "" %></td>
                                        <td>
                                            <span class="badge <%= e.getTransactionTypeBadgeClass() %> px-2 py-1" style="font-size: 0.75rem;">
                                                <%= e.getTransactionTypeLabel() %>
                                            </span>
                                        </td>
                                        <td>
                                            <% if (!ticketUrl.isEmpty()) { %>
                                            <a href="<%= ticketUrl %>" class="text-decoration-none fw-semibold font-monospace small"><%= e.getTicketCode() %></a>
                                            <% } else { %>
                                            <span class="text-muted small">-</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <% if (e.getRequestCode() != null) { %>
                                            <span class="font-monospace small"><%= e.getRequestCode() %></span>
                                            <% } else { %>
                                            <span class="text-muted small">-</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <div class="fw-semibold small"><%= e.getProductName() != null ? e.getProductName() : "" %></div>
                                            <div class="text-muted" style="font-size: 0.7rem;"><%= e.getSku() != null ? e.getSku() : "" %></div>
                                        </td>
                                        <td class="text-center fw-bold <%= e.getChangeQuantity() > 0 ? "text-success" : e.getChangeQuantity() < 0 ? "text-danger" : "" %>">
                                            <%= e.getChangeQuantity() > 0 ? "+" : "" %><%= e.getChangeQuantity() %>
                                        </td>
                                        <td class="text-center small"><%= e.getBalanceQuantity() %></td>
                                        <td class="small"><%= e.getWarehouseName() != null ? e.getWarehouseName() : "" %></td>
                                        <td class="small"><%= e.getPartnerName() != null ? e.getPartnerName() : "-" %></td>
                                        <td class="small"><%= e.getCreatedByName() != null ? e.getCreatedByName() : "-" %></td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="10" class="p-0">
                                            <div class="empty-state"><i class="bi bi-clock-history"></i><p>Không tìm thấy giao dịch nào phù hợp với bộ lọc.</p></div>
                                        </td>
                                    </tr>
                                    <%
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <% if (totalCount > 0) {
                        int startRecord = (currentPage - 1) * pageSize + 1;
                        int endRecord = Math.min(currentPage * pageSize, totalCount);
                    %>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                            <label class="text-muted small mb-0 flex-shrink-0">Hiển thị</label>
                            <select name="pageSize" form="filterForm" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;" onchange="document.getElementById('filterForm').submit();">
                                <option value="10" <%= pageSize == 10 ? "selected" : "" %>>10</option>
                                <option value="25" <%= pageSize == 25 ? "selected" : "" %>>25</option>
                                <option value="100" <%= pageSize == 100 ? "selected" : "" %>>100</option>
                            </select>
                            <span class="text-muted small">dòng</span>
                        </div>
                        <div class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto">
                            <span class="text-muted small">Hiển thị <%= startRecord %>–<%= endRecord %> / <%= totalCount %> bản ghi</span>
                            <% if (totalPages > 1) { %>
                            <nav aria-label="Page navigation" class="m-0">
                                <ul class="pagination pagination-sm m-0 gap-1">
                                    <li class="page-item <%= currentPage == 1 ? "disabled" : "" %>">
                                        <a class="page-link border-0 rounded-2 shadow-none px-2.5 py-1.5" href="inventory-history?page=<%= currentPage - 1 %><%= paginationParams %>" aria-label="Previous">
                                            <i class="bi bi-chevron-left"></i>
                                        </a>
                                    </li>
                                    <%
                                        int startP = Math.max(1, currentPage - 2);
                                        int endP = Math.min(totalPages, currentPage + 2);
                                        if (currentPage <= 3) endP = Math.min(totalPages, 5);
                                        if (currentPage >= totalPages - 2) startP = Math.max(1, totalPages - 4);
                                    %>
                                    <% if (startP > 1) { %>
                                    <li class="page-item">
                                        <a class="page-link border-0 rounded-2 shadow-none px-3 py-1.5" href="inventory-history?page=1<%= paginationParams %>">1</a>
                                    </li>
                                    <% if (startP > 2) { %>
                                    <li class="page-item disabled"><span class="page-link border-0 bg-transparent px-2">...</span></li>
                                    <% } %>
                                    <% } %>
                                    <% for (int i = startP; i <= endP; i++) { %>
                                    <li class="page-item <%= currentPage == i ? "active" : "" %>">
                                        <a class="page-link border-0 rounded-2 shadow-none px-3 py-1.5" href="inventory-history?page=<%= i %><%= paginationParams %>"><%= i %></a>
                                    </li>
                                    <% } %>
                                    <% if (endP < totalPages) { %>
                                    <% if (endP < totalPages - 1) { %>
                                    <li class="page-item disabled"><span class="page-link border-0 bg-transparent px-2">...</span></li>
                                    <% } %>
                                    <li class="page-item">
                                        <a class="page-link border-0 rounded-2 shadow-none px-3 py-1.5" href="inventory-history?page=<%= totalPages %><%= paginationParams %>"><%= totalPages %></a>
                                    </li>
                                    <% } %>
                                    <li class="page-item <%= currentPage == totalPages ? "disabled" : "" %>">
                                        <a class="page-link border-0 rounded-2 shadow-none px-2.5 py-1.5" href="inventory-history?page=<%= currentPage + 1 %><%= paginationParams %>" aria-label="Next">
                                            <i class="bi bi-chevron-right"></i>
                                        </a>
                                    </li>
                                </ul>
                            </nav>
                            <% } %>
                        </div>
                    </div>
                    <% } %>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
