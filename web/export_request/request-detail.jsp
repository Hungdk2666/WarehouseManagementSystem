<%@page import="model.ExportRequest"%>
<%@page import="model.ExportRequestDetail"%>
<%@page import="model.ExportTicket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("EXPORT_REQ_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    ExportRequest req = (ExportRequest) request.getAttribute("req");
    List<ExportTicket> ticketList = (List<ExportTicket>) request.getAttribute("ticketList");
    
    if (req == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/export-request?action=list");
        return;
    }

    boolean canApprove = loggedInUser.hasPermission("EXPORT_REQ_APPROVE");
    boolean canCancel = loggedInUser.hasPermission("EXPORT_REQ_CANCEL");
    boolean canCreateTicket = loggedInUser.hasPermission("EXPORT_TICKET_ADD");
    boolean canRequestCancel = loggedInUser.hasPermission("EXPORT_REQ_REQUESTCANCEL");
    boolean canApproveCancel = loggedInUser.hasPermission("EXPORT_REQ_APPROVECANCEL");

    int totalReqQty = 0;
    int totalIssuedQty = 0;
    if (req.getDetails() != null) {
        for (ExportRequestDetail d : req.getDetails()) {
            totalReqQty += d.getQuantity();
            totalIssuedQty += d.getIssuedQuantity();
        }
    }
    boolean canRequestCancelAction = totalIssuedQty < totalReqQty;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Export Request Details - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <!-- Left Sidebar -->
            <jsp:include page="/includes/sidebar.jsp" />

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <!-- Back Button -->
                <div class="mb-3">
                    <a href="export-request?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1.5 px-3 py-2 rounded-3">
                        <i class="bi bi-arrow-left"></i> Back to Requests Directory
                    </a>
                </div>

                <% if (req.getCancelRequestedAt() != null && "APPROVED".equals(req.getStatus())) { %>
                <div class="alert alert-warning border-0 shadow-sm d-flex align-items-center gap-3 p-3 mb-4" role="alert">
                    <i class="bi bi-exclamation-triangle-fill fs-3 text-warning"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Yêu cầu hủy phiếu xuất đang chờ duyệt (Pending Cancellation)</h6>
                        <p class="mb-0 small text-dark">
                            <strong>Lý do:</strong> <%= req.getCancelReason() %><br/>
                            <strong>Đề xuất bởi:</strong> <%= req.getCancelRequestedByFullName() %> lúc <%= req.getCancelRequestedAt() %>
                        </p>
                    </div>
                </div>
                <% } %>
                
                <% if ("CANCELLED".equals(req.getStatus())) { %>
                <div class="alert alert-secondary border-0 shadow-sm d-flex align-items-center gap-3 p-3 mb-4" role="alert">
                    <i class="bi bi-x-circle-fill fs-3 text-secondary"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Yêu cầu xuất kho đã bị đóng/hủy (Cancelled/Closed)</h6>
                        <p class="mb-0 small text-dark">
                            <% if (req.getCancelReason() != null) { %>
                            <strong>Lý do hủy:</strong> <%= req.getCancelReason() %><br/>
                            <% } %>
                            <strong>Thực hiện bởi:</strong> <%= req.getCancelledByFullName() != null ? req.getCancelledByFullName() : "System" %> lúc <%= req.getCancelledAt() %>
                        </p>
                    </div>
                </div>
                <% } %>

                <!-- Header Info -->
                <div class="card shadow-sm border-0 mb-4 bg-white">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h4 class="mb-0 fw-bold text-primary"><i class="bi bi-file-earmark-text-fill me-2"></i>Export Request #<%= req.getRequestCode() %></h4>
                        <%
                            String statusBadge = "bg-secondary text-secondary";
                            String displayStatus = req.getStatus();
                            if ("PENDING".equals(req.getStatus())) {
                                statusBadge = "bg-warning text-warning";
                            } else if ("APPROVED".equals(req.getStatus())) {
                                if (req.getCancelRequestedAt() != null) {
                                    statusBadge = "bg-warning text-warning";
                                    displayStatus = "PENDING CANCEL";
                                } else {
                                    statusBadge = "bg-info text-info";
                                }
                            } else if ("REJECTED".equals(req.getStatus())) {
                                statusBadge = "bg-danger text-danger";
                            } else if ("COMPLETED".equals(req.getStatus())) {
                                statusBadge = "bg-success text-success";
                            } else if ("CANCELLED".equals(req.getStatus())) {
                                statusBadge = "bg-secondary text-secondary";
                            }
                        %>
                        <span class="badge <%= statusBadge %> bg-opacity-10 px-3 py-2 fs-6"><%= displayStatus %></span>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Destination Node</label>
                                <span class="fw-bold text-slate-800 fs-5"><%= req.getDestinationName() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Export Reason</label>
                                <span class="badge bg-light text-dark border py-1.5 px-2.5 fs-6 mt-1"><%= req.getExportReason() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Expected Export Date</label>
                                <span class="fw-semibold text-slate-800"><%= req.getExpectedDate() %></span>
                            </div>
                            
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Proposed By</label>
                                <span class="fw-semibold text-slate-700"><%= req.getCreatorFullName() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Proposed At</label>
                                <span class="fw-semibold text-slate-700"><%= req.getCreatedAt() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Approved/Rejected By</label>
                                <span class="fw-semibold text-slate-800"><%= req.getApprovedBy() != null ? req.getApprovedByFullName() : "-" %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Approved/Rejected At</label>
                                <span class="fw-semibold text-slate-800"><%= req.getApprovedAt() != null ? req.getApprovedAt() : "-" %></span>
                            </div>

                            <% if ("CANCELLED".equals(req.getStatus())) { %>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Cancelled/Closed By</label>
                                <span class="fw-semibold text-slate-800"><%= req.getCancelledByFullName() != null ? req.getCancelledByFullName() : "System" %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Cancelled/Closed At</label>
                                <span class="fw-semibold text-slate-800"><%= req.getCancelledAt() %></span>
                            </div>
                            <% if (req.getCancelReason() != null) { %>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Cancellation Reason</label>
                                <span class="fw-semibold text-danger"><%= req.getCancelReason() %></span>
                            </div>
                            <% } %>
                            <% } %>
                        </div>

                        <!-- Action Buttons -->
                        <%
                            boolean hasActions = false;
                            if ("PENDING".equals(req.getStatus()) && (canApprove || (canCancel && req.getCreatorId() == loggedInUser.getId()))) {
                                hasActions = true;
                            } else if ("APPROVED".equals(req.getStatus())) {
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
                        <div class="mt-4 pt-3 border-top d-flex justify-content-end gap-2">
                            <% if ("PENDING".equals(req.getStatus())) { %>
                                <% if (canApprove) { %>
                                <form action="export-request?action=approve" method="POST" class="d-inline m-0">
                                    <input type="hidden" name="id" value="<%= req.getId() %>">
                                    <button type="submit" class="btn btn-success px-4 py-2"><i class="bi bi-check-circle me-1"></i> Approve Request</button>
                                </form>
                                <form action="export-request?action=reject" method="POST" class="d-inline m-0">
                                    <input type="hidden" name="id" value="<%= req.getId() %>">
                                    <button type="submit" class="btn btn-danger px-4 py-2"><i class="bi bi-x-circle me-1"></i> Reject Request</button>
                                </form>
                                <% } %>
                                <% if (canCancel && req.getCreatorId() == loggedInUser.getId()) { %>
                                <form action="export-request?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Are you sure you want to cancel this request?');">
                                    <input type="hidden" name="id" value="<%= req.getId() %>">
                                    <button type="submit" class="btn btn-outline-danger px-4 py-2"><i class="bi bi-trash me-1"></i> Cancel Request</button>
                                </form>
                                <% } %>
                            <% class ApprovedStatus { } %>
                            <% } else if ("APPROVED".equals(req.getStatus())) { %>
                                <% if (req.getCancelRequestedAt() == null) { %>
                                    <% if (canRequestCancel && canRequestCancelAction) { %>
                                    <button type="button" class="btn btn-outline-danger px-4 py-2" data-bs-toggle="modal" data-bs-target="#requestCancelModal">
                                        <i class="bi bi-exclamation-octagon me-1"></i> Request Cancellation
                                    </button>
                                    <% } %>
                                    <% if (canCreateTicket) { %>
                                    <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=add&request_id=<%= req.getId() %>" class="btn btn-primary px-4 py-2">
                                        <i class="bi bi-plus-circle me-1"></i> Create Export Ticket
                                    </a>
                                    <% } %>
                                <% } else { %>
                                    <% if (canApproveCancel) { %>
                                    <form action="export-request?action=rejectCancel" method="POST" class="d-inline m-0">
                                        <input type="hidden" name="id" value="<%= req.getId() %>">
                                        <button type="submit" class="btn btn-outline-success px-4 py-2"><i class="bi bi-x-circle me-1"></i> Reject Cancellation</button>
                                    </form>
                                    <form action="export-request?action=approveCancel" method="POST" class="d-inline m-0">
                                        <input type="hidden" name="id" value="<%= req.getId() %>">
                                        <button type="submit" class="btn btn-danger px-4 py-2"><i class="bi bi-check-circle-fill me-1"></i> Approve & Close Request</button>
                                    </form>
                                    <% } %>
                                <% } %>
                            <% } %>
                        </div>
                        <% } %>
                    </div>
                </div>

                <!-- Products Table -->
                <div class="card shadow-sm border-0 mb-4 bg-white">
                    <div class="card-header bg-transparent py-3 border-0">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-check me-2 text-primary"></i>Requested Items & Dispatch Progress</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.9rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th style="width: 8%;">#</th>
                                        <th class="text-start ps-4" style="width: 40%;">Product Name</th>
                                        <th>SKU</th>
                                        <th>Unit</th>
                                        <th>Requested Qty</th>
                                        <th>Actual Shipped Qty</th>
                                        <th>Completion Progress</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (req.getDetails() != null && !req.getDetails().isEmpty()) {
                                            int index = 1;
                                            for (ExportRequestDetail d : req.getDetails()) {
                                                int reqQty = d.getQuantity();
                                                int issuedQty = d.getIssuedQuantity();
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
                                        <td class="fw-bold text-primary"><%= issuedQty %></td>
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
                <div class="card shadow-sm border-0 bg-white">
                    <div class="card-header bg-transparent py-3 border-0">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-box-arrow-up-right me-2 text-primary"></i>Linked Export Tickets (<%= ticketList != null ? ticketList.size() : 0 %>)</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table align-middle mb-0 text-center" style="font-size: 0.9rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th>Ticket Code</th>
                                        <th>Keeper</th>
                                        <th>Created At</th>
                                        <th>Status</th>
                                        <th>Confirmed By</th>
                                        <th>Confirmed At</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (ticketList != null && !ticketList.isEmpty()) {
                                            for (ExportTicket t : ticketList) {
                                                String tStatusBadge = "bg-secondary text-secondary";
                                                if ("DRAFT".equals(t.getStatus())) tStatusBadge = "bg-warning text-warning";
                                                else if ("CONFIRMED".equals(t.getStatus())) tStatusBadge = "bg-success text-success";
                                                else if ("CANCELLED".equals(t.getStatus())) tStatusBadge = "bg-danger text-danger";
                                    %>
                                    <tr>
                                        <td class="fw-bold">#<%= t.getTicketCode() %></td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td class="small text-muted"><%= t.getCreatedAt() %></td>
                                        <td>
                                            <span class="badge <%= tStatusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= t.getStatus() %></span>
                                        </td>
                                        <td><%= t.getConfirmedBy() != null ? t.getConfirmedByFullName() : "-" %></td>
                                        <td class="small text-muted"><%= t.getConfirmedAt() != null ? t.getConfirmedAt() : "-" %></td>
                                        <td>
                                            <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-sm btn-outline-primary py-0.5 px-2">
                                                <i class="bi bi-eye"></i> View Export Ticket
                                            </a>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="7" class="text-center py-4 text-muted small">No Export Tickets linked to this request yet.</td>
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
                        <h5 class="modal-title fw-bold text-slate-800" id="requestCancelModalLabel">Request Export Request Cancellation</h5>
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
