<%@page import="model.Permission"%>
<%@page import="java.util.List"%>
<%@page import="model.Role"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("ROLE_ASSIGN")) {
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
                <div class="row justify-content-center">
                    <div class="col-xl-10 col-12">
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                                <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-shield-lock-fill me-2"></i>Edit Role Permissions for <%= roleInfo.getRoleName() %></h5>
                            </div>
                            <div class="card-body p-4">
                                <form action="role?action=permissions" method="POST" class="m-0">
                                    <input type="hidden" name="id" value="<%= roleInfo.getId() %>">
                                     <div class="mb-4">
                                         <div class="mb-3">
                                             <div class="input-group shadow-sm rounded-3">
                                                 <span class="input-group-text bg-white border-end-0 text-muted"><i class="bi bi-search text-muted"></i></span>
                                                 <input type="text" id="permissionSearch" class="form-control border-start-0 ps-0" placeholder="Search resources or actions (e.g. USER, EDIT)..." style="box-shadow: none;">
                                             </div>
                                         </div>
                                         
                                         <%
                                             // Group permissions by resource
                                             java.util.Map<String, java.util.List<Permission>> groupedPerms = new java.util.LinkedHashMap<>();
                                             if (allPerms != null) {
                                                 for (Permission p : allPerms) {
                                                     String name = p.getPermissionName();
                                                     int idx = name.lastIndexOf("_");
                                                     if (idx > 0) {
                                                         String resource = name.substring(0, idx);
                                                         if (!groupedPerms.containsKey(resource)) {
                                                             groupedPerms.put(resource, new java.util.ArrayList<Permission>());
                                                         }
                                                         groupedPerms.get(resource).add(p);
                                                     }
                                                 }
                                             }
                                         %>

                                         <div class="table-responsive border rounded-3 bg-white shadow-sm">
                                             <table id="permissionsTable" class="table table-bordered table-hover align-middle mb-0" style="font-size: 0.9rem;">
                                                 <thead class="table-light">
                                                     <tr>
                                                         <th class="text-start ps-4" style="width: 25%;">Resource</th>
                                                         <th class="text-start ps-4">Actions</th>
                                                     </tr>
                                                 </thead>
                                                <tbody>
                                                    <%
                                                        boolean isSystemAdmin = (roleInfo.getId() == 1);
                                                        if (groupedPerms.isEmpty()) {
                                                    %>
                                                        <tr>
                                                            <td colspan="2" class="text-muted py-4 text-center">No module permissions configured in database.</td>
                                                        </tr>
                                                    <%
                                                        } else {
                                                            for (java.util.Map.Entry<String, java.util.List<Permission>> entry : groupedPerms.entrySet()) {
                                                                String resource = entry.getKey();
                                                                java.util.List<Permission> rPerms = entry.getValue();
                                                                boolean isAdminResource = "USER".equals(resource) || "ROLE".equals(resource) || "SYSTEM_LOG".equals(resource);
                                                                boolean isRowEditable = isSystemAdmin ? isAdminResource : !isAdminResource;
                                                    %>
                                                        <tr class="<%= !isRowEditable ? "table-light text-muted" : "" %>" style="<%= !isRowEditable ? "opacity: 0.6;" : "" %>">
                                                            <td class="text-start fw-bold text-slate-800 ps-4 align-middle">
                                                                <span class="text-primary me-1">#</span><%= resource %>
                                                                <br>
                                                                <small class="fw-normal text-muted" style="font-size: 0.75rem;">
                                                                    <%= isAdminResource ? "Nghiệp vụ hệ thống" : "Nghiệp vụ kinh doanh" %>
                                                                </small>
                                                            </td>
                                                            <td class="text-start ps-4 py-3">
                                                                <div class="d-flex flex-wrap gap-4 align-items-center">
                                                                     <%
                                                                         for (Permission p : rPerms) {
                                                                             boolean hasPerm = assignedPerms != null && assignedPerms.contains(p.getId());
                                                                             String name = p.getPermissionName();
                                                                             String action = name.substring(name.lastIndexOf("_") + 1);
                                                                             
                                                                             boolean isEditable = isSystemAdmin ? isAdminResource : !isAdminResource;
                                                                             
                                                                             // Safety check: protect System Admin from unchecking ROLE_ASSIGN (lockout prevention)
                                                                             if (isSystemAdmin && "ROLE_ASSIGN".equals(name)) {
                                                                                 isEditable = false;
                                                                             }
                                                                     %>
                                                                         <div class="d-flex flex-column align-items-center gap-1 text-center" style="width: 75px;">
                                                                             <input class="form-check-input border-secondary-subtle m-0 <%= isEditable ? "cursor-pointer" : "" %>" 
                                                                                    type="checkbox" 
                                                                                    name="permissions" 
                                                                                    value="<%= p.getId() %>" 
                                                                                    <%= hasPerm ? "checked" : "" %> 
                                                                                    <%= !isEditable ? "disabled" : "" %>
                                                                                    style="width: 1.25rem; height: 1.25rem;"
                                                                                    title="<%= p.getDescription() %>">
                                                                             <% if (!isEditable && hasPerm) { %>
                                                                                 <input type="hidden" name="permissions" value="<%= p.getId() %>">
                                                                             <% } %>
                                                                             <span class="text-muted fw-semibold text-uppercase mt-1" style="font-size: 0.7rem; letter-spacing: 0.02em;"><%= action %></span>
                                                                         </div>
                                                                     <%
                                                                         }
                                                                     %>
                                                                </div>
                                                            </td>
                                                        </tr>
                                                    <%
                                                            }
                                                        }
                                                    %>
                                                </tbody>
                                            </table>
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
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const searchInput = document.getElementById('permissionSearch');
            if (searchInput) {
                // Prevent form submission when pressing Enter in search bar
                searchInput.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter') {
                        e.preventDefault();
                    }
                });

                searchInput.addEventListener('input', function() {
                    const query = this.value.toLowerCase().trim();
                    const rows = document.querySelectorAll('#permissionsTable tbody tr');
                    
                    if (query === '') {
                        rows.forEach(row => row.style.display = '');
                        return;
                    }

                    const words = query.split(/\s+/);

                    rows.forEach(row => {
                        if (row.cells.length < 2) return;
                        const resourceText = row.cells[0].textContent.toLowerCase();
                        const actionsText = row.cells[1].textContent.toLowerCase();
                        
                        // Get all checkbox description titles in this row
                        let descriptionsText = "";
                        row.querySelectorAll('input[type="checkbox"]').forEach(cb => {
                            if (cb.title) {
                                descriptionsText += " " + cb.title.toLowerCase();
                            }
                        });
                        
                        const rowText = resourceText + " " + actionsText + " " + descriptionsText;
                        
                        // Match if all search words are present in the row text (handling English plurals ending in 's')
                        const isMatch = words.every(word => {
                            if (rowText.includes(word)) return true;
                            if (word.endsWith('s') && word.length > 3 && rowText.includes(word.slice(0, -1))) return true;
                            return false;
                        });

                        if (isMatch) {
                            row.style.display = '';
                        } else {
                            row.style.display = 'none';
                        }
                    });
                });
            }
        });
    </script>
</body>
</html>
