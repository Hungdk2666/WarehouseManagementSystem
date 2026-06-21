package service;

import dao.UserDAO;
import java.util.List;
import model.User;
import utils.SecurityUtils;

public class UserService {
    private UserDAO userDAO;

    public UserService() {
        this.userDAO = new UserDAO();
    }

    public User login(String username, String rawPassword) {
        String hashedPassword = SecurityUtils.hashSHA256(rawPassword);
        return userDAO.login(username, hashedPassword);
    }

    public User getUserByEmail(String email) {
        return userDAO.getUserByEmail(email);
    }

    public User getUserById(int id) {
        return userDAO.getUserById(id);
    }

    public boolean updatePassword(int userId, String rawNewPassword) {
        String hashedPassword = SecurityUtils.hashSHA256(rawNewPassword);
        return userDAO.updatePassword(userId, hashedPassword);
    }

    public List<User> getAllUsers() {
        return userDAO.getAllUsers();
    }

    public List<User> searchAndFilterUsers(String search, String roleFilter) {
        return userDAO.searchAndFilterUsers(search, roleFilter);
    }

    public boolean addUser(User user, String rawPassword) {
        String hashedPassword = SecurityUtils.hashSHA256(rawPassword);
        user.setPassword(hashedPassword);
        return userDAO.addUser(user);
    }

    public boolean updateUser(User user) {
        return userDAO.updateUser(user);
    }

    public boolean toggleUserStatus(int userId) {
        return userDAO.toggleUserStatus(userId);
    }

    public boolean setResetCode(int userId, String code) {
        return userDAO.setResetCode(userId, code);
    }

    public User verifyResetCode(String email, String code) {
        return userDAO.verifyResetCode(email, code);
    }
}
