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
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h2 class="fw-bold mb-1"><%= row.getProductName() %>
                            <span class="badge bg-secondary bg-opacity-10 text-secondary fs-6"><%= row.getSku() %></span>
                        </h2>
                        <p class="text-muted small mb-0">Tồn tại kho <strong><%= row.getWarehouseName() %></strong></p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/inventory" class="btn btn-outline-secondary btn-sm">
                        <i class="bi bi-arrow-left"></i> Danh sách
                    </a>
                </div>

                <!-- Summary -->
                <div class="row g-3 mb-4">
                    <div class="col-md-3"><div class="card shadow-sm border-0"><div class="card-body">
                        <div class="text-muted small">Tồn bán được</div>
                        <div class="display-6 fw-bold <%= row.isLowStock() ? "text-warning" : "text-success" %>"><%= row.getQuantity() %></div>
                        <small class="text-muted"><%= row.getUnit() %></small>
                    </div></div></div>
                    <div class="col-md-3"><div class="card shadow-sm border-0"><div class="card-body">
                        <div class="text-muted small">Hàng cách ly (hỏng)</div>
                        <div class="display-6 fw-bold text-danger"><%= row.getQuarantineQuantity() %></div>
                    </div></div></div>
                    <div class="col-md-3"><div class="card shadow-sm border-0"><div class="card-body">
                        <div class="text-muted small">Đang chuyển kho</div>
                        <div class="display-6 fw-bold text-info"><%= row.getInTransitQuantity() %></div>
                    </div></div></div>
                    <div class="col-md-3"><div class="card shadow-sm border-0"><div class="card-body">
                        <div class="text-muted small">Đã mất (LOST)</div>
                        <div class="display-6 fw-bold text-muted"><%= row.getLostQuantity() %></div>
                    </div></div></div>
                </div>

                <ul class="nav nav-tabs" role="tablist">
                    <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#serialsTab">Serial (<%= serials == null ? 0 : serials.size() %>)</a></li>
                    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#ledgerTab">Lịch sử (30 dòng)</a></li>
                </ul>

                <div class="tab-content">
                    <!-- Serial tab -->
                    <div class="tab-pane fade show active" id="serialsTab">
                        <div class="card shadow-sm border-0 border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle">
                                    <thead class="table-light">
                                        <tr><th>Serial</th><th>Trạng thái kho</th><th>Chất lượng</th><th>Thêm vào lúc</th></tr>
                                    </thead>
                                    <tbody>
                                    <% if (serials == null || serials.isEmpty()) { %>
                                        <tr><td colspan="4" class="text-center text-muted p-4">Không có serial nào.</td></tr>
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
                                            <td><span class="badge bg-<%= b %>"><%= it.getStatus() %></span></td>
                                            <td><span class="badge bg-<%= c %>"><%= it.getItemCondition() %></span></td>
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
                        <div class="card shadow-sm border-0 border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle">
                                    <thead class="table-light">
                                        <tr><th>Loại GD</th><th>Ref</th><th class="text-end">Thay đổi</th><th class="text-end">Số dư</th><th>Người</th><th>Lúc</th></tr>
                                    </thead>
                                    <tbody>
                                    <% if (ledger == null || ledger.isEmpty()) { %>
                                        <tr><td colspan="6" class="text-center text-muted p-4">Chưa có giao dịch.</td></tr>
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
