package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import model.ProductItem;
import utils.DBUtils;

public class ProductItemDAO {

    /**
     * Generates and inserts unique serial numbers for a given import ticket.
     * Participating in the parent transaction.
     */
    public boolean addProductItems(int productId, int importTicketId, int quantity, String sku, Connection conn) throws Exception {
        String query = "INSERT INTO Product_Items (product_id, serial_number, status, import_ticket_id) VALUES (?, ?, 'IN_STOCK', ?)";
        
        String skuClean = sku.replaceAll("[^a-zA-Z0-9-]", ""); // normalize SKU prefix
        
        // Find current total count of items for this product to compute next sequence index
        int currentMaxIndex = 0;
        String maxQuery = "SELECT COUNT(*) FROM Product_Items WHERE product_id = ?";
        try (PreparedStatement psMax = conn.prepareStatement(maxQuery)) {
            psMax.setInt(1, productId);
            try (ResultSet rs = psMax.executeQuery()) {
                if (rs.next()) {
                    currentMaxIndex = rs.getInt(1);
                }
            }
        }
        
        try (PreparedStatement ps = conn.prepareStatement(query)) {
            for (int i = 0; i < quantity; i++) {
                int nextIndex = currentMaxIndex + i + 1;
                // Format: [SKU]-[3-DIGIT-INCREMENT] (e.g. PANA-9000-016)
                String serial = String.format("%s-%03d", skuClean, nextIndex);
                
                ps.setInt(1, productId);
                ps.setString(2, serial);
                ps.setInt(3, importTicketId);
                ps.executeUpdate();
            }
        }
        return true;
    }
    
    /**
     * Returns all available serial numbers for a product.
     */
    public List<ProductItem> getInStockItemsByProductId(int productId) {
        List<ProductItem> list = new ArrayList<>();
        String query = "SELECT i.*, p.product_name, p.sku, p.unit "
                     + "FROM Product_Items i "
                     + "JOIN Products p ON i.product_id = p.id "
                     + "WHERE i.product_id = ? AND i.status = 'IN_STOCK' "
                     + "ORDER BY i.id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = new ProductItem();
                    item.setId(rs.getInt("id"));
                    item.setProductId(rs.getInt("product_id"));
                    item.setSerialNumber(rs.getString("serial_number"));
                    item.setStatus(rs.getString("status"));
                    item.setImportTicketId(rs.getInt("import_ticket_id"));
                    item.setExportTicketId((Integer) rs.getObject("export_ticket_id"));
                    item.setCreatedAt(rs.getTimestamp("created_at"));
                    
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    list.add(item);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    
    /**
     * Returns serial numbers linked to an import ticket.
     */
    public List<ProductItem> getItemsByImportTicketId(int ticketId) {
        List<ProductItem> list = new ArrayList<>();
        String query = "SELECT i.*, p.product_name, p.sku, p.unit "
                     + "FROM Product_Items i "
                     + "JOIN Products p ON i.product_id = p.id "
                     + "WHERE i.import_ticket_id = ? "
                     + "ORDER BY i.id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = new ProductItem();
                    item.setId(rs.getInt("id"));
                    item.setProductId(rs.getInt("product_id"));
                    item.setSerialNumber(rs.getString("serial_number"));
                    item.setStatus(rs.getString("status"));
                    item.setImportTicketId(rs.getInt("import_ticket_id"));
                    item.setExportTicketId((Integer) rs.getObject("export_ticket_id"));
                    item.setCreatedAt(rs.getTimestamp("created_at"));
                    
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    list.add(item);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
    
    /**
     * Returns serial numbers linked to an export ticket.
     */
    public List<ProductItem> getItemsByExportTicketId(int ticketId) {
        List<ProductItem> list = new ArrayList<>();
        String query = "SELECT i.*, p.product_name, p.sku, p.unit "
                     + "FROM Product_Items i "
                     + "JOIN Products p ON i.product_id = p.id "
                     + "WHERE i.export_ticket_id = ? "
                     + "ORDER BY i.id ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, ticketId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ProductItem item = new ProductItem();
                    item.setId(rs.getInt("id"));
                    item.setProductId(rs.getInt("product_id"));
                    item.setSerialNumber(rs.getString("serial_number"));
                    item.setStatus(rs.getString("status"));
                    item.setImportTicketId(rs.getInt("import_ticket_id"));
                    item.setExportTicketId((Integer) rs.getObject("export_ticket_id"));
                    item.setCreatedAt(rs.getTimestamp("created_at"));
                    
                    item.setProductName(rs.getString("product_name"));
                    item.setSku(rs.getString("sku"));
                    item.setUnit(rs.getString("unit"));
                    list.add(item);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}
