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
import model.Role;
import dao.RoleDAO;
import utils.SecurityUtils;

@WebServlet(name = "AdminUserServlet", urlPatterns = {"/admin/user"})
public class UserServlet extends HttpServlet {

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

        // Action-based permission checks
        if ("list".equals(action) || "info".equals(action)) {
            if (!loggedInUser.hasPermission("USER_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view users.");
                return;
            }
        } else if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("USER_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add users.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("USER_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to edit users.");
                return;
            }
        }

        UserDAO dao = new UserDAO();
        RoleDAO roleDao = new RoleDAO();

        switch (action) {
            case "list":
                String search = request.getParameter("search");
                String roleFilter = request.getParameter("roleFilter");
                List<User> list;
                if ((search != null && !search.trim().isEmpty()) || (roleFilter != null && !roleFilter.trim().isEmpty())) {
                    list = dao.searchAndFilterUsers(search, roleFilter);
                } else {
                    list = dao.getAllUsers();
                }
                List<Role> roleList = roleDao.getAllRoles();
                request.setAttribute("userList", list);
                request.setAttribute("roleList", roleList);
                request.getRequestDispatcher("/admin/user-list.jsp").forward(request, response);
                break;
            case "add":
                List<Role> addRoleList = roleDao.getAllRoles();
                request.setAttribute("roleList", addRoleList);
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
                List<Role> updateRoleList = roleDao.getAllRoles();
                request.setAttribute("roleList", updateRoleList);
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
        
        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
            return;
        }

        // Action-based permission checks
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("USER_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add users.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("USER_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to edit users.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("USER_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to disable/enable users.");
                return;
            }
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
