<%@page import="model.Brand"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("BRAND_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Brand> brandList = (List<Brand>) request.getAttribute("brandList");
    boolean canAdd = loggedInUser.hasPermission("BRAND_ADD");
    boolean canEdit = loggedInUser.hasPermission("BRAND_EDIT");
    boolean canToggle = loggedInUser.hasPermission("BRAND_TOGGLE");
    boolean canManage = canEdit || canToggle;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Brand Directory - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Product Brands</h2>
                        <p class="text-muted small mb-0">Manage manufacturer brands and companies</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back
                    </a>
                </div>

                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-award-fill me-2"></i>Brands Directory</h5>
                        <% if (canAdd) { %>
                        <a class="btn btn-primary btn-sm d-flex align-items-center gap-1.5" href="brand?action=add">
                            <i class="bi bi-plus-circle-fill"></i> Add Brand
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="brandTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Brand Name</th>
                                        <th>Description</th>
                                        <th>Status</th>
                                        <% if (canManage) { %>
                                        <th>Actions</th>
                                        <% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (brandList != null && !brandList.isEmpty()) {
                                            for (Brand b : brandList) {
                                    %>
                                    <tr>
                                        <td class="fw-semibold text-muted">#<%= b.getId() %></td>
                                        <td class="fw-bold text-slate-800 text-start ps-5"><%= b.getBrandName() %></td>
                                        <td class="text-muted text-start text-truncate" style="max-width: 250px;"><%= b.getDescription() != null ? b.getDescription() : "" %></td>
                                        <td>
                                            <% if (b.isStatus()) { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Active</span>
                                            <% } else { %>
                                                <span class="badge bg-secondary bg-opacity-10 text-secondary px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Inactive</span>
                                            <% } %>
                                        </td>
                                        <% if (canManage) { %>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                 <% if (canEdit) { %>
                                                 <a href="brand?action=update&id=<%= b.getId() %>" class="btn btn-sm btn-warning d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Edit">
                                                     <i class="bi bi-pencil-square"></i> Edit
                                                 </a>
                                                 <% } %>
                                                <% if (canToggle) { %>
                                                <form action="brand?action=toggle" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= b.getId() %>">
                                                    <button type="submit" class="btn btn-sm <%= b.isStatus() ? "btn-outline-danger" : "btn-primary" %> d-inline-flex align-items-center gap-1 py-1 px-2.5" title="<%= b.isStatus() ? "Disable Brand" : "Enable Brand" %>">
                                                        <i class="bi bi-power"></i> <%= b.isStatus() ? "Disable" : "Enable" %>
                                                    </button>
                                                </form>
                                                <% } %>
                                            </div>
                                        </td>
                                        <% } %>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="<%= canManage ? 5 : 4 %>" class="text-center text-muted py-5">
                                            <i class="bi bi-award text-muted display-4 d-block mb-3"></i>
                                            No brands registered in the database.
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
                            <!-- Dynamically populated entries info & pagination list -->
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script>
        document.addEventListener("DOMContentLoaded", function() {
            initPagination("brandTable", "paginationContainer", "entriesPerPage");
        });

        function initPagination(tableId, containerId, selectId) {
            const table = document.getElementById(tableId);
            if (!table) return;
            const tbody = table.querySelector("tbody");
            if (!tbody) return;
            
            const rows = Array.from(tbody.querySelectorAll("tr"));
            if (rows.length === 1 && rows[0].querySelector("td[colspan]")) {
                return; // No pagination for empty data
            }
            
            const container = document.getElementById(containerId);
            const select = document.getElementById(selectId);
            if (!container || !select) return;
            
            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            
            function updateTable() {
                const totalRows = rows.length;
                const totalPages = Math.ceil(totalRows / pageSize);
                
                if (currentPage > totalPages) currentPage = Math.max(1, totalPages);
                
                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, totalRows);
                
                rows.forEach((row, index) => {
                    if (index >= start && index < end) {
                        row.style.display = "";
                    } else {
                        row.style.display = "none";
                    }
                });
                
                renderControls(totalRows, totalPages);
            }
            
            function renderControls(totalRows, totalPages) {
                container.innerHTML = "";
                
                const start = totalRows === 0 ? 0 : (currentPage - 1) * pageSize + 1;
                const end = Math.min(start + pageSize - 1, totalRows);
                
                const infoDiv = document.createElement("div");
                infoDiv.className = "text-muted small my-2 my-sm-0";
                infoDiv.textContent = "Showing " + start + " to " + end + " of " + totalRows + " entries";
                container.appendChild(infoDiv);
                
                const nav = document.createElement("nav");
                const ul = document.createElement("ul");
                ul.className = "pagination pagination-sm mb-0 gap-1";
                
                const prevLi = document.createElement("li");
                prevLi.className = "page-item " + (currentPage === 1 ? "disabled" : "");
                const prevBtn = document.createElement("a");
                prevBtn.className = "page-link border-0 rounded-2 shadow-none px-2.5 py-1.5";
                prevBtn.href = "javascript:void(0)";
                prevBtn.innerHTML = '<i class="bi bi-chevron-left"></i>';
                prevBtn.addEventListener("click", () => {
                    if (currentPage > 1) {
                        currentPage--;
                        updateTable();
                    }
                });
                prevLi.appendChild(prevBtn);
                ul.appendChild(prevLi);
                
                let startPage = Math.max(1, currentPage - 2);
                let endPage = Math.min(totalPages, startPage + 4);
                if (endPage - startPage < 4) {
                    startPage = Math.max(1, endPage - 4);
                }
                
                for (let i = startPage; i <= endPage; i++) {
                    const li = document.createElement("li");
                    li.className = "page-item " + (currentPage === i ? "active" : "");
                    const btn = document.createElement("a");
                    btn.className = "page-link border-0 rounded-2 shadow-none px-3 py-1.5";
                    btn.href = "javascript:void(0)";
                    btn.textContent = i;
                    btn.addEventListener("click", () => {
                        currentPage = i;
                        updateTable();
                    });
                    li.appendChild(btn);
                    ul.appendChild(li);
                }
                
                const nextLi = document.createElement("li");
                nextLi.className = "page-item " + (currentPage === totalPages || totalPages === 0 ? "disabled" : "");
                const nextBtn = document.createElement("a");
                nextBtn.className = "page-link border-0 rounded-2 shadow-none px-2.5 py-1.5";
                nextBtn.href = "javascript:void(0)";
                nextBtn.innerHTML = '<i class="bi bi-chevron-right"></i>';
                nextBtn.addEventListener("click", () => {
                    if (currentPage < totalPages) {
                        currentPage++;
                        updateTable();
                    }
                });
                nextLi.appendChild(nextBtn);
                ul.appendChild(nextLi);
                
                nav.appendChild(ul);
                container.appendChild(nav);
            }
            
            select.addEventListener("change", () => {
                pageSize = parseInt(select.value) || 10;
                currentPage = 1;
                updateTable();
            });
            
            updateTable();
        }
    </script>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
