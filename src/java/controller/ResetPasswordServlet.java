package controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import dao.UserDAO;
import utils.SecurityUtils;

@WebServlet(name = "ResetPasswordServlet", urlPatterns = {"/reset-password"})
public class ResetPasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("resetUserId");
        
        if (userId == null) {
            response.sendRedirect("forgot-password");
            return;
        }
        
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");
        
        if (!newPassword.equals(confirmPassword)) {
            request.setAttribute("error", "Passwords do not match!");
            request.getRequestDispatcher("reset_password.jsp").forward(request, response);
            return;
        }
        
        String hashedPass = SecurityUtils.hashSHA256(newPassword);
        UserDAO dao = new UserDAO();
        boolean success = dao.updatePassword(userId, hashedPass);
        
        if (success) {
            session.removeAttribute("resetUserId");
            request.setAttribute("message", "Password reset successfully! You can now login.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        } else {
            request.setAttribute("error", "Failed to reset password. Try again.");
            request.getRequestDispatcher("reset_password.jsp").forward(request, response);
        }
    }
}
