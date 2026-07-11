<%@page import="model.Ticket"%>
<%@page import="model.TicketDetail"%>
<%@page import="model.User"%>
<%@page import="model.ProductItem"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_VIEW_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Ticket ticket = (Ticket) request.getAttribute("ticket");
    if (ticket == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
        return;
    }
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_OUT");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_OUT");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi tiết phiếu xuất kho - #<%= ticket.getTicketCode() %></title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=detail-grid-20260714">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Chi tiết phiếu xuất kho</h2>
                        <p class="text-muted small mb-0">Xem chi tiết sản phẩm và xác nhận xuất kho thực tế cho Phiếu xuất kho #<%= ticket.getTicketCode() %></p>
                    </div>
                    <a href="export-ticket?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại danh sách
                    </a>
                </div>

                <div class="card bg-white mb-4">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin phiếu xuất kho</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="detail-grid">
                            <div class="detail-item">
                                <label class="text-muted small d-block">Mã phiếu xuất</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getTicketCode() %></span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Mã yêu cầu liên kết</label>
                                <a href="export-request?action=detail&id=<%= ticket.getRequestId() %>" class="fw-bold text-slate-800 text-decoration-none">
                                    #<%= ticket.getRequestCode() %>
                                </a>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Trạng thái</label>
                                <%
                                    String statusBadge = "bg-secondary text-secondary";
                                    String displayStatus = ticket.getStatus();
                                    if ("DRAFT".equals(ticket.getStatus())) {
                                        statusBadge = "bg-warning text-warning";
                                        displayStatus = "Bản nháp";
                                    } else if ("IN_TRANSIT".equals(ticket.getStatus())) {
                                        statusBadge = "bg-info text-info";
                                        displayStatus = "Đang vận chuyển";
                                    } else if ("CONFIRMED".equals(ticket.getStatus())) {
                                        statusBadge = "bg-success text-success";
                                        displayStatus = "Đã xác nhận";
                                    } else if ("CANCELLED".equals(ticket.getStatus())) {
                                        statusBadge = "bg-danger text-danger";
                                        displayStatus = "Đã hủy";
                                    }
                                %>
                                <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayStatus %></span>
                            </div>
                            
                            <div class="detail-item">
                                <label class="text-muted small d-block">Điểm nhận / Đối tác</label>
                                <span class="fw-semibold text-slate-700"><%= ticket.getPartnerName() %></span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Lý do xuất</label>
                                <span class="badge bg-light text-dark border">
                                    <%
                                        if ("TRANSFER".equals(ticket.getRequestReason())) out.print("CHUYỂN KHO");
                                        else if ("CUSTOMER_SALE".equals(ticket.getRequestReason())) out.print("BÁN HÀNG");
                                        else if ("DISPLAY".equals(ticket.getRequestReason())) out.print("TRƯNG BÀY");
                                        else if ("WARRANTY".equals(ticket.getRequestReason())) out.print("BẢO HÀNH");
                                        else out.print(ticket.getRequestReason() != null ? ticket.getRequestReason() : "-");
                                    %>
                                </span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Tình trạng xuất</label>
                                <span class="badge bg-light text-dark border">
                                    <%
                                        if ("DAMAGED".equals(ticket.getRequestedCondition())) out.print("Hàng hỏng (DAMAGED)");
                                        else if ("USED".equals(ticket.getRequestedCondition())) out.print("Hàng Cũ (USED)");
                                        else out.print("Hàng Mới (NEW)");
                                    %>
                                </span>
                            </div>
                            <div class="detail-item">
                                <label class="text-muted small d-block">Người tạo (Thủ kho)</label>
                                <span class="text-slate-700"><%= ticket.getKeeperFullName() %></span>
                            </div>
                            
                            <div class="detail-item">
                                <label class="text-muted small d-block">Thời gian tạo</label>
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
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-check me-2 text-primary"></i>Danh sách sản phẩm xuất kho</h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table align-middle text-center mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th class="text-start ps-4">Tên sản phẩm</th>
                                    <th>SKU</th>
                                    <th>Đơn vị</th>
                                    <th>Số lượng xuất thực tế</th>
                                    <th>Đơn giá (Tạm tính)</th>
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
                                        <% if ("CONFIRMED".equals(ticket.getStatus()) || "IN_TRANSIT".equals(ticket.getStatus())) { %>
                                            <%= String.format("%,.0f", d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0) %> VND
                                        <% } else { %>
                                            <span class="text-muted small">Chờ xác nhận</span>
                                        <% } %>
                                    </td>
                                    <td class="fw-bold">
                                        <% if ("CONFIRMED".equals(ticket.getStatus()) || "IN_TRANSIT".equals(ticket.getStatus())) { %>
                                            <%= String.format("%,.0f", itemCost) %> VND
                                        <% } else { %>
                                            <span class="text-muted small">Chờ xác nhận</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <%
                                        }
                                    }
                                %>
                                <% if ("CONFIRMED".equals(ticket.getStatus()) || "IN_TRANSIT".equals(ticket.getStatus())) { %>
                                <tr class="table-light fw-bold">
                                    <td colspan="6" class="text-end pe-4">Tổng giá trị xuất kho:</td>
                                    <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    
                    
                    <%-- IN_TRANSIT TRANSFER ticket — luồng v3: kho đích sẽ thấy Request IN-TRANSFER auto-sinh ở module Import Request --%>
                    <% if ("IN_TRANSIT".equals(ticket.getStatus())) { %>
                    <div class="card-footer bg-info bg-opacity-10 p-3 small text-info border-top-0">
                        <i class="bi bi-info-circle me-1"></i>
                        Phiếu đang vận chuyển. Kho đích cần vào <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list">Yêu cầu nhập kho</a>
                        để xử lý phiếu nhập tương ứng (hệ thống đã tự tạo khi xác nhận xuất kho).
                    </div>
                    <% } %>
                </div>

                <%
                    List<ProductItem> exportedSerials = (List<ProductItem>) request.getAttribute("exportedSerials");
                    if (exportedSerials != null && !exportedSerials.isEmpty()) {
                %>
                <div class="card bg-white mb-4">
                    <div class="card-header bg-light py-3 border-0">
                        <h5 class="mb-0 fw-bold text-success"><i class="bi bi-check2-all me-2"></i>Danh sách mã Serial xuất kho (Truy xuất nguồn gốc)</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <% for (ProductItem item : exportedSerials) { %>
                            <div class="col-md-4 col-sm-6 mb-2">
                                <div class="border rounded p-2 px-3 bg-light d-flex justify-content-between align-items-center">
                                    <div class="text-truncate" style="max-width: 60%;">
                                        <span class="fw-semibold text-slate-800 small d-block text-truncate" title="<%= item.getProductName() %>"><%= item.getProductName() %></span>
                                        <span class="text-muted small font-monospace"><%= item.getSku() %></span>
                                    </div>
                                    <span class="badge bg-light text-success font-monospace px-2 py-1"><%= item.getSerialNumber() %></span>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                <% } %>


            </div>
        </div>
    </div>
</body>
</html>
