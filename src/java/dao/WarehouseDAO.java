package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import model.Warehouse;
import utils.DBUtils;

public class WarehouseDAO {

    private Warehouse mapRow(ResultSet rs) throws Exception {
        Warehouse w = new Warehouse();
        w.setId(rs.getInt("id"));
        w.setWarehouseName(rs.getString("warehouse_name"));
        w.setAddress(rs.getString("address"));
        w.setStatus(rs.getBoolean("status"));
        w.setCreatedAt(rs.getTimestamp("created_at"));
        return w;
    }

    public List<Warehouse> getAllWarehouses() {
        List<Warehouse> list = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT * FROM Warehouses ORDER BY warehouse_name ASC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Warehouse> getAllActiveWarehouses() {
        List<Warehouse> list = new ArrayList<>();
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT * FROM Warehouses WHERE status = true ORDER BY warehouse_name ASC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Warehouse getById(int id) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT * FROM Warehouses WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean add(Warehouse w) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO Warehouses (warehouse_name, address, status) VALUES (?, ?, ?)",
                     Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, w.getWarehouseName().trim());
            ps.setString(2, w.getAddress() != null ? w.getAddress().trim() : null);
            ps.setBoolean(3, true);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    public boolean update(Warehouse w) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE Warehouses SET warehouse_name = ?, address = ? WHERE id = ?")) {
            ps.setString(1, w.getWarehouseName().trim());
            ps.setString(2, w.getAddress() != null ? w.getAddress().trim() : null);
            ps.setInt(3, w.getId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    public boolean toggleStatus(int id) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE Warehouses SET status = NOT status WHERE id = ?")) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    public int countStaff(int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM Users WHERE warehouse_id = ? AND status = true")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Total stock quantity (sum of all Inventories.quantity) for a warehouse. */
    public int getTotalStockQty(int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COALESCE(SUM(quantity), 0) FROM Inventories WHERE warehouse_id = ?")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Count distinct product SKUs in stock (qty > 0) for a warehouse. */
    public int countProductsInStock(int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM Inventories WHERE warehouse_id = ? AND quantity > 0")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Count pending (DRAFT) import tickets for a warehouse. */
    public int countPendingImportTickets(int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM Tickets WHERE type='IN' AND warehouse_id = ? AND status = 'DRAFT'")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Count pending (DRAFT) export tickets for a warehouse. */
    public int countPendingExportTickets(int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM Tickets WHERE type='OUT' AND warehouse_id = ? AND status = 'DRAFT'")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Count IN_TRANSIT OUT-TRANSFER tickets targeting this warehouse (incoming transfers). */
    public int countIncomingTransfers(int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM Tickets t "
                   + "JOIN Requests r ON t.request_id = r.id "
                   + "WHERE t.type = 'OUT' AND t.status = 'IN_TRANSIT' "
                   + "  AND r.reason = 'TRANSFER' AND r.partner_id = ?")) {
            ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}
