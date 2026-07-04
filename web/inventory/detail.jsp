<%@page import="model.InventoryRow"%>
<%@page import="model.ProductItem"%>
<%@page import="dao.InventoryDAO.LedgerEntry"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("INVENTORY_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    InventoryRow row = (InventoryRow) request.getAttribute("row");
    List<ProductItem> serials = (List<ProductItem>) request.getAttribute("serials");
    List<LedgerEntry> ledger = (List<LedgerEntry>) request.getAttribute("ledger");
    if (row == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/inventory");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tồn kho <%= row.getSku() %> @ <%= row.getWarehouseName() %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=inventory-layout-3">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="page-header">
                    <div>
                        <h2 class="page-title"><%= row.getProductName() %>
                            <span class="badge bg-secondary bg-opacity-10 text-secondary fs-6"><%= row.getSku() %></span>
                        </h2>
                        <p class="page-subtitle">Tồn tại kho <strong><%= row.getWarehouseName() %></strong></p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/inventory" class="btn btn-outline-secondary btn-sm">
                        <i class="bi bi-arrow-left"></i> Danh sách
                    </a>
                </div>

                <!-- Summary -->
                <div class="row g-3 mb-4">
                    <div class="col-md-3"><div class="card"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon <%= row.isLowStock() ? "bg-warning" : "bg-success" %> bg-opacity-10 <%= row.isLowStock() ? "text-warning" : "text-success" %>"><i class="bi bi-box-seam-fill"></i></div>
                        <div><div class="stat-label">Tồn bán được</div><h3 class="stat-value"><%= row.getQuantity() %></h3><small class="text-muted"><%= row.getUnit() %></small></div>
                    </div></div></div>
                    <div class="col-md-3"><div class="card"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-danger bg-opacity-10 text-danger"><i class="bi bi-x-octagon-fill"></i></div>
                        <div><div class="stat-label">Hàng lỗi</div><h3 class="stat-value"><%= row.getQuarantineQuantity() %></h3></div>
                    </div></div></div>
                    <div class="col-md-3"><div class="card"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-truck"></i></div>
                        <div><div class="stat-label">Đang chuyển kho</div><h3 class="stat-value"><%= row.getInTransitQuantity() %></h3></div>
                    </div></div></div>
                    <div class="col-md-3"><div class="card"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-secondary bg-opacity-10 text-secondary"><i class="bi bi-dash-circle-fill"></i></div>
                        <div><div class="stat-label">Thất thoát</div><h3 class="stat-value"><%= row.getLostQuantity() %></h3></div>
                    </div></div></div>
                </div>

                <ul class="nav nav-tabs" role="tablist">
                    <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#serialsTab">Serial (<%= serials == null ? 0 : serials.size() %>)</a></li>
                    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#ledgerTab">Lịch sử (30 dòng)</a></li>
                </ul>

                <div class="tab-content">
                    <!-- Serial tab -->
                    <div class="tab-pane fade show active" id="serialsTab">
                        <div class="card border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle inventory-detail-table">
                                    <colgroup><col class="inventory-detail-col-serial"><col class="inventory-detail-col-status"><col class="inventory-detail-col-condition"><col class="inventory-detail-col-time"></colgroup>
                                    <thead class="table-light">
                                        <tr><th>Serial</th><th>Trạng thái kho</th><th>Chất lượng</th><th>Thêm vào lúc</th></tr>
                                    </thead>
                                    <tbody>
                                    <% if (serials == null || serials.isEmpty()) { %>
                                        <tr><td colspan="4" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không có serial nào.</p></div></td></tr>
                                    <% } else { for (ProductItem it : serials) {
                                        String b = "secondary";
                                        if ("IN_STOCK".equals(it.getStatus())) b = "success";
                                        else if ("EXPORTED".equals(it.getStatus())) b = "primary";
                                        else if ("IN_TRANSIT".equals(it.getStatus())) b = "info";
                                        else if ("QUARANTINE".equals(it.getStatus())) b = "danger";
                                        else if ("LOST".equals(it.getStatus())) b = "dark";

                                        String c = "secondary";
                                        if ("NEW".equals(it.getItemCondition())) c = "success";
                                        else if ("USED".equals(it.getItemCondition())) c = "warning";
                                        else if ("DAMAGED".equals(it.getItemCondition())) c = "danger";
                                    %>
                                        <tr>
                                            <td><strong><%= it.getSerialNumber() %></strong></td>
                                            <td><span class="badge bg-<%= b %>"><%
                                                if ("IN_STOCK".equals(it.getStatus())) out.print("Trong kho");
                                                else if ("EXPORTED".equals(it.getStatus())) out.print("Đã xuất");
                                                else if ("IN_TRANSIT".equals(it.getStatus())) out.print("Đang chuyển");
                                                else if ("QUARANTINE".equals(it.getStatus())) out.print("Hàng lỗi");
                                                else if ("LOST".equals(it.getStatus())) out.print("Thất thoát");
                                                else out.print(it.getStatus());
                                            %></span></td>
                                            <td><span class="badge bg-<%= c %>"><%
                                                if ("NEW".equals(it.getItemCondition())) out.print("Mới");
                                                else if ("USED".equals(it.getItemCondition())) out.print("Đã qua sử dụng");
                                                else if ("DAMAGED".equals(it.getItemCondition())) out.print("Lỗi");
                                                else out.print(it.getItemCondition());
                                            %></span></td>
                                            <td><%= it.getCreatedAt() %></td>
                                        </tr>
                                    <% } } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- Ledger tab -->
                    <div class="tab-pane fade" id="ledgerTab">
                        <div class="card border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle inventory-ledger-table">
                                    <colgroup><col class="inventory-ledger-col-type"><col class="inventory-ledger-col-reference"><col class="inventory-ledger-col-change"><col class="inventory-ledger-col-balance"><col class="inventory-ledger-col-user"><col class="inventory-ledger-col-time"></colgroup>
                                    <thead class="table-light">
                                        <tr><th>Loại giao dịch</th><th>Mã phiếu</th><th class="text-end">Thay đổi</th><th class="text-end">Tồn sau</th><th>Người thực hiện</th><th>Thời gian</th></tr>
                                    </thead>
                                    <tbody>
                                    <% if (ledger == null || ledger.isEmpty()) { %>
                                        <tr><td colspan="6" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Chưa có giao dịch.</p></div></td></tr>
                                    <% } else { for (LedgerEntry e : ledger) {
                                        String cls = e.changeQuantity > 0 ? "text-success" : (e.changeQuantity < 0 ? "text-danger" : "text-muted");
                                    %>
                                        <tr>
                                            <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= e.transactionType %></span></td>
                                            <td>#<%= e.referenceId %></td>
                                            <td class="text-end <%= cls %>"><strong><%= e.changeQuantity > 0 ? "+" + e.changeQuantity : e.changeQuantity %></strong></td>
                                            <td class="text-end"><%= e.balanceQuantity %></td>
                                            <td><%= e.createdByName == null ? "—" : e.createdByName %></td>
                                            <td class="small text-muted"><%= e.createdAt %></td>
                                        </tr>
                                    <% } } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
