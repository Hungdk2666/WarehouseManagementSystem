<%@page import="model.User"%>
<%@page import="model.Role"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("USER_ADD")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Add New User</title>
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
                    <div class="col-md-6">
                        <div class="card shadow-sm border-0 bg-white">
                            <div class="card-header bg-success bg-opacity-10 py-3 border-0">
                                <h4 class="mb-0 fw-bold text-success"><i class="bi bi-person-plus-fill me-2"></i>Add New User</h4>
                            </div>
                            <div class="card-body p-4">
                                <div class="alert alert-info border-0 bg-info bg-opacity-10 text-dark py-2.5 px-3 rounded-3 small mb-4">
                                    <i class="bi bi-info-circle-fill me-1"></i> Default password for new users is <strong>123456</strong> (will be automatically hashed).
                                </div>
                                <form action="user?action=add" method="POST">
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-person me-1 text-muted"></i> Username</label>
                                        <input type="text" name="username" class="form-control" placeholder="Enter username" required>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-envelope me-1 text-muted"></i> Email</label>
                                        <input type="email" name="email" class="form-control" placeholder="Enter email address" required>
                                    </div>
                                    <div class="mb-3">
                                        <label class="form-label"><i class="bi bi-card-text me-1 text-muted"></i> Full Name</label>
                                        <input type="text" name="full_name" class="form-control" placeholder="Enter full name" required>
                                    </div>
                                    <div class="mb-4">
                                        <label class="form-label"><i class="bi bi-shield-check me-1 text-muted"></i> Role</label>
                                        <select name="role_id" class="form-select" required>
                                        <%
                                            List<Role> roleList = (List<Role>) request.getAttribute("roleList");
                                            if(roleList != null) {
                                                for(Role role : roleList) {
                                        %>
                                            <option value="<%= role.getId() %>"><%= role.getRoleName() %></option>
                                        <%
                                                }
                                            }
                                        %>
                                        </select>
                                    </div>
                                    <div class="d-grid mb-3 mt-4">
                                        <button type="submit" class="btn btn-success fw-semibold"><i class="bi bi-save me-1"></i> Save User</button>
                                    </div>
                                    <div class="text-center">
                                        <a href="user?action=list" class="btn btn-outline-secondary w-100"><i class="bi bi-x-circle me-1"></i> Cancel</a>
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
