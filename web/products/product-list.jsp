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
                
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Danh mục sản phẩm</h2>
                        <p class="page-subtitle">Theo dõi tồn kho khả dụng và thông số kỹ thuật chi tiết của các sản phẩm</p>
                    </div>
                    <div class="d-flex gap-2">
                        <% if (canAdd) { %>
                        <a href="product?action=add" class="btn btn-primary d-inline-flex align-items-center gap-1.5">
                            <i class="bi bi-plus-circle-fill"></i> Thêm sản phẩm mới
                        </a>
                        <% } %>
                    </div>
                </div>

                <!-- Searching & Filtering Panel -->
                <div class="card mb-3">
                    <div class="card-body py-3">
                    <form action="product" method="GET" class="row g-2">
                        <input type="hidden" name="action" value="list">
                        
                        <div class="<%= loggedInUser.getWarehouseId() == null ? "col-md-3" : "col-md-4" %>">
                            <label for="search" class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                            <input type="text" class="form-control form-control-sm" id="search" name="search" value="<%= searchVal != null ? searchVal : "" %>" placeholder="Nhập mã SKU hoặc tên...">
                        </div>

                        <% if (loggedInUser.getWarehouseId() == null) { %>
                        <div class="col-md-2">
                            <label for="warehouseId" class="form-label small fw-semibold mb-1">Lọc theo Kho</label>
                            <select class="form-select form-select-sm" id="warehouseId" name="warehouseId">
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

                        <div class="col-md-2">
                            <label for="categoryId" class="form-label small fw-semibold mb-1">Danh mục</label>
                            <select class="form-select form-select-sm" id="categoryId" name="categoryId">
                                <option value="">Tất cả</option>
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

                        <div class="col-md-2">
                            <label for="brandId" class="form-label small fw-semibold mb-1">Thương hiệu</label>
                            <select class="form-select form-select-sm" id="brandId" name="brandId">
                                <option value="">Tất cả</option>
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

                        <div class="col-md-3 d-flex align-items-end gap-1">
                            <button type="submit" class="btn btn-primary btn-sm px-3"><i class="bi bi-funnel-fill me-1"></i>Lọc</button>
                            <a href="product?action=list" class="btn btn-outline-secondary btn-sm" title="Làm mới"><i class="bi bi-arrow-counterclockwise"></i></a>
                            <a href="<%= request.getContextPath() %>/warehouse/inventory" class="btn btn-outline-info btn-sm" title="Tồn kho riêng"><i class="bi bi-clipboard-data"></i> Tồn kho</a>
                        </div>
                    </form>
                    </div>
                </div>

                <!-- Product List Card -->
                <div class="card mb-4">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-box-seam-fill me-2 text-primary"></i>Danh sách sản phẩm</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="productTable" class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-nowrap ps-3">SKU</th>
                                        <th class="text-nowrap" style="width: 30%; min-width: 220px;">Tên sản phẩm</th>
                                        <th class="text-nowrap">Danh mục</th>
                                        <th class="text-nowrap">Thương hiệu</th>
                                        <th class="text-nowrap">Đơn vị</th>
                                        <th class="text-nowrap text-center">Mức tồn tối thiểu</th>
                                        <th class="text-nowrap text-end">Giá vốn trung bình</th>
                                        <th class="text-nowrap">Trạng thái</th>
                                        <th class="text-nowrap text-center">Thao tác</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (productList != null && !productList.isEmpty()) {
                                            for (Product p : productList) {
                                    %>
                                    <tr>
                                        <td class="fw-bold text-slate-800 text-nowrap ps-3"><%= p.getSku() %></td>
                                        <td class="fw-bold text-slate-800"><%= p.getProductName() %></td>
                                        <td class="text-nowrap"><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= p.getCategoryName() != null ? p.getCategoryName() : "Chưa phân loại" %></span></td>
                                        <td class="text-nowrap"><span class="badge bg-secondary bg-opacity-10 text-secondary"><%= p.getBrandName() != null ? p.getBrandName() : "Chưa phân loại" %></span></td>
                                        <td class="text-muted text-nowrap"><%= p.getUnit() %></td>
                                        <td class="text-nowrap text-muted small text-center">
                                            <i class="bi bi-shield-check"></i> <%= p.getMinStock() %> <%= p.getUnit() %>
                                        </td>
                                        <td class="fw-bold text-slate-800 text-nowrap text-end"><%= String.format("%,.0f đ", p.getAverageCost()) %></td>
                                        <td class="text-nowrap">
                                            <% if (p.isStatus()) { %>
                                                <span class="status-chip chip-success">Hoạt động</span>
                                            <% } else { %>
                                                <span class="status-chip chip-muted">Ngừng hoạt động</span>
                                            <% } %>
                                        </td>
                                        <td class="text-nowrap text-center">
                                            <div class="d-flex align-items-center justify-content-center gap-1.5">
                                                <a href="product?action=details&id=<%= p.getId() %>" class="btn btn-table btn-outline-secondary" title="Chi tiết" data-bs-toggle="tooltip">
                                                    <i class="bi bi-eye"></i>
                                                </a>
                                                <% if (canEdit) { %>
                                                <a href="product?action=update&id=<%= p.getId() %>" class="btn btn-table btn-outline-primary" title="Sửa" data-bs-toggle="tooltip">
                                                    <i class="bi bi-pencil-square"></i>
                                                </a>
                                                <% } %>
                                                <% if (canToggle) { %>
                                                <form action="product?action=toggle" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= p.getId() %>">
                                                    <button type="submit" class="btn btn-table <%= p.isStatus() ? "btn-outline-danger" : "btn-outline-success" %>" title="<%= p.isStatus() ? "Vô hiệu hóa" : "Kích hoạt" %>" data-bs-toggle="tooltip">
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
                                        <td colspan="9" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Không tìm thấy sản phẩm nào khớp với bộ lọc trong cơ sở dữ liệu.</p>
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
