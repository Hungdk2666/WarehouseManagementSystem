<%@page import="model.Ticket"%>
<%@page import="model.TicketDetail"%>
<%@page import="model.User"%>
<%@page import="model.ProductItem"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_VIEW_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Ticket ticket = (Ticket) request.getAttribute("ticket");
    if (ticket == null) {
        response.sendRedirect(request.getContextPath() + "/warehouse/import-ticket?action=list");
        return;
    }
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_IN");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_IN");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chi tiết Phiếu nhập kho - #<%= ticket.getTicketCode() %></title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Chi tiết Phiếu nhập kho</h2>
                        <p class="text-muted small mb-0">Xem danh sách sản phẩm và xác nhận nhập kho cho Phiếu nhập kho #<%= ticket.getTicketCode() %></p>
                    </div>
                    <a href="import-ticket?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại danh sách
                    </a>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-info-circle-fill me-2"></i>Thông tin Phiếu nhập kho</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Mã Phiếu nhập kho</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getTicketCode() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Mã Yêu cầu liên kết</label>
                                <span class="fw-bold text-primary">#<%= ticket.getRequestCode() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Trạng thái</label>
                                <%
                                    String statusBadge = "bg-secondary text-secondary";
                                    String displayTStatus = ticket.getStatus();
                                    if ("DRAFT".equals(ticket.getStatus())) { statusBadge = "bg-warning text-warning"; displayTStatus = "BẢN NHÁP"; }
                                    else if ("CONFIRMED".equals(ticket.getStatus())) { statusBadge = "bg-success text-success"; displayTStatus = "ĐÃ XÁC NHẬN"; }
                                    else if ("CANCELLED".equals(ticket.getStatus())) { statusBadge = "bg-secondary text-secondary"; displayTStatus = "ĐÃ HỦY"; }
                                %>
                                <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayTStatus %></span>
                            </div>
                            
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Người tạo (Thủ kho)</label>
                                <span class="text-slate-700"><%= ticket.getKeeperFullName() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Ngày tạo</label>
                                <span class="text-slate-700"><%= ticket.getCreatedAt() %></span>
                            </div>
                            
                            <% if (ticket.getConfirmedBy() != null) { %>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Người xác nhận (Quản lý)</label>
                                <span class="text-slate-700"><%= ticket.getConfirmedByFullName() %></span>
                            </div>
                            <div class="col-md-4 border-top pt-2">
                                <label class="text-muted small d-block">Thời gian xác nhận</label>
                                <span class="text-slate-700"><%= ticket.getConfirmedAt() %></span>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-list-check me-2"></i>Sản phẩm thực nhận</h5>
                    </div>
                    <div class="card-body p-0">
                        <table class="table align-middle text-center mb-0">
                            <thead class="table-light">
                                <tr>
                                    <th>#</th>
                                    <th class="text-start ps-4">Tên sản phẩm</th>
                                    <th>SKU</th>
                                    <th>Đơn vị</th>
                                    <th>SL thực tế nhận</th>
                                    <th>Tình trạng</th>
                                    <th>Đơn giá thực tế</th>
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
                                        <%
                                            String cond = ticket.getRequestedCondition();
                                            String condBadge = "bg-success text-success";
                                            String displayCond = "MỚI";
                                            if ("DAMAGED".equals(cond)) { condBadge = "bg-danger text-danger"; displayCond = "HỎNG"; }
                                            else if ("USED".equals(cond)) { condBadge = "bg-warning text-warning"; displayCond = "CŨ"; }
                                        %>
                                        <span class="badge <%= condBadge %> bg-opacity-10"><%= displayCond %></span>
                                    </td>
                                    <td><%= String.format("%,.0f", d.getUnitCost() != null ? d.getUnitCost().doubleValue() : 0.0) %> VND</td>
                                    <td class="fw-bold"><%= String.format("%,.0f", itemCost) %> VND</td>
                                </tr>
                                <%
                                        }
                                    }
                                %>
                                <tr class="table-light fw-bold">
                                    <td colspan="7" class="text-end pe-4">Tổng giá trị thực tế:</td>
                                    <td><%= String.format("%,.0f", totalCost) %> VND</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    
                    <% if ("DRAFT".equals(ticket.getStatus()) && (canConfirm || canCancel)) { %>
                    <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                        <% if (canCancel) { %>
                        <form action="import-ticket?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Bạn có chắc chắn muốn hủy phiếu nhập kho này?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <button type="submit" class="btn btn-outline-danger px-4"><i class="bi bi-x-circle me-1"></i> Hủy Phiếu nhập</button>
                        </form>
                        <% } %>
                        <% if (canConfirm) { %>
                        <form action="import-ticket?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Xác nhận Phiếu nhập kho này sẽ tăng lượng hàng tồn kho, cập nhật giá vốn bình quân động và ghi nhận nhật ký giao dịch. Tiến hành?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <div id="hidden-serials-container"></div>
                            <button type="submit" id="confirm-submit-btn" class="btn btn-success px-4" <%= "RETURN".equals(ticket.getRequestReason()) ? "disabled" : "" %>><i class="bi bi-check-circle-fill me-1"></i> Xác nhận & Nhập kho</button>
                        </form>
                        <% } %>
                    </div>
                    <% } %>
                </div>

                <%
                    List<ProductItem> importedSerials = (List<ProductItem>) request.getAttribute("importedSerials");
                    if (importedSerials != null && !importedSerials.isEmpty()) {
                %>
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-success bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-success"><i class="bi bi-qr-code-scan me-2"></i>Mã vạch & Số Serial đã tạo</h5>
                        <button class="btn btn-success btn-sm d-inline-flex align-items-center gap-1" onclick="printBarcodes()">
                            <i class="bi bi-printer-fill"></i> In tất cả nhãn mã vạch
                        </button>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3" id="barcode-list-container">
                            <% for (ProductItem item : importedSerials) { %>
                            <div class="col-md-4 col-sm-6 text-center barcode-card-item mb-2">
                                <div class="border rounded p-3 bg-light">
                                    <div class="fw-semibold text-slate-800 small text-truncate mb-1" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                    <svg class="barcode-svg" data-value="<%= item.getSerialNumber() %>"></svg>
                                </div>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
                <!-- Hidden Printable Area -->
                <div class="d-none">
                    <div id="printable-barcodes-section">
                        <div style="display: flex; flex-wrap: wrap; justify-content: space-around; padding: 20px; font-family: 'Inter', sans-serif;">
                            <% for (ProductItem item : importedSerials) { %>
                            <div style="border: 1px solid #ccc; border-radius: 4px; padding: 15px; margin: 10px; background-color: #fff; text-align: center; width: 280px; page-break-inside: avoid; box-sizing: border-box;">
                                <div style="font-weight: bold; color: #333; margin-bottom: 5px; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                <svg class="printable-barcode-svg" data-value="<%= item.getSerialNumber() %>" style="max-width: 100%; height: auto;"></svg>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
                <script>
                    document.addEventListener("DOMContentLoaded", function() {
                        // Render standard display barcodes
                        document.querySelectorAll(".barcode-svg").forEach(function(el) {
                            const val = el.getAttribute("data-value");
                            JsBarcode(el, val, {
                                format: "CODE128",
                                width: 1.5,
                                height: 40,
                                displayValue: true,
                                fontSize: 11
                            });
                        });
                        
                        // Render printable barcodes
                        document.querySelectorAll(".printable-barcode-svg").forEach(function(el) {
                            const val = el.getAttribute("data-value");
                            JsBarcode(el, val, {
                                format: "CODE128",
                                width: 1.1,
                                height: 35,
                                displayValue: true,
                                fontSize: 11
                            });
                        });
                    });
                    
                    function printBarcodes() {
                        const printContent = document.getElementById("printable-barcodes-section").innerHTML;
                        const originalContent = document.body.innerHTML;
                        
                        // Replace body with print-only content
                        document.body.innerHTML = '<div>' + printContent + '</div>';
                        window.print();
                        
                        // Restore original page content
                        document.body.innerHTML = originalContent;
                        window.location.reload(); // reload to restore scripts/events
                    }
                </script>
                <% } %>

                <% if ("DRAFT".equals(ticket.getStatus()) && canConfirm && "RETURN".equals(ticket.getRequestReason())) { %>
                <!-- Scanning Interface Panel -->
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-warning bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-barcode me-2"></i>Thực hiện quét mã vạch (Barcode/Serial)</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="mb-3">
                            <label for="barcode-scanner-input" class="form-label fw-semibold text-slate-700">Quét mã Serial sản phẩm trả lại (Sử dụng máy quét hoặc nhập tay):</label>
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
                            showScanAlert("Mã Serial <strong>" + serial + "</strong> không thuộc lô hàng đã xuất hoặc không khả dụng cho sản phẩm này!", "danger");
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
                            panel.className = "border rounded p-3 bg-success bg-opacity-10 border-success";
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
