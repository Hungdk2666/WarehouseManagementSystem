package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import model.ProductItem;

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
}
