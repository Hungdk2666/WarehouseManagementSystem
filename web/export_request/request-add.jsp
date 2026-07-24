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

    String errorCode = request.getParameter("error");
    String errorMessage = null;
    if (errorCode != null) {
        switch (errorCode) {
            case "NoReason": errorMessage = "Vui lòng chọn lý do xuất kho."; break;
            case "InvalidReason": errorMessage = "Lý do xuất kho không hợp lệ."; break;
            case "InvalidCondition": errorMessage = "Tình trạng xuất không hợp lệ."; break;
            case "ConditionNotAllowed": errorMessage = "Tình trạng xuất không phù hợp với lý do đã chọn."; break;
            case "NoWarehouse": errorMessage = "Vui lòng chọn kho xuất."; break;
            case "WarehouseFrozen": errorMessage = "Kho đang trong quá trình kiểm kê · Phiếu #" + request.getParameter("stk") + ". Không thể tạo yêu cầu xuất lúc này."; break;
            case "NoTarget": errorMessage = "Vui lòng chọn kho đích khi chuyển kho."; break;
            case "SameWarehouse": errorMessage = "Kho đích phải khác kho nguồn."; break;
            case "NoCustomer": errorMessage = "Vui lòng chọn khách hàng."; break;
            case "NoDestination": errorMessage = "Vui lòng chọn điểm đến nội bộ."; break;
            case "DestinationPurposeMismatch": errorMessage = "Điểm đến đã chọn không đúng loại cho lý do xuất này — Bảo hành cần chọn Trung tâm bảo hành, Trưng bày cần chọn Showroom."; break;
            case "NoProducts": errorMessage = "Vui lòng chọn ít nhất 1 sản phẩm."; break;
            case "NoValidDetails": errorMessage = "Không có sản phẩm hợp lệ nào được chọn."; break;
            case "InvalidProduct": errorMessage = "Sản phẩm đã chọn không hợp lệ."; break;
            case "InsufficientStock": errorMessage = "Không đủ tồn kho khả dụng cho sản phẩm #" + request.getParameter("productId") + "."; break;
            case "Failed": errorMessage = "Tạo yêu cầu xuất kho thất bại. Vui lòng thử lại."; break;
            default: errorMessage = "Có lỗi xảy ra, vui lòng thử lại.";
        }
    }
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
    <style>
        .request-builder-card { border: 0; border-radius: 1rem; box-shadow: 0 12px 34px rgba(15, 23, 42, .08); }
        .request-builder-card .card-header { border-radius: 1rem 1rem 0 0; }
        .flow-guidance { background: linear-gradient(135deg, rgba(13,110,253,.08), rgba(13,202,240,.06)); border: 1px solid rgba(13,110,253,.16); }
        .flow-guidance .condition-dot { width: .65rem; height: .65rem; border-radius: 50%; display: inline-block; }
        .section-heading { font-size: .78rem; letter-spacing: .08em; text-transform: uppercase; color: #64748b; }
        @media (max-width: 767.98px) { .container-fluid { padding-left: 1rem !important; padding-right: 1rem !important; } }
    </style>
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />

            <div class="col-md-9 col-lg-10">
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Tạo Yêu cầu xuất kho</h2>
                        <p class="page-subtitle">Tạo mới yêu cầu xuất hàng ra khỏi kho</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/export-request?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Hủy
                    </a>
                </div>
                <div class="row justify-content-center">
                    <div class="col-12">
                        <form action="<%= request.getContextPath() %>/warehouse/export-request?action=add" method="POST" id="requestForm">
                            <div class="card bg-white request-builder-card" style="overflow: visible;">
                                <div class="card-header bg-white py-3">
                                    <span class="fw-bold text-slate-800"><i class="bi bi-plus-circle-fill me-2 text-primary"></i>Thông tin Yêu cầu xuất kho</span>
                                </div>
                                <div class="card-body p-4">
                                    <% if (errorMessage != null) { %>
                                    <div class="alert alert-danger rounded-3 mb-3 d-flex align-items-center">
                                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                                        <%= errorMessage %>
                                    </div>
                                    <% } %>

                                    <div class="row g-3 mb-4">
                                        <div class="col-xl-3 col-md-6">
                                            <label for="reasonSelect" class="form-label fw-semibold text-muted small mb-1">Lý do xuất kho <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="reasonSelect" name="export_reason" required>
                                                <option value=""></option>
                                                <option value="TRANSFER">Chuyển kho nội bộ</option>
                                                <option value="CUSTOMER_SALE">Xuất bán cho khách hàng</option>
                                                <option value="DISPLAY">Hàng trưng bày</option>
                                                <option value="WARRANTY">Bảo hành / sửa chữa</option>
                                            </select>
                                        </div>
                                        <div class="col-xl-3 col-md-6">
                                            <label for="expectedDate" class="form-label fw-semibold text-muted small mb-1">Ngày xuất kho dự kiến <span class="text-danger">*</span></label>
                                            <input type="date" class="form-control shadow-sm rounded-3" id="expectedDate" name="expected_date" required>
                                        </div>
                                        <div class="col-xl-3 col-md-6">
                                            <label for="sourceWarehouseSelect" class="form-label fw-semibold text-muted small mb-1">Kho nguồn <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="sourceWarehouseSelect" name="source_warehouse_id" required>
                                                <option value=""></option>
                                                <% if (warehouseList != null) { for (Warehouse w : warehouseList) { %>
                                                <option value="<%= w.getId() %>"><%= w.getWarehouseName() %></option>
                                                <% } } %>
                                            </select>
                                        </div>
                                        <div class="col-xl-3 col-md-6">
                                            <label for="conditionSelect" class="form-label fw-semibold text-muted small mb-1">Tình trạng xuất <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="conditionSelect" name="requested_condition" required>
                                                <option value="NEW" selected>Hàng mới</option>
                                                <option value="USED">Hàng cũ</option>
                                                <option value="DAMAGED">Hàng hỏng</option>
                                            </select>
                                        </div>
                                    </div>

                                    <div class="flow-guidance rounded-3 px-3 py-2 mb-4 d-flex flex-wrap align-items-center gap-3 small">
                                        <span class="fw-semibold text-primary"><i class="bi bi-shield-check me-1"></i>Quy tắc xuất:</span>
                                        <span><i class="condition-dot bg-success me-1"></i>Hàng mới / hàng cũ: bán, trưng bày hoặc chuyển kho</span>
                                        <span><i class="condition-dot bg-danger me-1"></i>Hàng hỏng: bảo hành hoặc chuyển kho</span>
                                    </div>

                                    
                                    
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

                                    
                                    <div id="customerSaleFields" class="row mb-3 d-none">
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Khách hàng <span class="text-danger">*</span></label>
                                            <select class="form-select shadow-sm rounded-3" id="customerSelect" name="customer_id">
                                                <option value=""></option>
                                                <% if (customerList != null) { for (Customer cu : customerList) { %>
                                                <option value="<%= cu.getId() %>"><%= cu.getCustomerName() %><%= cu.getPhone() != null ? " — " + cu.getPhone() : "" %></option>
                                                <% } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Địa chỉ giao hàng</label>
                                            <input type="text" class="form-control shadow-sm rounded-3" name="shipping_address" placeholder="Nhập khi địa chỉ giao hàng khác địa chỉ khách hàng">
                                        </div>
                                    </div>

                                    
                                    <div id="destinationFields" class="row mb-3 d-none">
                                        <div class="col-md-6">
                                            <label class="form-label fw-semibold text-muted small mb-1">Điểm đến nội bộ</label>
                                            <select class="form-select shadow-sm rounded-3" id="destinationSelect" name="destination_id">
                                                <option value=""></option>
                                                <% if (destinationList != null) { for (InternalDestination d : destinationList) { if (d.isStatus()) { %>
                                                <%
                                                    String dt = d.getDestinationType();
                                                    String dtLabel = "SHOWROOM".equals(dt) ? "Showroom"
                                                            : "WARRANTY_CENTER".equals(dt) ? "Trung tâm bảo hành"
                                                            : "OTHER".equals(dt) ? "Khác" : dt;
                                                %>
                                                <option value="<%= d.getId() %>" data-type="<%= dt %>"><%= d.getDestinationName() %> — <%= dtLabel %></option>
                                                <% } } } %>
                                            </select>
                                        </div>
                                    </div>

                                    <hr class="my-4 text-muted opacity-25">

                                    
                                    <div class="section-heading fw-bold mb-2">Danh sách hàng xuất</div>
                                    <h5 class="fw-bold text-slate-800 mb-3"><i class="bi bi-box-seam me-2 text-primary"></i>Chọn sản phẩm theo tồn khả dụng</h5>
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
                                                    <%= p.getProductName() %> — <%= p.getSku() %> · Khả dụng <%= p.getAvailableQty() %>
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
                                        <table class="table table-hover align-middle mb-0 text-center editable-table" style="font-size: 0.9rem; min-width: 800px;">
                                            <colgroup>
                                                <col style="width:40%">
                                                <col style="width:15%">
                                                <col style="width:10%">
                                                <col style="width:15%">
                                                <col style="width:15%">
                                                <col style="width:5%">
                                            </colgroup>
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
                                                    <td colspan="6" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Chưa có sản phẩm nào được thêm.</p></div></td>
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
        let allTargetWarehouseOptions = [];


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

        const warehouseStockDamaged = {
            <%
            java.util.Map<Integer, java.util.Map<Integer, Integer>> stockMapDamaged =
                (java.util.Map<Integer, java.util.Map<Integer, Integer>>) request.getAttribute("warehouseProductStockDamaged");
            if (stockMapDamaged != null) {
                for (java.util.Map.Entry<Integer, java.util.Map<Integer, Integer>> entry : stockMapDamaged.entrySet()) {
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
            if (cond === "DAMAGED") return warehouseStockDamaged;
            return cond === "USED" ? warehouseStockUsed : warehouseStockNew;
        }

        document.addEventListener("DOMContentLoaded", function () {
            document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new bootstrap.Tooltip(el));

            tsReason = new TomSelect("#reasonSelect", { create: false, placeholder: "-- Chọn lý do --" });
            tsProduct = new TomSelect("#productSelect", { create: false, placeholder: "-- Chọn sản phẩm --" });
            allTargetWarehouseOptions = Array.from(document.querySelectorAll("#targetWarehouseSelect option"))
                .filter(o => o.value !== "")
                .map(o => ({ value: o.value, text: o.textContent }));
            tsTargetWarehouse = new TomSelect("#targetWarehouseSelect", { create: false, placeholder: "-- Chọn kho đích --" });
            tsSourceWarehouse = new TomSelect("#sourceWarehouseSelect", { create: false, placeholder: "-- Chọn kho nguồn --" });
            tsCustomer = new TomSelect("#customerSelect", { create: false, placeholder: "-- Chọn khách hàng --" });

            allDestinationOptions = Array.from(document.querySelectorAll("#destinationSelect option"))
                .filter(o => o.value !== "")
                .map(o => ({ value: o.value, text: o.textContent, type: o.dataset.type }));
            tsDestination = new TomSelect("#destinationSelect", { create: false, placeholder: "-- Chọn điểm đến --" });
            tsCondition = new TomSelect("#conditionSelect", { create: false, controlInput: null });

            document.getElementById("reasonSelect").addEventListener("change", onReasonChange);
            document.getElementById("sourceWarehouseSelect").addEventListener("change", function() {
                configureTargetWarehouseOptions();
                toggleProductSelector();
            });
            document.getElementById("conditionSelect").addEventListener("change", toggleProductSelector);


            onReasonChange();
            configureTargetWarehouseOptions();
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


        expectedDateInput.addEventListener("change", function() {
            validateDateInput(this);
        });

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
            document.getElementById("destinationSelect").removeAttribute("required");

            if (reason === "TRANSFER") {
                document.getElementById("transferFields").classList.remove("d-none");
                document.getElementById("targetWarehouseSelect").setAttribute("required", "required");
            } else if (reason === "CUSTOMER_SALE") {
                document.getElementById("customerSaleFields").classList.remove("d-none");
                document.getElementById("customerSelect").setAttribute("required", "required");
            } else if (reason === "DISPLAY" || reason === "WARRANTY") {
                document.getElementById("destinationFields").classList.remove("d-none");
                document.getElementById("destinationSelect").setAttribute("required", "required");
            }

            configureConditionOptions(reason);
            configureDestinationOptions(reason);
            configureTargetWarehouseOptions();
        }


        function configureTargetWarehouseOptions() {
            if (!tsTargetWarehouse) return;

            const sourceWarehouseId = document.getElementById("sourceWarehouseSelect").value;
            const currentTargetId = tsTargetWarehouse.getValue();
            const filtered = allTargetWarehouseOptions.filter(item => item.value !== sourceWarehouseId);

            tsTargetWarehouse.clear(true);
            tsTargetWarehouse.clearOptions();
            filtered.forEach(item => tsTargetWarehouse.addOption(item));
            tsTargetWarehouse.refreshOptions(false);

            if (currentTargetId && currentTargetId !== sourceWarehouseId
                    && filtered.some(item => item.value === currentTargetId)) {
                tsTargetWarehouse.setValue(currentTargetId, true);
            }
        }



        let allDestinationOptions = [];

        function configureDestinationOptions(reason) {
            let requiredType = null;
            if (reason === "WARRANTY") requiredType = "WARRANTY_CENTER";
            else if (reason === "DISPLAY") requiredType = "SHOWROOM";

            const filtered = requiredType == null
                ? allDestinationOptions
                : allDestinationOptions.filter(item => item.type === requiredType);

            if (tsDestination) {
                const current = tsDestination.getValue();
                tsDestination.clear(true);
                tsDestination.clearOptions();
                filtered.forEach(item => tsDestination.addOption({ value: item.value, text: item.text }));
                tsDestination.refreshOptions(false);
                if (filtered.some(item => item.value === current)) tsDestination.setValue(current, true);
            }
        }

        const allConditionOptions = [
            { value: "NEW", text: "Hàng mới" },
            { value: "USED", text: "Hàng cũ" },
            { value: "DAMAGED", text: "Hàng hỏng" }
        ];

        function configureConditionOptions(reason) {
            let allowed = ["NEW", "USED", "DAMAGED"];
            if (reason === "WARRANTY") allowed = ["DAMAGED"];
            if (reason === "DISPLAY") allowed = ["NEW", "USED"];

            const current = document.getElementById("conditionSelect").value;
            const selected = allowed.includes(current) ? current : allowed[0];
            if (tsCondition) {
                tsCondition.clear(true);
                tsCondition.clearOptions();
                allConditionOptions.filter(item => allowed.includes(item.value)).forEach(item => tsCondition.addOption(item));
                tsCondition.refreshOptions(false);
                tsCondition.setValue(selected, true);
            } else {
                Array.from(document.getElementById("conditionSelect").options).forEach(opt => {
                    opt.disabled = !allowed.includes(opt.value);
                });
                document.getElementById("conditionSelect").value = selected;
            }
            toggleProductSelector();
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
                const productName = opt.text.split(" — ")[0];
                const sku = opt.dataset.sku;
                opt.text = productName + " — " + sku + " · Khả dụng " + avail;
            }

            if (tsProduct) {
                tsProduct.clear();
                tsProduct.clearOptions();
                for (let i = 1; i < options.length; i++) {
                    const opt = options[i];
                    tsProduct.addOption({
                        value: opt.value,
                        text: opt.text
                    });
                }
                tsProduct.refreshOptions(false);
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
            const productName = opt.text.split(" — ")[0];
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

        document.getElementById("itemsBody").addEventListener("input", function(e) {
            if (e.target && e.target.classList.contains("qty-input")) {
                if (e.target.value !== "") {
                    let val = parseInt(e.target.value);
                    let max = parseInt(e.target.getAttribute("max"));
                    if (!isNaN(val) && !isNaN(max) && val > max) {
                        e.target.value = max;
                    }
                }
            }
        });

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
