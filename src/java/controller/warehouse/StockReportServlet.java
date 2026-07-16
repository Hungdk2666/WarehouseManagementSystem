package controller.warehouse;

import java.io.IOException;
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
        boolean includeZero = "1".equals(req.getParameter("includeZero"));

        Integer filterWh = parseIntegerOrNull(req.getParameter("warehouseId"));
        // Nhân viên bị gán 1 kho và không có quyền xem tất cả -> ép về kho của họ
        Integer userWh = user.getWarehouseId();
        boolean canViewAll = user.hasPermission("INVENTORY_VIEW_ALL");
        if (userWh != null && !canViewAll) {
            filterWh = userWh;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        if ("export".equals(action)) {
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
        List<StockSnapshotRow> rows = service.getSnapshot(date, filterWh, search, includeZero);
        List<Warehouse> warehouses = new WarehouseService().getAllWarehouses();

        req.setAttribute("rows", rows);
        req.setAttribute("warehouses", warehouses);
        req.setAttribute("date", date);
        req.setAttribute("search", search);
        req.setAttribute("warehouseId", filterWh);
        req.setAttribute("includeZero", includeZero);
        req.setAttribute("userBoundToWarehouse", userWh != null && !canViewAll);

        req.getRequestDispatcher("/report/stock-report.jsp").forward(req, resp);
    }

    private Integer parseIntegerOrNull(String v) {
        if (v == null || v.isEmpty()) return null;
        try { return Integer.parseInt(v); } catch (Exception e) { return null; }
    }
}
