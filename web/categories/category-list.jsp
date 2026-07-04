<%@page import="model.Category"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("CATEGORY_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Category> categoryList = (List<Category>) request.getAttribute("categoryList");
    boolean canAdd = loggedInUser.hasPermission("CATEGORY_ADD");
    boolean canEdit = loggedInUser.hasPermission("CATEGORY_EDIT");
    boolean canToggle = loggedInUser.hasPermission("CATEGORY_TOGGLE");
    boolean canManage = canEdit || canToggle;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Danh sách danh mục - WMS</title>
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
                
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Danh sách danh mục</h2>
                        <p class="page-subtitle">Phân loại sản phẩm trong kho lưu trữ vật lý của bạn</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                    </div>
                </div>

                <!-- Search Panel -->
                <div class="card mb-3">
                    <div class="card-body py-3">
                        <div class="row g-2">
                            <div class="col-md-4">
                                <label class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" id="categorySearchInput" class="form-control form-control-sm" placeholder="Tìm kiếm theo tên, mô tả...">
                            </div>
                            <div class="col-md-2 d-flex align-items-end gap-1">
                                <button type="button" id="filterBtn" class="btn btn-primary btn-sm px-3"><i class="bi bi-funnel-fill"></i> Lọc</button>
                                <button type="button" id="clearSearchBtn" class="btn btn-outline-secondary btn-sm" title="Làm mới"><i class="bi bi-arrow-counterclockwise"></i></button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card mb-4">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                        <span class="fw-bold text-slate-800"><i class="bi bi-tags-fill me-2 text-primary"></i>Quản lý danh mục</span>
                        <% if (canAdd) { %>
                        <a class="btn btn-primary btn-sm" href="category?action=add">
                            <i class="bi bi-plus-circle-fill"></i> Thêm danh mục
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="categoryTable" class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-center">Mã ID</th>
                                        <th>Tên danh mục</th>
                                        <th>Mô tả</th>
                                        <th class="text-center">Trạng thái</th>
                                        <% if (canManage) { %>
                                        <th class="text-center">Thao tác</th>
                                        <% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (categoryList != null && !categoryList.isEmpty()) {
                                            for (Category c : categoryList) {
                                    %>
                                    <tr>
                                        <td class="fw-semibold text-muted text-center">#<%= c.getId() %></td>
                                        <td class="fw-bold text-slate-800"><%= c.getCategoryName() %></td>
                                        <td class="text-muted text-truncate" style="max-width: 250px;"><%= c.getDescription() != null ? c.getDescription() : "" %></td>
                                        <td class="text-center">
                                            <% if (c.isStatus()) { %>
                                                <span class="status-chip chip-success">Hoạt động</span>
                                            <% } else { %>
                                                <span class="status-chip chip-muted">Không hoạt động</span>
                                            <% } %>
                                        </td>
                                        <% if (canManage) { %>
                                        <td class="text-center">
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                 <% if (canEdit) { %>
                                                 <a href="category?action=update&id=<%= c.getId() %>" class="btn btn-table btn-outline-primary" title="Chỉnh sửa">
                                                     <i class="bi bi-pencil-square"></i> Sửa
                                                 </a>
                                                 <% } %>
                                                <% if (canToggle) { %>
                                                <form action="category?action=toggle" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= c.getId() %>">
                                                    <button type="submit" class="btn btn-table <%= c.isStatus() ? "btn-outline-danger" : "btn-outline-success" %>" title="<%= c.isStatus() ? "Vô hiệu hóa danh mục" : "Kích hoạt danh mục" %>">
                                                        <i class="bi bi-power"></i> <%= c.isStatus() ? "Vô hiệu hóa" : "Kích hoạt" %>
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
                                        <td colspan="<%= canManage ? 5 : 4 %>" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Không có danh mục nào được đăng ký trong cơ sở dữ liệu.</p>
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

    <script>
        document.addEventListener("DOMContentLoaded", function() {
            initPagination("categoryTable", "paginationContainer", "entriesPerPage", "categorySearchInput");
            
            const clearBtn = document.getElementById("clearSearchBtn");
            const searchInput = document.getElementById("categorySearchInput");
            if (clearBtn && searchInput) {
                clearBtn.addEventListener("click", function() {
                    searchInput.value = "";
                    const event = new Event('filterReset');
                    document.getElementById("categoryTable").dispatchEvent(event);
                });
            }
        });

        function initPagination(tableId, containerId, selectId, searchInputId) {
            const table = document.getElementById(tableId);
            if (!table) return;
            const tbody = table.querySelector("tbody");
            if (!tbody) return;
            
            const allRows = Array.from(tbody.querySelectorAll("tr"));
            if (allRows.length === 1 && allRows[0].querySelector("td[colspan]")) {
                return; // No pagination for empty data
            }
            
            const container = document.getElementById(containerId);
            const select = document.getElementById(selectId);
            const searchInput = searchInputId ? document.getElementById(searchInputId) : null;
            if (!container || !select) return;
            
            let currentPage = 1;
            let pageSize = parseInt(select.value) || 10;
            let filteredRows = allRows;
            
            function updateTable() {
                if (searchInput) {
                    const query = searchInput.value.toLowerCase().trim();
                    filteredRows = allRows.filter(row => {
                        const rowText = row.textContent.toLowerCase();
                        return rowText.includes(query);
                    });
                } else {
                    filteredRows = allRows;
                }

                const totalRows = filteredRows.length;
                const totalPages = Math.ceil(totalRows / pageSize) || 1;
                
                if (currentPage > totalPages) currentPage = Math.max(1, totalPages);
                
                const start = (currentPage - 1) * pageSize;
                const end = Math.min(start + pageSize, totalRows);
                
                allRows.forEach(row => {
                    row.style.display = "none";
                });
                
                filteredRows.forEach((row, index) => {
                    if (index >= start && index < end) {
                        row.style.display = "";
                    }
                });
                
                renderControls(totalRows, totalPages);
            }
            
            function renderControls(totalRows, totalPages) {
                container.innerHTML = "";
                
                if (totalRows === 0) {
                    const infoDiv = document.createElement("div");
                    infoDiv.className = "text-muted small my-2 my-sm-0";
                    infoDiv.textContent = "Hiển thị 0 đến 0 của 0 dòng";
                    container.appendChild(infoDiv);
                    return;
                }
                
                const start = (currentPage - 1) * pageSize + 1;
                const end = Math.min(start + pageSize - 1, totalRows);
                
                const infoDiv = document.createElement("div");
                infoDiv.className = "text-muted small my-2 my-sm-0";
                infoDiv.textContent = "Hiển thị " + start + " đến " + end + " của " + totalRows + " dòng";
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
                    if (i < 1) continue;
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

            if (document.getElementById("filterBtn")) {
                document.getElementById("filterBtn").addEventListener("click", () => {
                    currentPage = 1;
                    updateTable();
                });
            }

            document.getElementById("categoryTable").addEventListener("filterReset", () => {
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
