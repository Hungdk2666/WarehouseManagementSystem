<%@page import="model.Ticket"%>
<%@page import="model.TicketDetail"%>
<%@page import="model.User"%>
<%@page import="model.ProductItem"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_VIEW_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Ticket ticket = (Ticket) request.getAttribute("ticket");
    if (ticket == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/export-ticket?action=list");
        return;
    }
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_OUT");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_OUT");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi tiết phiếu xuất kho - #<%= ticket.getTicketCode() %></title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css?v=detail-layout-1">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="detail-page-header">
                    <div>
                        <h2 class="page-title">Chi tiết phiếu xuất kho</h2>
                        <p class="page-subtitle">Xem chi tiết sản phẩm và xác nhận xuất kho thực tế cho Phiếu xuất kho #<%= ticket.getTicketCode() %></p>
                    </div>
                    <a href="export-ticket?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại danh sách
                    </a>
                </div>

                <div class="card detail-section-card bg-white">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin phiếu xuất kho</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="detail-info-grid">
                            <div class="detail-info-item">
                                <label class="detail-info-label">Mã phiếu xuất</label>
                                <span class="detail-info-value">#<%= ticket.getTicketCode() %></span>
                            </div>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Mã yêu cầu liên kết</label>
                                <a href="export-request?action=detail&id=<%= ticket.getRequestId() %>" class="detail-info-value text-decoration-none">
                                    #<%= ticket.getRequestCode() %>
                                </a>
                            </div>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Trạng thái</label>
                                <%
                                    String statusBadge = "chip-muted";
                                    String displayStatus = ticket.getStatus();
                                    if ("DRAFT".equals(ticket.getStatus())) {
                                        statusBadge = "chip-warning";
                                        displayStatus = "Bản nháp";
                                    } else if ("IN_TRANSIT".equals(ticket.getStatus())) {
                                        statusBadge = "chip-info";
                                        displayStatus = "Đang vận chuyển";
                                    } else if ("CONFIRMED".equals(ticket.getStatus())) {
                                        statusBadge = "chip-success";
                                        displayStatus = "Đã xác nhận";
                                    } else if ("CANCELLED".equals(ticket.getStatus())) {
                                        statusBadge = "chip-muted";
                                        displayStatus = "Đã hủy";
                                    }
                                %>
                                <span class="status-chip <%= statusBadge %>"><%= displayStatus %></span>
                            </div>
                            
                            <div class="detail-info-item">
                                <label class="detail-info-label">Điểm nhận / Đối tác</label>
                                <span class="detail-info-value"><%= ticket.getPartnerName() %></span>
                            </div>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Lý do xuất</label>
                                <span class="detail-info-value">
                                    <%
                                        if ("TRANSFER".equals(ticket.getRequestReason())) out.print("CHUYỂN KHO");
                                        else if ("CUSTOMER_SALE".equals(ticket.getRequestReason())) out.print("BÁN HÀNG");
                                        else if ("DISPLAY".equals(ticket.getRequestReason())) out.print("TRƯNG BÀY");
                                        else if ("WARRANTY".equals(ticket.getRequestReason())) out.print("BẢO HÀNH");
                                        else if ("DISPOSAL".equals(ticket.getRequestReason())) out.print("TIÊU HỦY");
                                        else out.print(ticket.getRequestReason() != null ? ticket.getRequestReason() : "-");
                                    %>
                                </span>
                            </div>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Tình trạng xuất</label>
                                <span class="detail-info-value">
                                    <%= "USED".equals(ticket.getRequestedCondition()) ? "Hàng Cũ" : "Hàng Mới" %>
                                </span>
                            </div>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Người tạo (Thủ kho)</label>
                                <span class="detail-info-value"><%= ticket.getKeeperFullName() %></span>
                            </div>
                            
                            <div class="detail-info-item">
                                <label class="detail-info-label">Thời gian tạo</label>
                                <span class="detail-info-value"><%= ticket.getCreatedAt() %></span>
                            </div>
                            
                            <% if (ticket.getConfirmedBy() != null) { %>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Người xác nhận</label>
                                <span class="detail-info-value"><%= ticket.getConfirmedByFullName() %></span>
                            </div>
                            <div class="detail-info-item">
                                <label class="detail-info-label">Thời gian xác nhận</label>
                                <span class="detail-info-value"><%= ticket.getConfirmedAt() %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card detail-section-card bg-white">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-check me-2 text-primary"></i>Danh sách sản phẩm xuất kho</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                        <table class="table align-middle text-center mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th class="text-start ps-4">Tên sản phẩm</th>
                                    <th>SKU</th>
                                    <th>Đơn vị</th>
                                    <th>Số lượng xuất thực tế</th>
                                    <th>Đơn giá (Tạm tính)</th>
                                    <th>Thành tiền</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    double totalCost = 0;
                                    if (ticket.getDetails() != null && !ticket.getDetails().isEmpty()) {
                                        int index = 1;
                                        for (TicketDetail d : ticket.getDetails()) {
                                            double itemCost = d.getQuantity() * (d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0);
                                            totalCost += itemCost;
                                %>
                                <tr>
                                    <td><%= index++ %></td>
                                    <td class="text-start ps-4 fw-semibold"><%= d.getProductName() %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                    <td><%= d.getUnit() %></td>
                                    <td class="fw-bold"><%= d.getQuantity() %></td>
                                    <td>
                                        <% if ("CONFIRMED".equals(ticket.getStatus()) || "IN_TRANSIT".equals(ticket.getStatus())) { %>
                                            <%= String.format("%,.0f", d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0) %> VND
                                        <% } else { %>
                                            <span class="text-muted small">Chờ xác nhận</span>
                                        <% } %>
                                    </td>
                                    <td class="fw-bold">
                                        <% if ("CONFIRMED".equals(ticket.getStatus()) || "IN_TRANSIT".equals(ticket.getStatus())) { %>
                                            <%= String.format("%,.0f", itemCost) %> VND
                                        <% } else { %>
                                            <span class="text-muted small">Chờ xác nhận</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <%
                                        }
                                    }
                                %>
                                <% if ("CONFIRMED".equals(ticket.getStatus()) || "IN_TRANSIT".equals(ticket.getStatus())) { %>
                                <tr class="table-light fw-bold">
                                    <td colspan="6" class="text-end pe-4">Tổng giá trị xuất kho:</td>
                                    <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                        </div>
                    </div>
                    
                    <% if ("DRAFT".equals(ticket.getStatus()) && (canConfirm || canCancel)) { %>
                    <div class="card-footer detail-actions">
                        <% if (canCancel) { %>
                        <form action="export-ticket?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Bạn có chắc chắn muốn hủy Phiếu xuất kho này không?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <button type="submit" class="btn btn-outline-danger px-4"><i class="bi bi-x-circle me-1"></i> Hủy phiếu xuất kho</button>
                        </form>
                        <% } %>
                        <% if (canConfirm) { %>
                        <form action="export-ticket?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Xác nhận Phiếu xuất kho này sẽ trừ số lượng sản phẩm trong tồn kho thực tế và ghi lại nhật ký hoạt động. Xác nhận?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <div id="hidden-serials-container"></div>
                            <button type="submit" id="confirm-submit-btn" class="btn btn-secondary px-4" disabled><i class="bi bi-check-circle-fill me-1"></i> Xác nhận & Xuất kho</button>
                        </form>
                        <% } %>
                    </div>
                    <% } %>
                    
                    <%-- IN_TRANSIT TRANSFER ticket — luồng v3: kho đích sẽ thấy Request IN-TRANSFER auto-sinh ở module Import Request --%>
                    <% if ("IN_TRANSIT".equals(ticket.getStatus())) { %>
                    <div class="card-footer bg-info bg-opacity-10 p-3 small text-info border-top-0">
                        <i class="bi bi-info-circle me-1"></i>
                        Phiếu đang vận chuyển. Kho đích cần vào <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list">Yêu cầu nhập kho</a>
                        để xử lý phiếu nhập tương ứng (hệ thống đã tự tạo khi xác nhận xuất kho).
                    </div>
                    <% } %>
                </div>

                <%
                    List<ProductItem> exportedSerials = (List<ProductItem>) request.getAttribute("exportedSerials");
                    if (exportedSerials != null && !exportedSerials.isEmpty()) {
                %>
                <div class="card bg-white mb-4">
                    <div class="card-header bg-light py-3 border-0">
                        <h5 class="mb-0 fw-bold text-success"><i class="bi bi-check2-all me-2"></i>Danh sách mã Serial xuất kho (Truy xuất nguồn gốc)</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <% for (ProductItem item : exportedSerials) { %>
                            <div class="col-md-4 col-sm-6 mb-2">
                                <div class="border rounded p-2 px-3 bg-light d-flex justify-content-between align-items-center">
                                    <div class="text-truncate" style="max-width: 60%;">
                                        <span class="fw-semibold text-slate-800 small d-block text-truncate" title="<%= item.getProductName() %>"><%= item.getProductName() %></span>
                                        <span class="text-muted small font-monospace"><%= item.getSku() %></span>
                                    </div>
                                    <span class="badge bg-light text-success font-monospace px-2 py-1"><%= item.getSerialNumber() %></span>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                <% } %>

                <% if ("DRAFT".equals(ticket.getStatus()) && canConfirm) { %>
                <!-- Scanning Interface Panel -->
                <div class="card bg-white mb-4">
                    <div class="card-header bg-warning bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-barcode me-2"></i>Thực hiện quét mã vạch (Barcode/Serial)</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="mb-3">
                            <label for="barcode-scanner-input" class="form-label fw-semibold text-slate-700">Quét mã Serial sản phẩm (Sử dụng máy quét hoặc nhập tay):</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light text-muted"><i class="bi bi-upc-scan"></i></span>
                                <input type="text" id="barcode-scanner-input" class="form-control form-control-lg border-warning" placeholder="Để con trỏ tại đây và quét mã vạch..." autofocus autocomplete="off">
                            </div>
                            <div id="scan-status-alert" class="alert d-none mt-2 px-3 py-2" role="alert"></div>
                        </div>
                        
                        <hr class="my-4">
                        
                        <h6 class="fw-bold text-slate-800 mb-3"><i class="bi bi-list-task me-1"></i>Tiến độ quét mã xác thực:</h6>
                        <div class="row g-3">
                            <% 
                                if (ticket.getDetails() != null) {
                                    for (TicketDetail d : ticket.getDetails()) {
                             %>
                            <div class="col-md-6">
                                <div class="border rounded p-3 bg-light" id="prod-panel-<%= d.getProductId() %>">
                                    <div class="d-flex justify-content-between align-items-center mb-2">
                                        <span class="fw-semibold text-slate-800 small text-truncate" style="max-width: 70%;" title="<%= d.getProductName() %>"><%= d.getProductName() %></span>
                                        <span class="badge bg-secondary bg-opacity-10 text-secondary sku-badge"><%= d.getSku() %></span>
                                    </div>
                                    <div class="d-flex justify-content-between align-items-center border-top pt-2">
                                        <span class="text-muted small">Yêu cầu: <strong><%= d.getQuantity() %></strong></span>
                                        <span class="small font-monospace fw-bold scan-progress-text" id="progress-<%= d.getProductId() %>" data-required="<%= d.getQuantity() %>">Đã quét: <span class="scanned-count text-danger">0</span>/<%= d.getQuantity() %></span>
                                    </div>
                                    <div class="scanned-serials-list mt-2 border-top pt-2" style="max-height: 120px; overflow-y: auto;">
                                        <ul class="list-group list-group-flush small" id="list-<%= d.getProductId() %>">
                                            <li class="list-group-item bg-transparent text-muted text-center py-1 no-serials-msg">Chưa có mã serial nào được quét</li>
                                        </ul>
                                    </div>
                                </div>
                            </div>
                            <% 
                                    }
                                }
                            %>
                        </div>
                    </div>
                </div>

                <script>
                    // Available Serials mapping loaded from request
                    const availableSerials = {
                        <% 
                        Map<Integer, List<String>> avMap = (Map<Integer, List<String>>) request.getAttribute("availableSerials");
                        if (avMap != null) {
                            for (Map.Entry<Integer, List<String>> entry : avMap.entrySet()) {
                        %>
                            <%= entry.getKey() %>: [
                                <% for (String s : entry.getValue()) { %>
                                    "<%= s %>",
                                <% } %>
                            ],
                        <% 
                            }
                        }
                        %>
                    };

                    // Currently scanned serials model
                    const scannedSerials = {}; // format: { productId: [serial1, serial2, ...] }
                    
                    // Track all scanned serials globally for duplicate checks
                    const allScannedSerialsGlobal = new Set();

                    // Sound synthesis feedback using Web Audio API
                    function playBeep(isSuccess) {
                        try {
                            const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                            const oscillator = audioCtx.createOscillator();
                            const gainNode = audioCtx.createGain();
                            
                            oscillator.connect(gainNode);
                            gainNode.connect(audioCtx.destination);
                            
                            if (isSuccess) {
                                oscillator.type = 'sine';
                                oscillator.frequency.setValueAtTime(800, audioCtx.currentTime); // 800Hz
                                gainNode.gain.setValueAtTime(0.08, audioCtx.currentTime);
                                oscillator.start();
                                audioCtx.resume();
                                setTimeout(() => {
                                    oscillator.stop();
                                    audioCtx.close();
                                }, 80);
                            } else {
                                oscillator.type = 'sawtooth';
                                oscillator.frequency.setValueAtTime(140, audioCtx.currentTime); // 140Hz buzzer
                                gainNode.gain.setValueAtTime(0.12, audioCtx.currentTime);
                                oscillator.start();
                                audioCtx.resume();
                                setTimeout(() => {
                                    oscillator.stop();
                                    audioCtx.close();
                                }, 350);
                            }
                        } catch (e) {
                            console.error("Audio Context error", e);
                        }
                    }

                    // Display scan message alert
                    function showScanAlert(message, type) {
                        const alertBox = document.getElementById("scan-status-alert");
                        alertBox.className = "alert mt-2 px-3 py-2 " + (type === "success" ? "alert-success" : "alert-danger");
                        alertBox.innerHTML = (type === "success" ? '<i class="bi bi-check-circle-fill me-1"></i>' : '<i class="bi bi-exclamation-triangle-fill me-1"></i>') + message;
                        alertBox.classList.remove("d-none");
                    }

                    // DOM element for scan input
                    const scanInput = document.getElementById("barcode-scanner-input");

                    // Auto focus scanner input
                    scanInput.focus();
                    setInterval(function() {
                        const activeEl = document.activeElement;
                        if (activeEl.tagName !== 'INPUT' && activeEl.tagName !== 'TEXTAREA') {
                            scanInput.focus();
                        }
                    }, 2000);

                    // Process scanned serial number
                    function processScan(serial) {
                        serial = serial.trim();
                        if (!serial) return;

                        // 1. Check if already scanned in this session
                        if (allScannedSerialsGlobal.has(serial)) {
                            playBeep(false);
                            showScanAlert("Mã Serial <strong>" + serial + "</strong> đã được quét trong phiên làm việc này!", "danger");
                            return;
                        }

                        // 2. Identify which product this serial belongs to
                        let foundProductId = null;
                        for (const prodId in availableSerials) {
                            if (availableSerials[prodId].includes(serial)) {
                                foundProductId = parseInt(prodId);
                                break;
                            }
                        }

                        if (!foundProductId) {
                            playBeep(false);
                            showScanAlert("Mã Serial <strong>" + serial + "</strong> không khớp với bất kỳ sản phẩm nào có trong kho của phiếu xuất này!", "danger");
                            return;
                        }

                        // Initialize scanned list for product if not exists
                        if (!scannedSerials[foundProductId]) {
                            scannedSerials[foundProductId] = [];
                        }

                        // Get required count
                        const progressEl = document.getElementById("progress-" + foundProductId);
                        const requiredCount = parseInt(progressEl.getAttribute("data-required"));
                        const currentCount = scannedSerials[foundProductId].length;

                        // 3. Check if required quantity is already satisfied
                        if (currentCount >= requiredCount) {
                            playBeep(false);
                            showScanAlert("Số lượng yêu cầu của sản phẩm này đã được quét đầy đủ!", "danger");
                            return;
                        }

                        // 4. Add serial
                        scannedSerials[foundProductId].push(serial);
                        allScannedSerialsGlobal.add(serial);
                        playBeep(true);
                        showScanAlert("Đã quét thành công mã Serial: <strong>" + serial + "</strong>", "success");

                        // 5. Update UI list
                        const listEl = document.getElementById("list-" + foundProductId);
                        const noMsg = listEl.querySelector(".no-serials-msg");
                        if (noMsg) noMsg.remove();

                        const li = document.createElement("li");
                        li.className = "list-group-item bg-transparent py-1 px-0 d-flex justify-content-between align-items-center text-slate-700 font-monospace";
                        li.id = "li-" + serial.replace(/[^a-zA-Z0-9]/g, "-");
                        li.innerHTML = '<span><i class="bi bi-check-lg text-success me-1"></i>' + serial + '</span>' +
                                       '<button type="button" class="btn btn-link btn-sm text-danger p-0 text-decoration-none" onclick="removeSerial(' + foundProductId + ', \'' + serial + '\')"><i class="bi bi-trash"></i></button>';
                        listEl.appendChild(li);

                        // 6. Update hidden inputs in the form
                        const formContainer = document.getElementById("hidden-serials-container");
                        const hiddenInput = document.createElement("input");
                        hiddenInput.type = "hidden";
                        hiddenInput.name = "scanned_serials";
                        hiddenInput.value = serial;
                        hiddenInput.id = "hidden-input-" + serial.replace(/[^a-zA-Z0-9]/g, "-");
                        formContainer.appendChild(hiddenInput);

                        // 7. Update progress indicators
                        updateProgress(foundProductId);
                        checkOverallCompletion();
                    }

                    // Remove a scanned serial
                    window.removeSerial = function(productId, serial) {
                        if (!scannedSerials[productId]) return;
                        const idx = scannedSerials[productId].indexOf(serial);
                        if (idx > -1) {
                            scannedSerials[productId].splice(idx, 1);
                            allScannedSerialsGlobal.delete(serial);
                            
                            // Remove from list UI
                            const li = document.getElementById("li-" + serial.replace(/[^a-zA-Z0-9]/g, "-"));
                            if (li) li.remove();
                            
                            // Remove hidden input
                            const hi = document.getElementById("hidden-input-" + serial.replace(/[^a-zA-Z0-9]/g, "-"));
                            if (hi) hi.remove();
                            
                            // Re-add empty message if list empty
                            const listEl = document.getElementById("list-" + productId);
                            if (scannedSerials[productId].length === 0) {
                                listEl.innerHTML = '<li class="list-group-item bg-transparent text-muted text-center py-1 no-serials-msg">Chưa có mã serial nào được quét</li>';
                            }
                            
                            updateProgress(productId);
                            checkOverallCompletion();
                            showScanAlert("Đã xóa mã Serial: " + serial, "success");
                        }
                    };

                    function updateProgress(productId) {
                        const progressEl = document.getElementById("progress-" + productId);
                        const requiredCount = parseInt(progressEl.getAttribute("data-required"));
                        const currentCount = scannedSerials[productId] ? scannedSerials[productId].length : 0;
                        
                        const scannedCountEl = progressEl.querySelector(".scanned-count");
                        scannedCountEl.textContent = currentCount;
                        
                        const panel = document.getElementById("prod-panel-" + productId);
                        if (currentCount === requiredCount) {
                            scannedCountEl.className = "scanned-count text-success";
                            panel.className = "border rounded p-3 bg-light border-success";
                        } else {
                            scannedCountEl.className = "scanned-count text-danger";
                            panel.className = "border rounded p-3 bg-light";
                        }
                    }

                    function checkOverallCompletion() {
                        let allDone = true;
                        let totalRequired = 0;
                        let totalScanned = 0;
                        
                        document.querySelectorAll(".scan-progress-text").forEach(function(el) {
                            const req = parseInt(el.getAttribute("data-required"));
                            const prodId = parseInt(el.id.replace("progress-", ""));
                            const scan = scannedSerials[prodId] ? scannedSerials[prodId].length : 0;
                            totalRequired += req;
                            totalScanned += scan;
                            if (scan < req) {
                                allDone = false;
                            }
                        });
                        
                        const submitBtn = document.getElementById("confirm-submit-btn");
                        if (submitBtn) {
                            if (allDone && totalScanned === totalRequired && totalRequired > 0) {
                                submitBtn.removeAttribute("disabled");
                                submitBtn.className = "btn btn-success px-4";
                            } else {
                                submitBtn.setAttribute("disabled", "true");
                                submitBtn.className = "btn btn-secondary px-4";
                            }
                        }
                    }

                    // Listen to scanner keypress
                    scanInput.addEventListener("keypress", function(e) {
                        if (e.key === 'Enter') {
                            e.preventDefault();
                            const val = this.value.trim();
                            if (val) {
                                processScan(val);
                            }
                            this.value = "";
                            this.focus();
                        }
                    });

                    // Run initial completion check (to disable submit btn initially)
                    checkOverallCompletion();
                </script>
                <% } %>

            </div>
        </div>
    </div>
</body>
</html>
