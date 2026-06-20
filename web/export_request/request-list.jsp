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
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Yêu cầu xuất kho</h2>
                        <p class="text-muted small mb-0">Quản lý và theo dõi các yêu cầu xuất kho nội bộ.</p>
                    </div>
                    <% if (canAdd) { %>
                    <a href="export-request?action=add" class="btn btn-primary d-inline-flex align-items-center gap-2 px-3 py-2 shadow-sm rounded-3">
                        <i class="bi bi-plus-circle-fill"></i> Tạo yêu cầu
                    </a>
                    <% } %>
                </div>

                <!-- Filters -->
                <div class="card shadow-sm border-0 mb-4 bg-white">
                    <div class="card-body p-3">
                        <div class="row g-2 align-items-end">
                            <!-- Search -->
                            <div class="col-md-3">
                                <label for="searchInput" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-search me-1"></i>Tìm kiếm mã</label>
                                <input type="text" id="searchInput" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Nhập mã yêu cầu..." style="box-shadow: none; font-size: 0.85rem;">
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
                                    <option value="Chờ duyệt">Chờ duyệt</option>
                                    <option value="Đã duyệt">Đã duyệt</option>
                                    <option value="Chờ hủy">Chờ hủy</option>
                                    <option value="Từ chối">Từ chối</option>
                                    <option value="Hoàn thành">Hoàn thành</option>
                                    <option value="Đã hủy">Đã hủy</option>
                                </select>
                            </div>
                            <!-- Creator Filter -->
                            <div class="col-md-3">
                                <label for="creatorFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-person-fill me-1"></i>Người tạo</label>
                                <input type="text" id="creatorFilter" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Nhập tên..." style="box-shadow: none; font-size: 0.85rem;">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Requests Directory Table -->
                <div class="card shadow-sm border-0 bg-white">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-list-task me-2"></i>Danh sách yêu cầu xuất kho</h5>
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
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
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
                                                String statusBadge = "bg-secondary text-secondary";
                                                String displayStatus = r.getStatus();
                                                if ("PENDING".equals(r.getStatus())) {
                                                    statusBadge = "bg-warning text-warning";
                                                    displayStatus = "Chờ duyệt";
                                                } else if ("APPROVED".equals(r.getStatus())) {
                                                    if (r.getCancelRequestedAt() != null) {
                                                        statusBadge = "bg-warning text-warning";
                                                        displayStatus = "Chờ hủy";
                                                    } else {
                                                        statusBadge = "bg-info text-info";
                                                        displayStatus = "Đã duyệt";
                                                    }
                                                } else if ("PARTIALLY_COMPLETED".equals(r.getStatus())) {
                                                    statusBadge = "bg-primary text-primary";
                                                    displayStatus = "Đang xuất dở";
                                                } else if ("REJECTED".equals(r.getStatus())) {
                                                    statusBadge = "bg-danger text-danger";
                                                    displayStatus = "Từ chối";
                                                } else if ("COMPLETED".equals(r.getStatus())) {
                                                    statusBadge = "bg-success text-success";
                                                    displayStatus = "Hoàn thành";
                                                } else if ("CANCELLED".equals(r.getStatus())) {
                                                    statusBadge = "bg-secondary text-secondary";
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
                                        <td><%= r.getExpectedDate() %></td>
                                        <td><%= r.getStaffFullName() %></td>
                                        <td>
                                            <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayStatus %></span>
                                        </td>
                                        <td class="text-muted small"><%= r.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="export-request?action=detail&id=<%= r.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                    <i class="bi bi-eye"></i> Chi tiết
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
                                        <td colspan="8" class="text-center py-5 text-muted">
                                            <i class="bi bi-inbox display-6 d-block mb-2 text-muted bg-opacity-10"></i>
                                            Không tìm thấy yêu cầu xuất kho nào.
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
            const dateFilter = document.getElementById("dateFilter");
            const statusFilter = document.getElementById("statusFilter");
            const creatorFilter = document.getElementById("creatorFilter");
            const select = document.getElementById("entriesPerPage");
            const container = document.getElementById("paginationContainer");

            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            let filteredRows = [...allRows];

            function filterAndPaginate() {
                const searchVal = searchInput.value.toLowerCase().trim();
                const dateVal = dateFilter.value;
                const statusVal = statusFilter.value;
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
                    if (dateVal && !createdAt.startsWith(dateVal)) return false;
                    if (statusVal && status !== statusVal) return false;
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
                    tbody.innerHTML = `<tr><td colspan="8" class="text-center py-5 text-muted"><i class="bi bi-search display-6 d-block mb-2"></i>Không tìm thấy bản ghi phù hợp.</td></tr>`;
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

            searchInput.addEventListener("input", () => { currentPage = 1; filterAndPaginate(); });
            dateFilter.addEventListener("change", () => { currentPage = 1; filterAndPaginate(); });
            statusFilter.addEventListener("change", () => { currentPage = 1; filterAndPaginate(); });
            creatorFilter.addEventListener("input", () => { currentPage = 1; filterAndPaginate(); });

            filterAndPaginate();
        }
    </script>
</body>
</html>
