<%@page import="model.User"%>
<%@page import="model.Request"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.Comparator"%>
<%@page import="dao.RequestDAO"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    RequestDAO requestDAO = new RequestDAO();
    List<Request> myRequests = new ArrayList<>();
    for (Request r : requestDAO.getAll("IN")) { if (r.getStaffId() == user.getId()) myRequests.add(r); }
    for (Request r : requestDAO.getAll("OUT")) { if (r.getStaffId() == user.getId()) myRequests.add(r); }
    myRequests.sort(Comparator.comparing(Request::getCreatedAt).reversed());

    int total = myRequests.size();
    int pending = 0, approvedOrProcessing = 0, completed = 0, rejectedOrCancelled = 0;
    for (Request r : myRequests) {
        String status = r.getStatus();
        if ("PENDING".equals(status)) pending++;
        else if ("APPROVED".equals(status) || "PARTIALLY_COMPLETED".equals(status)
                || "PARTIALLY_IN_TRANSIT".equals(status) || "IN_TRANSIT".equals(status)
                || "RETURNING".equals(status)) approvedOrProcessing++;
        else if ("COMPLETED".equals(status) || "RETURNED".equals(status)) completed++;
        else if ("REJECTED".equals(status) || "CANCELLED".equals(status)
                || "REVOKED".equals(status) || "PARTIALLY_CLOSED".equals(status)) rejectedOrCancelled++;
    }

    List<Request> recent = myRequests.size() > 8 ? myRequests.subList(0, 8) : myRequests;
    SimpleDateFormat dateFmt = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard Nhân viên kinh doanh - WMS</title>
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
                        <p class="page-subtitle mb-0">Dashboard Nhân viên kinh doanh — theo dõi yêu cầu do bạn tạo</p>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-inboxes-fill"></i></div>
                        <div><div class="stat-label">Tổng yêu cầu đã tạo</div><h3 class="stat-value"><%= total %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-hourglass-split"></i></div>
                        <div><div class="stat-label">Đang chờ duyệt</div><h3 class="stat-value"><%= pending %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-info bg-opacity-10 text-info"><i class="bi bi-arrow-repeat"></i></div>
                        <div><div class="stat-label">Đã duyệt / đang xử lý</div><h3 class="stat-value"><%= approvedOrProcessing %></h3></div>
                    </div></div></div>
                    <div class="col-xl-3 col-sm-6"><div class="card border-0 shadow-sm"><div class="card-body p-3 stat-tile">
                        <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-check-circle-fill"></i></div>
                        <div><div class="stat-label">Hoàn tất</div><h3 class="stat-value"><%= completed %></h3></div>
                    </div></div></div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-lg-4">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-pie-chart-fill me-2 text-primary"></i>Tỷ lệ trạng thái yêu cầu</span></div>
                            <div class="card-body d-flex align-items-center justify-content-center" style="height: 280px;"><canvas id="statusChart"></canvas></div>
                        </div>
                    </div>
                    <div class="col-lg-8">
                        <div class="card border-0 shadow-sm h-100">
                            <div class="card-header bg-white py-3"><span class="fw-bold text-slate-800"><i class="bi bi-clock-history me-2 text-primary"></i>Yêu cầu gần đây của bạn</span></div>
                            <div class="card-body p-0">
                                <% if (!recent.isEmpty()) { %>
                                <div class="table-responsive">
                                    <table class="table align-middle mb-0">
                                        <thead class="table-light"><tr><th class="ps-3">Mã yêu cầu</th><th>Loại</th><th>Trạng thái</th><th>Ngày tạo</th><th></th></tr></thead>
                                        <tbody>
                                        <% for (Request r : recent) {
                                            String badge = "secondary";
                                            String statusLabel = r.getStatus();
                                            if ("PENDING".equals(r.getStatus())) { badge = "warning"; statusLabel = "Chờ duyệt"; }
                                            else if ("APPROVED".equals(r.getStatus())) { badge = "info"; statusLabel = "Đã duyệt"; }
                                            else if ("PARTIALLY_COMPLETED".equals(r.getStatus())) { badge = "info"; statusLabel = "Đang xử lý"; }
                                            else if ("PARTIALLY_IN_TRANSIT".equals(r.getStatus())) { badge = "info"; statusLabel = "Đang chuyển một phần"; }
                                            else if ("IN_TRANSIT".equals(r.getStatus())) { badge = "info"; statusLabel = "Đang chuyển"; }
                                            else if ("RETURNING".equals(r.getStatus())) { badge = "warning"; statusLabel = "Đang trả về nguồn"; }
                                            else if ("RETURNED".equals(r.getStatus())) { badge = "success"; statusLabel = "Đã trả về nguồn"; }
                                            else if ("PARTIALLY_CLOSED".equals(r.getStatus())) { badge = "secondary"; statusLabel = "Đã đóng một phần"; }
                                            else if ("REVOKED".equals(r.getStatus())) { badge = "secondary"; statusLabel = "Đã thu hồi"; }
                                            else if ("COMPLETED".equals(r.getStatus())) { badge = "success"; statusLabel = "Hoàn tất"; }
                                            else if ("REJECTED".equals(r.getStatus())) { badge = "danger"; statusLabel = "Bị từ chối"; }
                                            else if ("CANCELLED".equals(r.getStatus())) { badge = "secondary"; statusLabel = "Đã hủy"; }
                                            String detailUrl = r.isIn()
                                                ? request.getContextPath() + "/warehouse/import-request?action=detail&id=" + r.getId()
                                                : request.getContextPath() + "/warehouse/export-request?action=detail&id=" + r.getId();
                                        %>
                                        <tr>
                                            <td class="ps-3 font-monospace small">#<%= r.getRequestCode() %></td>
                                            <td class="small"><%= r.isIn() ? "Nhập kho" : "Xuất kho" %></td>
                                            <td><span class="badge bg-<%= badge %> bg-opacity-10 text-<%= badge %>"><%= statusLabel %></span></td>
                                            <td class="small text-muted"><%= dateFmt.format(r.getCreatedAt()) %></td>
                                            <td class="text-end pe-3"><a href="<%= detailUrl %>" class="btn btn-table btn-outline-secondary" title="Xem"><i class="bi bi-eye"></i></a></td>
                                        </tr>
                                        <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                <% } else { %>
                                <div class="empty-state"><i class="bi bi-inbox"></i><p>Bạn chưa tạo yêu cầu nào.</p></div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mb-4">
                    <div class="col-xl-4 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/import-request?action=add" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-box-arrow-in-down-left"></i></div>
                            <div><div class="stat-label">Tạo mới</div><h3 class="stat-value fs-6">Yêu cầu nhập</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-4 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/export-request?action=add" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-box-arrow-up-right"></i></div>
                            <div><div class="stat-label">Tạo mới</div><h3 class="stat-value fs-6">Yêu cầu xuất</h3></div></div>
                        </a>
                    </div>
                    <div class="col-xl-4 col-md-6">
                        <a href="<%= request.getContextPath() %>/warehouse/customer?action=add" class="card h-100 text-decoration-none">
                            <div class="card-body p-3 stat-tile"><div class="stat-icon bg-primary bg-opacity-10 text-primary"><i class="bi bi-person-plus-fill"></i></div>
                            <div><div class="stat-label">Thêm mới</div><h3 class="stat-value fs-6">Khách hàng</h3></div></div>
                        </a>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
        new Chart(document.getElementById('statusChart'), {
            type: 'doughnut',
            data: {
                labels: ['Chờ duyệt', 'Đã duyệt/Đang xử lý', 'Hoàn tất', 'Từ chối/Hủy'],
                datasets: [{
                    data: [<%= pending %>, <%= approvedOrProcessing %>, <%= completed %>, <%= rejectedOrCancelled %>],
                    backgroundColor: ['#f59e0b', '#0ea5e9', '#22c55e', '#94a3b8']
                }]
            },
            options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { position: 'bottom' } } }
        });
    </script>
</body>
</html>
