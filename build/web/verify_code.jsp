<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    String resetEmail = (String) session.getAttribute("resetEmail");
    if (resetEmail == null) {
        resetEmail = "";
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Verify Code - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container mt-5">
        <div class="row justify-content-center">
            <div class="col-md-4">
                <div class="card shadow-sm">
                    <div class="card-body">
                        <h4 class="card-title text-center mb-4">Verify Code</h4>
                        <div class="alert alert-info text-center">
                            A reset request has been sent to Admin.<br>Please contact the Admin to get your reset code.
                        </div>
                        <% 
                            String error = (String) request.getAttribute("error");
                            if (error != null) {
                        %>
                            <div class="alert alert-danger"><%= error %></div>
                        <% } %>
                        <form action="verify-code" method="POST">
                            <div class="mb-3">
                                <label class="form-label">Email Address</label>
                                <input type="email" name="email" class="form-control" value="<%= resetEmail %>" required <%= resetEmail.isEmpty() ? "" : "readonly" %>>
                            </div>
                            <div class="mb-3">
                                <label class="form-label">Admin Code</label>
                                <input type="text" name="code" class="form-control" placeholder="Enter 6-digit code" required>
                            </div>
                            <div class="d-grid mb-3">
                                <button type="submit" class="btn btn-primary">Verify Code</button>
                            </div>
                            <div class="text-center">
                                <a href="login" class="text-decoration-none">Cancel</a>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
