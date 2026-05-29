<%@page import="model.Product"%>
<%@page import="model.Category"%>
<%@page import="model.Brand"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("PRODUCT_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Product> productList = (List<Product>) request.getAttribute("productList");
    List<Category> categoryList = (List<Category>) request.getAttribute("categoryList");
    List<Brand> brandList = (List<Brand>) request.getAttribute("brandList");
    boolean canAdd = loggedInUser.hasPermission("PRODUCT_ADD");
    boolean canEdit = loggedInUser.hasPermission("PRODUCT_EDIT");
    boolean canToggle = loggedInUser.hasPermission("PRODUCT_TOGGLE");

    // Retrieve active filter values
    String searchVal = request.getParameter("search");
    String catVal = request.getParameter("categoryId");
    String brandVal = request.getParameter("brandId");
    boolean lowStockVal = "true".equals(request.getParameter("lowStock"));
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Product Catalog - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
    <style>
        .low-stock-row {
            background-color: rgba(239, 68, 68, 0.05) !important;
        }
        .filter-card {
            border: 1px solid var(--slate-200);
            border-radius: 12px;
            box-shadow: var(--card-shadow);
        }
    </style>
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Product Catalog</h2>
                        <p class="text-muted small mb-0">Monitor active warehouse inventory and detailed technical specifications</p>
                    </div>
                    <% if (canAdd) { %>
                    <a href="product?action=add" class="btn btn-primary d-inline-flex align-items-center gap-1.5 shadow-sm">
                        <i class="bi bi-plus-circle-fill"></i> Add New Product
                    </a>
                    <% } %>
                </div>

                <!-- Searching & Filtering Panel -->
                <div class="card filter-card bg-white p-4 mb-4">
                    <form action="product" method="GET" class="row g-3 align-items-end">
                        <input type="hidden" name="action" value="list">
                        
                        <div class="col-md-3">
                            <label for="search" class="form-label small">Search SKU / Product Name</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light border-end-0 text-muted"><i class="bi bi-search"></i></span>
                                <input type="text" class="form-control border-start-0 ps-0" id="search" name="search" value="<%= searchVal != null ? searchVal : "" %>" placeholder="Enter SKU or name...">
                            </div>
                        </div>

                        <div class="col-md-3">
                            <label for="categoryId" class="form-label small">Category Filter</label>
                            <select class="form-select" id="categoryId" name="categoryId">
                                <option value="">All Categories</option>
                                <%
                                    if (categoryList != null) {
                                        for (Category c : categoryList) {
                                            String selected = String.valueOf(c.getId()).equals(catVal) ? "selected" : "";
                                %>
                                <option value="<%= c.getId() %>" <%= selected %>><%= c.getCategoryName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>

                        <div class="col-md-3">
                            <label for="brandId" class="form-label small">Brand Filter</label>
                            <select class="form-select" id="brandId" name="brandId">
                                <option value="">All Brands</option>
                                <%
                                    if (brandList != null) {
                                        for (Brand b : brandList) {
                                            String selected = String.valueOf(b.getId()).equals(brandVal) ? "selected" : "";
                                %>
                                <option value="<%= b.getId() %>" <%= selected %>><%= b.getBrandName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>

                        <div class="col-md-3 d-flex flex-column justify-content-end align-items-start">
                            <div class="form-check mb-2">
                                <input class="form-check-input" type="checkbox" id="lowStock" name="lowStock" value="true" <%= lowStockVal ? "checked" : "" %>>
                                <label class="form-check-label text-danger fw-semibold small" for="lowStock">
                                    <i class="bi bi-exclamation-triangle-fill me-1"></i> Low Stock Alerts Only
                                </label>
                            </div>
                            <div class="d-flex gap-2 w-100">
                                <button type="submit" class="btn btn-primary btn-sm flex-fill py-2"><i class="bi bi-funnel-fill me-1"></i> Apply Filters</button>
                                <a href="product?action=list" class="btn btn-outline-secondary btn-sm flex-fill py-2 text-center">Reset</a>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- Product List Card -->
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-seam-fill me-2"></i>Product Listing</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="productTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th>SKU</th>
                                        <th>Product Name</th>
                                        <th>Category</th>
                                        <th>Brand</th>
                                        <th>Unit</th>
                                        <th>Stock</th>
                                        <th>Default Cost</th>
                                        <th>Average Cost</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (productList != null && !productList.isEmpty()) {
                                            for (Product p : productList) {
                                                boolean isLowStock = p.getQuantity() <= p.getMinStock();
                                    %>
                                    <tr class="<%= isLowStock ? "low-stock-row" : "" %>">
                                        <td class="fw-bold text-primary"><%= p.getSku() %></td>
                                        <td class="fw-bold text-slate-800 text-start ps-3"><%= p.getProductName() %></td>
                                        <td><span class="badge bg-light text-dark px-2.5 py-1.5"><%= p.getCategoryName() != null ? p.getCategoryName() : "Unassigned" %></span></td>
                                        <td><span class="badge bg-light text-dark px-2.5 py-1.5"><%= p.getBrandName() != null ? p.getBrandName() : "Unassigned" %></span></td>
                                        <td class="text-muted"><%= p.getUnit() %></td>
                                        <td>
                                            <% if (isLowStock) { %>
                                                <span class="badge bg-danger bg-opacity-10 text-danger fw-bold px-2.5 py-1.5" title="Low stock warning! Safety limit: <%= p.getMinStock() %>">
                                                    <%= p.getQuantity() %> <i class="bi bi-exclamation-triangle-fill ms-1"></i>
                                                </span>
                                            <% } else { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5">
                                                    <%= p.getQuantity() %>
                                                </span>
                                            <% } %>
                                        </td>
                                        <td class="fw-semibold text-slate-700"><%= String.format("%,.0f đ", p.getDefaultCost()) %></td>
                                        <td class="fw-bold text-success-emphasis"><%= String.format("%,.0f đ", p.getAverageCost()) %></td>
                                        <td>
                                            <% if (p.isStatus()) { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Active</span>
                                            <% } else { %>
                                                <span class="badge bg-danger bg-opacity-10 text-danger px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Deactive</span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                <a href="product?action=details&id=<%= p.getId() %>" class="btn btn-sm btn-info text-white d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Details">
                                                    <i class="bi bi-eye-fill"></i> View
                                                </a>
                                                <% if (canEdit) { %>
                                                <a href="product?action=update&id=<%= p.getId() %>" class="btn btn-sm btn-warning d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Edit">
                                                    <i class="bi bi-pencil-square"></i> Edit
                                                </a>
                                                <% } %>
                                                <% if (canToggle) { %>
                                                <form action="product?action=toggle" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= p.getId() %>">
                                                    <button type="submit" class="btn btn-sm <%= p.isStatus() ? "btn-outline-danger" : "btn-primary" %> d-inline-flex align-items-center gap-1 py-1 px-2.5" title="<%= p.isStatus() ? "Deactivate Product" : "Activate Product" %>">
                                                        <i class="bi bi-power"></i> <%= p.isStatus() ? "Disable" : "Enable" %>
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
                                            <i class="bi bi-box text-muted display-4 d-block mb-3"></i>
                                            No products matching the active filters were found in the database.
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

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            initPagination("productTable", "paginationContainer", "entriesPerPage");
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
</body>
</html>
