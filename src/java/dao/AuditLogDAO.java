package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import model.AuditLog;
import utils.DBUtils;

public class AuditLogDAO {

    public void log(Integer userId, String action, String details) {
        String query = "INSERT INTO Audit_Logs (user_id, action, details) VALUES (?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            if (userId != null) {
                ps.setInt(1, userId);
            } else {
                ps.setNull(1, java.sql.Types.INTEGER);
            }
            ps.setString(2, action);
            ps.setString(3, details);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public List<AuditLog> getLogs(String search, String[] actionFilters, String startDate, String endDate, int page, int pageSize) {
        List<AuditLog> list = new ArrayList<>();
        List<String> validActions = filterNonEmpty(actionFilters);
        StringBuilder sb = new StringBuilder(
            "SELECT l.*, u.username, u.full_name AS user_fullname " +
            "FROM Audit_Logs l " +
            "LEFT JOIN Users u ON l.user_id = u.id " +
            "WHERE 1=1 "
        );

        if (search != null && !search.trim().isEmpty()) {
            sb.append("AND (u.username LIKE ? OR u.full_name LIKE ? OR l.details LIKE ?) ");
        }
        if (!validActions.isEmpty()) {
            sb.append("AND l.action IN (");
            for (int i = 0; i < validActions.size(); i++) sb.append(i == 0 ? "?" : ",?");
            sb.append(") ");
        }
        if (startDate != null && !startDate.trim().isEmpty()) {
            sb.append("AND l.created_at >= ? ");
        }
        if (endDate != null && !endDate.trim().isEmpty()) {
            sb.append("AND l.created_at <= ? ");
        }

        sb.append("ORDER BY l.created_at DESC LIMIT ? OFFSET ?");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {

            int paramIndex = 1;
            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim() + "%";
                ps.setString(paramIndex++, searchPattern);
                ps.setString(paramIndex++, searchPattern);
                ps.setString(paramIndex++, searchPattern);
            }
            for (String a : validActions) ps.setString(paramIndex++, a);
            if (startDate != null && !startDate.trim().isEmpty()) {
                ps.setString(paramIndex++, startDate.trim() + " 00:00:00");
            }
            if (endDate != null && !endDate.trim().isEmpty()) {
                ps.setString(paramIndex++, endDate.trim() + " 23:59:59");
            }

            ps.setInt(paramIndex++, pageSize);
            ps.setInt(paramIndex++, (page - 1) * pageSize);
            
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    AuditLog log = new AuditLog();
                    log.setId(rs.getInt("id"));
                    log.setUserId((Integer) rs.getObject("user_id"));
                    log.setUsername(rs.getString("username"));
                    log.setUserFullName(rs.getString("user_fullname"));
                    log.setAction(rs.getString("action"));
                    log.setCreatedAt(rs.getTimestamp("created_at"));
                    log.setDetails(rs.getString("details"));
                    list.add(log);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public int getLogsCount(String search, String[] actionFilters, String startDate, String endDate) {
        List<String> validActions = filterNonEmpty(actionFilters);
        StringBuilder sb = new StringBuilder(
            "SELECT COUNT(*) " +
            "FROM Audit_Logs l " +
            "LEFT JOIN Users u ON l.user_id = u.id " +
            "WHERE 1=1 "
        );

        if (search != null && !search.trim().isEmpty()) {
            sb.append("AND (u.username LIKE ? OR u.full_name LIKE ? OR l.details LIKE ?) ");
        }
        if (!validActions.isEmpty()) {
            sb.append("AND l.action IN (");
            for (int i = 0; i < validActions.size(); i++) sb.append(i == 0 ? "?" : ",?");
            sb.append(") ");
        }
        if (startDate != null && !startDate.trim().isEmpty()) {
            sb.append("AND l.created_at >= ? ");
        }
        if (endDate != null && !endDate.trim().isEmpty()) {
            sb.append("AND l.created_at <= ? ");
        }

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sb.toString())) {

            int paramIndex = 1;
            if (search != null && !search.trim().isEmpty()) {
                String searchPattern = "%" + search.trim() + "%";
                ps.setString(paramIndex++, searchPattern);
                ps.setString(paramIndex++, searchPattern);
                ps.setString(paramIndex++, searchPattern);
            }
            for (String a : validActions) ps.setString(paramIndex++, a);
            if (startDate != null && !startDate.trim().isEmpty()) {
                ps.setString(paramIndex++, startDate.trim() + " 00:00:00");
            }
            if (endDate != null && !endDate.trim().isEmpty()) {
                ps.setString(paramIndex++, endDate.trim() + " 23:59:59");
            }
            
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    private List<String> filterNonEmpty(String[] arr) {
        List<String> result = new ArrayList<>();
        if (arr != null) for (String s : arr) if (s != null && !s.trim().isEmpty()) result.add(s.trim());
        return result;
    }

    public List<String> getAllUniqueActions() {
        List<String> actions = new ArrayList<>();
        String query = "SELECT DISTINCT action FROM Audit_Logs ORDER BY action ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                actions.add(rs.getString("action"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return actions;
    }
}
