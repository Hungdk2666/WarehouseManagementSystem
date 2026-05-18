package controller.admin;

import dao.UserDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import utils.SecurityUtils;

@WebServlet(name = "AdminUserServlet", urlPatterns = {"/admin/user"})
public class UserServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        // Authorization check (Admin only, role_id = 1)
        if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        UserDAO dao = new UserDAO();

        switch (action) {
            case "list":
                List<User> list = dao.getAllUsers();
                request.setAttribute("userList", list);
                request.getRequestDispatcher("/admin/user-list.jsp").forward(request, response);
                break;
            case "add":
                request.getRequestDispatcher("/admin/user-add.jsp").forward(request, response);
                break;
            case "info":
                int idInfo = Integer.parseInt(request.getParameter("id"));
                User userInfo = dao.getUserById(idInfo);
                request.setAttribute("userInfo", userInfo);
                request.getRequestDispatcher("/admin/user-info.jsp").forward(request, response);
                break;
            case "update":
                int idUpdate = Integer.parseInt(request.getParameter("id"));
                User userUpdate = dao.getUserById(idUpdate);
                request.setAttribute("userInfo", userUpdate);
                request.getRequestDispatcher("/admin/user-update.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        // Authorization check
        if (loggedInUser == null || loggedInUser.getRoleId() != 1) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
            return;
        }

        UserDAO dao = new UserDAO();

        try {
            switch (action) {
                case "add":
                    String username = request.getParameter("username");
                    String email = request.getParameter("email");
                    String fullName = request.getParameter("full_name");
                    int roleId = Integer.parseInt(request.getParameter("role_id"));
                    
                    User newUser = new User();
                    newUser.setUsername(username);
                    newUser.setEmail(email);
                    newUser.setFullName(fullName);
                    newUser.setRoleId(roleId);
                    newUser.setStatus(true); // default active
                    newUser.setPassword(SecurityUtils.hashSHA256("123456")); // Hashed immediately
                    
                    dao.addUser(newUser);
                    break;
                case "update":
                    int updateId = Integer.parseInt(request.getParameter("id"));
                    String updateEmail = request.getParameter("email");
                    String updateFullName = request.getParameter("full_name");
                    int updateRoleId = Integer.parseInt(request.getParameter("role_id"));
                    
                    User updateUser = new User();
                    updateUser.setId(updateId);
                    updateUser.setEmail(updateEmail);
                    updateUser.setFullName(updateFullName);
                    updateUser.setRoleId(updateRoleId);
                    
                    dao.updateUser(updateUser);
                    break;
                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleUserStatus(toggleId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
    }
}
