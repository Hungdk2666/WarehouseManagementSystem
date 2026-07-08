<%@page import="model.Permission"%>
<%@page import="java.util.List"%>
<%@page import="model.Role"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("ROLE_ASSIGN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Role roleInfo = (Role) request.getAttribute("roleInfo");
    List<Permission> allPerms = (List<Permission>) request.getAttribute("allPerms");
    List<Integer> assignedPerms = (List<Integer>) request.getAttribute("assignedPerms");

    if (roleInfo == null || allPerms == null) {
        response.sendRedirect("role?action=list");
        return;
    }

    // Build a quick lookup map: permission_name -> Permission
    java.util.Map<String, Permission> permMap = new java.util.LinkedHashMap<>();
    if (allPerms != null) {
        for (Permission p : allPerms) permMap.put(p.getPermissionName(), p);
    }

    boolean isSystemAdmin = (roleInfo.getId() == 1);

    // --- Category definitions ---
    // Each category: label, icon, color, array of { resourceLabel, permissionNames[], isAdminResource }
    String[][] categories = {
        // 0: category label, 1: icon, 2: badge color
        {"Quản trị hệ thống", "bi-gear-fill", "danger"},
        {"Dữ liệu gốc", "bi-database-fill", "primary"},
        {"Nhập kho", "bi-box-arrow-in-down", "success"},
        {"Xuất kho", "bi-box-arrow-up-right", "warning"},
        {"Tồn kho & Kiểm kê", "bi-clipboard-data-fill", "info"},
        {"Thanh lý sản phẩm hỏng", "bi-trash3-fill", "dark"},
        {"Báo cáo & Phân tích", "bi-graph-up-arrow", "secondary"},
    };

    // Resources per category: { resourceLabel, isAdminResource, perm1, perm2, ... }
    String[][][] resources = {
        // Category 0: Quản trị hệ thống
        {
            {"Người dùng", "admin", "USER_VIEW", "USER_ADD", "USER_EDIT", "USER_TOGGLE"},
            {"Vai trò", "admin", "ROLE_VIEW", "ROLE_ADD", "ROLE_EDIT", "ROLE_TOGGLE", "ROLE_ASSIGN"},
            {"Nhật ký hoạt động", "admin", "AUDIT_LOG_VIEW"},
        },
        // Category 1: Dữ liệu gốc
        {
            {"Nhà cung cấp", "biz", "SUPPLIER_VIEW", "SUPPLIER_ADD", "SUPPLIER_EDIT", "SUPPLIER_TOGGLE"},
            {"Sản phẩm", "biz", "PRODUCT_VIEW", "PRODUCT_ADD", "PRODUCT_EDIT", "PRODUCT_TOGGLE"},
            {"Ngành hàng", "biz", "CATEGORY_VIEW", "CATEGORY_ADD", "CATEGORY_EDIT", "CATEGORY_TOGGLE"},
            {"Thương hiệu", "biz", "BRAND_VIEW", "BRAND_ADD", "BRAND_EDIT", "BRAND_TOGGLE"},
            {"Điểm nhận nội bộ", "biz", "DESTINATION_VIEW", "DESTINATION_ADD", "DESTINATION_EDIT", "DESTINATION_TOGGLE"},
            {"Khách hàng", "biz", "CUSTOMER_VIEW", "CUSTOMER_ADD", "CUSTOMER_EDIT", "CUSTOMER_DELETE"},
            {"Kho hàng", "biz", "WAREHOUSE_VIEW", "WAREHOUSE_ADD", "WAREHOUSE_EDIT"},
        },
        // Category 2: Nhập kho
        {
            {"Yêu cầu nhập kho", "biz", "REQUEST_VIEW_IN", "REQUEST_ADD_IN", "REQUEST_EDIT_IN", "REQUEST_CANCEL_IN", "REQUEST_APPROVE_IN", "REQUEST_REQUEST_CANCEL_IN", "REQUEST_APPROVE_CANCEL_IN"},
            {"Phiếu nhập kho", "biz", "TICKET_VIEW_IN", "TICKET_ADD_IN", "TICKET_CONFIRM_IN", "TICKET_CANCEL_IN"},
        },
        // Category 3: Xuất kho
        {
            {"Yêu cầu xuất kho", "biz", "REQUEST_VIEW_OUT", "REQUEST_ADD_OUT", "REQUEST_EDIT_OUT", "REQUEST_CANCEL_OUT", "REQUEST_APPROVE_OUT", "REQUEST_REQUEST_CANCEL_OUT", "REQUEST_APPROVE_CANCEL_OUT"},
            {"Phiếu xuất kho", "biz", "TICKET_VIEW_OUT", "TICKET_ADD_OUT", "TICKET_CONFIRM_OUT", "TICKET_CANCEL_OUT"},
        },
        // Category 4: Tồn kho & Kiểm kê
        {
            {"Tồn kho", "biz", "INVENTORY_VIEW", "INVENTORY_VIEW_ALL", "INVENTORY_EXPORT"},
            {"Kiểm kê", "biz", "STOCKTAKE_VIEW", "STOCKTAKE_CREATE", "STOCKTAKE_COUNT", "STOCKTAKE_SUBMIT", "STOCKTAKE_APPROVE_L1", "STOCKTAKE_REJECT", "STOCKTAKE_APPROVE_L2", "STOCKTAKE_CONFIG"},
        },
        // Category 5: Thanh lý sản phẩm hỏng
        {
            {"Phiếu thanh lý", "biz", "DISPOSAL_VIEW", "DISPOSAL_CREATE", "DISPOSAL_SUBMIT", "DISPOSAL_APPROVE_L1", "DISPOSAL_APPROVE_L2", "DISPOSAL_EXECUTE", "DISPOSAL_CONFIG", "DISPOSAL_EXPORT"},
        },
        // Category 6: Báo cáo & Phân tích
        {
            {"Sổ kho", "biz", "STOCK_LEDGER_VIEW"},
            {"Cảnh báo sắp hết hàng", "biz", "LOW_STOCK_ALERT_VIEW"},
            {"Dashboard", "biz", "DASHBOARD_VIEW"},
            {"Giá trị kho", "biz", "INVENTORY_VALUE_VIEW"},
        },
    };
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Quản lý phân quyền vai trò - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
    <style>
        .perm-section-header { cursor: pointer; user-select: none; }
        .perm-section-header:hover { filter: brightness(0.95); }
        .perm-action-item { min-width: 90px; padding: 6px 8px; border-radius: 8px; transition: background 0.15s; }
        .perm-action-item:hover { background: #f1f5f9; }
        .perm-action-item.disabled-perm { opacity: 0.45; pointer-events: none; }
        .perm-action-item .form-check-input { width: 1.15rem; height: 1.15rem; cursor: pointer; }
        .perm-action-item .form-check-input:disabled { cursor: not-allowed; }
        .perm-action-label { font-size: 0.78rem; font-weight: 600; letter-spacing: 0.01em; }
        .perm-action-desc { font-size: 0.68rem; color: #94a3b8; line-height: 1.2; }
        .perm-resource-row { border-left: 3px solid transparent; }
        .perm-resource-row:hover { background: #f8fafc; }
        .toggle-icon { transition: transform 0.2s; }
        .collapsed .toggle-icon { transform: rotate(-90deg); }
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
                        <h2 class="page-title">Phân quyền: <%= roleInfo.getRoleName() %></h2>
                        <p class="page-subtitle">Tích chọn các quyền muốn cấp cho vai trò này</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="role?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                    </div>
                </div>

                <div class="mb-3">
                    <div class="input-group shadow-sm rounded-3">
                        <span class="input-group-text bg-white border-end-0 text-muted"><i class="bi bi-search"></i></span>
                        <input type="text" id="permissionSearch" class="form-control border-start-0 ps-0" placeholder="Tìm quyền... (vd: tồn kho, duyệt, xuất)" style="box-shadow:none;">
                    </div>
                </div>

                <form action="role?action=permissions" method="POST" class="m-0" id="permForm">
                    <input type="hidden" name="id" value="<%= roleInfo.getId() %>">

                    <%
                        // Action label map
                        java.util.Map<String, String[]> actionMeta = new java.util.LinkedHashMap<>();
                        // { vietnameseLabel, icon }
                        actionMeta.put("VIEW",             new String[]{"Xem",           "bi-eye"});
                        actionMeta.put("VIEW_ALL",         new String[]{"Xem tất cả kho","bi-globe2"});
                        actionMeta.put("ADD",              new String[]{"Thêm",          "bi-plus-circle"});
                        actionMeta.put("EDIT",             new String[]{"Sửa",           "bi-pencil"});
                        actionMeta.put("DELETE",           new String[]{"Xóa",           "bi-trash"});
                        actionMeta.put("TOGGLE",           new String[]{"Bật/Tắt",       "bi-toggle-on"});
                        actionMeta.put("ASSIGN",           new String[]{"Phân quyền",    "bi-shield-lock"});
                        actionMeta.put("APPROVE",          new String[]{"Duyệt",         "bi-check-circle"});
                        actionMeta.put("REJECT",           new String[]{"Từ chối",       "bi-x-circle"});
                        actionMeta.put("CANCEL",           new String[]{"Hủy",           "bi-x-lg"});
                        actionMeta.put("CONFIRM",          new String[]{"Xác nhận",      "bi-check2-circle"});
                        actionMeta.put("SUBMIT",           new String[]{"Gửi duyệt",     "bi-send"});
                        actionMeta.put("REQUEST_CANCEL",   new String[]{"Đề xuất hủy",   "bi-exclamation-circle"});
                        actionMeta.put("APPROVE_CANCEL",   new String[]{"Duyệt hủy",     "bi-check-circle"});
                        actionMeta.put("EXPORT",           new String[]{"Xuất file",      "bi-download"});
                        actionMeta.put("CREATE",           new String[]{"Tạo mới",        "bi-plus-circle"});
                        actionMeta.put("COUNT",            new String[]{"Đếm",            "bi-123"});
                        actionMeta.put("APPROVE_L1",       new String[]{"Duyệt L1",       "bi-check-circle"});
                        actionMeta.put("APPROVE_L2",       new String[]{"Duyệt L2",       "bi-check-circle-fill"});
                        actionMeta.put("CONFIG",           new String[]{"Cấu hình",       "bi-gear"});
                        actionMeta.put("EXECUTE",          new String[]{"Thực hiện",      "bi-trash3"});

                        for (int ci = 0; ci < categories.length; ci++) {
                            String catLabel = categories[ci][0];
                            String catIcon = categories[ci][1];
                            String catColor = categories[ci][2];
                            String[][] catResources = resources[ci];
                    %>
                    <div class="card mb-3 perm-category" data-cat="<%= ci %>">
                        <div class="perm-section-header card-header bg-<%= catColor %> bg-opacity-10 border-0 py-3 d-flex align-items-center gap-2"
                             onclick="toggleCategory(<%= ci %>)" role="button">
                            <i class="<%= catIcon %> text-<%= catColor %> fs-5"></i>
                            <h6 class="mb-0 fw-bold text-<%= catColor %> flex-grow-1"><%= catLabel %></h6>
                            <span class="badge bg-<%= catColor %> bg-opacity-25 text-<%= catColor %> perm-cat-count" data-cat="<%= ci %>"></span>
                            <i class="bi bi-chevron-down toggle-icon text-<%= catColor %>"></i>
                        </div>
                        <div class="card-body p-0 perm-cat-body" id="catBody<%= ci %>">
                            <table class="table table-hover align-middle mb-0" style="font-size:0.88rem;">
                                <tbody>
                                <%
                                    for (int ri = 0; ri < catResources.length; ri++) {
                                        String[] resDef = catResources[ri];
                                        String resLabel = resDef[0];
                                        boolean isAdminResource = "admin".equals(resDef[1]);
                                        boolean isRowEditable = isSystemAdmin ? isAdminResource : !isAdminResource;
                                %>
                                    <tr class="perm-resource-row" style="border-left-color: <%= !isRowEditable ? "#e2e8f0" : "var(--bs-" + catColor + ")" %>; <%= !isRowEditable ? "opacity:0.5;" : "" %>">
                                        <td class="ps-4 align-middle" style="width:200px; white-space:nowrap;">
                                            <div class="fw-semibold text-slate-800"><%= resLabel %></div>
                                        </td>
                                        <td class="py-2">
                                            <div class="d-flex flex-wrap gap-2">
                                            <%
                                                for (int pi = 2; pi < resDef.length; pi++) {
                                                    String permName = resDef[pi];
                                                    Permission perm = permMap.get(permName);
                                                    if (perm == null) continue;

                                                    boolean hasPerm = assignedPerms != null && assignedPerms.contains(perm.getId());
                                                    boolean isEditable = isRowEditable;
                                                    if (isSystemAdmin && "ROLE_ASSIGN".equals(permName)) isEditable = false;

                                                    // Extract action key
                                                    String actionKey = "";
                                                    if ((permName.startsWith("REQUEST_") || permName.startsWith("TICKET_")) && (permName.endsWith("_IN") || permName.endsWith("_OUT"))) {
                                                        String suffix = permName.endsWith("_IN") ? "_IN" : "_OUT";
                                                        actionKey = permName.substring(permName.indexOf("_") + 1, permName.lastIndexOf(suffix));
                                                    } else if (permName.equals("INVENTORY_VIEW_ALL")) {
                                                        actionKey = "VIEW_ALL";
                                                    } else if (permName.startsWith("STOCKTAKE_APPROVE_")) {
                                                        actionKey = permName.substring("STOCKTAKE_".length());
                                                    } else if (permName.startsWith("DISPOSAL_APPROVE_")) {
                                                        actionKey = permName.substring("DISPOSAL_".length());
                                                    } else {
                                                        actionKey = permName.substring(permName.lastIndexOf("_") + 1);
                                                    }

                                                    String[] meta = actionMeta.get(actionKey);
                                                    String actionLabel = meta != null ? meta[0] : actionKey;
                                                    String actionIcon = meta != null ? meta[1] : "bi-circle";
                                            %>
                                                <label class="perm-action-item d-flex align-items-center gap-2 mb-0 <%= !isEditable ? "disabled-perm" : "" %>"
                                                       title="<%= perm.getDescription() %>">
                                                    <input class="form-check-input m-0 perm-cb" type="checkbox"
                                                           name="permissions" value="<%= perm.getId() %>"
                                                           <%= hasPerm ? "checked" : "" %> <%= !isEditable ? "disabled" : "" %>
                                                           data-cat="<%= ci %>">
                                                    <% if (!isEditable && hasPerm) { %>
                                                        <input type="hidden" name="permissions" value="<%= perm.getId() %>">
                                                    <% } %>
                                                    <span>
                                                        <i class="<%= actionIcon %> me-1" style="font-size:0.75rem;"></i>
                                                        <span class="perm-action-label"><%= actionLabel %></span>
                                                    </span>
                                                </label>
                                            <%
                                                }
                                            %>
                                            </div>
                                        </td>
                                    </tr>
                                <%
                                    }
                                %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <%
                        }
                    %>

                    <div class="d-flex justify-content-end gap-2 mt-2 mb-4">
                        <a href="role?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                        <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Lưu phân quyền</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function updateCategoryCounts() {
            document.querySelectorAll('.perm-cat-count').forEach(badge => {
                const cat = badge.dataset.cat;
                const total = document.querySelectorAll('.perm-cb[data-cat="' + cat + '"]').length;
                const checked = document.querySelectorAll('.perm-cb[data-cat="' + cat + '"]:checked').length;
                badge.textContent = checked + ' / ' + total;
            });
        }

        function toggleCategory(ci) {
            const body = document.getElementById('catBody' + ci);
            const header = body.previousElementSibling;
            if (body.style.display === 'none') {
                body.style.display = '';
                header.classList.remove('collapsed');
            } else {
                body.style.display = 'none';
                header.classList.add('collapsed');
            }
        }

        document.addEventListener("DOMContentLoaded", function() {
            updateCategoryCounts();
            document.querySelectorAll('.perm-cb').forEach(cb => {
                cb.addEventListener('change', updateCategoryCounts);
            });

            const searchInput = document.getElementById('permissionSearch');
            if (searchInput) {
                searchInput.addEventListener('keydown', e => { if (e.key === 'Enter') e.preventDefault(); });
                searchInput.addEventListener('input', function() {
                    const q = this.value.toLowerCase().trim();
                    document.querySelectorAll('.perm-resource-row').forEach(row => {
                        if (!q) { row.style.display = ''; return; }
                        let rowText = row.textContent.toLowerCase();
                        row.querySelectorAll('[title]').forEach(el => { rowText += ' ' + el.title.toLowerCase(); });
                        const match = q.split(/\s+/).every(w => rowText.includes(w));
                        row.style.display = match ? '' : 'none';
                    });
                    // Show categories that have visible rows
                    document.querySelectorAll('.perm-category').forEach(card => {
                        const visibleRows = card.querySelectorAll('.perm-resource-row[style=""], .perm-resource-row:not([style])');
                        const allHidden = Array.from(card.querySelectorAll('.perm-resource-row')).every(r => r.style.display === 'none');
                        card.style.display = (q && allHidden) ? 'none' : '';
                        // Expand when searching
                        if (q) {
                            const body = card.querySelector('.perm-cat-body');
                            if (body) body.style.display = '';
                            const header = card.querySelector('.perm-section-header');
                            if (header) header.classList.remove('collapsed');
                        }
                    });
                });
            }
        });
    </script>
</body>
</html>
