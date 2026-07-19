package controller.admin;

import service.RoleService;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.Permission;
import model.Role;
import model.User;
import service.AuditLogService;
import service.UserService;

@WebServlet(name = "AdminRoleServlet", urlPatterns = {"/admin/role"})
public class RoleServlet extends HttpServlet {

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

        if ("list".equals(action) || "permissions".equals(action)) {
            if (!loggedInUser.hasPermission("ROLE_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền xem vai trò.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("ROLE_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền sửa vai trò.");
                return;
            }
        }

        RoleService dao = new RoleService();

        switch (action) {
            case "list":
                List<Role> list = dao.getAllRoles();
                request.setAttribute("roleList", list);
                request.getRequestDispatcher("/admin/role-list.jsp").forward(request, response);
                break;
            case "update":
                int idUpdate = Integer.parseInt(request.getParameter("id"));
                Role roleUpdate = dao.getRoleById(idUpdate);
                request.setAttribute("roleInfo", roleUpdate);
                request.getRequestDispatcher("/admin/role-update.jsp").forward(request, response);
                break;
            case "permissions":
                int idPerm = Integer.parseInt(request.getParameter("id"));
                Role rolePerm = dao.getRoleById(idPerm);
                List<Permission> allPerms = dao.getAllPermissions();
                List<Integer> assignedPerms = dao.getPermissionsByRoleId(idPerm);

                request.setAttribute("roleInfo", rolePerm);
                request.setAttribute("allPerms", allPerms);
                request.setAttribute("assignedPerms", assignedPerms);

                request.getRequestDispatcher("/admin/role-permissions.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/admin/role?action=list");
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
            response.sendRedirect(request.getContextPath() + "/admin/role?action=list");
            return;
        }

        if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("ROLE_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền sửa vai trò.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("ROLE_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền bật/tắt vai trò.");
                return;
            }
        } else if ("addRole".equals(action)) {
            if (!loggedInUser.hasPermission("ROLE_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền thêm vai trò.");
                return;
            }
        } else if ("permissions".equals(action)) {
            if (!loggedInUser.hasPermission("ROLE_ASSIGN")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "Bạn không có quyền phân quyền.");
                return;
            }
        }

        RoleService dao = new RoleService();
        AuditLogService auditLog = new AuditLogService();

        try {
            switch (action) {
                case "update": {
                    int updateId = Integer.parseInt(request.getParameter("id"));
                    String updateRoleName = request.getParameter("role_name");

                    Role updateRole = new Role();
                    updateRole.setId(updateId);
                    updateRole.setRoleName(updateRoleName);

                    dao.updateRole(updateRole);
                    auditLog.log(loggedInUser.getId(), "ROLE_UPDATE", "Updated role ID " + updateId + " name to: " + updateRoleName);
                    break;
                }
                case "toggle": {
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    // Chặn TẮT một vai trò khi vẫn còn người dùng đang hoạt động mang vai trò đó.
                    Role toggleRole = dao.getRoleById(toggleId);
                    if (toggleRole != null && toggleRole.isStatus()) {
                        int activeCount = new UserService().countActiveUsersByRoleId(toggleId);
                        if (activeCount > 0) {
                            response.sendRedirect(request.getContextPath()
                                    + "/admin/role?action=list&error=RoleInUse&count=" + activeCount);
                            return;
                        }
                    }
                    dao.toggleRoleStatus(toggleId);
                    auditLog.log(loggedInUser.getId(), "ROLE_TOGGLE", "Toggled status of role ID " + toggleId);
                    break;
                }
                case "permissions": {
                    int roleId = Integer.parseInt(request.getParameter("id"));
                    String[] selectedPerms = request.getParameterValues("permissions");

                    if (roleId == 1 && selectedPerms != null) {
                        java.util.List<String> filtered = new java.util.ArrayList<>();
                        for (String pIdStr : selectedPerms) {
                            int pId = Integer.parseInt(pIdStr);
                            if ((pId >= 1 && pId <= 10) || pId == 75) {
                                filtered.add(pIdStr);
                            }
                        }
                        selectedPerms = filtered.toArray(new String[0]);
                    }

                    dao.updateRolePermissions(roleId, selectedPerms);
                    int permCount = (selectedPerms != null) ? selectedPerms.length : 0;
                    auditLog.log(loggedInUser.getId(), "ROLE_PERMISSIONS", "Updated permissions for role ID " + roleId + " (" + permCount + " permissions assigned)");
                    break;
                }
                case "addRole": {
                    String roleName = request.getParameter("role_name");
                    boolean roleStatus = "true".equalsIgnoreCase(request.getParameter("status"));
                    dao.addRole(roleName, roleStatus);
                    auditLog.log(loggedInUser.getId(), "ROLE_ADD", "Created new role: " + roleName);
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/admin/role?action=list");
    }
}
