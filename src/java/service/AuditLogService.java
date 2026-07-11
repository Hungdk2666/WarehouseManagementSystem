package service;

import dao.AuditLogDAO;
import java.util.List;
import model.*;

public class AuditLogService {
    private AuditLogDAO dao;

    public AuditLogService() {
        this.dao = new AuditLogDAO();
    }

    public List<String> getAllUniqueActions(String category) {
        return dao.getAllUniqueActions(category);
    }

    public List<AuditLog> getLogs(String category, String search, String[] actionFilters, String startDate, String endDate, int page, int pageSize) {
        return dao.getLogs(category, search, actionFilters, startDate, endDate, page, pageSize);
    }

    public int getLogsCount(String category, String search, String[] actionFilters, String startDate, String endDate) {
        return dao.getLogsCount(category, search, actionFilters, startDate, endDate);
    }

    public void log(Integer arg0, String arg1, String arg2) {
        dao.log(arg0, arg1, arg2);
    }

}
