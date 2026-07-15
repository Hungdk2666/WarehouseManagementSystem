<%@page import="model.Request"%>
<%@page import="model.RequestDetail"%>
<%@page import="model.Ticket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_VIEW_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Request req = (Request) request.getAttribute("req");
    if (req == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/import-request?action=list");
        return;
    }
    List<Ticket> ticketList = (List<Ticket>) request.getAttribute("ticketList");
    boolean canApprove       = loggedInUser.hasPermission("REQUEST_APPROVE_IN");
    boolean canCancel        = loggedInUser.hasPermission("REQUEST_CANCEL_IN");
    boolean canRequestCancel = loggedInUser.hasPermission("REQUEST_REQUEST_CANCEL_IN");
    boolean canApproveCancel = loggedInUser.hasPermission("REQUEST_APPROVE_CANCEL_IN");

    boolean isReturn   = "RETURN".equals(req.getReason());
    boolean isTransfer = "TRANSFER".equals(req.getReason());
    boolean isPurchase = "PURCHASE".equals(req.getReason());

    int totalReqQty = 0, totalRecQty = 0;
    if (req.getDetails() != null) {
        for (RequestDetail d : req.getDetails()) {
            totalReqQty += d.getQuantity();
            totalRecQty += d.getProcessedQuantity();
        }
    }
    boolean canRequestCancelAction = totalRecQty < totalReqQty;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi tiết yêu cầu nhập - #<%= req.getRequestCode() %></title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
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
                        <h2 class="page-title">Chi tiết Yêu cầu nhập kho</h2>
                        <p class="page-subtitle">
                            #<%= req.getRequestCode() %>
                            <% if (isReturn) { %><span class="status-chip chip-warning ms-2">TRẢ HÀNG</span><% } %>
                        </p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (("APPROVED".equals(req.getStatus()) || "PARTIALLY_COMPLETED".equals(req.getStatus()))
                               && req.getCancelRequestedAt() == null
                               && loggedInUser.hasPermission("TICKET_ADD_IN")) { %>
                        <a href="<%= request.getContextPath() %>/warehouse/import-ticket?action=add&request_id=<%= req.getId() %>" class="btn btn-primary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Tạo phiếu nhập
                        </a>
                        <% } %>
                        <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                    </div>
                </div>

                <% if (req.getCancelRequestedAt() != null && ("APPROVED".equals(req.getStatus()) || "PARTIALLY_COMPLETED".equals(req.getStatus()))) { %>
                <div class="alert alert-warning border-0 shadow-sm d-flex align-items-center gap-3 p-3 mb-4">
                    <i class="bi bi-exclamation-triangle-fill fs-3 text-warning"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Đang chờ duyệt yêu cầu hủy</h6>
                        <p class="mb-0 small"><strong>Lý do:</strong> <%= req.getCancelReason() %><br>
                        <strong>Đề xuất bởi:</strong> <%= req.getCancelRequestedByFullName() %> lúc <%= req.getCancelRequestedAt() %></p>
                    </div>
                </div>
                <% } %>

                <% if ("CANCELLED".equals(req.getStatus()) || "REVOKED".equals(req.getStatus())
                        || "PARTIALLY_CLOSED".equals(req.getStatus()) || "RETURNING".equals(req.getStatus())
                        || "RETURNED".equals(req.getStatus())) { %>
                <div class="alert alert-secondary border-0 shadow-sm d-flex align-items-center gap-3 p-3 mb-4">
                    <i class="bi bi-x-circle-fill fs-3 text-secondary"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1"><%=
                            "REVOKED".equals(req.getStatus()) ? "Yêu cầu nhập kho đã được thu hồi" :
                            "PARTIALLY_CLOSED".equals(req.getStatus()) ? "Yêu cầu nhập kho đã đóng phần còn lại" :
                            "RETURNING".equals(req.getStatus()) ? "Hàng đang được trả về kho nguồn" :
                            "RETURNED".equals(req.getStatus()) ? "Hàng đã được trả về kho nguồn" :
                            "Yêu cầu nhập kho đã bị hủy"
                        %></h6>
                        <p class="mb-0 small">
                            <% if (req.getCancelReason() != null) { %><strong>Lý do:</strong> <%= req.getCancelReason() %><br><% } %>
                            <strong>Bởi:</strong> <%= req.getCancelledByFullName() != null ? req.getCancelledByFullName() : "Hệ thống" %> lúc <%= req.getCancelledAt() %>
                        </p>
                    </div>
                </div>
                <% } %>

                
                <div class="card mb-4">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin Yêu cầu nhập kho</span>
                    </div>
                    <div class="card-body p-4">
                        <div class="detail-grid">
                        <div class="detail-item">
                            <div class="detail-label">Mã yêu cầu nhập kho</div>
                            <div class="detail-value fw-bold">#<%= req.getRequestCode() %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Loại</div>
                            <div class="detail-value"><%= isReturn ? "TRẢ HÀNG" : (isTransfer ? "CHUYỂN KHO" : "MUA HÀNG") %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Ngày nhận hàng dự kiến</div>
                            <div class="detail-value"><%= req.getExpectedDate() %></div>
                        </div>

                        <% if (isPurchase) { %>
                        <div class="detail-item">
                            <div class="detail-label">Nhà cung cấp</div>
                            <div class="detail-value"><%= req.getPartnerName() != null ? req.getPartnerName() : "-" %></div>
                        </div>
                        <% } else if (isTransfer) { %>
                        <div class="detail-item">
                            <div class="detail-label">Kho nguồn</div>
                            <div class="detail-value"><i class="bi bi-building me-1 text-primary"></i><%= req.getPartnerName() != null ? req.getPartnerName() : "-" %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Phiếu xuất tham chiếu</div>
                            <div class="detail-value">
                                <% if (req.getRefTicketId() != null) { %>
                                <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=detail&id=<%= req.getRefTicketId() %>"><%= req.getRefTicketCode() != null ? req.getRefTicketCode() : "#" + req.getRefTicketId() %></a>
                                <% } else { %>-<% } %>
                            </div>
                        </div>
                        <% } else if (isReturn) { %>
                        <div class="detail-item">
                            <div class="detail-label">Phiếu xuất tham chiếu</div>
                            <div class="detail-value">
                                <% if (req.getRefTicketId() != null) { %>
                                <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=detail&id=<%= req.getRefTicketId() %>"><%= req.getRefTicketCode() != null ? req.getRefTicketCode() : "#" + req.getRefTicketId() %></a>
                                <% } else { %>-<% } %>
                            </div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Lý do trả hàng</div>
                            <div class="detail-value"><%
                                String rr = req.getReturnReason();
                                if ("CUSTOMER_REJECTION".equals(rr)) out.print("Khách hàng từ chối nhận hàng");
                                else if ("QUALITY_DEFECT".equals(rr)) out.print("Sản phẩm lỗi/hỏng hóc");
                                else if ("WRONG_ITEM".equals(rr)) out.print("Giao sai sản phẩm");
                                else if ("EXCESS_QUANTITY".equals(rr)) out.print("Giao thừa số lượng");
                                else if ("OTHER".equals(rr)) out.print("Lý do khác");
                                else out.print(rr != null ? rr : "-");
                            %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Serial dự kiến nhận lại</div>
                            <div class="detail-value"><%= req.getExpectedSerials() != null ? req.getExpectedSerials().replace(",", ", ") : "-" %></div>
                        </div>
                        <% } %>

                        <div class="detail-item">
                            <div class="detail-label">Người tạo</div>
                            <div class="detail-value"><%= req.getStaffFullName() %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Ngày tạo</div>
                            <div class="detail-value"><%= req.getCreatedAt() %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Trạng thái</div>
                            <div class="detail-value">
                                <%
                                    String statusBadge = "chip-muted";
                                    String displayStatus = req.getStatus();
                                    if ("PENDING".equals(req.getStatus())) {
                                        statusBadge = "chip-warning";
                                        displayStatus = "Chờ duyệt";
                                    } else if ("APPROVED".equals(req.getStatus())) {
                                        if (req.getCancelRequestedAt() != null) {
                                            statusBadge = "chip-warning";
                                            displayStatus = "Chờ hủy";
                                        } else {
                                            statusBadge = "chip-success";
                                            displayStatus = "Đã duyệt";
                                        }
                                    } else if ("PARTIALLY_COMPLETED".equals(req.getStatus())) {
                                        statusBadge = "chip-info";
                                        displayStatus = req.getCancelRequestedAt() != null ? "Chờ đóng phần còn lại" : "Đang nhập dở";
                                    } else if ("PARTIALLY_CLOSED".equals(req.getStatus())) {
                                        statusBadge = "chip-muted";
                                        displayStatus = "Đã đóng một phần";
                                    } else if ("RETURNING".equals(req.getStatus())) {
                                        statusBadge = "chip-warning";
                                        displayStatus = "Đang trả về nguồn";
                                    } else if ("RETURNED".equals(req.getStatus())) {
                                        statusBadge = "chip-primary";
                                        displayStatus = "Đã trả về nguồn";
                                    } else if ("REVOKED".equals(req.getStatus())) {
                                        statusBadge = "chip-muted";
                                        displayStatus = "Đã thu hồi";
                                    } else if ("REJECTED".equals(req.getStatus())) {
                                        statusBadge = "chip-danger";
                                        displayStatus = "Từ chối";
                                    } else if ("COMPLETED".equals(req.getStatus())) {
                                        statusBadge = "chip-primary";
                                        displayStatus = "Hoàn thành";
                                    } else if ("CANCELLED".equals(req.getStatus())) {
                                        statusBadge = "chip-muted";
                                        displayStatus = "Đã hủy";
                                    }
                                %>
                                <span class="status-chip <%= statusBadge %>"><%= displayStatus %></span>
                            </div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Duyệt/Từ chối bởi</div>
                            <div class="detail-value"><%= req.getApprovedBy() != null ? req.getApprovedByFullName() : "-" %></div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Thời gian duyệt</div>
                            <div class="detail-value"><%= req.getApprovedAt() != null ? req.getApprovedAt() : "-" %></div>
                        </div>
                        </div>
                    </div>
                </div>

                
                <div class="card mb-4">
                    <div class="card-header bg-white pt-3 pb-0 border-0">
                        <ul class="nav nav-tabs border-bottom-0" id="reqTabs" role="tablist">
                            <li class="nav-item">
                                <button class="nav-link active fw-bold text-slate-800" data-bs-toggle="tab" data-bs-target="#items-pane" type="button">
                                    <i class="bi bi-list-check me-2"></i>Sản phẩm yêu cầu
                                </button>
                            </li>
                            <li class="nav-item">
                                <button class="nav-link fw-bold text-secondary" data-bs-toggle="tab" data-bs-target="#tickets-pane" type="button">
                                    <i class="bi bi-box-arrow-in-down me-2"></i>Phiếu nhập liên quan (<%= ticketList != null ? ticketList.size() : 0 %>)
                                </button>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body p-0">
                        <div class="tab-content">
                            <div class="tab-pane fade show active" id="items-pane">
                                <div class="table-responsive">
                                    <table class="table table-hover align-middle text-center mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th>#</th>
                                                <th class="text-start ps-4">Tên sản phẩm</th>
                                                <th>SKU</th>
                                                <th>Đơn vị</th>
                                                <th>SL yêu cầu</th>
                                                <th>SL đã nhận</th>
                                                <th>Tiến độ</th>
                                                <% if (isPurchase) { %><th>Đơn giá</th><th>Thành tiền</th><% } %>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                double totalCost = 0;
                                                if (req.getDetails() != null) {
                                                    int idx = 1;
                                                    for (RequestDetail d : req.getDetails()) {
                                                        double itemCost = d.getQuantity() * (d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0);
                                                        totalCost += itemCost;
                                                        int reqQty = d.getQuantity(), recQty = d.getProcessedQuantity();
                                                        double pct = reqQty > 0 ? ((double)recQty/reqQty)*100 : 0;
                                                        String pColor = pct>=100 ? "bg-success" : (pct>0 ? "bg-primary" : "bg-warning");
                                            %>
                                            <tr>
                                                <td><%= idx++ %></td>
                                                <td class="text-start ps-4 fw-semibold"><%= d.getProductName() %></td>
                                                <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                                <td><%= d.getUnit() %></td>
                                                <td class="fw-bold"><%= reqQty %></td>
                                                <td class="fw-bold text-success"><%= recQty %></td>
                                                <td>
                                                    <div class="d-flex align-items-center justify-content-center gap-2" style="max-width:180px;margin:0 auto;">
                                                        <div class="progress flex-grow-1" style="height:6px;min-width:80px;">
                                                            <div class="progress-bar <%= pColor %>" style="width:<%= Math.min(pct,100) %>%"></div>
                                                        </div>
                                                        <span class="small fw-bold text-muted"><%= String.format("%.0f",pct) %>%</span>
                                                    </div>
                                                </td>
                                                <% if (isPurchase) { %>
                                                <td><%= String.format("%,.0f", d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0) %> VND</td>
                                                <td class="fw-bold"><%= String.format("%,.0f", itemCost) %> VND</td>
                                                <% } %>
                                            </tr>
                                            <% } } %>
                                            <% if (isPurchase) { %>
                                            <tr class="table-light fw-bold">
                                                <td colspan="8" class="text-end pe-4">Tổng giá trị ước tính:</td>
                                                <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                            <div class="tab-pane fade" id="tickets-pane">
                                <div class="table-responsive">
                                    <table class="table table-hover align-middle text-center mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th>Mã phiếu</th>
                                                <th>Trạng thái</th>
                                                <th>Kho nhận</th>
                                                <th>Thủ kho</th>
                                                <th>Ngày tạo</th>
                                                <th>Xác nhận bởi</th>
                                                <th>Thao tác</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                if (ticketList != null && !ticketList.isEmpty()) {
                                                    for (Ticket t : ticketList) {
                                                        String tBadge = "CONFIRMED".equals(t.getStatus()) ? "chip-success" :
                                                                        "DRAFT".equals(t.getStatus()) ? "chip-muted" : "chip-muted";
                                            %>
                                            <tr>
                                                <td class="fw-bold">#<%= t.getTicketCode() %></td>
                                                <td>
                                                    <%
                                                        String displayTStatus = t.getStatus();
                                                        if ("CONFIRMED".equals(t.getStatus())) displayTStatus = "ĐÃ XÁC NHẬN";
                                                        else if ("DRAFT".equals(t.getStatus())) displayTStatus = "BẢN NHÁP";
                                                    %>
                                                    <span class="status-chip <%= tBadge %>"><%= displayTStatus %></span>
                                                </td>
                                                <td><%= t.getWarehouseName() != null ? t.getWarehouseName() : "-" %></td>
                                                <td><%= t.getKeeperFullName() %></td>
                                                <td class="text-muted small"><%= t.getCreatedAt() %></td>
                                                <td><%= t.getConfirmedByFullName() != null ? t.getConfirmedByFullName() : "-" %></td>
                                                <td>
                                                    <a href="<%= request.getContextPath() %>/warehouse/import-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết">
                                                        <i class="bi bi-eye"></i>
                                                    </a>
                                                </td>
                                            </tr>
                                            <%
                                                    }
                                                } else {
                                            %>
                                            <tr><td colspan="7" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Không có phiếu nhập nào.</p></div></td></tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                    <%
                        boolean hasFooterActions =
                            ("PENDING".equals(req.getStatus()) && (canApprove || canCancel)) ||
                            (("APPROVED".equals(req.getStatus()) || "PARTIALLY_COMPLETED".equals(req.getStatus())) && (
                                (req.getCancelRequestedAt() == null && canRequestCancel && canRequestCancelAction) ||
                                (req.getCancelRequestedAt() != null && canApproveCancel)));
                        if (hasFooterActions) {
                    %>
                    <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                        <% if ("PENDING".equals(req.getStatus())) { %>
                            <% if (canCancel) { %>
                            <form action="<%= request.getContextPath() %>/warehouse/import-request?action=cancel" method="POST" class="d-inline" onsubmit="return confirm('Hủy Yêu cầu nhập kho này?')">
                                <input type="hidden" name="id" value="<%= req.getId() %>">
                                <button type="submit" class="btn btn-outline-danger px-4"><i class="bi bi-x-circle me-1"></i> Hủy</button>
                            </form>
                            <% } %>
                            <% if (canApprove) { %>
                            <form action="<%= request.getContextPath() %>/warehouse/import-request?action=reject" method="POST" class="d-inline">
                                <input type="hidden" name="id" value="<%= req.getId() %>">
                                <button type="submit" class="btn btn-danger px-4"><i class="bi bi-x-circle-fill me-1"></i> Từ chối</button>
                            </form>
                            <form action="<%= request.getContextPath() %>/warehouse/import-request?action=approve" method="POST" class="d-inline">
                                <input type="hidden" name="id" value="<%= req.getId() %>">
                                <button type="submit" class="btn btn-success px-4"><i class="bi bi-check-circle-fill me-1"></i> Duyệt</button>
                            </form>
                            <% } %>
                        <% } else if ("APPROVED".equals(req.getStatus()) || "PARTIALLY_COMPLETED".equals(req.getStatus())) { %>
                            <% if (req.getCancelRequestedAt() == null && canRequestCancel && canRequestCancelAction) { %>
                            <button type="button" class="btn btn-outline-danger px-4" data-bs-toggle="modal" data-bs-target="#requestCancelModal">
                                <i class="bi bi-exclamation-octagon me-1"></i> Đề xuất hủy
                            </button>
                            <% } else if (req.getCancelRequestedAt() != null && canApproveCancel) { %>
                            <form action="<%= request.getContextPath() %>/warehouse/import-request?action=rejectCancel" method="POST" class="d-inline">
                                <input type="hidden" name="id" value="<%= req.getId() %>">
                                <button type="submit" class="btn btn-outline-success px-4"><i class="bi bi-x-circle me-1"></i> Từ chối yêu cầu hủy</button>
                            </form>
                            <form action="<%= request.getContextPath() %>/warehouse/import-request?action=approveCancel" method="POST" class="d-inline">
                                <input type="hidden" name="id" value="<%= req.getId() %>">
                                <button type="submit" class="btn btn-danger px-4"><i class="bi bi-check-circle-fill me-1"></i> <%= isTransfer ? "Duyệt hủy & tạo nhập trả" : ("PARTIALLY_COMPLETED".equals(req.getStatus()) ? "Duyệt đóng phần còn lại" : "Duyệt & Đóng") %></button>
                            </form>
                            <% } %>
                        <% } %>
                    </div>
                    <% } %>
                </div>

            </div>
        </div>
    </div>

    
    <div class="modal fade" id="requestCancelModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form action="<%= request.getContextPath() %>/warehouse/import-request?action=cancel" method="POST">
                    <input type="hidden" name="id" value="<%= req.getId() %>">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold">Đề xuất hủy Yêu cầu nhập kho</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <label for="cancelReason" class="form-label small fw-semibold text-muted">Lý do hủy</label>
                        <textarea class="form-control" id="cancelReason" name="reason" rows="4" required placeholder="Nhập lý do chi tiết..."></textarea>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
                        <button type="submit" class="btn btn-danger">Gửi yêu cầu hủy</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
