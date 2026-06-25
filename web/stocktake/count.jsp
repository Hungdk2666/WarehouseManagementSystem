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
    boolean serialMode = s.isSerialMode();
    List<StocktakeDetail> details = s.getDetails();
    List<StocktakeItem> savedItems = s.getItems();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Đếm kiểm kê - <%= s.getStocktakeCode() %></title>
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

                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h2 class="fw-bold mb-1"><%= s.getStocktakeCode() %></h2>
                        <p class="text-muted small mb-0">
                            Kho: <strong><%= s.getWarehouseName() %></strong> ·
                            Cách đếm: <strong><%= serialMode ? "Scan serial" : "Theo số lượng" %></strong>
                        </p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=detail&id=<%= s.getId() %>" class="btn btn-outline-secondary btn-sm">
                        <i class="bi bi-arrow-left"></i> Quay lại
                    </a>
                </div>

                <% String msg = request.getParameter("msg"); if ("Saved".equals(msg)) { %>
                    <div class="alert alert-success alert-dismissible fade show">
                        <i class="bi bi-check-circle"></i> Đã lưu nháp.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" id="countForm">
                    <input type="hidden" name="action" value="saveCount">
                    <input type="hidden" name="id" value="<%= s.getId() %>">
                    <input type="hidden" name="submit_after_save" id="submitAfterSave" value="0">

                <% if (!serialMode) {  /* ========= QUANTITY MODE ========= */ %>
                    <div class="card shadow-sm border-0 mb-4">
                        <div class="card-header bg-primary bg-opacity-10">
                            <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-input-cursor-text me-2"></i>Nhập số lượng đếm được</h5>
                        </div>
                        <div class="card-body p-0">
                            <table class="table table-sm mb-0 align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th>Sản phẩm</th>
                                        <th>SKU</th>
                                        <th class="text-end">Số sổ sách</th>
                                        <th class="text-end" width="120">Số đếm được</th>
                                        <th class="text-end" width="120">Trong đó hỏng</th>
                                        <th width="140">Lý do</th>
                                        <th>Ghi chú</th>
                                    </tr>
                                </thead>
                                <tbody>
                                <% if (details != null) for (StocktakeDetail d : details) { %>
                                    <tr>
                                        <td>
                                            <%= d.getProductName() %>
                                            <input type="hidden" name="product_id" value="<%= d.getProductId() %>">
                                        </td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= d.getSku() %></span></td>
                                        <td class="text-end"><strong><%= d.getTheoreticalQty() %></strong> <%= d.getUnit() %></td>
                                        <td><input type="number" min="0" class="form-control form-control-sm text-end actual"
                                                   name="actual_<%= d.getProductId() %>" value="<%= d.getActualQty() %>"
                                                   data-theo="<%= d.getTheoreticalQty() %>"></td>
                                        <td><input type="number" min="0" class="form-control form-control-sm text-end"
                                                   name="damaged_<%= d.getProductId() %>" value="<%= d.getDamagedQty() %>"></td>
                                        <td>
                                            <select class="form-select form-select-sm" name="reason_<%= d.getProductId() %>">
                                                <% String[] reasons = {"NONE","LOST","FOUND","DAMAGED","EXPIRED","MISCOUNT","OTHER"};
                                                   String[] labels = {"—","Mất","Thừa","Hỏng","Hết hạn","Đếm nhầm","Khác"};
                                                   for (int i=0; i<reasons.length; i++) { %>
                                                    <option value="<%= reasons[i] %>" <%= reasons[i].equals(d.getVarianceReason()) ? "selected" : "" %>><%= labels[i] %></option>
                                                <% } %>
                                            </select>
                                        </td>
                                        <td><input type="text" class="form-control form-control-sm" name="note_<%= d.getProductId() %>"
                                                   value="<%= d.getNote() == null ? "" : d.getNote() %>" placeholder="..."></td>
                                    </tr>
                                <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                <% } else {  /* ========= SERIAL MODE ========= */ %>
                    <div class="card shadow-sm border-0 mb-3">
                        <div class="card-header bg-info bg-opacity-10">
                            <h5 class="mb-0 fw-bold text-info"><i class="bi bi-upc-scan me-2"></i>Scan từng serial</h5>
                        </div>
                        <div class="card-body">
                            <div class="row g-2 align-items-end">
                                <div class="col-md-6">
                                    <label class="form-label small fw-semibold">Quét serial</label>
                                    <input type="text" id="serialInput" class="form-control" placeholder="Bấm vào ô này rồi quét hoặc nhập serial...">
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label small fw-semibold">Tình trạng vật lý</label>
                                    <select id="scanCondition" class="form-select">
                                        <option value="NEW">Tốt (FOUND)</option>
                                        <option value="DAMAGED">Hỏng (DAMAGED)</option>
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <button type="button" id="markMissing" class="btn btn-outline-warning w-100">
                                        Đánh dấu MISSING
                                    </button>
                                </div>
                            </div>
                            <p class="small text-muted mt-2 mb-0">
                                Serial chưa có trong hệ thống sẽ tự đánh dấu EXTRA. Sau khi đếm xong, các serial của SKU đã có trong phiếu nhưng chưa scan sẽ được đánh dấu MISSING khi bạn bấm "Đánh dấu MISSING".
                            </p>
                        </div>
                    </div>

                    <div class="card shadow-sm border-0 mb-4">
                        <div class="card-header bg-light d-flex justify-content-between">
                            <strong><i class="bi bi-list-ul me-2"></i>Serial đã scan</strong>
                            <span id="itemCount" class="badge bg-primary">0</span>
                        </div>
                        <div class="card-body p-0">
                            <table class="table table-sm mb-0 align-middle">
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
                                        StocktakeItem it = savedItems.get(i); %>
                                    <tr data-serial="<%= it.getSerialNumber() %>">
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
                                                String bclass = "secondary";
                                                if ("FOUND".equals(it.getScannedStatus())) bclass = "success";
                                                else if ("MISSING".equals(it.getScannedStatus())) bclass = "warning";
                                                else if ("DAMAGED".equals(it.getScannedStatus())) bclass = "danger";
                                                else if ("EXTRA".equals(it.getScannedStatus())) bclass = "info";
                                            %>
                                            <span class="badge bg-<%= bclass %>"><%= it.getScannedStatus() %></span>
                                        </td>
                                        <td><%= it.getNote() == null ? "" : it.getNote() %></td>
                                        <td><button type="button" class="btn btn-sm btn-outline-danger remove-row"><i class="bi bi-trash"></i></button></td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <!-- Danh sách product_id của phiếu để JS biết SKU nào cần check MISSING -->
                    <% if (details != null) for (StocktakeDetail d : details) { %>
                        <input type="hidden" class="phantom-product"
                               data-pid="<%= d.getProductId() %>"
                               data-name="<%= d.getProductName() %>"
                               data-sku="<%= d.getSku() %>">
                    <% } %>
                <% } %>

                    <div class="d-flex gap-2 mb-4">
                        <button type="submit" class="btn btn-outline-primary">
                            <i class="bi bi-save"></i> Lưu nháp
                        </button>
                        <button type="button" class="btn btn-success" id="btnSubmit">
                            <i class="bi bi-send"></i> Lưu và gửi duyệt
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        const CTX = "<%= request.getContextPath() %>";
        const WAREHOUSE_ID = <%= s.getWarehouseId() %>;

        document.getElementById("btnSubmit").addEventListener("click", function() {
            if (!confirm("Gửi phiếu lên duyệt? Sau khi gửi không sửa được nữa.")) return;
            document.getElementById("submitAfterSave").value = "1";
            document.getElementById("countForm").submit();
        });

    <% if (serialMode) { %>
        const scannedBody = document.getElementById("scannedBody");
        const itemCount = document.getElementById("itemCount");
        const serialInput = document.getElementById("serialInput");
        const scanCondition = document.getElementById("scanCondition");

        function updateCount() {
            itemCount.innerText = scannedBody.querySelectorAll("tr").length;
        }
        updateCount();

        function getExistingSerials() {
            const set = new Set();
            scannedBody.querySelectorAll("tr").forEach(tr => set.add(tr.dataset.serial));
            return set;
        }

        function addRow(serial, productId, productName, sku, status, condition, note, productItemId) {
            const existing = getExistingSerials();
            if (existing.has(serial)) {
                alert("Serial " + serial + " đã có trong danh sách.");
                return;
            }
            const idx = scannedBody.querySelectorAll("tr").length + 1;
            const tr = document.createElement("tr");
            tr.dataset.serial = serial;
            const bclass = status === "FOUND" ? "success" : status === "MISSING" ? "warning"
                         : status === "DAMAGED" ? "danger" : status === "EXTRA" ? "info" : "secondary";
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
                '<td><span class="badge bg-' + bclass + '">' + status + '</span></td>' +
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
                        // serial chưa có → EXTRA, hỏi product
                        const pid = prompt("Serial " + serial + " chưa có trong hệ thống.\nNhập product_id của sản phẩm tương ứng (EXTRA):");
                        if (pid && /^\d+$/.test(pid)) {
                            addRow(serial, parseInt(pid), "(sản phẩm mới)", "?", "EXTRA", "NEW", res.message || "", null);
                        }
                    }
                    serialInput.value = "";
                    serialInput.focus();
                })
                .catch(err => { console.error(err); alert("Lỗi kết nối"); });
        });

        document.getElementById("markMissing").addEventListener("click", function() {
            if (!confirm("Đánh dấu MISSING cho tất cả serial CHƯA scan trong các SKU của phiếu này?\nBước này cần internet để truy DB serial. Tính năng đơn giản: bạn cần biết những serial bị mất rồi nhập tay.")) return;
            const serial = prompt("Nhập serial bị mất (MISSING):");
            if (!serial) return;
            fetch(CTX + "/warehouse/stocktake?action=lookupSerial&serial=" + encodeURIComponent(serial.trim()) + "&warehouse_id=" + WAREHOUSE_ID)
                .then(r => r.json())
                .then(res => {
                    if (res.success) {
                        addRow(serial.trim(), res.productId, res.productName, res.sku, "MISSING", "", "Không tìm thấy ngoài kho", res.productItemId);
                    } else {
                        alert("Serial không tồn tại — không thể đánh dấu MISSING.");
                    }
                });
        });
    <% } %>
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
