<%@page import="model.Product"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("product.view")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Product product = (Product) request.getAttribute("product");
    if (product == null) {
        response.sendRedirect("product?action=list");
        return;
    }
    boolean canUpdate = loggedInUser.hasPermission("product.edit");
    boolean isLowStock = product.getQuantity() <= product.getMinStock();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Product Profile: <%= product.getProductName() %> - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <!-- Custom CSS -->
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
    <style>
        .spec-label {
            font-weight: 600;
            color: var(--slate-700);
            font-size: 0.9rem;
        }
        .spec-value {
            color: var(--slate-900);
            font-size: 0.95rem;
        }
        .metric-card {
            border: 1px solid var(--slate-200);
            border-radius: 12px;
            padding: 1.5rem;
            background: #ffffff;
            box-shadow: var(--card-shadow);
        }
    </style>
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Product Details Sheet</h2>
                        <p class="text-muted small mb-0">Detailed catalog attributes and dynamic cost accounting information</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="product?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Back
                        </a>
                        <% if (canUpdate) { %>
                        <a href="product?action=update&id=<%= product.getId() %>" class="btn btn-warning text-dark d-inline-flex align-items-center gap-1">
                            <i class="bi bi-pencil-square"></i> Edit Profile
                        </a>
                        <% } %>
                    </div>
                </div>

                <!-- Metrics Grid -->
                <div class="row g-3 mb-4">
                    <div class="col-md-3">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em;">Current Stock Level</span>
                                <h3 class="fw-extrabold text-slate-800 mt-1 mb-0"><%= product.getQuantity() %> <%= product.getUnit() %></h3>
                            </div>
                            <div class="bg-primary bg-opacity-10 text-primary rounded-circle p-2.5">
                                <i class="bi bi-box-seam fs-4"></i>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-3">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em;">Safety Minimum</span>
                                <h3 class="fw-extrabold text-slate-800 mt-1 mb-0"><%= product.getMinStock() %> <%= product.getUnit() %></h3>
                            </div>
                            <div class="bg-warning bg-opacity-10 text-warning rounded-circle p-2.5">
                                <i class="bi bi-shield-alert fs-4"></i>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-3">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em;">Default Cost Price</span>
                                <h3 class="fw-extrabold text-slate-800 mt-1 mb-0"><%= String.format("%,.0f đ", product.getDefaultCost()) %></h3>
                            </div>
                            <div class="bg-secondary bg-opacity-10 text-secondary rounded-circle p-2.5">
                                <i class="bi bi-cash-stack fs-4"></i>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-3">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em;">Moving Avg Cost</span>
                                <h3 class="fw-extrabold text-success mt-1 mb-0"><%= String.format("%,.0f đ", product.getAverageCost()) %></h3>
                            </div>
                            <div class="bg-success bg-opacity-10 text-success rounded-circle p-2.5">
                                <i class="bi bi-graph-up-arrow fs-4"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (isLowStock) { %>
                <div class="alert alert-warning border-0 shadow-sm rounded-3 mb-4 p-4 d-flex align-items-center gap-3">
                    <i class="bi bi-exclamation-triangle-fill fs-3 text-warning"></i>
                    <div>
                        <h6 class="alert-heading fw-bold text-warning-emphasis mb-1">Low Stock Warning Alert!</h6>
                        <p class="mb-0 text-muted">The physical warehouse inventory of this item (<strong><%= product.getQuantity() %> <%= product.getUnit() %></strong>) is at or below the safety replenishment minimum threshold (<strong><%= product.getMinStock() %> <%= product.getUnit() %></strong>). Please create an Import Request to restock.</p>
                    </div>
                </div>
                <% } %>

                <div class="row g-4">
                    <!-- General details card -->
                    <div class="col-md-6">
                        <div class="card shadow-sm border-0 bg-white h-100">
                            <div class="card-header bg-transparent py-3 border-bottom border-light">
                                <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-info-circle-fill me-2 text-primary"></i>General Identification</h5>
                            </div>
                            <div class="card-body p-4">
                                <table class="table table-borderless align-middle mb-0">
                                    <tbody>
                                        <tr>
                                            <td class="spec-label" style="width: 35%;">Product Name:</td>
                                            <td class="spec-value fw-bold"><%= product.getProductName() %></td>
                                        </tr>
                                        <tr>
                                            <td class="spec-label">SKU Code:</td>
                                            <td class="spec-value fw-bold text-primary"><%= product.getSku() %></td>
                                        </tr>
                                        <tr>
                                            <td class="spec-label">Category:</td>
                                            <td class="spec-value"><span class="badge bg-light text-dark px-3 py-1.5 fs-7"><%= product.getCategoryName() != null ? product.getCategoryName() : "Unassigned" %></span></td>
                                        </tr>
                                        <tr>
                                            <td class="spec-label">Brand:</td>
                                            <td class="spec-value"><span class="badge bg-light text-dark px-3 py-1.5 fs-7"><%= product.getBrandName() != null ? product.getBrandName() : "Unassigned" %></span></td>
                                        </tr>
                                        <tr>
                                            <td class="spec-label">Unit of Measure:</td>
                                            <td class="spec-value text-muted"><%= product.getUnit() %></td>
                                        </tr>
                                        <tr>
                                            <td class="spec-label">Operational Status:</td>
                                            <td class="spec-value">
                                                <% if (product.isStatus()) { %>
                                                    <span class="badge bg-success bg-opacity-10 text-success px-3 py-1.5 fs-7"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Active</span>
                                                <% } else { %>
                                                    <span class="badge bg-danger bg-opacity-10 text-danger px-3 py-1.5 fs-7"><i class="bi bi-circle-fill me-1" style="font-size: 0.4rem; vertical-align: middle;"></i> Deactive</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <!-- Specs sheet -->
                    <div class="col-md-6">
                        <div class="card shadow-sm border-0 bg-white h-100">
                            <div class="card-header bg-transparent py-3 border-bottom border-light">
                                <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-cpu-fill me-2 text-primary"></i>Technical Specifications Sheet</h5>
                            </div>
                            <div class="card-body p-4">
                                <% if (product.getTechnicalSpecifications() != null && !product.getTechnicalSpecifications().trim().isEmpty()) { %>
                                    <div class="bg-light rounded-3 p-3 text-slate-800 h-100" style="min-height: 180px; white-space: pre-line; line-height: 1.6;">
                                        <%= product.getTechnicalSpecifications() %>
                                    </div>
                                <% } else { %>
                                    <div class="text-center py-5 text-muted">
                                        <i class="bi bi-cpu text-muted display-4 d-block mb-3"></i>
                                        No technical specifications recorded for this product yet.
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
