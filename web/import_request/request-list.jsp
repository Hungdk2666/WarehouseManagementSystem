<%@page import="model.Request"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("REQUEST_VIEW_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Request> requestList = (List<Request>) request.getAttribute("requestList");
    boolean canAdd     = loggedInUser.hasPermission("REQUEST_ADD_IN");
    boolean canApprove = loggedInUser.hasPermission("REQUEST_APPROVE_IN");
    boolean canCancel  = loggedInUser.hasPermission("REQUEST_CANCEL_IN");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Yêu cầu nhập kho - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
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
                        <h2 class="page-title">Yêu cầu nhập kho</h2>
                        <p class="page-subtitle">Quản lý yêu cầu nhập hàng từ nhà cung cấp</p>
                    </div>
                </div>

                <!-- Filters -->
                <div class="card mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-12 col-md-3">
                                <label for="reqSearch" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" id="reqSearch" class="form-control form-control-sm" placeholder="Mã, nhà cung cấp, người tạo...">
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
                                    <button type="button" id="statusDropdownBtn" class="btn btn-outline-secondary btn-sm dropdown-toggle w-100 text-start fw-normal"
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
                                <label for="typeFilter" class="form-label small fw-semibold mb-1">Loại</label>
                                <select id="typeFilter" class="form-select form-select-sm">
                                    <option value="">-- Tất cả --</option>
                                    <option value="MUA HÀNG">MUA HÀNG</option>
                                    <option value="TRẢ HÀNG">TRẢ HÀNG</option>
                                </select>
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

                <div class="card mb-4">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-receipt me-2 text-primary"></i>Danh sách Yêu cầu nhập kho</span>
                        <% if (canAdd) { %>
                        <a href="<%= request.getContextPath() %>/warehouse/import-request?action=add" class="btn btn-primary btn-sm d-inline-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Tạo Yêu cầu nhập kho
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="reqTable" class="table table-hover align-middle text-center mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th>Mã</th>
                                        <th>Loại</th>
                                        <th>Nhà cung cấp / Phiếu tham chiếu</th>
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
                                                String typeBadge = "RETURN".equals(r.getReason()) ? "bg-warning text-warning" : "bg-info text-info";
                                                String displayType = "RETURN".equals(r.getReason()) ? "TRẢ HÀNG" : "MUA HÀNG";
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= r.getRequestCode() %></td>
                                        <td><span class="badge <%= typeBadge %> bg-opacity-10"><%= displayType %></span></td>
                                        <td class="text-start ps-3 fw-semibold">
                                            <%= r.getPartnerName() != null ? r.getPartnerName() : (r.getRefTicketId() != null ? "Tham chiếu: Phiếu #" + r.getRefTicketId() : "-") %>
                                        </td>
                                        <td><%= r.getExpectedDate() %></td>
                                        <td><%= r.getStaffFullName() %></td>
                                        <td><span class="status-chip <%= statusBadge %>"><%= displayStatus %></span></td>
                                        <td class="text-muted small"><%= r.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="<%= request.getContextPath() %>/warehouse/import-request?action=detail&id=<%= r.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết" aria-label="Xem chi tiết yêu cầu nhập">
                                                    <i class="bi bi-eye" aria-hidden="true"></i>
                                                </a>
                                                <% if (canApprove && "PENDING".equals(r.getStatus())) { %>
                                                <form action="<%= request.getContextPath() %>/warehouse/import-request?action=approve" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-success d-inline-flex align-items-center gap-1 py-1 px-2"><i class="bi bi-check-circle"></i></button>
                                                </form>
                                                <form action="<%= request.getContextPath() %>/warehouse/import-request?action=reject" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-danger d-inline-flex align-items-center gap-1 py-1 px-2"><i class="bi bi-x-circle"></i></button>
                                                </form>
                                                <% } %>
                                                <% if (canCancel && "PENDING".equals(r.getStatus())) { %>
                                                <form action="<%= request.getContextPath() %>/warehouse/import-request?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Hủy Yêu cầu nhập kho này?')">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger py-1 px-2"><i class="bi bi-slash-circle"></i></button>
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
                                                <p>Không có Yêu cầu nhập kho nào.</p>
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
                            <label class="text-muted small mb-0">Hiển thị</label>
                            <select id="entriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;">
                                <option value="10" selected>10</option>
                                <option value="25">25</option>
                                <option value="100">100</option>
                            </select>
                            <span class="text-muted small">bản ghi</span>
                        </div>
                        <div id="paginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto"></div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const table = document.getElementById("reqTable");
            const tbody = table.querySelector("tbody");
            const allRows = Array.from(tbody.querySelectorAll("tr"));
            if (allRows.length === 1 && allRows[0].querySelector("td[colspan]")) return;

            const container = document.getElementById("paginationContainer");
            const selectEl  = document.getElementById("entriesPerPage");
            const searchInput  = document.getElementById("reqSearch");
            const startDateFilter   = document.getElementById("startDateFilter");
            const endDateFilter   = document.getElementById("endDateFilter");
            startDateFilter.addEventListener("change", () => {
                endDateFilter.min = startDateFilter.value;
                if (endDateFilter.value && endDateFilter.value < startDateFilter.value) endDateFilter.value = startDateFilter.value;
            });
            endDateFilter.addEventListener("change", () => {
                startDateFilter.max = endDateFilter.value;
                if (startDateFilter.value && startDateFilter.value > endDateFilter.value) startDateFilter.value = endDateFilter.value;
            });
            const typeFilter   = document.getElementById("typeFilter");

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

            let currentPage = 1;
            let pageSize = 10;
            let filteredRows = allRows;

            function filterAndPaginate() {
                const q      = searchInput.value.toLowerCase();
                const startDate   = startDateFilter.value;
                const endDate     = endDateFilter.value;
                const statusVals = getSelectedStatuses();
                const type   = typeFilter.value;

                filteredRows = allRows.filter(row => {
                    if (row.cells.length < 7) return false;
                    const code    = row.cells[0].textContent.toLowerCase();
                    const typeVal = row.cells[1].textContent.trim();
                    const ref     = row.cells[2].textContent.toLowerCase();
                    const creator = row.cells[4].textContent.toLowerCase();
                    const stat    = row.cells[5].textContent.trim();
                    const created = row.cells[6].textContent.trim().split(" ")[0];

                    let matchesDate = true;
                    if (startDate && created < startDate) matchesDate = false;
                    if (endDate && created > endDate) matchesDate = false;

                    return (!q || code.includes(q) || ref.includes(q) || creator.includes(q)) &&
                           matchesDate &&
                           (statusVals.length === 0 || statusVals.includes(stat)) &&
                           (!type || typeVal.includes(type));
                });

                allRows.forEach(r => r.style.display = "none");
                const total = filteredRows.length;
                const totalPages = Math.ceil(total / pageSize) || 1;
                if (currentPage > totalPages) currentPage = totalPages;
                const start = (currentPage - 1) * pageSize;
                filteredRows.slice(start, start + pageSize).forEach(r => r.style.display = "");

                container.innerHTML = "";
                if (total === 0) { container.innerHTML = "<span class='text-muted small'>Không có kết quả</span>"; return; }
                const info = document.createElement("span");
                info.className = "text-muted small";
                info.textContent = "Hiển thị " + (start+1) + "–" + Math.min(start+pageSize, total) + " / " + total;
                container.appendChild(info);
                const nav = document.createElement("nav");
                const ul  = document.createElement("ul");
                ul.className = "pagination pagination-sm m-0";
                const mkLi = (label, page, disabled) => {
                    const li = document.createElement("li");
                    li.className = "page-item " + (disabled ? "disabled" : "") + (page === currentPage ? " active" : "");
                    const a = document.createElement("a");
                    a.className = "page-link"; a.href = "#"; a.innerHTML = label;
                    a.addEventListener("click", e => { e.preventDefault(); if (!disabled) { currentPage = page; filterAndPaginate(); } });
                    li.appendChild(a); return li;
                };
                ul.appendChild(mkLi('<i class="bi bi-chevron-left"></i>', currentPage-1, currentPage===1));
                for (let i=1; i<=totalPages; i++) ul.appendChild(mkLi(i, i, false));
                ul.appendChild(mkLi('<i class="bi bi-chevron-right"></i>', currentPage+1, currentPage===totalPages));
                nav.appendChild(ul); container.appendChild(nav);
            }

            selectEl.addEventListener("change", () => { pageSize = +selectEl.value; currentPage=1; filterAndPaginate(); });
            
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
                typeFilter.value = "";
                currentPage = 1;
                filterAndPaginate();
            });

            filterAndPaginate();
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
