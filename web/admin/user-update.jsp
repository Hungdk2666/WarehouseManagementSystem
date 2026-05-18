<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    User userInfo = (User) request.getAttribute("userInfo");
    if (userInfo == null) {
        response.sendRedirect("user?action=list");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Update User</title>
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
                    <div class="card-header bg-warning">
                        <h4 class="mb-0">Update User Info</h4>
                    </div>
                    <div class="card-body">
                        <form action="user?action=update" method="POST">
                            <input type="hidden" name="id" value="<%= userInfo.getId() %>">
                            <div class="mb-3">
                                <label class="form-label">Username (Read-only)</label>
                                <input type="text" class="form-control" value="<%= userInfo.getUsername() %>" disabled>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Email</label>
                                <input type="email" name="email" class="form-control" value="<%= userInfo.getEmail() %>" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Full Name</label>
                                <input type="text" name="full_name" class="form-control" value="<%= userInfo.getFullName() %>" required>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Role</label>
                                <select name="role_id" class="form-select" required>
                                    <option value="1" <%= userInfo.getRoleId() == 1 ? "selected" : "" %>>Admin</option>
                                    <option value="2" <%= userInfo.getRoleId() == 2 ? "selected" : "" %>>Staff</option>
                                </select>
                            </div>
                            <div class="d-grid mb-3">
                                <button type="submit" class="btn btn-warning">Update Info</button>
                            </div>
                            <div class="text-center">
                                <a href="user?action=list" class="btn btn-secondary w-100">Cancel</a>
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
