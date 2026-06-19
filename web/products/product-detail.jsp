<%@page import="model.Product" %>
<%@page import="model.ProductItem" %>
<%@page import="model.WarehouseStockBreakdown" %>
<%@page import="java.util.List" %>
<%@page import="model.User" %>
<%@page contentType="text/html" pageEncoding="UTF-8" %>
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
    boolean isLowStock = product.getAvailableQty() <= product.getMinStock(); 
    List<ProductItem> inStockSerials = (List<ProductItem>) request.getAttribute("inStockSerials");
    List<WarehouseStockBreakdown> warehouseBreakdown = (List<WarehouseStockBreakdown>) request.getAttribute("warehouseBreakdown");
%>
                <!DOCTYPE html>
<html>

<head>
    <meta charset="UTF-8">
    <title>Thông tin sản phẩm: <%= product.getProductName() %> - WMS</title>
    <!-- Google Fonts - Inter -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"
        rel="stylesheet">
    <!-- Bootstrap CSS & Icons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
        rel="stylesheet">
    <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
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
                        <h2 class="fw-bold text-slate-800 mb-1">Chi tiết thông tin sản phẩm</h2>
                        <p class="text-muted small mb-0">Thông số kỹ thuật chi tiết của sản phẩm và thông tin định giá vốn liên quan</p>
                    </div>
                    <div class="d-flex gap-2">
                        <a href="product?action=list"
                            class="btn btn-outline-secondary d-inline-flex align-items-center gap-1">
                            <i class="bi bi-arrow-left"></i> Quay lại
                        </a>
                        <% if (canEdit) { %>
                            <a href="product?action=update&id=<%= product.getId() %>"
                                class="btn btn-warning text-dark d-inline-flex align-items-center gap-1">
                                <i class="bi bi-pencil-square"></i> Chỉnh sửa thông tin
                            </a>
                            <% } %>
                    </div>
                </div>

                <!-- Metrics Grid -->
                <div class="row g-3 mb-4">
                    <div class="col-md-4">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small"
                                    style="letter-spacing: 0.05em;">Tồn kho hiện tại</span>
                                <h3 class="fw-extrabold text-slate-800 mt-1 mb-0">
                                    <%= product.getQuantity() %>
                                        <%= product.getUnit() %>
                                </h3>
                            </div>
                            <div class="bg-primary bg-opacity-10 text-primary rounded-circle p-2.5">
                                <i class="bi bi-box-seam fs-4"></i>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small"
                                    style="letter-spacing: 0.05em;">Tồn kho tối thiểu an toàn</span>
                                <h3 class="fw-extrabold text-slate-800 mt-1 mb-0">
                                    <%= product.getMinStock() %>
                                        <%= product.getUnit() %>
                                </h3>
                            </div>
                            <div class="bg-warning bg-opacity-10 text-warning rounded-circle p-2.5">
                                <i class="bi bi-shield-alert fs-4"></i>
                            </div>
                        </div>
                    </div>

                    <div class="col-md-4">
                        <div class="metric-card d-flex align-items-center justify-content-between">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small"
                                    style="letter-spacing: 0.05em;">Giá vốn trung bình di động</span>
                                <h3 class="fw-extrabold text-success mt-1 mb-0">
                                    <%= String.format("%,.0f đ", product.getAverageCost()) %>
                                </h3>
                            </div>
                            <div class="bg-success bg-opacity-10 text-success rounded-circle p-2.5">
                                <i class="bi bi-graph-up-arrow fs-4"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Detailed Stock Status Grid -->
                <div class="row g-3 mb-4">
                    <div class="col-md-3">
                        <div class="metric-card bg-light border-0 d-flex align-items-center justify-content-between py-3">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em; font-size: 0.75rem;">Tồn kho thực tế</span>
                                <h4 class="fw-extrabold text-slate-800 mt-1 mb-0">
                                    <%= product.getPhysicalQty() %> <%= product.getUnit() %>
                                </h4>
                            </div>
                            <div class="bg-secondary bg-opacity-10 text-secondary rounded-circle p-2">
                                <i class="bi bi-box-seam fs-5"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="metric-card bg-light border-0 d-flex align-items-center justify-content-between py-3">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em; font-size: 0.75rem;">Tồn kho khả dụng</span>
                                <h4 class="fw-extrabold text-success mt-1 mb-0">
                                    <%= product.getAvailableQty() %> <%= product.getUnit() %>
                                </h4>
                            </div>
                            <div class="bg-success bg-opacity-10 text-success rounded-circle p-2">
                                <i class="bi bi-check-circle fs-5"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="metric-card bg-light border-0 d-flex align-items-center justify-content-between py-3">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em; font-size: 0.75rem;">Tồn kho tạm giữ</span>
                                <h4 class="fw-extrabold text-warning mt-1 mb-0">
                                    <%= product.getReservedQty() %> <%= product.getUnit() %>
                                </h4>
                            </div>
                            <div class="bg-warning bg-opacity-10 text-warning rounded-circle p-2">
                                <i class="bi bi-hourglass-split fs-5"></i>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="metric-card bg-light border-0 d-flex align-items-center justify-content-between py-3">
                            <div>
                                <span class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.05em; font-size: 0.75rem;">Hàng lỗi/Hỏng</span>
                                <h4 class="fw-extrabold text-danger mt-1 mb-0">
                                    <%= product.getDamagedQty() %> <%= product.getUnit() %>
                                </h4>
                            </div>
                            <div class="bg-danger bg-opacity-10 text-danger rounded-circle p-2">
                                <i class="bi bi-exclamation-octagon fs-5"></i>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Inventory Distribution by Warehouse -->
                <% if (warehouseBreakdown != null && !warehouseBreakdown.isEmpty()) { %>
                <div class="card shadow-sm border-0 bg-white mb-4">
                    <div class="card-header bg-primary bg-opacity-10 py-3 border-0">
                        <h5 class="mb-0 fw-bold text-primary"><i class="bi bi-houses-fill me-2"></i>Phân bổ tồn kho theo các kho</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table align-middle text-center mb-0" style="font-size: 0.9rem;">
                                <thead class="table-light text-uppercase text-muted" style="font-size: 0.75rem; font-weight: 700; letter-spacing: 0.05em;">
                                    <tr>
                                        <th class="text-start ps-4">Tên kho</th>
                                        <th>Tồn kho thực tế</th>
                                        <th>Tồn kho khả dụng</th>
                                        <th>Tồn kho tạm giữ</th>
                                        <th>Hàng lỗi/Hỏng</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (WarehouseStockBreakdown b : warehouseBreakdown) { %>
                                    <tr>
                                        <td class="text-start ps-4 fw-bold text-slate-800"><%= b.getWarehouseName() %></td>
                                        <td>
                                            <span class="badge bg-secondary bg-opacity-10 text-secondary px-2.5 py-1.5 fw-semibold"><%= b.getPhysicalQty() %></span>
                                        </td>
                                        <td>
                                            <% if (b.getAvailableQty() <= product.getMinStock() / 2) { %>
                                                <span class="badge bg-danger bg-opacity-10 text-danger px-2.5 py-1.5 fw-bold"><%= b.getAvailableQty() %></span>
                                            <% } else { %>
                                                <span class="badge bg-success bg-opacity-10 text-success px-2.5 py-1.5 fw-semibold"><%= b.getAvailableQty() %></span>
                                            <% } %>
                                        </td>
                                        <td>
                                            <span class="badge bg-warning bg-opacity-10 text-warning px-2.5 py-1.5 fw-semibold"><%= b.getReservedQty() %></span>
                                        </td>
                                        <td>
                                            <span class="badge bg-danger bg-opacity-10 text-danger px-2.5 py-1.5 fw-semibold"><%= b.getDamagedQty() %></span>
                                        </td>
                                    </tr>
                                    <% } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                <% } %>

                <% if (isLowStock) { %>
                    <div
                        class="alert alert-warning border-0 shadow-sm rounded-3 mb-4 p-4 d-flex align-items-center gap-3">
                        <i class="bi bi-exclamation-triangle-fill fs-3 text-warning"></i>
                        <div>
                            <h6 class="alert-heading fw-bold text-warning-emphasis mb-1">Cảnh báo sắp hết hàng!</h6>
                            <p class="mb-0 text-muted">Số lượng tồn kho khả dụng của sản phẩm này (<strong><%= product.getAvailableQty() %> <%= product.getUnit() %></strong>) đang ở mức bằng hoặc dưới ngưỡng tối thiểu an toàn (<strong><%= product.getMinStock() %> <%= product.getUnit() %></strong>). Vui lòng tạo Yêu cầu nhập kho để bổ sung hàng.</p>
                        </div>
                    </div>
                    <% } %>

                        <div class="row g-4">
                            <!-- General details card -->
                            <div class="col-md-6">
                                <div class="card shadow-sm border-0 bg-white h-100">
                                    <div
                                        class="card-header bg-transparent py-3 border-bottom border-light">
                                        <h5 class="mb-0 fw-bold text-slate-800"><i
                                                class="bi bi-info-circle-fill me-2 text-primary"></i>Thông tin cơ bản</h5>
                                    </div>
                                    <div class="card-body p-4">
                                        <table class="table table-borderless align-middle mb-0">
                                            <tbody>
                                                <tr>
                                                    <td class="spec-label" style="width: 35%;">Tên sản phẩm:</td>
                                                    <td class="spec-value fw-bold">
                                                        <%= product.getProductName() %>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="spec-label">Mã SKU:</td>
                                                    <td class="spec-value fw-bold text-primary">
                                                        <%= product.getSku() %>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="spec-label">Danh mục:</td>
                                                    <td class="spec-value"><span
                                                            class="badge bg-light text-dark px-3 py-1.5 fs-7">
                                                            <%= product.getCategoryName() !=null ?
                                                                product.getCategoryName() : "Chưa phân loại"
                                                                %>
                                                        </span></td>
                                                </tr>
                                                <tr>
                                                    <td class="spec-label">Thương hiệu:</td>
                                                    <td class="spec-value"><span
                                                            class="badge bg-light text-dark px-3 py-1.5 fs-7">
                                                            <%= product.getBrandName() !=null ?
                                                                product.getBrandName() : "Chưa phân loại" %>
                                                        </span></td>
                                                </tr>
                                                <tr>
                                                    <td class="spec-label">Đơn vị tính:</td>
                                                    <td class="spec-value text-muted">
                                                        <%= product.getUnit() %>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td class="spec-label">Trạng thái hoạt động:</td>
                                                    <td class="spec-value">
                                                        <% if (product.isStatus()) { %>
                                                            <span
                                                                class="badge bg-success bg-opacity-10 text-success px-3 py-1.5 fs-7"><i
                                                                    class="bi bi-circle-fill me-1"
                                                                    style="font-size: 0.4rem; vertical-align: middle;"></i>
                                                                Hoạt động</span>
                                                            <% } else { %>
                                                                <span
                                                                    class="badge bg-danger bg-opacity-10 text-danger px-3 py-1.5 fs-7"><i
                                                                        class="bi bi-circle-fill me-1"
                                                                        style="font-size: 0.4rem; vertical-align: middle;"></i>
                                                                    Ngừng hoạt động</span>
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
                                    <div
                                        class="card-header bg-transparent py-3 border-bottom border-light">
                                        <h5 class="mb-0 fw-bold text-slate-800"><i
                                                class="bi bi-cpu-fill me-2 text-primary"></i>Thông số kỹ thuật chi tiết</h5>
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
                                            <div class="text-center py-5 text-muted">
                                                <i class="bi bi-cpu text-muted display-4 d-block mb-3"></i>
                                                Chưa có thông số kỹ thuật nào được ghi nhận cho sản phẩm này.
                                            </div>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- In-Stock Serial Numbers & Barcodes Section -->
                        <div class="card shadow-sm border-0 bg-white mt-4 mb-4">
                            <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                                <h5 class="mb-0 fw-bold text-slate-800">
                                    <i class="bi bi-upc-scan me-2 text-primary"></i>Danh sách mã Serial & Barcode trong kho
                                </h5>
                                <% if (inStockSerials != null && !inStockSerials.isEmpty()) { %>
                                    <button class="btn btn-primary btn-sm d-inline-flex align-items-center gap-1" onclick="printBarcodes()">
                                        <i class="bi bi-printer-fill"></i> In tất cả nhãn Barcode
                                    </button>
                                <% } %>
                            </div>
                            <div class="card-body p-4">
                                <% if (inStockSerials == null || inStockSerials.isEmpty()) { %>
                                    <div class="text-center py-5 text-muted">
                                        <i class="bi bi-upc-scan text-muted display-4 d-block mb-3"></i>
                                        Hiện tại sản phẩm này không có mặt hàng thực tế nào trong kho.
                                    </div>
                                <% } else { %>
                                    <div class="table-responsive" style="max-height: 400px; overflow-y: auto;">
                                        <table class="table table-hover align-middle mb-0">
                                            <thead class="table-light sticky-top">
                                                <tr>
                                                    <th style="width: 5%;">#</th>
                                                    <th style="<%= loggedInUser.getWarehouseId() == null ? "width: 25%;" : "width: 35%;" %>">Mã Serial</th>
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

                        <!-- Hidden Printable Area for Barcodes -->
                        <% if (inStockSerials != null && !inStockSerials.isEmpty()) { %>
                        <div class="d-none">
                            <div id="printable-barcodes-section">
                                <div style="display: flex; flex-wrap: wrap; justify-content: space-around; padding: 20px; font-family: 'Inter', sans-serif;">
                                    <% for (ProductItem item : inStockSerials) { %>
                                    <div style="border: 1px solid #ccc; border-radius: 4px; padding: 15px; margin: 10px; background-color: #fff; text-align: center; width: 280px; page-break-inside: avoid; box-sizing: border-box;">
                                        <div style="font-weight: bold; color: #333; margin-bottom: 5px; font-size: 11px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="<%= item.getProductName() %>"><%= item.getProductName() %></div>
                                        <svg class="printable-barcode-svg" data-value="<%= item.getSerialNumber() %>" style="max-width: 100%; height: auto;"></svg>
                                    </div>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                        <% } %>

            </div>
        </div>
    </div>

    <!-- Bootstrap Bundle JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- JsBarcode & Print Logic -->
    <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            // Render standard display barcodes
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
            
            // Render printable barcodes
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
            
            // Replace body with print-only content
            document.body.innerHTML = '<div>' + printContent + '</div>';
            window.print();
            
            // Restore original page content
            document.body.innerHTML = originalContent;
            window.location.reload(); // reload to restore scripts/events
        }
    </script>
</body>

</html>