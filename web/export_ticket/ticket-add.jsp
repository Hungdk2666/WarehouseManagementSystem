<%@page import="model.Request"%>
<%@page import="model.RequestDetail"%>
<%@page import="java.util.Map"%>
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
                
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Tạo Phiếu xuất kho</h2>
                        <p class="page-subtitle">Ghi nhận xuất kho thực tế theo Yêu cầu xuất kho đã duyệt</p>
                    </div>
                    <a href="export-ticket?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại
                    </a>
                </div>

                <%-- Banner kho đang làm việc --%>
                <div class="d-flex align-items-center gap-3 py-2 px-3 mb-4 rounded-3 bg-warning bg-opacity-10">
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
                <div class="alert alert-danger rounded-3 mb-4">
                    <% if ("NoItemsDispatched".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Bạn phải chọn xuất ít nhất 1 sản phẩm (số lượng > 0) để lưu Phiếu xuất kho.
                    <% } else if ("ExceededRemainingQuantity".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Số lượng thực xuất vượt quá số lượng yêu cầu còn lại.
                    <% } else if ("InsufficientStock".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Không đủ tồn kho khả dụng cho một hoặc nhiều sản phẩm.
                    <% } else if ("RequiresWarehouseAssignment".equals(error)) { %>
                        <i class="bi bi-building-fill me-2"></i> Tài khoản của bạn chưa được gán kho. Liên hệ quản trị viên để gán kho trước khi tạo phiếu xuất.
                    <% } else if ("DispatchFailed".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Xuất kho thất bại: mã serial vừa quét có thể đã được xuất ở phiếu khác, hoặc đơn vừa bị đổi trạng thái. Vui lòng tải lại trang và quét lại.
                    <% } else if ("RequestNotApproved".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Yêu cầu này chưa được duyệt hoặc đang chờ hủy, không thể xuất kho.
                    <% } else if ("WrongWarehouse".equals(error)) { %>
                        <i class="bi bi-building-fill me-2"></i> Bạn chỉ được xuất kho cho yêu cầu thuộc kho của mình.
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Thao tác thất bại. Mã lỗi: <%= error %>. Vui lòng thử lại.
                    <% } %>
                </div>
                <% } %>

                <div class="card card-overflow-visible bg-white mb-4" style="overflow: visible;">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-receipt me-2 text-primary"></i>Chọn Yêu cầu xuất kho tham chiếu</h5>
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
                <form action="export-ticket?action=addAndConfirm" method="POST" id="ginForm">
                    <input type="hidden" name="request_id" value="<%= selectedReq.getId() %>">
                    <div id="hidden-serials-container"></div>
                    
                    <div class="card bg-white mb-4">
                        <div class="card-header bg-transparent py-3 border-bottom">
                            <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-box-seam me-2 text-primary"></i>Chi tiết phiếu xuất kho</h5>
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
                                            Tồn hỏng
                                            <i class="bi bi-info-circle text-muted" title="Số lượng hàng hỏng đang cách ly" data-bs-toggle="tooltip"></i>
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
                                        java.util.Map<Integer, Integer> damagedStockMap = (java.util.Map<Integer, Integer>) request.getAttribute("damagedStockMap");
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
                                            int damagedStock = (damagedStockMap != null && damagedStockMap.containsKey(d.getProductId())) ? damagedStockMap.get(d.getProductId()) : 0;
                                            int totalStock = (totalStockMap != null && totalStockMap.containsKey(d.getProductId())) ? totalStockMap.get(d.getProductId()) : 0;
                                            boolean isNewRequested = "NEW".equals(reqCond);
                                            boolean isUsedRequested = "USED".equals(reqCond);
                                            boolean isDamagedRequested = "DAMAGED".equals(reqCond);
                                        %>
                                        <td class="fw-semibold <%= isNewRequested ? (stock < remaining ? "text-danger bg-light" : "text-primary bg-light") : "text-muted" %>">
                                            <%= newStock %>
                                            <% if (isNewRequested && stock < remaining) { %>
                                            <i class="bi bi-exclamation-triangle-fill text-danger ms-1" title="Không đủ hàng NEW tại kho này" data-bs-toggle="tooltip"></i>
                                            <% } %>
                                        </td>
                                        <td class="fw-semibold <%= isUsedRequested ? (stock < remaining ? "text-danger bg-light" : "text-primary bg-light") : "text-muted" %>">
                                            <%= usedStock %>
                                            <% if (isUsedRequested && stock < remaining) { %>
                                            <i class="bi bi-exclamation-triangle-fill text-danger ms-1" title="Không đủ hàng USED tại kho này" data-bs-toggle="tooltip"></i>
                                            <% } %>
                                        </td>
                                        <td class="fw-semibold <%= isDamagedRequested ? (stock < remaining ? "text-danger bg-light" : "text-primary bg-light") : "text-muted" %>">
                                            <%= damagedStock %>
                                            <% if (isDamagedRequested && stock < remaining) { %>
                                            <i class="bi bi-exclamation-triangle-fill text-danger ms-1" title="Không đủ hàng hỏng tại kho này" data-bs-toggle="tooltip"></i>
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
                                                   data-pid="<%= d.getProductId() %>"
                                                   data-sku="<%= d.getSku() %>"
                                                   onkeydown="if(!/^[0-9]$/.test(event.key) && !['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab', 'Enter', 'Escape'].includes(event.key) && !event.ctrlKey && !event.metaKey) event.preventDefault();"
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
                        <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0" id="step1Footer">
                            <a href="export-ticket?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                            <button type="button" id="toScanBtn" class="btn btn-primary px-4" onclick="lockAndBuildScan()">
                                <i class="bi bi-arrow-right-circle me-1"></i> Tiếp tục: quét mã serial
                            </button>
                        </div>
                    </div>

                    <!-- BƯỚC 2: Quét serial rồi xuất kho (hiện sau khi bấm "Tiếp tục") -->
                    <div class="card bg-white mb-4 d-none" id="scanCard">
                        <div class="card-header bg-warning bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                            <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-barcode me-2"></i>Quét mã serial hàng xuất</h5>
                            <button type="button" class="btn btn-sm btn-outline-secondary" onclick="backToQty()">
                                <i class="bi bi-arrow-left me-1"></i> Sửa số lượng
                            </button>
                        </div>
                        <div class="card-body p-4">
                            <div class="mb-3">
                                <label for="barcode-scanner-input" class="form-label fw-semibold text-slate-700">Quét mã serial (máy quét hoặc nhập tay rồi Enter):</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light text-muted"><i class="bi bi-upc-scan"></i></span>
                                    <input type="text" id="barcode-scanner-input" class="form-control form-control-lg border-warning" placeholder="Đặt con trỏ tại đây và quét mã..." autocomplete="off">
                                </div>
                                <div id="scan-status-alert" class="alert d-none mt-2 px-3 py-2" role="alert"></div>
                            </div>
                            <hr class="my-4">
                            <h6 class="fw-bold text-slate-800 mb-3"><i class="bi bi-list-task me-1"></i>Tiến độ quét:</h6>
                            <div class="row g-3" id="scanPanels"></div>
                        </div>
                        <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                            <a href="export-ticket?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                            <button type="submit" id="confirm-submit-btn" class="btn btn-secondary px-4" disabled>
                                <i class="bi bi-box-arrow-right me-1"></i> Xuất kho
                            </button>
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
        // Danh sách serial khả dụng theo từng sản phẩm (nạp từ server)
        const availableSerials = {
            <%
            Map<Integer, List<String>> avMap = (Map<Integer, List<String>>) request.getAttribute("availableSerials");
            if (avMap != null) {
                for (Map.Entry<Integer, List<String>> entry : avMap.entrySet()) {
            %>
            <%= entry.getKey() %>: [
                <% for (String s : entry.getValue()) { %>"<%= s %>",<% } %>
            ],
            <%
                }
            }
            %>
        };

        const scannedSerials = {};              // { productId: [serial,...] }
        const allScannedSerialsGlobal = new Set();
        let requiredByProduct = {};             // { productId: soLuongCanQuet } — chốt ở bước 1

        document.addEventListener("DOMContentLoaded", function() {
            // Kẹp số lượng nhập trong khoảng cho phép
            document.querySelectorAll(".qty-input").forEach(input => input.addEventListener("input", function() {
                if (this.value !== "") {
                    let val = parseInt(this.value);
                    let max = parseInt(this.getAttribute("max"));
                    if (!isNaN(val) && !isNaN(max) && val > max) this.value = max;
                }
            }));
        });

        // BƯỚC 1 -> 2: kiểm tra số lượng, dựng panel quét theo số lượng vừa nhập
        function lockAndBuildScan() {
            const qtyInputs = document.querySelectorAll(".qty-input");
            let totalQty = 0;
            for (const input of qtyInputs) {
                const qty = parseInt(input.value) || 0;
                const remaining = parseInt(input.getAttribute("data-remaining")) || 0;
                const stock = parseInt(input.getAttribute("data-stock")) || 0;
                const pname = input.getAttribute("data-pname") || "Sản phẩm";
                if (qty > remaining) { alert("Sản phẩm '" + pname + "': số lượng xuất (" + qty + ") vượt quá số còn lại của yêu cầu (" + remaining + ")."); return; }
                if (qty > stock) { alert("Sản phẩm '" + pname + "': số lượng xuất (" + qty + ") vượt quá tồn kho khả dụng (" + stock + ")."); return; }
                totalQty += qty;
            }
            if (totalQty <= 0) { alert("Bạn phải chọn xuất ít nhất 1 sản phẩm (số lượng > 0)."); return; }

            // Dựng panel quét cho các sản phẩm có số lượng > 0
            requiredByProduct = {};
            for (const k in scannedSerials) delete scannedSerials[k];
            allScannedSerialsGlobal.clear();
            const panels = document.getElementById("scanPanels");
            panels.innerHTML = "";
            document.getElementById("hidden-serials-container").innerHTML = "";

            qtyInputs.forEach(input => {
                const qty = parseInt(input.value) || 0;
                if (qty <= 0) return;
                const pid = input.getAttribute("data-pid");
                const pname = input.getAttribute("data-pname") || "Sản phẩm";
                const sku = input.getAttribute("data-sku") || "";
                requiredByProduct[pid] = qty;
                scannedSerials[pid] = [];
                const col = document.createElement("div");
                col.className = "col-md-6";
                col.innerHTML =
                    '<div class="border rounded p-3 bg-light" id="prod-panel-' + pid + '">' +
                      '<div class="d-flex justify-content-between align-items-center mb-2">' +
                        '<span class="fw-semibold text-slate-800 small text-truncate" style="max-width:70%;" title="' + pname + '">' + pname + '</span>' +
                        '<span class="badge bg-secondary bg-opacity-10 text-secondary">' + sku + '</span>' +
                      '</div>' +
                      '<div class="d-flex justify-content-between align-items-center border-top pt-2">' +
                        '<span class="text-muted small">Cần xuất: <strong>' + qty + '</strong></span>' +
                        '<span class="small font-monospace fw-bold scan-progress-text" id="progress-' + pid + '" data-required="' + qty + '">Đã quét: <span class="scanned-count text-danger">0</span>/' + qty + '</span>' +
                      '</div>' +
                      '<div class="mt-2 border-top pt-2" style="max-height:120px;overflow-y:auto;">' +
                        '<ul class="list-group list-group-flush small" id="list-' + pid + '">' +
                          '<li class="list-group-item bg-transparent text-muted text-center py-1 no-serials-msg">Chưa quét mã nào</li>' +
                        '</ul>' +
                      '</div>' +
                    '</div>';
                panels.appendChild(col);
            });

            document.getElementById("step1Footer").classList.add("d-none");
            document.getElementById("scanCard").classList.remove("d-none");
            // Khóa ô số lượng (readonly vẫn gửi lên server, khác disabled)
            qtyInputs.forEach(input => input.setAttribute("readonly", "readonly"));
            checkOverallCompletion();
            const si = document.getElementById("barcode-scanner-input");
            si.focus();
        }

        function backToQty() {
            document.getElementById("scanCard").classList.add("d-none");
            document.getElementById("step1Footer").classList.remove("d-none");
            document.querySelectorAll(".qty-input").forEach(input => input.removeAttribute("readonly"));
        }

        function playBeep(isSuccess) {
            try {
                const ctx = new (window.AudioContext || window.webkitAudioContext)();
                const osc = ctx.createOscillator(); const gain = ctx.createGain();
                osc.connect(gain); gain.connect(ctx.destination);
                if (isSuccess) { osc.type='sine'; osc.frequency.setValueAtTime(800, ctx.currentTime); gain.gain.setValueAtTime(0.08, ctx.currentTime); osc.start(); ctx.resume(); setTimeout(()=>{osc.stop();ctx.close();},80); }
                else { osc.type='sawtooth'; osc.frequency.setValueAtTime(140, ctx.currentTime); gain.gain.setValueAtTime(0.12, ctx.currentTime); osc.start(); ctx.resume(); setTimeout(()=>{osc.stop();ctx.close();},350); }
            } catch(e) {}
        }

        function showScanAlert(message, type) {
            const box = document.getElementById("scan-status-alert");
            box.className = "alert mt-2 px-3 py-2 " + (type === "success" ? "alert-success" : "alert-danger");
            box.innerHTML = (type === "success" ? '<i class="bi bi-check-circle-fill me-1"></i>' : '<i class="bi bi-exclamation-triangle-fill me-1"></i>') + message;
            box.classList.remove("d-none");
        }

        function processScan(serial) {
            serial = serial.trim();
            if (!serial) return;
            if (allScannedSerialsGlobal.has(serial)) { playBeep(false); showScanAlert("Mã <strong>" + serial + "</strong> đã quét trong phiên này!", "danger"); return; }
            let foundPid = null;
            for (const pid in requiredByProduct) {
                if (availableSerials[pid] && availableSerials[pid].includes(serial)) { foundPid = pid; break; }
            }
            if (!foundPid) { playBeep(false); showScanAlert("Mã <strong>" + serial + "</strong> không thuộc sản phẩm nào đang xuất (hoặc không có trong kho).", "danger"); return; }
            const required = requiredByProduct[foundPid];
            if (scannedSerials[foundPid].length >= required) { playBeep(false); showScanAlert("Sản phẩm này đã quét đủ số lượng!", "danger"); return; }

            scannedSerials[foundPid].push(serial);
            allScannedSerialsGlobal.add(serial);
            playBeep(true);
            showScanAlert("Đã quét: <strong>" + serial + "</strong>", "success");

            const listEl = document.getElementById("list-" + foundPid);
            const noMsg = listEl.querySelector(".no-serials-msg"); if (noMsg) noMsg.remove();
            const li = document.createElement("li");
            li.className = "list-group-item bg-transparent py-1 px-0 d-flex justify-content-between align-items-center text-slate-700 font-monospace";
            li.id = "li-" + serial.replace(/[^a-zA-Z0-9]/g, "-");
            li.innerHTML = '<span><i class="bi bi-check-lg text-success me-1"></i>' + serial + '</span>' +
                           '<button type="button" class="btn btn-link btn-sm text-danger p-0 text-decoration-none" onclick="removeSerial(\'' + foundPid + '\', \'' + serial + '\')"><i class="bi bi-trash"></i></button>';
            listEl.appendChild(li);

            const c = document.getElementById("hidden-serials-container");
            const hi = document.createElement("input");
            hi.type = "hidden"; hi.name = "scanned_serials"; hi.value = serial;
            hi.id = "hidden-input-" + serial.replace(/[^a-zA-Z0-9]/g, "-");
            c.appendChild(hi);

            updateProgress(foundPid);
            checkOverallCompletion();
        }

        window.removeSerial = function(productId, serial) {
            if (!scannedSerials[productId]) return;
            const idx = scannedSerials[productId].indexOf(serial);
            if (idx > -1) {
                scannedSerials[productId].splice(idx, 1);
                allScannedSerialsGlobal.delete(serial);
                const li = document.getElementById("li-" + serial.replace(/[^a-zA-Z0-9]/g, "-")); if (li) li.remove();
                const hi = document.getElementById("hidden-input-" + serial.replace(/[^a-zA-Z0-9]/g, "-")); if (hi) hi.remove();
                const listEl = document.getElementById("list-" + productId);
                if (scannedSerials[productId].length === 0) listEl.innerHTML = '<li class="list-group-item bg-transparent text-muted text-center py-1 no-serials-msg">Chưa quét mã nào</li>';
                updateProgress(productId);
                checkOverallCompletion();
            }
        };

        function updateProgress(productId) {
            const progressEl = document.getElementById("progress-" + productId);
            const required = parseInt(progressEl.getAttribute("data-required"));
            const cur = scannedSerials[productId] ? scannedSerials[productId].length : 0;
            const countEl = progressEl.querySelector(".scanned-count");
            countEl.textContent = cur;
            const panel = document.getElementById("prod-panel-" + productId);
            if (cur === required) { countEl.className = "scanned-count text-success"; panel.className = "border rounded p-3 bg-light border-success"; }
            else { countEl.className = "scanned-count text-danger"; panel.className = "border rounded p-3 bg-light"; }
        }

        function checkOverallCompletion() {
            let allDone = true, totalRequired = 0, totalScanned = 0;
            for (const pid in requiredByProduct) {
                const req = requiredByProduct[pid];
                const scan = scannedSerials[pid] ? scannedSerials[pid].length : 0;
                totalRequired += req; totalScanned += scan;
                if (scan < req) allDone = false;
            }
            const btn = document.getElementById("confirm-submit-btn");
            if (btn) {
                if (allDone && totalScanned === totalRequired && totalRequired > 0) { btn.removeAttribute("disabled"); btn.className = "btn btn-success px-4"; }
                else { btn.setAttribute("disabled", "true"); btn.className = "btn btn-secondary px-4"; }
            }
        }

        document.addEventListener("DOMContentLoaded", function() {
            const si = document.getElementById("barcode-scanner-input");
            if (si) {
                si.addEventListener("keypress", function(e) {
                    if (e.key === 'Enter') { e.preventDefault(); const v = this.value.trim(); if (v) processScan(v); this.value=""; this.focus(); }
                });
            }
            const form = document.getElementById("ginForm");
            if (form) {
                form.addEventListener("submit", function(e) {
                    // Chỉ cho submit khi đã quét đủ (nút đã bật). Hỏi xác nhận lần cuối.
                    if (!confirm("Xác nhận XUẤT KHO các sản phẩm vừa quét? Hàng sẽ bị trừ khỏi tồn kho ngay.")) {
                        e.preventDefault();
                    }
                });
            }
        });
        <% } %>
    </script>
</body>
</html>
