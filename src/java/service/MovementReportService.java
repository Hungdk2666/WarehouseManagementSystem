package service;

import dao.MovementReportDAO;
import dao.TicketReportDAO;
import java.util.List;
import model.DailyMovementRow;
import model.PeriodSummaryRow;
import model.TicketReportRow;

/**
 * Lớp trung gian mỏng cho 2 báo cáo xuất-nhập theo mẫu giấy: chi tiết theo ngày và tổng hợp theo kỳ.
 */
public class MovementReportService {

    private final MovementReportDAO dao = new MovementReportDAO();
    private final TicketReportDAO ticketReportDao = new TicketReportDAO();

    public List<DailyMovementRow> getDailyMovement(String fromDate, String toDate,
            Integer warehouseId, String search) {
        return dao.getDailyMovement(fromDate, toDate, warehouseId, search);
    }

    public List<PeriodSummaryRow> getPeriodSummary(String fromDate, String toDate,
            Integer warehouseId, String search, boolean includeZero) {
        return dao.getPeriodSummary(fromDate, toDate, warehouseId, search, includeZero);
    }

    public List<TicketReportRow> getTicketReport(String ticketType, String fromDate, String toDate,
            Integer warehouseId, String search) {
        return ticketReportDao.getRows(ticketType, fromDate, toDate, warehouseId, search);
    }
}
