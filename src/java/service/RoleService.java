package service;

import dao.RoleDAO;
import java.util.List;
import model.*;

public class RoleService {
    private RoleDAO dao;

    public RoleService() {
        this.dao = new RoleDAO();
    }

    public List<Integer> getPermissionsByRoleId(int arg0) {
        return dao.getPermissionsByRoleId(arg0);
    }

    public boolean updateRolePermissions(int arg0, String[] arg1) {
        return dao.updateRolePermissions(arg0, arg1);
    }

    public List<Role> getAllRoles() {
        return dao.getAllRoles();
    }

    public Role getRoleById(int arg0) {
        return dao.getRoleById(arg0);
    }

    public boolean updateRole(Role arg0) {
        return dao.updateRole(arg0);
    }

    public boolean toggleRoleStatus(int arg0) {
        return dao.toggleRoleStatus(arg0);
    }

    public List<Permission> getAllPermissions() {
        return dao.getAllPermissions();
    }

    public boolean addRole(String arg0, boolean arg1) {
        return dao.addRole(arg0, arg1);
    }

}
