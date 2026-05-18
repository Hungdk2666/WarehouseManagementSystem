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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                <div class="row justify-content-center">
        <div class="row justify-content-center">
            <div class="col-md-6">
                <div class="card shadow-sm">
                    <div class="card-header bg-info text-white">
                        <h4 class="mb-0">Edit Permissions for Role: <%= roleInfo.getRoleName() %></h4>
                    </div>
                    <div class="card-body">
                        <form action="role?action=permissions" method="POST">
                            <input type="hidden" name="id" value="<%= roleInfo.getId() %>">
                            
                            <div class="mb-4">
                                <p class="text-muted">Select the permissions you want to assign to this role:</p>
                                <div class="list-group">
                                    <%
                                        if (allPerms.isEmpty()) {
                                    %>
                                        <div class="alert alert-warning">No permissions found in the database. Please insert test data directly into the DB.</div>
                                    <%
                                        } else {
                                            for (Permission p : allPerms) {
                                                boolean hasPerm = assignedPerms != null && assignedPerms.contains(p.getId());
                                    %>
                                        <label class="list-group-item d-flex gap-2">
                                            <input class="form-check-input flex-shrink-0" type="checkbox" name="permissions" value="<%= p.getId() %>" 
                                                <% if (hasPerm) { out.print("checked"); } %> >
                                            <span>
                                                <strong><%= p.getPermissionName() %></strong>
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
    </div>
</body>
</html>
