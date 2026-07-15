<%@page import="model.InventoryRow"%>
<%@page import="model.ProductItem"%>
<%@page import="dao.InventoryDAO.LedgerEntry"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    private String h(Object value) {
        if (value == null) return "";
        return value.toString().replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("INVENTORY_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    InventoryRow row = (InventoryRow) request.getAttribute("row");
    List<ProductItem> serials = (List<ProductItem>) request.getAttribute("serials");
    List<ProductItem> exportedOrLostSerials = (List<ProductItem>) request.getAttribute("exportedOrLostSerials");
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

                
                <div class="row g-3 mb-3">
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-seam"></i></div>
                        <div><div class="stat-label">Hàng mới</div><h3 class="stat-value"><%= row.getNewQuantity() %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-arrow-repeat"></i></div>
                        <div><div class="stat-label">Hàng cũ</div><h3 class="stat-value"><%= row.getUsedQuantity() %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-danger bg-opacity-10 text-danger"><i class="bi bi-shield-exclamation"></i></div>
                        <div><div class="stat-label">Hàng hỏng</div><h3 class="stat-value"><%= row.getQuarantineQuantity() %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-boxes"></i></div>
                        <div><div class="stat-label">Tổng hàng</div><h3 class="stat-value"><%= row.getTotalQuantity() %></h3><small class="text-muted"><%= row.getUnit() %></small></div>
                    </div></div></div>
                    <div class="col-12"><div class="d-flex flex-wrap gap-3 rounded-3 border bg-light px-3 py-2 small">
                        <span><i class="bi bi-truck text-info me-1"></i>Đang chuyển: <strong><%= row.getInTransitQuantity() %></strong></span>
                        <span><i class="bi bi-dash-circle-fill text-secondary me-1"></i>Thất thoát: <strong><%= row.getLostQuantity() %></strong></span>
                    </div></div>
                </div>
                <ul class="nav nav-tabs" role="tablist">
                    <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#serialsTab">Serial · <%= serials == null ? 0 : serials.size() %></a></li>
                    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#goneTab">Đã xuất / Đã mất · <%= exportedOrLostSerials == null ? 0 : exportedOrLostSerials.size() %></a></li>
                    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#ledgerTab">Lịch sử · 30 dòng</a></li>
                </ul>

                <div class="tab-content">
                    
                    <div class="tab-pane fade show active" id="serialsTab">
                        <div class="card border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle">
                                    <thead class="table-light">
                                        <tr><th>Mã WMS</th><th>Serial nhà sản xuất</th><th>Trạng thái kho</th><th>Chất lượng</th><th>Thêm vào lúc</th></tr>
                                    </thead>
                                    <tbody>
                                    <% if (serials == null || serials.isEmpty()) { %>
                                        <tr><td colspan="5" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không có serial nào.</p></div></td></tr>
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
                                            <td><span class="font-monospace"><%= it.getManufacturerSerial() == null ? "—" : h(it.getManufacturerSerial()) %></span></td>
                                            <td><span class="badge bg-<%= b %>"><%
                                                if ("IN_STOCK".equals(it.getStatus())) out.print("Trong kho");
                                                else if ("EXPORTED".equals(it.getStatus())) out.print("Đã xuất");
                                                else if ("IN_TRANSIT".equals(it.getStatus())) out.print("Đang chuyển");
                                                else if ("QUARANTINE".equals(it.getStatus())) out.print("Hàng hỏng");
                                                else if ("LOST".equals(it.getStatus())) out.print("Thất thoát");
                                                else out.print(it.getStatus());
                                            %></span></td>
                                            <td><span class="badge bg-<%= c %>"><%
                                                if ("NEW".equals(it.getItemCondition())) out.print("Mới");
                                                else if ("USED".equals(it.getItemCondition())) out.print("Hàng cũ");
                                                else if ("DAMAGED".equals(it.getItemCondition())) out.print("Hàng hỏng");
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

                    
                    <div class="tab-pane fade" id="goneTab">
                        <div class="card border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle">
                                    <thead class="table-light">
                                        <tr><th>Mã WMS</th><th>Serial nhà sản xuất</th><th>Trạng thái</th><th>Chất lượng</th><th>Thêm vào lúc</th></tr>
                                    </thead>
                                    <tbody>
                                    <% if (exportedOrLostSerials == null || exportedOrLostSerials.isEmpty()) { %>
                                        <tr><td colspan="5" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Chưa có serial nào đã xuất hoặc đã mất.</p></div></td></tr>
                                    <% } else { for (ProductItem it : exportedOrLostSerials) {
                                        String b = "secondary";
                                        if ("EXPORTED".equals(it.getStatus())) b = "primary";
                                        else if ("IN_TRANSIT".equals(it.getStatus())) b = "info";
                                        else if ("LOST".equals(it.getStatus())) b = "dark";

                                        String c = "secondary";
                                        if ("NEW".equals(it.getItemCondition())) c = "success";
                                        else if ("USED".equals(it.getItemCondition())) c = "warning";
                                        else if ("DAMAGED".equals(it.getItemCondition())) c = "danger";
                                    %>
                                        <tr>
                                            <td><strong><%= it.getSerialNumber() %></strong></td>
                                            <td><span class="font-monospace"><%= it.getManufacturerSerial() == null ? "—" : h(it.getManufacturerSerial()) %></span></td>
                                            <td><span class="badge bg-<%= b %>"><%
                                                if ("EXPORTED".equals(it.getStatus())) out.print("Đã xuất");
                                                else if ("IN_TRANSIT".equals(it.getStatus())) out.print("Đang chuyển");
                                                else if ("LOST".equals(it.getStatus())) out.print("Thất thoát");
                                                else out.print(it.getStatus());
                                            %></span></td>
                                            <td><span class="badge bg-<%= c %>"><%
                                                if ("NEW".equals(it.getItemCondition())) out.print("Mới");
                                                else if ("USED".equals(it.getItemCondition())) out.print("Hàng cũ");
                                                else if ("DAMAGED".equals(it.getItemCondition())) out.print("Hàng hỏng");
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

                    
                    <div class="tab-pane fade" id="ledgerTab">
                        <div class="card border-top-0 rounded-0 rounded-bottom">
                            <div class="card-body p-0">
                                <table class="table table-sm mb-0 align-middle">
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
                                            <%
                                                String tt = e.transactionType;
                                                String ttLabel = "IMPORT".equals(tt) ? "Nhập mua"
                                                        : "EXPORT".equals(tt) ? "Xuất bán"
                                                        : "TRANSFER_IN".equals(tt) ? "Nhận chuyển kho"
                                                        : "TRANSFER_OUT".equals(tt) ? "Chuyển kho đi"
                                                        : "RETURN".equals(tt) ? "Trả hàng"
                                                        : "TRANSFER_RETURN".equals(tt) ? "Nhập trả chuyển kho"
                                                        : "TRANSFER_RETURN_OUT".equals(tt) ? "Xuất trả chuyển kho"
                                                        : "STOCKTAKE".equals(tt) ? "Kiểm kê điều chỉnh" : tt;
                                                String documentCode = "STOCKTAKE".equals(tt) ? e.stocktakeCode : e.ticketCode;
                                                String documentUrl = "";
                                                if ("STOCKTAKE".equals(tt) && e.stocktakeCode != null) {
                                                    documentUrl = request.getContextPath() + "/warehouse/stocktake?action=detail&id=" + e.referenceId;
                                                } else if (e.ticketCode != null && "IN".equals(e.ticketType)) {
                                                    documentUrl = request.getContextPath() + "/warehouse/import-ticket?action=detail&id=" + e.referenceId;
                                                } else if (e.ticketCode != null && "OUT".equals(e.ticketType)) {
                                                    documentUrl = request.getContextPath() + "/warehouse/export-ticket?action=detail&id=" + e.referenceId;
                                                }
                                            %>
                                            <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= ttLabel %></span></td>
                                            <td><% if (!documentUrl.isEmpty()) { %><a href="<%= documentUrl %>" class="font-monospace text-decoration-none"><%= documentCode %></a><% } else { %>—<% } %></td>
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
