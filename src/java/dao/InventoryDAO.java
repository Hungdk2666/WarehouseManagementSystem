package dao;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.InventoryRow;
import model.ProductItem;
import utils.DBUtils;

/**
 * DAO cho trang Inventory (tách khỏi Product master data).
 *
 * Inventory là VIEW tổng hợp từ:
 *   - Inventories (quantity, quarantine_quantity)
 *   - Product_Items (đếm theo status: IN_TRANSIT, LOST)
 *   - Products (master data: tên, sku, min_stock, average_cost, category, brand)
 *
 * Trang Product tách bạch — không hiển thị tồn nữa.
 */
public class InventoryDAO {

    private static final String BASE_SELECT =
        "SELECT i.warehouse_id, i.product_id, i.quantity, i.quarantine_quantity, "
        + "       p.product_name, p.sku, p.unit, p.min_stock, p.average_cost, "
        + "       c.category_name, b.brand_name, w.warehouse_name, "
        + "       (SELECT COUNT(*) FROM Product_Items pi WHERE pi.product_id = i.product_id AND pi.warehouse_id = i.warehouse_id AND pi.status = 'IN_TRANSIT') AS in_transit_qty, "
        + "       (SELECT COUNT(*) FROM Product_Items pi WHERE pi.product_id = i.product_id AND pi.warehouse_id = i.warehouse_id AND pi.status = 'LOST') AS lost_qty "
        + "FROM Inventories i "
        + "JOIN Products p   ON p.id = i.product_id "
        + "JOIN Warehouses w ON w.id = i.warehouse_id "
        + "LEFT JOIN Categories c ON c.id = p.category_id "
        + "LEFT JOIN Brands b     ON b.id = p.brand_id ";

    private InventoryRow mapRow(ResultSet rs) throws Exception {
        InventoryRow r = new InventoryRow();
        r.setWarehouseId(rs.getInt("warehouse_id"));
        r.setProductId(rs.getInt("product_id"));
        r.setQuantity(rs.getInt("quantity"));
        r.setQuarantineQuantity(rs.getInt("quarantine_quantity"));
        r.setInTransitQuantity(rs.getInt("in_transit_qty"));
        r.setLostQuantity(rs.getInt("lost_qty"));
        r.setProductName(rs.getString("product_name"));
        r.setSku(rs.getString("sku"));
        r.setUnit(rs.getString("unit"));
        r.setMinStock(rs.getInt("min_stock"));
        r.setAverageCost(rs.getBigDecimal("average_cost"));
        r.setCategoryName(rs.getString("category_name"));
        r.setBrandName(rs.getString("brand_name"));
        r.setWarehouseName(rs.getString("warehouse_name"));
        return r;
    }

