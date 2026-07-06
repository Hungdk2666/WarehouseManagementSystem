<%@page import="model.User"%>
<%@page import="model.Notification"%>
<%@page import="java.util.List"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Notification> notifications = (List<Notification>) request.getAttribute("notifications");
    int currentPage = (int) request.getAttribute("currentPage");
    int totalPages = (int) request.getAttribute("totalPages");
    int totalCount = (int) request.getAttribute("totalCount");
    
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Thông báo - WMS</title>
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
        .notification-row {
            transition: background-color 0.2s ease;
            cursor: pointer;
        }
        .notification-row.unread {
            background-color: rgba(37, 99, 235, 0.04);
            border-left: 3px solid var(--primary);
        }
        .notification-row.read {
            border-left: 3px solid transparent;
        }
        .notification-row:hover {
            background-color: var(--slate-50) !important;
        }
        .unread-dot {
            width: 7px;
            height: 7px;
            background-color: var(--primary);
            border-radius: 50%;
            display: inline-block;
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
                        <h2 class="page-title">Thông báo</h2>
                        <p class="page-subtitle">Cập nhật các nhiệm vụ quan trọng và hoạt động hệ thống</p>
                    </div>
                    <div class="d-flex gap-2">
                        <button type="button" class="btn btn-outline-primary btn-sm px-3 py-2 d-flex align-items-center gap-1" onclick="markAllAsRead()">
                            <i class="bi bi-check2-all"></i> Đánh dấu tất cả đã đọc
                        </button>
                    </div>
                </div>

                <!-- Notifications Card -->
                <div class="card bg-white">
                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center border-bottom">
                        <span class="fw-bold text-slate-800"><i class="bi bi-bell-fill me-2 text-primary"></i>Danh sách thông báo (tổng số <%= totalCount %>)</span>
                    </div>
                    <div class="card-body p-0">
                        <% if (notifications != null && !notifications.isEmpty()) { %>
                            <div class="list-group list-group-flush">
                                <% for (Notification n : notifications) { %>
                                    <div id="noti-row-<%= n.getId() %>" 
                                         class="list-group-item p-4 d-flex justify-content-between align-items-start notification-row <%= n.isRead() ? "read" : "unread" %>"
                                         onclick="handleNotificationClick(<%= n.getId() %>, '<%= n.getLink() %>')">
                                        <div class="d-flex gap-3">
                                            <div class="fs-4 text-primary mt-1">
                                                <i class="bi <%= n.isRead() ? "bi-bell" : "bi-bell-fill" %>"></i>
                                            </div>
                                            <div>
                                                <div class="d-flex align-items-center gap-2 mb-1">
                                                    <h6 class="mb-0 fw-bold <%= n.isRead() ? "text-slate-700" : "text-slate-900" %>">
                                                        <%= n.getTitle() %>
                                                    </h6>
                                                    <% if (!n.isRead()) { %>
                                                        <span class="unread-dot" id="dot-<%= n.getId() %>"></span>
                                                    <% } %>
                                                </div>
                                                <p class="mb-2 text-slate-600 <%= n.isRead() ? "text-opacity-75" : "" %>" style="font-size: 0.95rem;">
                                                    <%= n.getMessage() %>
                                                </p>
                                                <span class="text-muted small"><i class="bi bi-clock me-1"></i><%= sdf.format(n.getCreatedAt()) %></span>
                                            </div>
                                        </div>
                                        <div class="d-flex align-items-center gap-2 ms-2">
                                            <% if (n.getLink() != null && !n.getLink().isEmpty()) { %>
                                                <a href="<%= request.getContextPath() %><%= n.getLink() %>" class="btn btn-sm btn-light py-1 px-3" onclick="event.stopPropagation(); markRead(<%= n.getId() %>)">
                                                    <i class="bi bi-box-arrow-up-right me-1"></i> Xem
                                                </a>
                                            <% } %>
                                            <% if (!n.isRead()) { %>
                                                <button type="button" class="btn btn-sm btn-outline-secondary py-1 px-2" onclick="event.stopPropagation(); markRead(<%= n.getId() %>, this)">
                                                    <i class="bi bi-check"></i> Đã đọc
                                                </button>
                                            <% } %>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        <% } else { %>
                            <div class="empty-state">
                                <i class="bi bi-bell-slash"></i>
                                <p>Bạn không có thông báo nào.</p>
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Pagination -->
                <% if (totalPages > 1) { %>
                <nav aria-label="Page navigation" class="mt-4">
                    <ul class="pagination justify-content-center">
                        <li class="page-item <%= currentPage == 1 ? "disabled" : "" %>">
                            <a class="page-link d-flex align-items-center gap-1" href="notifications?page=<%= currentPage - 1 %>" aria-label="Previous">
                                <i class="bi bi-chevron-left"></i> Trước
                            </a>
                        </li>
                        
                        <% for (int i = 1; i <= totalPages; i++) { %>
                            <li class="page-item <%= currentPage == i ? "active" : "" %>">
                                <a class="page-link" href="notifications?page=<%= i %>"><%= i %></a>
                            </li>
                        <% } %>
                        
                        <li class="page-item <%= currentPage == totalPages ? "disabled" : "" %>">
                            <a class="page-link d-flex align-items-center gap-1" href="notifications?page=<%= currentPage + 1 %>" aria-label="Next">
                                Sau <i class="bi bi-chevron-right"></i>
                            </a>
                        </li>
                    </ul>
                </nav>
                <% } %>
            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        const ctxPath = '<%= request.getContextPath() %>';

        function handleNotificationClick(id, link) {
            markRead(id).then(() => {
                if (link && link.trim() !== '') {
                    window.location.href = ctxPath + link;
                }
            });
        }

        function markRead(id, btnElement) {
            return fetch(ctxPath + '/api/notifications?action=markRead&id=' + id, {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const row = document.getElementById('noti-row-' + id);
                    if (row) {
                        row.classList.remove('unread');
                        row.classList.add('read');
                    }
                    const dot = document.getElementById('dot-' + id);
                    if (dot) dot.remove();
                    if (btnElement) btnElement.remove();
                    
                    // Trigger global header unread badge update if function exists
                    if (typeof updateHeaderBadge === 'function') {
                        updateHeaderBadge();
                    }
                }
            })
            .catch(err => console.error('Error marking notification as read:', err));
        }

        function markAllAsRead() {
            fetch(ctxPath + '/api/notifications?action=markAllRead', {
                method: 'POST'
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    location.reload();
                }
            })
            .catch(err => console.error('Error marking all as read:', err));
        }
    </script>
</body>
</html>
