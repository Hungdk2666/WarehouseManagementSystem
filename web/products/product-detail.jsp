<%@page import="model.Product" %>
<%@page import="model.ProductItem" %>
<%@page import="java.util.List" %>
<%@page import="model.User" %>
<%@page contentType="text/html" pageEncoding="UTF-8" %>
<%!
    private String h(Object value) {
        if (value == null) return "";
        return value.toString().replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("PRODUCT_VIEW")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    Product product = (Product) request.getAttribute("product");
    if (product == null) {
        response.sendRedirect("product?action=list");
        return;
    }
    boolean canEdit = loggedInUser.hasPermission("PRODUCT_EDIT");
    boolean canViewInventory = loggedInUser.hasPermission("INVENTORY_VIEW");
    List<ProductItem> inStockSerials = (List<ProductItem>) request.getAttribute("inStockSerials");
%>
                <!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Thông tin sản phẩm: <%= product.getProductName() %> - WMS</title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
        rel="stylesheet">
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
        rel="stylesheet">
    <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    
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
                        <h2 class="page-title">Chi tiết thông tin sản phẩm</h2>
                        <p class="page-subtitle">Thông số kỹ thuật chi tiết của sản phẩm và thông tin định giá vốn liên quan</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="product?action=list"
                            class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                        <% if (canViewInventory) { %>
                            <a href="<%= request.getContextPath() %>/warehouse/inventory?keyword=<%= java.net.URLEncoder.encode(product.getSku(), "UTF-8") %>"
                                class="btn btn-outline-primary d-inline-flex align-items-center gap-1">
                                <i class="bi bi-boxes"></i> Xem tồn kho
                            </a>
                        <% } %>
                        <% if (canEdit) { %>
                            <a href="product?action=update&id=<%= product.getId() %>"
                                class="btn btn-primary d-inline-flex align-items-center gap-1">
                                <i class="bi bi-pencil-square"></i> Chỉnh sửa thông tin
                            </a>
                            <% } %>
                    </div>
                </div>

                
                <div class="row g-3 mb-4">
                    <div class="col-md-6">
                        <div class="card h-100"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-warning bg-opacity-10 text-warning"><i class="bi bi-shield-alert"></i></div>
                            <div>
                                <div class="stat-label">Tồn kho tối thiểu an toàn</div>
                                <h3 class="stat-value"><%= product.getMinStock() %> <%= product.getUnit() %></h3>
                            </div>
                        </div></div>
                    </div>

                    <div class="col-md-6">
                        <div class="card h-100"><div class="card-body p-3 stat-tile">
                            <div class="stat-icon bg-success bg-opacity-10 text-success"><i class="bi bi-graph-up-arrow"></i></div>
                            <div>
                                <div class="stat-label">Giá vốn trung bình di động</div>
                                <h3 class="stat-value"><%= String.format("%,.0f đ", product.getAverageCost()) %></h3>
                            </div>
                        </div></div>
                    </div>
                </div>

                        <div class="row g-4">
                            
                            <div class="col-md-6">
                                <div class="card h-100">
                                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                                        <span class="fw-bold text-slate-800"><i
                                                class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin cơ bản</span>
                                    </div>
                                    <div class="card-body p-4">
                                        <div class="detail-row">
                                            <div class="detail-label">Tên sản phẩm</div>
                                            <div class="detail-value fw-bold"><%= product.getProductName() %></div>
                                        </div>
                                        <div class="detail-row">
                                            <div class="detail-label">Mã SKU</div>
                                            <div class="detail-value fw-bold text-slate-800"><%= product.getSku() %></div>
                                        </div>
                                        <div class="detail-row">
                                            <div class="detail-label">Danh mục</div>
                                            <div class="detail-value"><span class="badge bg-secondary bg-opacity-10 text-secondary">
                                                <%= product.getCategoryName() !=null ?
                                                    product.getCategoryName() : "Chưa phân loại" %>
                                            </span></div>
                                        </div>
                                        <div class="detail-row">
                                            <div class="detail-label">Thương hiệu</div>
                                            <div class="detail-value"><span class="badge bg-secondary bg-opacity-10 text-secondary">
                                                <%= product.getBrandName() !=null ?
                                                    product.getBrandName() : "Chưa phân loại" %>
                                            </span></div>
                                        </div>
                                        <div class="detail-row">
                                            <div class="detail-label">Đơn vị tính</div>
                                            <div class="detail-value text-muted"><%= product.getUnit() %></div>
                                        </div>
                                        <div class="detail-row">
                                            <div class="detail-label">Trạng thái hoạt động</div>
                                            <div class="detail-value">
                                                <% if (product.isStatus()) { %>
                                                    <span class="status-chip chip-success">Hoạt động</span>
                                                <% } else { %>
                                                    <span class="status-chip chip-muted">Ngừng hoạt động</span>
                                                <% } %>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            
                            <div class="col-md-6">
                                <div class="card h-100">
                                    <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                                        <span class="fw-bold text-slate-800"><i
                                                class="bi bi-cpu-fill me-2 text-primary"></i>Thông số kỹ thuật chi tiết</span>
                                    </div>
                                    <div class="card-body p-4">
                                        <% 
                                            List<model.ProductSpecification> specs = product.getSpecifications();
                                            if (specs != null && !specs.isEmpty()) { 
                                        %>
                                            <div class="bg-light rounded-3 p-3 text-slate-800 h-100" style="min-height: 180px;">
                                                <table class="table table-sm mb-0 align-middle" style="font-size: 0.92rem; border-collapse: collapse;">
                                                    <tbody>
                                                        <% for (model.ProductSpecification spec : specs) { %>
                                                            <tr>
                                                                <td class="fw-semibold text-secondary py-2.5 ps-2 border-bottom border-light" style="width: 45%; border-top: none; background: transparent;"><%= spec.getSpecKey() %></td>
                                                                <td class="text-end text-slate-800 py-2.5 pe-2 border-bottom border-light" style="border-top: none; background: transparent;"><%= spec.getSpecValue() %></td>
                                                            </tr>
                                                        <% } %>
                                                    </tbody>
                                                </table>
                                            </div>
                                        <% } else { %>
                                            <div class="empty-state">
                                                <i class="bi bi-inbox"></i>
                                                <p>Chưa có thông số kỹ thuật nào được ghi nhận cho sản phẩm này.</p>
                                            </div>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>

                        
                        <div class="card mt-4 mb-4">
                            <div class="card-header bg-white py-3 d-flex justify-content-between align-items-center">
                                <span class="fw-bold text-slate-800">
                                    <i class="bi bi-upc-scan me-2 text-primary"></i>Danh sách mã Serial & Barcode trong kho
                                </span>
                                <% if (inStockSerials != null && !inStockSerials.isEmpty()) { %>
                                    <button class="btn btn-primary btn-sm d-inline-flex align-items-center gap-1" onclick="printBarcodes()">
                                        <i class="bi bi-printer-fill"></i> In tất cả nhãn Barcode
                                    </button>
                                <% } %>
                            </div>
                            <div class="card-body p-4">
                                <% if (inStockSerials == null || inStockSerials.isEmpty()) { %>
                                    <div class="empty-state">
                                        <i class="bi bi-inbox"></i>
                                        <p>Hiện tại sản phẩm này không có mặt hàng thực tế nào trong kho.</p>
                                    </div>
                                <% } else { %>
                                    <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                                        <table class="table table-hover align-middle mb-0">
                                            <thead class="table-light sticky-top">
                                                <tr>
                                                    <th style="width: 5%;">#</th>
                                                    <th>Mã WMS</th>
                                                    <th>Serial nhà sản xuất</th>
                                                    <th style="<%= loggedInUser.getWarehouseId() == null ? "width: 30%;" : "width: 45%;" %>">Nhãn Barcode</th>
                                                    <% if (loggedInUser.getWarehouseId() == null) { %>
                                                    <th style="width: 20%;">Kho</th>
                                                    <% } %>
                                                    <th style="width: 20%;">Ngày nhập kho</th>
                                                </tr>
                                            </thead>
                                            <tbody>
                                                <% 
                                                int idx = 1;
                                                for (ProductItem item : inStockSerials) { 
                                                %>
                                                    <tr>
                                                        <td class="text-muted"><%= idx++ %></td>
                                                        <td>
                                                            <code class="fw-bold fs-6 text-dark"><%= item.getSerialNumber() %></code>
                                                        </td>
                                                        <td><span class="font-monospace"><%= item.getManufacturerSerial() == null ? "—" : h(item.getManufacturerSerial()) %></span></td>
                                                        <td>
                                                            <svg class="barcode-svg" data-value="<%= item.getSerialNumber() %>" style="max-height: 60px; max-width: 100%;"></svg>
                                                        </td>
                                                        <% if (loggedInUser.getWarehouseId() == null) { %>
                                                        <td>
                                                            <span class="badge bg-light text-dark border px-2.5 py-1.5"><%= item.getWarehouseName() != null ? item.getWarehouseName() : "Không xác định" %></span>
                                                        </td>
                                                        <% } %>
                                                        <td class="text-muted small">
                                                            <%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(item.getCreatedAt()) %>
                                                        </td>
                                                    </tr>
                                                <% } %>
                                            </tbody>
                                        </table>
                                    </div>
                                <% } %>
                            </div>
                        </div>

                        
                        <% if (inStockSerials != null && !inStockSerials.isEmpty()) { %>
                        <div class="d-none">
                            <div id="printable-barcodes-section">
                                <div style="display: flex; flex-wrap: wrap; justify-content: space-around; padding: 20px; font-family: 'Inter', sans-serif;">
                                    <% for (ProductItem item : inStockSerials) { %>
                                    <div style="border: 1px solid #ccc; border-radius: 4px; padding: 15px; margin: 10px; background-color: #fff; text-align: center; width: 280px; page-break-inside: avoid; box-sizing: border-box;">
                                        <div style="font-weight: bold; color: #333; margin-bottom: 5px; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                        <div style="font-size: 9px; color: #666;">Mã WMS</div>
                                        <svg class="printable-barcode-svg" data-value="<%= item.getSerialNumber() %>" style="max-width: 100%; height: auto;"></svg>
                                        <% if (item.getManufacturerSerial() != null) { %>
                                        <div style="font-size: 9px; color: #666; margin-top: 3px;">Serial hãng: <%= h(item.getManufacturerSerial()) %></div>
                                        <% } %>
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <% } %>

            </div>
        </div>
    </div>

    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    
    <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {

            document.querySelectorAll(".barcode-svg").forEach(function(el) {
                const val = el.getAttribute("data-value");
                JsBarcode(el, val, {
                    format: "CODE128",
                    width: 1.5,
                    height: 40,
                    displayValue: true,
                    fontSize: 11
                });
            });
            

            document.querySelectorAll(".printable-barcode-svg").forEach(function(el) {
                const val = el.getAttribute("data-value");
                JsBarcode(el, val, {
                    format: "CODE128",
                    width: 1.1,
                    height: 35,
                    displayValue: true,
                    fontSize: 11
                });
            });
        });
        
        function printBarcodes() {
            const printSection = document.getElementById("printable-barcodes-section");
            if (!printSection) return;
            const printContent = printSection.innerHTML;
            const originalContent = document.body.innerHTML;
            

            document.body.innerHTML = '<div>' + printContent + '</div>';
            window.print();
            

            document.body.innerHTML = originalContent;
            window.location.reload();
        }
    </script>
</body>

</html>
