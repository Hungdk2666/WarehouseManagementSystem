<%@page import="model.ImportRequest"%>
<%@page import="model.ImportRequestDetail"%>
<%@page import="model.ImportTicket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("PO_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    ImportRequest po = (ImportRequest) request.getAttribute("po");
    if (po == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
        return;
    }
    List<ImportTicket> ticketList = (List<ImportTicket>) request.getAttribute("ticketList");
    boolean canApprove = loggedInUser.hasPermission("PO_APPROVE");
    boolean canCancel = loggedInUser.hasPermission("PO_CANCEL");
    boolean canRequestCancel = loggedInUser.hasPermission("PO_REQUEST_CANCEL");
    boolean canApproveCancel = loggedInUser.hasPermission("PO_APPROVE_CANCEL");
    
    int totalReqQty = 0;
    int totalRecQty = 0;
    if (po.getDetails() != null) {
        for (ImportRequestDetail d : po.getDetails()) {
            totalReqQty += d.getQuantity();
            totalRecQty += d.getReceivedQuantity();
        }
    }
    boolean canRequestCancelAction = totalRecQty < totalReqQty;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Purchase Order Detail - #<%= po.getRequestCode() %></title>
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
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Purchase Order Detail</h2>
                        <p class="text-muted small mb-0">View items and status for Purchase Order #<%= po.getRequestCode() %></p>
                    </div>
                    <a href="po?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back to List
                    </a>
                </div>

                <% if (po.getCancelRequestedAt() != null && "APPROVED".equals(po.getStatus())) { %>
                <div class="alert alert-warning border-0 shadow-sm d-flex align-items-center gap-3 p-3 mb-4" role="alert">
                    <i class="bi bi-exclamation-triangle-fill fs-3 text-warning"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Yêu cầu hủy đơn hàng đang chờ duyệt (Pending Cancellation)</h6>
                        <p class="mb-0 small text-dark">
                            <strong>Lý do:</strong> <%= po.getCancelReason() %><br/>
                            <strong>Đề xuất bởi:</strong> <%= po.getCancelRequestedByFullName() %> lúc <%= po.getCancelRequestedAt() %>
                        </p>
                    </div>
                </div>
                <% } %>
                
                <% if ("CANCELLED".equals(po.getStatus())) { %>
                <div class="alert alert-secondary border-0 shadow-sm d-flex align-items-center gap-3 p-3 mb-4" role="alert">
                    <i class="bi bi-x-circle-fill fs-3 text-secondary"></i>
                    <div>
                        <h6 class="alert-heading fw-bold mb-1">Đơn hàng đã bị đóng/hủy (Cancelled/Closed)</h6>
                        <p class="mb-0 small text-dark">
                            <% if (po.getCancelReason() != null) { %>
                            <strong>Lý do hủy:</strong> <%= po.getCancelReason() %><br/>
                            <% } %>
                            <strong>Thực hiện bởi:</strong> <%= po.getCancelledByFullName() != null ? po.getCancelledByFullName() : "System" %> lúc <%= po.getCancelledAt() %>
                        </p>
                    </div>
                </div>
                <% } %>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-info-circle-fill me-2"></i>Purchase Order Metadata</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Purchase Order Code</label>
                                <span class="fw-bold text-slate-800">#<%= po.getRequestCode() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Supplier</label>
                                <span class="fw-semibold text-slate-800"><%= po.getSupplierName() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Expected Fulfillment Date</label>
                                <span class="fw-semibold text-slate-800"><%= po.getExpectedDate() %></span>
                            </div>
                            
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Created By</label>
                                <span class="text-slate-700"><%= po.getCreatorFullName() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Created At</label>
                                <span class="text-slate-700"><%= po.getCreatedAt() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Status</label>
                                <%
                                    String statusBadge = "bg-secondary text-secondary";
                                    String displayStatus = po.getStatus();
                                    if ("PENDING".equals(po.getStatus())) {
                                        statusBadge = "bg-warning text-warning";
                                    } else if ("APPROVED".equals(po.getStatus())) {
                                        if (po.getCancelRequestedAt() != null) {
                                            statusBadge = "bg-warning text-warning";
                                            displayStatus = "PENDING CANCEL";
                                        } else {
                                            statusBadge = "bg-info text-info";
                                        }
                                    } else if ("REJECTED".equals(po.getStatus())) {
                                        statusBadge = "bg-danger text-danger";
                                    } else if ("COMPLETED".equals(po.getStatus())) {
                                        statusBadge = "bg-success text-success";
                                    } else if ("CANCELLED".equals(po.getStatus())) {
                                        statusBadge = "bg-secondary text-secondary";
                                    }
                                %>
                                <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayStatus %></span>
                            </div>
                            
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Approved/Rejected By</label>
                                <span class="text-slate-700 fw-semibold"><%= po.getApprovedBy() != null ? po.getApprovedByFullName() : "-" %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Reviewed At</label>
                                <span class="text-slate-700 fw-semibold"><%= po.getApprovedAt() != null ? po.getApprovedAt() : "-" %></span>
                            </div>
                            
                            <% if ("CANCELLED".equals(po.getStatus())) { %>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Cancelled/Closed By</label>
                                <span class="text-slate-700 fw-semibold"><%= po.getCancelledByFullName() != null ? po.getCancelledByFullName() : "System" %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Cancelled/Closed At</label>
                                <span class="text-slate-700 fw-semibold"><%= po.getCancelledAt() %></span>
                            </div>
                            <% if (po.getCancelReason() != null) { %>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Cancellation Reason</label>
                                <span class="text-danger fw-semibold"><%= po.getCancelReason() %></span>
                            </div>
                            <% } %>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-white pt-3 pb-0 border-0">
                        <ul class="nav nav-tabs border-bottom-0" id="poTabs" role="tablist">
                            <li class="nav-item" role="presentation">
                                <button class="nav-link active fw-bold text-primary" id="items-tab" data-bs-toggle="tab" data-bs-target="#items-pane" type="button" role="tab" aria-controls="items-pane" aria-selected="true" style="border-top-left-radius: 8px; border-top-right-radius: 8px;">
                                    <i class="bi bi-list-check me-2"></i>Requested Items & Progress
                                </button>
                            </li>
                            <li class="nav-item" role="presentation">
                                <button class="nav-link fw-bold text-secondary" id="tickets-tab" data-bs-toggle="tab" data-bs-target="#tickets-pane" type="button" role="tab" aria-controls="tickets-pane" aria-selected="false" style="border-top-left-radius: 8px; border-top-right-radius: 8px;">
                                    <i class="bi bi-box-arrow-in-down me-2"></i>Linked Import Tickets (<%= ticketList != null ? ticketList.size() : 0 %>)
                                </button>
                            </li>
                        </ul>
                    </div>
                    <div class="card-body p-0">
                        <div class="tab-content" id="poTabsContent">
                            <!-- Items Pane -->
                            <div class="tab-pane fade show active" id="items-pane" role="tabpanel" aria-labelledby="items-tab">
                                <div class="table-responsive">
                                    <table class="table align-middle text-center mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th>#</th>
                                                <th class="text-start ps-4">Product Name</th>
                                                <th>SKU</th>
                                                <th>Unit</th>
                                                <th>Requested Qty</th>
                                                <th>Received Qty</th>
                                                <th>Completion Progress</th>
                                                <th>Expected Price</th>
                                                <th>Total Expected Cost</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                double totalCost = 0;
                                                if (po.getDetails() != null && !po.getDetails().isEmpty()) {
                                                    int index = 1;
                                                    for (ImportRequestDetail d : po.getDetails()) {
                                                        double itemCost = d.getQuantity() * d.getUnitPrice();
                                                        totalCost += itemCost;
                                                        int reqQty = d.getQuantity();
                                                        int recQty = d.getReceivedQuantity();
                                                        double pct = reqQty > 0 ? ((double) recQty / reqQty) * 100 : 0;
                                                        
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
                                                <td class="fw-bold text-success"><%= recQty %></td>
                                                <td>
                                                    <div class="d-flex align-items-center justify-content-center gap-2" style="max-width: 180px; margin: 0 auto;">
                                                        <div class="progress flex-grow-1" style="height: 6px; min-width: 80px;">
                                                            <div class="progress-bar <%= progressColor %>" role="progressbar" style="width: <%= Math.min(pct, 100) %>%" aria-valuenow="<%= pct %>" aria-valuemin="0" aria-valuemax="100"></div>
                                                        </div>
                                                        <span class="small fw-bold text-muted"><%= String.format("%.0f", pct) %>%</span>
                                                    </div>
                                                </td>
                                                <td><%= String.format("%,.0f", d.getUnitPrice()) %> VND</td>
                                                <td class="fw-bold"><%= String.format("%,.0f", itemCost) %> VND</td>
                                            </tr>
                                            <%
                                                    }
                                                }
                                            %>
                                            <tr class="table-light fw-bold">
                                                <td colspan="8" class="text-end pe-4">Estimated Grand Total:</td>
                                                <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                            <!-- Tickets Pane -->
                            <div class="tab-pane fade" id="tickets-pane" role="tabpanel" aria-labelledby="tickets-tab">
                                <div class="table-responsive">
                                    <table class="table align-middle text-center mb-0">
                                        <thead class="table-light">
                                            <tr>
                                                <th>Ticket Code</th>
                                                <th>Status</th>
                                                <th>Keeper (Staff)</th>
                                                <th>Created At</th>
                                                <th>Confirmed By</th>
                                                <th>Confirmed At</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                if (ticketList != null && !ticketList.isEmpty()) {
                                                    for (ImportTicket t : ticketList) {
                                                        String tStatusBadge = "bg-secondary text-secondary";
                                                        if ("DRAFT".equals(t.getStatus())) tStatusBadge = "bg-warning text-warning";
                                                        else if ("CONFIRMED".equals(t.getStatus())) tStatusBadge = "bg-success text-success";
                                                        else if ("CANCELLED".equals(t.getStatus())) tStatusBadge = "bg-secondary text-secondary";
                                            %>
                                            <tr>
                                                <td class="fw-bold text-slate-800">#<%= t.getTicketCode() %></td>
                                                <td>
                                                    <span class="badge <%= tStatusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= t.getStatus() %></span>
                                                </td>
                                                <td><%= t.getKeeperFullName() %></td>
                                                <td class="text-muted small"><%= t.getCreatedAt() %></td>
                                                <td><%= t.getConfirmedByFullName() != null ? t.getConfirmedByFullName() : "-" %></td>
                                                <td class="text-muted small"><%= t.getConfirmedAt() != null ? t.getConfirmedAt() : "-" %></td>
                                                <td>
                                                    <a href="<%= request.getContextPath() %>/warehouse/import?action=detail&id=<%= t.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-eye"></i> Details
                                                    </a>
                                                </td>
                                            </tr>
                                            <%
                                                    }
                                                } else {
                                            %>
                                            <tr>
                                                <td colspan="7" class="text-center text-muted py-5">
                                                    <i class="bi bi-box-arrow-in-down text-muted display-4 d-block mb-3"></i>
                                                    No Linked Import Tickets found.
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <%
                        boolean hasFooterActions = false;
                        if ("PENDING".equals(po.getStatus()) && (canApprove || canCancel)) {
                            hasFooterActions = true;
                        } else if ("APPROVED".equals(po.getStatus())) {
                            if (po.getCancelRequestedAt() == null && canRequestCancel && canRequestCancelAction) {
                                hasFooterActions = true;
                            } else if (po.getCancelRequestedAt() != null && canApproveCancel) {
                                hasFooterActions = true;
                            }
                        }
                        
                        if (hasFooterActions) {
                    %>
                    <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                        <% if ("PENDING".equals(po.getStatus())) { %>
                            <% if (canCancel) { %>
                            <form action="po?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Are you sure you want to cancel this Purchase Order?');">
                                <input type="hidden" name="id" value="<%= po.getId() %>">
                                <button type="submit" class="btn btn-outline-danger px-4"><i class="bi bi-x-circle me-1"></i> Cancel Purchase Order</button>
                            </form>
                            <% } %>
                            <% if (canApprove) { %>
                            <form action="po?action=reject" method="POST" class="d-inline m-0">
                                <input type="hidden" name="id" value="<%= po.getId() %>">
                                <button type="submit" class="btn btn-danger px-4"><i class="bi bi-x-circle-fill me-1"></i> Reject Purchase Order</button>
                            </form>
                            <form action="po?action=approve" method="POST" class="d-inline m-0">
                                <input type="hidden" name="id" value="<%= po.getId() %>">
                                <button type="submit" class="btn btn-success px-4"><i class="bi bi-check-circle-fill me-1"></i> Approve Purchase Order</button>
                            </form>
                            <% } %>
                        <% } else if ("APPROVED".equals(po.getStatus())) { %>
                            <% if (po.getCancelRequestedAt() == null) { %>
                                <% if (canRequestCancel && canRequestCancelAction) { %>
                                <button type="button" class="btn btn-outline-danger px-4" data-bs-toggle="modal" data-bs-target="#requestCancelModal">
                                    <i class="bi bi-exclamation-octagon me-1"></i> Request Cancellation
                                </button>
                                <% } %>
                            <% } else { %>
                                <% if (canApproveCancel) { %>
                                <form action="po?action=rejectCancel" method="POST" class="d-inline m-0">
                                    <input type="hidden" name="id" value="<%= po.getId() %>">
                                    <button type="submit" class="btn btn-outline-success px-4"><i class="bi bi-x-circle me-1"></i> Reject Cancellation</button>
                                </form>
                                <form action="po?action=approveCancel" method="POST" class="d-inline m-0">
                                    <input type="hidden" name="id" value="<%= po.getId() %>">
                                    <button type="submit" class="btn btn-danger px-4"><i class="bi bi-check-circle-fill me-1"></i> Approve & Close PO</button>
                                </form>
                                <% } %>
                            <% } %>
                        <% } %>
                    </div>
                    <% } %>
                </div>

            </div>
        </div>
    </div>
    <!-- Request Cancellation Modal -->
    <div class="modal fade" id="requestCancelModal" tabindex="-1" aria-labelledby="requestCancelModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <form action="po?action=cancel" method="POST">
                    <input type="hidden" name="id" value="<%= po.getId() %>">
                    <div class="modal-header">
                        <h5 class="modal-title fw-bold text-slate-800" id="requestCancelModalLabel">Request PO Cancellation</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="cancelReason" class="form-label small fw-semibold text-muted">Lý do hủy đơn hàng</label>
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
