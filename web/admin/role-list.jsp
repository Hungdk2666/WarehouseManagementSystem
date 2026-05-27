<%@page import="model.Role"%>
<<<<<<< HEAD
<%@page import="model.Permission"%>
=======
>>>>>>> origin/main
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Role> roleList = (List<Role>) request.getAttribute("roleList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Role & Permission Management - WMS</title>
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
                        <h2 class="fw-bold text-slate-800 mb-1">Role & Permission Management</h2>
                        <p class="text-muted small mb-0">Configure system roles, access levels, and assign permissions</p>
                    </div>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back to Dashboard
                    </a>
                </div>

                <!-- Navigation Tabs -->
                <ul class="nav nav-tabs border-bottom mb-4" id="rbacTabs" role="tablist" style="border-width: 2px !important;">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active fw-semibold text-primary border-bottom border-primary border-3 bg-transparent px-4 py-2.5" id="roles-tab" data-bs-toggle="tab" data-bs-target="#roles-pane" type="button" role="tab" aria-controls="roles-pane" aria-selected="true" style="border-radius: 0; border-top: 0; border-left: 0; border-right: 0;">
                            <i class="bi bi-shield-check me-2"></i>Roles Directory
                        </button>
                    </li>
                </ul>

                <!-- Tabs Content -->
                <div class="tab-content" id="rbacTabsContent">
                    
                    <!-- Roles Tab Pane -->
                    <div class="tab-pane fade show active" id="roles-pane" role="tabpanel" aria-labelledby="roles-tab">
                        <div class="card shadow-sm border-0 bg-white mb-4">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                                <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-safe-fill me-2"></i>System Access Roles</h5>
                                <button class="btn btn-primary btn-sm d-flex align-items-center gap-1.5" data-bs-toggle="modal" data-bs-target="#addRoleModal">
                                    <i class="bi bi-plus-circle-fill"></i> Add New Role
                                </button>
                            </div>
                            <div class="card-body p-0">
                                <div class="table-responsive">
                                    <table class="table table-hover align-middle text-center mb-0">
                                        <thead>
                                            <tr>
                                                <th>ID</th>
                                                <th>Role Name</th>
                                                <th>Status</th>
                                                <th>Actions</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                if (roleList != null && !roleList.isEmpty()) {
                                                    for (Role r : roleList) {
                                            %>
                                            <tr>
                                                <td class="fw-semibold text-muted">#<%= r.getId() %></td>
                                                <td class="fw-bold text-slate-800"><%= r.getRoleName() %></td>
                                                <td>
                                                    <% if (r.isStatus()) { %>
                                                        <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Active</span>
                                                    <% } else { %>
                                                        <span class="badge bg-secondary bg-opacity-10 text-secondary px-2.5 py-1.5"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Inactive</span>
                                                    <% } %>
                                                </td>
                                                <td>
                                                    <div class="d-flex align-items-center justify-content-center gap-1">
                                                        <a href="role?action=permissions&id=<%= r.getId() %>" class="btn btn-sm btn-info text-white d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Manage Permissions">
                                                            <i class="bi bi-shield-lock"></i> Permissions
                                                        </a>
                                                        <a href="role?action=update&id=<%= r.getId() %>" class="btn btn-sm btn-warning d-inline-flex align-items-center gap-1 py-1 px-2.5" title="Edit">
                                                            <i class="bi bi-pencil-square"></i> Edit
                                                        </a>
                                                        <form action="role?action=toggle" method="POST" class="d-inline m-0">
                                                            <input type="hidden" name="id" value="<%= r.getId() %>">
                                                            <button type="submit" class="btn btn-sm <%= r.isStatus() ? "btn-outline-danger" : "btn-primary" %> d-inline-flex align-items-center gap-1 py-1 px-2.5" title="<%= r.isStatus() ? "Deactivate Role" : "Activate Role" %>">
                                                                <i class="bi bi-power"></i> <%= r.isStatus() ? "Disable" : "Enable" %>
                                                            </button>
                                                        </form>
                                                    </div>
                                                </td>
                                            </tr>
                                            <%
                                                    }
                                                } else {
                                            %>
                                            <tr>
                                                <td colspan="4" class="text-center text-muted py-5">
                                                    <i class="bi bi-shield-slash text-muted display-4 d-block mb-3"></i>
                                                    No system roles registered.
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>

            </div>
        </div>
    </div>

    <!-- ADD ROLE MODAL -->
    <div class="modal fade" id="addRoleModal" tabindex="-1" aria-labelledby="addRoleModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg rounded-3">
                <div class="modal-header border-0 bg-primary bg-opacity-10 py-3">
                    <h5 class="modal-title fw-bold text-primary" id="addRoleModalLabel"><i class="bi bi-plus-circle-fill me-2"></i>Create New System Role</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <form action="role?action=addRole" method="POST" class="m-0">
                    <div class="modal-body p-4">
                        <div class="mb-3">
                            <label for="roleNameInput" class="form-label">Role Name</label>
                            <input type="text" class="form-control" id="roleNameInput" name="role_name" placeholder="Enter role name (e.g. Warehouse Manager)" required>
                        </div>
                        <div class="mb-2">
                            <label for="roleStatusSelect" class="form-label">Initial Status</label>
                            <select class="form-select" id="roleStatusSelect" name="status">
                                <option value="true" selected>Active</option>
                                <option value="false">Inactive</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer border-0 p-3 bg-light d-flex justify-content-end gap-2">
                        <button type="button" class="btn btn-secondary px-3" data-bs-dismiss="modal"><i class="bi bi-x-circle me-1"></i> Cancel</button>
                        <button type="submit" class="btn btn-primary px-3"><i class="bi bi-plus-lg me-1"></i> Create Role</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS (includes Popper) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
