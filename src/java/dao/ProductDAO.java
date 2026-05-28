package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import model.Product;
import utils.DBUtils;

public class ProductDAO {

    public List<Product> getAllProducts() {
        List<Product> list = new ArrayList<>();
        String query = "SELECT p.*, c.category_name, b.brand_name, COALESCE(i.quantity, 0) as quantity "
                     + "FROM Products p "
                     + "LEFT JOIN Categories c ON p.category_id = c.id "
                     + "LEFT JOIN Brands b ON p.brand_id = b.id "
                     + "LEFT JOIN Inventories i ON p.id = i.product_id";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToProduct(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Product> searchAndFilterProducts(String search, Integer categoryId, Integer brandId, boolean lowStockOnly) {
        List<Product> list = new ArrayList<>();
        StringBuilder query = new StringBuilder(
            "SELECT p.*, c.category_name, b.brand_name, COALESCE(i.quantity, 0) as quantity "
            + "FROM Products p "
            + "LEFT JOIN Categories c ON p.category_id = c.id "
            + "LEFT JOIN Brands b ON p.brand_id = b.id "
            + "LEFT JOIN Inventories i ON p.id = i.product_id "
            + "WHERE 1=1"
        );
        List<Object> params = new ArrayList<>();

        if (search != null && !search.trim().isEmpty()) {
            query.append(" AND (p.product_name LIKE ? OR p.sku LIKE ?)");
            String pattern = "%" + search.trim() + "%";
            params.add(pattern);
            params.add(pattern);
        }

        if (categoryId != null && categoryId > 0) {
            query.append(" AND p.category_id = ?");
            params.add(categoryId);
        }

        if (brandId != null && brandId > 0) {
            query.append(" AND p.brand_id = ?");
            params.add(brandId);
        }

        if (lowStockOnly) {
            query.append(" AND COALESCE(i.quantity, 0) <= p.min_stock");
        }

        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToProduct(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public Product getProductById(int id) {
        String query = "SELECT p.*, c.category_name, b.brand_name, COALESCE(i.quantity, 0) as quantity "
                     + "FROM Products p "
                     + "LEFT JOIN Categories c ON p.category_id = c.id "
                     + "LEFT JOIN Brands b ON p.brand_id = b.id "
                     + "LEFT JOIN Inventories i ON p.id = i.product_id "
                     + "WHERE p.id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapResultSetToProduct(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean addProduct(Product p) {
        String insertProd = "INSERT INTO Products (product_name, sku, unit, min_stock, default_cost, average_cost, status, category_id, brand_id, technical_specifications) "
                          + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        String insertInv = "INSERT INTO Inventories (product_id, quantity) VALUES (?, 0)";
        
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false); // start transaction

            int productId = 0;
            try (PreparedStatement ps = conn.prepareStatement(insertProd, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, p.getProductName());
                ps.setString(2, p.getSku());
                ps.setString(3, p.getUnit());
                ps.setInt(4, p.getMinStock());
                ps.setDouble(5, p.getDefaultCost());
                ps.setDouble(6, p.getAverageCost());
                ps.setBoolean(7, p.isStatus());
                
                if (p.getCategoryId() != null && p.getCategoryId() > 0) {
                    ps.setInt(8, p.getCategoryId());
                } else {
                    ps.setNull(8, java.sql.Types.INTEGER);
                }
                
                if (p.getBrandId() != null && p.getBrandId() > 0) {
                    ps.setInt(9, p.getBrandId());
                } else {
                    ps.setNull(9, java.sql.Types.INTEGER);
                }
                
                ps.setString(10, p.getTechnicalSpecifications());
                
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    try (ResultSet rs = ps.getGeneratedKeys()) {
                        if (rs.next()) {
                            productId = rs.getInt(1);
                        }
                    }
                }
            }

            if (productId > 0) {
                try (PreparedStatement psInv = conn.prepareStatement(insertInv)) {
                    psInv.setInt(1, productId);
                    psInv.executeUpdate();
                }
                conn.commit();
                return true;
            } else {
                conn.rollback();
            }
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

    public boolean updateProduct(Product p) {
        String query = "UPDATE Products SET product_name = ?, sku = ?, unit = ?, min_stock = ?, default_cost = ?, "
                     + "category_id = ?, brand_id = ?, technical_specifications = ? "
                     + "WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, p.getProductName());
            ps.setString(2, p.getSku());
            ps.setString(3, p.getUnit());
            ps.setInt(4, p.getMinStock());
            ps.setDouble(5, p.getDefaultCost());
            
            if (p.getCategoryId() != null && p.getCategoryId() > 0) {
                ps.setInt(6, p.getCategoryId());
            } else {
                ps.setNull(6, java.sql.Types.INTEGER);
            }
            
            if (p.getBrandId() != null && p.getBrandId() > 0) {
                ps.setInt(7, p.getBrandId());
            } else {
                ps.setNull(7, java.sql.Types.INTEGER);
            }
            
            ps.setString(8, p.getTechnicalSpecifications());
            ps.setInt(9, p.getId());
            
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean toggleProductStatus(int id) {
        String query = "UPDATE Products SET status = NOT status WHERE id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean isSkuExists(String sku, int excludeId) {
        String query = "SELECT COUNT(*) FROM Products WHERE sku = ? AND id != ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setString(1, sku);
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    private Product mapResultSetToProduct(ResultSet rs) throws Exception {
        Product p = new Product(
            rs.getInt("id"),
            rs.getString("product_name"),
            rs.getString("sku"),
            rs.getString("unit"),
            rs.getInt("min_stock"),
            rs.getDouble("default_cost"),
            rs.getDouble("average_cost"),
            rs.getBoolean("status"),
            rs.getInt("category_id"),
            rs.getInt("brand_id"),
            rs.getString("technical_specifications")
        );
        p.setCategoryName(rs.getString("category_name"));
        p.setBrandName(rs.getString("brand_name"));
        p.setQuantity(rs.getInt("quantity"));
        return p;
    }
}
