package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import model.Product;
import model.ProductSpecification;
import model.WarehouseStockBreakdown;
import utils.DBUtils;

public class ProductDAO {

    public List<Product> getAllProducts() {
        return getAllProducts(null);
    }

    public List<Product> getAllProducts(Integer warehouseId) {
        List<Product> list = new ArrayList<>();
        String query;
        if (warehouseId != null) {
            query = "SELECT p.*, c.category_name, b.brand_name, "
                  + "COALESCE(iv.in_stock_qty, 0)   AS quantity, "
                  + "(COALESCE(iv.in_stock_qty, 0) + COALESCE(iv.quarantine_qty, 0)) AS physical_qty, "
                  + "COALESCE(iv.available_qty, 0)  AS available_qty, "
                  + "COALESCE(iv.available_new_qty, 0)  AS available_new_qty, "
                  + "COALESCE(iv.available_used_qty, 0)  AS available_used_qty, "
                  + "COALESCE(iv.reserved_qty, 0)   AS reserved_qty, "
                  + "COALESCE(iv.reserved_new_qty, 0)   AS reserved_new_qty, "
                  + "COALESCE(iv.reserved_used_qty, 0)   AS reserved_used_qty, "
                  + "COALESCE(iv.quarantine_qty, 0) AS damaged_qty "
                  + "FROM Products p "
                  + "LEFT JOIN Categories c ON p.category_id = c.id "
                  + "LEFT JOIN Brands b ON p.brand_id = b.id "
                  + "LEFT JOIN Inventory_Available iv ON iv.product_id = p.id AND iv.warehouse_id = ?";
        } else {
            query = "SELECT p.*, c.category_name, b.brand_name, "
                  + "COALESCE((SELECT SUM(in_stock_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS quantity, "
                  + "COALESCE((SELECT SUM(in_stock_qty + quarantine_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS physical_qty, "
                  + "COALESCE((SELECT SUM(available_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_qty, "
                  + "COALESCE((SELECT SUM(available_new_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_new_qty, "
                  + "COALESCE((SELECT SUM(available_used_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_used_qty, "
                  + "COALESCE((SELECT SUM(reserved_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_qty, "
                  + "COALESCE((SELECT SUM(reserved_new_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_new_qty, "
                  + "COALESCE((SELECT SUM(reserved_used_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_used_qty, "
                  + "COALESCE((SELECT SUM(quarantine_qty)FROM Inventory_Available WHERE product_id = p.id), 0) AS damaged_qty "
                  + "FROM Products p "
                  + "LEFT JOIN Categories c ON p.category_id = c.id "
                  + "LEFT JOIN Brands b ON p.brand_id = b.id";
        }
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            if (warehouseId != null) {
                ps.setInt(1, warehouseId);
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

    public List<Product> searchAndFilterProducts(String search, Integer categoryId, Integer brandId, boolean lowStockOnly) {
        return searchAndFilterProducts(search, categoryId, brandId, lowStockOnly, null);
    }

    public List<Product> searchAndFilterProducts(String search, Integer categoryId, Integer brandId, boolean lowStockOnly, Integer warehouseId) {
        List<Product> list = new ArrayList<>();
        StringBuilder query = new StringBuilder();
        if (warehouseId != null) {
            query.append("SELECT p.*, c.category_name, b.brand_name, ")
                 .append("COALESCE(iv.in_stock_qty, 0)   AS quantity, ")
                 .append("(COALESCE(iv.in_stock_qty, 0) + COALESCE(iv.quarantine_qty, 0)) AS physical_qty, ")
                 .append("COALESCE(iv.available_qty, 0)  AS available_qty, ")
                 .append("COALESCE(iv.available_new_qty, 0)  AS available_new_qty, ")
                 .append("COALESCE(iv.available_used_qty, 0)  AS available_used_qty, ")
                 .append("COALESCE(iv.reserved_qty, 0)   AS reserved_qty, ")
                 .append("COALESCE(iv.reserved_new_qty, 0)   AS reserved_new_qty, ")
                 .append("COALESCE(iv.reserved_used_qty, 0)   AS reserved_used_qty, ")
                 .append("COALESCE(iv.quarantine_qty, 0) AS damaged_qty ")
                 .append("FROM Products p ")
                 .append("LEFT JOIN Categories c ON p.category_id = c.id ")
                 .append("LEFT JOIN Brands b ON p.brand_id = b.id ")
                 .append("LEFT JOIN Inventory_Available iv ON iv.product_id = p.id AND iv.warehouse_id = ? ")
                 .append("WHERE 1=1");
        } else {
            query.append("SELECT p.*, c.category_name, b.brand_name, ")
                 .append("COALESCE((SELECT SUM(in_stock_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS quantity, ")
                 .append("COALESCE((SELECT SUM(in_stock_qty + quarantine_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS physical_qty, ")
                 .append("COALESCE((SELECT SUM(available_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_qty, ")
                 .append("COALESCE((SELECT SUM(available_new_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_new_qty, ")
                 .append("COALESCE((SELECT SUM(available_used_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_used_qty, ")
                 .append("COALESCE((SELECT SUM(reserved_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_qty, ")
                 .append("COALESCE((SELECT SUM(reserved_new_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_new_qty, ")
                 .append("COALESCE((SELECT SUM(reserved_used_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_used_qty, ")
                 .append("COALESCE((SELECT SUM(quarantine_qty)FROM Inventory_Available WHERE product_id = p.id), 0) AS damaged_qty ")
                 .append("FROM Products p ")
                 .append("LEFT JOIN Categories c ON p.category_id = c.id ")
                 .append("LEFT JOIN Brands b ON p.brand_id = b.id ")
                 .append("WHERE 1=1");
        }

        List<Object> params = new ArrayList<>();
        if (warehouseId != null) {
            params.add(warehouseId);
        }

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
            if (warehouseId != null) {
                query.append(" AND COALESCE(iv.in_stock_qty, 0) < p.min_stock");
            } else {
                query.append(" AND COALESCE((SELECT SUM(in_stock_qty) FROM Inventory_Available WHERE product_id = p.id), 0) < p.min_stock");
            }
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
        return getProductById(id, null);
    }

    public Product getProductById(int id, Integer warehouseId) {
        // Dùng VIEW Inventory_Available để tính tồn kho chính xác (tự động trừ reserved)
        String query;
        if (warehouseId != null) {
            query = "SELECT p.*, c.category_name, b.brand_name, "
                  + "COALESCE(iv.in_stock_qty, 0)   AS quantity, "
                  + "(COALESCE(iv.in_stock_qty, 0) + COALESCE(iv.quarantine_qty, 0)) AS physical_qty, "
                  + "COALESCE(iv.available_qty, 0)  AS available_qty, "
                  + "COALESCE(iv.available_new_qty, 0)  AS available_new_qty, "
                  + "COALESCE(iv.available_used_qty, 0)  AS available_used_qty, "
                  + "COALESCE(iv.reserved_qty, 0)   AS reserved_qty, "
                  + "COALESCE(iv.reserved_new_qty, 0)   AS reserved_new_qty, "
                  + "COALESCE(iv.reserved_used_qty, 0)   AS reserved_used_qty, "
                  + "COALESCE(iv.quarantine_qty, 0) AS damaged_qty "
                  + "FROM Products p "
                  + "LEFT JOIN Categories c ON p.category_id = c.id "
                  + "LEFT JOIN Brands b ON p.brand_id = b.id "
                  + "LEFT JOIN Inventory_Available iv ON iv.product_id = p.id AND iv.warehouse_id = ? "
                  + "WHERE p.id = ?";
        } else {
            // Tổng toàn hệ thống (cộng tất cả kho)
            query = "SELECT p.*, c.category_name, b.brand_name, "
                  + "COALESCE((SELECT SUM(in_stock_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS quantity, "
                  + "COALESCE((SELECT SUM(in_stock_qty + quarantine_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS physical_qty, "
                  + "COALESCE((SELECT SUM(available_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_qty, "
                  + "COALESCE((SELECT SUM(available_new_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_new_qty, "
                  + "COALESCE((SELECT SUM(available_used_qty) FROM Inventory_Available WHERE product_id = p.id), 0) AS available_used_qty, "
                  + "COALESCE((SELECT SUM(reserved_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_qty, "
                  + "COALESCE((SELECT SUM(reserved_new_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_new_qty, "
                  + "COALESCE((SELECT SUM(reserved_used_qty)  FROM Inventory_Available WHERE product_id = p.id), 0) AS reserved_used_qty, "
                  + "COALESCE((SELECT SUM(quarantine_qty)FROM Inventory_Available WHERE product_id = p.id), 0) AS damaged_qty "
                  + "FROM Products p "
                  + "LEFT JOIN Categories c ON p.category_id = c.id "
                  + "LEFT JOIN Brands b ON p.brand_id = b.id "
                  + "WHERE p.id = ?";
        }
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            if (warehouseId != null) {
                ps.setInt(1, warehouseId);
                ps.setInt(2, id);
            } else {
                ps.setInt(1, id);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Product p = mapResultSetToProduct(rs);
                    if (p != null) {
                        p.setSpecifications(getSpecificationsByProductId(p.getId()));
                    }
                    return p;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<ProductSpecification> getSpecificationsByProductId(int productId) {
        List<ProductSpecification> specs = new ArrayList<>();
        String query = "SELECT * FROM Product_Specifications WHERE product_id = ?";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    specs.add(new ProductSpecification(
                        rs.getInt("id"),
                        rs.getInt("product_id"),
                        rs.getString("spec_key"),
                        rs.getString("spec_value")
                    ));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return specs;
    }

    /** Lấy nhanh available_qty cho 1 (sản phẩm, kho) — dùng cho validate Servlet. */
    public int getAvailableQty(int productId, int warehouseId) {
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT available_qty FROM Inventory_Available WHERE product_id = ? AND warehouse_id = ?")) {
            ps.setInt(1, productId);
            ps.setInt(2, warehouseId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("available_qty");
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    public boolean addProduct(Product p) {
        String insertProd = "INSERT INTO Products (product_name, sku, unit, min_stock, average_cost, status, category_id, brand_id) "
                          + "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        String insertInv = "INSERT INTO Inventories (warehouse_id, product_id, quantity, quarantine_quantity) SELECT id, ?, 0, 0 FROM Warehouses";
        
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
                ps.setDouble(5, p.getAverageCost());
                ps.setBoolean(6, p.isStatus());
                
                if (p.getCategoryId() != null && p.getCategoryId() > 0) {
                    ps.setInt(7, p.getCategoryId());
                } else {
                    ps.setNull(7, java.sql.Types.INTEGER);
                }
                
                if (p.getBrandId() != null && p.getBrandId() > 0) {
                    ps.setInt(8, p.getBrandId());
                } else {
                    ps.setNull(8, java.sql.Types.INTEGER);
                }
                
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

                // Insert specs
                if (p.getSpecifications() != null && !p.getSpecifications().isEmpty()) {
                    String insertSpec = "INSERT INTO Product_Specifications (product_id, spec_key, spec_value) VALUES (?, ?, ?)";
                    try (PreparedStatement psSpec = conn.prepareStatement(insertSpec)) {
                        for (ProductSpecification spec : p.getSpecifications()) {
                            psSpec.setInt(1, productId);
                            psSpec.setString(2, spec.getSpecKey());
                            psSpec.setString(3, spec.getSpecValue());
                            psSpec.addBatch();
                        }
                        psSpec.executeBatch();
                    }
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
        String query = "UPDATE Products SET product_name = ?, sku = ?, unit = ?, min_stock = ?, "
                     + "category_id = ?, brand_id = ? "
                     + "WHERE id = ?";
        Connection conn = null;
        try {
            conn = DBUtils.getConnection();
            conn.setAutoCommit(false); // start transaction
 
            try (PreparedStatement ps = conn.prepareStatement(query)) {
                ps.setString(1, p.getProductName());
                ps.setString(2, p.getSku());
                ps.setString(3, p.getUnit());
                ps.setInt(4, p.getMinStock());
                
                if (p.getCategoryId() != null && p.getCategoryId() > 0) {
                    ps.setInt(5, p.getCategoryId());
                } else {
                    ps.setNull(5, java.sql.Types.INTEGER);
                }
                
                if (p.getBrandId() != null && p.getBrandId() > 0) {
                    ps.setInt(6, p.getBrandId());
                } else {
                    ps.setNull(6, java.sql.Types.INTEGER);
                }
                
                ps.setInt(7, p.getId());
                ps.executeUpdate();
            }

            // Delete old specs
            String deleteSpecs = "DELETE FROM Product_Specifications WHERE product_id = ?";
            try (PreparedStatement psDel = conn.prepareStatement(deleteSpecs)) {
                psDel.setInt(1, p.getId());
                psDel.executeUpdate();
            }

            // Insert new specs
            if (p.getSpecifications() != null && !p.getSpecifications().isEmpty()) {
                String insertSpec = "INSERT INTO Product_Specifications (product_id, spec_key, spec_value) VALUES (?, ?, ?)";
                try (PreparedStatement psSpec = conn.prepareStatement(insertSpec)) {
                    for (ProductSpecification spec : p.getSpecifications()) {
                        psSpec.setInt(1, p.getId());
                        psSpec.setString(2, spec.getSpecKey());
                        psSpec.setString(3, spec.getSpecValue());
                        psSpec.addBatch();
                    }
                    psSpec.executeBatch();
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

    public List<WarehouseStockBreakdown> getWarehouseStockBreakdown(int productId) {
        List<WarehouseStockBreakdown> list = new ArrayList<>();
        String query = "SELECT w.id AS warehouse_id, w.warehouse_name, "
                     + "COALESCE((SELECT quantity + quarantine_quantity FROM Inventories WHERE product_id = ? AND warehouse_id = w.id), 0) AS physical_qty, "
                     + "(SELECT COUNT(*) FROM Product_Items WHERE product_id = ? AND warehouse_id = w.id AND status = 'IN_STOCK' AND item_condition != 'DAMAGED') AS available_qty, "
                     + "(SELECT COUNT(*) FROM Product_Items WHERE product_id = ? AND warehouse_id = w.id AND status = 'IN_TRANSIT') AS reserved_qty, "
                     + "(SELECT COUNT(*) FROM Product_Items WHERE product_id = ? AND warehouse_id = w.id AND (status = 'DAMAGED' OR item_condition = 'DAMAGED')) AS damaged_qty "
                     + "FROM Warehouses w "
                     + "WHERE w.status = true "
                     + "ORDER BY w.warehouse_name ASC";
        try (Connection conn = DBUtils.getConnection();
             PreparedStatement ps = conn.prepareStatement(query)) {
            ps.setInt(1, productId);
            ps.setInt(2, productId);
            ps.setInt(3, productId);
            ps.setInt(4, productId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    WarehouseStockBreakdown b = new WarehouseStockBreakdown();
                    b.setWarehouseId(rs.getInt("warehouse_id"));
                    b.setWarehouseName(rs.getString("warehouse_name"));
                    b.setPhysicalQty(rs.getInt("physical_qty"));
                    b.setAvailableQty(rs.getInt("available_qty"));
                    b.setReservedQty(rs.getInt("reserved_qty"));
                    b.setDamagedQty(rs.getInt("damaged_qty"));
                    list.add(b);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private Product mapResultSetToProduct(ResultSet rs) throws Exception {
        Product p = new Product(
            rs.getInt("id"),
            rs.getString("product_name"),
            rs.getString("sku"),
            rs.getString("unit"),
            rs.getInt("min_stock"),
            rs.getDouble("average_cost"),
            rs.getBoolean("status"),
            (Integer) rs.getObject("category_id"),
            (Integer) rs.getObject("brand_id")
        );
        p.setCategoryName(rs.getString("category_name"));
        p.setBrandName(rs.getString("brand_name"));
        p.setQuantity(rs.getInt("quantity"));
        try {
            p.setPhysicalQty(rs.getInt("physical_qty"));
            p.setAvailableQty(rs.getInt("available_qty"));
            p.setAvailableNewQty(rs.getInt("available_new_qty"));
            p.setAvailableUsedQty(rs.getInt("available_used_qty"));
            p.setReservedQty(rs.getInt("reserved_qty"));
            p.setReservedNewQty(rs.getInt("reserved_new_qty"));
            p.setReservedUsedQty(rs.getInt("reserved_used_qty"));
            p.setDamagedQty(rs.getInt("damaged_qty"));
        } catch (Exception e) {
            // Ignore if columns not in projection
        }
        return p;
    }
}
