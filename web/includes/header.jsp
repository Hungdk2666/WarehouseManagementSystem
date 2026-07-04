<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%
    User loggedUser = (User) session.getAttribute("user");
%>
<nav class="navbar navbar-expand-lg navbar-light navbar-custom py-2">
    <div class="container-fluid px-4">
        <a class="navbar-brand d-flex align-items-center" href="<%= request.getContextPath() %>/index.jsp">
            <i class="bi bi-box-seam-fill text-primary me-2 fs-4"></i>
            <span class="d-flex flex-column lh-sm">
                <span>WMS</span>
                <small class="text-muted fw-semibold" style="font-size: 0.68rem;">Warehouse Management</small>
            </span>
        </a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarContent" aria-controls="navbarContent" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav ms-auto align-items-center gap-2">
                <% if (loggedUser != null) { %>
                <!-- Notification Dropdown -->
                <li class="nav-item dropdown me-2">
                    <a class="nav-link px-3 position-relative" href="#" id="notificationDropdown" role="button" data-bs-toggle="dropdown" aria-expanded="false" onclick="if(typeof window.updateHeaderBadge === 'function') window.updateHeaderBadge();">
                        <i class="bi bi-bell fs-5" id="headerBellIcon"></i>
                        <span class="position-absolute top-2 start-75 translate-middle badge rounded-pill bg-danger d-none" id="headerNotiBadge" style="font-size: 0.7rem;">
                            0
                        </span>
                    </a>
                    <div class="dropdown-menu dropdown-menu-end shadow border-0 py-0 overflow-hidden" aria-labelledby="notificationDropdown" style="width: 340px; border-radius: 12px;">
                        <div class="p-3 border-bottom d-flex justify-content-between align-items-center bg-light">
                            <span class="fw-bold text-slate-800 small">Thông báo</span>
                            <a href="#" class="text-primary small fw-semibold text-decoration-none" onclick="event.stopPropagation(); headerMarkAllRead()">Đánh dấu tất cả là đã đọc</a>
                        </div>
                        <div class="list-group list-group-flush" id="headerNotiList" style="max-height: 300px; overflow-y: auto;">
                            <!-- Dynamic Content -->
                            <div class="text-center py-4 text-muted small">Đang tải...</div>
                        </div>
                        <div class="p-2 border-top text-center bg-light">
                            <a href="<%= request.getContextPath() %>/notifications" class="text-primary small fw-semibold text-decoration-none d-block py-1">Xem tất cả thông báo</a>
                        </div>
                    </div>
                </li>
                <% } %>
                <% if (loggedUser != null && loggedUser.getWarehouseId() != null) { %>
                <li class="nav-item">
                    <span class="badge bg-primary bg-opacity-10 text-primary d-flex align-items-center gap-1 px-3 py-2" style="font-size: 0.8rem; border-radius: 20px; font-weight: 600;">
                        <i class="bi bi-building-fill"></i>
                        <%= loggedUser.getWarehouseName() != null ? loggedUser.getWarehouseName() : "Kho #" + loggedUser.getWarehouseId() %>
                    </span>
                </li>
                <% } %>
                <li class="nav-item">
                    <a class="nav-link profile-identity px-2" href="<%= request.getContextPath() %>/profile" aria-label="Mở trang cá nhân">
                        <span class="profile-avatar" aria-hidden="true"><i class="bi bi-person-fill"></i></span>
                        <span class="profile-copy">
                            <span class="profile-name"><%= loggedUser.getFullName() != null && !loggedUser.getFullName().trim().isEmpty() ? loggedUser.getFullName() : loggedUser.getUsername() %></span>
                            <span class="profile-role"><i class="bi bi-shield-check"></i><%= loggedUser.getRoleName() != null && !loggedUser.getRoleName().trim().isEmpty() ? loggedUser.getRoleName() : "Nhân viên" %></span>
                        </span>
                        <i class="bi bi-chevron-down profile-chevron" aria-hidden="true"></i>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="btn btn-outline-secondary btn-sm px-3" href="<%= request.getContextPath() %>/logout">
                        <i class="bi bi-box-arrow-right me-1"></i> Đăng xuất
                    </a>
                </li>
            </ul>
        </div>
    </div>
