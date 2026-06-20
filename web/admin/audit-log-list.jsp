<%@page import="model.User"%>
<%@page import="model.AuditLog"%>
<%@page import="java.util.List"%>
<%@page import="java.text.SimpleDateFormat"%>
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
    
    String search = (String) request.getAttribute("search");
    String actionFilter = (String) request.getAttribute("actionFilter");
    String startDate = (String) request.getAttribute("startDate");
    String endDate = (String) request.getAttribute("endDate");
    
    if (search == null) search = "";
    if (actionFilter == null) actionFilter = "";
    if (startDate == null) startDate = "";
    if (endDate == null) endDate = "";

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

                <!-- Advanced Filters Panel -->
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-body p-4">
                        <form action="audit-log" method="GET" class="row g-3">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold text-muted small">Tìm người dùng hoặc Chi tiết</label>
                                <div class="input-group">
                                    <span class="input-group-text bg-transparent border-end-0 text-muted"><i class="bi bi-search"></i></span>
                                    <input type="text" name="search" class="form-control border-start-0 ps-0" placeholder="Tên đăng nhập, họ tên, chi tiết..." value="<%= search %>">
                                </div>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label fw-semibold text-muted small">Loại hành động</label>
                                <select name="actionFilter" class="form-select">
                                    <option value="">Tất cả hành động</option>
                                    <%
                                        if (actions != null) {
                                            for (String a : actions) {
                                                boolean isSelected = a.equals(actionFilter);
                                    %>
                                        <option value="<%= a %>" <%= isSelected ? "selected" : "" %>><%= a %></option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label fw-semibold text-muted small">Ngày bắt đầu</label>
                                <input type="date" name="startDate" class="form-control" value="<%= startDate %>">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label fw-semibold text-muted small">Ngày kết thúc</label>
                                <input type="date" name="endDate" class="form-control" value="<%= endDate %>">
                            </div>
                            <div class="col-md-2 d-flex align-items-end gap-2">
                                <button type="submit" class="btn btn-primary w-100 py-2 d-flex align-items-center justify-content-center gap-1">
                                    <i class="bi bi-funnel"></i> Lọc
                                </button>
                                <a href="audit-log" class="btn btn-outline-secondary py-2" title="Đặt lại bộ lọc">
                                    <i class="bi bi-arrow-counterclockwise"></i>
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
                                <thead class="table-light">
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
                                            <span class="badge <%= badgeClass %> px-2.5 py-1.5"><%= log.getAction() %></span>
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

                <!-- Pagination -->
                <% if (totalPages > 1) { %>
                <nav aria-label="Page navigation" class="mt-4">
                    <ul class="pagination justify-content-center">
                        <li class="page-item <%= currentPage == 1 ? "disabled" : "" %>">
                            <a class="page-link d-flex align-items-center gap-1" href="audit-log?page=<%= currentPage - 1 %>&search=<%= search %>&actionFilter=<%= actionFilter %>&startDate=<%= startDate %>&endDate=<%= endDate %>" aria-label="Previous">
                                <i class="bi bi-chevron-left"></i> Trước
                            </a>
                        </li>
                        
                        <% for (int i = 1; i <= totalPages; i++) { %>
                            <li class="page-item <%= currentPage == i ? "active" : "" %>">
                                <a class="page-link" href="audit-log?page=<%= i %>&search=<%= search %>&actionFilter=<%= actionFilter %>&startDate=<%= startDate %>&endDate=<%= endDate %>"><%= i %></a>
                            </li>
                        <% } %>
                        
                        <li class="page-item <%= currentPage == totalPages ? "disabled" : "" %>">
                            <a class="page-link d-flex align-items-center gap-1" href="audit-log?page=<%= currentPage + 1 %>&search=<%= search %>&actionFilter=<%= actionFilter %>&startDate=<%= startDate %>&endDate=<%= endDate %>" aria-label="Next">
                                Sau <i class="bi bi-chevron-right"></i>
                            </a>
                        </li>
                    </ul>
                </nav>
                <% } %>
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
                            <div id="modal-user" class="fw-bold text-primary"></div>
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
