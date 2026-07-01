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
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2"></i>Thông tin Phiếu nhập kho</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Mã Phiếu nhập kho</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getTicketCode() %></span>
                            </div>
                            <div class="col-md-4">
                                <label class="text-muted small d-block">Mã Yêu cầu liên kết</label>
                                <span class="fw-bold text-slate-800">#<%= ticket.getRequestCode() %></span>
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
                                <label class="text-muted small d-block">Người xác nhận</label>
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
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-list-check me-2"></i>Sản phẩm thực nhận</h5>
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
                                            if ("DAMAGED".equals(cond)) { condBadge = "bg-danger text-danger"; displayCond = "LỖI"; }
                                            else if ("USED".equals(cond)) { condBadge = "bg-warning text-warning"; displayCond = "ĐÃ DÙNG"; }
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
                        <form action="import-ticket?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Xác nhận phiếu nhập kho này sẽ cập nhật số lượng tồn kho, giá vốn trung bình và ghi nhận vào sổ kho. Tiến hành?');">
                            <input type="hidden" name="id" value="<%= ticket.getId() %>">
                            <div id="hidden-serials-container"></div>
                            <button type="submit" id="confirm-submit-btn" class="btn btn-success px-4" <%= "RETURN".equals(ticket.getRequestReason()) ? "disabled" : "" %>><i class="bi bi-check-circle-fill me-1"></i> Xác nhận & Nhập kho</button>
                        </form>
                        <% } %>
                    </div>
                    <% } %>

                    <% if ("DRAFT".equals(ticket.getStatus()) && canConfirm && "PURCHASE".equals(ticket.getRequestReason())) { %>
                    <div class="card shadow-sm border-0 bg-white mb-4 mt-4" id="mfr-serial-card">
                        <div class="card-header bg-warning bg-opacity-10 py-3 border-0 d-flex align-items-center justify-content-between">
                            <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-upc-scan me-2"></i>Nhập Serial nhà sản xuất (tùy chọn)</h5>
                            <div class="btn-group btn-group-sm" role="group">
                                <input type="radio" class="btn-check" name="mfr-method" id="mfr-method-excel" value="excel" autocomplete="off" checked>
                                <label class="btn btn-outline-warning" for="mfr-method-excel">
                                    <i class="bi bi-file-earmark-spreadsheet me-1"></i>Upload Excel
                                </label>
                                <input type="radio" class="btn-check" name="mfr-method" id="mfr-method-scan" value="scan" autocomplete="off">
                                <label class="btn btn-outline-warning" for="mfr-method-scan">
                                    <i class="bi bi-barcode me-1"></i>Quét mã vạch
                                </label>
                            </div>
                        </div>

                        <%-- ===== PHƯƠNG PHÁP 1: UPLOAD EXCEL ===== --%>
                        <div class="card-body p-4" id="mfr-excel-panel">
                            <p class="text-muted small mb-3">Upload file Excel với 2 cột: <code>sku</code> và <code>manufacturer_serial</code>. Số lượng serial mỗi SKU phải khớp với SL thực tế nhận.</p>
                            <div class="d-flex align-items-center gap-3 mb-3">
                                <input type="file" id="mfrExcelFile" accept=".xlsx,.xls" class="form-control" style="max-width: 380px;">
                                <button type="button" id="uploadMfrBtn" class="btn btn-warning px-4" onclick="uploadMfrExcel()">
                                    <i class="bi bi-upload me-1"></i> Upload &amp; Validate
                                </button>
                                <button type="button" id="clearMfrBtn" class="btn btn-outline-secondary px-3 d-none" onclick="clearMfrSerials()">
                                    <i class="bi bi-x-circle me-1"></i> Xóa
                                </button>
                            </div>
                            <div id="mfr-upload-result"></div>
                            <div id="mfr-preview" class="d-none mt-3">
                                <h6 class="fw-bold text-success mb-2"><i class="bi bi-check-circle-fill me-1"></i> Serial NSX đã nhận dạng</h6>
                                <div id="mfr-preview-content" style="max-height: 300px; overflow-y: auto;"></div>
                            </div>
                        </div>

                        <%-- ===== PHƯƠNG PHÁP 2: QUÉT MÃ VẠCH NSX ===== --%>
                        <div class="card-body p-4 d-none" id="mfr-scan-panel">
                            <div class="mb-3">
                                <label for="mfr-scan-input" class="form-label fw-semibold text-slate-700">Quét mã Serial nhà sản xuất (Sử dụng máy quét hoặc nhập tay):</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-light text-muted"><i class="bi bi-upc-scan"></i></span>
                                    <input type="text" id="mfr-scan-input"
                                           class="form-control form-control-lg border-warning"
                                           placeholder="Để con trỏ tại đây và quét mã vạch..."
                                           autocomplete="off">
                                    <select id="mfr-scan-sku-select" class="form-select" style="max-width: 180px;" title="Chọn SKU">
                                        <% if (ticket.getDetails() != null) {
                                               for (TicketDetail d : ticket.getDetails()) { %>
                                        <option value="<%= d.getSku() %>" data-product-id="<%= d.getProductId() %>" data-required="<%= d.getQuantity() %>">
                                            <%= d.getSku() %>
                                        </option>
                                        <% } } %>
                                    </select>
                                    <button type="button" class="btn btn-warning" onclick="addMfrScanSerial()">
                                        <i class="bi bi-plus-lg"></i> Thêm
                                    </button>
                                </div>
                                <div id="mfr-scan-alert" class="alert d-none mt-2 px-3 py-2" role="alert"></div>
                            </div>

                            <hr class="my-4">

                            <h6 class="fw-bold text-slate-800 mb-3"><i class="bi bi-list-task me-1"></i>Tiến độ nhập serial NSX:</h6>
                            <div class="row g-3" id="mfr-scan-progress-panels">
                                <% if (ticket.getDetails() != null) {
                                       for (TicketDetail d : ticket.getDetails()) { %>
                                <div class="col-md-6">
                                    <div class="border rounded p-3 bg-light" id="mfr-panel-<%= d.getProductId() %>">
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span class="fw-semibold text-slate-800 small text-truncate" style="max-width: 70%;" title="<%= d.getProductName() %>"><%= d.getProductName() %></span>
                                            <span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span>
                                        </div>
                                        <div class="d-flex justify-content-between align-items-center border-top pt-2">
                                            <span class="text-muted small">Cần nhập: <strong><%= d.getQuantity() %></strong></span>
                                            <span class="small font-monospace fw-bold mfr-progress-text"
                                                  id="mfr-progress-<%= d.getProductId() %>"
                                                  data-sku="<%= d.getSku() %>"
                                                  data-required="<%= d.getQuantity() %>">
                                                Đã nhập: <span class="mfr-scanned-count text-danger">0</span>/<%= d.getQuantity() %>
                                            </span>
                                        </div>
                                        <div class="scanned-serials-list mt-2 border-top pt-2" style="max-height: 120px; overflow-y: auto;">
                                            <ul class="list-group list-group-flush small" id="mfr-list-<%= d.getProductId() %>">
                                                <li class="list-group-item bg-transparent text-muted text-center py-1 mfr-no-serial-msg">Chưa có serial NSX nào được nhập</li>
                                            </ul>
                                        </div>
                                    </div>
                                </div>
                                <% } } %>
                            </div>
                        </div>
                    </div>



                    <script>
                    // =============================================
                    // PHƯƠNG PHÁP 1: UPLOAD EXCEL
                    // =============================================
                    function uploadMfrExcel() {
                        const fileInput = document.getElementById('mfrExcelFile');
                        if (!fileInput.files || fileInput.files.length === 0) {
                            showMfrAlert('Vui lòng chọn file Excel.', 'danger');
                            return;
                        }
                        const formData = new FormData();
                        formData.append('excelFile', fileInput.files[0]);
                        formData.append('id', '<%= ticket.getId() %>');
                        formData.append('action', 'uploadSerials');

                        document.getElementById('uploadMfrBtn').disabled = true;
                        document.getElementById('uploadMfrBtn').innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Đang xử lý...';

                        fetch('import-ticket?action=uploadSerials&id=<%= ticket.getId() %>', {
                            method: 'POST',
                            body: formData
                        })
                        .then(r => r.json())
                        .then(data => {
                            document.getElementById('uploadMfrBtn').disabled = false;
                            document.getElementById('uploadMfrBtn').innerHTML = '<i class="bi bi-upload me-1"></i> Upload &amp; Validate';

                            if (data.valid) {
                                showMfrAlert('Upload thành công! ' + data.totalSerials + ' serial NSX đã được nhận dạng.', 'success');
                                renderMfrPreview(data.serialsBySku);
                                document.getElementById('clearMfrBtn').classList.remove('d-none');
                            } else {
                                let errHtml = '<strong>Có lỗi trong file Excel:</strong><ul class="mb-0 mt-1">';
                                data.errors.forEach(function(e) { errHtml += '<li>' + e + '</li>'; });
                                errHtml += '</ul>';
                                showMfrAlert(errHtml, 'danger');
                                document.getElementById('mfr-preview').classList.add('d-none');
                            }
                        })
                        .catch(function() {
                            document.getElementById('uploadMfrBtn').disabled = false;
                            document.getElementById('uploadMfrBtn').innerHTML = '<i class="bi bi-upload me-1"></i> Upload &amp; Validate';
                            showMfrAlert('Lỗi kết nối server.', 'danger');
                        });
                    }

                    function clearMfrSerials() {
                        fetch('import-ticket?action=clearSerials&id=<%= ticket.getId() %>', { method: 'POST' })
                        .then(function() {
                            document.getElementById('mfr-preview').classList.add('d-none');
                            document.getElementById('mfr-upload-result').innerHTML = '';
                            document.getElementById('clearMfrBtn').classList.add('d-none');
                            document.getElementById('mfrExcelFile').value = '';
                        });
                    }

                    function showMfrAlert(html, type) {
                        document.getElementById('mfr-upload-result').innerHTML =
                            '<div class="alert alert-' + type + ' border-0 py-2 px-3 small">' +
                            (type === 'success' ? '<i class="bi bi-check-circle-fill me-1"></i>' : '<i class="bi bi-exclamation-triangle-fill me-1"></i>') +
                            html + '</div>';
                    }

                    function renderMfrPreview(serialsBySku) {
                        const container = document.getElementById('mfr-preview-content');
                        let html = '<table class="table table-sm table-bordered mb-0"><thead class="table-light"><tr><th>SKU</th><th>Serial NSX</th></tr></thead><tbody>';
                        for (const sku in serialsBySku) {
                            serialsBySku[sku].forEach(function(s, i) {
                                html += '<tr><td>' + (i === 0 ? '<strong>' + sku + '</strong>' : '') + '</td><td class="font-monospace small">' + s + '</td></tr>';
                            });
                        }
                        html += '</tbody></table>';
                        container.innerHTML = html;
                        document.getElementById('mfr-preview').classList.remove('d-none');
                    }

                    // =============================================
                    // PHƯƠNG PHÁP 2: QUÉT MÃ VẠCH NSX
                    // =============================================
                    // Lưu trữ serial đã quét: { productId: [serial1, serial2,...] }
                    const mfrScannedSerials = {};
                    const mfrAllScanned = new Set();

                    function showMfrScanAlert(msg, type) {
                        const el = document.getElementById('mfr-scan-alert');
                        el.className = 'alert mt-2 py-2 px-3 small ' + (type === 'success' ? 'alert-success' : 'alert-danger');
                        el.innerHTML = (type === 'success' ? '<i class="bi bi-check-circle-fill me-1"></i>' : '<i class="bi bi-exclamation-triangle-fill me-1"></i>') + msg;
                        el.classList.remove('d-none');
                        clearTimeout(el._timer);
                        el._timer = setTimeout(() => el.classList.add('d-none'), 4000);
                    }

                    function playMfrBeep(ok) {
                        try {
                            const ctx = new (window.AudioContext || window.webkitAudioContext)();
                            const osc = ctx.createOscillator();
                            const gain = ctx.createGain();
                            osc.connect(gain); gain.connect(ctx.destination);
                            osc.type = ok ? 'sine' : 'sawtooth';
                            osc.frequency.setValueAtTime(ok ? 880 : 140, ctx.currentTime);
                            gain.gain.setValueAtTime(ok ? 0.07 : 0.12, ctx.currentTime);
                            osc.start(); ctx.resume();
                            setTimeout(() => { osc.stop(); ctx.close(); }, ok ? 80 : 320);
                        } catch(e) {}
                    }

                    function addMfrScanSerial() {
                        const input = document.getElementById('mfr-scan-input');
                        const serial = input.value.trim();
                        input.value = '';
                        input.focus();
                        if (!serial) return;
                        processMfrSerial(serial);
                    }

                    function processMfrSerial(serial) {
                        if (mfrAllScanned.has(serial)) {
                            playMfrBeep(false);
                            showMfrScanAlert('Serial <strong>' + serial + '</strong> đã được nhập trước đó!', 'danger');
                            return;
                        }

                        const skuSelect = document.getElementById('mfr-scan-sku-select');
                        const selectedOption = skuSelect.options[skuSelect.selectedIndex];
                        const productId = parseInt(selectedOption.getAttribute('data-product-id'));
                        const required = parseInt(selectedOption.getAttribute('data-required'));

                        if (!mfrScannedSerials[productId]) mfrScannedSerials[productId] = [];
                        if (mfrScannedSerials[productId].length >= required) {
                            playMfrBeep(false);
                            showMfrScanAlert('SKU <strong>' + skuSelect.value + '</strong> đã đủ số lượng serial!', 'danger');
                            return;
                        }

                        // Thêm serial
                        mfrScannedSerials[productId].push(serial);
                        mfrAllScanned.add(serial);
                        playMfrBeep(true);
                        showMfrScanAlert('Đã nhập serial NSX: <strong>' + serial + '</strong> cho SKU ' + skuSelect.value, 'success');

                        // Cập nhật UI list
                        const listEl = document.getElementById('mfr-list-' + productId);
                        const noMsg = listEl.querySelector('.mfr-no-serial-msg');
                        if (noMsg) noMsg.remove();

                        const li = document.createElement('li');
                        li.className = 'list-group-item bg-transparent py-1 px-0 d-flex justify-content-between align-items-center font-monospace text-slate-700';
                        li.id = 'mfr-li-' + serial.replace(/[^a-zA-Z0-9]/g, '-');
                        li.innerHTML = '<span><i class="bi bi-check-lg text-success me-1"></i>' + serial + '</span>' +
                                       '<button type="button" class="btn btn-link btn-sm text-danger p-0" onclick="removeMfrSerial(' + productId + ',\'' + serial + '\')">' +
                                       '<i class="bi bi-trash"></i></button>';
                        listEl.appendChild(li);

                        // Thêm hidden input vào form confirm (hidden-serials-container nằm trong form)
                        const hiddenContainer = document.getElementById('hidden-serials-container');
                        const hInput = document.createElement('input');
                        hInput.type = 'hidden';
                        hInput.name = 'manufacturer_serial_scan';
                        hInput.value = skuSelect.value + '|' + serial; // format: "SKU|serial"
                        hInput.id = 'mfr-hidden-' + serial.replace(/[^a-zA-Z0-9]/g, '-');
                        hiddenContainer.appendChild(hInput);

                        updateMfrProgress(productId);

                        // Tự động chuyển sang SKU tiếp theo nếu SKU hiện tại đã đủ
                        if (mfrScannedSerials[productId].length >= required) {
                            const opts = skuSelect.options;
                            for (let i = 0; i < opts.length; i++) {
                                const pid = parseInt(opts[i].getAttribute('data-product-id'));
                                const req = parseInt(opts[i].getAttribute('data-required'));
                                if (!mfrScannedSerials[pid] || mfrScannedSerials[pid].length < req) {
                                    skuSelect.selectedIndex = i;
                                    break;
                                }
                            }
                        }
                    }

                    window.removeMfrSerial = function(productId, serial) {
                        if (!mfrScannedSerials[productId]) return;
                        const idx = mfrScannedSerials[productId].indexOf(serial);
                        if (idx > -1) {
                            mfrScannedSerials[productId].splice(idx, 1);
                            mfrAllScanned.delete(serial);
                            const li = document.getElementById('mfr-li-' + serial.replace(/[^a-zA-Z0-9]/g, '-'));
                            if (li) li.remove();
                            const hi = document.getElementById('mfr-hidden-' + serial.replace(/[^a-zA-Z0-9]/g, '-'));
                            if (hi) hi.remove();
                            const listEl = document.getElementById('mfr-list-' + productId);
                            if (mfrScannedSerials[productId].length === 0) {
                                listEl.innerHTML = '<li class="list-group-item bg-transparent text-muted text-center py-1 mfr-no-serial-msg">Chưa có serial NSX nào</li>';
                            }
                            updateMfrProgress(productId);
                            showMfrScanAlert('Đã xóa serial: ' + serial, 'success');
                        }
                    };

                    function updateMfrProgress(productId) {
                        const el = document.getElementById('mfr-progress-' + productId);
                        const required = parseInt(el.getAttribute('data-required'));
                        const current = mfrScannedSerials[productId] ? mfrScannedSerials[productId].length : 0;
                        el.querySelector('.mfr-scanned-count').textContent = current;
                        el.querySelector('.mfr-scanned-count').className = 'mfr-scanned-count ' + (current >= required ? 'text-success' : 'text-danger');
                        const panel = document.getElementById('mfr-panel-' + productId);
                        panel.className = 'border rounded p-3 bg-light' + (current >= required ? ' border-success' : '');
                    }

                    // Xử lý chuyển đổi giữa Excel và Quét mã vạch
                    document.querySelectorAll('input[name="mfr-method"]').forEach(function(radio) {
                        radio.addEventListener('change', function() {
                            const isExcel = this.value === 'excel';
                            document.getElementById('mfr-excel-panel').classList.toggle('d-none', !isExcel);
                            document.getElementById('mfr-scan-panel').classList.toggle('d-none', isExcel);
                            if (!isExcel) {
                                setTimeout(() => document.getElementById('mfr-scan-input').focus(), 100);
                            }
                        });
                    });

                    // Xử lý Enter trên ô quét
                    document.getElementById('mfr-scan-input').addEventListener('keypress', function(e) {
                        if (e.key === 'Enter') {
                            e.preventDefault();
                            addMfrScanSerial();
                        }
                    });
                    </script>
                    <% } %>
                </div>

                <%
                    List<ProductItem> importedSerials = (List<ProductItem>) request.getAttribute("importedSerials");
                    if (importedSerials != null && !importedSerials.isEmpty()) {
                %>
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-light py-3 border-0 d-flex justify-content-between align-items-center">
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
                                    <% if (item.getManufacturerSerial() != null) { %>
                                    <div class="text-muted small mt-1" style="font-size: 10px;">NSX: <span class="font-monospace"><%= item.getManufacturerSerial() %></span></div>
                                    <% } %>
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
                                <% if (item.getManufacturerSerial() != null) { %>
                                <div style="font-size: 9px; color: #666; margin-top: 3px;">NSX: <%= item.getManufacturerSerial() %></div>
                                <% } %>
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
