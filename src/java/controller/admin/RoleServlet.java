package controller.admin;

import dao.RoleDAO;
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
        } else if (loggedInUser.getRoleId() != 1){
            response.sendRedirect(request.getContextPath());
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        RoleDAO dao = new RoleDAO();

        switch (action) {
            case "list":
                List<Role> list = dao.getAllRoles();
                List<Permission> permList = dao.getAllPermissions();
                request.setAttribute("roleList", list);
                request.setAttribute("permissionList", permList);
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
        } else if (loggedInUser.getRoleId() != 1){
            response.sendRedirect(request.getContextPath());
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/admin/role?action=list");
            return;
        }

        RoleDAO dao = new RoleDAO();

        try {
            switch (action) {
                case "update":
                    int updateId = Integer.parseInt(request.getParameter("id"));
                    String updateRoleName = request.getParameter("role_name");
                    
                    Role updateRole = new Role();
                    updateRole.setId(updateId);
                    updateRole.setRoleName(updateRoleName);
                    
                    dao.updateRole(updateRole);
                    break;
                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleRoleStatus(toggleId);
                    break;
                case "permissions":
                    int roleId = Integer.parseInt(request.getParameter("id"));
                    String[] selectedPerms = request.getParameterValues("permissions");
                    
                    if (selectedPerms != null) {
                        java.util.List<String> filtered = new java.util.ArrayList<>();
                        for (String pIdStr : selectedPerms) {
                            int pId = Integer.parseInt(pIdStr);
                            if (roleId != 1 && pId != 1 && pId != 2 && pId != 3) {
                                filtered.add(pIdStr);
                            }
                        }
                        selectedPerms = filtered.toArray(new String[0]);
                    }
                    
                    dao.updateRolePermissions(roleId, selectedPerms);
                    break;
                case "addRole":
                    String roleName = request.getParameter("role_name");
                    boolean roleStatus = "true".equalsIgnoreCase(request.getParameter("status"));
                    dao.addRole(roleName, roleStatus);
                    break;
                case "addPermission":
                    String permName = request.getParameter("permission_name");
                    String permDesc = request.getParameter("description");
                    dao.addPermission(permName, permDesc);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.sendRedirect(request.getContextPath() + "/admin/role?action=list");
    }
}
