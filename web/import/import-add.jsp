<%@page import="model.Request"%>
<%@page import="model.RequestDetail"%>
<%@page import="model.ProductItem"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Map"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%!
    private String escapeHtml(Object value) {
        if (value == null) return "";
        return value.toString().replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
%>
<%
    User loggedInUser = (User) session.getAttribute("user");
    if (loggedInUser == null || !loggedInUser.hasPermission("TICKET_ADD_IN")) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    List<Request> poList = (List<Request>) request.getAttribute("requestList");
    Request selectedRequest = (Request) request.getAttribute("selectedRequest");
    boolean isReturnRequest   = selectedRequest != null && "RETURN".equals(selectedRequest.getReason());
    boolean isTransferRequest = selectedRequest != null && "TRANSFER".equals(selectedRequest.getReason());
    boolean isTransferReturnRequest = isTransferRequest
            && Boolean.TRUE.equals(request.getAttribute("transferReturnReceipt"));
    boolean needsExistingSerialScan = isReturnRequest || isTransferRequest;
    boolean isPurchaseRequest = selectedRequest != null && "PURCHASE".equals(selectedRequest.getReason());
    boolean showCondition     = isReturnRequest || isTransferRequest;
    List<ProductItem> eligibleTransferItems =
            (List<ProductItem>) request.getAttribute("eligibleTransferItems");

    String error = request.getParameter("error");
    List<String> serialErrors = (List<String>) request.getAttribute("serialErrors");
    Map<Integer, Integer> existingSerialCounts = (Map<Integer, Integer>) request.getAttribute("existingSerialCounts");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tạo Phiếu nhập kho - WMS</title>
    
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    
    <link href="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/css/tom-select.bootstrap5.min.css" rel="stylesheet">
    <style>
        #wmsPrintPreview { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 12px; }
        .wms-label { border: 1px dashed #64748b; border-radius: 8px; padding: 12px; background: #fff; }
        @media print {
            body * { visibility: hidden !important; }
            body > * { display: none !important; }
            body > #wmsPrintHost { display: block !important; }
            #wmsPrintHost, #wmsPrintHost * { visibility: visible !important; }
            #wmsPrintPreview { display: grid !important; position: static !important; width: 100%; grid-template-columns: repeat(3, 1fr); gap: 10px; }
            .wms-label { break-inside: avoid; page-break-inside: avoid; }
        }
    </style>
    
    <link rel="stylesheet" href="<%= request.getContextPath() %>/css/style.css">
    <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>
</head>
<body>
    <jsp:include page="/includes/header.jsp" />
    <div class="container-fluid mt-4 px-4 animated-fade-in">
        <div class="row">
            <jsp:include page="/includes/sidebar.jsp" />
            <div class="col-md-9 col-lg-10">
                
                <div class="page-header">
                    <div>
                        <h2 class="page-title">Tạo Phiếu nhập kho</h2>
                        <p class="page-subtitle">Ghi nhận hàng hóa thực tế nhập kho theo Yêu cầu nhập đã duyệt</p>
                    </div>
                    <a href="import-ticket?action=list" class="btn btn-outline-secondary btn-sm d-inline-flex align-items-center gap-1">
                        <i class="bi bi-arrow-left"></i> Hủy
                    </a>
                </div>

                
                <div class="d-flex align-items-center gap-3 py-2 px-3 mb-4 rounded-3 bg-info bg-opacity-10">
                    <i class="bi bi-building-fill fs-5 text-info"></i>
                    <div class="small">
                        <span class="text-muted">Kho nhận hàng:</span>
                        <strong class="ms-1 text-info">
                            <%= loggedInUser.getWarehouseName() != null ? loggedInUser.getWarehouseName() : "Kho #" + loggedInUser.getWarehouseId() %>
                        </strong>
                        <span class="text-muted ms-2">— Hàng nhập sẽ được ghi vào kho này</span>
                    </div>
                </div>

                <% if (error != null) { %>
                <div class="alert alert-danger rounded-3 mb-4">
                    <% if ("NoItemsReceived".equals(error) || "NoItems".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Bạn phải nhận ít nhất một sản phẩm với số lượng lớn hơn 0.
                    <% } else if ("RequiresWarehouseAssignment".equals(error)) { %>
                        <i class="bi bi-building-fill me-2"></i> Tài khoản của bạn chưa được gán kho. Liên hệ quản trị viên để gán kho trước khi tạo phiếu nhập.
                    <% } else if ("InvalidPrice".equals(error)) { %>
                        <i class="bi bi-cash-coin me-2"></i> Đơn giá thực tế phải lớn hơn 0 đối với hàng nhập mua.
                    <% } else if ("InvalidSerialFile".equals(error)) { %>
                        <i class="bi bi-file-earmark-excel me-2"></i> File Excel serial nhà sản xuất không hợp lệ do sai SKU, sai số lượng hoặc trùng serial. Kiểm tra lại file rồi thử lại.
                    <% } else if ("InvalidManufacturerSerial".equals(error)
                            || "MissingManufacturerSerial".equals(error)
                            || "ManufacturerSerialCountMismatch".equals(error)) { %>
                        <i class="bi bi-upc-scan me-2"></i> Chưa nhập đủ serial nhà sản xuất cho các sản phẩm nhận kho.
                    <% } else if ("DuplicateManufacturerSerial".equals(error)) { %>
                        <i class="bi bi-exclamation-octagon-fill me-2"></i> Có serial nhà sản xuất đã tồn tại cho cùng sản phẩm. Phiếu chưa được nhập kho.
                    <% } else if ("WrongWarehouse".equals(error)) { %>
                        <i class="bi bi-building-fill me-2"></i> Bạn chỉ được nhập kho cho yêu cầu thuộc kho của mình.
                    <% } else if ("RequestNotApproved".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Yêu cầu này chưa được duyệt hoặc đang chờ hủy, không thể nhập kho.
                    <% } else if ("ReceiveFailed".equals(error)) { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Nhập kho thất bại do số lượng vượt yêu cầu, kho đang kiểm kê hoặc dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.
                    <% } else if ("MissingReturnSerial".equals(error) || "InvalidReturnSerial".equals(error)) { %>
                        <i class="bi bi-upc-scan me-2"></i> Hàng nhập lại phải được quét đủ và đúng serial của hàng đã xuất trong yêu cầu này.
                    <% } else if ("MissingTransferReturnSerial".equals(error) || "InvalidTransferReturnSerial".equals(error)) { %>
                        <i class="bi bi-upc-scan me-2"></i> Hàng trả phải được quét đủ và đúng serial còn đang trên đường của phiếu xuất gốc.
                    <% } else if ("MissingTransferSerial".equals(error) || "InvalidTransferSerial".equals(error)) { %>
                        <i class="bi bi-upc-scan me-2"></i> Hàng chuyển kho phải được quét đủ và đúng serial của phiếu xuất chuyển kho liên kết.
                    <% } else { %>
                        <i class="bi bi-exclamation-triangle-fill me-2"></i> Thao tác thất bại. Mã lỗi: <%= error %>. Vui lòng thử lại.
                    <% } %>
                </div>
                <% } %>

                <% if (serialErrors != null && !serialErrors.isEmpty()) { %>
                <div class="alert alert-warning rounded-3 mb-4">
                    <div class="fw-semibold mb-1"><i class="bi bi-list-check me-2"></i>Chi tiết cần kiểm tra:</div>
                    <ul class="mb-0 ps-4">
                        <% for (String serialError : serialErrors) { %>
                        <li><%= escapeHtml(serialError) %></li>
                        <% } %>
                    </ul>
                </div>
                <% } %>

                <div class="card card-overflow-visible bg-white mb-4" style="overflow: visible;">
                    <div class="card-header bg-transparent py-3 border-bottom">
                        <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-receipt me-2 text-primary"></i>Chọn Yêu cầu nhập kho tham chiếu</h5>
                    </div>
                    <div class="card-body p-4">
                        <div class="row align-items-end g-3">
                            <div class="col-md-8">
                                <label for="poSelect" class="form-label">Yêu cầu nhập tham chiếu <span class="text-danger">*</span></label>
                                <select class="form-select" id="poSelect">
                                    <option value="" <%= selectedRequest == null ? "selected" : "" %>></option>
                                    <%
                                        if (poList != null) {
                                            for (Request r : poList) {
                                                boolean isSel = selectedRequest != null && selectedRequest.getId() == r.getId();
                                                String displayStatus = r.getStatus();
                                                if ("APPROVED".equals(r.getStatus())) displayStatus = "Đã xác nhận";
                                                else if ("PENDING".equals(r.getStatus())) displayStatus = "Chờ duyệt";
                                    %>
                                    <option value="<%= r.getId() %>" <%= isSel ? "selected" : "" %>>
                                        #<%= r.getRequestCode() %> — <%= r.getPartnerName() %> · <%= displayStatus %>
                                    </option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <button type="button" class="btn btn-outline-secondary w-100" onclick="resetPOSelection()">
                                    <i class="bi bi-arrow-clockwise"></i> Xóa lựa chọn
                                </button>
                            </div>
                        </div>
                    </div>
                </div>

                <% if (selectedRequest != null) { %>
                <form action="import-ticket?action=addAndConfirm" method="POST" id="grnForm" enctype="multipart/form-data">
                    <input type="hidden" name="request_id" value="<%= selectedRequest.getId() %>">
                    
                    <div class="card bg-white mb-4" id="receiptDetailCard">
                        <div class="card-header bg-transparent py-3 border-bottom">
                            <h5 class="mb-0 fw-bold text-slate-800"><i class="bi bi-box-seam me-2 text-primary"></i>Chi tiết Phiếu nhập kho</h5>
                        </div>
                        <div class="card-body p-0">
                            <div class="table-responsive">
                            <table class="table align-middle text-center mb-0 editable-table" style="min-width: <%= showCondition ? "1120px" : "1040px" %>;">
                                <% if (showCondition) { %>
                                <colgroup>
                                    <col style="width:18%">
                                    <col style="width:10%">
                                    <col style="width:7%">
                                    <col style="width:8%">
                                    <col style="width:12%">
                                    <col style="width:11%">
                                    <col style="width:14%">
                                    <col style="width:10%">
                                    <col style="width:10%">
                                </colgroup>
                                <% } else { %>
                                <colgroup>
                                    <col style="width:22%">
                                    <col style="width:11%">
                                    <col style="width:8%">
                                    <col style="width:9%">
                                    <col style="width:14%">
                                    <col style="width:12%">
                                    <col style="width:15%">
                                    <col style="width:9%">
                                </colgroup>
                                <% } %>
                                <thead class="table-light">
                                    <tr>
                                        <th class="text-start ps-4">Tên sản phẩm</th>
                                        <th>SKU</th>
                                        <th>Đơn vị</th>
                                        <th>SL yêu cầu</th>
                                        <th>Đơn giá dự kiến</th>
                                        <th style="width: 15%;">SL thực tế nhận</th>
                                        <th style="width: 20%;">Đơn giá thực tế · VND</th>
                                        <% if (showCondition) { %><th>Tình trạng</th><% } %>
                                        <th>Thành tiền</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (selectedRequest.getDetails() != null) {
                                            for (RequestDetail d : selectedRequest.getDetails()) {
                                                int remaining = d.getQuantity() - d.getProcessedQuantity();
                                                if (remaining < 0) remaining = 0;
                                    %>
                                    <tr class="product-row">
                                        <td class="text-start ps-4 fw-semibold">
                                            <input type="hidden" name="product_id" value="<%= d.getProductId() %>">
                                            <span class="product-name"><%= d.getProductName() %></span>
                                        </td>
                                        <td><span class="badge bg-secondary bg-opacity-10 text-secondary product-sku"><%= d.getSku() %></span></td>
                                        <td><%= d.getUnit() %></td>
                                        <td class="text-muted"><%= remaining %></td>
                                        <td class="text-muted"><%= String.format("%,.0f", (d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0)) %> VND</td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm text-center qty-input" name="quantity" value="<%= remaining %>" min="0" max="<%= remaining %>" onkeydown="if(!/^[0-9]$/.test(event.key) && !['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab', 'Enter', 'Escape'].includes(event.key) && !event.ctrlKey && !event.metaKey) event.preventDefault();" required style="box-shadow: none;">
                                        </td>
                                        <td>
                                            <input type="number" class="form-control form-control-sm text-end price-input" name="unit_price" value="<%= (d.getUnitPrice() != null ? d.getUnitPrice().stripTrailingZeros().toPlainString() : "0") %>" min="0" step="any" onkeydown="if(!/^[0-9.]$/.test(event.key) && !['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'Tab', 'Enter', 'Escape'].includes(event.key) && !event.ctrlKey && !event.metaKey) event.preventDefault();" required style="box-shadow: none;">
                                        </td>
                                        <% if (showCondition) { %>
                                        <td>
                                            <% if (isTransferRequest) { %>
                                            <span class="badge bg-info bg-opacity-10 text-info">
                                                Giữ theo serial
                                            </span>
                                            <% } else { %>
                                            <select class="form-select form-select-sm" name="item_condition" style="box-shadow: none;">
                                                <% if (isReturnRequest) { %>
                                                <option value="USED" selected>Hàng cũ</option>
                                                <option value="NEW">Mới</option>
                                                <option value="DAMAGED">Hàng hỏng</option>
                                                <% } else { %>
                                                <option value="NEW" selected>Hàng mới</option>
                                                <option value="USED">Hàng cũ</option>
                                                <option value="DAMAGED">Hàng hỏng</option>
                                                <% } %>
                                            </select>
                                            <% } %>
                                        </td>
                                        <% } else { %>
                                        <input type="hidden" name="item_condition" value="NEW">
                                        <% } %>
                                        <td class="fw-bold row-total"><%= String.format("%,.0f", d.getQuantity() * (d.getUnitPrice() != null ? d.getUnitPrice().doubleValue() : 0.0)) %> VND</td>
                                    </tr>
                                    <%
                                            }
                                        }
                                    %>
                                    <tr class="table-light fw-bold">
                                        <td colspan="<%= showCondition ? 8 : 7 %>" class="text-end pe-4">Tổng giá trị thực tế:</td>
                                        <td id="grandTotal">0 VND</td>
                                    </tr>
                                </tbody>
                            </table>
                            </div>
                        </div>
                        <% if (isPurchaseRequest) { %>
                        <div class="card-body border-top pt-3 d-none" id="legacyExcelArea">
                            <label for="excelFile" class="form-label fw-semibold text-slate-700 small">
                                <i class="bi bi-file-earmark-excel text-success me-1"></i>
                                File Excel serial nhà sản xuất · Không bắt buộc
                            </label>
                            <input type="file" class="form-control form-control-sm" id="excelFile" name="excelFile" accept=".xlsx,.xls">
                            <div class="form-text">Nếu không đính kèm, hệ thống tự sinh serial cho hàng nhập mua.</div>
                        </div>
                        <% } %>
                        <% if (needsExistingSerialScan && !isTransferRequest) { %>
                        <div class="card-body border-top p-4 bg-warning bg-opacity-10">
                            <div class="d-flex align-items-start gap-3 mb-3">
                                <i class="bi bi-arrow-return-left fs-4 text-warning"></i>
                                <div>
                                    <h6 class="fw-bold mb-1"><%= isReturnRequest
                                            ? "Quét serial hàng nhập lại"
                                            : (isTransferReturnRequest
                                                ? "Quét serial hàng trả về kho nguồn"
                                                : "Quét serial hàng chuyển kho thực nhận") %></h6>
                                    <div class="small text-muted"><%= isReturnRequest
                                            ? "Chỉ serial của hàng đã được xuất theo yêu cầu này mới được nhập lại. Quét đủ số lượng thực tế nhận."
                                            : (isTransferReturnRequest
                                                ? "Chỉ serial của phiếu xuất chuyển kho đang bị hủy mới được nhận trả. Hệ thống sẽ đóng phiếu xuất gốc khi đã nhận đủ."
                                                : "Quét đúng serial WMS trên từng món hàng của phiếu xuất chuyển kho liên kết. Tình trạng hàng được giữ nguyên theo serial.") %></div>
                                </div>
                            </div>
                            <div class="input-group">
                                <input type="text" id="returnSerialInput" class="form-control" autocomplete="off" placeholder="Quét hoặc nhập serial WMS rồi nhấn Enter">
                                <button type="button" class="btn btn-warning" id="addReturnSerialButton"><i class="bi bi-plus-lg me-1"></i>Thêm serial</button>
                            </div>
                            <div id="returnSerialProgress" class="small mt-2 text-muted">Chưa quét serial nào.</div>
                            <div id="returnSerialList" class="d-flex flex-wrap gap-2 mt-2"></div>
                            <div id="returnSerialInputs"></div>
                        </div>
                        <% } %>
                        <div class="card-footer bg-light p-3 d-flex justify-content-end gap-2 border-top-0">
                            <a href="import-ticket?action=list" class="btn btn-outline-secondary px-4"><i class="bi bi-x-circle me-1"></i> Hủy</a>
                            <button type="submit" class="btn btn-primary px-4">
                                <i class="bi <%= isTransferRequest ? "bi-arrow-right-circle" : "bi-box-arrow-in-down" %> me-1"></i>
                                <%= isTransferRequest ? "Tiếp tục: quét serial" : "Nhập kho" %>
                            </button>
                        </div>
                    </div>

                    <% if (isTransferRequest) { %>
                    <div class="card bg-white mb-4 d-none" id="transferSerialCaptureCard">
                        <div class="card-header bg-warning bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                            <div>
                                <h5 class="mb-1 fw-bold text-warning">
                                    <i class="bi bi-upc-scan me-2"></i>
                                    <%= isTransferReturnRequest
                                            ? "Quét serial hàng trả về kho nguồn"
                                            : "Quét serial hàng chuyển kho thực nhận" %>
                                </h5>
                                <div class="small text-muted">
                                    <%= isTransferReturnRequest
                                            ? "Quét đúng các serial thuộc lô hàng đang được hoàn trả."
                                            : "Quét đúng serial WMS trên từng món hàng thực tế nhận; condition được giữ nguyên theo serial." %>
                                </div>
                            </div>
                            <button type="button" class="btn btn-sm btn-outline-secondary" onclick="backToTransferQuantities()">
                                <i class="bi bi-arrow-left me-1"></i>Sửa số lượng
                            </button>
                        </div>
                        <div class="card-body p-4 bg-warning bg-opacity-10">
                            <div class="input-group input-group-lg">
                                <input type="text" id="returnSerialInput" class="form-control" autocomplete="off"
                                       placeholder="Quét hoặc nhập serial WMS rồi nhấn Enter">
                                <button type="button" class="btn btn-warning" id="addReturnSerialButton">
                                    <i class="bi bi-plus-lg me-1"></i>Thêm serial
                                </button>
                            </div>
                            <div id="returnSerialProgress" class="small mt-3 text-muted">Chưa quét serial nào.</div>
                            <div id="returnSerialList" class="d-flex flex-wrap gap-2 mt-2"></div>
                            <div id="returnSerialInputs"></div>
                        </div>
                        <div class="card-footer bg-light p-3 d-flex justify-content-between align-items-center">
                            <span id="existingSerialCompletionText" class="small text-muted">Chưa quét đủ serial</span>
                            <button type="submit" id="confirmTransferReceiptButton"
                                    class="btn btn-secondary px-4" disabled>
                                <i class="bi bi-box-arrow-in-down me-1"></i>Nhập kho
                            </button>
                        </div>
                    </div>
                    <% } %>

                    <% if (isPurchaseRequest) { %>
                    <input type="hidden" name="serial_capture_mode" id="serialCaptureMode" value="SCAN">
                    <div class="card bg-white mb-4 d-none" id="serialCaptureCard">
                        <div class="card-header bg-primary bg-opacity-10 py-3 border-0 d-flex justify-content-between align-items-center">
                            <div>
                                <h5 class="mb-1 fw-bold text-primary"><i class="bi bi-upc-scan me-2"></i>Serial nhà sản xuất</h5>
                                <div class="small text-muted">Mỗi món hàng sẽ được ghép với một serial hãng; mã WMS vẫn do hệ thống tự sinh.</div>
                            </div>
                            <button type="button" class="btn btn-sm btn-outline-secondary" onclick="backToReceiptDetails()">
                                <i class="bi bi-arrow-left me-1"></i>Sửa số lượng
                            </button>
                        </div>
                        <div class="card-body p-4">
                            <div class="d-flex flex-wrap gap-2 mb-4">
                                <button type="button" id="scanModeButton" class="btn btn-primary" onclick="selectSerialMode('SCAN')">
                                    <i class="bi bi-upc-scan me-1"></i>Quét trực tiếp
                                </button>
                                <button type="button" id="excelModeButton" class="btn btn-outline-success" onclick="selectSerialMode('EXCEL')">
                                    <i class="bi bi-file-earmark-excel me-1"></i>Nhập từ Excel
                                </button>
                            </div>

                            <div id="scanModeArea">
                                <div class="alert alert-info py-2 small mb-3">
                                    <i class="bi bi-printer me-1"></i> Hệ thống tạo tem WMS trước. In và dán tem, sau đó quét tem WMS để tự chọn sản phẩm rồi quét serial nhà sản xuất.
                                </div>
                                <div id="wmsPrintStep" class="border rounded-3 p-3 mb-3 bg-light">
                                    <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                                        <div>
                                            <div class="fw-semibold">Bước 1 · In tem WMS</div>
                                            <div class="small text-muted">Mỗi tem dưới đây là một mã WMS sẽ được lưu cho đúng món hàng khi nhập kho.</div>
                                        </div>
                                        <button type="button" class="btn btn-primary" id="printWmsLabelsButton"><i class="bi bi-printer me-1"></i>In tem & bắt đầu quét</button>
                                    </div>
                                    <div id="wmsPrintPreview"></div>
                                </div>
                                <div id="wmsScanStep" class="d-none">
                                    <div class="mb-3">
                                        <label for="wmsScannerInput" class="form-label fw-semibold"><i class="bi bi-upc-scan me-1"></i>Quét tem WMS</label>
                                        <div class="input-group input-group-lg">
                                            <span class="input-group-text bg-light"><i class="bi bi-upc-scan"></i></span>
                                            <input type="text" id="wmsScannerInput" class="form-control border-primary" placeholder="Quét mã WMS vừa dán..." maxlength="100" autocomplete="off">
                                        </div>
                                        <div id="wmsScanAlert" class="alert d-none mt-2 mb-0 py-2" role="alert"></div>
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <label for="manufacturerScannerInput" class="form-label fw-semibold">
                                        Đang quét cho: <span id="activeProductLabel" class="text-primary">Chưa chọn sản phẩm</span>
                                    </label>
                                    <div class="input-group input-group-lg">
                                        <span class="input-group-text bg-light"><i class="bi bi-upc-scan"></i></span>
                                        <input type="text" id="manufacturerScannerInput" class="form-control border-primary"
                                               placeholder="Đặt con trỏ tại đây và quét serial..." maxlength="100" autocomplete="off">
                                    </div>
                                    <div id="manufacturerScanAlert" class="alert d-none mt-2 mb-0 py-2" role="alert"></div>
                                </div>
                                <h6 class="fw-bold mb-3"><i class="bi bi-list-check me-1"></i>Tiến độ theo sản phẩm</h6>
                                <div class="row g-3" id="manufacturerScanPanels"></div>
                                <div id="manufacturerSerialHiddenInputs"></div>
                            </div>

                            <div id="excelModeArea" class="d-none">
                                <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
                                    <label class="form-label fw-semibold mb-0">Chọn file danh sách serial nhà sản xuất</label>
                                    <button type="button" class="btn btn-outline-success btn-sm" onclick="downloadSerialTemplate()">
                                        <i class="bi bi-download me-1"></i>Tải file Excel mẫu
                                    </button>
                                </div>
                                <div id="excelFileHost"></div>
                                <div class="form-text mt-2">Nếu serial có số 0 ở đầu, hãy để cột serial trong Excel ở dạng Text.</div>
                            </div>
                        </div>
                        <div class="card-footer bg-light p-3 d-flex justify-content-between align-items-center">
                            <span id="serialCompletionText" class="small text-muted">Chưa quét đủ serial</span>
                            <button type="submit" id="confirmPurchaseReceiptButton" class="btn btn-secondary px-4" disabled>
                                <i class="bi bi-box-arrow-in-down me-1"></i>Nhập kho
                            </button>
                        </div>
                    </div>
                    <% } %>
                </form>
                <% } %>

            </div>
        </div>
    </div>

    
    <script src="https://cdn.jsdelivr.net/npm/tom-select@2.2.2/dist/js/tom-select.complete.min.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            new TomSelect("#poSelect", {
                create: false,
                placeholder: "-- Chọn Yêu cầu nhập đã duyệt/hoạt động --",
                onChange: function(value) {
                    loadPOItems(value);
                }
            });
        });

        function loadPOItems(poId) {
            if (poId) {
                window.location.href = "import-ticket?action=add&request_id=" + poId;
            }
        }

        function resetPOSelection() {
            window.location.href = 'import-ticket?action=add';
        }

        <% if (selectedRequest != null) { %>
        const isPurchaseReceipt = <%= isPurchaseRequest ? "true" : "false" %>;
        const existingSerialCounts = {
            <% if (existingSerialCounts != null) { int countIndex = 0; for (Map.Entry<Integer, Integer> entry : existingSerialCounts.entrySet()) { %>
            <%= entry.getKey() %>: <%= entry.getValue() %><%= (++countIndex < existingSerialCounts.size()) ? "," : "" %>
            <% } } %>
        };
        const needsExistingSerialScan = <%= needsExistingSerialScan ? "true" : "false" %>;
        const isTransferReceipt = <%= isTransferRequest ? "true" : "false" %>;
        const isTransferReturnReceipt = <%= isTransferReturnRequest ? "true" : "false" %>;
        const expectedReceiptSerials = new Set([
            <% if (isTransferRequest && eligibleTransferItems != null) {
                for (int i = 0; i < eligibleTransferItems.size(); i++) {
                    String serial = eligibleTransferItems.get(i).getSerialNumber(); %>
            "<%= escapeHtml(serial).replace("\\", "\\\\").replace("\"", "\\\"") %>"<%= i + 1 < eligibleTransferItems.size() ? "," : "" %>
            <%  }
               } else if (isReturnRequest && selectedRequest.getExpectedSerials() != null) {
                String[] serials = selectedRequest.getExpectedSerials().split(",");
                for (int i = 0; i < serials.length; i++) { %>
            "<%= escapeHtml(serials[i].trim()).replace("\\", "\\\\").replace("\"", "\\\"") %>"<%= i + 1 < serials.length ? "," : "" %>
            <%  }
               } %>
        ]);
        let scannedReceiptSerials = [];
        let existingSerialStepOpen = false;
        let scannedWmsByProduct = {};
        let activeManufacturerWmsSerial = null;
        let serialStepOpen = false;
        let serialMode = "SCAN";
        let serialProducts = [];
        let scannedManufacturerSerials = {};
        let activeManufacturerProductId = null;

        document.addEventListener("DOMContentLoaded", function() {
            const qtyInputs = document.querySelectorAll(".qty-input");
            const priceInputs = document.querySelectorAll(".price-input");
            
            qtyInputs.forEach(input => input.addEventListener("input", function() {
                if (this.value !== "") {
                    let val = parseInt(this.value);
                    let max = parseInt(this.getAttribute("max"));
                    if (!isNaN(val) && !isNaN(max) && val > max) {
                        this.value = max;
                    }
                }
                recalculateTotals();
            }));
            priceInputs.forEach(input => input.addEventListener("input", recalculateTotals));
            
            recalculateTotals();
            if (isPurchaseReceipt) initializePurchaseSerialUi();
            if (needsExistingSerialScan) initializeExistingSerialUi();
        });

        function initializeExistingSerialUi() {
            const input = document.getElementById("returnSerialInput");
            const addButton = document.getElementById("addReturnSerialButton");
            input.addEventListener("keydown", function(event) {
                if (event.key === "Enter") { event.preventDefault(); addReceiptSerial(); }
            });
            addButton.addEventListener("click", addReceiptSerial);
            document.getElementById("grnForm").addEventListener("submit", function(event) {
                const needed = Array.from(document.querySelectorAll(".qty-input"))
                        .reduce(function(sum, el) { return sum + (parseInt(el.value) || 0); }, 0);
                if (isTransferReceipt && !existingSerialStepOpen) {
                    event.preventDefault();
                    event.stopImmediatePropagation();
                    if (needed <= 0) {
                        alert("Bạn phải chọn ít nhất một sản phẩm với số lượng lớn hơn 0.");
                        return;
                    }
                    openTransferSerialCapture();
                    return;
                }
                if (needed === 0 || scannedReceiptSerials.length !== needed) {
                    event.preventDefault();
                    event.stopImmediatePropagation();
                    alert("Số serial quét phải đúng bằng tổng số lượng thực tế nhận.");
                }
            }, true);
            if (!isTransferReceipt) input.focus();
        }

        function openTransferSerialCapture() {
            existingSerialStepOpen = true;
            document.getElementById("receiptDetailCard").classList.add("d-none");
            const captureCard = document.getElementById("transferSerialCaptureCard");
            captureCard.classList.remove("d-none");
            document.querySelectorAll(".qty-input, .price-input").forEach(function(field) {
                field.setAttribute("readonly", "readonly");
            });
            updateExistingSerialCompletion();
            const input = document.getElementById("returnSerialInput");
            input.focus();
            window.scrollTo({ top: captureCard.offsetTop - 20, behavior: "smooth" });
        }

        function backToTransferQuantities() {
            if (scannedReceiptSerials.length > 0
                    && !confirm("Danh sách serial đã quét sẽ bị xóa. Bạn có muốn sửa số lượng không?")) {
                return;
            }
            existingSerialStepOpen = false;
            scannedReceiptSerials = [];
            renderReceiptSerials();
            document.getElementById("transferSerialCaptureCard").classList.add("d-none");
            document.getElementById("receiptDetailCard").classList.remove("d-none");
            document.querySelectorAll(".qty-input, .price-input").forEach(function(field) {
                field.removeAttribute("readonly");
            });
            window.scrollTo({ top: document.getElementById("receiptDetailCard").offsetTop - 20, behavior: "smooth" });
        }

        function addReceiptSerial() {
            const input = document.getElementById("returnSerialInput");
            const serial = input.value.trim();
            if (!serial) return;
            if (!expectedReceiptSerials.has(serial)) {
                alert(isTransferReturnReceipt
                        ? "Serial không thuộc lô hàng chuyển kho đang chờ trả."
                        : (isTransferReceipt
                            ? "Serial không thuộc phiếu xuất chuyển kho đang chờ nhận."
                            : "Serial không thuộc hàng đã xuất của yêu cầu nhập lại này.")); return;
            }
            if (scannedReceiptSerials.includes(serial)) {
                alert("Serial này đã được quét."); return;
            }
            scannedReceiptSerials.push(serial);
            input.value = "";
            input.focus();
            renderReceiptSerials();
        }

        function renderReceiptSerials() {
            const list = document.getElementById("returnSerialList");
            const inputs = document.getElementById("returnSerialInputs");
            list.replaceChildren(); inputs.replaceChildren();
            scannedReceiptSerials.forEach(function(serial, index) {
                const badge = document.createElement("span");
                badge.className = "badge bg-white text-dark border font-monospace";
                const text = document.createTextNode(serial + " ");
                const remove = document.createElement("button");
                remove.type = "button"; remove.className = "btn-close ms-1"; remove.style.fontSize = "0.55rem";
                remove.addEventListener("click", function() { scannedReceiptSerials.splice(index, 1); renderReceiptSerials(); });
                badge.append(text, remove); list.appendChild(badge);
                const hidden = document.createElement("input");
                hidden.type = "hidden"; hidden.name = "scanned_serials"; hidden.value = serial; inputs.appendChild(hidden);
            });
            const needed = Array.from(document.querySelectorAll(".qty-input"))
                    .reduce(function(sum, el) { return sum + (parseInt(el.value) || 0); }, 0);
            document.getElementById("returnSerialProgress").textContent = "Đã quét "
                    + scannedReceiptSerials.length + "/" + needed + " serial.";
            updateExistingSerialCompletion();
        }

        function updateExistingSerialCompletion() {
            if (!isTransferReceipt) return;
            const needed = Array.from(document.querySelectorAll(".qty-input"))
                    .reduce(function(sum, el) { return sum + (parseInt(el.value) || 0); }, 0);
            const complete = needed > 0 && scannedReceiptSerials.length === needed;
            const button = document.getElementById("confirmTransferReceiptButton");
            const text = document.getElementById("existingSerialCompletionText");
            if (!button || !text) return;
            button.disabled = !complete;
            button.className = complete ? "btn btn-primary px-4" : "btn btn-secondary px-4";
            text.textContent = complete
                    ? "Đã đủ " + needed + " serial"
                    : "Đã quét " + scannedReceiptSerials.length + "/" + needed + " serial";
        }

        function recalculateTotals() {
            let total = 0;
            const rows = document.querySelectorAll("#grnForm tbody tr");
            
            rows.forEach(row => {
                const qtyInput = row.querySelector(".qty-input");
                const priceInput = row.querySelector(".price-input");
                
                if (qtyInput && priceInput) {
                    const qty = parseInt(qtyInput.value) || 0;
                    const price = parseFloat(priceInput.value) || 0;
                    const rowTotal = qty * price;
                    
                    total += rowTotal;
                    row.querySelector(".row-total").textContent = formatNumber(rowTotal) + " VND";
                }
            });
            
            document.getElementById("grandTotal").textContent = formatNumber(total) + " VND";
        }

        function formatNumber(num) {
            return parseFloat(num).toLocaleString('vi-VN');
        }

        function initializePurchaseSerialUi() {
            const firstStepButton = document.querySelector("#receiptDetailCard button[type='submit']");
            if (firstStepButton) {
                firstStepButton.innerHTML = '<i class="bi bi-arrow-right-circle me-1"></i>Tiếp tục: nhập serial';
            }

            const excelFile = document.getElementById("excelFile");
            const excelHost = document.getElementById("excelFileHost");
            if (excelFile && excelHost) {
                excelFile.classList.remove("form-control-sm");
                excelHost.appendChild(excelFile);
                excelFile.addEventListener("change", updateSerialCompletion);
            }

            const excelButton = document.getElementById("excelModeButton");
            const excelArea = document.getElementById("excelModeArea");
            if (excelButton) excelButton.classList.add("d-none");
            if (excelArea) excelArea.classList.add("d-none");
            const wmsScanner = document.getElementById("wmsScannerInput");
            if (wmsScanner) wmsScanner.addEventListener("keydown", function(event) {
                if (event.key === "Enter") { event.preventDefault(); processWmsLabelScan(this.value); this.value = ""; }
            });
            const printButton = document.getElementById("printWmsLabelsButton");
            if (printButton) printButton.addEventListener("click", function() {
                const preview = document.getElementById("wmsPrintPreview");
                const originalParent = preview ? preview.parentElement : null;
                const originalNextSibling = preview ? preview.nextSibling : null;
                const printHost = document.createElement("div");
                printHost.id = "wmsPrintHost";
                if (preview && originalParent) {
                    printHost.appendChild(preview);
                    document.body.appendChild(printHost);
                }
                let restored = false;
                const restorePrintPreview = function() {
                    if (restored) return;
                    restored = true;
                    if (preview && originalParent) {
                        originalParent.insertBefore(preview, originalNextSibling);
                    }
                    if (printHost.parentNode) printHost.parentNode.removeChild(printHost);
                    window.removeEventListener("afterprint", restorePrintPreview);
                };
                window.addEventListener("afterprint", restorePrintPreview);
                window.print();
                document.getElementById("wmsPrintStep").classList.add("d-none");
                document.getElementById("wmsScanStep").classList.remove("d-none");
                if (wmsScanner) wmsScanner.focus();
            });

            const scanner = document.getElementById("manufacturerScannerInput");
            if (scanner) {
                scanner.addEventListener("keydown", function(event) {
                    if (event.key === "Enter") {
                        event.preventDefault();
                        processManufacturerScan(this.value);
                        this.value = "";
                    }
                });
            }
        }

        function collectSerialProducts() {
            return Array.from(document.querySelectorAll("#grnForm tbody .product-row")).map(function(row) {
                return {
                    id: parseInt(row.querySelector("input[name='product_id']").value),
                    name: row.querySelector(".product-name").textContent.trim(),
                    sku: row.querySelector(".product-sku").textContent.trim(),
                    qty: parseInt(row.querySelector(".qty-input").value) || 0
                };
            }).filter(function(product) { return product.qty > 0; });
        }

        function openSerialCapture() {
            serialProducts = collectSerialProducts();
            if (serialProducts.length === 0) {
                alert("Bạn phải nhận ít nhất một sản phẩm trước khi nhập serial.");
                return;
            }

            scannedManufacturerSerials = {};
            serialProducts.forEach(function(product) { scannedManufacturerSerials[product.id] = []; });
            serialProducts.forEach(function(product) {
                scannedWmsByProduct[product.id] = [];
            });
            serialStepOpen = true;
            const printStep = document.getElementById("wmsPrintStep");
            const scanStep = document.getElementById("wmsScanStep");
            if (printStep) printStep.classList.remove("d-none");
            if (scanStep) scanStep.classList.add("d-none");
            document.getElementById("receiptDetailCard").classList.add("d-none");
            document.getElementById("serialCaptureCard").classList.remove("d-none");
            document.querySelectorAll(".qty-input, .price-input").forEach(function(input) {
                input.setAttribute("readonly", "readonly");
            });
            buildWmsPrintPreview();
            document.getElementById("wmsScanStep").classList.add("d-none");
            buildManufacturerScanPanels();
            selectSerialMode("SCAN");
            window.scrollTo({ top: document.getElementById("serialCaptureCard").offsetTop - 20, behavior: "smooth" });
        }

        function backToReceiptDetails() {
            const hasScans = Object.keys(scannedManufacturerSerials).some(function(productId) {
                return scannedManufacturerSerials[productId].length > 0;
            });
            if (hasScans && !confirm("Danh sách serial và tem WMS đã in sẽ bị bỏ. Bạn có muốn sửa số lượng và in lại tem không?")) return;

            serialStepOpen = false;
            scannedManufacturerSerials = {};
            scannedWmsByProduct = {};
            activeManufacturerProductId = null;
            activeManufacturerWmsSerial = null;
            const printStep = document.getElementById("wmsPrintStep");
            const scanStep = document.getElementById("wmsScanStep");
            if (printStep) printStep.classList.remove("d-none");
            if (scanStep) scanStep.classList.add("d-none");
            const preview = document.getElementById("wmsPrintPreview");
            if (preview) preview.replaceChildren();
            document.getElementById("manufacturerSerialHiddenInputs").replaceChildren();
            document.getElementById("serialCaptureCard").classList.add("d-none");
            document.getElementById("receiptDetailCard").classList.remove("d-none");
            document.querySelectorAll(".qty-input, .price-input").forEach(function(input) {
                input.removeAttribute("readonly");
            });
        }

        function buildManufacturerScanPanels() {
            const container = document.getElementById("manufacturerScanPanels");
            container.replaceChildren();

            serialProducts.forEach(function(product) {
                const column = document.createElement("div");
                column.className = "col-lg-4 col-md-6";

                const card = document.createElement("div");
                card.className = "card h-100 border-2 manufacturer-product-card";
                card.id = "manufacturer-card-" + product.id;
                card.tabIndex = 0;
                card.style.cursor = "default";

                const body = document.createElement("div");
                body.className = "card-body p-3";

                const top = document.createElement("div");
                top.className = "d-flex justify-content-between gap-2 mb-2";
                const titleWrap = document.createElement("div");
                const title = document.createElement("div");
                title.className = "fw-bold text-slate-800";
                title.textContent = product.name;
                const sku = document.createElement("div");
                sku.className = "small text-muted font-monospace";
                sku.textContent = product.sku;
                titleWrap.append(title, sku);
                const progress = document.createElement("span");
                progress.className = "badge bg-light text-dark border align-self-start";
                progress.id = "manufacturer-progress-" + product.id;
                top.append(titleWrap, progress);

                const hint = document.createElement("div");
                hint.className = "small text-primary mb-2";
                hint.textContent = "Quét tem WMS đã in để chọn đúng sản phẩm";

                const list = document.createElement("ul");
                list.className = "list-group list-group-flush small border-top pt-1";
                list.id = "manufacturer-list-" + product.id;
                list.style.maxHeight = "150px";
                list.style.overflowY = "auto";

                body.append(top, hint, list);
                card.appendChild(body);
                column.appendChild(card);
                container.appendChild(column);
                renderManufacturerProduct(product.id);
            });

            updateSerialCompletion();
        }

        function activateManufacturerProduct(productId) {
            activeManufacturerProductId = productId;
            document.querySelectorAll(".manufacturer-product-card").forEach(function(card) {
                card.classList.remove("border-primary", "bg-primary-subtle");
            });
            const selectedCard = document.getElementById("manufacturer-card-" + productId);
            if (selectedCard) selectedCard.classList.add("border-primary", "bg-primary-subtle");
            const product = serialProducts.find(function(item) { return item.id === productId; });
            document.getElementById("activeProductLabel").textContent = product
                    ? product.name + " — " + product.sku : "Chưa chọn sản phẩm";
            const scanner = document.getElementById("manufacturerScannerInput");
            if (scanner && serialMode === "SCAN") scanner.focus();
        }

        function processManufacturerScan(rawSerial) {
            const serial = rawSerial.trim();
            if (!activeManufacturerProductId || !activeManufacturerWmsSerial) {
                showManufacturerScanAlert("Hãy quét tem WMS trước khi quét serial nhà sản xuất.", false);
                playManufacturerBeep(false);
                return;
            }
            if (!serial || serial.length > 100 || /[\u0000-\u001F\u007F]/.test(serial)) {
                showManufacturerScanAlert("Serial trống, quá dài hoặc chứa ký tự không hợp lệ.", false);
                playManufacturerBeep(false);
                return;
            }

            const product = serialProducts.find(function(item) { return item.id === activeManufacturerProductId; });
            const values = scannedManufacturerSerials[activeManufacturerProductId];
            if (values.length >= product.qty) {
                showManufacturerScanAlert("Sản phẩm này đã quét đủ số lượng.", false);
                playManufacturerBeep(false);
                return;
            }
            if (values.some(function(value) { return value.toLocaleLowerCase() === serial.toLocaleLowerCase(); })) {
                showManufacturerScanAlert("Serial " + serial + " đã được quét cho sản phẩm này.", false);
                playManufacturerBeep(false);
                return;
            }

            values.push(serial);
            scannedWmsByProduct[activeManufacturerProductId].push(activeManufacturerWmsSerial);
            activeManufacturerWmsSerial = null;
            renderManufacturerProduct(activeManufacturerProductId);
            rebuildManufacturerHiddenInputs();
            showManufacturerScanAlert("Đã nhận serial " + serial + ".", true);
            playManufacturerBeep(true);

            if (values.length === product.qty) {
                const next = serialProducts.find(function(item) {
                    return scannedManufacturerSerials[item.id].length < item.qty;
                });
                activeManufacturerProductId = null;
                document.getElementById("activeProductLabel").textContent = "Quét tem WMS tiếp theo";
                const wmsScanner = document.getElementById("wmsScannerInput");
                if (next && wmsScanner) wmsScanner.focus();
            }
            updateSerialCompletion();
        }

        function renderManufacturerProduct(productId) {
            const product = serialProducts.find(function(item) { return item.id === productId; });
            const values = scannedManufacturerSerials[productId] || [];
            const progress = document.getElementById("manufacturer-progress-" + productId);
            const list = document.getElementById("manufacturer-list-" + productId);
            if (!product || !progress || !list) return;

            progress.textContent = values.length + "/" + product.qty;
            progress.className = "badge align-self-start "
                    + (values.length === product.qty ? "bg-success" : "bg-light text-dark border");
            list.replaceChildren();
            if (values.length === 0) {
                const empty = document.createElement("li");
                empty.className = "list-group-item bg-transparent text-muted text-center py-2";
                empty.textContent = "Chưa quét serial nào";
                list.appendChild(empty);
                return;
            }

            values.forEach(function(serial, index) {
                const item = document.createElement("li");
                item.className = "list-group-item bg-transparent px-0 py-1 d-flex justify-content-between align-items-center";
                const text = document.createElement("span");
                text.className = "font-monospace text-break";
                text.textContent = serial;
                const remove = document.createElement("button");
                remove.type = "button";
                remove.className = "btn btn-link btn-sm text-danger p-0 ms-2";
                remove.setAttribute("aria-label", "Xóa serial");
                remove.innerHTML = '<i class="bi bi-trash"></i>';
                remove.addEventListener("click", function(event) {
                    event.stopPropagation();
                    removeManufacturerSerial(productId, index);
                });
                item.append(text, remove);
                list.appendChild(item);
            });
        }

        function removeManufacturerSerial(productId, index) {
            scannedManufacturerSerials[productId].splice(index, 1);
            scannedWmsByProduct[productId].splice(index, 1);
            renderManufacturerProduct(productId);
            rebuildManufacturerHiddenInputs();
            activateManufacturerProduct(productId);
            updateSerialCompletion();
        }

        function rebuildManufacturerHiddenInputs() {
            const container = document.getElementById("manufacturerSerialHiddenInputs");
            container.replaceChildren();
            serialProducts.forEach(function(product) {
                (scannedManufacturerSerials[product.id] || []).forEach(function(serial, serialIndex) {
                    const productInput = document.createElement("input");
                    productInput.type = "hidden";
                    productInput.name = "manufacturer_product_id";
                    productInput.value = product.id;
                    const serialInput = document.createElement("input");
                    serialInput.type = "hidden";
                    serialInput.name = "manufacturer_serial";
                    serialInput.value = serial;
                    const wmsInput = document.createElement("input");
                    wmsInput.type = "hidden";
                    wmsInput.name = "wms_serial";
                    wmsInput.value = (scannedWmsByProduct[product.id] || [])[serialIndex] || "";
                    container.append(productInput, serialInput, wmsInput);
                });

            });
        }

        function selectSerialMode(mode) {
            serialMode = mode;
            document.getElementById("serialCaptureMode").value = mode;
            document.getElementById("scanModeArea").classList.toggle("d-none", mode !== "SCAN");
            document.getElementById("excelModeArea").classList.toggle("d-none", mode !== "EXCEL");
            document.getElementById("scanModeButton").className = mode === "SCAN"
                    ? "btn btn-primary" : "btn btn-outline-primary";
            document.getElementById("excelModeButton").className = mode === "EXCEL"
                    ? "btn btn-success" : "btn btn-outline-success";
            updateSerialCompletion();
            if (mode === "SCAN") {
                setTimeout(function() {
                    const wmsScanner = document.getElementById("wmsScannerInput");
                    if (wmsScanner) wmsScanner.focus();
                }, 0);
            }
        }

        function downloadSerialTemplate() {
            const params = new URLSearchParams();
            params.set("action", "downloadSerialTemplate");
            params.set("request_id", "<%= selectedRequest.getId() %>");
            serialProducts.forEach(function(product) {
                params.append("product_id", product.id);
                params.append("quantity", product.qty);
            });
            window.location.href = "import-ticket?" + params.toString();
        }

        function updateSerialCompletion() {
            if (!isPurchaseReceipt) return;
            const button = document.getElementById("confirmPurchaseReceiptButton");
            const text = document.getElementById("serialCompletionText");
            if (serialMode === "EXCEL") {
                const file = document.getElementById("excelFile");
                const ready = file && file.files && file.files.length > 0;
                button.disabled = !ready;
                button.className = ready ? "btn btn-primary px-4" : "btn btn-secondary px-4";
                text.textContent = ready ? "Đã chọn file " + file.files[0].name : "Chưa chọn file Excel";
                return;
            }

            const complete = serialProducts.length > 0 && serialProducts.every(function(product) {
                return scannedManufacturerSerials[product.id]
                        && scannedManufacturerSerials[product.id].length === product.qty;
            });
            const totalRequired = serialProducts.reduce(function(sum, product) { return sum + product.qty; }, 0);
            const totalScanned = Object.keys(scannedManufacturerSerials).reduce(function(sum, productId) {
                return sum + scannedManufacturerSerials[productId].length;
            }, 0);
            button.disabled = !complete;
            button.className = complete ? "btn btn-primary px-4" : "btn btn-secondary px-4";
            text.textContent = complete ? "Đã đủ " + totalScanned + " serial"
                    : "Đã quét " + totalScanned + "/" + totalRequired + " serial";
        }

        function showManufacturerScanAlert(message, success) {
            const alertBox = document.getElementById("manufacturerScanAlert");
            alertBox.textContent = message;
            alertBox.className = "alert mt-2 mb-0 py-2 " + (success ? "alert-success" : "alert-danger");
        }

        function playManufacturerBeep(success) {
            try {
                const AudioContextClass = window.AudioContext || window.webkitAudioContext;
                const context = new AudioContextClass();
                const oscillator = context.createOscillator();
                const gain = context.createGain();
                oscillator.connect(gain);
                gain.connect(context.destination);
                oscillator.frequency.value = success ? 800 : 160;
                gain.gain.value = 0.07;
                oscillator.start();
                setTimeout(function() { oscillator.stop(); context.close(); }, success ? 80 : 250);
            } catch (ignored) {}
        }

        document.getElementById("grnForm").addEventListener("submit", function(e) {
            if (isPurchaseReceipt && !serialStepOpen) {
                e.preventDefault();
                if (!this.checkValidity()) {
                    this.reportValidity();
                    return;
                }
                const invalidPriceRow = Array.from(document.querySelectorAll("#grnForm tbody .product-row")).find(function(row) {
                    const quantity = parseInt(row.querySelector(".qty-input").value) || 0;
                    const price = parseFloat(row.querySelector(".price-input").value) || 0;
                    return quantity > 0 && price <= 0;
                });
                if (invalidPriceRow) {
                    alert("Đơn giá thực tế phải lớn hơn 0 đối với sản phẩm được nhận.");
                    invalidPriceRow.querySelector(".price-input").focus();
                    return;
                }
                openSerialCapture();
                return;
            }
            if (isPurchaseReceipt && serialMode === "SCAN") {
                const complete = serialProducts.length > 0 && serialProducts.every(function(product) {
                    return scannedManufacturerSerials[product.id]
                            && scannedManufacturerSerials[product.id].length === product.qty;
                });
                if (!complete) {
                    e.preventDefault();
                    alert("Bạn cần quét đủ serial nhà sản xuất trước khi nhập kho.");
                    return;
                }
            }
            if (isPurchaseReceipt && serialMode === "EXCEL") {
                const file = document.getElementById("excelFile");
                if (!file || !file.files || file.files.length === 0) {
                    e.preventDefault();
                    alert("Bạn chưa chọn file Excel serial nhà sản xuất.");
                    return;
                }
            }

            const qtyInputs = document.querySelectorAll(".qty-input");
            let totalQty = 0;
            qtyInputs.forEach(input => {
                totalQty += parseInt(input.value) || 0;
            });

            if (totalQty <= 0) {
                e.preventDefault();
                alert("Bạn phải nhận ít nhất một sản phẩm với số lượng lớn hơn 0.");
                return;
            }
            if (!confirm("Xác nhận NHẬP KHO các sản phẩm này? Hàng sẽ được cộng vào tồn kho ngay.")) {
                e.preventDefault();
            }
        });
        <% } %>

        function getWmsLabels(product) {
            if (!product.wmsLabels) {
                const safeSku = (product.sku || "ITEM").replace(/[^A-Za-z0-9-]/g, "").slice(0, 42) || "ITEM";
                product.wmsLabels = Array.from({ length: product.qty }, function(_, index) {
                    return safeSku + "-" + String((existingSerialCounts[product.id] || 0) + index + 1).padStart(3, "0");
                });
            }
            return product.wmsLabels;
        }

        function buildWmsPrintPreview() {
            const preview = document.getElementById("wmsPrintPreview");
            if (!preview) return;
            preview.replaceChildren();
            serialProducts.forEach(function(product) {
                getWmsLabels(product).forEach(function(wms, index) {
                    const label = document.createElement("div");
                    label.className = "wms-label";
                    label.innerHTML = "<div class='small text-muted'>" + product.sku + " · Tem " + (index + 1) + "/" + product.qty + "</div>"
                            + "<div class='fw-bold mt-1'>" + product.name + "</div>"
                            + "<div class='font-monospace fw-bold fs-5 mt-2'>" + wms + "</div>"
                            + "<div class='small text-muted mt-1'>Quét mã này trước, rồi quét serial nhà sản xuất.</div>";
                    const barcode = document.createElementNS("http://www.w3.org/2000/svg", "svg");
                    barcode.setAttribute("class", "mt-2 w-100");
                    try { if (window.JsBarcode) window.JsBarcode(barcode, wms, { format: "CODE128", displayValue: false, height: 42, margin: 0 }); } catch (ignored) {}
                    label.appendChild(barcode);
                    preview.appendChild(label);
                });
            });
        }

        function processWmsLabelScan(rawWms) {
            const wms = rawWms.trim();
            const alertBox = document.getElementById("wmsScanAlert");
            const show = function(message, success) {
                alertBox.textContent = message;
                alertBox.className = "alert mt-2 mb-0 py-2 " + (success ? "alert-success" : "alert-danger");
            };
            const product = serialProducts.find(function(item) {
                return getWmsLabels(item).some(function(label) { return label.toLowerCase() === wms.toLowerCase(); });
            });
            if (!product) { show("Mã WMS không thuộc phiếu nhập này.", false); playManufacturerBeep(false); return; }
            if ((scannedWmsByProduct[product.id] || []).some(function(value) { return value.toLowerCase() === wms.toLowerCase(); })) {
                show("Tem WMS này đã được ghép serial nhà sản xuất.", false); playManufacturerBeep(false); return;
            }
            activeManufacturerWmsSerial = getWmsLabels(product).find(function(label) { return label.toLowerCase() === wms.toLowerCase(); });
            activateManufacturerProduct(product.id);
            show("Đã chọn " + product.name + ". Quét serial nhà sản xuất ngay bây giờ.", true);
            playManufacturerBeep(true);
        }
</script>
</body>
</html>
