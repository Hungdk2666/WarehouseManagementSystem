package controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import service.UserService;
import model.User;

@WebServlet(name = "ChangePasswordServlet", urlPatterns = {"/change-password"})
public class ChangePasswordServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        if (session.getAttribute("user") == null) {
            response.sendRedirect("login");
            return;
        }
        request.getRequestDispatcher("change_password.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        if (loggedInUser == null) {
            response.sendRedirect("login");
            return;
        }
        
        String oldPassword = request.getParameter("oldPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        UserService userService = new UserService();
        User verifyUser = userService.login(loggedInUser.getUsername(), oldPassword);
        
        if (verifyUser == null) {
            request.setAttribute("error", "Incorrect old password!");
            request.getRequestDispatcher("change_password.jsp").forward(request, response);
            return;
        }
        
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "New passwords do not match!");
            request.getRequestDispatcher("change_password.jsp").forward(request, response);
            return;
        }
        
        boolean success = userService.updatePassword(loggedInUser.getId(), newPassword);
        
        if (success) {
            request.setAttribute("message", "Password changed successfully!");
            request.getRequestDispatcher("change_password.jsp").forward(request, response);
        } else {
            request.setAttribute("error", "Failed to change password. Try again.");
            request.getRequestDispatcher("change_password.jsp").forward(request, response);
        }
    }
}
