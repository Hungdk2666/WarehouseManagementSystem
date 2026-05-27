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

    private boolean canView(User user) {
        return user != null && user.hasPermission("product.view");
    }

    private boolean canAdd(User user) {
        return user != null && user.hasPermission("product.add");
    }

    private boolean canUpdate(User user) {
        return user != null && user.hasPermission("product.edit");
    }

    private boolean canToggle(User user) {
        return user != null && user.hasPermission("product.toggle");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
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
                if (!canView(loggedInUser)) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view products.");
                    return;
                }
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
                if (!canView(loggedInUser)) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view product details.");
                    return;
                }
                int id = Integer.parseInt(request.getParameter("id"));
                Product product = dao.getProductById(id);
                if (product == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/product?action=list");
                    return;
                }
                request.setAttribute("product", product);
                request.getRequestDispatcher("/products/product-detail.jsp").forward(request, response);
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

        ProductDAO dao = new ProductDAO();

        try {
            switch (action) {
                
                case "toggle":
                    if (!canToggle(loggedInUser)) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to change product status.");
                        return;
                    }
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
