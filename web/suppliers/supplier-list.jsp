<%@page import="model.Supplier"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("SUPPLIER_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Supplier> supplierList = (List<Supplier>) request.getAttribute("supplierList");
    boolean canAdd = loggedInUser.hasPermission("SUPPLIER_ADD");
    boolean canEdit = loggedInUser.hasPermission("SUPPLIER_EDIT");
    boolean canToggle = loggedInUser.hasPermission("SUPPLIER_TOGGLE");
    boolean canManage = canEdit || canToggle;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Danh sách nhà cung cấp - WMS</title>
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
                        <h2 class="page-title">Danh sách nhà cung cấp</h2>
                        <p class="page-subtitle">Quản lý các đối tác và nhà cung cấp sản phẩm</p>
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
                                <input type="text" id="supplierSearchInput" class="form-control form-control-sm" placeholder="Tìm kiếm theo tên, liên hệ, điện thoại, email, địa chỉ...">
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
                        <span class="fw-bold text-slate-800"><i class="bi bi-truck me-2 text-primary"></i>Quản lý nhà cung cấp</span>
                        <% if (canAdd) { %>
                        <a class="btn btn-primary btn-sm" href="supplier?action=add">
                            <i class="bi bi-plus-circle-fill"></i> Thêm nhà cung cấp
                        </a>
                        <% } %>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table id="supplierTable" class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-center">Mã ID</th>
                                        <th>Tên nhà cung cấp</th>
                                        <th>Người liên hệ</th>
                                        <th>Số điện thoại</th>
                                        <th>Email</th>
                                        <th>Địa chỉ</th>
                                        <th class="text-center">Trạng thái</th>
                                        <% if (canManage) { %>
                                        <th class="text-center">Thao tác</th>
                                        <% } %>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (supplierList != null && !supplierList.isEmpty()) {
                                            for (Supplier s : supplierList) {
                                    %>
                                    <tr>
                                        <td class="fw-semibold text-muted text-center">#<%= s.getId() %></td>
                                        <td class="fw-bold text-slate-800"><%= s.getSupplierName() %></td>
                                        <td><%= s.getContactName() != null ? s.getContactName() : "-" %></td>
                                        <td><%= s.getPhone() != null ? s.getPhone() : "-" %></td>
                                        <td><%= s.getEmail() != null ? s.getEmail() : "-" %></td>
                                        <td class="text-muted text-truncate" style="max-width: 250px;"><%= s.getAddress() != null ? s.getAddress() : "" %></td>
                                        <td class="text-center">
                                            <% if (s.isStatus()) { %>
                                                <span class="status-chip chip-success">Hoạt động</span>
                                            <% } else { %>
                                                <span class="status-chip chip-muted">Không hoạt động</span>
                                            <% } %>
                                        </td>
                                        <% if (canManage) { %>
                                        <td class="text-center">
                                            <div class="d-flex align-items-center justify-content-center gap-1">
                                                 <% if (canEdit) { %>
                                                 <a href="supplier?action=update&id=<%= s.getId() %>" class="btn btn-table btn-outline-primary" title="Chỉnh sửa">
                                                     <i class="bi bi-pencil-square"></i> Sửa
                                                 </a>
                                                 <% } %>
                                                <% if (canToggle) { %>
                                                <form action="supplier?action=toggle" method="POST" class="d-inline m-0">
                                                    <input type="hidden" name="id" value="<%= s.getId() %>">
                                                    <button type="submit" class="btn btn-table <%= s.isStatus() ? "btn-outline-danger" : "btn-outline-success" %>" title="<%= s.isStatus() ? "Vô hiệu hóa nhà cung cấp" : "Kích hoạt nhà cung cấp" %>">
                                                        <i class="bi bi-power"></i> <%= s.isStatus() ? "Vô hiệu hóa" : "Kích hoạt" %>
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
                                        <td colspan="<%= canManage ? 8 : 7 %>" class="p-0">
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Không có nhà cung cấp nào được đăng ký trong cơ sở dữ liệu.</p>
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
            initPagination("supplierTable", "paginationContainer", "entriesPerPage", "supplierSearchInput");
            
            const clearBtn = document.getElementById("clearSearchBtn");
            const searchInput = document.getElementById("supplierSearchInput");
            if (clearBtn && searchInput) {
                clearBtn.addEventListener("click", function() {
                    searchInput.value = "";
                    const event = new Event('filterReset');
                    document.getElementById("supplierTable").dispatchEvent(event);
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
                return;
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
                
                renderPaginationControls(totalPages, totalRows);
            }
            
            function renderPaginationControls(totalPages, totalRows) {
                container.innerHTML = "";
                
                if (totalRows === 0) {
                    const infoSpan = document.createElement("span");
                    infoSpan.className = "text-muted small";
                    infoSpan.textContent = "Hiển thị 0 đến 0 của 0 dòng";
                    container.appendChild(infoSpan);
                    return;
                }
                
                const infoSpan = document.createElement("span");
                infoSpan.className = "text-muted small";
                const startIdx = (currentPage - 1) * pageSize + 1;
                const endIdx = Math.min(currentPage * pageSize, totalRows);
                infoSpan.textContent = "Hiển thị " + startIdx + " đến " + endIdx + " của " + totalRows + " dòng";
                container.appendChild(infoSpan);
                
                const nav = document.createElement("nav");
                const ul = document.createElement("ul");
                ul.className = "pagination pagination-sm m-0 border-0 gap-1";
                
                // Prev
                const prevLi = document.createElement("li");
                prevLi.className = "page-item " + (currentPage === 1 ? "disabled" : "");
                const prevA = document.createElement("a");
                prevA.className = "page-link border-0 rounded-2 shadow-none px-2.5 py-1.5";
                prevA.href = "javascript:void(0)";
                prevA.innerHTML = '<i class="bi bi-chevron-left"></i>';
                prevA.addEventListener("click", function(e) {
                    e.preventDefault();
                    if (currentPage > 1) {
                        currentPage--;
                        updateTable();
                    }
                });
                prevLi.appendChild(prevA);
                ul.appendChild(prevLi);
                
                // Pages
                let startPage = Math.max(1, currentPage - 2);
                let endPage = Math.min(totalPages, startPage + 4);
                if (endPage - startPage < 4) {
                    startPage = Math.max(1, endPage - 4);
                }
                for (let i = startPage; i <= endPage; i++) {
                    if (i < 1) continue;
                    const li = document.createElement("li");
                    li.className = "page-item " + (currentPage === i ? "active" : "");
                    const a = document.createElement("a");
                    a.className = "page-link border-0 rounded-2 shadow-none px-3 py-1.5";
                    a.href = "javascript:void(0)";
                    a.textContent = i;
                    a.addEventListener("click", function(e) {
                        e.preventDefault();
                        currentPage = i;
                        updateTable();
                    });
                    li.appendChild(a);
                    ul.appendChild(li);
                }
                
                // Next
                const nextLi = document.createElement("li");
                nextLi.className = "page-item " + (currentPage === totalPages || totalPages === 0 ? "disabled" : "");
                const nextA = document.createElement("a");
                nextA.className = "page-link border-0 rounded-2 shadow-none px-2.5 py-1.5";
                nextA.href = "javascript:void(0)";
                nextA.innerHTML = '<i class="bi bi-chevron-right"></i>';
                nextA.addEventListener("click", function(e) {
                    e.preventDefault();
                    if (currentPage < totalPages) {
                        currentPage++;
                        updateTable();
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
                updateTable();
            });

            if (document.getElementById("filterBtn")) {
                document.getElementById("filterBtn").addEventListener("click", function() {
                    currentPage = 1;
                    updateTable();
                });
            }

            document.getElementById("supplierTable").addEventListener("filterReset", function() {
                currentPage = 1;
                updateTable();
            });
            
            updateTable();
        }
    </script>
</body>
</html>
