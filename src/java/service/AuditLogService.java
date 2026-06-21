package service;

import dao.AuditLogDAO;
import java.util.List;
import model.*;

public class AuditLogService {
    private AuditLogDAO dao;

    public AuditLogService() {
        this.dao = new AuditLogDAO();
    }

    public List<String> getAllUniqueActions() {
        return dao.getAllUniqueActions();
    }

    public List<AuditLog> getLogs(String arg0, String arg1, String arg2, String arg3, int arg4, int arg5) {
        return dao.getLogs(arg0, arg1, arg2, arg3, arg4, arg5);
    }

    public int getLogsCount(String arg0, String arg1, String arg2, String arg3) {
        return dao.getLogsCount(arg0, arg1, arg2, arg3);
    }

    public void log(Integer arg0, String arg1, String arg2) {
        dao.log(arg0, arg1, arg2);
    }

}
