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
            <!-- Left Sidebar -->
            <jsp:include page="/includes/sidebar.jsp" />

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Phiếu xuất kho</h2>
                        <p class="text-muted small mb-0">Ghi nhận và xác nhận thực tế xuất hàng hóa khỏi kho.</p>
                    </div>
                    <% if (canAdd) { %>
                    <a href="export-ticket?action=add" class="btn btn-primary d-inline-flex align-items-center gap-2 px-3 py-2 shadow-sm rounded-3">
                        <i class="bi bi-plus-circle-fill"></i> Tạo Phiếu xuất kho
                    </a>
                    <% } %>
                </div>

                <%-- Phase 4: Incoming Transfers section — only for destination warehouse staff --%>
                <% if (incomingTransfers != null && !incomingTransfers.isEmpty()) { %>
                <div class="card border-0 shadow-sm mb-4" style="border-left: 4px solid #f59e0b !important;">
                    <div class="card-header bg-warning bg-opacity-10 py-3 border-0 d-flex align-items-center gap-2">
                        <i class="bi bi-truck fs-5 text-warning"></i>
                        <h5 class="mb-0 fw-bold text-warning">Hàng đang chuyển đến kho bạn</h5>
                        <span class="badge bg-warning text-dark ms-2"><%= incomingTransfers.size() %> phiếu</span>
                        <span class="ms-auto text-muted small">Những phiếu chuyển kho này đang trên đường vận chuyển (IN_TRANSIT) — tạo phiếu nhập khi nhận được hàng.</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0 text-center" style="font-size: 0.88rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.72rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th>Mã phiếu</th>
                                        <th>Mã yêu cầu</th>
                                        <th>Kho xuất (nguồn)</th>
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
                                        <td class="text-muted small"><%= it.getConfirmedAt() != null ? it.getConfirmedAt().toString().substring(0, 16) : "-" %></td>
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

                <!-- Filters -->
                <div class="card shadow-sm border-0 mb-4 bg-white">
                    <div class="card-body p-3">
                        <div class="row g-2 align-items-end">
                            <!-- Search -->
                            <div class="col-md-3">
                                <label for="searchInput" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-search me-1"></i>Tìm kiếm mã</label>
                                <input type="text" id="searchInput" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Tìm mã phiếu, mã yêu cầu..." style="box-shadow: none; font-size: 0.85rem;">
                            </div>
                            <!-- Date Filter -->
                            <div class="col-md-3">
                                <label for="dateFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-calendar3 me-1"></i>Ngày tạo</label>
                                <input type="date" id="dateFilter" class="form-control form-control-sm shadow-sm rounded-3" style="box-shadow: none; font-size: 0.85rem;">
                            </div>
                            <!-- Status Filter -->
                            <div class="col-md-3">
                                <label for="statusFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-tag-fill me-1"></i>Trạng thái</label>
                                <select id="statusFilter" class="form-select form-select-sm shadow-sm rounded-3" style="box-shadow: none; font-size: 0.85rem;">
                                    <option value="">-- Tất cả trạng thái --</option>
                                    <option value="Bản nháp">Bản nháp</option>
                                    <option value="Đã xác nhận">Đã xác nhận</option>
                                    <option value="Đang vận chuyển">Đang vận chuyển</option>
                                    <option value="Đã hủy">Đã hủy</option>
                                </select>
                            </div>
                            <!-- Warehouse Filter -->
                            <div class="col-md-3">
                                <label for="warehouseFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-building me-1"></i>Kho xuất</label>
                                <select id="warehouseFilter" class="form-select form-select-sm shadow-sm rounded-3" style="box-shadow: none; font-size: 0.85rem;">
                                    <option value="">-- Tất cả kho --</option>
                                </select>
                            </div>
                            <!-- Keeper Filter -->
                            <div class="col-md-3">
                                <label for="keeperFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-person-fill me-1"></i>Thủ kho</label>
                                <input type="text" id="keeperFilter" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Nhập tên thủ kho..." style="box-shadow: none; font-size: 0.85rem;">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Tickets Directory Table -->
                <div class="card shadow-sm border-0 bg-white">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-arrow-up-right me-2"></i>Danh sách phiếu xuất kho</h5>
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
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
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
                                                String statusBadge = "bg-secondary text-secondary";
                                                String displayStatus = t.getStatus();
                                                if ("DRAFT".equals(t.getStatus())) {
                                                    statusBadge = "bg-warning text-warning";
                                                    displayStatus = "Bản nháp";
                                                } else if ("CONFIRMED".equals(t.getStatus())) {
                                                    statusBadge = "bg-success text-success";
                                                    displayStatus = "Đã xác nhận";
                                                } else if ("IN_TRANSIT".equals(t.getStatus())) {
                                                    statusBadge = "bg-info text-info";
                                                    displayStatus = "Đang vận chuyển";
                                                } else if ("CANCELLED".equals(t.getStatus())) {
                                                    statusBadge = "bg-danger text-danger";
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
                                                    else if ("DISPOSAL".equals(t.getRequestReason())) out.print("TIÊU HỦY");
                                                    else out.print(t.getRequestReason() != null ? t.getRequestReason() : "-");
                                                %>
                                            </span>
                                        </td>
                                        <td><span class="badge bg-primary bg-opacity-10 text-primary"><i class="bi bi-building me-1"></i><%= t.getWarehouseName() != null ? t.getWarehouseName() : "-" %></span></td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td>
                                            <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayStatus %></span>
                                        </td>
                                        <td class="text-muted small"><%= t.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="export-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                    <i class="bi bi-eye"></i> Chi tiết
                                                </a>
                                                <% if (canConfirm && "DRAFT".equals(t.getStatus())) { %>
                                                <form action="export-ticket?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Xác nhận phiếu này sẽ trừ tồn kho thực tế. Bạn có chắc chắn không?');">
                                                    <input type="hidden" name="id" value="<%= t.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-success d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-check-circle"></i> Xác nhận
                                                    </button>
                                                </form>
                                                <% } %>
                                                <% if (canCancel && "DRAFT".equals(t.getStatus())) { %>
                                                <form action="export-ticket?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Bạn có chắc chắn muốn hủy Phiếu xuất kho này không?');">
                                                    <input type="hidden" name="id" value="<%= t.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-trash"></i> Hủy
                                                    </button>
                                                </form>
                                                <% } %>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="9" class="text-center py-5 text-muted">
                                            <i class="bi bi-inbox display-6 d-block mb-2 text-muted bg-opacity-10"></i>
                                            Không tìm thấy phiếu xuất kho nào.
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <!-- Pagination Container -->
                    <div class="card-footer bg-transparent py-3 border-0" id="paginationContainer"></div>
                </div>

            </div>
        </div>
    </div>

    <!-- Client-Side Pagination & Filter Script -->
    <script>
        // Col indices: 0=code, 1=reqCode, 2=destination, 3=reason, 4=warehouse, 5=keeper, 6=status, 7=createdAt, 8=actions
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
            const dateFilter = document.getElementById("dateFilter");
            const statusFilter = document.getElementById("statusFilter");
            const warehouseFilter = document.getElementById("warehouseFilter");
            const keeperFilter = document.getElementById("keeperFilter");
            const select = document.getElementById("entriesPerPage");

            // Populate warehouse dropdown
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
                const dateVal = dateFilter ? dateFilter.value : "";
                const statusVal = statusFilter ? statusFilter.value : "";
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
                    if (dateVal && !createdAt.startsWith(dateVal)) return false;
                    if (statusVal && status !== statusVal) return false;
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
                    tbody.innerHTML = `<tr><td colspan="9" class="text-center py-5 text-muted"><i class="bi bi-search display-6 d-block mb-2"></i>Không tìm thấy bản ghi phù hợp.</td></tr>`;
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

                // Prev
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

                // Pages
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

                // Next
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

            if (searchInput) searchInput.addEventListener("input", () => { currentPage = 1; filterAndPaginate(); });
            if (dateFilter) dateFilter.addEventListener("change", () => { currentPage = 1; filterAndPaginate(); });
            if (statusFilter) statusFilter.addEventListener("change", () => { currentPage = 1; filterAndPaginate(); });
            if (warehouseFilter) warehouseFilter.addEventListener("change", () => { currentPage = 1; filterAndPaginate(); });
            if (keeperFilter) keeperFilter.addEventListener("input", () => { currentPage = 1; filterAndPaginate(); });

            filterAndPaginate();
        }
    </script>
</body>
</html>
