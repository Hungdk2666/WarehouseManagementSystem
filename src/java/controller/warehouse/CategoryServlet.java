package controller.warehouse;

import service.CategoryService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Category;
import model.User;

@WebServlet(name = "CategoryServlet", urlPatterns = {"/warehouse/category"})
public class CategoryServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // RBAC check: Read actions require CATEGORY_VIEW
        if (!loggedInUser.hasPermission("CATEGORY_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền xem ngành hàng.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        CategoryService dao = new CategoryService();

        switch (action) {
            case "list":
                List<Category> list = dao.getAllCategories();
                request.setAttribute("categoryList", list);
                request.getRequestDispatcher("/categories/category-list.jsp").forward(request, response);
                break;
            case "add":
                if (!loggedInUser.hasPermission("CATEGORY_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thêm ngành hàng.");
                    return;
                }
                request.getRequestDispatcher("/categories/category-add.jsp").forward(request, response);
                break;
            case "update":
                if (!loggedInUser.hasPermission("CATEGORY_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền sửa ngành hàng.");
                    return;
                }
                int updateId = Integer.parseInt(request.getParameter("id"));
                Category category = dao.getCategoryById(updateId);
                if (category == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/category?action=list");
                    return;
                }
                request.setAttribute("category", category);
                request.getRequestDispatcher("/categories/category-update.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/category?action=list");
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
            response.sendRedirect(request.getContextPath() + "/warehouse/category?action=list");
            return;
        }

        // RBAC check: Action-based permissions
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("CATEGORY_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thêm ngành hàng.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("CATEGORY_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền sửa ngành hàng.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("CATEGORY_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền bật/tắt ngành hàng.");
                return;
            }
        }

        CategoryService dao = new CategoryService();

        try {
            switch (action) {
                case "add":
                    String categoryName = request.getParameter("category_name");
                    String description = request.getParameter("description");
                    boolean status = Boolean.parseBoolean(request.getParameter("status"));
                    
                    Category newCat = new Category();
                    newCat.setCategoryName(categoryName);
                    newCat.setDescription(description);
                    newCat.setStatus(status);
                    
                    dao.addCategory(newCat);
                    break;
                case "update":
                    int id = Integer.parseInt(request.getParameter("id"));
                    String updateName = request.getParameter("category_name");
                    String updateDesc = request.getParameter("description");
                    
                    Category updateCat = new Category();
                    updateCat.setId(id);
                    updateCat.setCategoryName(updateName);
                    updateCat.setDescription(updateDesc);
                    
                    dao.updateCategory(updateCat);
                    break;
                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleCategoryStatus(toggleId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/category?action=list");
    }
}
