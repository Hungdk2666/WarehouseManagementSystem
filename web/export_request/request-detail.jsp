<%@page import="model.Request"%>
<%@page import="model.RequestDetail"%>
<%@page import="model.Ticket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_VIEW_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Request req = (Request) request.getAttribute("req");
    List<Ticket> ticketList = (List<Ticket>) request.getAttribute("ticketList");

    if (req == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
        return;
    }

    boolean canApprove = loggedInUser.hasPermission("REQUEST_APPROVE_OUT");
    boolean canCancel = loggedInUser.hasPermission("REQUEST_CANCEL_OUT");
    boolean canCreateTicket = loggedInUser.hasPermission("TICKET_ADD_OUT");
    boolean canRequestCancel = loggedInUser.hasPermission("REQUEST_REQUEST_CANCEL_OUT");
    boolean canApproveCancel = loggedInUser.hasPermission("REQUEST_APPROVE_CANCEL_OUT");

    int totalReqQty = 0, totalIssuedQty = 0;
    if (req.getDetails() != null) {
        for (RequestDetail d : req.getDetails()) {
            totalReqQty += d.getQuantity();
            totalIssuedQty += d.getProcessedQuantity();
        }
    }
    boolean canRequestCancelAction = totalIssuedQty < totalReqQty;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi tiết yêu cầu xuất kho - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=detail-layout-1">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <!-- Left Sidebar -->
            <jsp:include page="/includes/sidebar.jsp" />

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <div class="detail-page-header">
                    <div>
                        <h2 class="page-title">Chi tiết yêu cầu xuất kho</h2>
                        <p class="page-subtitle">Theo dõi sản phẩm, tiến độ thực hiện và các phiếu xuất liên kết cho yêu cầu #<%= req.getRequestCode() %></p>
                    </div>
                    <a href="export-request?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1.5 px-3 py-2 rounded-3">
                        <i class="bi bi-arrow-left"></i> Quay lại danh sách
                    </a>
                </div>

                <% if (req.getCancelRequestedAt() != null && "APPROVED".equals(req.getStatus())) { %>
                <div class="alert alert-warning border-0 d-flex align-items-center gap-3 p-3 mb-4" role="alert">
                    <i class="bi bi-exclamation-triangle-fill fs-3 text-warning"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Yêu cầu hủy phiếu xuất đang chờ duyệt</h6>
                        <p class="mb-0 small text-dark">
                            <strong>Lý do:</strong> <%= req.getCancelReason() %><br/>
                            <strong>Đề xuất bởi:</strong> <%= req.getCancelRequestedByFullName() %> lúc <%= req.getCancelRequestedAt() %>
                        </p>
                    </div>
                </div>
                <% } %>
                
                <% if ("CANCELLED".equals(req.getStatus())) { %>
                <div class="alert alert-secondary border-0 d-flex align-items-center gap-3 p-3 mb-4" role="alert">
                    <i class="bi bi-x-circle-fill fs-3 text-secondary"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Yêu cầu xuất kho đã bị đóng/hủy</h6>
                        <p class="mb-0 small text-dark">
                            <% if (req.getCancelReason() != null) { %>
                            <strong>Lý do hủy:</strong> <%= req.getCancelReason() %><br/>
                            <% } %>
                            <strong>Thực hiện bởi:</strong> <%= req.getCancelledByFullName() != null ? req.getCancelledByFullName() : "Hệ thống" %> lúc <%= req.getCancelledAt() %>
                        </p>
                    </div>
                </div>
                <% } %>

                <!-- Header Info -->
                <div class="card detail-section-card">
                    <div class="card-header bg-white py-3">
                        <span class="fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin yêu cầu xuất kho</span>
                    </div>
                    <div class="card-body p-4">
                        <div class="row gx-5 detail-info-grid">
                            <div class="col-lg-6">
                                <div class="detail-row">
                                    <div class="detail-label">Mã yêu cầu xuất</div>
                                    <div class="detail-value">#<%= req.getRequestCode() %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Trạng thái</div>
                                    <div class="detail-value">
                                        <%
                                            String statusBadge = "chip-muted";
                                            String displayStatus = req.getStatus();
                                            if ("PENDING".equals(req.getStatus())) { statusBadge = "chip-warning"; displayStatus = "Chờ duyệt"; }
                                            else if ("APPROVED".equals(req.getStatus())) { statusBadge = req.getCancelRequestedAt() != null ? "chip-warning" : "chip-success"; displayStatus = req.getCancelRequestedAt() != null ? "Chờ hủy" : "Đã duyệt"; }
                                            else if ("PARTIALLY_COMPLETED".equals(req.getStatus())) { statusBadge = "chip-info"; displayStatus = "Đang xuất dở"; }
                                            else if ("REJECTED".equals(req.getStatus())) { statusBadge = "chip-danger"; displayStatus = "Từ chối"; }
                                            else if ("COMPLETED".equals(req.getStatus())) { statusBadge = "chip-primary"; displayStatus = "Hoàn thành"; }
                                            else if ("CANCELLED".equals(req.getStatus())) { displayStatus = "Đã hủy"; }
                                        %>
                                        <span class="status-chip <%= statusBadge %>"><%= displayStatus %></span>
                                    </div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Lý do xuất</div>
                                    <div class="detail-value">
                                        <span>
                                            <%
                                                if ("TRANSFER".equals(req.getReason())) out.print("CHUYỂN KHO");
                                                else if ("CUSTOMER_SALE".equals(req.getReason())) out.print("BÁN HÀNG");
                                                else if ("DISPLAY".equals(req.getReason())) out.print("TRƯNG BÀY");
                                                else if ("WARRANTY".equals(req.getReason())) out.print("BẢO HÀNH");
                                                else if ("DISPOSAL".equals(req.getReason())) out.print("TIÊU HỦY");
                                                else out.print(req.getReason());
                                            %>
                                        </span>
                                    </div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Kho nguồn</div>
                                    <div class="detail-value"><%= req.getWarehouseName() != null ? req.getWarehouseName() : "-" %></div>
                                </div>
                                <%-- Polymorphic destination: show the right one based on reason --%>
                                <div class="detail-row">
                                    <% if ("TRANSFER".equals(req.getReason())) { %>
                                    <div class="detail-label">Kho đích</div>
                                    <% } else if ("CUSTOMER_SALE".equals(req.getReason())) { %>
                                    <div class="detail-label">Khách hàng</div>
                                    <% } else { %>
                                    <div class="detail-label">Điểm đến</div>
                                    <% } %>
                                    <div class="detail-value"><%= req.getPartnerName() != null ? req.getPartnerName() : "-" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Ngày xuất dự kiến</div>
                                    <div class="detail-value"><%= req.getExpectedDate() %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Tình trạng xuất</div>
                                    <div class="detail-value">
                                        <span>
                                            <%= "USED".equals(req.getRequestedCondition()) ? "Hàng Cũ" : "Hàng Mới" %>
                                        </span>
                                    </div>
                                </div>
                                <% if ("CUSTOMER_SALE".equals(req.getReason()) && req.getShippingAddress() != null && !req.getShippingAddress().isEmpty()) { %>
                                <div class="detail-row">
                                    <div class="detail-label">Địa chỉ giao hàng</div>
                                    <div class="detail-value"><%= req.getShippingAddress() %></div>
                                </div>
                                <% } %>
                            </div>
                            <div class="col-lg-6">
                                <div class="detail-row">
                                    <div class="detail-label">Người đề xuất</div>
                                    <div class="detail-value"><%= req.getStaffFullName() %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Thời gian đề xuất</div>
                                    <div class="detail-value"><%= req.getCreatedAt() %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Người duyệt / từ chối</div>
                                    <div class="detail-value"><%= req.getApprovedBy() != null ? req.getApprovedByFullName() : "-" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Thời gian duyệt / từ chối</div>
                                    <div class="detail-value"><%= req.getApprovedAt() != null ? req.getApprovedAt() : "-" %></div>
                                </div>

                                <% if ("CANCELLED".equals(req.getStatus())) { %>
                                <div class="detail-row">
                                    <div class="detail-label">Người hủy / đóng</div>
                                    <div class="detail-value"><%= req.getCancelledByFullName() != null ? req.getCancelledByFullName() : "Hệ thống" %></div>
                                </div>
                                <div class="detail-row">
                                    <div class="detail-label">Thời gian hủy / đóng</div>
                                    <div class="detail-value"><%= req.getCancelledAt() %></div>
                                </div>
                                <% if (req.getCancelReason() != null) { %>
                                <div class="detail-row">
                                    <div class="detail-label">Lý do hủy</div>
                                    <div class="detail-value text-danger"><%= req.getCancelReason() %></div>
                                </div>
                                <% } %>
                                <% } %>
                            </div>
                        </div>

                        <!-- Action Buttons -->
                        <%
                            boolean hasActions = false;
                            if ("PENDING".equals(req.getStatus()) && (canApprove || (canCancel && req.getStaffId() == loggedInUser.getId()))) {
                                hasActions = true;
                            } else if ("APPROVED".equals(req.getStatus()) || "PARTIALLY_COMPLETED".equals(req.getStatus())) {
                                if (req.getCancelRequestedAt() == null) {
                                    if (canCreateTicket || (canRequestCancel && canRequestCancelAction)) {
                                        hasActions = true;
                                    }
                                } else {
                                    if (canApproveCancel) {
                                        hasActions = true;
                                    }
                                }
                            }
                            
                            if (hasActions) {
                        %>
                        <div class="detail-actions mt-4">
                            <% if ("PENDING".equals(req.getStatus())) { %>
                                <% if (canApprove) { %>
                                <form action="export-request?action=approve" method="POST" class="d-inline m-0">
                                    <input type="hidden" name="id" value="<%= req.getId() %>">
                                    <button type="submit" class="btn btn-success px-4 py-2"><i class="bi bi-check-circle me-1"></i> Duyệt yêu cầu</button>
                                </form>
                                <form action="export-request?action=reject" method="POST" class="d-inline m-0">
                                    <input type="hidden" name="id" value="<%= req.getId() %>">
                                    <button type="submit" class="btn btn-danger px-4 py-2"><i class="bi bi-x-circle me-1"></i> Từ chối yêu cầu</button>
                                </form>
                                <% } %>
                                <% if (canCancel && req.getStaffId() == loggedInUser.getId()) { %>
                                <form action="export-request?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Bạn có chắc chắn muốn hủy yêu cầu này không?');">
                                    <input type="hidden" name="id" value="<%= req.getId() %>">
                                    <button type="submit" class="btn btn-outline-danger px-4 py-2"><i class="bi bi-trash me-1"></i> Hủy yêu cầu</button>
                                </form>
                                <% } %>
                            <% } else if ("APPROVED".equals(req.getStatus()) || "PARTIALLY_COMPLETED".equals(req.getStatus())) { %>
                                <% if (req.getCancelRequestedAt() == null) { %>
                                    <% if (canRequestCancel && canRequestCancelAction) { %>
                                    <button type="button" class="btn btn-outline-danger px-4 py-2" data-bs-toggle="modal" data-bs-target="#requestCancelModal">
                                        <i class="bi bi-exclamation-octagon me-1"></i> Yêu cầu hủy
                                    </button>
                                    <% } %>
                                    <% if (canCreateTicket) { %>
                                    <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=add&request_id=<%= req.getId() %>" class="btn btn-primary px-4 py-2">
                                        <i class="bi bi-plus-circle me-1"></i> Tạo phiếu xuất kho
                                    </a>
                                    <% } %>
                                <% } else { %>
                                    <% if (canApproveCancel) { %>
                                    <form action="export-request?action=rejectCancel" method="POST" class="d-inline m-0">
                                        <input type="hidden" name="id" value="<%= req.getId() %>">
                                        <button type="submit" class="btn btn-outline-success px-4 py-2"><i class="bi bi-x-circle me-1"></i> Từ chối yêu cầu hủy</button>
                                    </form>
                                    <form action="export-request?action=approveCancel" method="POST" class="d-inline m-0">
                                        <input type="hidden" name="id" value="<%= req.getId() %>">
                                        <button type="submit" class="btn btn-danger px-4 py-2"><i class="bi bi-check-circle-fill me-1"></i> Duyệt hủy & Đóng yêu cầu</button>
                                    </form>
                                    <% } %>
                                <% } %>
                            <% } %>
                        </div>
                        <% } %>
                    </div>
                </div>

                <!-- Products Table -->
                <div class="card detail-section-card bg-white">
                    <div class="card-header bg-white py-3">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-check me-2 text-primary"></i>Danh sách sản phẩm & Tiến độ xuất kho</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.9rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th style="width: 8%;">#</th>
                                        <th class="text-start ps-4" style="width: 40%;">Tên sản phẩm</th>
                                        <th>SKU</th>
                                        <th>Đơn vị</th>
                                        <th>Số lượng yêu cầu</th>
                                        <th>Số lượng thực xuất</th>
                                        <th>Tiến độ hoàn thành</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (req.getDetails() != null && !req.getDetails().isEmpty()) {
                                            int index = 1;
                                            for (RequestDetail d : req.getDetails()) {
                                                int reqQty = d.getQuantity();
                                                int issuedQty = d.getProcessedQuantity();
                                                double pct = reqQty > 0 ? ((double) issuedQty / reqQty) * 100 : 0;
                                                
                                                String progressColor = "bg-warning";
                                                if (pct >= 100) {
                                                    progressColor = "bg-success";
                                                } else if (pct > 0) {
                                                    progressColor = "bg-primary";
                                                }
                                    %>
                                    <tr>
                                        <td><%= index++ %></td>
                                        <td class="text-start ps-4 fw-semibold"><%= d.getProductName() %></td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                        <td><%= d.getUnit() %></td>
                                        <td class="fw-bold"><%= reqQty %></td>
                                        <td class="fw-bold text-slate-800"><%= issuedQty %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-2" style="max-width: 180px; margin: 0 auto;">
                                                <div class="progress flex-grow-1" style="height: 6px; min-width: 80px;">
                                                    <div class="progress-bar <%= progressColor %>" role="progressbar" style="width: <%= Math.min(pct, 100) %>%" aria-valuenow="<%= pct %>" aria-valuemin="0" aria-valuemax="100"></div>
                                                </div>
                                                <span class="small fw-bold text-muted"><%= String.format("%.0f", pct) %>%</span>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!-- Linked Export Tickets (GINs) -->
                <div class="card detail-section-card bg-white">
                    <div class="card-header bg-white py-3">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-box-arrow-up-right me-2 text-primary"></i>Phiếu xuất kho liên kết (<%= ticketList != null ? ticketList.size() : 0 %>)</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table align-middle mb-0 text-center" style="font-size: 0.9rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th>Mã phiếu</th>
                                        <th>Thủ kho</th>
                                        <th>Ngày tạo</th>
                                        <th>Trạng thái</th>
                                        <th>Người xác nhận</th>
                                        <th>Ngày xác nhận</th>
                                        <th>Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (ticketList != null && !ticketList.isEmpty()) {
                                            for (Ticket t : ticketList) {
                                                String tStatusBadge = "chip-muted";
                                                String displayTStatus = t.getStatus();
                                                if ("DRAFT".equals(t.getStatus())) {
                                                    tStatusBadge = "chip-warning";
                                                    displayTStatus = "Bản nháp";
                                                } else if ("CONFIRMED".equals(t.getStatus())) {
                                                    tStatusBadge = "chip-success";
                                                    displayTStatus = "Đã xác nhận";
                                                } else if ("CANCELLED".equals(t.getStatus())) {
                                                    tStatusBadge = "chip-danger";
                                                    displayTStatus = "Đã hủy";
                                                }
                                    %>
                                    <tr>
                                        <td class="fw-bold">#<%= t.getTicketCode() %></td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td class="small text-muted"><%= t.getCreatedAt() %></td>
                                        <td>
                                            <span class="status-chip <%= tStatusBadge %>"><%= displayTStatus %></span>
                                        </td>
                                        <td><%= t.getConfirmedBy() != null ? t.getConfirmedByFullName() : "-" %></td>
                                        <td class="small text-muted"><%= t.getConfirmedAt() != null ? t.getConfirmedAt() : "-" %></td>
                                        <td>
                                            <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-table btn-outline-primary" title="Xem phiếu xuất">
                                                <i class="bi bi-eye"></i>
                                            </a>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="7" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Chưa có phiếu xuất kho nào liên kết với yêu cầu này.</p></div></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>
    <!-- Request Cancellation Modal -->
    <div class="modal fade" id="requestCancelModal" tabindex="-1" aria-labelledby="requestCancelModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form action="export-request?action=cancel" method="POST">
                    <input type="hidden" name="id" value="<%= req.getId() %>">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold text-slate-800" id="requestCancelModalLabel">Yêu cầu hủy yêu cầu xuất kho</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="cancelReason" class="form-label small fw-semibold text-muted">Lý do hủy yêu cầu xuất kho</label>
                            <textarea class="form-control" id="cancelReason" name="reason" rows="4" required placeholder="Nhập lý do chi tiết để Business Admin duyệt..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Đóng</button>
                        <button type="submit" class="btn btn-danger">Gửi yêu cầu hủy</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    <!-- Bootstrap JS Bundle -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
