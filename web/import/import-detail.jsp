<%@page import="model.ImportTicket"%>
<%@page import="model.ImportTicketDetail"%>
<%@page import="model.User"%>
<%@page import="model.ProductItem"%>
<%@page import="java.util.List"%>
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
    boolean canConfirm = loggedInUser.hasPermission("IMPORT_TICKET_CONFIRM");
    boolean canCancel = loggedInUser.hasPermission("IMPORT_TICKET_CANCEL");
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
                    
                    <% if ("DRAFT".equals(ticket.getStatus()) && (canConfirm || canCancel)) { %>
                    <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                        <% if (canCancel) { %>
                        <form action="import?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Are you sure you want to cancel this ticket?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <button type="submit" class="btn btn-outline-danger px-4"><i class="bi bi-x-circle me-1"></i> Cancel Ticket</button>
                        </form>
                        <% } %>
                        <% if (canConfirm) { %>
                        <form action="import?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Are you sure you want to confirm this ticket?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <button type="submit" class="btn btn-success px-4"><i class="bi bi-check-circle-fill me-1"></i> Confirm & Post Stock</button>
                        </form>
                        <% } %>
                    </div>
                    <% } %>
                </div>

                <%
                    List<ProductItem> importedSerials = (List<ProductItem>) request.getAttribute("importedSerials");
                    if (importedSerials != null && !importedSerials.isEmpty()) {
                %>
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-success bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-success"><i class="bi bi-qr-code-scan me-2"></i>Generated Serial Numbers & Barcodes</h5>
                        <button class="btn btn-success btn-sm d-inline-flex align-items-center gap-1" onclick="printBarcodes()">
                            <i class="bi bi-printer-fill"></i> Print All Barcode Labels
                        </button>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3" id="barcode-list-container">
                            <% for (ProductItem item : importedSerials) { %>
                            <div class="col-md-4 col-sm-6 text-center barcode-card-item mb-2">
                                <div class="border rounded p-3 bg-light">
                                    <div class="fw-semibold text-slate-800 small text-truncate mb-1" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                    <svg class="barcode-svg" data-value="<%= item.getSerialNumber() %>"></svg>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
                <!-- Hidden Printable Area -->
                <div class="d-none">
                    <div id="printable-barcodes-section">
                        <div style="display: flex; flex-wrap: wrap; justify-content: space-around; padding: 20px; font-family: 'Inter', sans-serif;">
                            <% for (ProductItem item : importedSerials) { %>
                            <div style="border: 1px solid #ccc; border-radius: 4px; padding: 15px; margin: 10px; background-color: #fff; text-align: center; width: 280px; page-break-inside: avoid; box-sizing: border-box;">
                                <div style="font-weight: bold; color: #333; margin-bottom: 5px; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                <svg class="printable-barcode-svg" data-value="<%= item.getSerialNumber() %>" style="max-width: 100%; height: auto;"></svg>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
                <script>
                    document.addEventListener("DOMContentLoaded", function() {
                        // Render standard display barcodes
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
                        
                        // Render printable barcodes
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
                        
                        // Replace body with print-only content
                        document.body.innerHTML = '<div>' + printContent + '</div>';
                        window.print();
                        
                        // Restore original page content
                        document.body.innerHTML = originalContent;
                        window.location.reload(); // reload to restore scripts/events
                    }
                </script>
                <% } %>

            </div>
        </div>
    </div>
</body>
</html>
