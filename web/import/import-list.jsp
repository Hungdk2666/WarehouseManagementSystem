<%@page import="model.Ticket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page import="model.Warehouse"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_VIEW_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Ticket> ticketList = (List<Ticket>) request.getAttribute("ticketList");
    List<Ticket> incomingTransfers = (List<Ticket>) request.getAttribute("incomingTransfers");
    boolean canAdd = loggedInUser.hasPermission("TICKET_ADD_IN");
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_IN");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_IN");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Phiếu nhập kho - WMS</title>
    
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
                <jsp:include page="/includes/frozen-banner.jsp" />

                <div class="page-header">
                    <div>
                        <h2 class="page-title">Phiếu nhập kho</h2>
                        <p class="page-subtitle">Ghi nhận và xác nhận hàng hóa thực tế nhập kho</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (canAdd) { %>
                        <a href="import-ticket?action=add" class="btn btn-primary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Tạo Phiếu nhập kho
                        </a>
                        <% } %>
                    </div>
                </div>

                <% if (incomingTransfers != null && !incomingTransfers.isEmpty()) { %>
                <div class="card mb-4" style="border-left: 4px solid #f59e0b !important;">
                    <div class="card-header bg-warning bg-opacity-10 py-3 d-flex align-items-center gap-2">
                        <i class="bi bi-truck fs-5 text-warning"></i>
                        <span class="fw-bold text-warning">Hàng chuyển kho chờ nhận</span>
                        <span class="badge bg-warning text-dark ms-2"><%= incomingTransfers.size() %> phiếu</span>
                        <span class="ms-auto text-muted small">Các lô hàng đang trên đường đến kho của bạn — tạo phiếu nhập khi đã nhận thực tế.</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.88rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.72rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th>Mã phiếu xuất</th>
                                        <th>Yêu cầu nhập liên kết</th>
                                        <th>Kho nguồn</th>
                                        <th>Thủ kho xuất</th>
                                        <th>Ngày xuất</th>
                                        <% if (canAdd && canConfirm) { %><th>Thao tác</th><% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Ticket transfer : incomingTransfers) { %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= transfer.getTicketCode() %></td>
                                        <td class="fw-semibold text-primary">
                                            <% if (transfer.getLinkedInRequestId() != null) { %>
                                            <a href="<%= request.getContextPath() %>/warehouse/import-request?action=detail&id=<%= transfer.getLinkedInRequestId() %>" class="text-decoration-none">
                                                #<%= transfer.getLinkedInRequestCode() %>
                                            </a>
                                            <% } else { %>-<% } %>
                                        </td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><i class="bi bi-building me-1"></i><%= transfer.getWarehouseName() != null ? transfer.getWarehouseName() : "-" %></span></td>
                                        <td><%= transfer.getKeeperFullName() %></td>
                                        <td class="text-muted small text-nowrap"><%= transfer.getConfirmedAt() != null ? transfer.getConfirmedAt().toString().substring(0, 16) : "-" %></td>
                                        <% if (canAdd && canConfirm) { %>
                                        <td>
                                            <a href="<%= request.getContextPath() %>/warehouse/import-ticket?action=add&request_id=<%= transfer.getLinkedInRequestId() %>" class="btn btn-sm btn-warning py-1 px-2">
                                                <i class="bi bi-box-arrow-in-down"></i> Tạo Phiếu nhập
                                            </a>
                                        </td>
                                        <% } %>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <% } %>


                <div class="card card-overflow-visible mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-12 col-md-3">
                                <label for="importSearch" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" id="importSearch" class="form-control form-control-sm" placeholder="Mã phiếu, yêu cầu, thủ kho...">
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="startDateFilter" class="form-label small fw-semibold mb-1">Từ ngày</label>
                                <input type="date" id="startDateFilter" class="form-control form-control-sm">
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="endDateFilter" class="form-label small fw-semibold mb-1">Đến ngày</label>
                                <input type="date" id="endDateFilter" class="form-control form-control-sm">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Trạng thái</label>
                                <div class="dropdown">
                                    <button type="button" id="statusDropdownBtn" class="btn btn-outline-secondary btn-sm dropdown-toggle w-100 text-start fw-normal justify-content-between"
                                            data-bs-toggle="dropdown" data-bs-auto-close="outside" style="background:#fff; font-size:0.875rem;">
                                        <span id="statusLabel">-- Tất cả --</span>
                                    </button>
                                    <ul class="dropdown-menu p-2 shadow-sm" id="statusDropdownMenu" style="min-width:170px;">
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="BẢN NHÁP"> Bản nháp</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="ĐÃ XÁC NHẬN"> Đã xác nhận</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="ĐÃ HỦY"> Đã hủy</label></li>
                                        <li><hr class="dropdown-divider my-1"></li>
                                        <li><button type="button" id="clearStatusBtn" class="btn btn-link btn-sm w-100 text-muted text-decoration-none py-1" style="font-size:0.8rem;"><i class="bi bi-x-circle me-1"></i>Xóa chọn</button></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="warehouseFilter" class="form-label small fw-semibold mb-1">Kho nhập</label>
                                <select id="warehouseFilter" class="form-select form-select-sm">
                                    <option value="">-- Tất cả kho --</option>
                                </select>
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="keeperFilter" class="form-label small fw-semibold mb-1">Thủ kho</label>
                                <input type="text" id="keeperFilter" list="keeperDatalist" class="form-control form-control-sm" placeholder="Nhập hoặc chọn...">
                                <datalist id="keeperDatalist"></datalist>
                            </div>
                            <div class="col-6 col-md-auto ms-md-auto d-flex gap-2">
                                <button type="button" id="filterBtn" class="btn btn-primary btn-sm px-3">
                                    <i class="bi bi-funnel-fill me-1"></i>Lọc
                                </button>
                                <button type="button" id="resetBtn" class="btn btn-outline-secondary btn-sm px-3" title="Đặt lại bộ lọc">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>Đặt lại
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card mb-4">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-box-arrow-in-down me-2 text-primary"></i>Sổ đăng ký Phiếu nhập kho</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="grnTable" class="table table-hover align-middle text-center mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Mã phiếu</th>
                                        <th>Yêu cầu liên kết</th>
                                        <th>Nhà cung cấp</th>
                                        <th>Kho nhập</th>
                                        <th>Trạng thái</th>
                                        <th>Thủ kho</th>
                                        <th>Ngày tạo</th>
                                        <th>Xác nhận bởi</th>
                                        <th>Thời gian xác nhận</th>
                                        <th>Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (ticketList != null && !ticketList.isEmpty()) {
                                            for (Ticket t : ticketList) {
                                                String statusBadge = "chip-muted";
                                                if ("DRAFT".equals(t.getStatus())) statusBadge = "chip-muted";
                                                else if ("CONFIRMED".equals(t.getStatus())) statusBadge = "chip-success";
                                                else if ("CANCELLED".equals(t.getStatus())) statusBadge = "chip-muted";
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= t.getTicketCode() %></td>
                                        <td class="fw-bold text-slate-800">#<%= t.getRequestCode() %></td>
                                        <td class="text-start ps-3 fw-semibold"><%= t.getPartnerName() != null ? t.getPartnerName() : "-" %></td>
                                        <td><span class="badge bg-light text-primary"><i class="bi bi-building me-1"></i><%= t.getWarehouseName() != null ? t.getWarehouseName() : "-" %></span></td>
                                        <td>
                                            <%
                                                String displayTStatus = t.getStatus();
                                                if ("CONFIRMED".equals(t.getStatus())) displayTStatus = "ĐÃ XÁC NHẬN";
                                                else if ("DRAFT".equals(t.getStatus())) displayTStatus = "BẢN NHÁP";
                                                else if ("CANCELLED".equals(t.getStatus())) displayTStatus = "ĐÃ HỦY";
                                            %>
                                            <span class="status-chip <%= statusBadge %>"><%= displayTStatus %></span>
                                        </td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td class="text-muted small text-nowrap"><%= t.getCreatedAt() %></td>
                                        <td><%= t.getConfirmedByFullName() != null ? t.getConfirmedByFullName() : "-" %></td>
                                        <td class="text-muted small text-nowrap"><%= t.getConfirmedAt() != null ? t.getConfirmedAt() : "-" %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="import-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết" aria-label="Xem chi tiết phiếu nhập">
                                                    <i class="bi bi-eye" aria-hidden="true"></i>
                                                </a>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="10" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Không tìm thấy Phiếu nhập kho nào.</p>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                                    <label class="text-muted small mb-0 flex-shrink-0">Hiển thị</label>
                                    <select id="entriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;">
                                        <option value="10" selected>10</option>
                                        <option value="25">25</option>
                                        <option value="100">100</option>
                                    </select>
                                    <span class="text-muted small">bản ghi</span>
                                </div>
                                <div id="paginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto">
                                </div>
                    </div>
                </div>

            </div>
        </div>
    </div>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const userWarehouseName = '<%= loggedInUser.getWarehouseName() != null ? loggedInUser.getWarehouseName().replace("'", "\\'") : "" %>';

        document.addEventListener("DOMContentLoaded", function() {
            initPaginationAndFilter("grnTable", "paginationContainer", "entriesPerPage", "importSearch", "startDateFilter", "endDateFilter", "statusFilter", "warehouseFilter", "keeperFilter");
        });


        function initPaginationAndFilter(tableId, containerId, selectId, searchInputId, startDateFilterId, endDateFilterId, statusFilterId, warehouseFilterId, keeperFilterId) {
            const table = document.getElementById(tableId);
            if (!table) return;
            const tbody = table.querySelector("tbody");
            if (!tbody) return;

            const allRows = Array.from(tbody.querySelectorAll("tr"));
            if (allRows.length === 1 && allRows[0].querySelector("td[colspan]")) {
                return;
            }

            const container = document.getElementById(containerId);
            const select = document.getElementById(selectId);
            const searchInput = document.getElementById(searchInputId);
            const startDateFilter = document.getElementById(startDateFilterId);
            const endDateFilter = document.getElementById(endDateFilterId);
            if (startDateFilter && endDateFilter) {
                startDateFilter.addEventListener("change", () => {
                    endDateFilter.min = startDateFilter.value;
                    if (endDateFilter.value && endDateFilter.value < startDateFilter.value) endDateFilter.value = startDateFilter.value;
                });
                endDateFilter.addEventListener("change", () => {
                    startDateFilter.max = endDateFilter.value;
                    if (startDateFilter.value && startDateFilter.value > endDateFilter.value) startDateFilter.value = endDateFilter.value;
                });
            }
            const warehouseFilter = document.getElementById(warehouseFilterId);
            const keeperFilter = document.getElementById(keeperFilterId);
            if (!container || !select) return;


            function getSelectedStatuses() {
                return Array.from(document.querySelectorAll('#statusDropdownMenu .status-cb:checked')).map(cb => cb.value);
            }
            function updateStatusLabel() {
                const checked = document.querySelectorAll('#statusDropdownMenu .status-cb:checked');
                const label = document.getElementById('statusLabel');
                if (checked.length === 0) label.textContent = '-- Tất cả --';
                else if (checked.length === 1) label.textContent = checked[0].closest('label').textContent.trim();
                else label.textContent = checked.length + ' đã chọn';
            }
            document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(cb => cb.addEventListener('change', updateStatusLabel));
            document.getElementById('clearStatusBtn').addEventListener('click', e => {
                e.stopPropagation();
                document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(cb => cb.checked = false);
                updateStatusLabel();
            });
            new bootstrap.Dropdown(document.getElementById('statusDropdownBtn'), { popperConfig: { strategy: 'fixed' } });

            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            let filteredRows = allRows;


            if (warehouseFilter) {
                const warehouses = new Set();
                allRows.forEach(row => {
                    if (row.cells.length > 3) warehouses.add(row.cells[3].textContent.trim());
                });
                warehouses.forEach(w => {
                    const opt = document.createElement("option");
                    opt.value = w;
                    opt.textContent = w;
                    warehouseFilter.appendChild(opt);
                });
            }


            if (keeperFilter) {
                const keepers = new Set();
                allRows.forEach(row => {
                    if (row.cells.length > 5) {
                        const kText = row.cells[5].textContent.trim();
                        if (kText) keepers.add(kText);
                    }
                });
                const datalist = document.getElementById("keeperDatalist");
                if (datalist) {
                    keepers.forEach(k => {
                        const opt = document.createElement("option");
                        opt.value = k;
                        datalist.appendChild(opt);
                    });
                }
            }

            function filterAndPaginate() {
                const searchQuery = searchInput ? searchInput.value.toLowerCase().trim() : "";
                const selectedStartDate = startDateFilter ? startDateFilter.value : "";
                const selectedEndDate = endDateFilter ? endDateFilter.value : "";
                const selectedStatuses = getSelectedStatuses();
                const selectedWarehouse = warehouseFilter ? warehouseFilter.value.trim() : "";
                const selectedKeeper = keeperFilter ? keeperFilter.value.trim() : "";

                filteredRows = allRows.filter(row => {
                    if (row.cells.length < 7) return false;

                    const ticketCode = row.cells[0].textContent.toLowerCase();
                    const poCode = row.cells[1].textContent.toLowerCase();
                    const supplier = row.cells[2].textContent.toLowerCase();
                    const warehouse = row.cells[3].textContent.trim();
                    const keeper = row.cells[5].textContent.toLowerCase();
                    const matchesSearch = searchQuery === "" ||
                                          ticketCode.includes(searchQuery) ||
                                          poCode.includes(searchQuery) ||
                                          supplier.includes(searchQuery) ||
                                          keeper.includes(searchQuery);

                    const createdAtText = row.cells[6].textContent.trim();
                    const createdAtDatePart = createdAtText.split(" ")[0];
                    let matchesDate = true;
                    if (selectedStartDate !== "" && createdAtDatePart < selectedStartDate) matchesDate = false;
                    if (selectedEndDate !== "" && createdAtDatePart > selectedEndDate) matchesDate = false;

                    const status = row.cells[4].textContent.trim();
                    const matchesStatus = selectedStatuses.length === 0 || selectedStatuses.includes(status);

                    const matchesWarehouse = selectedWarehouse === "" || warehouse === selectedWarehouse;

                    const keeperText = row.cells[5].textContent.trim();
                    const matchesKeeper = selectedKeeper === "" || keeperText.toLowerCase().includes(selectedKeeper.toLowerCase());

                    return matchesSearch && matchesDate && matchesStatus && matchesWarehouse && matchesKeeper;
                });
                

                allRows.forEach(row => row.style.display = "none");
                
                const totalRows = filteredRows.length;
                const totalPages = Math.ceil(totalRows / pageSize);
                
                if (currentPage > totalPages) currentPage = Math.max(1, totalPages);
                
                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, totalRows);
                

                for (let i = start; i < end; i++) {
                    filteredRows[i].style.display = "";
                }
                
                renderPaginationControls(totalPages, totalRows);
            }
            
            function renderPaginationControls(totalPages, totalRows) {
                container.innerHTML = "";
                if (totalRows === 0) {
                    container.innerHTML = "<span class='text-muted small'>Không tìm thấy kết quả phù hợp</span>";
                    return;
                }
                
                const infoSpan = document.createElement("span");
                infoSpan.className = "text-muted small";
                const startIdx = (currentPage - 1) * pageSize + 1;
                const endIdx = Math.min(currentPage * pageSize, totalRows);
                infoSpan.textContent = "Hiển thị " + startIdx + " đến " + endIdx + " trong số " + totalRows + " bản ghi · Tổng " + allRows.length + " bản ghi";
                container.appendChild(infoSpan);
                
                const nav = document.createElement("nav");
                const ul = document.createElement("ul");
                ul.className = "pagination pagination-sm m-0 border-0";
                

                const prevLi = document.createElement("li");
                prevLi.className = "page-item " + (currentPage === 1 ? "disabled" : "");
                const prevA = document.createElement("a");
                prevA.className = "page-link";
                prevA.href = "#";
                prevA.innerHTML = '<i class="bi bi-chevron-left"></i>';
                prevA.addEventListener("click", function(e) {
                    e.preventDefault();
                    if (currentPage > 1) {
                        currentPage--;
                        filterAndPaginate();
                    }
                });
                prevLi.appendChild(prevA);
                ul.appendChild(prevLi);
                

                for (let i = 1; i <= totalPages; i++) {
                    const li = document.createElement("li");
                    li.className = "page-item " + (currentPage === i ? "active" : "");
                    const a = document.createElement("a");
                    a.className = "page-link";
                    a.href = "#";
                    a.textContent = i;
                    a.addEventListener("click", function(e) {
                        e.preventDefault();
                        currentPage = i;
                        filterAndPaginate();
                    });
                    li.appendChild(a);
                    ul.appendChild(li);
                }
                

                const nextLi = document.createElement("li");
                nextLi.className = "page-item " + (currentPage === totalPages ? "disabled" : "");
                const nextA = document.createElement("a");
                nextA.className = "page-link";
                nextA.href = "#";
                nextA.innerHTML = '<i class="bi bi-chevron-right"></i>';
                nextA.addEventListener("click", function(e) {
                    e.preventDefault();
                    if (currentPage < totalPages) {
                        currentPage++;
                        filterAndPaginate();
                    }
                });
                nextLi.appendChild(nextA);
                ul.appendChild(nextLi);
                
                nav.appendChild(ul);
                container.appendChild(nav);
            }
            
            select.addEventListener("change", function() {
                pageSize = parseInt(this.value) || 10;
                currentPage = 1;
                filterAndPaginate();
            });

            document.getElementById("filterBtn").addEventListener("click", function() {
                currentPage = 1;
                filterAndPaginate();
            });

            document.getElementById("resetBtn").addEventListener("click", function() {
                if (searchInput) searchInput.value = "";
                if (startDateFilter) { startDateFilter.value = ""; startDateFilter.max = ""; }
                if (endDateFilter) { endDateFilter.value = ""; endDateFilter.min = ""; }
                document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(cb => cb.checked = false);
                updateStatusLabel();
                if (warehouseFilter) warehouseFilter.value = "";
                if (keeperFilter) keeperFilter.value = "";
                currentPage = 1;
                filterAndPaginate();
            });
            
            filterAndPaginate();
        }
    </script>
</body>
</html>
