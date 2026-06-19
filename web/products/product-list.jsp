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
    List<model.Warehouse> warehouseList = (List<model.Warehouse>) request.getAttribute("warehouseList");
    boolean canAdd = loggedInUser.hasPermission("PRODUCT_ADD");
    boolean canEdit = loggedInUser.hasPermission("PRODUCT_EDIT");
    boolean canToggle = loggedInUser.hasPermission("PRODUCT_TOGGLE");

    // Retrieve active filter values
    String searchVal = request.getParameter("search");
    String catVal = request.getParameter("categoryId");
    String brandVal = request.getParameter("brandId");
    String whVal = request.getParameter("warehouseId");
    boolean lowStockVal = "true".equals(request.getParameter("lowStock"));
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Danh mục sản phẩm - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Danh mục sản phẩm</h2>
                        <p class="text-muted small mb-0">Theo dõi tồn kho khả dụng và thông số kỹ thuật chi tiết của các sản phẩm</p>
                    </div>
                    <% if (canAdd) { %>
                    <a href="product?action=add" class="btn btn-primary d-inline-flex align-items-center gap-1.5 shadow-sm">
                        <i class="bi bi-plus-circle-fill"></i> Thêm sản phẩm mới
                    </a>
                    <% } %>
                </div>

                <!-- Searching & Filtering Panel -->
                <div class="card filter-card bg-white p-4 mb-4">
                    <form action="product" method="GET" class="row g-3 align-items-end">
                        <input type="hidden" name="action" value="list">
                        
                        <div class="<%= loggedInUser.getWarehouseId() == null ? "col-md-3" : "col-md-3" %>">
                            <label for="search" class="form-label small">Tìm SKU / Tên sản phẩm</label>
                            <div class="input-group">
                                <span class="input-group-text bg-light border-end-0 text-muted"><i class="bi bi-search"></i></span>
                                <input type="text" class="form-control border-start-0 ps-0" id="search" name="search" value="<%= searchVal != null ? searchVal : "" %>" placeholder="Nhập mã SKU hoặc tên...">
                            </div>
                        </div>

                        <% if (loggedInUser.getWarehouseId() == null) { %>
                        <div class="col-md-2">
                            <label for="warehouseId" class="form-label small">Lọc theo Kho</label>
                            <select class="form-select" id="warehouseId" name="warehouseId">
                                <option value="">Tất cả kho</option>
                                <%
                                    if (warehouseList != null) {
                                        for (model.Warehouse w : warehouseList) {
                                            String selected = String.valueOf(w.getId()).equals(whVal) ? "selected" : "";
                                %>
                                <option value="<%= w.getId() %>" <%= selected %>><%= w.getWarehouseName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>
                        <% } %>

                        <div class="<%= loggedInUser.getWarehouseId() == null ? "col-md-2" : "col-md-3" %>">
                            <label for="categoryId" class="form-label small">Lọc theo Danh mục</label>
                            <select class="form-select" id="categoryId" name="categoryId">
                                <option value="">Tất cả danh mục</option>
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

                        <div class="<%= loggedInUser.getWarehouseId() == null ? "col-md-2" : "col-md-3" %>">
                            <label for="brandId" class="form-label small">Lọc theo Thương hiệu</label>
                            <select class="form-select" id="brandId" name="brandId">
                                <option value="">Tất cả thương hiệu</option>
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

                        <div class="<%= loggedInUser.getWarehouseId() == null ? "col-md-3" : "col-md-3" %> d-flex flex-column justify-content-end align-items-start">
                            <div class="form-check mb-2">
                                <input class="form-check-input" type="checkbox" id="lowStock" name="lowStock" value="true" <%= lowStockVal ? "checked" : "" %>>
                                <label class="form-check-label text-danger fw-semibold small" for="lowStock">
                                    <i class="bi bi-exclamation-triangle-fill me-1"></i> Chỉ hiển thị cảnh báo sắp hết hàng
                                </label>
                            </div>
                            <div class="d-flex gap-2 w-100">
                                <button type="submit" class="btn btn-primary btn-sm flex-fill py-2"><i class="bi bi-funnel-fill me-1"></i> Áp dụng lọc</button>
                                <a href="product?action=list" class="btn btn-outline-secondary btn-sm flex-fill py-2 text-center">Đặt lại</a>
                            </div>
                        </div>
                    </form>
                </div>

                <!-- Product List Card -->
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-box-seam-fill me-2"></i>Danh sách sản phẩm</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="productTable" class="table table-hover align-middle text-center mb-0">
                                <thead>
                                    <tr>
                                        <th class="text-nowrap">SKU</th>
                                        <th class="text-start ps-3 text-nowrap" style="width: 30%; min-width: 220px;">Tên sản phẩm</th>
                                        <th class="text-nowrap">Danh mục</th>
                                        <th class="text-nowrap">Thương hiệu</th>
                                        <th class="text-nowrap">Đơn vị</th>
                                        <th class="text-nowrap">Tồn kho (Khả dụng / Thực tế)</th>
                                        <th class="text-nowrap">Giá vốn trung bình</th>
                                        <th class="text-nowrap">Trạng thái</th>
                                        <th class="text-nowrap">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (productList != null && !productList.isEmpty()) {
                                            for (Product p : productList) {
                                                boolean isLowStock = p.getAvailableQty() <= p.getMinStock();
                                    %>
                                    <tr class="<%= isLowStock ? "low-stock-row" : "" %>">
                                        <td class="fw-bold text-primary text-nowrap"><%= p.getSku() %></td>
                                        <td class="fw-bold text-slate-800 text-start ps-3"><%= p.getProductName() %></td>
                                        <td class="text-nowrap"><span class="badge bg-light text-dark px-2.5 py-1.5"><%= p.getCategoryName() != null ? p.getCategoryName() : "Chưa phân loại" %></span></td>
                                        <td class="text-nowrap"><span class="badge bg-light text-dark px-2.5 py-1.5"><%= p.getBrandName() != null ? p.getBrandName() : "Chưa phân loại" %></span></td>
                                        <td class="text-muted text-nowrap"><%= p.getUnit() %></td>
                                        <td class="text-nowrap">
                                            <% if (isLowStock) { %>
                                                <span class="badge bg-danger bg-opacity-10 text-danger fw-bold px-2.5 py-1.5" title="Cảnh báo sắp hết hàng! Giới hạn an toàn: <%= p.getMinStock() %>">
                                                    <%= p.getAvailableQty() %> <i class="bi bi-exclamation-triangle-fill"></i>
                                                </span>
                                            <% } else { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5">
                                                    <%= p.getAvailableQty() %>
                                                </span>
                                            <% } %>
                                            <span class="text-muted mx-1">/</span>
                                            <span class="badge bg-secondary bg-opacity-10 text-secondary px-2.5 py-1.5" title="Tồn kho thực tế trong kho">
                                                <%= p.getPhysicalQty() %>
                                            </span>
                                        </td>
                                        <td class="fw-bold text-success-emphasis text-nowrap"><%= String.format("%,.0f đ", p.getAverageCost()) %></td>
                                        <td class="text-nowrap">
                                            <% if (p.isStatus()) { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Hoạt động</span>
                                            <% } else { %>
                                                <span class="badge bg-danger bg-opacity-10 text-danger px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Ngừng hoạt động</span>
                                            <% } %>
                                        </td>
                                        <td class="text-nowrap">
                                            <div class="d-flex align-items-center justify-content-center gap-1.5">
                                                <a href="product?action=details&id=<%= p.getId() %>" class="btn btn-sm btn-outline-primary d-inline-flex align-items-center justify-content-center p-2" title="Chi tiết" data-bs-toggle="tooltip">
                                                    <i class="bi bi-eye-fill"></i>
                                                </a>
                                                <% if (canEdit) { %>
                                                <a href="product?action=update&id=<%= p.getId() %>" class="btn btn-sm btn-warning d-inline-flex align-items-center justify-content-center p-2" title="Sửa" data-bs-toggle="tooltip">
                                                    <i class="bi bi-pencil-square"></i>
                                                </a>
                                                <% } %>
                                                <% if (canToggle) { %>
                                                <form action="product?action=toggle" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= p.getId() %>">
                                                    <button type="submit" class="btn btn-sm <%= p.isStatus() ? "btn-outline-danger" : "btn-primary" %> d-inline-flex align-items-center justify-content-center p-2" title="<%= p.isStatus() ? "Vô hiệu hóa" : "Kích hoạt" %>" data-bs-toggle="tooltip">
                                                        <i class="bi bi-power"></i>
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
                                            <i class="bi bi-box text-muted display-4 d-block mb-3"></i>
                                            Không tìm thấy sản phẩm nào khớp với bộ lọc trong cơ sở dữ liệu.
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
                            <span class="text-muted small">dòng</span>
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
            
            // Initialize Bootstrap Tooltips
            const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
            const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
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
                infoDiv.textContent = "Hiển thị từ " + start + " đến " + end + " trong số " + totalRows + " dòng";
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
