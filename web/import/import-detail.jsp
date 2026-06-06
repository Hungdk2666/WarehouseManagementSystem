<%@page import="model.ImportTicket"%>
<%@page import="model.ImportTicketDetail"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("IMPORT_TICKET_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    ImportTicket ticket = (ImportTicket) request.getAttribute("ticket");
    if (ticket == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/import?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Import Ticket Detail - #<%= ticket.getTicketCode() %></title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Import Ticket Detail</h2>
                        <p class="text-muted small mb-0">View items and confirm stock addition for Import Ticket #<%= ticket.getTicketCode() %></p>
                    </div>
                    <a href="import?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back to List
                    </a>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-info-circle-fill me-2"></i>Import Ticket Metadata</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Import Ticket Code</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getTicketCode() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Linked PO Code</label>
                                <span class="fw-bold text-primary">#<%= ticket.getRequestCode() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Status</label>
                                <%
                                    String statusBadge = "bg-secondary text-secondary";
                                    if ("DRAFT".equals(ticket.getStatus())) statusBadge = "bg-warning text-warning";
                                    else if ("CONFIRMED".equals(ticket.getStatus())) statusBadge = "bg-success text-success";
                                    else if ("CANCELLED".equals(ticket.getStatus())) statusBadge = "bg-secondary text-secondary";
                                %>
                                <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= ticket.getStatus() %></span>
                            </div>
                            
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Created By (Keeper)</label>
                                <span class="text-slate-700"><%= ticket.getKeeperFullName() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Created At</label>
                                <span class="text-slate-700"><%= ticket.getCreatedAt() %></span>
                            </div>
                            
                            <% if (ticket.getConfirmedBy() != null) { %>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Confirmed By (Manager)</label>
                                <span class="text-slate-700"><%= ticket.getConfirmedByFullName() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Confirmed At</label>
                                <span class="text-slate-700"><%= ticket.getConfirmedAt() %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-list-check me-2"></i>Received Items</h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table align-middle text-center mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th class="text-start ps-4">Product Name</th>
                                    <th>SKU</th>
                                    <th>Unit</th>
                                    <th>Actual Received Qty</th>
                                    <th>Actual Cost Price</th>
                                    <th>Total Cost</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    double totalCost = 0;
                                    if (ticket.getDetails() != null && !ticket.getDetails().isEmpty()) {
                                        int index = 1;
                                        for (ImportTicketDetail d : ticket.getDetails()) {
                                            double itemCost = d.getQuantity() * d.getUnitPrice();
                                            totalCost += itemCost;
                                %>
                                <tr>
                                    <td><%= index++ %></td>
                                    <td class="text-start ps-4 fw-semibold"><%= d.getProductName() %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                    <td><%= d.getUnit() %></td>
                                    <td class="fw-bold"><%= d.getQuantity() %></td>
                                    <td><%= String.format("%,.0f", d.getUnitPrice()) %> VND</td>
                                    <td class="fw-bold"><%= String.format("%,.0f", itemCost) %> VND</td>
                                </tr>
                                <%
                                        }
                                    }
                                %>
                                <tr class="table-light fw-bold">
                                    <td colspan="6" class="text-end pe-4">Total Cost:</td>
                                    <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    
                </div>

            </div>
        </div>
    </div>
</body>
</html>
