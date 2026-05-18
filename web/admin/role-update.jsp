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
    if (roleInfo == null) {
        response.sendRedirect("role?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Role Info</title>
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
            <div class="col-md-5">
                <div class="card shadow-sm">
                    <div class="card-header bg-warning">
                        <h4 class="mb-0">Edit Role Info</h4>
                    </div>
                    <div class="card-body">
                        <form action="role?action=update" method="POST">
                            <input type="hidden" name="id" value="<%= roleInfo.getId() %>">
                            <div class="mb-3">
                                <label class="form-label">Role ID (Read-only)</label>
                                <input type="text" class="form-control" value="<%= roleInfo.getId() %>" disabled>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Role Name</label>
                                <input type="text" name="role_name" class="form-control" value="<%= roleInfo.getRoleName() %>" required>
                            </div>
                            <div class="d-grid mb-3">
                                <button type="submit" class="btn btn-warning">Save Changes</button>
                            </div>
                            <div class="text-center">
                                <a href="role?action=list" class="btn btn-secondary w-100">Cancel</a>
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
