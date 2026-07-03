package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.ProductItem;
import utils.DBUtils;

public class ProductItemDAO {

    private ProductItem mapRow(ResultSet rs) throws Exception {
        ProductItem item = new ProductItem();
        item.setId(rs.getInt("id"));
        item.setProductId(rs.getInt("product_id"));
        item.setSerialNumber(rs.getString("serial_number"));
        item.setStatus(rs.getString("status"));
        item.setCreatedAt(rs.getTimestamp("created_at"));
        item.setItemCondition(rs.getString("item_condition"));
        item.setWarehouseId(rs.getInt("warehouse_id"));
        item.setManufacturerSerial(rs.getString("manufacturer_serial"));
        return item;
    }

    /**
     * Inserts new Product_Items for a confirmed import ticket.
     * Returns serial numbers generated so the caller can insert Product_Item_Movements.
     * Participates in the caller's transaction via the passed Connection.
     */
    public List<String> addProductItemsAndReturnSerials(
            int productId, int importTicketId, int quantity, String sku, int warehouseId, Connection conn) throws Exception {
        return addProductItemsAndReturnSerials(productId, importTicketId, quantity, sku, warehouseId, "NEW", null, conn);
    }

    public List<String> addProductItemsAndReturnSerials(
            int productId, int importTicketId, int quantity, String sku, int warehouseId, String itemCondition, Connection conn) throws Exception {
        return addProductItemsAndReturnSerials(productId, importTicketId, quantity, sku, warehouseId, itemCondition, null, conn);
    }

