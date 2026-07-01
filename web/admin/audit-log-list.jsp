<%@page import="model.User"%>
<%@page import="model.AuditLog"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Arrays"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.net.URLEncoder"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("AUDIT_LOG_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<AuditLog> logs = (List<AuditLog>) request.getAttribute("logs");
    List<String> actions = (List<String>) request.getAttribute("actions");
    int currentPage = (int) request.getAttribute("currentPage");
    int totalPages = (int) request.getAttribute("totalPages");
    int totalCount = (int) request.getAttribute("totalCount");
    int pageSize = (int) request.getAttribute("pageSize");

    String search = (String) request.getAttribute("search");
    String[] actionFilters = (String[]) request.getAttribute("actionFilters");
    String startDate = (String) request.getAttribute("startDate");
    String endDate = (String) request.getAttribute("endDate");

    if (search == null) search = "";
    if (actionFilters == null) actionFilters = new String[0];
    if (startDate == null) startDate = "";
    if (endDate == null) endDate = "";

    List<String> selectedActions = Arrays.asList(actionFilters);

    // Build action filter query string for pagination links
    StringBuilder actionParams = new StringBuilder();
    for (String af : actionFilters) {
        if (af != null && !af.trim().isEmpty())
            actionParams.append("&actionFilter=").append(URLEncoder.encode(af.trim(), "UTF-8"));
    }

    // Label for the action dropdown button
    String actionLabel;
    if (selectedActions.isEmpty()) actionLabel = "-- Tất cả --";
    else if (selectedActions.size() == 1) actionLabel = selectedActions.get(0);
    else actionLabel = selectedActions.size() + " đã chọn";

    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Nhật ký hoạt động - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Nhật ký hoạt động</h2>
                        <p class="text-muted small mb-0">Giám sát hoạt động của hệ thống và dấu vết các giao dịch quan trọng</p>
                    </div>
                </div>

                <!-- Filters -->
                <div class="card shadow-sm border-0 mb-3" style="position: relative; z-index: 20;">
                    <div class="card-body py-3">
                        <form id="filterForm" action="audit-log" method="GET" class="row g-2 align-items-end">
                            <div class="col-12 col-md-3">
                                <label class="form-label small fw-semibold mb-1">Tìm kiếm</label>
                                <input type="text" name="search" class="form-control form-control-sm" placeholder="Tên đăng nhập, họ tên, chi tiết..." value="<%= search %>">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Loại hành động</label>
                                <div class="dropdown" id="actionDropdownWrap">
                                    <button type="button" id="actionDropdownBtn" class="btn btn-outline-secondary btn-sm dropdown-toggle w-100 text-start fw-normal"
                                            data-bs-toggle="dropdown" data-bs-auto-close="outside" style="background:#fff; font-size:0.875rem;">
                                        <span id="actionLabel"><%= actionLabel %></span>
                                    </button>
                                    <ul class="dropdown-menu p-2 shadow-sm" id="actionDropdownMenu" style="min-width:200px; max-height:280px; overflow-y:auto;">
                                        <%
                                            if (actions != null) {
                                                for (String a : actions) {
                                                    boolean isChecked = selectedActions.contains(a);
                                        %>
                                        <li>
                                            <label class="d-flex align-items-center gap-2 px-2 py-1 rounded hover-item">
                                                <input type="checkbox" name="actionFilter" class="action-cb form-check-input flex-shrink-0 m-0"
                                                       value="<%= a %>" <%= isChecked ? "checked" : "" %>> <%
                                                    String aLabel = a;
                                                    if ("LOGIN".equals(a)) aLabel = "Đăng nhập";
                                                    else if ("LOGOUT".equals(a)) aLabel = "Đăng xuất";
                                                    else if ("CONFIRM_GRN".equals(a)) aLabel = "Xác nhận nhập kho";
                                                    else if ("CONFIRM_GIN".equals(a)) aLabel = "Xác nhận xuất kho";
                                                    else if ("CREATE".equals(a)) aLabel = "Tạo mới";
                                                    else if ("UPDATE".equals(a)) aLabel = "Cập nhật";
                                                    else if ("DELETE".equals(a)) aLabel = "Xóa";
                                                %><%= aLabel %>
                                            </label>
                                        </li>
                                        <%
                                                }
                                            }
                                        %>
                                        <li><hr class="dropdown-divider my-1"></li>
                                        <li><button type="button" id="clearActionBtn" class="btn btn-link btn-sm w-100 text-muted text-decoration-none py-1" style="font-size:0.8rem;"><i class="bi bi-x-circle me-1"></i>Xóa chọn</button></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Từ ngày</label>
                                <input type="date" id="startDate" name="startDate" class="form-control form-control-sm" value="<%= startDate %>">
                            </div>
                            <div class="col-6 col-md-2">
                                <label class="form-label small fw-semibold mb-1">Đến ngày</label>
                                <input type="date" id="endDate" name="endDate" class="form-control form-control-sm" value="<%= endDate %>"
                                       <%= !startDate.isEmpty() ? "min=\"" + startDate + "\"" : "" %>>
                            </div>
                            <div class="col-12 col-md-auto ms-md-auto d-flex gap-2">
                                <button type="submit" class="btn btn-primary btn-sm px-3">
                                    <i class="bi bi-funnel-fill me-1"></i>Lọc
                                </button>
                                <a href="audit-log" class="btn btn-outline-secondary btn-sm px-3" title="Đặt lại bộ lọc">
                                    <i class="bi bi-arrow-counterclockwise me-1"></i>Đặt lại
                                </a>
                            </div>
                        </form>
                    </div>
                </div>

                <!-- Logs Table Card -->
                <div class="card shadow-sm border-0 bg-white">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                        <span class="fw-bold text-slate-800"><i class="bi bi-list-task me-2 text-primary"></i>Bản ghi nhật ký (<%= totalCount %> bản ghi)</span>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light" style="position: sticky; top: 0; z-index: 1;">
                                    <tr>
                                        <th class="ps-4">Thời gian</th>
                                        <th>Người dùng</th>
                                        <th>Hành động</th>
                                        <th>Chi tiết</th>
                                        <th class="pe-4 text-center">Hành động</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (logs != null && !logs.isEmpty()) {
                                            for (AuditLog log : logs) {
                                                String badgeClass = "bg-secondary text-secondary";
                                                String act = log.getAction();
                                                if ("LOGIN".equals(act)) {
                                                    badgeClass = "bg-success text-success bg-opacity-10";
                                                } else if ("LOGOUT".equals(act)) {
                                                    badgeClass = "bg-secondary text-secondary bg-opacity-10";
                                                } else if ("CONFIRM_GRN".equals(act)) {
                                                    badgeClass = "bg-info text-info bg-opacity-10";
                                                } else if ("CONFIRM_GIN".equals(act)) {
                                                    badgeClass = "bg-warning text-warning bg-opacity-10";
                                                } else {
                                                    badgeClass = "bg-primary text-primary bg-opacity-10";
                                                }
                                                
                                                String userDisplay = log.getUsername() != null ? 
                                                    "<strong>" + log.getUsername() + "</strong> <span class='text-muted small'>(" + log.getUserFullName() + ")</span>" : 
                                                    "<span class='text-muted italic'>Hệ thống / Người dùng đã xóa</span>";
                                    %>
                                    <tr>
                                        <td class="ps-4 text-muted small"><%= sdf.format(log.getCreatedAt()) %></td>
                                        <td><%= userDisplay %></td>
                                        <td>
                                            <span class="badge <%= badgeClass %> px-2.5 py-1.5"><%
                                                String displayAction = log.getAction();
                                                if ("LOGIN".equals(displayAction)) displayAction = "Đăng nhập";
                                                else if ("LOGOUT".equals(displayAction)) displayAction = "Đăng xuất";
                                                else if ("CONFIRM_GRN".equals(displayAction)) displayAction = "Xác nhận nhập kho";
                                                else if ("CONFIRM_GIN".equals(displayAction)) displayAction = "Xác nhận xuất kho";
                                                else if ("CREATE".equals(displayAction)) displayAction = "Tạo mới";
                                                else if ("UPDATE".equals(displayAction)) displayAction = "Cập nhật";
                                                else if ("DELETE".equals(displayAction)) displayAction = "Xóa";
                                            %><%= displayAction %></span>
                                        </td>
                                        <td class="text-truncate" style="max-width: 400px;"><%= log.getDetails() %></td>
                                        <td class="pe-4 text-center">
                                            <button type="button" 
                                                    class="btn btn-sm btn-outline-primary py-1 px-3"
                                                    onclick="showDetails('<%= sdf.format(log.getCreatedAt()) %>', '<%= log.getUsername() != null ? log.getUsername() + " (" + log.getUserFullName() + ")" : "Hệ thống" %>', '<%= log.getAction() %>', '<%= badgeClass %>', '<%= log.getDetails().replace("'", "\\'") %>')">
                                                <i class="bi bi-eye"></i> Xem
                                            </button>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        } else {
                                    %>
                                    <tr>
                                        <td colspan="5" class="text-center py-5 text-muted">
                                            <i class="bi bi-journal-x fs-1 d-block mb-3 text-muted" style="opacity: 0.5;"></i>
                                            Không tìm thấy nhật ký hoạt động nào phù hợp với bộ lọc.
                                        </td>
                                    </tr>
                                    <%
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                    </div>
                    <div class="card-footer bg-transparent border-top d-flex flex-column flex-sm-row justify-content-between align-items-center px-4 py-3 gap-3">
                        <div class="d-flex align-items-center gap-2">
                            <label class="text-muted small mb-0 flex-shrink-0">Hiển thị</label>
                            <select name="pageSize" form="filterForm" class="form-select form-select-sm border border-secondary-subtle bg-white shadow-none px-3 py-1" style="width: 80px; border-radius: 8px;" onchange="document.getElementById('filterForm').submit();">
                                <option value="10" <%= pageSize == 10 ? "selected" : "" %>>10</option>
                                <option value="25" <%= pageSize == 25 ? "selected" : "" %>>25</option>
                                <option value="100" <%= pageSize == 100 ? "selected" : "" %>>100</option>
                            </select>
                            <span class="text-muted small">dòng</span>
                        </div>
                        <div class="d-flex align-items-center justify-content-between justify-content-sm-end gap-3 flex-wrap w-100 w-sm-auto">
                            <!-- Pagination -->
                            <% if (totalPages > 1) { %>
                            <nav aria-label="Page navigation" class="m-0">
                                <ul class="pagination pagination-sm m-0 gap-1">
                                    <li class="page-item <%= currentPage == 1 ? "disabled" : "" %>">
                                        <a class="page-link border-0 rounded-2 shadow-none px-2.5 py-1.5" href="audit-log?page=<%= currentPage - 1 %>&pageSize=<%= pageSize %>&search=<%= search %><%= actionParams %>&startDate=<%= startDate %>&endDate=<%= endDate %>" aria-label="Previous">
                                            <i class="bi bi-chevron-left"></i>
                                        </a>
                                    </li>
                                    
                                    <% 
                                        int startPage = Math.max(1, currentPage - 2);
                                        int endPage = Math.min(totalPages, currentPage + 2);
                                        if (currentPage <= 3) {
                                            endPage = Math.min(totalPages, 5);
                                        }
                                        if (currentPage >= totalPages - 2) {
                                            startPage = Math.max(1, totalPages - 4);
                                        }
                                    %>
                                    
                                    <% if (startPage > 1) { %>
                                        <li class="page-item">
                                            <a class="page-link border-0 rounded-2 shadow-none px-3 py-1.5" href="audit-log?page=1&pageSize=<%= pageSize %>&search=<%= search %><%= actionParams %>&startDate=<%= startDate %>&endDate=<%= endDate %>">1</a>
                                        </li>
                                        <% if (startPage > 2) { %>
                                            <li class="page-item disabled"><span class="page-link border-0 bg-transparent px-2">...</span></li>
                                        <% } %>
                                    <% } %>

                                    <% for (int i = startPage; i <= endPage; i++) { %>
                                        <li class="page-item <%= currentPage == i ? "active" : "" %>">
                                            <a class="page-link border-0 rounded-2 shadow-none px-3 py-1.5" href="audit-log?page=<%= i %>&pageSize=<%= pageSize %>&search=<%= search %><%= actionParams %>&startDate=<%= startDate %>&endDate=<%= endDate %>"><%= i %></a>
                                        </li>
                                    <% } %>

                                    <% if (endPage < totalPages) { %>
                                        <% if (endPage < totalPages - 1) { %>
                                            <li class="page-item disabled"><span class="page-link border-0 bg-transparent px-2">...</span></li>
                                        <% } %>
                                        <li class="page-item">
                                            <a class="page-link border-0 rounded-2 shadow-none px-3 py-1.5" href="audit-log?page=<%= totalPages %>&pageSize=<%= pageSize %>&search=<%= search %><%= actionParams %>&startDate=<%= startDate %>&endDate=<%= endDate %>"><%= totalPages %></a>
                                        </li>
                                    <% } %>
                                    
                                    <li class="page-item <%= currentPage == totalPages ? "disabled" : "" %>">
                                        <a class="page-link border-0 rounded-2 shadow-none px-2.5 py-1.5" href="audit-log?page=<%= currentPage + 1 %>&pageSize=<%= pageSize %>&search=<%= search %><%= actionParams %>&startDate=<%= startDate %>&endDate=<%= endDate %>" aria-label="Next">
                                            <i class="bi bi-chevron-right"></i>
                                        </a>
                                    </li>
                                </ul>
                            </nav>
                            <% } %>
                        </div>
                    </div>
            </div>
        </div>
    </div>

    <!-- Modal details -->
    <div class="modal fade" id="logDetailsModal" tabindex="-1" aria-labelledby="logDetailsModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg" style="border-radius: 12px; overflow: hidden;">
                <div class="modal-header bg-dark text-white border-0 py-3">
                    <h5 class="modal-title fw-bold" id="logDetailsModalLabel"><i class="bi bi-journal-text me-2"></i>Chi tiết nhật ký</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body p-4 bg-white">
                    <div class="mb-3">
                        <span class="text-uppercase fw-semibold text-muted small d-block mb-1">Thời gian</span>
                        <div id="modal-time" class="fw-medium text-slate-800"></div>
                    </div>
                    <div class="row mb-3">
                        <div class="col-12">
                            <span class="text-uppercase fw-semibold text-muted small d-block mb-1">Người thực hiện</span>
                            <div id="modal-user" class="fw-bold text-slate-800"></div>
                        </div>
                    </div>
                    <div class="mb-3">
                        <span class="text-uppercase fw-semibold text-muted small d-block mb-1">Hành động</span>
                        <div><span id="modal-action" class="badge"></span></div>
                    </div>
                    <div class="mb-0">
                        <span class="text-uppercase fw-semibold text-muted small d-block mb-1">Mô tả nhật ký hoạt động</span>
                        <div id="modal-details" class="p-3 bg-light rounded text-slate-700 font-monospace border small" style="white-space: pre-wrap; word-break: break-all; max-height: 250px; overflow-y: auto;"></div>
                    </div>
                </div>
                <div class="modal-footer border-0 bg-light py-2">
                    <button type="button" class="btn btn-secondary px-4 py-2 small" data-bs-dismiss="modal">Đóng</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            // Multi-select hành động
            function updateActionLabel() {
                var checked = document.querySelectorAll('#actionDropdownMenu .action-cb:checked');
                var label = document.getElementById('actionLabel');
                if (checked.length === 0) label.textContent = '-- Tất cả --';
                else if (checked.length === 1) label.textContent = checked[0].closest('label').textContent.trim();
                else label.textContent = checked.length + ' đã chọn';
            }
            document.querySelectorAll('#actionDropdownMenu .action-cb').forEach(function(cb) {
                cb.addEventListener('change', updateActionLabel);
            });
            document.getElementById('clearActionBtn').addEventListener('click', function(e) {
                e.stopPropagation();
                document.querySelectorAll('#actionDropdownMenu .action-cb').forEach(function(cb) { cb.checked = false; });
                updateActionLabel();
            });
            new bootstrap.Dropdown(document.getElementById('actionDropdownBtn'), { popperConfig: { strategy: 'fixed' } });

            var startEl = document.getElementById("startDate");
            var endEl = document.getElementById("endDate");
            if (startEl && endEl) {
                startEl.addEventListener("change", function() {
                    endEl.min = startEl.value;
                    if (endEl.value && endEl.value < startEl.value) endEl.value = startEl.value;
                });
                endEl.addEventListener("change", function() {
                    startEl.max = endEl.value;
                    if (startEl.value && startEl.value > endEl.value) startEl.value = endEl.value;
                });
            }
        });

        function showDetails(time, user, action, badgeClass, details) {
            document.getElementById('modal-time').innerText = time;
            document.getElementById('modal-user').innerText = user;
            
            const actionEl = document.getElementById('modal-action');
            actionEl.innerText = action;
            actionEl.className = 'badge ' + badgeClass + ' px-2.5 py-1.5';
            
            document.getElementById('modal-details').innerText = details;
            
            const modal = new bootstrap.Modal(document.getElementById('logDetailsModal'));
            modal.show();
        }
    </script>
</body>
</html>
