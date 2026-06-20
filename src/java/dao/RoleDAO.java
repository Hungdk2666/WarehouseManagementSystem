package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.Permission;
import model.Role;
import utils.DBUtils;

public class RoleDAO {

    public List<Role> getAllRoles() {
        List<Role> list = new ArrayList<>();
        String query = "SELECT * FROM Roles";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Role(
                    rs.getInt("id"),
                    rs.getString("role_name"),
                    rs.getBoolean("status")
                ));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public Role getRoleById(int id) {
        String query = "SELECT * FROM Roles WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Role(
                        rs.getInt("id"),
                        rs.getString("role_name"),
                        rs.getBoolean("status")
                    );
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean updateRole(Role role) {
        String query = "UPDATE Roles SET role_name = ? WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, role.getRoleName());
            ps.setInt(2, role.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean toggleRoleStatus(int roleId) {
        String query = "UPDATE Roles SET status = NOT status WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, roleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public List<Permission> getAllPermissions() {
        List<Permission> list = new ArrayList<>();
        String query = "SELECT * FROM Permissions";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Permission(
                    rs.getInt("id"),
                    rs.getString("permission_name"),
                    rs.getString("description")
                ));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Integer> getPermissionsByRoleId(int roleId) {
        List<Integer> list = new ArrayList<>();
        String query = "SELECT permission_id FROM Role_Permissions WHERE role_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, roleId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(rs.getInt("permission_id"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean updateRolePermissions(int roleId, String[] permissionIds) {
        String deleteQuery = "DELETE FROM Role_Permissions WHERE role_id = ?";
        String insertQuery = "INSERT INTO Role_Permissions (role_id, permission_id) VALUES (?, ?)";
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // 1. Delete old permissions
            try (PreparedStatement deletePs = conn.prepareStatement(deleteQuery)) {
                deletePs.setInt(1, roleId);
                deletePs.executeUpdate();
            }

            // 2. Insert new permissions (if any)
            if (permissionIds != null && permissionIds.length > 0) {
                try (PreparedStatement insertPs = conn.prepareStatement(insertQuery)) {
                    for (String permIdStr : permissionIds) {
                        insertPs.setInt(1, roleId);
                        insertPs.setInt(2, Integer.parseInt(permIdStr));
                        insertPs.addBatch();
                    }
                    insertPs.executeBatch();
                }
            }

            conn.commit();
            return true;
        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try { conn.setAutoCommit(true); conn.close(); } catch (Exception ex) { ex.printStackTrace(); }
            }
        }
        return false;
    }

    public boolean addRole(String roleName, boolean status) {
        String query = "INSERT INTO Roles (role_name, status) VALUES (?, ?)";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, roleName);
            ps.setBoolean(2, status);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}