    public List<String> addProductItemsAndReturnSerials(
            int productId, int importTicketId, int quantity, String sku, int warehouseId,
            String itemCondition, List<String> manufacturerSerials, Connection conn) throws Exception {

        String skuClean = sku.replaceAll("[^a-zA-Z0-9-]", "");
        String condition = (itemCondition != null) ? itemCondition : "NEW";
        String status = "DAMAGED".equals(condition) ? "QUARANTINE" : "IN_STOCK";

        int currentMaxIndex = 0;
        try (PreparedStatement psMax = conn.prepareStatement("SELECT COUNT(*) FROM Product_Items WHERE product_id = ?")) {
            psMax.setInt(1, productId);
            try (ResultSet rs = psMax.executeQuery()) { if (rs.next()) currentMaxIndex = rs.getInt(1); }
        }

        List<String> serials = new ArrayList<>();
        String insertSql = "INSERT INTO Product_Items (product_id, serial_number, manufacturer_serial, status, item_condition, warehouse_id) VALUES (?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            for (int i = 0; i < quantity; i++) {
                int nextIndex = currentMaxIndex + i + 1;
                String serial = String.format("%s-%03d", skuClean, nextIndex);
                String mfrSerial = (manufacturerSerials != null && i < manufacturerSerials.size()) ? manufacturerSerials.get(i) : null;
                ps.setInt(1, productId);
                ps.setString(2, serial);
                if (mfrSerial != null) {
                    ps.setString(3, mfrSerial);
                } else {
                    ps.setNull(3, java.sql.Types.VARCHAR);
                }
                ps.setString(4, status);
                ps.setString(5, condition);
                ps.setInt(6, warehouseId);
                ps.executeUpdate();
                serials.add(serial);
            }
        }
        return serials;
    }

    /** Legacy wrapper — delegates to addProductItemsAndReturnSerials via a fresh connection. */
    public boolean addProductItems(int productId, int importTicketId, int quantity, String sku, int warehouseId, Connection conn) throws Exception {
        addProductItemsAndReturnSerials(productId, importTicketId, quantity, sku, warehouseId, conn);
        return true;
    }

    public boolean addProductItems(int productId, int importTicketId, int quantity, String sku, Connection conn) throws Exception {
        return addProductItems(productId, importTicketId, quantity, sku, 1, conn);
    }

    public List<ProductItem> getInStockItemsByProductId(int productId, String itemCondition) {
        return getInStockItemsByProductId(productId, null, itemCondition);
    }

    public List<ProductItem> getInStockItemsByProductId(int productId, Integer warehouseId) {
        return getInStockItemsByProductId(productId, warehouseId, null);
    }

    public List<ProductItem> getInStockItemsByProductId(int productId, Integer warehouseId, String itemCondition) {
        List<ProductItem> list = new ArrayList<>();
        String query;
        if (warehouseId != null) {
            query = "SELECT i.*, p.product_name, p.sku, p.unit, w.warehouse_name "
                  + "FROM Product_Items i "
                  + "JOIN Products p ON i.product_id = p.id "
                  + "LEFT JOIN Warehouses w ON i.warehouse_id = w.id "
                  + "WHERE i.product_id = ? AND i.status = 'IN_STOCK' AND i.warehouse_id = ? "
                  + (itemCondition != null ? "AND i.item_condition = ? " : "")
                  + "ORDER BY i.id ASC";
        } else {
            query = "SELECT i.*, p.product_name, p.sku, p.unit, w.warehouse_name "
                  + "FROM Product_Items i "
                  + "JOIN Products p ON i.product_id = p.id "
                  + "LEFT JOIN Warehouses w ON i.warehouse_id = w.id "
                  + "WHERE i.product_id = ? AND i.status = 'IN_STOCK' "
                  + (itemCondition != null ? "AND i.item_condition = ? " : "")
                  + "ORDER BY i.id ASC";
        }
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, productId);
            int paramIndex = 2;
            if (warehouseId != null) {
                ps.setInt(paramIndex++, warehouseId);
            }
            if (itemCondition != null) {
                ps.setString(paramIndex++, itemCondition);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = mapRow(rs);
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    item.setWarehouseName(rs.getString("warehouse_name"));
                    list.add(item);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<ProductItem> getExportedItemsByProductId(int productId) {
        List<ProductItem> list = new ArrayList<>();
        String query = "SELECT i.*, p.product_name, p.sku, p.unit, w.warehouse_name "
                     + "FROM Product_Items i "
                     + "JOIN Products p ON i.product_id = p.id "
                     + "LEFT JOIN Warehouses w ON i.warehouse_id = w.id "
                     + "WHERE i.product_id = ? AND i.status = 'EXPORTED' "
                     + "ORDER BY i.id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = mapRow(rs);
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    item.setWarehouseName(rs.getString("warehouse_name"));
                    list.add(item);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /** Returns serial numbers linked to a ticket (IN or OUT) via Product_Item_Movements. */
    public List<ProductItem> getItemsByTicketId(int ticketId) {
        List<ProductItem> list = new ArrayList<>();
        String query = "SELECT DISTINCT i.*, p.product_name, p.sku, p.unit "
                     + "FROM Product_Items i "
                     + "JOIN Product_Item_Movements m ON m.product_item_id = i.id "
                     + "JOIN Products p ON i.product_id = p.id "
                     + "WHERE m.ticket_id = ? "
                     + "ORDER BY i.id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = mapRow(rs);
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    list.add(item);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<ProductItem> getExportedItemsByTicketId(int ticketId) {
        List<ProductItem> list = new ArrayList<>();
        String query = "SELECT DISTINCT i.*, p.product_name, p.sku, p.unit "
                     + "FROM Product_Items i "
                     + "JOIN Product_Item_Movements m ON m.product_item_id = i.id "
                     + "JOIN Products p ON i.product_id = p.id "
                     + "WHERE m.ticket_id = ? AND m.action IN ('EXPORT_OUT','TRANSFER_OUT') "
                     + "  AND i.status = 'EXPORTED' "
                     + "ORDER BY i.id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = mapRow(rs);
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    list.add(item);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public boolean checkSerialAvailable(String serialNumber, int productId) {
        return checkSerialAvailable(serialNumber, productId, null);
    }

    public boolean checkSerialAvailable(String serialNumber, int productId, Integer warehouseId) {
        String query;
        if (warehouseId != null) {
            query = "SELECT COUNT(*) FROM Product_Items WHERE serial_number = ? AND product_id = ? AND status = 'IN_STOCK' AND warehouse_id = ?";
        } else {
            query = "SELECT COUNT(*) FROM Product_Items WHERE serial_number = ? AND product_id = ? AND status = 'IN_STOCK'";
        }
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, serialNumber);
            ps.setInt(2, productId);
            if (warehouseId != null) ps.setInt(3, warehouseId);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return rs.getInt(1) > 0; }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }
}
