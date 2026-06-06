<%@page import="model.ImportRequest"%>
<%@page import="model.ImportRequestDetail"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("IMPORT_TICKET_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<ImportRequest> poList = (List<ImportRequest>) request.getAttribute("poList");
    ImportRequest selectedPO = (ImportRequest) request.getAttribute("selectedPO");
    
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Import Ticket - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Create Import Ticket</h2>
                        <p class="text-muted small mb-0">Record physical stock arrival against approved Purchase Orders</p>
                    </div>
                    <a href="import?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Cancel
                    </a>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger border-0 shadow-sm rounded-3 mb-4">
                    <% if ("NoItemsReceived".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> You must receive at least 1 item (quantity > 0) to save the Import Ticket.
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Failed to create Import Ticket. Please try again.
                    <% } %>
                </div>
                <% } %>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-receipt me-2"></i>Select Reference Purchase Order</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row align-items-end g-3">
                            <div class="col-md-8">
                                <label for="poSelect" class="form-label">Reference PO <span class="text-danger">*</span></label>
                                <select class="form-select" id="poSelect" onchange="loadPOItems(this.value)">
                                    <option value="" disabled <%= selectedPO == null ? "selected" : "" %>>-- Select Approved/Active PO --</option>
                                    <%
                                        if (poList != null) {
                                            for (ImportRequest r : poList) {
                                                boolean isSel = selectedPO != null && selectedPO.getId() == r.getId();
                                    %>
                                    <option value="<%= r.getId() %>" <%= isSel ? "selected" : "" %>>
                                        #<%= r.getRequestCode() %> - <%= r.getSupplierName() %> (Status: <%= r.getStatus() %>)
                                    </option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <button type="button" class="btn btn-outline-secondary w-100" onclick="resetPOSelection()">
                                    <i class="bi bi-arrow-clockwise"></i> Clear Selection
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (selectedPO != null) { %>
                <form action="import?action=add" method="POST" id="grnForm">
                    <input type="hidden" name="po_id" value="<%= selectedPO.getId() %>">
                    
                    <div class="card shadow-sm border-0 bg-white mb-4">
                        <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                            <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-seam me-2"></i>Import Ticket Details</h5>
                        </div>
                        <div class="card-body p-0">
                            <table class="table align-middle text-center mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-start ps-4">Product Name</th>
                                        <th>SKU</th>
                                        <th>Unit</th>
                                        <th>Requested Qty in PO</th>
                                        <th>Expected Unit Price</th>
                                        <th style="width: 15%;">Actual Received Qty</th>
                                        <th style="width: 20%;">Actual Cost Price (VND)</th>
                                        <th>Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (selectedPO.getDetails() != null) {
                                            for (ImportRequestDetail d : selectedPO.getDetails()) {
                                    %>
                                    <tr>
                                        <td class="text-start ps-4 fw-semibold">
                                            <input type="hidden" name="product_id" value="<%= d.getProductId() %>">
                                            <%= d.getProductName() %>
                                        </td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                        <td><%= d.getUnit() %></td>
                                        <td class="text-muted"><%= d.getQuantity() %></td>
                                        <td class="text-muted"><%= String.format("%,.0f", d.getUnitPrice()) %> VND</td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="<%= d.getQuantity() %>" min="0" max="<%= d.getQuantity() %>" required style="box-shadow: none;">
                                        </td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm text-end price-input" name="unit_price" value="<%= d.getUnitPrice() %>" min="0" required style="box-shadow: none;">
                                        </td>
                                        <td class="fw-bold row-total"><%= String.format("%,.0f", d.getQuantity() * d.getUnitPrice()) %> VND</td>
                                    </tr>
                                    <%
                                            }
                                        }
                                    %>
                                    <tr class="table-light fw-bold">
                                        <td colspan="7" class="text-end pe-4">Total Cost:</td>
                                        <td id="grandTotal">0 VND</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                            <a href="import?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                            <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Save Draft Import Ticket</button>
                        </div>
                    </div>
                </form>
                <% } %>

            </div>
        </div>
    </div>

    <script>
        function loadPOItems(poId) {
            if (poId) {
                window.location.href = "import?action=add&request_id=" + poId;
            }
        }

        function resetPOSelection() {
            window.location.href = 'import?action=add';
        }

        <% if (selectedPO != null) { %>
        document.addEventListener("DOMContentLoaded", function() {
            const qtyInputs = document.querySelectorAll(".qty-input");
            const priceInputs = document.querySelectorAll(".price-input");
            
            qtyInputs.forEach(input => input.addEventListener("input", recalculateTotals));
            priceInputs.forEach(input => input.addEventListener("input", recalculateTotals));
            
            recalculateTotals();
        });

        function recalculateTotals() {
            let total = 0;
            const rows = document.querySelectorAll("#grnForm tbody tr");
            
            rows.forEach(row => {
                const qtyInput = row.querySelector(".qty-input");
                const priceInput = row.querySelector(".price-input");
                
                if (qtyInput && priceInput) {
                    const qty = parseInt(qtyInput.value) || 0;
                    const price = parseFloat(priceInput.value) || 0;
                    const rowTotal = qty * price;
                    
                    total += rowTotal;
                    row.querySelector(".row-total").textContent = formatNumber(rowTotal) + " VND";
                }
            });
            
            document.getElementById("grandTotal").textContent = formatNumber(total) + " VND";
        }

        function formatNumber(num) {
            return parseFloat(num).toLocaleString('vi-VN');
        }

        document.getElementById("grnForm").addEventListener("submit", function(e) {
            const qtyInputs = document.querySelectorAll(".qty-input");
            let totalQty = 0;
            qtyInputs.forEach(input => {
                totalQty += parseInt(input.value) || 0;
            });

            if (totalQty <= 0) {
                e.preventDefault();
                alert("You must receive at least 1 item (quantity > 0) to save the Import Ticket.");
            }
        });
        <% } %>
    </script>
</body>
</html>
