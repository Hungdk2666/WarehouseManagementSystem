<%@page import="model.Category"%>
<%@page import="model.Brand"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("PRODUCT_ADD")) {
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
    <title>Thêm sản phẩm mới - WMS</title>
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
                
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Tạo thông tin sản phẩm</h2>
                        <p class="page-subtitle">Đăng ký sản phẩm mới với giá vốn mặc định và thông số kỹ thuật</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="product?action=list" class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Quay lại danh mục
                        </a>
                    </div>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger alert-dismissible fade show border-0 shadow-sm rounded-3 mb-4" role="alert">
                    <i class="bi bi-exclamation-octagon-fill me-2 fs-5"></i>
                    <strong>Lỗi:</strong> <%= error %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
                <% } %>

                <div class="card form-card p-4">
                    <form action="product?action=add" method="POST" class="row g-3">
                        
                        <div class="col-md-6">
                            <label for="productName" class="form-label">Tên sản phẩm <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="productName" name="product_name" placeholder="Nhập tên sản phẩm..." required>
                        </div>

                        <div class="col-md-6">
                            <label for="sku" class="form-label">Mã SKU <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="sku" name="sku" placeholder="Nhập SKU duy nhất (ví dụ: PANA-9000)" required>
                        </div>

                        <div class="col-md-6">
                            <label for="unit" class="form-label">Đơn vị tính <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="unit" name="unit" value="cái" placeholder="Ví dụ: cái, bộ, chiếc..." required>
                        </div>

                        <div class="col-md-6">
                            <label for="minStock" class="form-label">Mức tồn kho tối thiểu (Ngưỡng an toàn) <span class="text-danger">*</span></label>
                            <input type="number" class="form-control" id="minStock" name="min_stock" min="1" value="5" onkeydown="if(!/^[0-9]$/.test(event.key) && !['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab', 'Enter', 'Escape'].includes(event.key) && !event.ctrlKey && !event.metaKey) event.preventDefault();" required>
                        </div>

                        <div class="col-md-6">
                            <label for="categoryId" class="form-label">Danh mục</label>
                            <select class="form-select" id="categoryId" name="category_id">
                                <option value="">Chọn Danh mục...</option>
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
                            <label for="brandId" class="form-label">Thương hiệu</label>
                            <select class="form-select" id="brandId" name="brand_id">
                                <option value="">Chọn Thương hiệu...</option>
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
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <label class="form-label fw-bold mb-0">Thông số kỹ thuật</label>
                                <button type="button" id="btnAddSpec" class="btn btn-outline-primary btn-sm d-flex align-items-center gap-1">
                                    <i class="bi bi-plus-lg"></i> Thêm dòng thông số
                                </button>
                            </div>
                            <div class="table-responsive border rounded bg-white p-3">
                                <table class="table table-hover align-middle mb-0" id="specsTable" style="font-size: 0.9rem;">
                                    <thead>
                                        <tr class="table-light">
                                            <th style="width: 45%;">Tên thông số (Ví dụ: Công suất, Dung tích)</th>
                                            <th style="width: 45%;">Giá trị thông số (Ví dụ: 9000 BTU, 236 Lít)</th>
                                            <th style="width: 10%;" class="text-center">Hành động</th>
                                        </tr>
                                    </thead>
                                    <tbody id="specsContainer">
                                        <!-- Dòng thông số động sẽ được thêm ở đây -->
                                    </tbody>
                                </table>
                                <div id="noSpecsMsg" class="text-center text-muted py-4">
                                    <i class="bi bi-info-circle me-1"></i> Chưa có thông số kỹ thuật nào được thiết lập. Hãy nhấn "Thêm dòng thông số".
                                </div>
                            </div>
                        </div>

                        <div class="col-12">
                            <div class="form-actions">
                                <a href="product?action=list" class="btn btn-outline-secondary">Hủy</a>
                                <button type="submit" class="btn btn-primary"><i class="bi bi-check-lg me-1"></i>Tạo sản phẩm</button>
                            </div>
                        </div>
                    </form>
                </div>

            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            const btnAddSpec = document.getElementById("btnAddSpec");
            const specsContainer = document.getElementById("specsContainer");
            const noSpecsMsg = document.getElementById("noSpecsMsg");

            function checkEmptyState() {
                if (specsContainer.children.length === 0) {
                    noSpecsMsg.style.display = "block";
                } else {
                    noSpecsMsg.style.display = "none";
                }
            }

            function createSpecRow(name = "", value = "") {
                const tr = document.createElement("tr");
                tr.className = "spec-row";
                tr.innerHTML = 
                    '<td>' +
                    '    <input type="text" class="form-control form-control-sm spec-name" name="spec_key" value="' + escapeHtml(name) + '" placeholder="VD: Công suất, Thương hiệu..." required>' +
                    '</td>' +
                    '<td>' +
                    '    <input type="text" class="form-control form-control-sm spec-value" name="spec_value" value="' + escapeHtml(value) + '" placeholder="VD: 9000 BTU, Nhật Bản..." required>' +
                    '</td>' +
                    '<td class="text-center">' +
                    '    <button type="button" class="btn btn-outline-danger btn-sm btn-delete-spec">' +
                    '        <i class="bi bi-trash"></i>' +
                    '    </button>' +
                    '</td>';

                // Add delete event
                tr.querySelector(".btn-delete-spec").addEventListener("click", function() {
                    tr.remove();
                    checkEmptyState();
                });

                specsContainer.appendChild(tr);
                checkEmptyState();
            }

            function escapeHtml(text) {
                return text
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#039;");
            }

            btnAddSpec.addEventListener("click", function() {
                createSpecRow();
            });

            // Initialize with empty state
            checkEmptyState();
        });
    </script>
</body>
</html>
