package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import model.User;
import utils.DBUtils;

public class UserDAO {

    public User getUserByUsername(String username) {
        String query = "SELECT u.*, r.role_name, w.warehouse_name FROM Users u LEFT JOIN Roles r ON u.role_id = r.id LEFT JOIN Warehouses w ON u.warehouse_id = w.id WHERE u.username = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs, conn);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public User getUserByEmail(String email) {
        String query = "SELECT u.*, r.role_name, w.warehouse_name FROM Users u LEFT JOIN Roles r ON u.role_id = r.id LEFT JOIN Warehouses w ON u.warehouse_id = w.id WHERE u.email = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs, conn);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public User getUserById(int id) {
        String query = "SELECT u.*, r.role_name, w.warehouse_name FROM Users u LEFT JOIN Roles r ON u.role_id = r.id LEFT JOIN Warehouses w ON u.warehouse_id = w.id WHERE u.id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs, conn);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updatePassword(int userId, String newHashedPassword) {
        String query = "UPDATE Users SET password = ?, reset_code = NULL, reset_code_expires_at = NULL, reset_attempts = 0 WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, newHashedPassword);
            ps.setInt(2, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<User> getAllUsers() {
        List<User> list = new ArrayList<>();
        String query = "SELECT u.*, r.role_name, w.warehouse_name FROM Users u LEFT JOIN Roles r ON u.role_id = r.id LEFT JOIN Warehouses w ON u.warehouse_id = w.id";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToUser(rs, conn));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<User> searchAndFilterUsers(String search, String roleFilter) {
        List<User> list = new ArrayList<>();
        StringBuilder query = new StringBuilder("SELECT u.*, r.role_name, w.warehouse_name FROM Users u LEFT JOIN Roles r ON u.role_id = r.id LEFT JOIN Warehouses w ON u.warehouse_id = w.id WHERE 1=1");
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            query.append(" AND (u.username LIKE ? OR u.email LIKE ? OR u.full_name LIKE ?)");
            String searchPattern = "%" + search.trim() + "%";
            params.add(searchPattern);
            params.add(searchPattern);
            params.add(searchPattern);
        }

        if (roleFilter != null && !roleFilter.trim().isEmpty()) {
            query.append(" AND r.role_name = ?");
            params.add(roleFilter.trim());
        }

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToUser(rs, conn));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean addUser(User user) {
        String query = "INSERT INTO Users (username, password, email, full_name, status, role_id, warehouse_id) VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, user.getUsername());
            ps.setString(2, user.getPassword());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getFullName());
            ps.setBoolean(5, user.isStatus());
            ps.setInt(6, user.getRoleId());
            if (user.getWarehouseId() != null) {
                ps.setInt(7, user.getWarehouseId());
            } else {
                ps.setNull(7, java.sql.Types.INTEGER);
            }
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean updateUser(User user) {
        String query = "UPDATE Users SET email = ?, full_name = ?, role_id = ?, warehouse_id = ? WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, user.getEmail());
            ps.setString(2, user.getFullName());
            ps.setInt(3, user.getRoleId());
            if (user.getWarehouseId() != null) {
                ps.setInt(4, user.getWarehouseId());
            } else {
                ps.setNull(4, java.sql.Types.INTEGER);
            }
            ps.setInt(5, user.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean toggleUserStatus(int userId) {
        String query = "UPDATE Users SET status = NOT status WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public int countActiveUsersByRoleId(int roleId) {
        String query = "SELECT COUNT(*) FROM Users WHERE role_id = ? AND status = true";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, roleId);
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

    public boolean setResetCode(int userId, String code, Timestamp expiresAt) {
        String query = "UPDATE Users SET reset_code = ?, reset_code_expires_at = ?, reset_attempts = 0 WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, code);
            ps.setTimestamp(2, expiresAt);
            ps.setInt(3, userId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean setResetCode(int userId, String code) {
        return setResetCode(userId, code, new Timestamp(System.currentTimeMillis() + 10 * 60 * 1000));
    }

    public User verifyResetCode(String email, String code) {
        String query = "SELECT u.*, r.role_name, w.warehouse_name FROM Users u "
                + "LEFT JOIN Roles r ON u.role_id = r.id "
                + "LEFT JOIN Warehouses w ON u.warehouse_id = w.id "
                + "WHERE u.email = ? AND u.reset_code = ? "
                + "AND u.reset_code_expires_at > NOW() "
                + "AND u.reset_attempts < 5";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, email);
            ps.setString(2, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToUser(rs, conn);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public void incrementResetAttempts(String email) {
        String query = "UPDATE Users SET reset_attempts = reset_attempts + 1 WHERE email = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, email);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void clearResetCode(int userId) {
        String query = "UPDATE Users SET reset_code = NULL, reset_code_expires_at = NULL, reset_attempts = 0 WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private List<String> getPermissionNamesByRoleId(int roleId, Connection conn) throws Exception {
        List<String> list = new ArrayList<>();
        String query = "SELECT p.permission_name FROM Role_Permissions rp "
                     + "JOIN Permissions p ON rp.permission_id = p.id WHERE rp.role_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, roleId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(rs.getString("permission_name"));
                }
            }
        }
        return list;
    }

    private User mapResultSetToUser(ResultSet rs, Connection conn) throws Exception {
        User u = new User(
            rs.getInt("id"),
            rs.getString("username"),
            rs.getString("password"),
            rs.getString("email"),
            rs.getString("full_name"),
            rs.getBoolean("status"),
            rs.getInt("role_id"),
            rs.getString("reset_code")
        );
        int wId = rs.getInt("warehouse_id");
        if (rs.wasNull()) {
            u.setWarehouseId(null);
        } else {
            u.setWarehouseId(wId);
        }
        try {
            u.setRoleName(rs.getString("role_name"));
        } catch (Exception e) {
        }
        try {
            u.setWarehouseName(rs.getString("warehouse_name"));
        } catch (Exception e) {
        }
        u.setPermissions(getPermissionNamesByRoleId(u.getRoleId(), conn));
        return u;
    }
}