    /**
     * Liệt kê tồn kho với filter.
     */
    public List<InventoryRow> list(Integer warehouseId, Integer categoryId,
                                   Integer brandId, boolean onlyLowStock,
                                   boolean onlyHasDamaged, String keyword) {
        List<InventoryRow> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(BASE_SELECT).append(" WHERE 1=1 ");
        List<Object> params = new ArrayList<>();

        if (warehouseId != null) { sql.append(" AND i.warehouse_id = ?"); params.add(warehouseId); }
        if (categoryId != null)  { sql.append(" AND p.category_id = ?");  params.add(categoryId); }
        if (brandId != null)     { sql.append(" AND p.brand_id = ?");     params.add(brandId); }
        if (onlyLowStock)        { sql.append(" AND i.quantity < p.min_stock"); }
        if (onlyHasDamaged)      { sql.append(" AND i.quarantine_quantity > 0"); }
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append(" AND (p.product_name LIKE ? OR p.sku LIKE ?) ");
            params.add("%" + keyword.trim() + "%");
            params.add("%" + keyword.trim() + "%");
        }
        sql.append(" ORDER BY w.warehouse_name, p.product_name");

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Lấy chi tiết 1 dòng inventory (1 SKU trong 1 kho).
     */
    public InventoryRow getByKey(int warehouseId, int productId) {
        String sql = BASE_SELECT + " WHERE i.warehouse_id = ? AND i.product_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, warehouseId);
            ps.setInt(2, productId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /**
     * Tổng quan KPI cho dashboard inventory.
     */
    public InventoryKpi getKpi(Integer warehouseId) {
        InventoryKpi k = new InventoryKpi();
        String filter = warehouseId != null ? " WHERE warehouse_id = ?" : "";

        String sql =
            "SELECT "
          + " COUNT(DISTINCT product_id)              AS total_skus, "
          + " COUNT(DISTINCT CASE WHEN quantity > 0 THEN product_id END) AS skus_in_stock, "
          + " (SELECT COUNT(DISTINCT i2.product_id) FROM Inventories i2"
          +   " JOIN Products p2 ON p2.id = i2.product_id"
          +   " WHERE i2.quantity < p2.min_stock" + (warehouseId != null ? " AND i2.warehouse_id = ?" : "") + ") AS low_stock_skus, "
          + " SUM(quarantine_quantity)                AS total_quarantine, "
          + " SUM(quantity * (SELECT average_cost FROM Products WHERE id = product_id)) AS total_value "
          + "FROM Inventories " + filter;
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (warehouseId != null) {
                ps.setInt(1, warehouseId);
                ps.setInt(2, warehouseId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    k.totalSkus      = rs.getInt("total_skus");
                    k.skusInStock    = rs.getInt("skus_in_stock");
                    k.lowStockSkus   = rs.getInt("low_stock_skus");
                    k.totalQuarantine = rs.getInt("total_quarantine");
                    k.totalValue     = rs.getBigDecimal("total_value");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        // Đếm LOST từ Product_Items
        String sqlLost = "SELECT COUNT(*) FROM Product_Items WHERE status = 'LOST'"
                       + (warehouseId != null ? " AND warehouse_id = ?" : "");
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sqlLost)) {
            if (warehouseId != null) ps.setInt(1, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) k.totalLost = rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }

        return k;
    }

    /**
     * Lấy danh sách serial của 1 SKU trong 1 kho — group theo status.
     */
    public List<ProductItem> getSerialsByWarehouseProduct(int warehouseId, int productId) {
        List<ProductItem> list = new ArrayList<>();
        String sql = "SELECT i.*, p.product_name, p.sku, p.unit "
                   + "FROM Product_Items i "
                   + "JOIN Products p ON p.id = i.product_id "
                   + "WHERE i.warehouse_id = ? AND i.product_id = ? "
                   + "ORDER BY i.status, i.item_condition, i.serial_number";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, warehouseId);
            ps.setInt(2, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem it = new ProductItem();
                    it.setId(rs.getInt("id"));
                    it.setProductId(rs.getInt("product_id"));
                    it.setSerialNumber(rs.getString("serial_number"));
                    it.setStatus(rs.getString("status"));
                    it.setItemCondition(rs.getString("item_condition"));
                    it.setWarehouseId(rs.getInt("warehouse_id"));
                    it.setCreatedAt(rs.getTimestamp("created_at"));
                    it.setProductName(rs.getString("product_name"));
                    it.setSku(rs.getString("sku"));
                    it.setUnit(rs.getString("unit"));
                    list.add(it);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Lấy 30 dòng gần nhất trong Product_Ledger cho 1 SKU trong 1 kho.
     */
    public List<LedgerEntry> getRecentLedger(int warehouseId, int productId, int limit) {
        List<LedgerEntry> list = new ArrayList<>();
        String sql = "SELECT l.*, u.full_name AS created_by_name "
                   + "FROM Product_Ledger l "
                   + "LEFT JOIN Users u ON u.id = l.created_by "
                   + "WHERE l.warehouse_id = ? AND l.product_id = ? "
                   + "ORDER BY l.id DESC LIMIT ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, warehouseId);
            ps.setInt(2, productId);
            ps.setInt(3, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LedgerEntry e = new LedgerEntry();
                    e.transactionType = rs.getString("transaction_type");
                    e.referenceId = rs.getInt("reference_id");
                    e.changeQuantity = rs.getInt("change_quantity");
                    e.balanceQuantity = rs.getInt("balance_quantity");
                    e.createdAt = rs.getTimestamp("created_at");
                    e.createdByName = rs.getString("created_by_name");
                    list.add(e);
                }
            }
        } catch (Exception ex) { ex.printStackTrace(); }
        return list;
    }

    // ============================================================
    // Inner DTOs — tránh tạo file model riêng cho dữ liệu chỉ-đọc
    // ============================================================
    public static class InventoryKpi {
        public int totalSkus;
        public int skusInStock;
        public int lowStockSkus;
        public int totalQuarantine;
        public int totalLost;
        public BigDecimal totalValue;
    }

    public static class LedgerEntry {
        public String transactionType;
        public int referenceId;
        public int changeQuantity;
        public int balanceQuantity;
        public java.sql.Timestamp createdAt;
        public String createdByName;
    }
}
