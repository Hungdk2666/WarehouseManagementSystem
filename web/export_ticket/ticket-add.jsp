<%@page import="model.Request"%>
<%@page import="model.RequestDetail"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_ADD_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Request> reqList = (List<Request>) request.getAttribute("reqList");
    Request selectedReq = (Request) request.getAttribute("selectedReq");
    
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo Phiếu xuất kho - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Tạo Phiếu xuất kho</h2>
                        <p class="text-muted small mb-0">Ghi nhận xuất kho thực tế theo Yêu cầu xuất kho đã duyệt</p>
                    </div>
                    <a href="export-ticket?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại
                    </a>
                </div>

                <%-- Banner kho đang làm việc --%>
                <div class="alert alert-warning border-0 shadow-sm d-flex align-items-center gap-3 py-2 px-3 mb-4" style="background: #fff8e1;">
                    <i class="bi bi-building-fill fs-5 text-warning"></i>
                    <div class="small">
                        <span class="text-muted">Kho xuất hàng:</span>
                        <strong class="ms-1 text-warning">
                            <%= loggedInUser.getWarehouseName() != null ? loggedInUser.getWarehouseName() : "Kho #" + loggedInUser.getWarehouseId() %>
                        </strong>
                        <span class="text-muted ms-2">— Tồn kho và serial số hiển thị bên dưới thuộc kho này</span>
                    </div>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger border-0 shadow-sm rounded-3 mb-4">
                    <% if ("NoItemsDispatched".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Bạn phải chọn xuất ít nhất 1 sản phẩm (số lượng > 0) để lưu Phiếu xuất kho.
                    <% } else if ("ExceededRemainingQuantity".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Số lượng thực xuất vượt quá số lượng yêu cầu còn lại.
                    <% } else if ("InsufficientStock".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Không đủ tồn kho khả dụng cho một hoặc nhiều sản phẩm.
                    <% } else if ("RequiresWarehouseAssignment".equals(error)) { %>
                        <i class="bi bi-building-fill me-2"></i> Tài khoản của bạn chưa được gán kho. Liên hệ quản trị viên để gán kho trước khi tạo phiếu xuất.
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Tạo Phiếu xuất kho thất bại. Mã lỗi: <%= error %>. Vui lòng thử lại.
                    <% } %>
                </div>
                <% } %>

                <div class="card card-overflow-visible shadow-sm border-0 bg-white mb-4" style="overflow: visible;">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-receipt me-2"></i>Chọn Yêu cầu xuất kho tham chiếu</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row align-items-end g-3">
                            <div class="col-md-8">
                                <label for="reqSelect" class="form-label">Yêu cầu xuất kho tham chiếu <span class="text-danger">*</span></label>
                                <select class="form-select" id="reqSelect">
                                    <option value="" <%= selectedReq == null ? "selected" : "" %>></option>
                                    <%
                                        if (reqList != null) {
                                            for (Request r : reqList) {
                                                boolean isSel = selectedReq != null && selectedReq.getId() == r.getId();
                                    %>
                                    <option value="<%= r.getId() %>" <%= isSel ? "selected" : "" %>>
                                        #<%= r.getRequestCode() %> - Điểm nhận: <%= r.getPartnerName() %> (Trạng thái: 
                                        <%
                                            if ("PENDING".equals(r.getStatus())) out.print("Chờ duyệt");
                                            else if ("APPROVED".equals(r.getStatus())) out.print("Đã duyệt");
                                            else if ("PARTIALLY_COMPLETED".equals(r.getStatus())) out.print("Đang xuất dở");
                                            else if ("REJECTED".equals(r.getStatus())) out.print("Từ chối");
                                            else if ("COMPLETED".equals(r.getStatus())) out.print("Hoàn thành");
                                            else if ("CANCELLED".equals(r.getStatus())) out.print("Đã hủy");
                                            else out.print(r.getStatus());
                                        %>)
                                    </option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <button type="button" class="btn btn-outline-secondary w-100" onclick="resetRequestSelection()">
                                    <i class="bi bi-arrow-clockwise"></i> Xóa lựa chọn
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
                            <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-seam me-2"></i>Chi tiết phiếu xuất kho</h5>
                        </div>
                        <div class="card-body p-0">
                            <table class="table align-middle text-center mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-start ps-4">Tên sản phẩm</th>
                                        <th>SKU</th>
                                        <th>Đơn vị</th>
                                        <th>Số lượng yêu cầu</th>
                                        <th>Đã xuất</th>
                                        <th>Còn lại</th>
                                        <th>
                                            Tồn NEW
                                            <i class="bi bi-info-circle text-muted" title="Số lượng khả dụng hàng MỚI" data-bs-toggle="tooltip"></i>
                                        </th>
                                        <th>
                                            Tồn USED
                                            <i class="bi bi-info-circle text-muted" title="Số lượng khả dụng hàng CŨ" data-bs-toggle="tooltip"></i>
                                        </th>
                                        <th>
                                            Tổng khả dụng
                                            <i class="bi bi-info-circle text-muted" title="Tổng số lượng khả dụng tại kho của bạn" data-bs-toggle="tooltip"></i>
                                        </th>
                                        <th style="width: 15%;">Số lượng xuất thực tế</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        java.util.Map<Integer, Integer> stockMap = (java.util.Map<Integer, Integer>) request.getAttribute("stockMap");
                                        java.util.Map<Integer, Integer> newStockMap = (java.util.Map<Integer, Integer>) request.getAttribute("newStockMap");
                                        java.util.Map<Integer, Integer> usedStockMap = (java.util.Map<Integer, Integer>) request.getAttribute("usedStockMap");
                                        java.util.Map<Integer, Integer> totalStockMap = (java.util.Map<Integer, Integer>) request.getAttribute("totalStockMap");
                                        String reqCond = selectedReq.getRequestedCondition() != null ? selectedReq.getRequestedCondition() : "NEW";
                                        
                                        if (selectedReq.getDetails() != null) {
                                            for (RequestDetail d : selectedReq.getDetails()) {
                                                int remaining = d.getQuantity() - d.getProcessedQuantity();
                                                if (remaining < 0) remaining = 0;
                                                
                                                int stock = (stockMap != null && stockMap.containsKey(d.getProductId())) ? stockMap.get(d.getProductId()) : 0;
                                                int defaultIssue = Math.min(remaining, stock);
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
                                        <td class="text-muted text-success fw-semibold"><%= d.getProcessedQuantity() %></td>
                                        <td class="fw-semibold text-primary"><%= remaining %></td>
                                        <% 
                                            int newStock = (newStockMap != null && newStockMap.containsKey(d.getProductId())) ? newStockMap.get(d.getProductId()) : 0;
                                            int usedStock = (usedStockMap != null && usedStockMap.containsKey(d.getProductId())) ? usedStockMap.get(d.getProductId()) : 0;
                                            int totalStock = (totalStockMap != null && totalStockMap.containsKey(d.getProductId())) ? totalStockMap.get(d.getProductId()) : 0;
                                            boolean isNewRequested = "NEW".equals(reqCond);
                                            boolean isUsedRequested = "USED".equals(reqCond);
                                        %>
                                        <td class="fw-semibold <%= isNewRequested ? (stock < remaining ? "text-danger bg-danger bg-opacity-10" : "text-primary bg-primary bg-opacity-10") : "text-muted" %>">
                                            <%= newStock %>
                                            <% if (isNewRequested && stock < remaining) { %>
                                            <i class="bi bi-exclamation-triangle-fill text-danger ms-1" title="Không đủ hàng NEW tại kho này" data-bs-toggle="tooltip"></i>
                                            <% } %>
                                        </td>
                                        <td class="fw-semibold <%= isUsedRequested ? (stock < remaining ? "text-danger bg-danger bg-opacity-10" : "text-primary bg-primary bg-opacity-10") : "text-muted" %>">
                                            <%= usedStock %>
                                            <% if (isUsedRequested && stock < remaining) { %>
                                            <i class="bi bi-exclamation-triangle-fill text-danger ms-1" title="Không đủ hàng USED tại kho này" data-bs-toggle="tooltip"></i>
                                            <% } %>
                                        </td>
                                        <td class="fw-bold text-dark">
                                            <%= totalStock %>
                                        </td>
                                        <td>
                                            <input type="number"
                                                   class="form-control form-control-sm text-center qty-input" 
                                                   name="quantity" 
                                                   value="<%= defaultIssue %>" 
                                                   min="0" 
                                                   max="<%= remaining %>" 
                                                   data-remaining="<%= remaining %>"
                                                   data-stock="<%= stock %>"
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
                            <a href="export-ticket?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                            <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Lưu nháp Phiếu xuất kho</button>
                        </div>
                    </div>
                </form>
                <% } %>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <!-- Tom Select JS -->
    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            // Init tooltips
            document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new bootstrap.Tooltip(el));

            new TomSelect("#reqSelect", {
                create: false,
                placeholder: "-- Chọn Yêu cầu xuất kho đã duyệt --",
                onChange: function(value) {
                    loadRequestItems(value);
                }
            });
        });

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
                const pname = input.getAttribute("data-pname") || "Sản phẩm";

                if (qty > remaining) {
                    alert("Lỗi: Đối với sản phẩm '" + pname + "', số lượng thực xuất (" + qty + ") không được vượt quá số lượng yêu cầu còn lại (" + remaining + ").");
                    validationFailed = true;
                }
                
                if (qty > stock) {
                    alert("Lỗi: Đối với sản phẩm '" + pname + "', số lượng thực xuất (" + qty + ") không được vượt quá lượng tồn kho thực tế khả dụng (" + stock + ").");
                    validationFailed = true;
                }
            });

            if (validationFailed) {
                e.preventDefault();
                return;
            }

            if (totalQty <= 0) {
                e.preventDefault();
                alert("Bạn phải chọn xuất ít nhất 1 sản phẩm (số lượng > 0) để lưu Phiếu xuất kho.");
            }
        });
        <% } %>
    </script>
</body>
</html>
