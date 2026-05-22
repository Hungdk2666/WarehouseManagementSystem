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
    <title>Manage Role Permissions - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
                    <div class="col-md-6">
                        <div class="card shadow-sm">
                            <div class="card-header bg-primary text-white">
                                <h5 class="mb-0">Edit Role Permissions for <%= roleInfo.getRoleName() %></h5>
                            </div>
                            <div class="card-body">
                                <form action="role?action=permissions" method="POST">
                                    <input type="hidden" name="id" value="<%= roleInfo.getId() %>">
                                    <div class="mb-3">
                                        <div class="list-group">
                                            <%
                                                if (allPerms.isEmpty()) {
                                            %>
                                                <div class="list-group-item text-center text-muted">No permissions found</div>
                                            <%
                                                } else {
                                                    for (Permission p : allPerms) {
                                                        boolean hasPerm = assignedPerms != null && assignedPerms.contains(p.getId());
                                                        boolean isSystemAdmin = (roleInfo.getId() == 1);
                                                        boolean isSystemAdminPerm = (p.getId() == 1 || p.getId() == 2 || p.getId() == 3);

                                                        boolean isDisabled = (isSystemAdmin && !isSystemAdminPerm) || (!isSystemAdmin && isSystemAdminPerm);;
                                            %>
                                                <label class="list-group-item d-flex gap-2 <%= isDisabled ? "bg-light text-muted" : "" %>">
                                                    <input class="form-check-input flex-shrink-0" type="checkbox" name="permissions" value="<%= p.getId() %>" 
                                                        <% if (hasPerm) { out.print("checked"); } %> 
                                                        <% if (isDisabled) { out.print("disabled"); } %> >
                                                    <span>
                                                        <strong><%= p.getPermissionName() %></strong>
                                                        <% if (isDisabled) { %>
                                                            <span class="badge bg-danger">Disabled</span>
                                                        <% } %>
                                                        <small class="d-block text-muted"><%= p.getDescription() != null ? p.getDescription() : "" %></small>
                                                    </span>
                                                </label>
                                            <%
                                                    }
                                                }
                                            %>
                                        </div>
                                    </div>
                                    <div class="d-grid gap-2 d-md-flex justify-content-md-end">
                                        <a href="role?action=list" class="btn btn-secondary me-md-2">Cancel</a>
                                        <button type="submit" class="btn btn-primary">Save Permissions</button>
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
