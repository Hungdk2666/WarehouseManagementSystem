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
    boolean canAdd = loggedInUser.hasPermission("TICKET_ADD_IN");
    boolean canConfirm = loggedInUser.hasPermission("TICKET_CONFIRM_IN");
    boolean canCancel = loggedInUser.hasPermission("TICKET_CANCEL_IN");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Phiếu nhập kho - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Phiếu nhập kho</h2>
                        <p class="text-muted small mb-0">Ghi nhận và xác nhận hàng hóa thực tế nhập kho</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Quay lại
                    </a>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-arrow-in-down me-2"></i>Sổ đăng ký Phiếu nhập kho</h5>
                        <% if (canAdd) { %>
                        <a href="import-ticket?action=add" class="btn btn-primary btn-sm d-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Tạo Phiếu nhập kho
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="px-4 pt-4 pb-2">
                            <div class="row g-3 align-items-end">
                                <!-- Search Bar -->
                                <div class="col-md-3">
                                    <label for="importSearch" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-search me-1"></i>Tìm kiếm</label>
                                    <input type="text" id="importSearch" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Phiếu nhập, mã yêu cầu, thủ kho..." style="box-shadow: none; font-size: 0.85rem;">
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
                                        <option value="BẢN NHÁP">BẢN NHÁP</option>
                                        <option value="ĐÃ XÁC NHẬN">ĐÃ XÁC NHẬN</option>
                                        <option value="ĐÃ HỦY">ĐÃ HỦY</option>
                                    </select>
                                </div>
                                <!-- Warehouse Filter -->
                                <div class="col-md-3">
                                    <label for="warehouseFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-building me-1"></i>Kho nhập</label>
                                    <select id="warehouseFilter" class="form-select form-select-sm shadow-sm rounded-3" style="box-shadow: none; font-size: 0.85rem;">
                                        <option value="">-- Tất cả kho --</option>
                                    </select>
                                </div>
                                <!-- Keeper Filter -->
                                <div class="col-md-3">
                                    <label for="keeperFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-person-fill me-1"></i>Thủ kho (Nhân viên)</label>
                                    <input type="text" id="keeperFilter" list="keeperDatalist" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Nhập hoặc chọn..." style="box-shadow: none; font-size: 0.85rem;">
                                    <datalist id="keeperDatalist"></datalist>
                                </div>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table id="grnTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th>Mã phiếu</th>
                                        <th>Yêu cầu liên kết</th>
                                        <th>Nhà cung cấp</th>
                                        <th>Kho nhập</th>
                                        <th>Trạng thái</th>
                                        <th>Thủ kho (Nhân viên)</th>
                                        <th>Ngày tạo</th>
                                        <th>Xác nhận bởi</th>
                                        <th>Thời gian xác nhận</th>
                                        <th>Hành động</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (ticketList != null && !ticketList.isEmpty()) {
                                            for (Ticket t : ticketList) {
                                                String statusBadge = "bg-secondary text-secondary";
                                                if ("DRAFT".equals(t.getStatus())) statusBadge = "bg-warning text-warning";
                                                else if ("CONFIRMED".equals(t.getStatus())) statusBadge = "bg-success text-success";
                                                else if ("CANCELLED".equals(t.getStatus())) statusBadge = "bg-secondary text-secondary";
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= t.getTicketCode() %></td>
                                        <td class="fw-bold text-primary">#<%= t.getRequestCode() %></td>
                                        <td class="text-start ps-3 fw-semibold"><%= t.getPartnerName() != null ? t.getPartnerName() : "-" %></td>
                                        <td><span class="badge bg-primary bg-opacity-10 text-primary"><i class="bi bi-building me-1"></i><%= t.getWarehouseName() != null ? t.getWarehouseName() : "-" %></span></td>
                                        <td>
                                            <%
                                                String displayTStatus = t.getStatus();
                                                if ("CONFIRMED".equals(t.getStatus())) displayTStatus = "ĐÃ XÁC NHẬN";
                                                else if ("DRAFT".equals(t.getStatus())) displayTStatus = "BẢN NHÁP";
                                                else if ("CANCELLED".equals(t.getStatus())) displayTStatus = "ĐÃ HỦY";
                                            %>
                                            <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayTStatus %></span>
                                        </td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td class="text-muted small"><%= t.getCreatedAt() %></td>
                                        <td><%= t.getConfirmedByFullName() != null ? t.getConfirmedByFullName() : "-" %></td>
                                        <td class="text-muted small"><%= t.getConfirmedAt() != null ? t.getConfirmedAt() : "-" %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="import-ticket?action=detail&id=<%= t.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                    <i class="bi bi-eye"></i> Chi tiết
                                                </a>
                                                <% if (canConfirm && "DRAFT".equals(t.getStatus())) { %>
                                                <form action="import-ticket?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Xác nhận Phiếu nhập kho này sẽ cập nhật số lượng sản phẩm, giá vốn bình quân động và đăng ký giao dịch sổ cái kho. Tiến hành?');">
                                                    <input type="hidden" name="id" value="<%= t.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-success d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-check-circle"></i> Xác nhận
                                                    </button>
                                                </form>
                                                <% } %>
                                                <% if (canCancel && "DRAFT".equals(t.getStatus())) { %>
                                                <form action="import-ticket?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Bạn có chắc chắn muốn hủy Phiếu nhập kho này?');">
                                                    <input type="hidden" name="id" value="<%= t.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-slash-circle"></i> Hủy
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
                                        <td colspan="10" class="text-center text-muted py-5">
                                            <i class="bi bi-box-arrow-in-down text-muted display-4 d-block mb-3"></i>
                                            Không tìm thấy Phiếu nhập kho nào.
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-top-0 d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 bg-light rounded-bottom-3 gap-3">
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
    
    <script>
        const userWarehouseName = '<%= loggedInUser.getWarehouseName() != null ? loggedInUser.getWarehouseName().replace("'", "\\'") : "" %>';

        document.addEventListener("DOMContentLoaded", function() {
            initPaginationAndFilter("grnTable", "paginationContainer", "entriesPerPage", "importSearch", "dateFilter", "statusFilter", "warehouseFilter", "keeperFilter");
        });

        // Col indices: 0=code, 1=PO, 2=supplier, 3=warehouse, 4=status, 5=keeper, 6=createdAt, 7=confirmedBy, 8=confirmedAt, 9=actions
        function initPaginationAndFilter(tableId, containerId, selectId, searchInputId, dateFilterId, statusFilterId, warehouseFilterId, keeperFilterId) {
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
            const dateFilter = document.getElementById(dateFilterId);
            const statusFilter = document.getElementById(statusFilterId);
            const warehouseFilter = document.getElementById(warehouseFilterId);
            const keeperFilter = document.getElementById(keeperFilterId);
            if (!container || !select) return;

            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            let filteredRows = allRows;

            // Populate warehouse dropdown
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

            // Dynamically populate Keeper datalist
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
                const selectedDate = dateFilter ? dateFilter.value : "";
                const selectedStatus = statusFilter ? statusFilter.value : "";
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
                    const matchesDate = selectedDate === "" || createdAtDatePart === selectedDate;

                    const status = row.cells[4].textContent.trim();
                    const matchesStatus = selectedStatus === "" || status === selectedStatus;

                    const matchesWarehouse = selectedWarehouse === "" || warehouse === selectedWarehouse;

                    const keeperText = row.cells[5].textContent.trim();
                    const matchesKeeper = selectedKeeper === "" || keeperText.toLowerCase().includes(selectedKeeper.toLowerCase());

                    return matchesSearch && matchesDate && matchesStatus && matchesWarehouse && matchesKeeper;
                });
                
                // Hide all rows first
                allRows.forEach(row => row.style.display = "none");
                
                const totalRows = filteredRows.length;
                const totalPages = Math.ceil(totalRows / pageSize);
                
                if (currentPage > totalPages) currentPage = Math.max(1, totalPages);
                
                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, totalRows);
                
                // Show only the current page rows of the filtered set
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
                infoSpan.textContent = "Hiển thị " + startIdx + " đến " + endIdx + " trong số " + totalRows + " bản ghi (lọc từ tổng số " + allRows.length + " bản ghi)";
                container.appendChild(infoSpan);
                
                const nav = document.createElement("nav");
                const ul = document.createElement("ul");
                ul.className = "pagination pagination-sm m-0 border-0";
                
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

            if (searchInput) {
                searchInput.addEventListener("input", function() {
                    currentPage = 1;
                    filterAndPaginate();
                });
            }
            if (dateFilter) {
                dateFilter.addEventListener("change", function() {
                    currentPage = 1;
                    filterAndPaginate();
                });
            }
            if (statusFilter) {
                statusFilter.addEventListener("change", function() {
                    currentPage = 1;
                    filterAndPaginate();
                });
            }
            if (warehouseFilter) {
                warehouseFilter.addEventListener("change", function() {
                    currentPage = 1;
                    filterAndPaginate();
                });
            }
            if (keeperFilter) {
                keeperFilter.addEventListener("input", function() {
                    currentPage = 1;
                    filterAndPaginate();
                });
            }
            
            filterAndPaginate();
        }
    </script>
</body>
</html>
