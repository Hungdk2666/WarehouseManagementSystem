package controller.warehouse;

import service.RequestService;
import service.TicketService;
import service.ProductItemService;
import service.ProductService;
import service.ManufacturerSerialExcelService;
import model.Product;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;
import model.ProductItem;
import model.Request;
import model.Ticket;
import model.TicketDetail;
import model.User;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

@WebServlet(name = "ImportTicketServlet", urlPatterns = { "/warehouse/import-ticket", "/warehouse/import" })
@MultipartConfig(maxFileSize = 5 * 1024 * 1024)
public class ImportTicketServlet extends HttpServlet {

    private static final String TYPE = Ticket.TYPE_IN;

    private boolean canAccessWarehouse(User user, int warehouseId) {
        return user.getWarehouseId() == null || user.getWarehouseId() == warehouseId;
    }

    @Override
    protected void doGet(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) {
            response.sendRedirect(httpReq.getContextPath() + "/login");
            return;
        }

        String action = httpReq.getParameter("action");
        if (action == null)
            action = "list";

        if (("list".equals(action) || "detail".equals(action)) && !loggedInUser.hasPermission("TICKET_VIEW_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem phiếu nhập.");
            return;
        }
        if (("add".equals(action) || "downloadSerialTemplate".equals(action))
                && !loggedInUser.hasPermission("TICKET_ADD_IN")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo phiếu nhập.");
            return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();

        switch (action) {
            case "list":
                httpReq.setAttribute("ticketList", ticketService.getAll(TYPE, loggedInUser.getWarehouseId()));
                if (loggedInUser.getWarehouseId() != null) {
                    httpReq.setAttribute("incomingTransfers",
                            ticketService.getIncomingTransfersForWarehouse(loggedInUser.getWarehouseId()));
                }
                httpReq.getRequestDispatcher("/import/import-list.jsp").forward(httpReq, response);
                break;
            case "detail": {
                int id = Integer.parseInt(httpReq.getParameter("id"));
                Ticket ticket = ticketService.getById(id);
                if (ticket == null) {
                    response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
                    return;
                }
                if (!canAccessWarehouse(loggedInUser, ticket.getWarehouseId())) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Ticket belongs to another warehouse.");
                    return;
                }
                if (Ticket.STATUS_CONFIRMED.equals(ticket.getStatus())
                        || Ticket.STATUS_COMPLETED.equals(ticket.getStatus())) {
                    List<ProductItem> serials = new ProductItemService().getItemsByTicketId(id);
                    httpReq.setAttribute("importedSerials", serials);
                }
                httpReq.setAttribute("ticket", ticket);
                httpReq.getRequestDispatcher("/import/import-detail.jsp").forward(httpReq, response);
                break;
            }
            case "add": {
                // Lá»c theo kho cá»§a user: staff_hcm chá»‰ tháº¥y yĂªu cáº§u nháº­p cá»§a TPHCM, staff_hn
                // chá»‰ tháº¥y HN
                Integer userWh = loggedInUser.getWarehouseId();
                // Block khi kho đang có phiếu kiểm kê chạy
                if (userWh != null) {
                    model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(userWh);
                    if (active != null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list"
                                + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                        return;
                    }
                }
                List<Request> pendingRequests = requestService.getPendingOrApproved(Request.TYPE_IN, userWh);
                httpReq.setAttribute("requestList", pendingRequests);
                String reqIdParam = httpReq.getParameter("request_id");
                if (reqIdParam != null && !reqIdParam.trim().isEmpty()) {
                    int reqId = Integer.parseInt(reqIdParam);
                    Request selectedRequest = requestService.getById(reqId);
                    if (selectedRequest == null || !canAccessWarehouse(loggedInUser, selectedRequest.getWarehouseId())) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "Request belongs to another warehouse.");
                        return;
                    }
                    httpReq.setAttribute("selectedRequest", selectedRequest);
                }
                Object serialErrors = session.getAttribute("importSerialErrors");
                if (serialErrors != null) {
                    httpReq.setAttribute("serialErrors", serialErrors);
                    session.removeAttribute("importSerialErrors");
                }
                httpReq.getRequestDispatcher("/import/import-add.jsp").forward(httpReq, response);
                break;
            }
            case "downloadSerialTemplate":
                downloadManufacturerSerialTemplate(httpReq, response, loggedInUser, requestService);
                return;
            default:
                response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) {
            response.sendRedirect(httpReq.getContextPath() + "/login");
            return;
        }

        String action = httpReq.getParameter("action");
        if (action == null) {
            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
            return;
        }

        if ("addAndConfirm".equals(action)
                && !(loggedInUser.hasPermission("TICKET_ADD_IN") && loggedInUser.hasPermission("TICKET_CONFIRM_IN"))) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền tạo và nhập kho.");
            return;
        }

        TicketService ticketService = new TicketService();
        RequestService requestService = new RequestService();

        try {
            switch (action) {
                case "addAndConfirm": {
                    // GỘP 1 MÀN HÌNH: tạo phiếu nhập + nhập kho trong 1 bước, không để lại phiếu nháp.
                    int reqId = Integer.parseInt(httpReq.getParameter("request_id"));
                    Request req = requestService.getById(reqId);
                    if (req == null || req.getCancelRequestedAt() != null
                            || !(Request.STATUS_APPROVED.equals(req.getStatus())
                                || Request.STATUS_PARTIALLY_COMPLETED.equals(req.getStatus()))) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&error=RequestNotApproved");
                        return;
                    }
                    if (loggedInUser.getWarehouseId() != null) {
                        model.Stocktake active = new service.StocktakeService().getActiveStocktakeForWarehouse(loggedInUser.getWarehouseId());
                        if (active != null) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list"
                                    + "&error=WarehouseFrozen&stk=" + active.getStocktakeCode());
                            return;
                        }
                    }
                    if (loggedInUser.getWarehouseId() == null) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=RequiresWarehouseAssignment");
                        return;
                    }
                    if (loggedInUser.getWarehouseId() != req.getWarehouseId()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=WrongWarehouse");
                        return;
                    }

                    boolean isTransfer = Request.REASON_TRANSFER.equals(req.getReason());
                    boolean isReturn = Request.REASON_RETURN.equals(req.getReason());
                    boolean isPurchase = Request.REASON_PURCHASE.equals(req.getReason());

                    String[] productIds = httpReq.getParameterValues("product_id");
                    String[] quantities = httpReq.getParameterValues("quantity");
                    String[] unitPrices = httpReq.getParameterValues("unit_price");
                    if (productIds == null || productIds.length == 0) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=NoItems");
                        return;
                    }
                    List<TicketDetail> details = new ArrayList<>();
                    for (int i = 0; i < productIds.length; i++) {
                        int qty = Integer.parseInt(quantities[i]);
                        if (qty <= 0) continue;
                        // Giá: chỉ BẮT BUỘC > 0 với nhập MUA (PURCHASE). Chuyển kho/Trả hàng không cần giá.
                        java.math.BigDecimal price = java.math.BigDecimal.ZERO;
                        if (unitPrices != null && i < unitPrices.length && unitPrices[i] != null && !unitPrices[i].trim().isEmpty()) {
                            price = new java.math.BigDecimal(unitPrices[i].trim());
                        }
                        if (isPurchase && price.compareTo(java.math.BigDecimal.ZERO) <= 0) {
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=InvalidPrice");
                            return;
                        }
                        TicketDetail d = new TicketDetail();
                        d.setProductId(Integer.parseInt(productIds[i]));
                        d.setQuantity(qty);
                        d.setUnitCost(price);
                        details.add(d);
                    }
                    if (details.isEmpty()) {
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id=" + reqId + "&error=NoItemsReceived");
                        return;
                    }

                    // RETURN/TRANSFER: serial được xác định từ hàng đã xuất / đang trên đường (không cần quét ở đây,
                    // DAO tự lấy). Ở đây chỉ truyền serial nếu người dùng có nhập tay cho RETURN.
                    String[] scanned = httpReq.getParameterValues("scanned_serials");
                    List<String> serials = null;
                    if (scanned != null && scanned.length > 0) {
                        serials = new ArrayList<>();
                        for (String s : scanned) if (s != null && !s.trim().isEmpty()) serials.add(s.trim());
                    }

                    // PURCHASE: (tùy chọn) đính kèm file Excel serial nhà sản xuất — parse ngay tại đây.
                    Map<Integer, List<String>> mfrSerials = null;
                    if (isPurchase) {
                        Map<Integer, Integer> expectedByProductId = new LinkedHashMap<>();
                        Map<String, Integer> expectedBySku = new LinkedHashMap<>();
                        Map<String, Integer> productIdBySku = new LinkedHashMap<>();
                        List<String> serialErrors = new ArrayList<>();
                        ProductService pService = new ProductService();
                        for (TicketDetail d : details) {
                            Product p = pService.getProductById(d.getProductId(), req.getWarehouseId());
                            if (p == null) {
                                serialErrors.add("Không tìm thấy sản phẩm #" + d.getProductId() + ".");
                                continue;
                            }
                            expectedByProductId.put(d.getProductId(), d.getQuantity());
                            expectedBySku.put(p.getSku(), d.getQuantity());
                            productIdBySku.put(p.getSku(), d.getProductId());
                        }

                        Part filePart = null;
                        try { filePart = httpReq.getPart("excelFile"); } catch (Exception ignore) {}
                        String captureMode = httpReq.getParameter("serial_capture_mode");
                        if (captureMode == null || captureMode.trim().isEmpty()) {
                            captureMode = filePart != null && filePart.getSize() > 0 ? "EXCEL" : "SCAN";
                        }

                        if ("EXCEL".equalsIgnoreCase(captureMode)) {
                            if (filePart == null || filePart.getSize() == 0) {
                                serialErrors.add("Bạn chưa chọn file Excel serial nhà sản xuất.");
                            } else {
                            ManufacturerSerialExcelService excelService = new ManufacturerSerialExcelService();
                            ManufacturerSerialExcelService.ParseResult result;
                            try (InputStream is = filePart.getInputStream()) {
                                    result = excelService.parseAndValidate(is, expectedBySku, productIdBySku);
                            }
                            if (!result.isValid()) {
                                    serialErrors.addAll(result.getErrors());
                                } else {
                                    mfrSerials = result.getSerialsByProductId();
                                }
                            }
                        } else if ("SCAN".equalsIgnoreCase(captureMode)) {
                            mfrSerials = parseScannedManufacturerSerials(httpReq, expectedByProductId, serialErrors);
                        } else {
                            serialErrors.add("Cách nhập serial nhà sản xuất không hợp lệ.");
                        }

                        if (!serialErrors.isEmpty()) {
                            session.setAttribute("importSerialErrors", serialErrors);
                            String errorCode = "EXCEL".equalsIgnoreCase(captureMode)
                                    ? "InvalidSerialFile" : "InvalidManufacturerSerial";
                            response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id="
                                    + reqId + "&error=" + errorCode);
                            return;
                        }
                    }

                    Ticket ticket = new Ticket();
                    ticket.setType(Ticket.TYPE_IN);
                    ticket.setRequestId(reqId);
                    ticket.setWarehouseId(loggedInUser.getWarehouseId());
                    ticket.setKeeperId(loggedInUser.getId());
                    boolean ok = ticketService.addAndConfirm(ticket, details, serials, loggedInUser.getId(), mfrSerials);
                    if (!ok) {
                        String errorCode = ticketService.getLastErrorCode();
                        if (errorCode == null || errorCode.trim().isEmpty()) errorCode = "ReceiveFailed";
                        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=add&request_id="
                                + reqId + "&error=" + errorCode);
                        return;
                    }
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(httpReq.getContextPath() + "/warehouse/import-ticket?action=list");
    }

    private Map<Integer, List<String>> parseScannedManufacturerSerials(HttpServletRequest request,
            Map<Integer, Integer> expectedByProductId, List<String> errors) {
        Map<Integer, List<String>> result = new LinkedHashMap<>();
        for (Integer productId : expectedByProductId.keySet()) {
            result.put(productId, new ArrayList<>());
        }

        String[] productIds = request.getParameterValues("manufacturer_product_id");
        String[] serials = request.getParameterValues("manufacturer_serial");
        if (productIds == null || serials == null || productIds.length != serials.length) {
            errors.add("Danh sách serial quét không đầy đủ.");
            return result;
        }

        Map<Integer, Set<String>> seenByProduct = new LinkedHashMap<>();
        for (int i = 0; i < productIds.length; i++) {
            int productId;
            try {
                productId = Integer.parseInt(productIds[i]);
            } catch (Exception e) {
                errors.add("Có serial được gửi lên nhưng không xác định được sản phẩm.");
                continue;
            }
            if (!expectedByProductId.containsKey(productId)) {
                errors.add("Serial được gắn với sản phẩm không có trong phiếu nhập.");
                continue;
            }

            String serial = serials[i] == null ? "" : serials[i].trim();
            if (!isValidManufacturerSerial(serial)) {
                errors.add("Serial nhà sản xuất trống, quá 100 ký tự hoặc chứa ký tự không hợp lệ.");
                continue;
            }
            Set<String> seen = seenByProduct.computeIfAbsent(productId, ignored -> new HashSet<>());
            if (!seen.add(serial.toLowerCase(Locale.ROOT))) {
                errors.add("Serial '" + serial + "' đã được quét hai lần cho cùng một sản phẩm.");
                continue;
            }
            result.get(productId).add(serial);
        }

        for (Map.Entry<Integer, Integer> entry : expectedByProductId.entrySet()) {
            int actual = result.get(entry.getKey()).size();
            if (actual != entry.getValue()) {
                errors.add("Sản phẩm #" + entry.getKey() + ": cần " + entry.getValue()
                        + " serial nhưng đã nhận " + actual + ".");
            }
        }
        return result;
    }

    private void downloadManufacturerSerialTemplate(HttpServletRequest request, HttpServletResponse response,
            User loggedInUser, RequestService requestService) throws IOException {
        String requestIdParam = request.getParameter("request_id");
        if (requestIdParam == null || requestIdParam.trim().isEmpty()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Thiếu yêu cầu nhập.");
            return;
        }

        int requestId;
        try {
            requestId = Integer.parseInt(requestIdParam);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Yêu cầu nhập không hợp lệ.");
            return;
        }

        Request importRequest = requestService.getById(requestId);
        if (importRequest == null
                || !Request.REASON_PURCHASE.equals(importRequest.getReason())
                || !(Request.STATUS_APPROVED.equals(importRequest.getStatus())
                    || Request.STATUS_PARTIALLY_COMPLETED.equals(importRequest.getStatus()))
                || importRequest.getCancelRequestedAt() != null
                || loggedInUser.getWarehouseId() == null
                || loggedInUser.getWarehouseId() != importRequest.getWarehouseId()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Không thể tạo mẫu cho yêu cầu nhập này.");
            return;
        }

        String[] productIds = request.getParameterValues("product_id");
        String[] quantities = request.getParameterValues("quantity");
        Map<Integer, Integer> quantitiesByProduct = new LinkedHashMap<>();
        Map<Integer, Integer> remainingByProduct = new LinkedHashMap<>();
        Map<Integer, String> skuByProduct = new LinkedHashMap<>();

        for (model.RequestDetail detail : importRequest.getDetails()) {
            int remaining = Math.max(0, detail.getQuantity() - detail.getProcessedQuantity());
            remainingByProduct.put(detail.getProductId(), remaining);
            skuByProduct.put(detail.getProductId(), detail.getSku());
        }

        if (productIds != null && quantities != null && productIds.length == quantities.length) {
            for (int i = 0; i < productIds.length; i++) {
                try {
                    int productId = Integer.parseInt(productIds[i]);
                    int quantity = Integer.parseInt(quantities[i]);
                    int remaining = remainingByProduct.getOrDefault(productId, -1);
                    if (quantity < 0 || remaining < 0 || quantity > remaining) {
                        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Số lượng nhận không hợp lệ.");
                        return;
                    }
                    quantitiesByProduct.put(productId, quantity);
                } catch (NumberFormatException e) {
                    response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Dữ liệu sản phẩm không hợp lệ.");
                    return;
                }
            }
        } else {
            quantitiesByProduct.putAll(remainingByProduct);
        }

        int totalRows = 0;
        for (int quantity : quantitiesByProduct.values()) totalRows += quantity;
        if (totalRows <= 0) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Cần chọn ít nhất một sản phẩm để tạo mẫu.");
            return;
        }

        String requestCode = importRequest.getRequestCode().replaceAll("[^A-Za-z0-9_-]", "_");
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename=\"mau-serial-" + requestCode + ".xlsx\"");

        try (XSSFWorkbook workbook = new XSSFWorkbook(); OutputStream output = response.getOutputStream()) {
            Sheet sheet = workbook.createSheet("Serial NSX");
            CellStyle headerStyle = workbook.createCellStyle();
            headerStyle.setFillForegroundColor(IndexedColors.LIGHT_CORNFLOWER_BLUE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            CellStyle serialStyle = workbook.createCellStyle();
            serialStyle.setDataFormat(workbook.createDataFormat().getFormat("@"));

            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("sku");
            header.createCell(1).setCellValue("manufacturer_serial");
            header.getCell(0).setCellStyle(headerStyle);
            header.getCell(1).setCellStyle(headerStyle);

            int rowIndex = 1;
            for (Map.Entry<Integer, Integer> entry : quantitiesByProduct.entrySet()) {
                String sku = skuByProduct.get(entry.getKey());
                for (int i = 0; i < entry.getValue(); i++) {
                    Row row = sheet.createRow(rowIndex++);
                    row.createCell(0).setCellValue(sku == null ? "" : sku);
                    Cell serialCell = row.createCell(1);
                    serialCell.setCellStyle(serialStyle);
                    serialCell.setCellValue("");
                }
            }
            sheet.createFreezePane(0, 1);
            sheet.setColumnWidth(0, 24 * 256);
            sheet.setColumnWidth(1, 40 * 256);
            workbook.write(output);
        }
    }

    private boolean isValidManufacturerSerial(String serial) {
        if (serial == null || serial.isEmpty() || serial.length() > 100) return false;
        for (int i = 0; i < serial.length(); i++) {
            if (Character.isISOControl(serial.charAt(i))) return false;
        }
        return true;
    }
}
