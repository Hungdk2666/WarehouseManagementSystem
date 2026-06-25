<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUserSidebar = (User) session.getAttribute("user");
    String requestURI = (String) request.getAttribute("javax.servlet.forward.request_uri");
    if (requestURI == null) {
        requestURI = request.getRequestURI();
    }
%>
<style>
    .list-group-custom .sidebar-header {
        background-color: transparent !important;
        transform: none !important;
        cursor: pointer;
        user-select: none;
        transition: color 0.2s ease;
    }
    .list-group-custom .sidebar-header:hover {
        color: var(--slate-900) !important;
        background-color: rgba(0,0,0,0.02) !important;
    }
    .list-group-custom .chevron-icon {
        transition: transform 0.2s ease;
        font-size: 0.75rem;
    }
    .list-group-custom .sidebar-header[aria-expanded="true"] .chevron-icon {
        transform: rotate(90deg);
    }
    .list-group-custom .collapse {
        transition: max-height 0.25s ease-out, opacity 0.2s ease-in-out;
        max-height: 0;
        opacity: 0;
        overflow: hidden;
        display: block !important;
    }
    .list-group-custom .collapse.show {
        max-height: 1000px;
        opacity: 1;
    }
</style>

<div class="col-md-3 col-lg-2 mb-4">
    <div class="list-group list-group-custom shadow-sm bg-white p-2 rounded-3 border">
        
        <!-- Navigation Section -->
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mb-2 d-flex justify-content-between align-items-center sidebar-header" 
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseNavigation" aria-expanded="false">
            <span><i class="bi bi-grid-fill me-2"></i>Điều hướng</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseNavigation">
            <a href="<%= request.getContextPath() %>/index.jsp" class="list-group-item list-group-item-action <%= requestURI.endsWith("index.jsp") || requestURI.endsWith("/") || requestURI.endsWith("WareHouseManagementSystem") || requestURI.endsWith("WareHouseManagementSystem/") ? "active" : "" %>">
                <i class="bi bi-speedometer2 me-2"></i> Bảng điều khiển
            </a>
        </div>
        
        <!-- Administration Section -->
        <% if (loggedInUserSidebar != null && (loggedInUserSidebar.hasPermission("USER_VIEW") || loggedInUserSidebar.hasPermission("ROLE_VIEW") || loggedInUserSidebar.hasPermission("AUDIT_LOG_VIEW"))) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2 d-flex justify-content-between align-items-center sidebar-header" 
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseAdmin" aria-expanded="false">
            <span><i class="bi bi-gear-fill me-2"></i> Quản trị hệ thống</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseAdmin">
            <% if (loggedInUserSidebar.hasPermission("USER_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/admin/user?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("user") ? "active" : "" %>">
                <i class="bi bi-people-fill me-2"></i> Quản lý người dùng
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("ROLE_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/admin/role?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("role") ? "active" : "" %>">
                <i class="bi bi-shield-lock-fill me-2"></i> Quản lý vai trò
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("AUDIT_LOG_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/admin/audit-log" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("audit-log") ? "active" : "" %>">
                <i class="bi bi-journal-text me-2"></i> Nhật ký hoạt động
            </a>
            <% } %>
        </div>
        <% } %>

        <!-- Inbound Operations Section -->
        <% if (loggedInUserSidebar != null && (loggedInUserSidebar.hasPermission("REQUEST_VIEW_IN") || loggedInUserSidebar.hasPermission("TICKET_VIEW_IN"))) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2 d-flex justify-content-between align-items-center sidebar-header" 
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseInbound" aria-expanded="false">
            <span><i class="bi bi-arrow-down-left-square-fill me-2"></i> Hoạt động nhập kho</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseInbound">
            <% if (loggedInUserSidebar.hasPermission("REQUEST_VIEW_IN")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/import-request?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= (requestURI.contains("import-request") || requestURI.contains("import_request")) && !requestURI.contains("return-add") && !"addReturn".equals(request.getParameter("action")) ? "active" : "" %>">
                <i class="bi bi-receipt me-2"></i> Yêu cầu nhập kho
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("REQUEST_ADD_IN")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/import-request?action=addReturn" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("return-add") || "addReturn".equals(request.getParameter("action")) ? "active" : "" %>">
                <i class="bi bi-arrow-counterclockwise me-2"></i> Tạo Return Request
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("TICKET_VIEW_IN")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/import-ticket?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("import-ticket") || requestURI.contains("/import/") || requestURI.endsWith("/import") ? "active" : "" %>">
                <i class="bi bi-box-arrow-in-down-left me-2"></i> Phiếu nhập kho
            </a>
            <% } %>
        </div>
        <% } %>

        <!-- Outbound Operations Section -->
        <% if (loggedInUserSidebar != null && (loggedInUserSidebar.hasPermission("REQUEST_VIEW_OUT") || loggedInUserSidebar.hasPermission("TICKET_VIEW_OUT"))) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2 d-flex justify-content-between align-items-center sidebar-header" 
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseOutbound" aria-expanded="false">
            <span><i class="bi bi-arrow-up-right-square-fill me-2"></i> Hoạt động xuất kho</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseOutbound">
            <% if (loggedInUserSidebar.hasPermission("REQUEST_VIEW_OUT")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/export-request?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("export-request") || requestURI.contains("export_request") ? "active" : "" %>">
                <i class="bi bi-receipt me-2"></i> Yêu cầu xuất kho
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("TICKET_VIEW_OUT")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/export-ticket?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("export-ticket") || requestURI.contains("export_ticket") ? "active" : "" %>">
                <i class="bi bi-box-arrow-up-right me-2"></i> Phiếu xuất kho
            </a>
            <% } %>
        </div>
        <% } %>

        <!-- Inventory Section -->
        <% if (loggedInUserSidebar != null && loggedInUserSidebar.hasPermission("INVENTORY_VIEW")) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2 d-flex justify-content-between align-items-center sidebar-header"
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseInventory" aria-expanded="false">
            <span><i class="bi bi-boxes me-2"></i> Tồn kho</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseInventory">
            <a href="<%= request.getContextPath() %>/warehouse/inventory" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("/inventory") ? "active" : "" %>">
                <i class="bi bi-clipboard-data me-2"></i> Số liệu tồn kho
            </a>
        </div>
        <% } %>

        <!-- Stocktake Section -->
        <% if (loggedInUserSidebar != null && loggedInUserSidebar.hasPermission("STOCKTAKE_VIEW")) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2 d-flex justify-content-between align-items-center sidebar-header"
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseStocktake" aria-expanded="false">
            <span><i class="bi bi-clipboard-check-fill me-2"></i> Kiểm kê tồn kho</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseStocktake">
            <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("/stocktake") && !"config".equals(request.getParameter("action")) ? "active" : "" %>">
                <i class="bi bi-list-check me-2"></i> Phiếu kiểm kê
            </a>
            <% if (loggedInUserSidebar.hasPermission("STOCKTAKE_CONFIG")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/stocktake?action=config" class="list-group-item list-group-item-action d-flex align-items-center <%= "config".equals(request.getParameter("action")) ? "active" : "" %>">
                <i class="bi bi-sliders me-2"></i> Ngưỡng duyệt 2 cấp
            </a>
            <% } %>
        </div>
        <% } %>

        <!-- Master Data Section -->
        <% if (loggedInUserSidebar != null && (loggedInUserSidebar.hasPermission("PRODUCT_VIEW") || loggedInUserSidebar.hasPermission("CATEGORY_VIEW") || loggedInUserSidebar.hasPermission("BRAND_VIEW") || loggedInUserSidebar.hasPermission("DESTINATION_VIEW") || loggedInUserSidebar.hasPermission("SUPPLIER_VIEW") || loggedInUserSidebar.hasPermission("WAREHOUSE_VIEW"))) { %>
        <div class="list-group-item text-uppercase text-muted border-0 ps-3 mt-3 mb-2 d-flex justify-content-between align-items-center sidebar-header" 
             style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;"
             data-custom-toggle="collapse" data-custom-target="#collapseMasterData" aria-expanded="false">
            <span><i class="bi bi-database-fill me-2"></i> Dữ liệu gốc</span>
            <i class="bi bi-chevron-right chevron-icon"></i>
        </div>
        <div class="collapse" id="collapseMasterData">
            <% if (loggedInUserSidebar.hasPermission("PRODUCT_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/product?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("product") ? "active" : "" %>">
                <i class="bi bi-box-seam-fill me-2"></i> Danh mục sản phẩm
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("CATEGORY_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/category?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("category") ? "active" : "" %>">
                <i class="bi bi-tags-fill me-2"></i> Danh mục phân loại
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("BRAND_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/brand?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("brand") ? "active" : "" %>">
                <i class="bi bi-award-fill me-2"></i> Danh sách thương hiệu
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("SUPPLIER_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/supplier?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("supplier") ? "active" : "" %>">
                <i class="bi bi-truck me-2"></i> Danh sách nhà cung cấp
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("DESTINATION_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/destination?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("destination") ? "active" : "" %>">
                <i class="bi bi-geo-alt-fill me-2"></i> Danh sách điểm nhận
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("CUSTOMER_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/customer?action=list" class="list-group-item list-group-item-action d-flex align-items-center <%= requestURI.contains("/customer") ? "active" : "" %>">
                <i class="bi bi-people-fill me-2"></i> Khách hàng
            </a>
            <% } %>
            <% if (loggedInUserSidebar.hasPermission("WAREHOUSE_VIEW")) { %>
            <a href="<%= request.getContextPath() %>/warehouse/warehouse" class="list-group-item list-group-item-action d-flex align-items-center <%= (requestURI.contains("/warehouse/warehouse") || requestURI.contains("warehouse-list") || requestURI.contains("warehouse-form")) ? "active" : "" %>">
                <i class="bi bi-building-fill me-2"></i> Danh sách kho
            </a>
            <% } %>
        </div>
        <% } %>
    </div>
</div>

<script>
    document.addEventListener("DOMContentLoaded", function() {
        // Toggle collapse sections manually (independent of Bootstrap JS)
        const headers = document.querySelectorAll('.list-group-custom .sidebar-header');
        headers.forEach(header => {
            header.addEventListener('click', function() {
                const targetSelector = this.getAttribute('data-custom-target');
                const targetCollapse = document.querySelector(targetSelector);
                
                if (targetCollapse) {
                    const isExpanded = this.getAttribute('aria-expanded') === 'true';
                    if (isExpanded) {
                        targetCollapse.classList.remove('show');
                        this.setAttribute('aria-expanded', 'false');
                    } else {
                        targetCollapse.classList.add('show');
                        this.setAttribute('aria-expanded', 'true');
                    }
                }
            });
        });

        // Auto-expand the active section on load
        const activeLink = document.querySelector('.list-group-custom .list-group-item.active');
        if (activeLink) {
            const parentCollapse = activeLink.closest('.collapse');
            if (parentCollapse) {
                parentCollapse.classList.add('show');
                const header = document.querySelector('[data-custom-target="#' + parentCollapse.id + '"]');
                if (header) {
                    header.setAttribute('aria-expanded', 'true');
                }
            }
        } else {
            // Default expand Navigation if no active link
            const firstCollapse = document.getElementById('collapseNavigation');
            if (firstCollapse) {
                firstCollapse.classList.add('show');
                const header = document.querySelector('[data-custom-target="#collapseNavigation"]');
                if (header) {
                    header.setAttribute('aria-expanded', 'true');
                }
            }
        }
    });
</script>
