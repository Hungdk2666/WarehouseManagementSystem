<%@page import="model.InternalDestination"%>
<%@page import="model.Product"%>
<%@page import="model.Warehouse"%>
<%@page import="model.Customer"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_ADD_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<InternalDestination> destinationList = (List<InternalDestination>) request.getAttribute("destinationList");
    List<Product> productList = (List<Product>) request.getAttribute("productList");
    List<Warehouse> warehouseList = (List<Warehouse>) request.getAttribute("warehouseList");
    List<Customer> customerList = (List<Customer>) request.getAttribute("customerList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo Yêu Cầu Xuất Kho - WMS</title>
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
                <div class="row justify-content-center">
                    <div class="col-md-11">
                        <form action="<%= request.getContextPath() %>/warehouse/export-request?action=add" method="POST" id="requestForm">
                            <div class="card shadow-sm border-0 bg-white" style="overflow: visible;">
                                <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                    <h4 class="mb-0 fw-bold text-primary"><i class="bi bi-plus-circle-fill me-2"></i>Tạo Yêu Cầu Xuất Kho</h4>
                                </div>
                                <div class="card-body p-4">
                                    <% if (request.getAttribute("error") != null) { %>
                                    <div class="alert alert-danger shadow-sm border-0 rounded-3 mb-3 d-flex align-items-center">
                                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                                        <%= request.getAttribute("error") %>
                                    </div>
                                    <% } %>

                                    <div class="row mb-3">
                                        <div class="col-md-3">
                                            <label for="reasonSelect" class="form-label fw-semibold text-muted small mb-1">Lý do xuất kho <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="reasonSelect" name="export_reason" required>
                                                <option value=""></option>
                                                <option value="TRANSFER">TRANSFER — Chuyển kho nội bộ</option>
                                                <option value="CUSTOMER_SALE">CUSTOMER_SALE — Xuất bán cho khách hàng</option>
                                                <option value="DISPLAY">DISPLAY — Hàng trưng bày</option>
                                                <option value="WARRANTY">WARRANTY — Bảo hành / sửa chữa</option>
                                                <option value="DISPOSAL">DISPOSAL — Tiêu hủy</option>
                                                <option value="OTHER">OTHER — Lý do khác</option>
                                            </select>
                                        </div>
                                        <div class="col-md-3">
                                            <label for="expectedDate" class="form-label fw-semibold text-muted small mb-1">Ngày xuất kho dự kiến <span class="text-danger">*</span></label>
                                            <input type="date" class="form-control shadow-sm rounded-3" id="expectedDate" name="expected_date" required>
                                        </div>
                                        <div class="col-md-3">
                                            <label for="sourceWarehouseSelect" class="form-label fw-semibold text-muted small mb-1">Kho nguồn <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="sourceWarehouseSelect" name="source_warehouse_id" required>
                                                <option value=""></option>
                                                <% if (warehouseList != null) { for (Warehouse w : warehouseList) { %>
                                                <option value="<%= w.getId() %>"><%= w.getWarehouseName() %></option>
                                                <% } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-3">
                                            <label for="conditionSelect" class="form-label fw-semibold text-muted small mb-1">Tình trạng xuất <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="conditionSelect" name="requested_condition" required>
                                                <option value="NEW" selected>Hàng Mới (NEW)</option>
                                                <option value="USED">Hàng Cũ (USED)</option>
                                            </select>
                                        </div>
                                    </div>

                                    <!-- Conditional destination fields -->
                                    <!-- TRANSFER: target warehouse -->
                                    <div id="transferFields" class="row mb-3 d-none">
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Kho đích <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="targetWarehouseSelect" name="target_warehouse_id">
                                                <option value=""></option>
                                                <% if (warehouseList != null) { for (Warehouse w : warehouseList) { %>
                                                <option value="<%= w.getId() %>"><%= w.getWarehouseName() %> — <%= w.getAddress() != null ? w.getAddress() : "" %></option>
                                                <% } } %>
                                            </select>
                                        </div>
                                    </div>

                                    <!-- CUSTOMER_SALE: customer + shipping address -->
                                    <div id="customerSaleFields" class="row mb-3 d-none">
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Khách hàng <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="customerSelect" name="customer_id">
                                                <option value=""></option>
                                                <% if (customerList != null) { for (Customer cu : customerList) { %>
                                                <option value="<%= cu.getId() %>"><%= cu.getCustomerName() %><%= cu.getPhone() != null ? " (" + cu.getPhone() + ")" : "" %></option>
                                                <% } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Địa chỉ giao hàng</label>
                                            <input type="text" class="form-control shadow-sm rounded-3" name="shipping_address" placeholder="Địa chỉ giao hàng (nếu khác địa chỉ khách hàng)">
                                        </div>
                                    </div>

                                    <!-- DISPLAY/WARRANTY/DISPOSAL/OTHER: internal destination -->
                                    <div id="destinationFields" class="row mb-3 d-none">
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Điểm đến nội bộ</label>
                                            <select class="form-select shadow-sm rounded-3" id="destinationSelect" name="destination_id">
                                                <option value=""></option>
                                                <% if (destinationList != null) { for (InternalDestination d : destinationList) { if (d.isStatus()) { %>
                                                <option value="<%= d.getId() %>"><%= d.getDestinationName() %> (<%= d.getDestinationType() %>)</option>
                                                <% } } } %>
                                            </select>
                                        </div>
                                    </div>

                                    <hr class="my-4 text-muted opacity-25">

                                    <!-- Products -->
                                    <h5 class="fw-bold text-slate-800 mb-3"><i class="bi bi-box-seam me-2 text-primary"></i>Chọn Sản Phẩm</h5>
                                    <div class="row g-2 align-items-center mb-4">
                                        <div class="col-md-8">
                                            <select class="form-select shadow-sm rounded-3" id="productSelect">
                                                <option value=""></option>
                                                <% if (productList != null) { for (Product p : productList) { if (p.isStatus()) { %>
                                                <option value="<%= p.getId() %>"
                                                    data-sku="<%= p.getSku() %>"
                                                    data-unit="<%= p.getUnit() %>"
                                                    data-qty="<%= p.getPhysicalQty() %>"
                                                    data-avail="<%= p.getAvailableQty() %>">
                                                    <%= p.getProductName() %> (SKU: <%= p.getSku() %>) [Khả dụng: <%= p.getAvailableQty() %>]
                                                </option>
                                                <% } } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-4">
                                            <button type="button" class="btn btn-outline-primary w-100 py-2 d-inline-flex align-items-center justify-content-center gap-2" id="addItemBtn">
                                                <i class="bi bi-plus-lg"></i> Thêm vào danh sách
                                            </button>
                                        </div>
                                    </div>

                                    <div class="table-responsive border rounded-3 mb-3">
                                        <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.9rem;">
                                            <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                                <tr>
                                                    <th class="text-start ps-4" style="width: 40%;">Sản phẩm</th>
                                                    <th style="width: 15%;">SKU</th>
                                                    <th style="width: 10%;">Đơn vị</th>
                                                    <th style="width: 15%;">Tồn khả dụng</th>
                                                    <th style="width: 15%;">Số lượng</th>
                                                    <th style="width: 5%;">Xóa</th>
                                                </tr>
                                            </thead>
                                            <tbody id="itemsBody">
                                                <tr id="emptyRow">
                                                    <td colspan="6" class="text-muted py-4">Chưa có sản phẩm nào được thêm.</td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                                <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                                    <a href="<%= request.getContextPath() %>/warehouse/export-request?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                                    <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Lưu yêu cầu</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>
    <script>
        const addedProducts = new Set();
        let tsReason, tsProduct, tsTargetWarehouse, tsSourceWarehouse, tsCustomer, tsDestination, tsCondition;

        // Build warehouse -> product -> available quantity mapping from request attributes
        const warehouseStockNew = {
            <% 
            java.util.Map<Integer, java.util.Map<Integer, Integer>> stockMapNew = 
                (java.util.Map<Integer, java.util.Map<Integer, Integer>>) request.getAttribute("warehouseProductStockNew");
            if (stockMapNew != null) {
                for (java.util.Map.Entry<Integer, java.util.Map<Integer, Integer>> entry : stockMapNew.entrySet()) {
            %>
                <%= entry.getKey() %>: {
                    <% for (java.util.Map.Entry<Integer, Integer> pEntry : entry.getValue().entrySet()) { %>
                        <%= pEntry.getKey() %>: <%= pEntry.getValue() %>,
                    <% } %>
                },
            <% 
                }
            }
            %>
        };

        const warehouseStockUsed = {
            <% 
            java.util.Map<Integer, java.util.Map<Integer, Integer>> stockMapUsed = 
                (java.util.Map<Integer, java.util.Map<Integer, Integer>>) request.getAttribute("warehouseProductStockUsed");
            if (stockMapUsed != null) {
                for (java.util.Map.Entry<Integer, java.util.Map<Integer, Integer>> entry : stockMapUsed.entrySet()) {
            %>
                <%= entry.getKey() %>: {
                    <% for (java.util.Map.Entry<Integer, Integer> pEntry : entry.getValue().entrySet()) { %>
                        <%= pEntry.getKey() %>: <%= pEntry.getValue() %>,
                    <% } %>
                },
            <% 
                }
            }
            %>
        };

        function getActiveStockMap() {
            const cond = document.getElementById("conditionSelect").value;
            return cond === "USED" ? warehouseStockUsed : warehouseStockNew;
        }

        document.addEventListener("DOMContentLoaded", function () {
            document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new bootstrap.Tooltip(el));

            tsReason = new TomSelect("#reasonSelect", { create: false, placeholder: "-- Chọn lý do --" });
            tsProduct = new TomSelect("#productSelect", { create: false, placeholder: "-- Chọn sản phẩm --" });
            tsTargetWarehouse = new TomSelect("#targetWarehouseSelect", { create: false, placeholder: "-- Chọn kho đích --" });
            tsSourceWarehouse = new TomSelect("#sourceWarehouseSelect", { create: false, placeholder: "-- Chọn kho nguồn --" });
            tsCustomer = new TomSelect("#customerSelect", { create: false, placeholder: "-- Chọn khách hàng --" });
            tsDestination = new TomSelect("#destinationSelect", { create: false, placeholder: "-- Chọn điểm đến --" });
            tsCondition = new TomSelect("#conditionSelect", { create: false, controlInput: null });

            document.getElementById("reasonSelect").addEventListener("change", onReasonChange);
            document.getElementById("sourceWarehouseSelect").addEventListener("change", toggleProductSelector);
            document.getElementById("conditionSelect").addEventListener("change", toggleProductSelector);

            // Initialize selector state on load
            toggleProductSelector();
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

        function onReasonChange() {
            const reason = document.getElementById("reasonSelect").value;
            document.getElementById("transferFields").classList.add("d-none");
            document.getElementById("customerSaleFields").classList.add("d-none");
            document.getElementById("destinationFields").classList.add("d-none");

            document.getElementById("targetWarehouseSelect").removeAttribute("required");
            document.getElementById("customerSelect").removeAttribute("required");

            if (reason === "TRANSFER") {
                document.getElementById("transferFields").classList.remove("d-none");
                document.getElementById("targetWarehouseSelect").setAttribute("required", "required");
            } else if (reason === "CUSTOMER_SALE") {
                document.getElementById("customerSaleFields").classList.remove("d-none");
                document.getElementById("customerSelect").setAttribute("required", "required");
            } else if (reason === "DISPLAY" || reason === "WARRANTY" || reason === "DISPOSAL" || reason === "OTHER") {
                document.getElementById("destinationFields").classList.remove("d-none");
            }
        }

        function updateProductOptions(warehouseId) {
            const select = document.getElementById("productSelect");
            const options = select.options;
            const stockMap = getActiveStockMap();
            
            for (let i = 1; i < options.length; i++) {
                const opt = options[i];
                const pId = opt.value;
                const avail = (stockMap[warehouseId] && stockMap[warehouseId][pId] !== undefined)
                    ? stockMap[warehouseId][pId]
                    : 0;
                
                opt.dataset.avail = avail;
                const productName = opt.text.split(" (SKU:")[0];
                const sku = opt.dataset.sku;
                opt.text = productName + " (SKU: " + sku + ") [Khả dụng: " + avail + "]";
            }
            
            if (tsProduct) {
                tsProduct.sync();
                tsProduct.clear();
            }
        }

        function toggleProductSelector() {
            const warehouseId = document.getElementById("sourceWarehouseSelect").value;
            const addItemBtn = document.getElementById("addItemBtn");
            
            if (!warehouseId) {
                if (tsProduct) {
                    tsProduct.clear();
                    tsProduct.disable();
                }
                addItemBtn.disabled = true;
                clearItemsTable();
            } else {
                updateProductOptions(warehouseId);
                if (tsProduct) {
                    tsProduct.enable();
                }
                addItemBtn.disabled = false;
                updateExistingItems(warehouseId);
            }
        }

        function clearItemsTable() {
            const itemsBody = document.getElementById("itemsBody");
            const rows = itemsBody.querySelectorAll("tr:not(#emptyRow)");
            rows.forEach(r => r.remove());
            addedProducts.clear();
            const emptyRow = document.getElementById("emptyRow");
            if (emptyRow) emptyRow.style.display = "";
        }

        function updateExistingItems(warehouseId) {
            const stockMap = getActiveStockMap();
            const rows = document.querySelectorAll("#itemsBody tr:not(#emptyRow)");
            rows.forEach(row => {
                const productId = row.id.replace("item-row-", "");
                const avail = (stockMap[warehouseId] && stockMap[warehouseId][productId] !== undefined)
                    ? stockMap[warehouseId][productId]
                    : 0;
                    
                const availCol = row.querySelector("td:nth-child(4)");
                if (availCol) {
                    availCol.textContent = avail;
                }
                
                const qtyInput = row.querySelector(".qty-input");
                if (qtyInput) {
                    qtyInput.setAttribute("max", avail);
                    const currentVal = parseInt(qtyInput.value) || 0;
                    if (currentVal > avail) {
                        qtyInput.value = avail;
                    }
                    if (avail === 0) {
                        row.classList.add("table-danger");
                    } else {
                        row.classList.remove("table-danger");
                    }
                }
            });
        }

        document.getElementById("addItemBtn").addEventListener("click", function () {
            const productSelect = document.getElementById("productSelect");
            const productId = productSelect.value;
            if (!productId) { alert("Vui lòng chọn sản phẩm trước."); return; }
            if (addedProducts.has(productId)) { alert("Sản phẩm này đã được thêm vào danh sách."); return; }

            const opt = productSelect.querySelector('option[value="' + productId + '"]');
            const productName = opt.text.split(" (SKU:")[0];
            const sku = opt.dataset.sku;
            const unit = opt.dataset.unit;
            const availableStock = opt.dataset.avail;

            if (document.getElementById("emptyRow")) document.getElementById("emptyRow").style.display = "none";

            const tr = document.createElement("tr");
            tr.id = "item-row-" + productId;
            tr.innerHTML =
                '<td class="text-start ps-4 fw-semibold">' +
                    '<input type="hidden" name="product_id" value="' + productId + '">' +
                    productName +
                '</td>' +
                '<td><span class="badge bg-secondary bg-opacity-10 text-secondary">' + sku + '</span></td>' +
                '<td>' + unit + '</td>' +
                '<td class="fw-semibold">' + availableStock + '</td>' +
                '<td><input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="1" min="1" max="' + availableStock + '" required style="max-width: 100px; margin: 0 auto; box-shadow: none;"></td>' +
                '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="removeItem(' + productId + ')"><i class="bi bi-trash"></i></button></td>';

            document.getElementById("itemsBody").appendChild(tr);
            addedProducts.add(productId);
            
            // Highlight row if available stock is 0
            if (parseInt(availableStock) === 0) {
                tr.classList.add("table-danger");
            }
            
            if (tsProduct) tsProduct.clear();
        });

        function removeItem(id) {
            const row = document.getElementById("item-row-" + id);
            if (row) { row.remove(); addedProducts.delete(id.toString()); }
            if (addedProducts.size === 0 && document.getElementById("emptyRow")) {
                document.getElementById("emptyRow").style.display = "";
            }
        }

        document.getElementById("requestForm").addEventListener("submit", function (e) {
            const reason = document.getElementById("reasonSelect").value;
            if (!reason) { e.preventDefault(); alert("Vui lòng chọn lý do xuất kho."); return; }
            if (addedProducts.size === 0) { e.preventDefault(); alert("Bạn phải thêm ít nhất một sản phẩm."); return; }

            let qtyError = false;
            document.querySelectorAll("#itemsBody .qty-input").forEach(input => {
                const qty = parseInt(input.value) || 0;
                const max = parseInt(input.getAttribute("max")) || 999999;
                if (qty <= 0 || qty > max) qtyError = true;
            });
            if (qtyError) {
                e.preventDefault();
                alert("Số lượng yêu cầu phải lớn hơn 0 và không vượt quá tồn khả dụng.");
            }
        });
    </script>
</body>
</html>
