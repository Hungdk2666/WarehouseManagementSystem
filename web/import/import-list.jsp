<%@page import="model.ImportTicket"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("IMPORT_TICKET_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<ImportTicket> ticketList = (List<ImportTicket>) request.getAttribute("ticketList");
    boolean canAdd = loggedInUser.hasPermission("IMPORT_TICKET_ADD");
    boolean canConfirm = loggedInUser.hasPermission("IMPORT_TICKET_CONFIRM");
    boolean canCancel = loggedInUser.hasPermission("IMPORT_TICKET_CANCEL");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Import Tickets - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Import Tickets</h2>
                        <p class="text-muted small mb-0">Record and confirm physical inbound stock deliveries</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back
                    </a>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-arrow-in-down me-2"></i>Import Tickets Registry</h5>
                        <% if (canAdd) { %>
                        <a href="import?action=add" class="btn btn-primary btn-sm d-flex align-items-center gap-1">
                            <i class="bi bi-plus-circle-fill"></i> Create Import Ticket
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="px-4 pt-4 pb-2">
                            <div class="row g-3 align-items-end">
                                <!-- Search Bar -->
                                <div class="col-md-3">
                                    <label for="importSearch" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-search me-1"></i>Search Text</label>
                                    <input type="text" id="importSearch" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Ticket, PO code, keeper..." style="box-shadow: none; font-size: 0.85rem;">
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
                                        <option value="DRAFT">DRAFT</option>
                                        <option value="CONFIRMED">CONFIRMED</option>
                                        <option value="CANCELLED">CANCELLED</option>
                                    </select>
                                </div>
                                <!-- Keeper Filter -->
                                <div class="col-md-3">
                                    <label for="keeperFilter" class="form-label small fw-semibold text-muted mb-1"><i class="bi bi-person-fill me-1"></i>Keeper (Staff)</label>
                                    <input type="text" id="keeperFilter" list="keeperDatalist" class="form-control form-control-sm shadow-sm rounded-3" placeholder="Type or select..." style="box-shadow: none; font-size: 0.85rem;">
                                    <datalist id="keeperDatalist"></datalist>
                                </div>
                            </div>
                        </div>
                        <div class="table-responsive">
                            <table id="grnTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th>Ticket Code</th>
                                        <th>Linked PO</th>
                                        <th>Supplier</th>
                                        <th>Status</th>
                                        <th>Keeper (Staff)</th>
                                        <th>Created At</th>
                                        <th>Confirmed By</th>
                                        <th>Confirmed At</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (ticketList != null && !ticketList.isEmpty()) {
                                            for (ImportTicket t : ticketList) {
                                                String statusBadge = "bg-secondary text-secondary";
                                                if ("DRAFT".equals(t.getStatus())) statusBadge = "bg-warning text-warning";
                                                else if ("CONFIRMED".equals(t.getStatus())) statusBadge = "bg-success text-success";
                                                else if ("CANCELLED".equals(t.getStatus())) statusBadge = "bg-secondary text-secondary";
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800">#<%= t.getTicketCode() %></td>
                                        <td class="fw-bold text-primary">#<%= t.getRequestCode() %></td>
                                        <td class="text-start ps-3 fw-semibold"><%= t.getSupplierName() != null ? t.getSupplierName() : "-" %></td>
                                        <td>
                                            <span class="badge <%= statusBadge %> bg-opacity-10 px-2.5 py-1.5"><%= t.getStatus() %></span>
                                        </td>
                                        <td><%= t.getKeeperFullName() %></td>
                                        <td class="text-muted small"><%= t.getCreatedAt() %></td>
                                        <td><%= t.getConfirmedByFullName() != null ? t.getConfirmedByFullName() : "-" %></td>
                                        <td class="text-muted small"><%= t.getConfirmedAt() != null ? t.getConfirmedAt() : "-" %></td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="import?action=detail&id=<%= t.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                    <i class="bi bi-eye"></i> Details
                                                </a>
                                                <% if (canConfirm && "DRAFT".equals(t.getStatus())) { %>
                                                <form action="import?action=confirm" method="POST" class="d-inline m-0" onsubmit="return confirm('Confirming this Import Ticket will update product quantities, dynamic average costs, and register inventory ledger transactions. Proceed?');">
                                                    <input type="hidden" name="id" value="<%= t.getId() %>">
                                                    <button type="submit" class="btn btn-sm btn-success d-inline-flex align-items-center gap-1 py-1 px-2.5">
                                                        <i class="bi bi-check-circle"></i> Confirm
                                                    </button>
                                                </form>
                                                <% } %>
                                                <% if (canCancel && "DRAFT".equals(t.getStatus())) { %>
                                                <form action="import?action=cancel" method="POST" class="d-inline m-0" onsubmit="return confirm('Are you sure you want to cancel this Import Ticket?');">
                                                    <input type="hidden" name="id" value="<%= t.getId() %>">
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
                                        <td colspan="9" class="text-center text-muted py-5">
                                            <i class="bi bi-box-arrow-in-down text-muted display-4 d-block mb-3"></i>
                                            No Import Tickets found.
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
            initPaginationAndFilter("grnTable", "paginationContainer", "entriesPerPage", "importSearch", "dateFilter", "statusFilter", "keeperFilter");
        });

        function initPaginationAndFilter(tableId, containerId, selectId, searchInputId, dateFilterId, statusFilterId, keeperFilterId) {
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
            const keeperFilter = document.getElementById(keeperFilterId);
            if (!container || !select) return;
            
            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            let filteredRows = allRows;

            // Dynamically populate Keeper list filter
            if (keeperFilter) {
                const keepers = new Set();
                allRows.forEach(row => {
                    if (row.cells.length > 4) {
                        const kText = row.cells[4].textContent.trim();
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
                const selectedKeeper = keeperFilter ? keeperFilter.value.trim() : "";
                
                filteredRows = allRows.filter(row => {
                    if (row.cells.length < 6) return false;
                    
                    // 1. Text Search (Matches Ticket Code, Linked PO Code, Supplier, Keeper)
                    const ticketCode = row.cells[0].textContent.toLowerCase();
                    const poCode = row.cells[1].textContent.toLowerCase();
                    const supplier = row.cells[2].textContent.toLowerCase();
                    const keeper = row.cells[4].textContent.toLowerCase();
                    const matchesSearch = searchQuery === "" || 
                                          ticketCode.includes(searchQuery) || 
                                          poCode.includes(searchQuery) || 
                                          supplier.includes(searchQuery) || 
                                          keeper.includes(searchQuery);

                    // 2. Date Filter (Matches Created At date part: YYYY-MM-DD)
                    const createdAtText = row.cells[5].textContent.trim();
                    const createdAtDatePart = createdAtText.split(" ")[0]; // Get 'YYYY-MM-DD'
                    const matchesDate = selectedDate === "" || createdAtDatePart === selectedDate;

                    // 3. Status Filter (Matches Status)
                    const status = row.cells[3].textContent.trim();
                    const matchesStatus = selectedStatus === "" || status === selectedStatus;

                    // 4. Keeper Filter (Matches Keeper)
                    const keeperText = row.cells[4].textContent.trim();
                    const matchesKeeper = selectedKeeper === "" || keeperText.toLowerCase().includes(selectedKeeper.toLowerCase());

                    return matchesSearch && matchesDate && matchesStatus && matchesKeeper;
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
                    container.innerHTML = "<span class='text-muted small'>No matching entries found</span>";
                    return;
                }
                
                const infoSpan = document.createElement("span");
                infoSpan.className = "text-muted small";
                const startIdx = (currentPage - 1) * pageSize + 1;
                const endIdx = Math.min(currentPage * pageSize, totalRows);
                infoSpan.textContent = "Showing " + startIdx + " to " + endIdx + " of " + totalRows + " entries (filtered from " + allRows.length + " total)";
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
