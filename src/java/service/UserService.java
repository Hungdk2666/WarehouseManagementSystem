package service;

import dao.UserDAO;
import java.sql.Timestamp;
import java.util.List;
import model.User;
import utils.SecurityUtils;

public class UserService {
    private UserDAO userDAO;

    public UserService() {
        this.userDAO = new UserDAO();
    }

    public User login(String username, String rawPassword) {
        User user = userDAO.getUserByUsername(username);
        if (user == null || !user.isStatus()) {
            return null;
        }
        if (!SecurityUtils.verifyPassword(rawPassword, user.getPassword())) {
            return null;
        }
        if (SecurityUtils.isLegacyHash(user.getPassword())) {
            String newHash = SecurityUtils.hashPassword(rawPassword);
            userDAO.updatePassword(user.getId(), newHash);
        }
        return user;
    }

    public User getUserByEmail(String email) {
        return userDAO.getUserByEmail(email);
    }

    public User getUserById(int id) {
        return userDAO.getUserById(id);
    }

    public boolean updatePassword(int userId, String rawNewPassword) {
        String hashedPassword = SecurityUtils.hashPassword(rawNewPassword);
        return userDAO.updatePassword(userId, hashedPassword);
    }

    public List<User> getAllUsers() {
        return userDAO.getAllUsers();
    }

    public List<User> searchAndFilterUsers(String search, String roleFilter) {
        return userDAO.searchAndFilterUsers(search, roleFilter);
    }

    public boolean addUser(User user, String rawPassword) {
        String hashedPassword = SecurityUtils.hashPassword(rawPassword);
        user.setPassword(hashedPassword);
        return userDAO.addUser(user);
    }

    public boolean updateUser(User user) {
        return userDAO.updateUser(user);
    }

    public boolean toggleUserStatus(int userId) {
        return userDAO.toggleUserStatus(userId);
    }

    public int countActiveUsersByRoleId(int roleId) {
        return userDAO.countActiveUsersByRoleId(roleId);
    }

    public boolean setResetCode(int userId, String code) {
        Timestamp expiresAt = new Timestamp(System.currentTimeMillis() + 10 * 60 * 1000);
        return userDAO.setResetCode(userId, code, expiresAt);
    }

    public User verifyResetCode(String email, String code) {
        User user = userDAO.verifyResetCode(email, code);
        if (user == null) {
            userDAO.incrementResetAttempts(email);
        }
        return user;
    }

    public void clearResetCode(int userId) {
        userDAO.clearResetCode(userId);
    }
}
