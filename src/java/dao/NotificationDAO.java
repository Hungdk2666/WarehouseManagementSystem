package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import model.Notification;
import utils.DBUtils;

public class NotificationDAO {

    /**
     * Create a notification for a specific user using an active connection.
     * This ensures the operation is part of the parent transaction.
     */
    public void createNotification(int userId, String title, String message, String link, Connection conn) throws Exception {
        String query = "INSERT INTO Notifications (user_id, title, message, link) VALUES (?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setString(2, title);
            ps.setString(3, message);
            ps.setString(4, link);
            ps.executeUpdate();
        }
    }

    /**
     * Create a notification for all users of a specific role using an active connection.
     * Useful for broadcasting alerts (e.g. notify all Business Admins or all Warehouse Staff).
     */
    /**
     * Notify all active users assigned to a specific warehouse.
     * Used when an incoming transfer ticket arrives (IN_TRANSIT).
     */
    public void createNotificationForWarehouse(int warehouseId, String title, String message, String link, Connection conn) throws Exception {
        List<Integer> userIds = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM Users WHERE warehouse_id = ? AND status = TRUE")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) userIds.add(rs.getInt("id"));
            }
        }
        if (!userIds.isEmpty()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Notifications (user_id, title, message, link) VALUES (?, ?, ?, ?)")) {
                for (int uid : userIds) {
                    ps.setInt(1, uid); ps.setString(2, title);
                    ps.setString(3, message); ps.setString(4, link);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
        }
    }

    /**
     * Thông báo cho user vừa THUỘC kho vừa CÓ vai trò chỉ định (đang hoạt động).
     * Dùng cho nghiệp vụ nhắm đúng người của đúng kho (vd: thủ kho/quản lý của kho đang kiểm kê),
     * tránh gửi lan sang nhân viên kho khác.
     */
    public void createNotificationForWarehouseRole(int warehouseId, int roleId, String title, String message, String link, Connection conn) throws Exception {
        List<Integer> userIds = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM Users WHERE warehouse_id = ? AND role_id = ? AND status = TRUE")) {
            ps.setInt(1, warehouseId);
            ps.setInt(2, roleId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) userIds.add(rs.getInt("id"));
            }
        }
        if (!userIds.isEmpty()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Notifications (user_id, title, message, link) VALUES (?, ?, ?, ?)")) {
                for (int uid : userIds) {
                    ps.setInt(1, uid); ps.setString(2, title);
                    ps.setString(3, message); ps.setString(4, link);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
        }
    }

    public void createNotificationForRole(int roleId, String title, String message, String link, Connection conn) throws Exception {
        String queryUsers = "SELECT id FROM Users WHERE role_id = ? AND status = TRUE";
        List<Integer> userIds = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(queryUsers)) {
            ps.setInt(1, roleId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    userIds.add(rs.getInt("id"));
                }
            }
        }

        if (!userIds.isEmpty()) {
            String queryInsert = "INSERT INTO Notifications (user_id, title, message, link) VALUES (?, ?, ?, ?)";
            try (PreparedStatement psInsert = conn.prepareStatement(queryInsert)) {
                for (int uId : userIds) {
                    psInsert.setInt(1, uId);
                    psInsert.setString(2, title);
                    psInsert.setString(3, message);
                    psInsert.setString(4, link);
                    psInsert.addBatch();
                }
                psInsert.executeBatch();
            }
        }
    }

    public List<Notification> getRecentNotifications(int userId, int limit) {
        List<Notification> list = new ArrayList<>();
        String query = "SELECT * FROM Notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Notification n = new Notification();
                    n.setId(rs.getInt("id"));
                    n.setUserId(rs.getInt("user_id"));
                    n.setTitle(rs.getString("title"));
                    n.setMessage(rs.getString("message"));
                    n.setLink(rs.getString("link"));
                    n.setRead(rs.getBoolean("is_read"));
                    n.setCreatedAt(rs.getTimestamp("created_at"));
                    list.add(n);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public int getUnreadCount(int userId) {
        String query = "SELECT COUNT(*) FROM Notifications WHERE user_id = ? AND is_read = FALSE";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
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

    public boolean markAsRead(int notificationId, int userId) {
        String query = "UPDATE Notifications SET is_read = TRUE WHERE id = ? AND user_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, notificationId);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean markAllAsRead(int userId) {
        String query = "UPDATE Notifications SET is_read = TRUE WHERE user_id = ? AND is_read = FALSE";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<Notification> getNotifications(int userId, int limit, int offset) {
        List<Notification> list = new ArrayList<>();
        String query = "SELECT * FROM Notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.setInt(2, limit);
            ps.setInt(3, offset);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Notification n = new Notification();
                    n.setId(rs.getInt("id"));
                    n.setUserId(rs.getInt("user_id"));
                    n.setTitle(rs.getString("title"));
                    n.setMessage(rs.getString("message"));
                    n.setLink(rs.getString("link"));
                    n.setRead(rs.getBoolean("is_read"));
                    n.setCreatedAt(rs.getTimestamp("created_at"));
                    list.add(n);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public int getNotificationsCount(int userId) {
        String query = "SELECT COUNT(*) FROM Notifications WHERE user_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
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
}
