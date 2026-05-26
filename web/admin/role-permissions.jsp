<%@page import="model.Permission"%>
<%@page import="java.util.List"%>
<%@page import="model.Role"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
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
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Role Permissions</title>
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
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
                                        
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
                    <div class="col-md-6">
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-shield-lock-fill me-2"></i>Edit Role Permissions for <%= roleInfo.getRoleName() %></h5>
                            </div>
                            <div class="card-body p-4">
                                <form action="role?action=permissions" method="POST" class="m-0">
                                    <input type="hidden" name="id" value="<%= roleInfo.getId() %>">
                                    <div class="mb-4">
                                        <label class="form-label mb-3 text-slate-900"><i class="bi bi-check2-square me-1 text-muted"></i> Select Permissions for this Role</label>
                                        <div class="list-group list-group-flush border rounded-3 overflow-hidden">
                                            <%
                                                if (allPerms.isEmpty()) {
                                            %>
                                                <div class="list-group-item text-center text-muted py-4">No permissions found</div>
                                            <%
                                                } else {
                                                    for (Permission p : allPerms) {
                                                        boolean hasPerm = assignedPerms != null && assignedPerms.contains(p.getId());
                                                        boolean isSystemAdmin = (roleInfo.getId() == 1);
                                                        boolean isSystemAdminPerm = (p.getId() == 1 || p.getId() == 2 || p.getId() == 3);

                                                        boolean isDisabled = (isSystemAdmin && !isSystemAdminPerm) || (!isSystemAdmin && isSystemAdminPerm);;
                                            %>
                                                <label class="list-group-item d-flex gap-3 align-items-start py-3 px-4 <%= isDisabled ? "bg-light text-muted" : "" %>" style="cursor: pointer; transition: background-color 0.2s ease;">
                                                    <input class="form-check-input flex-shrink-0 mt-1" type="checkbox" name="permissions" value="<%= p.getId() %>" 
                                                        <% if (hasPerm) { out.print("checked"); } %> 
                                                        <% if (isDisabled) { out.print("disabled"); } %>
                                                        style="width: 1.15rem; height: 1.15rem; border-color: var(--slate-300);">
                                                    <span class="d-block">
                                                        <strong class="text-slate-800 d-inline-flex align-items-center gap-2">
                                                            <%= p.getPermissionName() %>
                                                            <% if (isDisabled) { %>
                                                                <span class="badge bg-danger bg-opacity-10 text-danger" style="font-size: 0.65rem;">System Required</span>
                                                            <% } %>
                                                        </strong>
                                                        <small class="d-block text-muted mt-0.5" style="font-size: 0.85rem;"><%= p.getDescription() != null ? p.getDescription() : "" %></small>
                                                    </span>
                                                </label>
                                            <%
                                                    }
                                                }
                                            %>
                                        </div>
                                    </div>
                                    <div class="d-flex justify-content-end gap-2 mt-4 pt-3 border-top border-light">
                                        <a href="role?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                                        <button type="submit" class="btn btn-primary px-4"><i class="bi bi-check-circle-fill me-1"></i> Save Permissions</button>
                                    </div>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
