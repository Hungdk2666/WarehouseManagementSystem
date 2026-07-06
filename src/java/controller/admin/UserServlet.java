package controller.admin;

import service.UserService;
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
import service.AuditLogService;
import service.RoleService;

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

        UserService dao = new UserService();
        RoleService roleService = new RoleService();

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
                List<Role> roleList = roleService.getAllRoles();
                request.setAttribute("userList", list);
                request.setAttribute("roleList", roleList);
                request.getRequestDispatcher("/admin/user-list.jsp").forward(request, response);
                break;
            case "add":
                List<Role> addRoleList = roleService.getAllRoles();
                request.setAttribute("roleList", addRoleList);
                request.setAttribute("warehouseList", new service.WarehouseService().getAllActiveWarehouses());
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
                List<Role> updateRoleList = roleService.getAllRoles();
                request.setAttribute("roleList", updateRoleList);
                request.setAttribute("warehouseList", new service.WarehouseService().getAllActiveWarehouses());
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

        UserService dao = new UserService();
        AuditLogService auditLog = new AuditLogService();

        try {
            switch (action) {
                case "add": {
                    String username = request.getParameter("username");
                    String email = request.getParameter("email");
                    String fullName = request.getParameter("full_name");
                    int roleId = Integer.parseInt(request.getParameter("role_id"));
                    String warehouseIdStr = request.getParameter("warehouse_id");
                    Integer warehouseId = (warehouseIdStr != null && !warehouseIdStr.trim().isEmpty()) ? Integer.parseInt(warehouseIdStr) : null;

                    User newUser = new User();
                    newUser.setUsername(username);
                    newUser.setEmail(email);
                    newUser.setFullName(fullName);
                    newUser.setRoleId(roleId);
                    newUser.setWarehouseId(warehouseId);
                    newUser.setStatus(true);
                    dao.addUser(newUser, "123456");
                    auditLog.log(loggedInUser.getId(), "USER_ADD", "Created user: " + username + " (role_id=" + roleId + ")");
                    break;
                }
                case "update": {
                    int updateId = Integer.parseInt(request.getParameter("id"));
                    String updateEmail = request.getParameter("email");
                    String updateFullName = request.getParameter("full_name");
                    int updateRoleId = Integer.parseInt(request.getParameter("role_id"));
                    String updateWarehouseIdStr = request.getParameter("warehouse_id");
                    Integer updateWarehouseId = (updateWarehouseIdStr != null && !updateWarehouseIdStr.trim().isEmpty()) ? Integer.parseInt(updateWarehouseIdStr) : null;

                    if (updateId == loggedInUser.getId()) {
                        User currentUser = dao.getUserById(updateId);
                        if (currentUser != null && currentUser.getRoleId() != updateRoleId) {
                            request.getSession().setAttribute("errorMessage", "You cannot change your own role.");
                            response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
                            return;
                        }
                    }

                    User oldUser = dao.getUserById(updateId);

                    User updateUser = new User();
                    updateUser.setId(updateId);
                    updateUser.setEmail(updateEmail);
                    updateUser.setFullName(updateFullName);
                    updateUser.setRoleId(updateRoleId);
                    updateUser.setWarehouseId(updateWarehouseId);

                    dao.updateUser(updateUser);

                    StringBuilder details = new StringBuilder("Updated user ID " + updateId);
                    if (oldUser != null && oldUser.getRoleId() != updateRoleId) {
                        details.append(" | Role changed from ").append(oldUser.getRoleId()).append(" to ").append(updateRoleId);
                    }
                    auditLog.log(loggedInUser.getId(), "USER_UPDATE", details.toString());
                    break;
                }
                case "toggle": {
                    int toggleId = Integer.parseInt(request.getParameter("id"));

                    User targetUser = dao.getUserById(toggleId);
                    if (targetUser != null && targetUser.isStatus()) {
                        if (toggleId == loggedInUser.getId()) {
                            request.getSession().setAttribute("errorMessage", "You cannot deactivate your own account.");
                            response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
                            return;
                        }
                        int activeCount = dao.countActiveUsersByRoleId(targetUser.getRoleId());
                        if (activeCount <= 1) {
                            request.getSession().setAttribute("errorMessage", "Cannot deactivate the last active user with this role.");
                            response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
                            return;
                        }
                    }

                    dao.toggleUserStatus(toggleId);
                    String statusAction = (targetUser != null && targetUser.isStatus()) ? "DEACTIVATED" : "ACTIVATED";
                    auditLog.log(loggedInUser.getId(), "USER_TOGGLE", statusAction + " user ID " + toggleId);
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/admin/user?action=list");
    }
}
