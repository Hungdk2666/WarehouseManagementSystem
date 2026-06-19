<%@page import="model.Supplier"%>
<%@page import="model.Product"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_ADD_IN")) {
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
    <title>Tạo Yêu cầu nhập kho - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link href="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/css/tom-select.bootstrap5.min.css" rel="stylesheet">
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
                        <h2 class="fw-bold text-slate-800 mb-1">Tạo Yêu cầu nhập kho</h2>
                        <p class="text-muted small mb-0">Tạo mới yêu cầu nhập hàng từ nhà cung cấp</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Hủy
                    </a>
                </div>
 
                <div class="row">
                    <div class="col-12">
                        <form action="<%= request.getContextPath() %>/warehouse/import-request?action=add" method="POST" id="reqForm">
                            <div class="card card-overflow-visible shadow-sm border-0 bg-white mb-4" style="overflow: visible;">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-info-circle-fill me-2"></i>Thông tin Yêu cầu nhập kho</h5>
                                </div>
                                <div class="card-body p-4">
                                    <% if (request.getAttribute("error") != null) { %>
                                    <div class="alert alert-danger mb-3"><i class="bi bi-exclamation-triangle-fill me-2"></i><%= request.getAttribute("error") %></div>
                                    <% } %>
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label for="supplierId" class="form-label">Nhà cung cấp <span class="text-danger">*</span></label>
                                            <select class="form-select" id="supplierId" name="supplier_id" required>
                                                <option value=""></option>
                                                <% if (supplierList != null) { for (Supplier s : supplierList) { if (s.isStatus()) { %>
                                                <option value="<%= s.getId() %>"><%= s.getSupplierName() %></option>
                                                <% } } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="expectedDate" class="form-label">Ngày nhận hàng dự kiến <span class="text-danger">*</span></label>
                                            <input type="date" class="form-control" id="expectedDate" name="expected_date" required>
                                        </div>
                                    </div>
                                </div>
                            </div>
 
                            <div class="card card-overflow-visible shadow-sm border-0 bg-white mb-4" style="overflow: visible;">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                    <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-list-stars me-2"></i>Sản phẩm cần nhập</h5>
                                </div>
                                <div class="card-body p-4">
                                    <div class="row g-2 align-items-end mb-4 border-bottom pb-4">
                                        <div class="col-md-8">
                                            <label for="productSelect" class="form-label">Chọn sản phẩm để thêm</label>
                                            <select class="form-select" id="productSelect">
                                                <option value=""></option>
                                                <% if (productList != null) { for (Product p : productList) { if (p.isStatus()) { %>
                                                <option value="<%= p.getId() %>" data-sku="<%= p.getSku() %>" data-unit="<%= p.getUnit() %>" data-cost="<%= p.getAverageCost() %>">
                                                    <%= p.getProductName() %> (SKU: <%= p.getSku() %>)
                                                </option>
                                                <% } } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <button type="button" class="btn btn-primary w-100" id="addItemBtn">
                                                <i class="bi bi-plus-circle me-1"></i> Thêm sản phẩm
                                            </button>
                                        </div>
                                    </div>
 
                                    <div class="table-responsive">
                                        <table class="table align-middle text-center" id="itemsTable">
                                            <thead class="table-light">
                                                <tr>
                                                    <th class="text-start ps-4">Tên sản phẩm</th>
                                                    <th>SKU</th>
                                                    <th>Đơn vị</th>
                                                    <th style="width: 15%;">Số lượng</th>
                                                    <th style="width: 20%;">Đơn giá nhập (VND)</th>
                                                    <th>Thành tiền</th>
                                                    <th>Xóa</th>
                                                </tr>
                                            </thead>
                                            <tbody id="itemsBody">
                                                <tr id="emptyRow">
                                                    <td colspan="7" class="text-muted py-4">Chưa có sản phẩm nào được thêm.</td>
                                                </tr>
                                            </tbody>
                                            <tfoot>
                                                <tr class="table-light fw-bold">
                                                    <td colspan="5" class="text-end pe-4">Tổng giá trị ước tính:</td>
                                                    <td id="grandTotal">0 VND</td>
                                                    <td></td>
                                                </tr>
                                            </tfoot>
                                        </table>
                                    </div>
                                </div>
                                 <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                                     <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                                     <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Lưu Yêu cầu nhập kho</button>
                                 </div>
                            </div>
                        </form>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>
    <script>
        const productSelect = document.getElementById("productSelect");
        const addItemBtn = document.getElementById("addItemBtn");
        const itemsBody = document.getElementById("itemsBody");
        const emptyRow = document.getElementById("emptyRow");
        const grandTotalSpan = document.getElementById("grandTotal");
        const reqForm = document.getElementById("reqForm");

        let addedProducts = new Set();
        let tsSupplier, tsProduct;

        document.addEventListener("DOMContentLoaded", function() {
            tsSupplier = new TomSelect("#supplierId", { create: false, placeholder: "-- Chọn nhà cung cấp --" });
            tsProduct  = new TomSelect("#productSelect", { create: false, placeholder: "-- Chọn sản phẩm --" });
        });

        function getLocalTodayString() {
            const today = new Date();
            const yyyy = today.getFullYear();
            const mm = String(today.getMonth() + 1).padStart(2, '0');
            const dd = String(today.getDate()).padStart(2, '0');
            return yyyy + "-" + mm + "-" + dd;
        }

        const expectedDateInput = document.getElementById('expectedDate');
        const localToday = getLocalTodayString();
        expectedDateInput.setAttribute('min', localToday);

        function validateDateInput(input) {
            // Chỉ validate khi đã nhập đủ ngày tháng năm (10 ký tự YYYY-MM-DD)
            if (input.value && input.value.length === 10 && input.value < localToday) {
                input.classList.add("is-invalid");
                let errEl = document.getElementById("expectedDateError");
                if (!errEl) {
                    errEl = document.createElement("div");
                    errEl.id = "expectedDateError";
                    errEl.className = "invalid-feedback";
                    errEl.textContent = "Ngày dự kiến không được ở trong quá khứ!";
                    input.parentNode.appendChild(errEl);
                }
            } else if (input.value.length === 10) {
                input.classList.remove("is-invalid");
                input.classList.add("is-valid");
                const errEl = document.getElementById("expectedDateError");
                if (errEl) errEl.remove();
            } else {
                input.classList.remove("is-invalid", "is-valid");
                const errEl = document.getElementById("expectedDateError");
                if (errEl) errEl.remove();
            }
        }

        // Chỉ validate khi người dùng đã chọn xong (change = nhấp xong calendar picker)
        expectedDateInput.addEventListener("change", function() {
            validateDateInput(this);
        });
        // Với input tay: chỉ validate khi đã nhập đủ 10 ký tự
        expectedDateInput.addEventListener("input", function() {
            if (this.value.length === 10) validateDateInput(this);
        });

        addItemBtn.addEventListener("click", function() {
            const productId = productSelect.value;
            if (!productId) { alert("Vui lòng chọn sản phẩm trước."); return; }
            if (addedProducts.has(productId)) { alert("Sản phẩm này đã được thêm."); return; }

            const opt = productSelect.querySelector('option[value="' + productId + '"]');
            const productName = opt.text.split(" (SKU:")[0];
            const sku = opt.dataset.sku;
            const unit = opt.dataset.unit;
            const defaultCost = opt.dataset.cost || 0;

            if (emptyRow) emptyRow.style.display = "none";

            const tr = document.createElement("tr");
            tr.id = "item-row-" + productId;
            tr.innerHTML =
                '<td class="text-start ps-4 fw-semibold">' +
                    '<input type="hidden" name="product_id" value="' + productId + '">' +
                    productName +
                '</td>' +
                '<td><span class="badge bg-secondary bg-opacity-10 text-secondary">' + sku + '</span></td>' +
                '<td>' + unit + '</td>' +
                '<td><input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="1" min="1" required></td>' +
                '<td><input type="number" class="form-control form-control-sm text-end price-input" name="unit_price" value="' + defaultCost + '" min="0" required></td>' +
                '<td class="fw-bold row-total">' + formatNumber(defaultCost) + ' VND</td>' +
                '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="removeItem(' + productId + ')"><i class="bi bi-trash"></i></button></td>';

            itemsBody.appendChild(tr);
            addedProducts.add(productId);

            tr.querySelector(".qty-input").addEventListener("input", recalculateTotals);
            tr.querySelector(".price-input").addEventListener("input", recalculateTotals);
            recalculateTotals();

            if (tsProduct) tsProduct.clear(); else productSelect.selectedIndex = 0;
        });

        function removeItem(id) {
            const row = document.getElementById("item-row-" + id);
            if (row) { row.remove(); addedProducts.delete(id.toString()); }
            if (addedProducts.size === 0 && emptyRow) emptyRow.style.display = "";
            recalculateTotals();
        }

        function recalculateTotals() {
            let total = 0;
            itemsBody.querySelectorAll("tr").forEach(row => {
                if (row.id === "emptyRow") return;
                const qty = parseInt(row.querySelector(".qty-input").value) || 0;
                const price = parseFloat(row.querySelector(".price-input").value) || 0;
                const rowTotal = qty * price;
                total += rowTotal;
                row.querySelector(".row-total").textContent = formatNumber(rowTotal) + " VND";
            });
            grandTotalSpan.textContent = formatNumber(total) + " VND";
        }

        function formatNumber(num) { return parseFloat(num).toLocaleString('vi-VN'); }

        reqForm.addEventListener("submit", function(e) {
            if (!document.getElementById("supplierId").value) {
                e.preventDefault(); alert("Vui lòng chọn nhà cung cấp."); return;
            }
            if (addedProducts.size === 0) {
                e.preventDefault(); alert("Vui lòng thêm ít nhất một sản phẩm.");
            }
        });
    </script>
</body>
</html>
