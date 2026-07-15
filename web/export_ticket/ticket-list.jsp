<%@page import="model.Ticket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_VIEW_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Ticket> ticketList = (List<Ticket>) request.getAttribute("ticketList");
    List<Ticket> incomingTransfers = (List<Ticket>) request.getAttribute("incomingTransfers");
    boolean canAdd = loggedInUser.hasPermission("TICKET_ADD_OUT");
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_OUT");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_OUT");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Phiếu xuất kho - WMS</title>
    
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
                        <h2 class="page-title">Phiếu xuất kho</h2>
                        <p class="page-subtitle">Ghi nhận và xác nhận thực tế xuất hàng hóa khỏi kho.</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (canAdd) { %>
                        <a href="export-ticket?action=add" class="btn btn-primary d-inline-flex align-items-center gap-2">
                            <i class="bi bi-plus-circle-fill"></i> Tạo Phiếu xuất kho
                        </a>
                        <% } %>
                    </div>
                </div>

                
                <% if (incomingTransfers != null && !incomingTransfers.isEmpty()) { %>
                <div class="card mb-4" style="border-left: 4px solid #f59e0b !important;">
                    <div class="card-header bg-warning bg-opacity-10 py-3 d-flex align-items-center gap-2">
                        <i class="bi bi-truck fs-5 text-warning"></i>
                        <span class="fw-bold text-warning">Hàng đang chuyển đến kho bạn</span>
                        <span class="badge bg-warning text-dark ms-2"><%= incomingTransfers.size() %> phiếu</span>
                        <span class="ms-auto text-muted small">Những phiếu chuyển kho này đang trên đường vận chuyển — tạo phiếu nhập khi nhận được hàng.</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.88rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.72rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th>Mã phiếu</th>
                                        <th>Mã yêu cầu</th>
                                        <th>Kho nguồn</th>
                                        <th>Thủ kho</th>
                                        <th>Ngày xuất</th>
                                        <% if (canConfirm) { %><th>Thao tác</th><% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Ticket it : incomingTransfers) { %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= it.getTicketCode() %></td>
                                        <td class="fw-semibold text-primary">#<%= it.getRequestCode() %></td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary"><i class="bi bi-building me-1"></i><%= it.getWarehouseName() != null ? it.getWarehouseName() : "-" %></span></td>
                                        <td><%= it.getKeeperFullName() %></td>
                                        <td class="text-muted small text-nowrap"><%= it.getConfirmedAt() != null ? it.getConfirmedAt().toString().substring(0, 16) : "-" %></td>
                                        <% if (canConfirm) { %>
                                        <td>
                                            <div class="d-flex justify-content-center gap-1">
                                                <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="btn btn-sm btn-warning py-1 px-2">
                                                    <i class="bi bi-box-arrow-in-down"></i> Vào tạo Phiếu nhập
                                                </a>
                                            </div>
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
                                <label for="searchInput" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" id="searchInput" class="form-control form-control-sm" placeholder="Mã phiếu, mã yêu cầu...">
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
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Bản nháp"> Bản nháp</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Đã xác nhận"> Đã xác nhận</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Đang vận chuyển"> Đang vận chuyển</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Đã hủy"> Đã hủy</label></li>
                                        <li><hr class="dropdown-divider my-1"></li>
                                        <li><button type="button" id="clearStatusBtn" class="btn btn-link btn-sm w-100 text-muted text-decoration-none py-1" style="font-size:0.8rem;"><i class="bi bi-x-circle me-1"></i>Xóa chọn</button></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="warehouseFilter" class="form-label small fw-semibold mb-1">Kho xuất</label>
                                <select id="warehouseFilter" class="form-select form-select-sm">
                                    <option value="">-- Tất cả kho --</option>
                                </select>
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="keeperFilter" class="form-label small fw-semibold mb-1">Thủ kho</label>
                                <input type="text" id="keeperFilter" class="form-control form-control-sm" placeholder="Nhập tên...">
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
                        <span class="fw-bold text-slate-800"><i class="bi bi-box-arrow-up-right me-2 text-primary"></i>Danh sách phiếu xuất kho</span>
                        <div class="d-flex align-items-center gap-2">
                            <span class="text-muted small">Hiển thị</span>
                            <select id="entriesPerPage" class="form-select form-select-sm py-0.5 ps-2 pe-4 border rounded" style="width: 75px; font-size: 0.75rem;">
                                <option value="5">5</option>
                                <option value="10" selected>10</option>
                                <option value="20">20</option>
                                <option value="50">50</option>
                            </select>
                            <span class="text-muted small">dòng</span>
                        </div>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="ginTable" class="table table-hover align-middle mb-0 text-center">
                                <thead class="table-light">
                                    <tr>
                                        <th>Mã phiếu</th>
                                        <th>Mã yêu cầu</th>
                                        <th class="text-start ps-3">Điểm nhận</th>
                                        <th>Lý do</th>
                                        <th>Kho xuất</th>
                                        <th>Thủ kho</th>
                                        <th>Trạng thái</th>
                                        <th>Ngày tạo</th>
                                        <th>Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (ticketList != null && !ticketList.isEmpty()) {
                                            for (Ticket t : ticketList) {
                                                String statusBadge = "chip-muted";
                                                String displayStatus = t.getStatus();
                                                if ("DRAFT".equals(t.getStatus())) {
                                                    statusBadge = "chip-warning";
                                                    displayStatus = "Bản nháp";
                                                } else if ("CONFIRMED".equals(t.getStatus())) {
                                                    statusBadge = "chip-success";
                                                    displayStatus = "Đã xác nhận";
                                                } else if ("IN_TRANSIT".equals(t.getStatus())) {
                                                    statusBadge = "chip-info";
                                                    displayStatus = "Đang vận chuyển";
                                                } else if ("CANCELLED".equals(t.getStatus())) {
                                                    statusBadge = "chip-muted";
                                                    displayStatus = "Đã hủy";
                                                }
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= t.getTicketCode() %></td>
                                        <td class="fw-semibold text-primary">#<%= t.getRequestCode() %></td>
                                        <td class="text-start ps-3 fw-semibold"><%= t.getPartnerName() %></td>
                                        <td>
                                            <span class="badge bg-light text-dark border">
                                                <%
                                                    if ("TRANSFER".equals(t.getRequestReason())) out.print("CHUYỂN KHO");
                                                    else if ("CUSTOMER_SALE".equals(t.getRequestReason())) out.print("BÁN HÀNG");
                                                    else if ("DISPLAY".equals(t.getRequestReason())) out.print("TRƯNG BÀY");
                                                    else if ("WARRANTY".equals(t.getRequestReason())) out.print("BẢO HÀNH");
                                                    else out.print(t.getRequestReason() != null ? t.getRequestReason() : "-");
                                                %>
                                            </span>
                                        </td>
                                        <td><span class="badge bg-light text-primary"><i class="bi bi-building me-1"></i><%= t.getWarehouseName() != null ? t.getWarehouseName() : "-" %></span></td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td>
                                            <span class="status-chip <%= statusBadge %>"><%= displayStatus %></span>
                                        </td>
                                        <td class="text-muted small text-nowrap"><%= t.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="export-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết" aria-label="Xem chi tiết phiếu xuất">
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
                                        <td colspan="9" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Không tìm thấy phiếu xuất kho nào.</p>
                                            </div>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    
                    <div class="card-footer bg-transparent py-3 border-0" id="paginationContainer"></div>
                </div>

            </div>
        </div>
    </div>

    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>

        const exportUserWarehouse = '<%= loggedInUser.getWarehouseName() != null ? loggedInUser.getWarehouseName().replace("'", "\\'") : "" %>';

        document.addEventListener("DOMContentLoaded", function() {
            initTableFilterAndPagination();
        });

        function initTableFilterAndPagination() {
            const table = document.getElementById("ginTable");
            const tbody = table.querySelector("tbody");
            const allRows = Array.from(tbody.querySelectorAll("tr"));

            if (allRows.length === 1 && allRows[0].cells.length === 1) return;

            const searchInput = document.getElementById("searchInput");
            const startDateFilter = document.getElementById("startDateFilter");
            const endDateFilter = document.getElementById("endDateFilter");
            startDateFilter.addEventListener("change", () => {
                endDateFilter.min = startDateFilter.value;
                if (endDateFilter.value && endDateFilter.value < startDateFilter.value) endDateFilter.value = startDateFilter.value;
            });
            endDateFilter.addEventListener("change", () => {
                startDateFilter.max = endDateFilter.value;
                if (startDateFilter.value && startDateFilter.value > endDateFilter.value) startDateFilter.value = endDateFilter.value;
            });
            const warehouseFilter = document.getElementById("warehouseFilter");
            const keeperFilter = document.getElementById("keeperFilter");
            const select = document.getElementById("entriesPerPage");


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


            if (warehouseFilter) {
                const warehouses = new Set();
                allRows.forEach(row => {
                    if (row.cells.length > 4) warehouses.add(row.cells[4].textContent.trim());
                });
                warehouses.forEach(w => {
                    const opt = document.createElement("option");
                    opt.value = w; opt.textContent = w;
                    warehouseFilter.appendChild(opt);
                });
            }
            const container = document.getElementById("paginationContainer");

            let currentPage = 1;
            let pageSize = parseInt(select ? select.value : "10") || 10;
            let filteredRows = [...allRows];

            function filterAndPaginate() {
                const searchVal = searchInput ? searchInput.value.toLowerCase().trim() : "";
                const startDateVal = startDateFilter ? startDateFilter.value : "";
                const endDateVal = endDateFilter ? endDateFilter.value : "";
                const statusVals = getSelectedStatuses();
                const warehouseVal = warehouseFilter ? warehouseFilter.value.trim() : "";
                const keeperVal = keeperFilter ? keeperFilter.value.toLowerCase().trim() : "";

                filteredRows = allRows.filter(row => {
                    const cells = row.cells;
                    if (cells.length < 8) return true;

                    const code = cells[0].textContent.toLowerCase();
                    const reqCode = cells[1].textContent.toLowerCase();
                    const destination = cells[2].textContent.toLowerCase();
                    const warehouse = cells[4].textContent.trim();
                    const keeper = cells[5].textContent.toLowerCase();
                    const status = cells[6].textContent.trim();
                    const createdAt = cells[7].textContent;

                    if (searchVal && !code.includes(searchVal) && !reqCode.includes(searchVal) && !destination.includes(searchVal)) return false;
                    
                    let matchesDate = true;
                    const createdAtDatePart = createdAt.trim().split(" ")[0];
                    if (startDateVal && createdAtDatePart < startDateVal) matchesDate = false;
                    if (endDateVal && createdAtDatePart > endDateVal) matchesDate = false;
                    if (!matchesDate) return false;

                    if (statusVals.length > 0 && !statusVals.includes(status)) return false;
                    if (warehouseVal && warehouse !== warehouseVal) return false;
                    if (keeperVal && !keeper.includes(keeperVal)) return false;

                    return true;
                });

                currentPage = Math.min(currentPage, Math.ceil(filteredRows.length / pageSize) || 1);
                renderTable();
                renderPagination();
            }

            function renderTable() {
                tbody.innerHTML = "";
                if (filteredRows.length === 0) {
                    tbody.innerHTML = `<tr><td colspan="9" class="p-0"><div class="empty-state"><i class="bi bi-search"></i><p>Không tìm thấy bản ghi phù hợp.</p></div></td></tr>`;
                    return;
                }

                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, filteredRows.length);

                for (let i = start; i < end; i++) {
                    tbody.appendChild(filteredRows[i]);
                }
            }

            function renderPagination() {
                container.innerHTML = "";
                const totalPages = Math.ceil(filteredRows.length / pageSize);
                if (totalPages <= 1) return;

                const nav = document.createElement("nav");
                nav.className = "d-flex justify-content-between align-items-center";

                const info = document.createElement("div");
                info.className = "small text-muted";
                const start = (currentPage - 1) * pageSize + 1;
                const end = Math.min(start + pageSize - 1, filteredRows.length);
                info.textContent = "Hiển thị từ " + start + " đến " + end + " trong số " + filteredRows.length + " bản ghi";
                nav.appendChild(info);

                const ul = document.createElement("ul");
                ul.className = "pagination pagination-sm m-0";


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
                    li.className = "page-item " + (i === currentPage ? "active" : "");
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

            if (document.getElementById("filterBtn")) {
                document.getElementById("filterBtn").addEventListener("click", () => {
                    currentPage = 1;
                    filterAndPaginate();
                });
            }

            if (document.getElementById("resetBtn")) {
                document.getElementById("resetBtn").addEventListener("click", () => {
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
            }

            filterAndPaginate();
        }
    </script>
</body>
</html>
