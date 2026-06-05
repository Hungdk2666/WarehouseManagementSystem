<%@page import="model.ImportRequest"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("PO_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<ImportRequest> poList = (List<ImportRequest>) request.getAttribute("poList");
    boolean canAdd = loggedInUser.hasPermission("PO_ADD");
    boolean canApprove = loggedInUser.hasPermission("PO_APPROVE");
    boolean canCancel = loggedInUser.hasPermission("PO_CANCEL");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Purchase Orders - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Purchase Orders</h2>
                        <p class="text-muted small mb-0">Manage incoming supplier purchase agreements</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back
                    </a>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-receipt me-2"></i>POs Registry</h5>
                        <% if (canAdd) { %>
                        <a href="po?action=add" class="btn btn-primary btn-sm d-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Create PO
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="px-4 pt-4 pb-2">
                            <div class="row g-3 align-items-end">
                                <!-- Search Bar -->
                                <div class="col-md-3">
                                    <label for="poSearch" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-search me-1"></i>Search Text</label>
                                    <input type="text" id="poSearch" class="form-control form-control-sm shadow-sm rounded-3" placeholder="PO code, supplier, creator..." style="box-shadow: none; font-size: 0.85rem;">
                                </div>
                                <!-- Date Filter -->
                                <div class="col-md-3">
                                    <label for="dateFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-calendar3 me-1"></i>Created Date</label>
                                    <input type="date" id="dateFilter" class="form-control form-control-sm shadow-sm rounded-3" style="box-shadow: none; font-size: 0.85rem;">
                                </div>
                                <!-- Status Filter -->
                                <div class="col-md-3">
                                    <label for="statusFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-tag-fill me-1"></i>Status</label>
                                    <select id="statusFilter" class="form-select form-select-sm shadow-sm rounded-3" style="box-shadow: none; font-size: 0.85rem;">
                                        <option value="">-- All Statuses --</option>
                                        <option value="PENDING">PENDING</option>
                                        <option value="APPROVED">APPROVED</option>
                                        <option value="PENDING CANCEL">PENDING CANCEL</option>
                                        <option value="REJECTED">REJECTED</option>
                                        <option value="COMPLETED">COMPLETED</option>
                                        <option value="CANCELLED">CANCELLED</option>
                                    </select>
                                </div>
                                <!-- Creator Filter -->
                                <div class="col-md-3">
                                    <label for="creatorFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-person-fill me-1"></i>Creator</label>
                                    <input type="text" id="creatorFilter" list="creatorDatalist" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Type or select..." style="box-shadow: none; font-size: 0.85rem;">
                                    <datalist id="creatorDatalist"></datalist>
                                </div>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table id="poTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th>Code</th>
                                        <th>Supplier</th>
                                        <th>Expected Date</th>
                                        <th>Created By</th>
                                        <th>Status</th>
                                        <th>Created At</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (poList != null && !poList.isEmpty()) {
                                            for (ImportRequest r : poList) {
                                                String statusBadge = "bg-secondary text-secondary";
                                                String displayStatus = r.getStatus();
                                                if ("PENDING".equals(r.getStatus())) {
                                                    statusBadge = "bg-warning text-warning";
                                                } else if ("APPROVED".equals(r.getStatus())) {
                                                    if (r.getCancelRequestedAt() != null) {
                                                        statusBadge = "bg-warning text-warning";
                                                        displayStatus = "PENDING CANCEL";
                                                    } else {
                                                        statusBadge = "bg-info text-info";
                                                    }
                                                } else if ("REJECTED".equals(r.getStatus())) {
                                                    statusBadge = "bg-danger text-danger";
                                                } else if ("COMPLETED".equals(r.getStatus())) {
                                                    statusBadge = "bg-success text-success";
                                                } else if ("CANCELLED".equals(r.getStatus())) {
                                                    statusBadge = "bg-secondary text-secondary";
                                                }
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= r.getRequestCode() %></td>
                                        <td class="text-start ps-3 fw-semibold"><%= r.getSupplierName() %></td>
                                        <td><%= r.getExpectedDate() %></td>
                                        <td><%= r.getCreatorFullName() %></td>
                                        <td>
                                            <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= displayStatus %></span>
                                        </td>
                                        <td class="text-muted small"><%= r.getCreatedAt() %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="po?action=detail&id=<%= r.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                    <i class="bi bi-eye"></i> Details
                                                </a>
                                                <% if (canApprove && "PENDING".equals(r.getStatus())) { %>
                                                <form action="po?action=approve" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-success d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-check-circle"></i> Approve
                                                    </button>
                                                </form>
                                                <form action="po?action=reject" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-danger d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-x-circle"></i> Reject
                                                    </button>
                                                </form>
                                                <% } %>
                                                <% if (canCancel && "PENDING".equals(r.getStatus())) { %>
                                                <form action="po?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Are you sure you want to cancel this Purchase Order?');">
                                                    <input type="hidden" name="id" value="<%= r.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-slash-circle"></i> Cancel
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
                                        <td colspan="7" class="text-center text-muted py-5">
                                            <i class="bi bi-receipt text-muted display-4 d-block mb-3"></i>
                                            No Purchase Orders found.
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <div class="card-footer bg-transparent border-top-0 d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 bg-light rounded-bottom-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                            <label class="text-muted small mb-0 flex-shrink-0">Show</label>
                            <select id="entriesPerPage" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;">
                                <option value="10" selected>10</option>
                                <option value="25">25</option>
                                <option value="100">100</option>
                            </select>
                            <span class="text-muted small">entries</span>
                        </div>
                        <div id="paginationContainer" class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto">
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>
    
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            initPagination("poTable", "paginationContainer", "entriesPerPage");
        });

        function initPagination(tableId, containerId, selectId) {
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
            if (!container || !select) return;

            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;

            function paginate() {
                allRows.forEach(row => row.style.display = "none");

                const totalRows = allRows.length;
                const totalPages = Math.ceil(totalRows / pageSize);

                if (currentPage > totalPages) currentPage = Math.max(1, totalPages);

                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, totalRows);

                for (let i = start; i < end; i++) {
                    allRows[i].style.display = "";
                }

                renderPaginationControls(totalPages, totalRows);
            }

            function renderPaginationControls(totalPages, totalRows) {
                container.innerHTML = "";

                const infoSpan = document.createElement("span");
                infoSpan.className = "text-muted small";
                const startIdx = (currentPage - 1) * pageSize + 1;
                const endIdx = Math.min(currentPage * pageSize, totalRows);
                infoSpan.textContent = "Showing " + startIdx + " to " + endIdx + " of " + totalRows + " entries";
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
                        paginate();
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
                        paginate();
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
                        paginate();
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
                paginate();
            });

            paginate();
        }
    </script>
</body>
</html>
