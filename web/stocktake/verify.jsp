<%@page import="model.Stocktake"%>
<%@page import="model.StocktakeDetail"%>
<%@page import="model.StocktakeItem"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("STOCKTAKE_COUNT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Stocktake s = (Stocktake) request.getAttribute("stocktake");
    if (s == null) { response.sendRedirect(request.getContextPath() + "/warehouse/stocktake"); return; }
    List<StocktakeDetail> details = s.getDetails();
    List<StocktakeItem> savedItems = s.getItems();
    List<Integer> varianceProductIds = (List<Integer>) request.getAttribute("varianceProductIds");
    List<Integer> verificationProductIds = (List<Integer>) request.getAttribute("verificationProductIds");
    List<Integer> damagedOnlyProductIds = (List<Integer>) request.getAttribute("damagedOnlyProductIds");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Xác minh chênh lệch - <%= s.getStocktakeCode() %></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="page-header">
                    <div>
                        <h2 class="page-title"><%= s.getStocktakeCode() %> <span class="status-chip chip-warning ms-2">Xác minh chênh lệch</span></h2>
                        <p class="page-subtitle">
                            Kho: <strong><%= s.getWarehouseName() %></strong> ·
                            Quét serial cho sản phẩm thiếu/thừa hoặc có hàng hỏng
                        </p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=count&id=<%= s.getId() %>" class="btn btn-outline-secondary btn-sm">
                            <i class="bi bi-arrow-left"></i> Quay lại đếm
                        </a>
                    </div>
                </div>

                <% String msg = request.getParameter("msg");
                   String error = request.getParameter("error");
                   if ("Saved".equals(msg)) { %>
                    <div class="alert alert-success alert-dismissible fade show">
                        <i class="bi bi-check-circle"></i> Đã lưu kết quả xác minh.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } else if ("VerificationRequired".equals(msg)) { %>
                    <div class="alert alert-warning alert-dismissible fade show">
                        <i class="bi bi-exclamation-triangle"></i> Phiếu có sản phẩm thiếu/thừa hoặc có hàng hỏng — cần quét serial xác minh trước khi gửi duyệt.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } else if ("DamagedOnlyRequiresDamagedSerials".equals(error)) { %>
                    <div class="alert alert-danger alert-dismissible fade show">
                        <i class="bi bi-exclamation-circle"></i> SKU chỉ hỏng chỉ được quét serial với tình trạng "Hàng hỏng".
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                
                <div class="card mb-3">
                    <div class="card-header bg-warning bg-opacity-10 py-3">
                        <span class="fw-bold text-slate-800"><i class="bi bi-exclamation-triangle me-2 text-warning"></i>Sản phẩm cần xác minh</span>
                    </div>
                    <div class="card-body p-0">
                        <table class="table table-sm table-hover mb-0 align-middle">
                            <thead class="table-light">
                                <tr>
                                    <th>Sản phẩm</th>
                                    <th>SKU</th>
                                    <th class="text-end">Số sổ sách</th>
                                    <th class="text-end">Số đếm tay</th>
                                    <th class="text-end">Hàng hỏng</th>
                                    <th class="text-end">Chênh lệch</th>
                                    <th>Loại xác minh</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% if (details != null) for (StocktakeDetail d : details) {
                                int diff = d.getVariance();
                                boolean damagedOnly = diff == 0 && d.getDamagedQty() > 0;
                                if (diff == 0 && d.getDamagedQty() <= 0) continue;
                                String diffCls = diff < 0 ? "text-danger" : "text-warning";
                            %>
                                <tr>
                                    <td><%= d.getProductName() %></td>
                                    <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                    <td class="text-end"><%= d.getTheoreticalQty() %></td>
                                    <td class="text-end"><%= d.getActualQty() %></td>
                                    <td class="text-end text-danger"><%= d.getDamagedQty() %></td>
                                    <td class="text-end <%= diffCls %>"><strong><%= diff > 0 ? "+" + diff : diff %></strong></td>
                                    <td>
                                        <% if (damagedOnly) { %>
                                            <span class="status-chip chip-danger">Hỏng</span>
                                        <% } else { %>
                                            <span class="status-chip chip-warning">Toàn bộ</span>
                                        <% } %>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                
                <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" id="verifyForm">
                    <input type="hidden" name="action" value="saveVerification">
                    <input type="hidden" name="id" value="<%= s.getId() %>">
                    <input type="hidden" name="submit_after_save" id="submitAfterSave" value="0">

                    <div class="card mb-3">
                        <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                            <span class="fw-bold text-slate-800"><i class="bi bi-upc-scan me-2 text-primary"></i>Quét serial xác minh</span>
                        </div>
                        <div class="card-body">
                            <div class="row g-2 align-items-end">
                                <div class="col-md-6">
                                    <label class="form-label small fw-semibold">Quét serial</label>
                                    <input type="text" id="serialInput" class="form-control" placeholder="Quét serial cần xác minh..." autofocus>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label small fw-semibold">Tình trạng vật lý</label>
                                    <select id="scanCondition" class="form-select">
                                        <option value="NEW">Tốt</option>
                                        <option value="DAMAGED">Hàng hỏng</option>
                                    </select>
                                </div>
                            </div>
                            <p class="small text-muted mt-2 mb-0">
                                SKU thiếu/thừa: quét hết serial, serial trong sổ nhưng không quét sẽ tự động được đánh dấu thiếu khi lưu.
                                SKU chỉ hỏng: chỉ quét serial hỏng và chọn tình trạng "Hàng hỏng".
                            </p>
                        </div>
                    </div>

                    <div class="card mb-4">
                        <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                            <span class="fw-bold text-slate-800"><i class="bi bi-list-ul me-2 text-primary"></i>Serial đã quét</span>
                            <span id="itemCount" class="badge bg-primary">0</span>
                        </div>
                        <div class="card-body p-0">
                            <table class="table table-sm table-hover mb-0 align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th>#</th>
                                        <th>Serial</th>
                                        <th>Sản phẩm</th>
                                        <th>Trạng thái</th>
                                        <th>Ghi chú</th>
                                        <th></th>
                                    </tr>
                                </thead>
                                <tbody id="scannedBody">
                                    <% if (savedItems != null) for (int i = 0; i < savedItems.size(); i++) {
                                        StocktakeItem it = savedItems.get(i);
                                        if (!"VERIFY".equals(it.getPhase())) continue;
                                    %>
                                    <tr data-serial="<%= it.getSerialNumber() %>" data-pid="<%= it.getProductId() %>" data-status="<%= it.getScannedStatus() %>">
                                        <td><%= i+1 %></td>
                                        <td>
                                            <strong><%= it.getSerialNumber() %></strong>
                                            <input type="hidden" name="serial_number" value="<%= it.getSerialNumber() %>">
                                            <input type="hidden" name="item_product_id" value="<%= it.getProductId() %>">
                                            <input type="hidden" name="product_item_id" value="<%= it.getProductItemId() == null ? "" : it.getProductItemId() %>">
                                            <input type="hidden" name="scanned_status" value="<%= it.getScannedStatus() %>">
                                            <input type="hidden" name="new_condition" value="<%= it.getNewCondition() == null ? "" : it.getNewCondition() %>">
                                            <input type="hidden" name="item_note" value="<%= it.getNote() == null ? "" : it.getNote() %>">
                                        </td>
                                        <td><%= it.getProductName() %> <span class="badge bg-secondary bg-opacity-10 text-secondary"><%= it.getSku() %></span></td>
                                        <td>
                                            <%
                                                String bclass = "chip-muted";
                                                if ("FOUND".equals(it.getScannedStatus())) bclass = "chip-success";
                                                else if ("MISSING".equals(it.getScannedStatus())) bclass = "chip-warning";
                                                else if ("DAMAGED".equals(it.getScannedStatus())) bclass = "chip-danger";
                                                else if ("EXTRA".equals(it.getScannedStatus())) bclass = "chip-info";
                                            %>
                                            <span class="status-chip <%= bclass %>"><%
                                                if ("FOUND".equals(it.getScannedStatus())) out.print("Tìm thấy");
                                                else if ("MISSING".equals(it.getScannedStatus())) out.print("Thiếu");
                                                else if ("DAMAGED".equals(it.getScannedStatus())) out.print("Hàng hỏng");
                                                else if ("EXTRA".equals(it.getScannedStatus())) out.print("Phát hiện thêm");
                                                else out.print(it.getScannedStatus());
                                            %></span>
                                        </td>
                                        <td><%= it.getNote() == null ? "" : it.getNote() %></td>
                                        <td><button type="button" class="btn btn-sm btn-outline-danger remove-row"><i class="bi bi-trash"></i></button></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="d-flex gap-2 mb-4">
                        <button type="submit" class="btn btn-outline-primary">
                            <i class="bi bi-save"></i> Lưu xác minh
                        </button>
                        <button type="button" class="btn btn-success" id="btnSubmit">
                            <i class="bi bi-send"></i> Lưu và gửi duyệt
                        </button>
                    </div>
                </form>

                
                <% if (details != null) for (StocktakeDetail d : details) {
                    if (d.getVariance() == 0 && d.getDamagedQty() <= 0) continue;
                %>
                    <input type="hidden" class="phantom-product"
                           data-pid="<%= d.getProductId() %>"
                           data-diff="<%= d.getVariance() %>"
                           data-damaged="<%= d.getDamagedQty() %>"
                           data-name="<%= d.getProductName() %>"
                           data-sku="<%= d.getSku() %>">
                <% } %>
            </div>
        </div>
    </div>

    <script>
        const CTX = "<%= request.getContextPath() %>";
        const WAREHOUSE_ID = <%= s.getWarehouseId() %>;
        const VARIANCE_PIDS = new Set([<% if (varianceProductIds != null) { for (int i = 0; i < varianceProductIds.size(); i++) { if (i > 0) out.print(","); out.print(varianceProductIds.get(i)); } } %>]);
        const VERIFICATION_PIDS = new Set([<% if (verificationProductIds != null) { for (int i = 0; i < verificationProductIds.size(); i++) { if (i > 0) out.print(","); out.print(verificationProductIds.get(i)); } } %>]);
        const DAMAGED_ONLY_PIDS = new Set([<% if (damagedOnlyProductIds != null) { for (int i = 0; i < damagedOnlyProductIds.size(); i++) { if (i > 0) out.print(","); out.print(damagedOnlyProductIds.get(i)); } } %>]);
        const DAMAGED_TARGETS = {};
        document.querySelectorAll(".phantom-product").forEach(function(el) {
            const pid = parseInt(el.dataset.pid, 10);
            if (DAMAGED_ONLY_PIDS.has(pid)) {
                DAMAGED_TARGETS[pid] = parseInt(el.dataset.damaged || "0", 10);
            }
        });

        const scannedBody = document.getElementById("scannedBody");
        const itemCount = document.getElementById("itemCount");
        const serialInput = document.getElementById("serialInput");
        const scanCondition = document.getElementById("scanCondition");

        document.getElementById("btnSubmit").addEventListener("click", function() {
            let message = "Lưu kết quả xác minh và gửi phiếu lên duyệt?\nSKU thiếu/thừa sẽ tự động đánh dấu thiếu cho serial trong sổ nhưng chưa quét. SKU chỉ hỏng sẽ không auto-fill thiếu.";
            const mismatch = getDamagedOnlyMismatchMessage();
            if (mismatch) {
                message += "\n\nCảnh báo:\n" + mismatch + "\nBạn vẫn muốn gửi duyệt?";
            }
            if (!confirm(message)) return;
            document.getElementById("submitAfterSave").value = "1";
            document.getElementById("verifyForm").submit();
        });

        function updateCount() {
            itemCount.innerText = scannedBody.querySelectorAll("tr").length;
        }
        updateCount();

        function statusLabel(s) {
            var map = {FOUND:"Tìm thấy",MISSING:"Thiếu",DAMAGED:"Hàng hỏng",EXTRA:"Phát hiện thêm"};
            return map[s] || s;
        }

        function getExistingSerials() {
            const set = new Set();
            scannedBody.querySelectorAll("tr").forEach(tr => set.add(tr.dataset.serial));
            return set;
        }

        function getDamagedOnlyMismatchMessage() {
            const damagedCounts = {};
            scannedBody.querySelectorAll("tr").forEach(tr => {
                const pid = parseInt(tr.dataset.pid || "0", 10);
                if (!DAMAGED_ONLY_PIDS.has(pid)) return;
                if (tr.dataset.status === "DAMAGED") {
                    damagedCounts[pid] = (damagedCounts[pid] || 0) + 1;
                }
            });
            const messages = [];
            Object.keys(DAMAGED_TARGETS).forEach(pid => {
                const expected = DAMAGED_TARGETS[pid];
                const actual = damagedCounts[pid] || 0;
                if (actual !== expected) {
                    messages.push("Sản phẩm #" + pid + ": đã quét " + actual + " serial hỏng, số đã báo là " + expected + ".");
                }
            });
            return messages.join("\n");
        }

        function addRow(serial, productId, productName, sku, status, condition, note, productItemId) {
            const existing = getExistingSerials();
            if (existing.has(serial)) {
                alert("Serial " + serial + " đã có trong danh sách.");
                return;
            }
            const isVariance = VARIANCE_PIDS.has(productId);
            const isDamagedOnly = DAMAGED_ONLY_PIDS.has(productId);
            if (!VERIFICATION_PIDS.has(productId)) {
                alert("Serial " + serial + " thuộc sản phẩm không cần xác minh.");
                return;
            }
            if (isDamagedOnly && status !== "DAMAGED") {
                alert("SKU này chỉ cần xác minh hàng hỏng. Hãy chọn tình trạng 'Hàng hỏng' và quét serial hỏng.");
                return;
            }
            if (!isVariance && (status === "MISSING" || status === "EXTRA")) {
                alert("SKU chỉ hỏng không được đánh dấu thiếu hoặc phát hiện thêm.");
                return;
            }
            const idx = scannedBody.querySelectorAll("tr").length + 1;
            const tr = document.createElement("tr");
            tr.dataset.serial = serial;
            tr.dataset.pid = productId;
            tr.dataset.status = status;
            const bclass = status === "FOUND" ? "chip-success" : status === "MISSING" ? "chip-warning"
                         : status === "DAMAGED" ? "chip-danger" : status === "EXTRA" ? "chip-info" : "chip-muted";
            tr.innerHTML =
                '<td>' + idx + '</td>' +
                '<td><strong>' + serial + '</strong>' +
                    '<input type="hidden" name="serial_number" value="' + serial + '">' +
                    '<input type="hidden" name="item_product_id" value="' + productId + '">' +
                    '<input type="hidden" name="product_item_id" value="' + (productItemId == null ? "" : productItemId) + '">' +
                    '<input type="hidden" name="scanned_status" value="' + status + '">' +
                    '<input type="hidden" name="new_condition" value="' + (condition || "") + '">' +
                    '<input type="hidden" name="item_note" value="' + (note || "") + '">' +
                '</td>' +
                '<td>' + productName + ' <span class="badge bg-secondary bg-opacity-10 text-secondary">' + sku + '</span></td>' +
                '<td><span class="status-chip ' + bclass + '">' + statusLabel(status) + '</span></td>' +
                '<td>' + (note || "") + '</td>' +
                '<td><button type="button" class="btn btn-sm btn-outline-danger remove-row"><i class="bi bi-trash"></i></button></td>';
            scannedBody.appendChild(tr);
            updateCount();
        }

        scannedBody.addEventListener("click", function(e) {
            const btn = e.target.closest(".remove-row");
            if (btn) {
                btn.closest("tr").remove();
                updateCount();
            }
        });

        serialInput.addEventListener("keydown", function(e) {
            if (e.key !== "Enter") return;
            e.preventDefault();
            const serial = serialInput.value.trim();
            if (!serial) return;

            fetch(CTX + "/warehouse/stocktake?action=lookupSerial&serial=" + encodeURIComponent(serial) + "&warehouse_id=" + WAREHOUSE_ID)
                .then(r => r.json())
                .then(res => {
                    if (res.success) {
                        const cond = scanCondition.value;
                        const status = cond === "DAMAGED" ? "DAMAGED" : "FOUND";
                        addRow(serial, res.productId, res.productName, res.sku, status, cond, "", res.productItemId);
                    } else {
                        const pid = prompt("Serial " + serial + " chưa có trong hệ thống.\nNhập ID sản phẩm tương ứng:");
                        if (pid && /^\d+$/.test(pid)) {
                            addRow(serial, parseInt(pid), "Sản phẩm mới", "?", "EXTRA", "NEW", res.message || "", null);
                        }
                    }
                    serialInput.value = "";
                    serialInput.focus();
                })
                .catch(err => { console.error(err); alert("Lỗi kết nối"); });
        });

    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