</nav>

<% if (loggedUser != null) { %>
<!-- Bootstrap Bundle JS Dynamic Loader -->
<script>
    (function() {
        function loadBootstrap() {
            if (typeof bootstrap === 'undefined') {
                const script = document.createElement('script');
                script.src = "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js";
                script.type = "text/javascript";
                document.head.appendChild(script);
            }
        }
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', loadBootstrap);
        } else {
            loadBootstrap();
        }
    })();
</script>

<!-- CSS for Notification animations -->
<style>
    @keyframes shake {
        0% { transform: rotate(0deg); }
        15% { transform: rotate(15deg); }
        30% { transform: rotate(-15deg); }
        45% { transform: rotate(10deg); }
        60% { transform: rotate(-10deg); }
        75% { transform: rotate(5deg); }
        85% { transform: rotate(-5deg); }
        100% { transform: rotate(0deg); }
    }
    .bell-shake {
        animation: shake 0.6s ease-in-out;
    }
    .noti-item {
        transition: background-color 0.2s;
        font-size: 0.85rem;
        cursor: pointer;
        color: #1e293b !important;
    }
    .noti-item.unread {
        background-color: rgba(13, 110, 253, 0.03);
    }
    .noti-item:hover {
        background-color: rgba(0, 0, 0, 0.02);
        color: #0f172a !important;
    }
    .noti-item .fw-bold {
        color: #1e293b !important;
    }
    .noti-item:hover .fw-bold {
        color: #0f172a !important;
    }
    .noti-item .text-muted {
        color: #64748b !important;
    }
    .noti-item-unread-dot {
        width: 6px;
        height: 6px;
        background-color: #0d6efd;
        border-radius: 50%;
        display: inline-block;
        flex-shrink: 0;
    }

    /* Header account identity */
    .profile-identity{display:inline-flex!important;align-items:center;gap:.58rem;min-height:2.65rem;padding:.25rem .55rem!important;border:1px solid transparent;color:var(--slate-700)!important;background:transparent;white-space:nowrap}
    .profile-identity:hover,.profile-identity:focus{border-color:var(--slate-200);background:var(--slate-50)!important;color:var(--slate-900)!important}
    .profile-avatar{width:2.15rem;height:2.15rem;display:inline-flex;flex:0 0 2.15rem;align-items:center;justify-content:center;border:1px solid rgba(37,99,235,.18);border-radius:50%;color:var(--primary);background:var(--primary-soft);font-size:1rem}
    .profile-copy{min-width:0;display:flex;flex-direction:column;align-items:flex-start;gap:.08rem;line-height:1.12}
    .profile-name{max-width:13rem;overflow:hidden;color:var(--slate-800);font-size:.84rem;font-weight:900;text-overflow:ellipsis}
    .profile-role{display:inline-flex;align-items:center;gap:.28rem;max-width:13rem;overflow:hidden;color:var(--slate-500);font-size:.68rem;font-weight:800;text-overflow:ellipsis}
    .profile-role i{color:var(--accent);font-size:.7rem}
    .profile-chevron{margin-left:.08rem;color:var(--slate-400);font-size:.7rem;transition:transform .18s ease}
    .profile-identity:hover .profile-chevron,.profile-identity:focus .profile-chevron{color:var(--primary);transform:translateY(1px)}
    @media (max-width:767.98px){.profile-identity{width:100%;justify-content:flex-start;padding:.55rem .7rem!important}.profile-name,.profile-role{max-width:calc(100vw - 7rem)}.profile-chevron{margin-left:auto}}
</style>

