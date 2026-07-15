<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="model.AuditLog"%>
<%@page import="java.util.List"%>
<%@page import="dao.RoleDAO"%>
<%@page import="dao.UserDAO"%>
<%@page import="dao.AuditLogDAO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !(user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW"))) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    UserDAO userDAO = new UserDAO();
    RoleDAO roleDAO = new RoleDAO();
    AuditLogDAO auditLogDAO = new AuditLogDAO();

    List<User> allUsers = userDAO.getAllUsers();
    int totalUsers = allUsers.size();
    int activeUsers = 0;
    for (User u : allUsers) { if (u.isStatus()) activeUsers++; }
    int inactiveUsers = totalUsers - activeUsers;

    List<Role> allRoles = roleDAO.getAllRoles();
    int totalRoles = allRoles.size();

    String today = java.time.LocalDate.now().toString();
    String sevenDaysAgo = java.time.LocalDate.now().minusDays(7).toString();
    int resetCount7d = auditLogDAO.getLogsCount("SYSTEM", null, new String[]{"RESET_PASSWORD"}, sevenDaysAgo, today);
    int changeCount7d = auditLogDAO.getLogsCount("SYSTEM", null, new String[]{"CHANGE_PASSWORD"}, sevenDaysAgo, today);

    List<AuditLog> recentSystemLogs = auditLogDAO.getLogs("SYSTEM", null, null, null, null, 1, 8);
    SimpleDateFormat activityFmt = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    StringBuilder roleLabelsJson = new StringBuilder("[");
    StringBuilder roleDataJson = new StringBuilder("[");
    for (int i = 0; i < allRoles.size(); i++) {
        Role r = allRoles.get(i);
        int count = userDAO.countActiveUsersByRoleId(r.getId());
        if (i > 0) { roleLabelsJson.append(","); roleDataJson.append(","); }
        roleLabelsJson.append("\"").append(r.getRoleName().replace("\"", "'")).append("\"");
        roleDataJson.append(count);
    }
    roleLabelsJson.append("]");
    roleDataJson.append("]");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard Quản trị hệ thống - WMS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
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
                        <h1 class="page-title">Chào mừng, <%= user.getFullName() %>!</h1>
                        <p class="page-subtitle mb-0">Dashboard Quản trị hệ thống — tài khoản, vai trò &amp; bảo mật</p>
                    </div>
                </div>

                <div class="alert alert-info border-0 bg-info bg-opacity-10 text-dark p-3 rounded-3 mb-4 d-flex align-items-start gap-2">
                    <i class="bi bi-shield-lock-fill fs-5 text-info-emphasis"></i>
                    <div class="small text-muted">Theo chính sách phân chia nhiệm vụ, tài khoản Quản trị hệ thống chỉ quản lý người dùng, vai trò và nhật ký kỹ thuật; không truy cập số liệu kinh doanh.</div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-people-fill"></i></div>
                        <div><div class="stat-label">Tổng người dùng</div><h3 class="stat-value"><%= totalUsers %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-person-check-fill"></i></div>
                        <div><div class="stat-label">Đang hoạt động</div><h3 class="stat-value"><%= activeUsers %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-secondary bg-opacity-10 text-secondary"><i class="bi bi-person-x-fill"></i></div>
                        <div><div class="stat-label">Ngừng hoạt động</div><h3 class="stat-value"><%= inactiveUsers %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-diagram-3-fill"></i></div>
                        <div><div class="stat-label">Vai trò hệ thống</div><h3 class="stat-value"><%= totalRoles %></h3></div>
                    </div></div></div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <div class="card border-0 shadow-sm h-100"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-key-fill"></i></div>
                            <div><div class="stat-label">Đặt lại mật khẩu trong 7 ngày</div><h3 class="stat-value"><%= resetCount7d %></h3></div>
                        </div></div>
                    </div>
                    <div class="col-md-6">
                        <div class="card border-0 shadow-sm h-100"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-shield-lock"></i></div>
                            <div><div class="stat-label">Đổi mật khẩu trong 7 ngày</div><h3 class="stat-value"><%= changeCount7d %></h3></div>
                        </div></div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-lg-5">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-pie-chart-fill me-2 text-primary"></i>Người dùng theo vai trò</span></div>
                            <div class="card-body d-flex align-items-center justify-content-center" style="height: 300px;">
                                <canvas id="roleChart"></canvas>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-7">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-activity me-2 text-primary"></i>Hoạt động hệ thống gần đây</span></div>
                            <div class="card-body p-0">
                                <% if (recentSystemLogs != null && !recentSystemLogs.isEmpty()) { %>
                                <ul class="list-group list-group-flush">
                                    <% for (AuditLog log : recentSystemLogs) { %>
                                    <li class="list-group-item d-flex justify-content-between align-items-center px-4 py-2">
                                        <span class="small">
                                            <strong><%= log.getUsername() != null ? log.getUsername() : "Hệ thống" %></strong>
                                            <span class="text-muted">— <%= log.getAction() %></span>
                                        </span>
                                        <span class="text-muted small"><%= activityFmt.format(log.getCreatedAt()) %></span>
                                    </li>
                                    <% } %>
                                </ul>
                                <% } else { %>
                                <div class="empty-state"><i class="bi bi-inbox"></i><p>Không có hoạt động gần đây để hiển thị.</p></div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/admin/user?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile">
                                <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-people"></i></div>
                                <div><div class="stat-label">Quản trị</div><h3 class="stat-value fs-6">Người dùng</h3></div>
                            </div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/admin/role?action=list" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile">
                                <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-diagram-3"></i></div>
                                <div><div class="stat-label">Quản trị</div><h3 class="stat-value fs-6">Vai trò &amp; quyền</h3></div>
                            </div>
                        </a>
                    </div>
                    <div class="col-xl-3 col-md-6">
                        <a href="<%= request.getContextPath() %>/admin/audit-log" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile">
                                <div class="stat-icon bg-secondary bg-opacity-10 text-secondary"><i class="bi bi-journal-text"></i></div>
                                <div><div class="stat-label">Quản trị</div><h3 class="stat-value fs-6">Nhật ký hệ thống</h3></div>
                            </div>
                        </a>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        new Chart(document.getElementById('roleChart'), {
            type: 'doughnut',
            data: {
                labels: <%= roleLabelsJson.toString() %>,
                datasets: [{
                    data: <%= roleDataJson.toString() %>,
                    backgroundColor: ['#4f46e5', '#0ea5e9', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6']
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
        });
    </script>
</body>
</html>
