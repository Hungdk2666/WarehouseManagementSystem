<%@page import="model.Product"%>
<%@page import="model.Warehouse"%>
<%@page import="java.util.List"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("STOCKTAKE_CREATE")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Product> productList = (List<Product>) request.getAttribute("productList");
    List<Warehouse> warehouseList = (List<Warehouse>) request.getAttribute("warehouseList");
    Integer userWh = loggedInUser.getWarehouseId();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo phiếu kiểm kê - WMS</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">

                <div class="mb-4">
                    <h2 class="fw-bold mb-1">Tạo phiếu kiểm kê</h2>
                    <p class="text-muted small">Chọn kho và phạm vi cần kiểm kê</p>
                </div>

                <form action="<%= request.getContextPath() %>/warehouse/stocktake" method="POST">
                    <input type="hidden" name="action" value="add">

                    <div class="card shadow-sm border-0 mb-4">
                        <div class="card-body">
                            <div class="row g-3">
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Kho kiểm kê <span class="text-danger">*</span></label>
                                    <% if (userWh != null) {
                                        Warehouse selected = null;
                                        if (warehouseList != null) {
                                            for (Warehouse w : warehouseList) if (w.getId() == userWh) { selected = w; break; }
                                        }
                                    %>
                                        <input type="text" class="form-control" value="<%= selected != null ? selected.getWarehouseName() : "Kho #" + userWh %>" readonly>
                                    <% } else { %>
                                        <select class="form-select" name="warehouse_id" required>
                                            <option value="">-- Chọn kho --</option>
                                            <% if (warehouseList != null) for (Warehouse w : warehouseList) { %>
                                                <option value="<%= w.getId() %>"><%= w.getWarehouseName() %></option>
                                            <% } %>
                                        </select>
                                    <% } %>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Phạm vi <span class="text-danger">*</span></label>
                                    <select class="form-select" name="scope" id="scope" required>
                                        <option value="PARTIAL">Một phần (chọn vài SKU)</option>
                                        <option value="FULL">Toàn kho (tất cả SKU)</option>
                                    </select>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label fw-semibold">Cách đếm <span class="text-danger">*</span></label>
                                    <select class="form-select" name="count_mode" required>
                                        <option value="QUANTITY">Theo số lượng (nhập số đếm)</option>
                                        <option value="SERIAL">Scan từng serial (chính xác hơn)</option>
                                    </select>
                                </div>
                                <div class="col-12">
                                    <label class="form-label fw-semibold">Ghi chú</label>
                                    <textarea class="form-control" name="notes" rows="2" placeholder="Lý do kiểm kê, ghi chú..."></textarea>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="card shadow-sm border-0 mb-4" id="productPicker">
                        <div class="card-header bg-info bg-opacity-10">
                            <h5 class="mb-0 fw-bold text-info"><i class="bi bi-list-check me-2"></i>Chọn sản phẩm cần kiểm</h5>
                            <small class="text-muted">Bỏ qua phần này nếu chọn phạm vi "Toàn kho"</small>
                        </div>
                        <div class="card-body">
                            <div class="mb-2">
                                <input type="text" id="prodSearch" class="form-control form-control-sm" placeholder="Tìm sản phẩm theo tên/SKU...">
                            </div>
                            <div style="max-height:400px;overflow-y:auto;">
                                <table class="table table-sm">
                                    <thead class="table-light sticky-top">
                                        <tr>
                                            <th width="40"><input type="checkbox" id="selectAll"></th>
                                            <th>Tên sản phẩm</th>
                                            <th>SKU</th>
                                            <th>Đơn vị</th>
                                        </tr>
                                    </thead>
                                    <tbody id="prodBody">
                                    <% if (productList != null) for (Product p : productList) { %>
                                        <tr>
                                            <td><input type="checkbox" name="product_id" value="<%= p.getId() %>" class="prod-check"></td>
                                            <td class="prod-name"><%= p.getProductName() %></td>
                                            <td class="prod-sku"><%= p.getSku() %></td>
                                            <td><%= p.getUnit() %></td>
                                        </tr>
                                    <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    <div class="d-flex gap-2">
                        <button type="submit" class="btn btn-primary">
                            <i class="bi bi-save"></i> Tạo phiếu
                        </button>
                        <a href="<%= request.getContextPath() %>/warehouse/stocktake" class="btn btn-outline-secondary">Hủy</a>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <script>
        document.getElementById("scope").addEventListener("change", function() {
            document.getElementById("productPicker").style.display = this.value === "FULL" ? "none" : "block";
        });
        document.getElementById("selectAll").addEventListener("change", function() {
            document.querySelectorAll(".prod-check").forEach(cb => cb.checked = this.checked);
        });
        document.getElementById("prodSearch").addEventListener("input", function() {
            const kw = this.value.toLowerCase();
            document.querySelectorAll("#prodBody tr").forEach(tr => {
                const name = tr.querySelector(".prod-name").innerText.toLowerCase();
                const sku  = tr.querySelector(".prod-sku").innerText.toLowerCase();
                tr.style.display = (name.includes(kw) || sku.includes(kw)) ? "" : "none";
            });
        });
    </script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
