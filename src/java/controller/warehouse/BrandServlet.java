package controller.warehouse;

import dao.BrandDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Brand;
import model.User;

@WebServlet(name = "BrandServlet", urlPatterns = {"/warehouse/brand"})
public class BrandServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // RBAC check: Read actions require BRAND_VIEW
        if (!loggedInUser.hasPermission("BRAND_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view brands.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        BrandDAO dao = new BrandDAO();

        switch (action) {
            case "list":
                List<Brand> list = dao.getAllBrands();
                request.setAttribute("brandList", list);
                request.getRequestDispatcher("/brands/brand-list.jsp").forward(request, response);
                break;
            case "add":
                if (!loggedInUser.hasPermission("BRAND_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add brands.");
                    return;
                }
                request.getRequestDispatcher("/brands/brand-add.jsp").forward(request, response);
                break;
            case "update":
                if (!loggedInUser.hasPermission("BRAND_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to modify brands.");
                    return;
                }
                int updateId = Integer.parseInt(request.getParameter("id"));
                Brand brand = dao.getBrandById(updateId);
                if (brand == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/brand?action=list");
                    return;
                }
                request.setAttribute("brand", brand);
                request.getRequestDispatcher("/brands/brand-update.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/brand?action=list");
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
            response.sendRedirect(request.getContextPath() + "/warehouse/brand?action=list");
            return;
        }

        // RBAC check: Action-based permissions
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("BRAND_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add brands.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("BRAND_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to modify brands.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("BRAND_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to enable/disable brands.");
                return;
            }
        }

        BrandDAO dao = new BrandDAO();

        try {
            switch (action) {
                case "add":
                    String brandName = request.getParameter("brand_name");
                    String description = request.getParameter("description");
                    boolean status = Boolean.parseBoolean(request.getParameter("status"));
                    
                    Brand newBrand = new Brand();
                    newBrand.setBrandName(brandName);
                    newBrand.setDescription(description);
                    newBrand.setStatus(status);
                    
                    dao.addBrand(newBrand);
                    break;
                case "update":
                    int id = Integer.parseInt(request.getParameter("id"));
                    String updateName = request.getParameter("brand_name");
                    String updateDesc = request.getParameter("description");
                    
                    Brand updateBrand = new Brand();
                    updateBrand.setId(id);
                    updateBrand.setBrandName(updateName);
                    updateBrand.setDescription(updateDesc);
                    
                    dao.updateBrand(updateBrand);
                    break;
                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleBrandStatus(toggleId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/brand?action=list");
    }
}
