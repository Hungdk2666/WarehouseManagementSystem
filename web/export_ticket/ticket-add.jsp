<%@page import="model.ExportRequest"%>
<%@page import="model.ExportRequestDetail"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("EXPORT_TICKET_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<ExportRequest> reqList = (List<ExportRequest>) request.getAttribute("reqList");
    ExportRequest selectedReq = (ExportRequest) request.getAttribute("selectedReq");
    
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Export Ticket - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Create Export Ticket</h2>
                        <p class="text-muted small mb-0">Record physical stock dispatch against approved Export Requests</p>
                    </div>
                    <a href="export-ticket?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Cancel
                    </a>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger border-0 shadow-sm rounded-3 mb-4">
                    <% if ("NoItemsDispatched".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> You must dispatch at least 1 item (quantity > 0) to save the Export Ticket.
                    <% } else if ("ExceededRemainingQuantity".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Dispatch quantity exceeds the remaining requested quantity.
                    <% } else if ("InsufficientStock".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Insufficient inventory stock for one or more products.
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Failed to create Export Ticket. Error code: <%= error %>. Please try again.
                    <% } %>
                </div>
                <% } %>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-receipt me-2"></i>Select Reference Export Request</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row align-items-end g-3">
                            <div class="col-md-8">
                                <label for="reqSelect" class="form-label">Reference Export Request <span class="text-danger">*</span></label>
                                <select class="form-select" id="reqSelect" onchange="loadRequestItems(this.value)">
                                    <option value="" disabled <%= selectedReq == null ? "selected" : "" %>>-- Select Approved Export Request --</option>
                                    <%
                                        if (reqList != null) {
                                            for (ExportRequest r : reqList) {
                                                boolean isSel = selectedReq != null && selectedReq.getId() == r.getId();
                                    %>
                                    <option value="<%= r.getId() %>" <%= isSel ? "selected" : "" %>>
                                        #<%= r.getRequestCode() %> - Destination: <%= r.getDestinationName() %> (Status: <%= r.getStatus() %>)
                                    </option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <button type="button" class="btn btn-outline-secondary w-100" onclick="resetRequestSelection()">
                                    <i class="bi bi-arrow-clockwise"></i> Clear Selection
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (selectedReq != null) { %>
                <form action="export-ticket?action=add" method="POST" id="ginForm">
                    <input type="hidden" name="request_id" value="<%= selectedReq.getId() %>">
                    
                    <div class="card shadow-sm border-0 bg-white mb-4">
                        <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                            <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-seam me-2"></i>Export Ticket Details</h5>
                        </div>
                        <div class="card-body p-0">
                            <table class="table align-middle text-center mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-start ps-4">Product Name</th>
                                        <th>SKU</th>
                                        <th>Unit</th>
                                        <th>Requested Qty</th>
                                        <th>Already Issued</th>
                                        <th>Remaining Requested</th>
                                        <th>Current Stock</th>
                                        <th style="width: 15%;">Quantity to Issue</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (selectedReq.getDetails() != null) {
                                            for (ExportRequestDetail d : selectedReq.getDetails()) {
                                                int remaining = d.getQuantity() - d.getIssuedQuantity();
                                                if (remaining < 0) remaining = 0;
                                                // Default issue qty: min(remaining, currentStock)
                                                int defaultIssue = Math.min(remaining, d.getCurrentStock());
                                                if (defaultIssue < 0) defaultIssue = 0;
                                    %>
                                    <tr>
                                        <td class="text-start ps-4 fw-semibold">
                                            <input type="hidden" name="product_id" value="<%= d.getProductId() %>">
                                            <%= d.getProductName() %>
                                        </td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                        <td><%= d.getUnit() %></td>
                                        <td class="text-muted"><%= d.getQuantity() %></td>
                                        <td class="text-muted text-success fw-semibold"><%= d.getIssuedQuantity() %></td>
                                        <td class="fw-semibold text-primary"><%= remaining %></td>
                                        <td class="fw-semibold <%= d.getCurrentStock() < remaining ? "text-danger" : "text-dark" %>">
                                            <%= d.getCurrentStock() %>
                                        </td>
                                        <td>
                                            <input type="number" 
                                                   class="form-control form-control-sm text-center qty-input" 
                                                   name="quantity" 
                                                   value="<%= defaultIssue %>" 
                                                   min="0" 
                                                   max="<%= remaining %>" 
                                                   data-remaining="<%= remaining %>"
                                                   data-stock="<%= d.getCurrentStock() %>"
                                                   data-pname="<%= d.getProductName() %>"
                                                   required 
                                                   style="box-shadow: none;">
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                        <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                            <a href="export-ticket?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                            <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Save Draft Export Ticket</button>
                        </div>
                    </div>
                </form>
                <% } %>

            </div>
        </div>
    </div>

    <script>
        function loadRequestItems(reqId) {
            if (reqId) {
                window.location.href = "export-ticket?action=add&request_id=" + reqId;
            }
        }

        function resetRequestSelection() {
            window.location.href = 'export-ticket?action=add';
        }

        <% if (selectedReq != null) { %>
        document.getElementById("ginForm").addEventListener("submit", function(e) {
            const qtyInputs = document.querySelectorAll(".qty-input");
            let totalQty = 0;
            let validationFailed = false;

            qtyInputs.forEach(input => {
                const qty = parseInt(input.value) || 0;
                totalQty += qty;
                
                const remaining = parseInt(input.getAttribute("data-remaining")) || 0;
                const stock = parseInt(input.getAttribute("data-stock")) || 0;
                const pname = input.getAttribute("data-pname") || "Product";

                if (qty > remaining) {
                    alert("Error: For '" + pname + "', dispatch quantity (" + qty + ") cannot exceed the remaining requested quantity (" + remaining + ").");
                    validationFailed = true;
                }
                
                if (qty > stock) {
                    alert("Error: For '" + pname + "', dispatch quantity (" + qty + ") cannot exceed the current stock in inventory (" + stock + ").");
                    validationFailed = true;
                }
            });

            if (validationFailed) {
                e.preventDefault();
                return;
            }

            if (totalQty <= 0) {
                e.preventDefault();
                alert("You must dispatch at least 1 item (quantity > 0) to save the Export Ticket.");
            }
        });
        <% } %>
    </script>
</body>
</html>
