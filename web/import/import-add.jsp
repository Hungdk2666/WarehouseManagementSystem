<%@page import="model.Request"%>
<%@page import="model.RequestDetail"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_ADD_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Request> poList = (List<Request>) request.getAttribute("requestList");
    Request selectedRequest = (Request) request.getAttribute("selectedRequest");
    boolean isReturnRequest   = selectedRequest != null && "RETURN".equals(selectedRequest.getReason());
    boolean isTransferRequest = selectedRequest != null && "TRANSFER".equals(selectedRequest.getReason());
    boolean isPurchaseRequest = selectedRequest != null && "PURCHASE".equals(selectedRequest.getReason());
    boolean showCondition     = isReturnRequest || isTransferRequest;  // có thể ghi NEW/USED/DAMAGED

    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo Phiếu nhập kho - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Tom Select CSS -->
    <link href="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/css/tom-select.bootstrap5.min.css" rel="stylesheet">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Tạo Phiếu nhập kho</h2>
                        <p class="text-muted small mb-0">Ghi nhận hàng hóa thực tế nhập kho theo Yêu cầu nhập đã duyệt</p>
                    </div>
                    <a href="import-ticket?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Hủy
                    </a>
                </div>

                <%-- Banner kho đang làm việc --%>
                <div class="alert alert-info border-0 shadow-sm d-flex align-items-center gap-3 py-2 px-3 mb-4" style="background: #e8f4fd;">
                    <i class="bi bi-building-fill fs-5 text-info"></i>
                    <div class="small">
                        <span class="text-muted">Kho nhận hàng:</span>
                        <strong class="ms-1 text-info">
                            <%= loggedInUser.getWarehouseName() != null ? loggedInUser.getWarehouseName() : "Kho #" + loggedInUser.getWarehouseId() %>
                        </strong>
                        <span class="text-muted ms-2">— Hàng nhập sẽ được ghi vào kho này</span>
                    </div>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger border-0 shadow-sm rounded-3 mb-4">
                    <% if ("NoItemsReceived".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Bạn phải nhận ít nhất 1 sản phẩm (số lượng > 0) để lưu Phiếu nhập kho.
                    <% } else if ("RequiresWarehouseAssignment".equals(error)) { %>
                        <i class="bi bi-building-fill me-2"></i> Tài khoản của bạn chưa được gán kho. Liên hệ quản trị viên để gán kho trước khi tạo phiếu nhập.
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Tạo Phiếu nhập kho thất bại. Vui lòng thử lại.
                    <% } %>
                </div>
                <% } %>

                <div class="card card-overflow-visible shadow-sm border-0 bg-white mb-4" style="overflow: visible;">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-receipt me-2"></i>Chọn Yêu cầu nhập kho tham chiếu</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row align-items-end g-3">
                            <div class="col-md-8">
                                <label for="poSelect" class="form-label">Yêu cầu nhập tham chiếu <span class="text-danger">*</span></label>
                                <select class="form-select" id="poSelect">
                                    <option value="" <%= selectedRequest == null ? "selected" : "" %>></option>
                                    <%
                                        if (poList != null) {
                                            for (Request r : poList) {
                                                boolean isSel = selectedRequest != null && selectedRequest.getId() == r.getId();
                                                String displayStatus = r.getStatus();
                                                if ("APPROVED".equals(r.getStatus())) displayStatus = "Đã duyệt";
                                                else if ("PENDING".equals(r.getStatus())) displayStatus = "Chờ duyệt";
                                    %>
                                    <option value="<%= r.getId() %>" <%= isSel ? "selected" : "" %>>
                                        #<%= r.getRequestCode() %> - <%= r.getPartnerName() %> (Trạng thái: <%= displayStatus %>)
                                    </option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <button type="button" class="btn btn-outline-secondary w-100" onclick="resetPOSelection()">
                                    <i class="bi bi-arrow-clockwise"></i> Xóa lựa chọn
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (selectedRequest != null) { %>
                <form action="import-ticket?action=add" method="POST" id="grnForm">
                    <input type="hidden" name="request_id" value="<%= selectedRequest.getId() %>">
                    
                    <div class="card shadow-sm border-0 bg-white mb-4">
                        <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                            <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-seam me-2"></i>Chi tiết Phiếu nhập kho</h5>
                        </div>
                        <div class="card-body p-0">
                            <table class="table align-middle text-center mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-start ps-4">Tên sản phẩm</th>
                                        <th>SKU</th>
                                        <th>Đơn vị</th>
                                        <th>SL yêu cầu</th>
                                        <th>Đơn giá dự kiến</th>
                                        <th style="width: 15%;">SL thực tế nhận</th>
                                        <th style="width: 20%;">Đơn giá thực tế (VND)</th>
                                        <% if (showCondition) { %><th>Tình trạng</th><% } %>
                                        <th>Thành tiền</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (selectedRequest.getDetails() != null) {
                                            for (RequestDetail d : selectedRequest.getDetails()) {
                                    %>
                                    <tr>
                                        <td class="text-start ps-4 fw-semibold">
                                            <input type="hidden" name="product_id" value="<%= d.getProductId() %>">
                                            <%= d.getProductName() %>
                                        </td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                        <td><%= d.getUnit() %></td>
                                        <td class="text-muted"><%= d.getQuantity() %></td>
                                        <td class="text-muted"><%= String.format("%,.0f", (d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0)) %> VND</td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="<%= d.getQuantity() %>" min="0" max="<%= d.getQuantity() %>" required style="box-shadow: none;">
                                        </td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm text-end price-input" name="unit_price" value="<%= (d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0) %>" min="0" required style="box-shadow: none;">
                                        </td>
                                        <% if (showCondition) { %>
                                        <td>
                                            <select class="form-select form-select-sm" name="item_condition" style="box-shadow: none;">
                                                <% if (isReturnRequest) { %>
                                                <option value="USED" selected>Used</option>
                                                <option value="NEW">New</option>
                                                <option value="DAMAGED">Damaged (→ Quarantine)</option>
                                                <% } else { %>
                                                <option value="NEW" selected>New (nguyên vẹn)</option>
                                                <option value="USED">Used (cũ)</option>
                                                <option value="DAMAGED">Damaged (hỏng → Quarantine)</option>
                                                <% } %>
                                            </select>
                                        </td>
                                        <% } else { %>
                                        <input type="hidden" name="item_condition" value="NEW">
                                        <% } %>
                                        <td class="fw-bold row-total"><%= String.format("%,.0f", d.getQuantity() * (d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0)) %> VND</td>
                                    </tr>
                                    <%
                                            }
                                        }
                                    %>
                                    <tr class="table-light fw-bold">
                                        <td colspan="<%= showCondition ? 8 : 7 %>" class="text-end pe-4">Tổng giá trị thực tế:</td>
                                        <td id="grandTotal">0 VND</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                            <a href="import-ticket?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                            <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Lưu bản nháp Phiếu nhập kho</button>
                        </div>
                    </div>
                </form>
                <% } %>

            </div>
        </div>
    </div>

    <!-- Tom Select JS -->
    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            new TomSelect("#poSelect", {
                create: false,
                placeholder: "-- Chọn Yêu cầu nhập đã duyệt/hoạt động --",
                onChange: function(value) {
                    loadPOItems(value);
                }
            });
        });

        function loadPOItems(poId) {
            if (poId) {
                window.location.href = "import-ticket?action=add&request_id=" + poId;
            }
        }

        function resetPOSelection() {
            window.location.href = 'import-ticket?action=add';
        }

        <% if (selectedRequest != null) { %>
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
                alert("Bạn phải nhận ít nhất 1 sản phẩm (số lượng > 0) để lưu Phiếu nhập kho.");
            }
        });
        <% } %>
    </script>
</body>
</html>
