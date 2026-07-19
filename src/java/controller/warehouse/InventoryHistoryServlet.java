package controller.warehouse;

import service.InventoryHistoryService;
import service.WarehouseService;
import service.InventoryHistoryExcelService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.HistoryEntry;
import model.User;
import model.Warehouse;

@WebServlet(name = "InventoryHistoryServlet", urlPatterns = {"/warehouse/inventory-history"})
public class InventoryHistoryServlet extends HttpServlet {

    private static final int DEFAULT_PAGE_SIZE = 10;

    @Override
    protected void doGet(HttpServletRequest httpReq, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = httpReq.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        if (loggedInUser == null) {
            response.sendRedirect(httpReq.getContextPath() + "/login");
            return;
        }
        if (!loggedInUser.hasPermission("STOCK_LEDGER_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem lịch sử kho.");
            return;
        }

        String action = httpReq.getParameter("action");
        if (action == null) action = "list";

        String search = httpReq.getParameter("search");
        String transactionType = httpReq.getParameter("transactionType");
        String warehouseIdStr = httpReq.getParameter("warehouseId");
        String startDate = httpReq.getParameter("startDate");
        String endDate = httpReq.getParameter("endDate");

        Integer warehouseId = null;
        if (warehouseIdStr != null && !warehouseIdStr.trim().isEmpty()) {
            try { warehouseId = Integer.parseInt(warehouseIdStr); } catch (NumberFormatException ignored) {}
        }

        InventoryHistoryService historyService = new InventoryHistoryService();

        if ("export".equals(action)) {
            List<HistoryEntry> allData = historyService.getHistoryForExport(
                    search, transactionType, warehouseId, startDate, endDate);

            String fileName = "lich-su-bien-dong-kho";
            if (startDate != null && !startDate.isEmpty()) fileName += "_" + startDate;
            if (endDate != null && !endDate.isEmpty()) fileName += "_" + endDate;
            fileName += ".xlsx";

            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");

            try {
                new InventoryHistoryExcelService().export(allData, response.getOutputStream());
            } catch (Exception e) {
                e.printStackTrace();
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi xuất Excel.");
            }
            return;
        }

        int page = 1;
        String pageStr = httpReq.getParameter("page");
        if (pageStr != null) {
            try { page = Math.max(1, Integer.parseInt(pageStr)); } catch (NumberFormatException ignored) {}
        }

        int pageSize = DEFAULT_PAGE_SIZE;
        String pageSizeStr = httpReq.getParameter("pageSize");
        if (pageSizeStr != null && !pageSizeStr.trim().isEmpty()) {
            try {
                pageSize = Integer.parseInt(pageSizeStr.trim());
            } catch (NumberFormatException ignored) {
                pageSize = DEFAULT_PAGE_SIZE;
            }
        }
        if (pageSize != 10 && pageSize != 25 && pageSize != 100) {
            pageSize = DEFAULT_PAGE_SIZE;
        }

        int totalCount = historyService.getCount(
                search, transactionType, warehouseId, startDate, endDate);
        int totalPages = (int) Math.ceil((double) totalCount / pageSize);
        if (totalPages == 0) {
            totalPages = 1;
        }
        if (page > totalPages) {
            page = totalPages;
        }

        List<HistoryEntry> entries = historyService.getHistory(
                search, transactionType, warehouseId, startDate, endDate, page, pageSize);

        List<Warehouse> warehouses = new WarehouseService().getAllWarehouses();

        httpReq.setAttribute("entries", entries);
        httpReq.setAttribute("warehouses", warehouses);
        httpReq.setAttribute("currentPage", page);
        httpReq.setAttribute("totalPages", totalPages);
        httpReq.setAttribute("totalCount", totalCount);
        httpReq.setAttribute("pageSize", pageSize);
        httpReq.setAttribute("search", search);
        httpReq.setAttribute("transactionType", transactionType);
        httpReq.setAttribute("warehouseId", warehouseId);
        httpReq.setAttribute("startDate", startDate);
        httpReq.setAttribute("endDate", endDate);

        httpReq.getRequestDispatcher("/inventory/history.jsp").forward(httpReq, response);
    }
}
