<%@page import="model.Role"%>
<%@page import="model.Permission"%>
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
    List<Permission> permissionList = (List<Permission>) request.getAttribute("permissionList");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Role & Permission Management - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h2>Role & Permission Management</h2>
                    <a href="<%= request.getContextPath() %>/index.jsp" class="btn btn-secondary">
                        Back to Dashboard
                    </a>
                </div>

                <!-- Navigation Tabs -->
                <ul class="nav nav-tabs mb-4" id="rbacTabs" role="tablist">
                    <li class="nav-item" role="presentation">
                        <button class="nav-link active" id="roles-tab" data-bs-toggle="tab" data-bs-target="#roles-pane" type="button" role="tab" aria-controls="roles-pane" aria-selected="true">
                            Roles Directory
                        </button>
                    </li>
                    <li class="nav-item" role="presentation">
                        <button class="nav-link" id="permissions-tab" data-bs-toggle="tab" data-bs-target="#permissions-pane" type="button" role="tab" aria-controls="permissions-pane" aria-selected="false">
                            Permissions Registry
                        </button>
                    </li>
                </ul>

                <!-- Tabs Content -->
                <div class="tab-content" id="rbacTabsContent">
                    
                    <!-- Roles Tab Pane -->
                    <div class="tab-pane fade show active" id="roles-pane" role="tabpanel" aria-labelledby="roles-tab">
                        <div class="card shadow-sm mb-4">
                            <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">System Access Roles</h5>
                                <button class="btn btn-light btn-sm" data-bs-toggle="modal" data-bs-target="#addRoleModal">
                                    Add New Role
                                </button>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-hover align-middle text-center mb-0">
                                        <thead class="table-dark">
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
                                                <td><%= r.getId() %></td>
                                                <td><%= r.getRoleName() %></td>
                                                <td>
                                                    <% if (r.isStatus()) { %>
                                                        <span class="badge bg-success">Active</span>
                                                    <% } else { %>
                                                        <span class="badge bg-secondary">Deactive</span>
                                                    <% } %>
                                                </td>
                                                <td>
                                                    <a href="role?action=permissions&id=<%= r.getId() %>" class="btn btn-sm btn-info text-white">Permissions</a>
                                                    <a href="role?action=update&id=<%= r.getId() %>" class="btn btn-sm btn-warning">Edit</a>
                                                    <form action="role?action=toggle" method="POST" class="d-inline">
                                                        <input type="hidden" name="id" value="<%= r.getId() %>">
                                                        <button type="submit" class="btn btn-sm <%= r.isStatus() ? "btn-danger" : "btn-primary" %>">
                                                            <%= r.isStatus() ? "Deactivate" : "Activate" %>
                                                        </button>
                                                    </form>
                                                </td>
                                            </tr>
                                            <%
                                                    }
                                                } else {
                                            %>
                                            <tr>
                                                <td colspan="4" class="text-muted py-4">No system roles registered.</td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Permissions Tab Pane -->
                    <div class="tab-pane fade" id="permissions-pane" role="tabpanel" aria-labelledby="permissions-tab">
                        <div class="card shadow-sm mb-4">
                            <div class="card-header bg-primary text-white d-flex justify-content-between align-items-center">
                                <h5 class="mb-0">System Access Permissions Registry</h5>
                                <button class="btn btn-light btn-sm" data-bs-toggle="modal" data-bs-target="#addPermissionModal">
                                    Add New Permission
                                </button>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive">
                                    <table class="table table-bordered table-hover align-middle text-center mb-0">
                                        <thead class="table-dark">
                                            <tr>
                                                <th>ID</th>
                                                <th>Permission Key</th>
                                                <th>Functional Description</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <%
                                                if (permissionList != null && !permissionList.isEmpty()) {
                                                    for (Permission p : permissionList) {
                                            %>
                                            <tr>
                                                <td><%= p.getId() %></td>
                                                <td><span class="badge bg-primary"><%= p.getPermissionName() %></span></td>
                                                <td class="text-start"><%= p.getDescription() != null ? p.getDescription() : "No description." %></td>
                                            </tr>
                                            <%
                                                    }
                                                } else {
                                            %>
                                            <tr>
                                                <td colspan="3" class="text-muted py-4">No access permissions found in database.</td>
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
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="addRoleModalLabel">Create New System Role</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <form action="role?action=addRole" method="POST">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="roleNameInput" class="form-label">Role Name</label>
                            <input type="text" class="form-control" id="roleNameInput" name="role_name" placeholder="Enter role name" required>
                        </div>
                        <div class="mb-3">
                            <label for="roleStatusSelect" class="form-label">Status</label>
                            <select class="form-select" id="roleStatusSelect" name="status">
                                <option value="true" selected>Active</option>
                                <option value="false">Inactive</option>
                            </select>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Create Role</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ADD PERMISSION MODAL -->
    <div class="modal fade" id="addPermissionModal" tabindex="-1" aria-labelledby="addPermissionModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="addPermissionModalLabel">Create New Permission</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <form action="role?action=addPermission" method="POST">
                    <div class="modal-body">
                        <div class="mb-3">
                            <label for="permNameInput" class="form-label">Permission Key</label>
                            <input type="text" class="form-control text-uppercase" id="permNameInput" name="permission_name" placeholder="e.g. MANAGE_DELIVERY" required>
                        </div>
                        <div class="mb-3">
                            <label for="permDescInput" class="form-label">Description</label>
                            <textarea class="form-control" id="permDescInput" name="description" rows="3" placeholder="Enter permission description..."></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-primary">Create Permission</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS (includes Popper) -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
