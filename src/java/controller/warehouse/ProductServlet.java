package controller.warehouse;

import dao.BrandDAO;
import dao.CategoryDAO;
import dao.ProductDAO;
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
import model.User;

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

        ProductDAO dao = new ProductDAO();
        CategoryDAO catDao = new CategoryDAO();
        BrandDAO brandDao = new BrandDAO();

        switch (action) {
            case "list":
                String search = request.getParameter("search");
                String catIdStr = request.getParameter("categoryId");
                String brandIdStr = request.getParameter("brandId");
                boolean lowStockOnly = "true".equals(request.getParameter("lowStock"));

                Integer catId = (catIdStr != null && !catIdStr.isEmpty()) ? Integer.parseInt(catIdStr) : null;
                Integer brandId = (brandIdStr != null && !brandIdStr.isEmpty()) ? Integer.parseInt(brandIdStr) : null;

                List<Product> products = dao.searchAndFilterProducts(search, catId, brandId, lowStockOnly);
                List<Category> categories = catDao.getAllCategories();
                List<Brand> brands = brandDao.getAllBrands();

                request.setAttribute("productList", products);
                request.setAttribute("categoryList", categories);
                request.setAttribute("brandList", brands);
                request.getRequestDispatcher("/products/product-list.jsp").forward(request, response);
                break;

            case "details":
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = dao.getProductById(id);
                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
                    return;
                }
                request.setAttribute("product", product);
                request.getRequestDispatcher("/products/product-detail.jsp").forward(request, response);
                break;

            case "add":
                // Write actions require PRODUCT_ADD
                if (!loggedInUser.hasPermission("PRODUCT_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add products.");
                    return;
                }
                List<Category> addCategories = catDao.getAllCategories();
                List<Brand> addBrands = brandDao.getAllBrands();
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
                List<Category> updateCategories = catDao.getAllCategories();
                List<Brand> updateBrands = brandDao.getAllBrands();
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

        ProductDAO dao = new ProductDAO();

        try {
            switch (action) {
                case "add":
                    String productName = request.getParameter("product_name");
                    String sku = request.getParameter("sku");
                    String unit = request.getParameter("unit");
                    int minStock = Integer.parseInt(request.getParameter("min_stock"));
                    double defaultCost = Double.parseDouble(request.getParameter("default_cost"));
                    
                    String catIdStr = request.getParameter("category_id");
                    String brandIdStr = request.getParameter("brand_id");
                    Integer categoryId = (catIdStr != null && !catIdStr.isEmpty()) ? Integer.parseInt(catIdStr) : null;
                    Integer brandId = (brandIdStr != null && !brandIdStr.isEmpty()) ? Integer.parseInt(brandIdStr) : null;
                    String specs = request.getParameter("technical_specifications");

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
                    newP.setDefaultCost(defaultCost);
                    newP.setAverageCost(defaultCost); // average cost initially is equal to default cost
                    newP.setStatus(true);
                    newP.setCategoryId(categoryId);
                    newP.setBrandId(brandId);
                    newP.setTechnicalSpecifications(specs);

                    dao.addProduct(newP);
                    break;

                case "update":
                    int id = Integer.parseInt(request.getParameter("id"));
                    String updateName = request.getParameter("product_name");
                    String updateSku = request.getParameter("sku");
                    String updateUnit = request.getParameter("unit");
                    int updateMinStock = Integer.parseInt(request.getParameter("min_stock"));
                    double updateDefaultCost = Double.parseDouble(request.getParameter("default_cost"));
                    
                    String updateCatIdStr = request.getParameter("category_id");
                    String updateBrandIdStr = request.getParameter("brand_id");
                    Integer updateCategoryId = (updateCatIdStr != null && !updateCatIdStr.isEmpty()) ? Integer.parseInt(updateCatIdStr) : null;
                    Integer updateBrandId = (updateBrandIdStr != null && !updateBrandIdStr.isEmpty()) ? Integer.parseInt(updateBrandIdStr) : null;
                    String updateSpecs = request.getParameter("technical_specifications");

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
                    updateP.setDefaultCost(updateDefaultCost);
                    updateP.setCategoryId(updateCategoryId);
                    updateP.setBrandId(updateBrandId);
                    updateP.setTechnicalSpecifications(updateSpecs);

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
