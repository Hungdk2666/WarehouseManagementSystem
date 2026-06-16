<%@page import="model.InternalDestination"%>
<%@page import="model.Product"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("EXPORT_REQ_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<InternalDestination> destinationList = (List<InternalDestination>) request.getAttribute("destinationList");
    List<Product> productList = (List<Product>) request.getAttribute("productList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Export Request - WMS</title>
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
                <div class="row justify-content-center">
                    <div class="col-md-11">
                        <form action="export-request?action=add" method="POST" id="requestForm">
                            <div class="card shadow-sm border-0 bg-white">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                    <h4 class="mb-0 fw-bold text-primary"><i class="bi bi-plus-circle-fill me-2"></i>Create Export Request</h4>
                                </div>
                                <div class="card-body p-4">
                                    <% if (request.getAttribute("error") != null) { %>
                                    <div class="alert alert-danger shadow-sm border-0 rounded-3 mb-3 d-flex align-items-center">
                                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                                        <%= request.getAttribute("error") %>
                                    </div>
                                    <% } %>

                                    <!-- Step 1: Request Header -->
                                    <div class="row mb-4">
                                        <div class="col-md-4">
                                            <label for="destinationSelect" class="form-label fw-semibold text-muted small mb-1">Internal Destination</label>
                                            <select class="form-select shadow-sm rounded-3" id="destinationSelect" name="destination_id" required style="box-shadow: none;">
                                                <option value="" disabled selected>-- Select Destination --</option>
                                                <%
                                                    if (destinationList != null) {
                                                        for (InternalDestination d : destinationList) {
                                                            if (d.isStatus()) {
                                                %>
                                                <option value="<%= d.getId() %>"><%= d.getDestinationName() %> (<%= d.getDestinationType() %>)</option>
                                                <%
                                                            }
                                                        }
                                                    }
                                                %>
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <label for="reasonSelect" class="form-label fw-semibold text-muted small mb-1">Export Reason</label>
                                            <select class="form-select shadow-sm rounded-3" id="reasonSelect" name="export_reason" required style="box-shadow: none;">
                                                <option value="TRANSFER">TRANSFER (Chuyển kho)</option>
                                                <option value="DISPOSAL">DISPOSAL (Tiêu hủy)</option>
                                                <option value="DISPLAY">DISPLAY (Hàng trưng bày)</option>
                                                <option value="OTHER">OTHER (Khác)</option>
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <label for="expectedDate" class="form-label fw-semibold text-muted small mb-1">Expected Export Date</label>
                                            <input type="date" class="form-control shadow-sm rounded-3" id="expectedDate" name="expected_date" required style="box-shadow: none;">
                                        </div>
                                    </div>

                                    <hr class="my-4 text-muted opacity-25">

                                    <!-- Step 2: Add Items -->
                                    <h5 class="fw-bold text-slate-800 mb-3"><i class="bi bi-box-seam me-2 text-primary"></i>Select Products</h5>
                                    <div class="row g-2 align-items-center mb-4">
                                        <div class="col-md-8">
                                            <select class="form-select shadow-sm rounded-3" id="productSelect" style="box-shadow: none;">
                                                <option value="" disabled selected>-- Select Product --</option>
                                                <%
                                                    if (productList != null) {
                                                        for (Product p : productList) {
                                                            if (p.isStatus()) {
                                                %>
                                                <option value="<%= p.getId() %>" data-sku="<%= p.getSku() %>" data-unit="<%= p.getUnit() %>" data-qty="<%= p.getQuantity() %>">
                                                    <%= p.getProductName() %> (SKU: <%= p.getSku() %>) [Stock: <%= p.getQuantity() %>]
                                                </option>
                                                <%
                                                            }
                                                        }
                                                    }
                                                %>
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <button type="button" class="btn btn-outline-primary w-100 py-2 d-inline-flex align-items-center justify-content-center gap-2" id="addItemBtn">
                                                <i class="bi bi-plus-lg"></i> Add to List
                                            </button>
                                        </div>
                                    </div>

                                    <!-- Table List -->
                                    <div class="table-responsive border rounded-3 mb-3">
                                        <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.9rem;">
                                            <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                                <tr>
                                                    <th class="text-start ps-4" style="width: 40%;">Product Name</th>
                                                    <th style="width: 15%;">SKU</th>
                                                    <th style="width: 10%;">Unit</th>
                                                    <th style="width: 15%;">Current Stock</th>
                                                    <th style="width: 15%;">Requested Qty</th>
                                                    <th style="width: 5%;">Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody id="itemsBody">
                                                <tr id="emptyRow">
                                                    <td colspan="6" class="text-muted py-4">No products added to this request yet.</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                                <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                                    <a href="export-request?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                                    <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Save Request</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script>
        const productSelect = document.getElementById("productSelect");
        const addItemBtn = document.getElementById("addItemBtn");
        const itemsBody = document.getElementById("itemsBody");
        const emptyRow = document.getElementById("emptyRow");
        const requestForm = document.getElementById("requestForm");
        
        let addedProducts = new Set();

        // Prevent past dates in expected_date
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('expectedDate').setAttribute('min', today);

        addItemBtn.addEventListener("click", function() {
            const selectedOpt = productSelect.options[productSelect.selectedIndex];
            if (!selectedOpt.value) {
                alert("Please select a product first.");
                return;
            }

            const productId = selectedOpt.value;
            const productName = selectedOpt.text.split(" (SKU:")[0];
            const sku = selectedOpt.getAttribute("data-sku");
            const unit = selectedOpt.getAttribute("data-unit");
            const currentStock = selectedOpt.getAttribute("data-qty");

            if (addedProducts.has(productId)) {
                alert("This product is already added to the list.");
                return;
            }

            // Hide empty row
            if (emptyRow) {
                emptyRow.style.display = "none";
            }

            // Create new row
            const tr = document.createElement("tr");
            tr.id = "item-row-" + productId;
            tr.innerHTML = 
                '<td class="text-start ps-4 fw-semibold">' +
                    '<input type="hidden" name="product_id" value="' + productId + '">' +
                    productName +
                '</td>' +
                '<td><span class="badge bg-secondary bg-opacity-10 text-secondary">' + sku + '</span></td>' +
                '<td>' + unit + '</td>' +
                '<td class="fw-semibold text-slate-700">' + currentStock + '</td>' +
                '<td>' +
                    '<input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="1" min="1" required style="box-shadow: none; max-width: 120px; margin: 0 auto;">' +
                '</td>' +
                '<td>' +
                    '<button type="button" class="btn btn-sm btn-outline-danger" onclick="removeItem(' + productId + ')">' +
                        '<i class="bi bi-trash"></i>' +
                    '</button>' +
                '</td>';

            itemsBody.appendChild(tr);
            addedProducts.add(productId);

            productSelect.selectedIndex = 0; // reset
        });

        function removeItem(id) {
            const row = document.getElementById("item-row-" + id);
            if (row) {
                row.remove();
                addedProducts.delete(id.toString());
            }

            if (addedProducts.size === 0) {
                if (emptyRow) {
                    emptyRow.style.display = "";
                }
            }
        }

        // Form validation
        requestForm.addEventListener("submit", function(e) {
            if (addedProducts.size === 0) {
                e.preventDefault();
                alert("You must add at least one product to submit the request.");
            }
        });
    </script>
</body>
</html>