<!-- JS for Live Notification Polling -->
<script>
    (function() {
        const headerCtxPath = '<%= request.getContextPath() %>';
        let lastUnreadCount = 0;

        function updateHeaderNotifications() {
            fetch(headerCtxPath + '/api/notifications?action=getRecent')
                .then(response => {
                    if (!response.ok) throw new Error('Not logged in or network error');
                    return response.json();
                })
                .then(data => {
                    const badge = document.getElementById('headerNotiBadge');
                    const listContainer = document.getElementById('headerNotiList');
                    const bell = document.getElementById('headerBellIcon');

                    // 1. Update Badge
                    const unread = data.unreadCount;
                    if (unread > 0) {
                        badge.innerText = unread > 99 ? '99+' : unread;
                        badge.classList.remove('d-none');
                        
                        // Micro-animation: shake bell if unread count increased
                        if (unread > lastUnreadCount) {
                            bell.classList.add('bell-shake');
                            setTimeout(() => {
                                bell.classList.remove('bell-shake');
                            }, 650);
                        }
                    } else {
                        badge.classList.add('d-none');
                    }
                    lastUnreadCount = unread;

                    // 2. Render List
                    const list = data.notifications;
                    if (!list || list.length === 0) {
                        listContainer.innerHTML = `
                            <div class="text-center py-4 text-muted small">
                                <i class="bi bi-bell-slash d-block mb-1 fs-5 opacity-50"></i>
                                Không có thông báo
                            </div>
                        `;
                        return;
                    }

                    let html = '';
                    list.forEach(n => {
                        const unreadClass = n.isRead ? 'read' : 'unread';
                        const dotHtml = n.isRead ? '' : '<span class="noti-item-unread-dot mt-1"></span>';
                        const bellClass = n.isRead ? 'bi-bell' : 'bi-bell-fill';
                        
                        html += '<div class="list-group-item p-3 d-flex align-items-start gap-2 noti-item ' + unreadClass + '" ' +
                                'onclick="headerHandleClick(' + n.id + ', \'' + n.link + '\')">' +
                                '<div class="text-primary mt-0.5" style="font-size: 1.1rem;">' +
                                    '<i class="bi ' + bellClass + '"></i>' +
                                '</div>' +
                                '<div class="flex-grow-1 min-w-0">' +
                                    '<div class="d-flex align-items-center gap-1.5 mb-0.5">' +
                                        '<span class="fw-bold text-slate-800 text-truncate" style="max-width: 240px;">' + n.title + '</span>' +
                                        dotHtml +
                                    '</div>' +
                                    '<p class="text-muted mb-0.5 text-wrap-pretty" style="line-height: 1.25;">' + n.message + '</p>' +
                                    '<span class="text-muted text-opacity-75" style="font-size: 0.75rem;">' + n.createdAt + '</span>' +
                                '</div>' +
                            '</div>';
                    });
                    listContainer.innerHTML = html;
                })
                .catch(err => {
                    // Fail silently or clear interval if user logs out
                });
        }

        window.headerHandleClick = function(id, link) {
            fetch(headerCtxPath + '/api/notifications?action=markRead&id=' + id, { method: 'POST' })
                .then(() => {
                    if (link && link.trim() !== '') {
                        window.location.href = headerCtxPath + link;
                    } else {
                        updateHeaderNotifications();
                    }
                })
                .catch(() => {
                    if (link && link.trim() !== '') {
                        window.location.href = headerCtxPath + link;
                    }
                });
        };

        window.headerMarkAllRead = function() {
            fetch(headerCtxPath + '/api/notifications?action=markAllRead', { method: 'POST' })
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        updateHeaderNotifications();
                        // If we are on the main notifications page, reload it too
                        if (window.location.pathname.endsWith('/notifications')) {
                            location.reload();
                        }
                    }
                })
                .catch(err => console.error('Error marking all as read:', err));
        };

        // Expose global callback for other pages to trigger updates
        window.updateHeaderBadge = updateHeaderNotifications;

        // Poll immediately and then every 15 seconds
        updateHeaderNotifications();
        setInterval(updateHeaderNotifications, 15000);
    })();
</script>
<% } %>


