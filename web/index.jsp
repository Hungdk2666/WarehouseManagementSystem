<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Dashboard - WMS</title>
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
            <!-- Left Sidebar -->
            <jsp:include page="/includes/sidebar.jsp" />

            <!-- Main Content -->
            <div class="col-md-9 col-lg-10">
                <div class="d-flex align-items-center justify-content-between mb-3">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Welcome, <%= user.getFullName() %>!</h2>
                        <p class="text-muted small mb-0">
                            <span class="badge bg-primary bg-opacity-10 text-primary px-3 py-1.5 fs-7">
                                <i class="bi bi-shield-check me-1"></i> Role: <%= user.getRoleName() != null ? user.getRoleName() : ((user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) ? "Admin" : "Staff") %>
                            </span>
                            <span class="badge bg-success bg-opacity-10 text-success px-3 py-1.5 fs-7 ms-2">
                                <i class="bi bi-circle-fill me-1" style="font-size: 0.5rem; vertical-align: middle;"></i> Status: <%= user.isStatus() ? "Active" : "Inactive" %>
                            </span>
                        </p>
                    </div>
                </div>
                <hr class="text-muted opacity-25">
                
                <div class="row mt-4">
                    <div class="col-12">
                        <% if (user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) { %>
                        <div class="alert alert-info shadow-sm border-0 bg-info bg-opacity-10 text-dark p-4 rounded-3">
                            <h5 class="alert-heading fw-bold text-info-emphasis d-flex align-items-center gap-2 mb-2">
                                <i class="bi bi-shield-lock-fill fs-4"></i> Access Restricted
                            </h5>
                            <p class="mb-0 text-muted">You are logged in as a <strong>System Admin</strong>. According to the Separation of Duties (SoD) policy, you do not have permission to view business data or financial reports.</p>
                        </div>
                        <% } else { %>
                        
                        <!-- Beautiful dashboard widgets -->
                        <div class="row g-3 mb-4">
                            <div class="col-md-4">
                                <div class="card h-100 border-0 shadow-sm" style="background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);">
                                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                                        <div>
                                            <h6 class="text-uppercase fw-bold text-primary-emphasis small mb-1" style="letter-spacing: 0.05em;">Total Products</h6>
                                            <h2 class="fw-extrabold text-primary mb-0">0</h2>
                                        </div>
                                        <div class="bg-primary bg-opacity-10 text-primary rounded-circle p-3 d-flex align-items-center justify-content-center" style="width: 56px; height: 56px;">
                                            <i class="bi bi-box-seam-fill fs-3"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            
                            <div class="col-md-4">
                                <div class="card h-100 border-0 shadow-sm" style="background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);">
                                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                                        <div>
                                            <h6 class="text-uppercase fw-bold text-success-emphasis small mb-1" style="letter-spacing: 0.05em;">Active Orders</h6>
                                            <h2 class="fw-extrabold text-success mb-0">0</h2>
                                        </div>
                                        <div class="bg-success bg-opacity-10 text-success rounded-circle p-3 d-flex align-items-center justify-content-center" style="width: 56px; height: 56px;">
                                            <i class="bi bi-cart-check-fill fs-3"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="card h-100 border-0 shadow-sm" style="background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);">
                                    <div class="card-body p-4 d-flex align-items-center justify-content-between">
                                        <div>
                                            <h6 class="text-uppercase fw-bold text-warning-emphasis small mb-1" style="letter-spacing: 0.05em;">Pending Alerts</h6>
                                            <h2 class="fw-extrabold text-warning mb-0">0</h2>
                                        </div>
                                        <div class="bg-warning bg-opacity-10 text-warning rounded-circle p-3 d-flex align-items-center justify-content-center" style="width: 56px; height: 56px;">
                                            <i class="bi bi-exclamation-triangle-fill fs-3"></i>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                    </div>
                    <div class="col-12">
                        <div class="card shadow-sm border-0 mb-4 bg-white">
                            <div class="card-header bg-transparent py-3 border-0">
                                <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-activity me-2 text-primary"></i>Recent Activities</h5>
                            </div>
                            <div class="card-body p-4">
                                <div class="text-center py-5">
                                    <i class="bi bi-inbox text-muted display-4 d-block mb-3"></i>
                                    <p class="text-muted mb-0">No recent activities to display.</p>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
