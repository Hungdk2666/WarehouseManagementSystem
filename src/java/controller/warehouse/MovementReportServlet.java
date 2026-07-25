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
import model.DailyMovementRow;
import model.PeriodSummaryRow;
import model.TicketReportRow;
import model.User;
import model.Warehouse;
import service.MovementReportExcelService;
import service.MovementReportService;
import service.TicketReportExcelService;
import service.WarehouseService;

/**
 * 2 báo cáo theo mẫu giấy của giảng viên, chọn qua tham số "type":
 *  - type=daily  : Báo cáo chi tiết xuất - nhập vật tư theo ngày (khoảng ngày)
 *  - type=period : Báo cáo tổng hợp Nhập - Xuất - Tồn (đầu kỳ/trong kỳ/cuối kỳ)
 * action=export xuất Excel, mặc định hiển thị màn hình.
 */
@WebServlet(name = "MovementReportServlet", urlPatterns = {"/warehouse/movement-report"})
public class MovementReportServlet extends HttpServlet {

    private final MovementReportService service = new MovementReportService();

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
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền xem báo cáo xuất nhập kho.");
            return;
        }

        String type = req.getParameter("type");
        if (type == null || (!type.equals("daily") && !type.equals("period")
                && !type.equals("import") && !type.equals("export"))) type = "daily";

        String fromDate = req.getParameter("fromDate");
        String toDate = req.getParameter("toDate");
        if (fromDate != null) fromDate = fromDate.trim();
        if (toDate != null) toDate = toDate.trim();
        String search = req.getParameter("search");
        boolean includeZero = "1".equals(req.getParameter("includeZero"));

        String warehouseParam = req.getParameter("warehouseId");
        Integer filterWh = parseIntegerOrNull(warehouseParam);
        Integer userWh = user.getWarehouseId();
        boolean canViewAll = user.hasPermission("INVENTORY_VIEW_ALL");
        if (userWh != null && !canViewAll) {
            filterWh = userWh;
        }

        String action = req.getParameter("action");
        boolean hasRange = fromDate != null && !fromDate.trim().isEmpty()
                && toDate != null && !toDate.trim().isEmpty();
        String reportError = null;
        if (warehouseParam != null && !warehouseParam.trim().isEmpty() && filterWh == null) {
            reportError = "Kho không hợp lệ.";
        }
        LocalDate parsedFrom = parseDate(fromDate);
        LocalDate parsedTo = parseDate(toDate);
        if (reportError == null && hasRange && (parsedFrom == null || parsedTo == null)) {
            reportError = "Ngày không hợp lệ. Vui lòng chọn ngày theo định dạng YYYY-MM-DD.";
        } else if (reportError == null && hasRange && parsedFrom.isAfter(parsedTo)) {
            reportError = "Ngày bắt đầu không được sau ngày kết thúc.";
        }
        boolean validRange = hasRange && reportError == null;

        if ("export".equals(action)) {
            if (!validRange) {
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "Vui lòng chọn khoảng ngày trước khi xuất Excel.");
                return;
            }
            String filePrefix = "period".equals(type) ? "bao-cao-tong-hop-nxt_"
                    : ("import".equals(type) ? "bao-cao-nhap-hang_"
                    : ("export".equals(type) ? "bao-cao-xuat-kho_" : "bao-cao-chi-tiet-xnk_"));
            String fileName = filePrefix + fromDate + "_" + toDate + ".xlsx";
            resp.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            resp.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");
            try {
                if ("period".equals(type)) {
                    MovementReportExcelService excel = new MovementReportExcelService();
                    List<PeriodSummaryRow> data = service.getPeriodSummary(fromDate, toDate, filterWh, search, includeZero);
                    excel.exportPeriod(data, fromDate, toDate, resp.getOutputStream());
                } else if ("daily".equals(type)) {
                    MovementReportExcelService excel = new MovementReportExcelService();
                    List<DailyMovementRow> data = service.getDailyMovement(fromDate, toDate, filterWh, search);
                    excel.exportDaily(data, fromDate, toDate, resp.getOutputStream());
                } else {
                    List<TicketReportRow> data = service.getTicketReport("import".equals(type) ? "IN" : "OUT",
                            fromDate, toDate, filterWh, search);
                    TicketReportExcelService excel = new TicketReportExcelService();
                    if ("import".equals(type)) excel.exportImport(data, fromDate, toDate, resp.getOutputStream());
                    else excel.exportExport(data, fromDate, toDate, resp.getOutputStream());
                }
            } catch (Exception e) {
                e.printStackTrace();
                resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Lỗi xuất Excel.");
            }
            return;
        }

        List<Warehouse> warehouses = new WarehouseService().getAllWarehouses();
        req.setAttribute("warehouses", warehouses);
        req.setAttribute("fromDate", fromDate);
        req.setAttribute("toDate", toDate);
        req.setAttribute("search", search);
        req.setAttribute("warehouseId", filterWh);
        req.setAttribute("includeZero", includeZero);
        req.setAttribute("userBoundToWarehouse", userWh != null && !canViewAll);
        req.setAttribute("reportError", reportError);
        req.setAttribute("type", type);

        if ("period".equals(type)) {
            List<PeriodSummaryRow> rows = validRange
                    ? service.getPeriodSummary(fromDate, toDate, filterWh, search, includeZero)
                    : java.util.Collections.emptyList();
            req.setAttribute("periodRows", rows);
            req.getRequestDispatcher("/report/period-summary-report.jsp").forward(req, resp);
        } else if ("import".equals(type) || "export".equals(type)) {
            boolean importReport = "import".equals(type);
            List<TicketReportRow> rows = validRange
                    ? service.getTicketReport(importReport ? "IN" : "OUT", fromDate, toDate, filterWh, search)
                    : java.util.Collections.emptyList();
            req.setAttribute("ticketRows", rows);
            req.setAttribute("ticketReportType", type);
            req.getRequestDispatcher("/report/ticket-report.jsp").forward(req, resp);
        } else {
            List<DailyMovementRow> rows = validRange
                    ? service.getDailyMovement(fromDate, toDate, filterWh, search)
                    : java.util.Collections.emptyList();
            req.setAttribute("dailyRows", rows);
            req.getRequestDispatcher("/report/daily-movement-report.jsp").forward(req, resp);
        }
    }


    private LocalDate parseDate(String value) {
        if (value == null || value.trim().isEmpty()) return null;
        try {
            return LocalDate.parse(value.trim());
        } catch (DateTimeParseException e) {
            return null;
        }
    }
    private Integer parseIntegerOrNull(String v) {
        if (v == null || v.isEmpty()) return null;
        try { return Integer.parseInt(v); } catch (Exception e) { return null; }
    }
}
