<%@page import="model.Category"%>
<%@page import="model.Brand"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("product.add")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Category> categoryList = (List<Category>) request.getAttribute("categoryList");
    List<Brand> brandList = (List<Brand>) request.getAttribute("brandList");
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Add New Product - WMS</title>
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
                
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h2 class="fw-bold text-slate-800 mb-1">Create Product Profile</h2>
                        <p class="text-muted small mb-0">Register a new product with default costing parameters and tech specifications</p>
                    </div>
                    <a href="product?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Back to Catalog
                    </a>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm rounded-3 mb-4" role="alert">
                    <i class="bi bi-exclamation-octagon-fill me-2 fs-5"></i>
                    <strong>Error:</strong> <%= error %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <% } %>

                <div class="card shadow-sm border-0 bg-white p-4">
                    <form action="product?action=add" method="POST" class="row g-3">
                        
                        <div class="col-md-6">
                            <label for="productName" class="form-label">Product Name <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="productName" name="product_name" placeholder="Enter product name..." required>
                        </div>

                        <div class="col-md-6">
                            <label for="sku" class="form-label">SKU (Stock Keeping Unit) <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="sku" name="sku" placeholder="Enter unique SKU (e.g. PANA-9000)" required>
                        </div>

                        <div class="col-md-4">
                            <label for="unit" class="form-label">Unit of Measure <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="unit" name="unit" value="cái" placeholder="e.g. cái, bộ, chiếc" required>
                        </div>

                        <div class="col-md-4">
                            <label for="minStock" class="form-label">Minimum Stock Level (Safety threshold) <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="minStock" name="min_stock" min="1" value="5" required>
                        </div>

                        <div class="col-md-4">
                            <label for="defaultCost" class="form-label">Initial Default Cost <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <input type="number" class="form-control" id="defaultCost" name="default_cost" min="0" step="1000" placeholder="Enter default price..." required>
                                <span class="input-group-text bg-light text-muted">đ</span>
                            </div>
                        </div>

                        <div class="col-md-6">
                            <label for="categoryId" class="form-label">Category</label>
                            <select class="form-select" id="categoryId" name="category_id">
                                <option value="">Select Category...</option>
                                <%
                                    if (categoryList != null) {
                                        for (Category c : categoryList) {
                                %>
                                <option value="<%= c.getId() %>"><%= c.getCategoryName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>

                        <div class="col-md-6">
                            <label for="brandId" class="form-label">Brand</label>
                            <select class="form-select" id="brandId" name="brand_id">
                                <option value="">Select Brand...</option>
                                <%
                                    if (brandList != null) {
                                        for (Brand b : brandList) {
                                %>
                                <option value="<%= b.getId() %>"><%= b.getBrandName() %></option>
                                <%
                                        }
                                    }
                                %>
                            </select>
                        </div>

                        <div class="col-12">
                            <label for="techSpecs" class="form-label">Technical Specifications</label>
                            <textarea class="form-control" id="techSpecs" name="technical_specifications" placeholder="BTU, Capacity, Wattage, Dimensions..." rows="4"></textarea>
                        </div>

                        <div class="col-12 d-flex justify-content-end gap-2 mt-4">
                            <a href="product?action=list" class="btn btn-secondary px-4"><i class="bi bi-x-circle me-1"></i> Cancel</a>
                            <button type="submit" class="btn btn-primary px-4"><i class="bi bi-plus-lg me-1"></i> Create Product</button>
                        </div>
                    </form>
                </div>

            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
