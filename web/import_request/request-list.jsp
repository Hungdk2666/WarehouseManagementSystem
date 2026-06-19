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

                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Yêu cầu nhập kho</h2>
                        <p class="text-muted small mb-0">Quản lý yêu cầu nhập hàng từ nhà cung cấp</p>
                    </div>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-receipt me-2"></i>Danh sách Yêu cầu nhập kho</h5>
                        <% if (canAdd) { %>
                        <a href="<%= request.getContextPath() %>/warehouse/import-request?action=add" class="btn btn-primary btn-sm d-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Tạo Yêu cầu nhập kho
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="px-4 pt-4 pb-2">
                            <div class="row g-3 align-items-end">
                                <div class="col-md-3">
                                    <label for="reqSearch" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-search me-1"></i>Tìm kiếm</label>
                                    <input type="text" id="reqSearch" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Mã, nhà cung cấp, người tạo...">
                                </div>
                                <div class="col-md-3">
                                    <label for="dateFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-calendar3 me-1"></i>Ngày tạo</label>
                                    <input type="date" id="dateFilter" class="form-control form-control-sm shadow-sm rounded-3">
                                </div>
                                <div class="col-md-3">
                                    <label for="statusFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-tag-fill me-1"></i>Trạng thái</label>
                                    <select id="statusFilter" class="form-select form-select-sm shadow-sm rounded-3">
                                        <option value="">-- Tất cả --</option>
                                        <option value="Chờ duyệt">Chờ duyệt</option>
                                        <option value="Đã duyệt">Đã duyệt</option>
                                        <option value="Chờ hủy">Chờ hủy</option>
                                        <option value="Từ chối">Từ chối</option>
                                        <option value="Hoàn thành">Hoàn thành</option>
                                        <option value="Đã hủy">Đã hủy</option>
                                    </select>
                                </div>
                                <div class="col-md-3">
                                    <label for="typeFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-funnel me-1"></i>Loại</label>
                                    <select id="typeFilter" class="form-select form-select-sm shadow-sm rounded-3">
                                        <option value="">-- Tất cả --</option>
                                        <option value="MUA HÀNG">MUA HÀNG</option>
                                        <option value="TRẢ HÀNG">TRẢ HÀNG</option>
                                    </select>
                                </div>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table id="reqTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
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
                                        <td><span class="badge <%= statusBadge %> bg-opacity-10 px-2 py-1"><%= displayStatus %></span></td>
                                        <td class="text-muted small"><%= r.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="<%= request.getContextPath() %>/warehouse/import-request?action=detail&id=<%= r.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2">
                                                    <i class="bi bi-eye"></i> Chi tiết
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
                                                <form action="<%= request.getContextPath() %>/warehouse/import-request?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Hủy Import Request này?')">
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
                                        <td colspan="8" class="text-center text-muted py-5">
                                            <i class="bi bi-receipt text-muted display-4 d-block mb-3"></i>
                                            Không có Yêu cầu nhập kho nào.
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-top-0 d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 bg-light rounded-bottom-3 gap-3">
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
            const dateFilter   = document.getElementById("dateFilter");
            const statusFilter = document.getElementById("statusFilter");
            const typeFilter   = document.getElementById("typeFilter");

            let currentPage = 1;
            let pageSize = 10;
            let filteredRows = allRows;

            function filterAndPaginate() {
                const q      = searchInput.value.toLowerCase();
                const date   = dateFilter.value;
                const status = statusFilter.value;
                const type   = typeFilter.value;

                filteredRows = allRows.filter(row => {
                    if (row.cells.length < 7) return false;
                    const code    = row.cells[0].textContent.toLowerCase();
                    const typeVal = row.cells[1].textContent.trim();
                    const ref     = row.cells[2].textContent.toLowerCase();
                    const creator = row.cells[4].textContent.toLowerCase();
                    const stat    = row.cells[5].textContent.trim();
                    const created = row.cells[6].textContent.trim().split(" ")[0];

                    return (!q || code.includes(q) || ref.includes(q) || creator.includes(q)) &&
                           (!date || created === date) &&
                           (!status || stat === status) &&
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
            [searchInput, dateFilter, statusFilter, typeFilter].forEach(el => el.addEventListener(el.tagName==="SELECT"?"change":"input", () => { currentPage=1; filterAndPaginate(); }));
            filterAndPaginate();
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
