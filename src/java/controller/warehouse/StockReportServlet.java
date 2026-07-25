package controller.warehouse;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.StockSnapshotRow;
import model.User;
import model.Warehouse;
import service.StockSnapshotService;
import service.StockSnapshotExcelService;
import service.WarehouseService;

/**
 * Báo cáo tồn kho theo ngày: chọn 1 ngày -> xem tồn của từng sản phẩm tại ngày đó.
 * Tái dựng từ Product_Ledger (xem StockSnapshotDAO). Có 2 action: list và export (Excel).
 */
@WebServlet(name = "StockReportServlet", urlPatterns = {"/warehouse/stock-report"})
public class StockReportServlet extends HttpServlet {

    private final StockSnapshotService service = new StockSnapshotService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        if (!user.hasPermission("STOCK_LEDGER_VIEW")) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem báo cáo tồn kho.");
            return;
        }

        // Đọc bộ lọc
        String date = req.getParameter("date");
        String search = req.getParameter("search");
        if (date != null) date = date.trim();
        boolean includeZero = "1".equals(req.getParameter("includeZero"));

        String warehouseParam = req.getParameter("warehouseId");
        Integer filterWh = parseIntegerOrNull(warehouseParam);
        // Nhân viên bị gán 1 kho và không có quyền xem tất cả -> ép về kho của họ
        Integer userWh = user.getWarehouseId();
        boolean canViewAll = user.hasPermission("INVENTORY_VIEW_ALL");
        if (userWh != null && !canViewAll) {
            filterWh = userWh;
        }

        String action = req.getParameter("action");
        String reportError = null;
        if (warehouseParam != null && !warehouseParam.trim().isEmpty() && filterWh == null) {
            reportError = "Kho không hợp lệ.";
        }
        if (reportError == null && date != null && !date.trim().isEmpty() && parseDate(date) == null) {
            reportError = "Ngày không hợp lệ. Vui lòng chọn ngày theo định dạng YYYY-MM-DD.";
        }
        boolean validDate = reportError == null;
        if (action == null) action = "list";

        if ("export".equals(action)) {
            if (!validDate) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, reportError);
                return;
            }
            List<StockSnapshotRow> data = service.getSnapshot(date, filterWh, search, includeZero);

            String fileName = "bao-cao-ton-kho";
            if (date != null && !date.isEmpty()) fileName += "_" + date;
            fileName += ".xlsx";

            resp.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            resp.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");

            try {
                new StockSnapshotExcelService().export(data, date, resp.getOutputStream());
            } catch (Exception e) {
                e.printStackTrace();
                resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi xuất Excel.");
            }
            return;
        }

        // action list
        List<StockSnapshotRow> rows = validDate
                ? service.getSnapshot(date, filterWh, search, includeZero)
                : java.util.Collections.emptyList();
        List<Warehouse> warehouses = new WarehouseService().getAllWarehouses();

        if (!validDate) rows = java.util.Collections.emptyList();
        req.setAttribute("rows", rows);
        req.setAttribute("warehouses", warehouses);
        req.setAttribute("date", date);
        req.setAttribute("search", search);
        req.setAttribute("warehouseId", filterWh);
        req.setAttribute("includeZero", includeZero);
        req.setAttribute("userBoundToWarehouse", userWh != null && !canViewAll);
        req.setAttribute("reportError", reportError);

        req.getRequestDispatcher("/report/stock-report.jsp").forward(req, resp);
    }

    private LocalDate parseDate(String value) {
        if (value == null || value.trim().isEmpty()) return null;
        try { return LocalDate.parse(value.trim()); }
        catch (DateTimeParseException e) { return null; }
    }

    private Integer parseIntegerOrNull(String v) {
        if (v == null || v.isEmpty()) return null;
        try { return Integer.parseInt(v); } catch (Exception e) { return null; }
    }
}
