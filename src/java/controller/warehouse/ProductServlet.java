 package controller.warehouse;

import service.BrandService;
import service.CategoryService;
import service.ProductService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Brand;
import model.Category;
import model.Product;
import model.ProductItem;
import model.ProductSpecification;
import model.User;
import service.ProductItemService;
import service.WarehouseService;
import model.WarehouseStockBreakdown;

@WebServlet(name = "ProductServlet", urlPatterns = {"/warehouse/product"})
public class ProductServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // RBAC check: read actions require PRODUCT_VIEW
        if (!loggedInUser.hasPermission("PRODUCT_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view products.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        ProductService dao = new ProductService();
        CategoryService catService = new CategoryService();
        BrandService brandService = new BrandService();

        switch (action) {
            case "list":
                String search = request.getParameter("search");
                String catIdStr = request.getParameter("categoryId");
                String brandIdStr = request.getParameter("brandId");
                boolean lowStockOnly = "true".equals(request.getParameter("lowStock"));

                Integer catId = (catIdStr != null && !catIdStr.isEmpty()) ? Integer.parseInt(catIdStr) : null;
                Integer brandId = (brandIdStr != null && !brandIdStr.isEmpty()) ? Integer.parseInt(brandIdStr) : null;

                Integer userWarehouseId = loggedInUser.getWarehouseId();
                if (userWarehouseId == null) {
                    String filterWhIdStr = request.getParameter("warehouseId");
                    if (filterWhIdStr != null && !filterWhIdStr.isEmpty()) {
                        try {
                            userWarehouseId = Integer.parseInt(filterWhIdStr);
                        } catch (NumberFormatException e) {
                            // ignore
                        }
                    }
                }

                List<Product> products = dao.searchAndFilterProducts(search, catId, brandId, lowStockOnly, userWarehouseId);
                List<Category> categories = catService.getAllCategories();
                List<Brand> brands = brandService.getAllBrands();

                if (loggedInUser.getWarehouseId() == null) {
                    WarehouseService whService = new WarehouseService();
                    request.setAttribute("warehouseList", whService.getAllActiveWarehouses());
                }

                request.setAttribute("productList", products);
                request.setAttribute("categoryList", categories);
                request.setAttribute("brandList", brands);
                request.getRequestDispatcher("/products/product-list.jsp").forward(request, response);
                break;

            case "details":
                int id = Integer.parseInt(request.getParameter("id"));
                Integer detailWarehouseId = loggedInUser.getWarehouseId();
                Product product = dao.getProductById(id, detailWarehouseId);
                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
                    return;
                }
                ProductItemService itemService = new ProductItemService();
                List<ProductItem> inStockSerials = itemService.getInStockItemsByProductId(id, detailWarehouseId);
                
                if (loggedInUser.getWarehouseId() == null) {
                    List<WarehouseStockBreakdown> breakdown = dao.getWarehouseStockBreakdown(id);
                    request.setAttribute("warehouseBreakdown", breakdown);
                }

                request.setAttribute("product", product);
                request.setAttribute("inStockSerials", inStockSerials);
                request.getRequestDispatcher("/products/product-detail.jsp").forward(request, response);
                break;

            case "add":
                // Write actions require PRODUCT_ADD
                if (!loggedInUser.hasPermission("PRODUCT_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add products.");
                    return;
                }
                List<Category> addCategories = catService.getAllCategories();
                List<Brand> addBrands = brandService.getAllBrands();
                request.setAttribute("categoryList", addCategories);
                request.setAttribute("brandList", addBrands);
                request.getRequestDispatcher("/products/product-add.jsp").forward(request, response);
                break;

            case "update":
                // Write actions require PRODUCT_EDIT
                if (!loggedInUser.hasPermission("PRODUCT_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to update products.");
                    return;
                }
                int updateId = Integer.parseInt(request.getParameter("id"));
                Product updateProd = dao.getProductById(updateId);
                if (updateProd == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
                    return;
                }
                List<Category> updateCategories = catService.getAllCategories();
                List<Brand> updateBrands = brandService.getAllBrands();
                request.setAttribute("product", updateProd);
                request.setAttribute("categoryList", updateCategories);
                request.setAttribute("brandList", updateBrands);
                request.getRequestDispatcher("/products/product-update.jsp").forward(request, response);
                break;

            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
            return;
        }

        // RBAC check: Action-based permissions
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("PRODUCT_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add products.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("PRODUCT_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to modify products.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("PRODUCT_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to enable/disable products.");
                return;
            }
        }

        ProductService dao = new ProductService();

        try {
            switch (action) {
                case "add":
                    String productName = request.getParameter("product_name");
                    String sku = request.getParameter("sku");
                    String unit = request.getParameter("unit");
                    int minStock = Integer.parseInt(request.getParameter("min_stock"));
                    
                    String catIdStr = request.getParameter("category_id");
                    String brandIdStr = request.getParameter("brand_id");
                    Integer categoryId = (catIdStr != null && !catIdStr.isEmpty()) ? Integer.parseInt(catIdStr) : null;
                    Integer brandId = (brandIdStr != null && !brandIdStr.isEmpty()) ? Integer.parseInt(brandIdStr) : null;
                    String[] specKeys = request.getParameterValues("spec_key");
                    String[] specValues = request.getParameterValues("spec_value");

                    // Validation checks
                    if (dao.isSkuExists(sku, 0)) {
                        request.setAttribute("error", "SKU unique constraint violated! Product SKU already exists.");
                        doGet(request, response); // re-populate and forward
                        return;
                    }

                    Product newP = new Product();
                    newP.setProductName(productName);
                    newP.setSku(sku);
                    newP.setUnit(unit);
                    newP.setMinStock(minStock);
                    newP.setAverageCost(0.0); // initially, new product average cost is 0.0
                    newP.setStatus(true);
                    newP.setCategoryId(categoryId);
                    newP.setBrandId(brandId);
                    
                    List<ProductSpecification> specsList = new java.util.ArrayList<>();
                    if (specKeys != null && specValues != null) {
                        for (int i = 0; i < specKeys.length; i++) {
                            String key = specKeys[i].trim();
                            String val = specValues[i].trim();
                            if (!key.isEmpty()) {
                                ProductSpecification spec = new ProductSpecification();
                                spec.setSpecKey(key);
                                spec.setSpecValue(val);
                                specsList.add(spec);
                            }
                        }
                    }
                    newP.setSpecifications(specsList);

                    dao.addProduct(newP);
                    break;

                case "update":
                    int id = Integer.parseInt(request.getParameter("id"));
                    String updateName = request.getParameter("product_name");
                    String updateSku = request.getParameter("sku");
                    String updateUnit = request.getParameter("unit");
                    int updateMinStock = Integer.parseInt(request.getParameter("min_stock"));
                    
                    String updateCatIdStr = request.getParameter("category_id");
                    String updateBrandIdStr = request.getParameter("brand_id");
                    Integer updateCategoryId = (updateCatIdStr != null && !updateCatIdStr.isEmpty()) ? Integer.parseInt(updateCatIdStr) : null;
                    Integer updateBrandId = (updateBrandIdStr != null && !updateBrandIdStr.isEmpty()) ? Integer.parseInt(updateBrandIdStr) : null;
                    String[] updateSpecKeys = request.getParameterValues("spec_key");
                    String[] updateSpecValues = request.getParameterValues("spec_value");

                    // Validation checks
                    if (dao.isSkuExists(updateSku, id)) {
                        request.setAttribute("error", "SKU unique constraint violated! Product SKU already exists.");
                        doGet(request, response); // re-populate and forward
                        return;
                    }

                    Product updateP = new Product();
                    updateP.setId(id);
                    updateP.setProductName(updateName);
                    updateP.setSku(updateSku);
                    updateP.setUnit(updateUnit);
                    updateP.setMinStock(updateMinStock);
                    updateP.setCategoryId(updateCategoryId);
                    updateP.setBrandId(updateBrandId);
                    
                    List<ProductSpecification> updateSpecsList = new java.util.ArrayList<>();
                    if (updateSpecKeys != null && updateSpecValues != null) {
                        for (int i = 0; i < updateSpecKeys.length; i++) {
                            String key = updateSpecKeys[i].trim();
                            String val = updateSpecValues[i].trim();
                            if (!key.isEmpty()) {
                                ProductSpecification spec = new ProductSpecification();
                                spec.setSpecKey(key);
                                spec.setSpecValue(val);
                                updateSpecsList.add(spec);
                            }
                        }
                    }
                    updateP.setSpecifications(updateSpecsList);

                    dao.updateProduct(updateP);
                    break;

                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleProductStatus(toggleId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
    }
}
