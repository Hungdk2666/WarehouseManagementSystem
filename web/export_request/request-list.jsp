<%@page import="model.Request"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_VIEW_OUT")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Request> requestList = (List<Request>) request.getAttribute("requestList");
    boolean canAdd = loggedInUser.hasPermission("REQUEST_ADD_OUT");
    boolean canApprove = loggedInUser.hasPermission("REQUEST_APPROVE_OUT");
    boolean canCancel = loggedInUser.hasPermission("REQUEST_CANCEL_OUT");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Yêu cầu xuất kho - WMS</title>
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
                <jsp:include page="/includes/frozen-banner.jsp" />
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Yêu cầu xuất kho</h2>
                        <p class="page-subtitle">Quản lý và theo dõi các yêu cầu xuất kho nội bộ.</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (canAdd) { %>
                        <a href="export-request?action=add" class="btn btn-primary d-inline-flex align-items-center gap-2">
                            <i class="bi bi-plus-circle-fill"></i> Tạo yêu cầu
                        </a>
                        <% } %>
                    </div>
                </div>

                <!-- Filters -->
                <div class="card card-overflow-visible mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-12 col-md-3">
                                <label for="searchInput" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" id="searchInput" class="form-control form-control-sm" placeholder="Mã yêu cầu, người tạo...">
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
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Chờ duyệt"> Chờ duyệt</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Đã duyệt"> Đã duyệt</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Chờ hủy"> Chờ hủy</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Từ chối"> Từ chối</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Hoàn thành"> Hoàn thành</label></li>
                                        <li><label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item"><input type="checkbox" class="status-cb form-check-input flex-shrink-0 m-0" value="Đã hủy"> Đã hủy</label></li>
                                        <li><hr class="dropdown-divider my-1"></li>
                                        <li><button type="button" id="clearStatusBtn" class="btn btn-link btn-sm w-100 text-muted text-decoration-none py-1" style="font-size:0.8rem;"><i class="bi bi-x-circle me-1"></i>Xóa chọn</button></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-6 col-md-2">
                                <label for="creatorFilter" class="form-label small fw-semibold mb-1">Người tạo</label>
                                <input type="text" id="creatorFilter" class="form-control form-control-sm" placeholder="Nhập tên...">
                            </div>
                            <div class="col-12 col-md-auto ms-md-auto d-flex gap-2">
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

                <!-- Requests Directory Table -->
                <div class="card mb-4">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-list-task me-2 text-primary"></i>Danh sách yêu cầu xuất kho</span>
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
                            <table id="requestTable" class="table table-hover align-middle mb-0 text-center">
                                <thead class="table-light">
                                    <tr>
                                        <th>Mã yêu cầu</th>
                                        <th class="text-start ps-3">Điểm nhận</th>
                                        <th>Lý do</th>
                                        <th>Ngày dự kiến</th>
                                        <th>Người tạo</th>
                                        <th>Trạng thái</th>
                                        <th>Ngày tạo</th>
                                        <th>Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (requestList != null && !requestList.isEmpty()) {
                                            for (Request r : requestList) {
                                                String statusBadge = "chip-muted";
                                                String displayStatus = r.getStatus();
                                                if ("PENDING".equals(r.getStatus())) {
                                                    statusBadge = "chip-warning";
                                                    displayStatus = "Chờ duyệt";
                                                } else if ("APPROVED".equals(r.getStatus())) {
                                                    if (r.getCancelRequestedAt() != null) {
                                                        statusBadge = "chip-warning";
                                                        displayStatus = "Chờ hủy";
                                                    } else {
                                                        statusBadge = "chip-success";
                                                        displayStatus = "Đã duyệt";
                                                    }
                                                } else if ("PARTIALLY_COMPLETED".equals(r.getStatus())) {
                                                    statusBadge = "chip-info";
                                                    displayStatus = "Đang xuất dở";
                                                } else if ("REJECTED".equals(r.getStatus())) {
                                                    statusBadge = "chip-danger";
                                                    displayStatus = "Từ chối";
                                                } else if ("COMPLETED".equals(r.getStatus())) {
                                                    statusBadge = "chip-primary";
                                                    displayStatus = "Hoàn thành";
                                                } else if ("CANCELLED".equals(r.getStatus())) {
                                                    statusBadge = "chip-muted";
                                                    displayStatus = "Đã hủy";
                                                }
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= r.getRequestCode() %></td>
                                        <td class="text-start ps-3 fw-semibold">
                                            <% if ("TRANSFER".equals(r.getReason())) { %>
                                            <i class="bi bi-building me-1 text-info"></i><%= r.getPartnerName() != null ? r.getPartnerName() : "-" %>
                                            <% } else if ("CUSTOMER_SALE".equals(r.getReason())) { %>
                                            <i class="bi bi-person me-1 text-success"></i><%= r.getPartnerName() != null ? r.getPartnerName() : "-" %>
                                            <% } else { %>
                                            <%= r.getPartnerName() != null ? r.getPartnerName() : "-" %>
                                            <% } %>
                                        </td>
                                        <td>
                                            <span class="badge bg-light text-dark border">
                                                <%
                                                    if ("TRANSFER".equals(r.getReason())) {
                                                        out.print("CHUYỂN KHO");
                                                    } else if ("CUSTOMER_SALE".equals(r.getReason())) {
                                                        out.print("BÁN HÀNG");
                                                    } else {
                                                        out.print(r.getReason());
                                                    }
                                                %>
                                            </span>
                                        </td>
                                        <td class="text-nowrap"><%= r.getExpectedDate() %></td>
                                        <td><%= r.getStaffFullName() %></td>
                                        <td>
                                            <span class="status-chip <%= statusBadge %>"><%= displayStatus %></span>
                                        </td>
                                        <td class="text-muted small text-nowrap"><%= r.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="export-request?action=detail&id=<%= r.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết" aria-label="Xem chi tiết yêu cầu xuất">
                                                    <i class="bi bi-eye" aria-hidden="true"></i>
                                                </a>
                                                <% if (canApprove && "PENDING".equals(r.getStatus())) { %>
                                                <form action="export-request?action=approve" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-success d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-check-circle"></i> Duyệt
                                                    </button>
                                                </form>
                                                <form action="export-request?action=reject" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-danger d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-x-circle"></i> Từ chối
                                                    </button>
                                                </form>
                                                <% } %>
                                                <% if (canCancel && "PENDING".equals(r.getStatus())) { %>
                                                <form action="export-request?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Bạn có chắc chắn muốn hủy yêu cầu này không?');">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
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
                                        <td colspan="8" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Không tìm thấy yêu cầu xuất kho nào.</p>
                                            </div>
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
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            initTableFilterAndPagination();
        });

        function initTableFilterAndPagination() {
            const table = document.getElementById("requestTable");
            const tbody = table.querySelector("tbody");
            const allRows = Array.from(tbody.querySelectorAll("tr"));
            
            // If it's empty, skip
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
            const creatorFilter = document.getElementById("creatorFilter");

            // Multi-select trạng thái
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
            const select = document.getElementById("entriesPerPage");
            const container = document.getElementById("paginationContainer");

            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            let filteredRows = [...allRows];

            function filterAndPaginate() {
                const searchVal = searchInput.value.toLowerCase().trim();
                const startDateVal = startDateFilter.value;
                const endDateVal = endDateFilter.value;
                const statusVals = getSelectedStatuses();
                const creatorVal = creatorFilter.value.toLowerCase().trim();

                filteredRows = allRows.filter(row => {
                    const cells = row.cells;
                    if (cells.length < 7) return true; // safety

                    const code = cells[0].textContent.toLowerCase();
                    const destination = cells[1].textContent.toLowerCase();
                    const reason = cells[2].textContent.toLowerCase();
                    const expectedDate = cells[3].textContent;
                    const creator = cells[4].textContent.toLowerCase();
                    const status = cells[5].textContent.trim();
                    const createdAt = cells[6].textContent;

                    // Match filters
                    if (searchVal && !code.includes(searchVal)) return false;
                    let matchesDate = true;
                    const createdAtDatePart = createdAt.trim().split(" ")[0];
                    if (startDateVal && createdAtDatePart < startDateVal) matchesDate = false;
                    if (endDateVal && createdAtDatePart > endDateVal) matchesDate = false;
                    if (!matchesDate) return false;
                    if (statusVals.length > 0 && !statusVals.includes(status)) return false;
                    if (creatorVal && !creator.includes(creatorVal)) return false;

                    return true;
                });

                currentPage = Math.min(currentPage, Math.ceil(filteredRows.length / pageSize) || 1);
                renderTable();
                renderPagination();
            }

            function renderTable() {
                tbody.innerHTML = "";
                if (filteredRows.length === 0) {
                    tbody.innerHTML = `<tr><td colspan="8" class="p-0"><div class="empty-state"><i class="bi bi-search"></i><p>Không tìm thấy bản ghi phù hợp.</p></div></td></tr>`;
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

            document.getElementById("filterBtn").addEventListener("click", () => {
                currentPage = 1;
                filterAndPaginate();
            });

            document.getElementById("resetBtn").addEventListener("click", () => {
                searchInput.value = "";
                startDateFilter.value = "";
                startDateFilter.max = "";
                endDateFilter.value = "";
                endDateFilter.min = "";
                document.querySelectorAll('#statusDropdownMenu .status-cb').forEach(cb => cb.checked = false);
                updateStatusLabel();
                creatorFilter.value = "";
                currentPage = 1;
                filterAndPaginate();
            });

            filterAndPaginate();
        }
    </script>
</body>
</html>
