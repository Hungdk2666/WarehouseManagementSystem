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

                <div class="page-header">
                    <div>
                        <h2 class="page-title"><%= s.getStocktakeCode() %></h2>
                        <p class="page-subtitle">
                            Kho: <strong><%= s.getWarehouseName() %></strong> ·
                            Hình thức kiểm: <strong><%= serialMode ? "Quét mã serial" : "Theo số lượng" %></strong>
                        </p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=detail&id=<%= s.getId() %>" class="btn btn-outline-secondary btn-sm">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                    </div>
                </div>

                <% String msg = request.getParameter("msg"); if ("Saved".equals(msg)) { %>
                    <div class="alert alert-success alert-dismissible fade show">
                        <i class="bi bi-check-circle"></i> Đã lưu nháp.
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                <% } %>

                <% if (s.isQuantityMode() && s.isVerificationCompleted()) { %>
                    <div class="alert alert-success">
                        <i class="bi bi-patch-check"></i> Đã xác minh serial cho các sản phẩm thiếu/thừa hoặc có hàng hỏng.
                        Người xác minh: <strong><%= s.getVerifiedByFullName() %></strong> · <%= s.getVerifiedAt() %>
                        — <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=verify&id=<%= s.getId() %>" class="alert-link">Xem / quét lại</a>
                    </div>
                <% } else if (s.isQuantityMode() && s.isVerificationRequired()) { %>
                    <div class="alert alert-warning">
                        <i class="bi bi-exclamation-triangle"></i> Có sản phẩm thiếu/thừa hoặc có hàng hỏng — cần
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=verify&id=<%= s.getId() %>" class="alert-link fw-bold">quét serial xác minh</a>
                        trước khi gửi duyệt.
                    </div>
                <% } %>

                <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST" id="countForm">
                    <input type="hidden" name="action" value="saveCount">
                    <input type="hidden" name="id" value="<%= s.getId() %>">
                    <input type="hidden" name="submit_after_save" id="submitAfterSave" value="0">

                <% if (!serialMode) { %>
                    <div class="card mb-4">
                        <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                            <span class="fw-bold text-slate-800"><i class="bi bi-input-cursor-text me-2 text-primary"></i>Nhập số lượng đếm được</span>
                        </div>
                        <div class="card-body p-0">
                            <div class="table-responsive">
                            <table class="table table-sm table-hover mb-0 align-middle editable-table" style="min-width: 1250px;">
                                <colgroup>
                                    <col style="width:18%">
                                    <col style="width:10%">
                                    <col style="width:16%">
                                    <col style="width:8%">
                                    <col style="width:8%">
                                    <col style="width:8%">
                                    <col style="width:10%">
                                    <col style="width:11%">
                                    <col style="width:11%">
                                </colgroup>
                                <thead class="table-light">
                                    <tr>
                                        <th>Sản phẩm</th>
                                        <th>SKU</th>
                                        <th class="text-end">Lý thuyết</th>
                                        <th class="text-end" width="105">Thực tế mới</th>
                                        <th class="text-end" width="105">Thực tế cũ</th>
                                        <th class="text-end" width="105">Thực tế hỏng</th>
                                        <th class="text-end" width="105">Tổng thực tế</th>
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
                                        <td class="text-end">
                                            <strong><%= d.getTheoreticalQty() %></strong> <%= d.getUnit() %>
                                            <div class="small text-muted mt-1">Mới <%= d.getTheoreticalNewQty() %> · Cũ <%= d.getTheoreticalUsedQty() %> · Hỏng <%= d.getTheoreticalDamagedQty() %></div>
                                        </td>
                                        <td><input type="number" min="0" class="form-control form-control-sm text-end condition-actual"
                                                   name="actual_new_<%= d.getProductId() %>" value="<%= d.getActualNewQty() %>" data-pid="<%= d.getProductId() %>"></td>
                                        <td><input type="number" min="0" class="form-control form-control-sm text-end condition-actual"
                                                   name="actual_used_<%= d.getProductId() %>" value="<%= d.getActualUsedQty() %>" data-pid="<%= d.getProductId() %>"></td>
                                        <td><input type="number" min="0" class="form-control form-control-sm text-end condition-actual"
                                                   name="actual_damaged_<%= d.getProductId() %>" value="<%= d.getActualDamagedQty() %>" data-pid="<%= d.getProductId() %>"></td>
                                        <td class="text-end"><strong class="actual-total" data-pid="<%= d.getProductId() %>"><%= d.getActualQty() %></strong> <%= d.getUnit() %></td>
                                        <td>
                                            <select class="form-select form-select-sm" name="reason_<%= d.getProductId() %>">
                                                <% String[] reasons = {"NONE","LOST","FOUND","DAMAGED","EXPIRED","MISCOUNT","OTHER"};
                                                   String[] labels = {"—","Thất thoát","Thừa","Hàng hỏng","Hết hạn","Đếm nhầm","Khác"};
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
                    </div>
                <% } else { %>
                    <div class="card mb-3">
                        <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                            <span class="fw-bold text-slate-800"><i class="bi bi-upc-scan me-2 text-primary"></i>Quét từng serial</span>
                        </div>
                        <div class="card-body">
                            <div class="row g-2 align-items-end">
                                <div class="col-md-6">
                                    <label class="form-label small fw-semibold">Quét serial</label>
                                    <input type="text" id="serialInput" class="form-control" placeholder="Bấm vào ô này rồi quét hoặc nhập serial...">
                                    <div class="form-text">WMS serial / manufacturer serial</div>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label small fw-semibold">Tình trạng vật lý</label>
                                    <select id="scanCondition" class="form-select">
                                        <option value="NEW">Hàng mới</option>
                                        <option value="USED">Hàng cũ</option>
                                        <option value="DAMAGED">Hàng hỏng</option>
                                    </select>
                                </div>
                            </div>
                            <p class="small text-muted mt-2 mb-0">
                                Serial trong sổ nhưng không quét thấy sẽ được đánh dấu là "Thiếu" và chuyển thành "Mất" khi duyệt, kể cả hàng hỏng. Hàng hỏng còn trong kho bắt buộc phải quét serial.
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

        function refreshConditionTotals() {
            document.querySelectorAll(".actual-total").forEach(function(total) {
                var pid = total.dataset.pid;
                var sum = 0;
                document.querySelectorAll('.condition-actual[data-pid="' + pid + '"]').forEach(function(input) {
                    sum += Math.max(0, parseInt(input.value || "0", 10) || 0);
                });
                total.textContent = sum;
            });
        }
        document.querySelectorAll(".condition-actual").forEach(function(input) {
            input.addEventListener("input", refreshConditionTotals);
        });
        refreshConditionTotals();
        document.getElementById("btnSubmit").addEventListener("click", function() {
        <% if (!serialMode) { %>

            if (!confirm("Lưu và gửi duyệt? Nếu có sản phẩm thiếu/thừa hoặc có hàng hỏng, bạn sẽ cần quét serial xác minh trước.")) return;
        <% } else { %>
            if (!confirm("Gửi phiếu lên duyệt? Sau khi gửi không sửa được nữa.")) return;
        <% } %>
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

        function statusLabel(s) {
            var map = {FOUND:"Tìm thấy",MISSING:"Thiếu",DAMAGED:"Hàng hỏng",EXTRA:"Phát hiện thêm"};
            return map[s] || s;
        }

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
                        const canonicalSerial = res.serialNumber || serial;
                        const lookupNote = res.manufacturerSerial && canonicalSerial.toLowerCase() !== serial.toLowerCase()
                                ? "Manufacturer serial: " + res.manufacturerSerial : "";
                        addRow(canonicalSerial, res.productId, res.productName, res.sku, status, cond, lookupNote, res.productItemId);
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

    <% } %>
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
