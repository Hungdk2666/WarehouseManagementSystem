<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_ADD_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    java.util.List<model.Warehouse> warehouseList = (java.util.List<model.Warehouse>) request.getAttribute("warehouseList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo yêu cầu trả hàng - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
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
                        <h2 class="page-title">Tạo yêu cầu trả hàng</h2>
                        <p class="page-subtitle">Tạo yêu cầu nhập lại hàng trả từ khách hàng bằng mã Serial</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Hủy
                    </a>
                </div>
 
                <div class="row">
                    <div class="col-12">
                        <form action="<%= request.getContextPath() %>/warehouse/import-request?action=addReturn" method="POST" id="reqForm">
                            
                            <input type="hidden" name="ref_ticket_id" id="refTicketId" value="">

                            
                            <div class="card bg-white mb-4 d-none" id="customerInfoCard">
                                <div class="card-header bg-light py-3 border-0">
                                    <h5 class="mb-0 fw-bold text-success"><i class="bi bi-person-check-fill me-2"></i>Thông tin đối chiếu đơn xuất gốc</h5>
                                </div>
                                <div class="card-body p-4">
                                    <div class="row">
                                        <div class="col-md-6">
                                            <span class="text-muted small d-block">Khách hàng / Đối tác:</span>
                                            <span class="fw-bold text-slate-800" id="infoPartnerName">-</span>
                                        </div>
                                        <div class="col-md-6">
                                            <span class="text-muted small d-block">Phiếu xuất gốc:</span>
                                            <span class="fw-bold text-slate-800" id="infoTicketCode">-</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            
                            <div class="card card-overflow-visible bg-white mb-4" style="overflow: visible;">
                                <div class="card-header bg-warning bg-opacity-10 py-3 border-0">
                                    <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-info-circle-fill me-2"></i>Cấu hình Yêu cầu trả</h5>
                                </div>
                                <div class="card-body p-4">
                                    <% 
                                        String errParam = request.getParameter("error");
                                        if (errParam != null) {
                                            String errMsg = "Đã xảy ra lỗi.";
                                            if ("NoReason".equals(errParam)) errMsg = "Vui lòng nhập lý do trả hàng.";
                                            else if ("NoProducts".equals(errParam) || "NoValidDetails".equals(errParam)) errMsg = "Vui lòng nhập ít nhất một Serial sản phẩm hợp lệ.";
                                            else if ("NoRefTicket".equals(errParam) || "InvalidTicket".equals(errParam)) errMsg = "Đơn xuất gốc liên kết không hợp lệ.";
                                            else if ("Failed".equals(errParam)) errMsg = "Không thể lưu vào cơ sở dữ liệu. Vui lòng kiểm tra lại.";
                                    %>
                                    <div class="alert alert-danger mb-3"><i class="bi bi-exclamation-triangle-fill me-2"></i><%= errMsg %></div>
                                    <% } %>
                                    
                                    <div class="row g-3">
                                        <div class="col-md-6">
                                            <label for="warehouseSelect" class="form-label">Kho nhận hàng trả <span class="text-danger">*</span></label>
                                            <select class="form-select" id="warehouseSelect" name="warehouse_id" required>
                                                <% if (warehouseList != null) { for (model.Warehouse w : warehouseList) { %>
                                                <option value="<%= w.getId() %>" <%= (loggedInUser.getWarehouseId() != null && loggedInUser.getWarehouseId() == w.getId()) ? "selected" : "" %>>
                                                    <%= w.getWarehouseName() %>
                                                </option>
                                                <% } } %>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="returnReason" class="form-label">Lý do trả hàng <span class="text-danger">*</span></label>
                                            <select class="form-select" id="returnReason" name="return_reason" required>
                                                <option value="" disabled selected>-- Chọn lý do --</option>
                                                <option value="CUSTOMER_REJECTION">Khách hàng từ chối nhận hàng</option>
                                                <option value="QUALITY_DEFECT">Sản phẩm lỗi/hỏng hóc</option>
                                                <option value="WRONG_ITEM">Giao sai sản phẩm</option>
                                                <option value="EXCESS_QUANTITY">Giao thừa số lượng</option>
                                                <option value="OTHER">Lý do khác</option>
                                            </select>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="expectedDate" class="form-label">Ngày nhận hàng dự kiến <span class="text-danger">*</span></label>
                                            <input type="date" class="form-control" id="expectedDate" name="expected_date" required>
                                        </div>
                                        <div class="col-md-6">
                                            <label for="requestedCondition" class="form-label">Tình trạng hàng trả về <span class="text-danger">*</span></label>
                                            <select class="form-select" id="requestedCondition" name="requested_condition" required>
                                                <option value="NEW">Hàng mới</option>
                                                <option value="DAMAGED">Hàng hỏng</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>
                            </div>
 
                            
                            <div class="card card-overflow-visible bg-white mb-4" style="overflow: visible;">
                                <div class="card-header bg-warning bg-opacity-10 py-3 border-0">
                                    <h5 class="mb-0 fw-bold text-warning"><i class="bi bi-qr-code-scan me-2"></i>Quét/Nhập mã Serial sản phẩm</h5>
                                </div>
                                <div class="card-body p-4">
                                    <div class="row g-2 align-items-end mb-4 border-bottom pb-4">
                                        <div class="col-md-9">
                                            <label for="serialInput" class="form-label fw-semibold text-muted">Nhập Số Serial của sản phẩm cần trả</label>
                                            <div class="input-group">
                                                <span class="input-group-text"><i class="bi bi-qr-code"></i></span>
                                                <input type="text" class="form-control" id="serialInput" placeholder="Ví dụ: LAP-001..." autocomplete="off">
                                            </div>
                                        </div>
                                        <div class="col-md-3">
                                            <button type="button" class="btn btn-warning w-100" id="addSerialBtn">
                                                <i class="bi bi-plus-circle me-1"></i> Thêm Serial
                                            </button>
                                        </div>
                                    </div>
 
                                    <div class="table-responsive">
                                        <table class="table align-middle text-center" id="itemsTable">
                                            <thead class="table-light">
                                                <tr>
                                                    <th style="width: 5%;">#</th>
                                                    <th>Số Serial</th>
                                                    <th class="text-start ps-4">Tên sản phẩm</th>
                                                    <th>SKU</th>
                                                    <th>Đơn vị</th>
                                                    <th>Phiếu xuất gốc</th>
                                                    <th style="width: 10%;">Xóa</th>
                                                </tr>
                                            </thead>
                                            <tbody id="itemsBody">
                                                <tr id="emptyRow">
                                                    <td colspan="7" class="p-0"><div class="empty-state"><i class="bi bi-inbox"></i><p>Chưa có sản phẩm nào được nhập. Hãy điền số Serial ở trên để bắt đầu.</p></div></td>
                                                </tr>
                                            </tbody>
                                        </table>
                                    </div>
                                </div>
                                <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                                    <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                                    <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Lưu Yêu cầu trả hàng</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
 
            </div>
        </div>
    </div>
 
    <script>
        const serialInput = document.getElementById("serialInput");
        const addSerialBtn = document.getElementById("addSerialBtn");
        const itemsBody = document.getElementById("itemsBody");
        const emptyRow = document.getElementById("emptyRow");
        const reqForm = document.getElementById("reqForm");
        const refTicketIdInput = document.getElementById("refTicketId");
        
        const customerInfoCard = document.getElementById("customerInfoCard");
        const infoPartnerName = document.getElementById("infoPartnerName");
        const infoTicketCode = document.getElementById("infoTicketCode");
 
        let addedSerials = new Set();
 
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


        serialInput.addEventListener("keypress", function(e) {
            if (e.key === "Enter") {
                e.preventDefault();
                addSerialBtn.click();
            }
        });
 
        addSerialBtn.addEventListener("click", function() {
            const serial = serialInput.value.trim();
            if (!serial) { alert("Vui lòng nhập số Serial."); return; }
            if (addedSerials.has(serial)) { alert("Mã Serial này đã được thêm vào danh sách."); return; }
 

            fetch("<%= request.getContextPath() %>/warehouse/import-request?action=lookupSerial&serial=" + encodeURIComponent(serial))
                .then(response => response.json())
                .then(res => {
                    if (!res.success) {
                        alert(res.message || "Mã Serial không hợp lệ hoặc chưa được bán.");
                        return;
                    }
                    
                    const currentLockedTicket = refTicketIdInput.value;
                    if (currentLockedTicket && currentLockedTicket !== String(res.ticketId)) {
                        alert("Mã Serial này thuộc phiếu xuất #" + res.ticketCode + " của khách " + res.partnerName + ".\n" +
                              "Mỗi yêu cầu trả hàng chỉ được phép chọn các Serial thuộc CÙNG MỘT đơn xuất gốc.\n" +
                              "Vui lòng tạo yêu cầu trả hàng riêng biệt cho đơn này.");
                        return;
                    }
                    

                    if (!currentLockedTicket) {
                        refTicketIdInput.value = res.ticketId;
                        infoPartnerName.innerText = res.partnerName ? res.partnerName : "Khách vãng lai";
                        infoTicketCode.innerText = res.ticketCode;
                        customerInfoCard.classList.remove("d-none");
                    }
                    

                    if (emptyRow && emptyRow.style.display !== "none") {
                        emptyRow.style.display = "none";
                    }
                    
                    addedSerials.add(serial);
                    const idx = addedSerials.size;
                    const tr = document.createElement("tr");
                    tr.id = "serial-row-" + serial;
                    tr.innerHTML = 
                        '<td>' + idx + '</td>' +
                        '<td class="fw-bold text-slate-800">' + 
                            '<input type="hidden" name="scanned_serials" value="' + serial + '">' +
                            '<input type="hidden" name="product_id" value="' + res.productId + '">' +
                            serial + 
                        '</td>' +
                        '<td class="text-start ps-4 fw-semibold">' + res.productName + '</td>' +
                        '<td><span class="badge bg-secondary bg-opacity-10 text-secondary">' + res.sku + '</span></td>' +
                        '<td>' + res.unit + '</td>' +
                        '<td class="text-muted small">' + res.ticketCode + '</td>' +
                        '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="removeSerial(\'' + serial + '\')"><i class="bi bi-trash"></i></button></td>';
                    
                    itemsBody.appendChild(tr);
                    serialInput.value = "";
                    serialInput.focus();
                })
                .catch(err => {
                    console.error("Error looking up serial:", err);
                    alert("Không thể kết nối máy chủ để xác thực Serial.");
                });
        });
 
        window.removeSerial = function(serial) {
            const row = document.getElementById("serial-row-" + serial);
            if (row) {
                row.remove();
                addedSerials.delete(serial);
            }
            if (addedSerials.size === 0) {
                refTicketIdInput.value = "";
                customerInfoCard.classList.add("d-none");
                if (emptyRow) emptyRow.style.display = "";
            } else {

                let index = 1;
                itemsBody.querySelectorAll("tr").forEach(tr => {
                    if (tr.id !== "emptyRow" && tr.style.display !== "none") {
                        tr.cells[0].innerText = index++;
                    }
                });
            }
        };
 
        reqForm.addEventListener("submit", function(e) {
            if (addedSerials.size === 0) {
                e.preventDefault();
                alert("Vui lòng nhập ít nhất một Serial sản phẩm trước khi lưu.");
            }
        });
    </script>
</body>
</html>
