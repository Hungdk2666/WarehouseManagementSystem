<%@page import="model.Supplier"%>
<%@page import="model.Product"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("PO_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Supplier> supplierList = (List<Supplier>) request.getAttribute("supplierList");
    List<Product> productList = (List<Product>) request.getAttribute("productList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Purchase Order - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Create Purchase Order</h2>
                        <p class="text-muted small mb-0">Create new incoming stock requests for suppliers</p>
                    </div>
                    <a href="po?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Cancel
                    </a>
                </div>

                <div class="row">
                    <div class="col-12">
                        <form action="po?action=add" method="POST" id="poForm">
                            <div class="card shadow-sm border-0 bg-white mb-4">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-info-circle-fill me-2"></i>Purchase Order Metadata</h5>
                                </div>
                                <div class="card-body p-4">
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label for="supplierId" class="form-label">Select Supplier <span class="text-danger">*</span></label>
                                            <select class="form-select" id="supplierId" name="supplier_id" required>
                                                <option value="" disabled selected>-- Select Supplier --</option>
                                                <%
                                                    if (supplierList != null) {
                                                        for (Supplier s : supplierList) {
                                                            if (s.isStatus()) {
                                                %>
                                                <option value="<%= s.getId() %>"><%= s.getSupplierName() %></option>
                                                <%
                                                            }
                                                        }
                                                    }
                                                %>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="expectedDate" class="form-label">Expected Fulfillment Date <span class="text-danger">*</span></label>
                                            <input type="date" class="form-control" id="expectedDate" name="expected_date" required>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="card shadow-sm border-0 bg-white mb-4">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-list-stars me-2"></i>Purchase Order Items</h5>
                                </div>
                                <div class="card-body p-4">
                                    <div class="row g-2 align-items-end mb-4 border-bottom pb-4">
                                        <div class="col-md-8">
                                            <label for="productSelect" class="form-label">Select Product to Add</label>
                                            <select class="form-select" id="productSelect">
                                                <option value="" disabled selected>-- Select Product --</option>
                                                <%
                                                    if (productList != null) {
                                                        for (Product p : productList) {
                                                            if (p.isStatus()) {
                                                %>
                                                <option value="<%= p.getId() %>" data-sku="<%= p.getSku() %>" data-unit="<%= p.getUnit() %>" data-cost="<%= p.getDefaultCost() %>">
                                                    <%= p.getProductName() %> (SKU: <%= p.getSku() %>)
                                                </option>
                                                <%
                                                            }
                                                        }
                                                    }
                                                %>
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <button type="button" class="btn btn-primary w-100" id="addItemBtn">
                                                <i class="bi bi-plus-circle me-1"></i> Add Item
                                            </button>
                                        </div>
                                    </div>

                                    <div class="table-responsive">
                                        <table class="table align-middle text-center" id="itemsTable">
                                            <thead class="table-light">
                                                <tr>
                                                    <th class="text-start ps-4">Product Name</th>
                                                    <th>SKU</th>
                                                    <th>Unit</th>
                                                    <th style="width: 15%;">Quantity</th>
                                                    <th style="width: 20%;">Expected Cost Price (VND)</th>
                                                    <th>Total Cost</th>
                                                    <th>Actions</th>
                                                </tr>
                                            </thead>
                                            <tbody id="itemsBody">
                                                <tr id="emptyRow">
                                                    <td colspan="7" class="text-muted py-4">No items added to this purchase order yet.</td>
                                                </tr>
                                            </tbody>
                                            <tfoot>
                                                <tr class="table-light fw-bold">
                                                    <td colspan="5" class="text-end pe-4">Estimated Total Cost:</td>
                                                    <td id="grandTotal">0 VND</td>
                                                    <td></td>
                                                </tr>
                                            </tfoot>
                                        </table>
                                    </div>
                                </div>
                                <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                                    <a href="po?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                                    <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Save Purchase Order</button>
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
        const grandTotalSpan = document.getElementById("grandTotal");
        const poForm = document.getElementById("poForm");
        
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
            const defaultCost = selectedOpt.getAttribute("data-cost") || 0;

            if (addedProducts.has(productId)) {
                alert("This product is already added to the PO list.");
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
                '<td>' +
                    '<input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="1" min="1" required style="box-shadow: none;">' +
                '</td>' +
                '<td>' +
                    '<input type="number" class="form-control form-control-sm text-end price-input" name="unit_price" value="' + defaultCost + '" min="0" required style="box-shadow: none;">' +
                '</td>' +
                '<td class="fw-bold row-total">' + formatNumber(defaultCost) + ' VND</td>' +
                '<td>' +
                    '<button type="button" class="btn btn-sm btn-outline-danger" onclick="removeItem(' + productId + ')">' +
                        '<i class="bi bi-trash"></i> Remove' +
                    '</button>' +
                '</td>';

            itemsBody.appendChild(tr);
            addedProducts.add(productId);

            // Add events to inputs for real-time recalculations
            const qtyInput = tr.querySelector(".qty-input");
            const priceInput = tr.querySelector(".price-input");
            
            qtyInput.addEventListener("input", recalculateTotals);
            priceInput.addEventListener("input", recalculateTotals);

            recalculateTotals();
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
            recalculateTotals();
        }

        function recalculateTotals() {
            let total = 0;
            const rows = itemsBody.querySelectorAll("tr");
            
            rows.forEach(row => {
                if (row.id === "emptyRow") return;
                
                const qty = parseInt(row.querySelector(".qty-input").value) || 0;
                const price = parseFloat(row.querySelector(".price-input").value) || 0;
                const rowTotal = qty * price;
                
                total += rowTotal;
                row.querySelector(".row-total").textContent = formatNumber(rowTotal) + " VND";
            });
            
            grandTotalSpan.textContent = formatNumber(total) + " VND";
        }

        function formatNumber(num) {
            return parseFloat(num).toLocaleString('vi-VN');
        }

        poForm.addEventListener("submit", function(e) {
            if (addedProducts.size === 0) {
                e.preventDefault();
                alert("Please add at least one product item to the purchase order.");
            }
        });
    </script>
</body>
</html>
