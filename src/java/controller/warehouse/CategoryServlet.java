package controller.warehouse;

import dao.CategoryDAO;
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

    private boolean canView(User user) {
        return user != null && user.hasPermission("category.view");
    }

    private boolean canAdd(User user) {
        return user != null && user.hasPermission("category.add");
    }

    private boolean canUpdate(User user) {
        return user != null && user.hasPermission("category.edit");
    }

    private boolean canToggle(User user) {
        return user != null && user.hasPermission("category.toggle");
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

        if (!canView(loggedInUser)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view categories.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        CategoryDAO dao = new CategoryDAO();

        switch (action) {
            case "list":
                List<Category> list = dao.getAllCategories();
                request.setAttribute("categoryList", list);
                request.getRequestDispatcher("/categories/category-list.jsp").forward(request, response);
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

        CategoryDAO dao = new CategoryDAO();

        try {
            switch (action) {
                case "add":
                    if (!canAdd(loggedInUser)) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add categories.");
                        return;
                    }
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
                    if (!canUpdate(loggedInUser)) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to update categories.");
                        return;
                    }
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
                    if (!canToggle(loggedInUser)) {
                        response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to change category status.");
                        return;
                    }
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
