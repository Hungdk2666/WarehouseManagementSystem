<%@page import="model.Ticket"%>
<%@page import="model.TicketDetail"%>
<%@page import="model.User"%>
<%@page import="model.ProductItem"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
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
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_VIEW_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Ticket ticket = (Ticket) request.getAttribute("ticket");
    if (ticket == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/import-ticket?action=list");
        return;
    }
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_IN");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_IN");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi tiết Phiếu nhập kho - #<%= ticket.getTicketCode() %></title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=detail-grid-20260714">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Chi tiết Phiếu nhập kho</h2>
                        <p class="page-subtitle">Xem danh sách sản phẩm và xác nhận nhập kho cho Phiếu nhập kho #<%= ticket.getTicketCode() %></p>
                    </div>
                    <a href="import-ticket?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại danh sách
                    </a>
                </div>

                <div class="card bg-white mb-4">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin Phiếu nhập kho</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="detail-grid">
                            <div class="detail-item">
                                <label class="text-muted small d-block">Mã Phiếu nhập kho</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getTicketCode() %></span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Mã Yêu cầu liên kết</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getRequestCode() %></span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Trạng thái</label>
                                <%
                                    String statusChipCls = "chip-muted";
                                    String displayTStatus = ticket.getStatus();
                                    if ("DRAFT".equals(ticket.getStatus())) { statusChipCls = "chip-warning"; displayTStatus = "BẢN NHÁP"; }
                                    else if ("CONFIRMED".equals(ticket.getStatus())) { statusChipCls = "chip-success"; displayTStatus = "ĐÃ XÁC NHẬN"; }
                                    else if ("CANCELLED".equals(ticket.getStatus())) { statusChipCls = "chip-muted"; displayTStatus = "ĐÃ HỦY"; }
                                %>
                                <span class="status-chip <%= statusChipCls %>"><%= displayTStatus %></span>
                            </div>
                            
                            <div class="detail-item">
                                <label class="text-muted small d-block">Người tạo</label>
                                <span class="text-slate-700"><%= ticket.getKeeperFullName() %></span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Ngày tạo</label>
                                <span class="text-slate-700"><%= ticket.getCreatedAt() %></span>
                            </div>
                            
                            <% if (ticket.getConfirmedBy() != null) { %>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Người xác nhận</label>
                                <span class="text-slate-700"><%= ticket.getConfirmedByFullName() %></span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Thời gian xác nhận</label>
                                <span class="text-slate-700"><%= ticket.getConfirmedAt() %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card bg-white mb-4">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-check me-2 text-primary"></i>Sản phẩm thực nhận</h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table align-middle text-center mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th class="text-start ps-4">Tên sản phẩm</th>
                                    <th>SKU</th>
                                    <th>Đơn vị</th>
                                    <th>SL thực tế nhận</th>
                                    <th>Tình trạng</th>
                                    <th>Đơn giá thực tế</th>
                                    <th>Thành tiền</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    double totalCost = 0;
                                    if (ticket.getDetails() != null && !ticket.getDetails().isEmpty()) {
                                        int index = 1;
                                        for (TicketDetail d : ticket.getDetails()) {
                                            double itemCost = d.getQuantity() * (d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0);
                                            totalCost += itemCost;
                                %>
                                <tr>
                                    <td><%= index++ %></td>
                                    <td class="text-start ps-4 fw-semibold"><%= d.getProductName() %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                    <td><%= d.getUnit() %></td>
                                    <td class="fw-bold"><%= d.getQuantity() %></td>
                                    <td>
                                        <%
                                            String cond = ticket.getRequestedCondition();
                                            String condChipCls = "chip-success";
                                            String displayCond = "MỚI";
                                            if ("DAMAGED".equals(cond)) { condChipCls = "chip-danger"; displayCond = "LỖI"; }
                                            else if ("USED".equals(cond)) { condChipCls = "chip-warning"; displayCond = "HÀNG CŨ"; }
                                        %>
                                        <span class="status-chip <%= condChipCls %>"><%= displayCond %></span>
                                    </td>
                                    <td><%= String.format("%,.0f", d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0) %> VND</td>
                                    <td class="fw-bold"><%= String.format("%,.0f", itemCost) %> VND</td>
                                </tr>
                                <%
                                        }
                                    }
                                %>
                                <tr class="table-light fw-bold">
                                    <td colspan="7" class="text-end pe-4">Tổng giá trị thực tế:</td>
                                    <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    
                </div>

                <%
                    List<ProductItem> importedSerials = (List<ProductItem>) request.getAttribute("importedSerials");
                    if (importedSerials != null && !importedSerials.isEmpty()) {
                %>
                <div class="card bg-white mb-4">
                    <div class="card-header bg-light py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-success"><i class="bi bi-qr-code-scan me-2"></i>Mã vạch & Số Serial đã tạo</h5>
                        <button class="btn btn-success btn-sm d-inline-flex align-items-center gap-1" onclick="printBarcodes()">
                            <i class="bi bi-printer-fill"></i> In tất cả nhãn mã vạch
                        </button>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3" id="barcode-list-container">
                            <% for (ProductItem item : importedSerials) { %>
                            <div class="col-md-4 col-sm-6 text-center barcode-card-item mb-2">
                                <div class="border rounded p-3 bg-light">
                                    <div class="fw-semibold text-slate-800 small text-truncate mb-1" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                    <div class="text-muted" style="font-size: 10px;">Mã WMS</div>
                                    <svg class="barcode-svg" data-value="<%= item.getSerialNumber() %>"></svg>
                                    <% if (item.getManufacturerSerial() != null) { %>
                                    <div class="text-muted small mt-1" style="font-size: 10px;">Serial hãng: <span class="font-monospace"><%= h(item.getManufacturerSerial()) %></span></div>
                                    <% } %>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
                
                <div class="d-none">
                    <div id="printable-barcodes-section">
                        <div style="display: flex; flex-wrap: wrap; justify-content: space-around; padding: 20px; font-family: 'Inter', sans-serif;">
                            <% for (ProductItem item : importedSerials) { %>
                            <div style="border: 1px solid #ccc; border-radius: 4px; padding: 15px; margin: 10px; background-color: #fff; text-align: center; width: 280px; page-break-inside: avoid; box-sizing: border-box;">
                                <div style="font-weight: bold; color: #333; margin-bottom: 5px; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                <div style="font-size: 9px; color: #666;">Mã WMS</div>
                                <svg class="printable-barcode-svg" data-value="<%= item.getSerialNumber() %>" style="max-width: 100%; height: auto;"></svg>
                                <% if (item.getManufacturerSerial() != null) { %>
                                <div style="font-size: 9px; color: #666; margin-top: 3px;">Serial hãng: <%= h(item.getManufacturerSerial()) %></div>
                                <% } %>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
                <script>
                    document.addEventListener("DOMContentLoaded", function() {

                        document.querySelectorAll(".barcode-svg").forEach(function(el) {
                            const val = el.getAttribute("data-value");
                            JsBarcode(el, val, {
                                format: "CODE128",
                                width: 1.5,
                                height: 40,
                                displayValue: true,
                                fontSize: 11
                            });
                        });
                        

                        document.querySelectorAll(".printable-barcode-svg").forEach(function(el) {
                            const val = el.getAttribute("data-value");
                            JsBarcode(el, val, {
                                format: "CODE128",
                                width: 1.1,
                                height: 35,
                                displayValue: true,
                                fontSize: 11
                            });
                        });
                    });
                    
                    function printBarcodes() {
                        const printContent = document.getElementById("printable-barcodes-section").innerHTML;
                        const originalContent = document.body.innerHTML;
                        

                        document.body.innerHTML = '<div>' + printContent + '</div>';
                        window.print();
                        

                        document.body.innerHTML = originalContent;
                        window.location.reload();
                    }
                </script>
                <% } %>


            </div>
        </div>
    </div>
</body>
</html>
