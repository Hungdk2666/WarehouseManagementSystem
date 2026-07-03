package controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import service.AuditLogService;
import service.UserService;
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

        String strengthError = SecurityUtils.validatePasswordStrength(newPassword);
        if (strengthError != null) {
            request.setAttribute("error", strengthError);
            request.getRequestDispatcher("reset_password.jsp").forward(request, response);
            return;
        }

        UserService userService = new UserService();
        boolean success = userService.updatePassword(userId, newPassword);

        if (success) {
            userService.clearResetCode(userId);
            session.invalidate();
            new AuditLogService().log(userId, "RESET_PASSWORD", "Password reset via OTP verification");
            request.setAttribute("message", "Password reset successfully! You can now login.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        } else {
            request.setAttribute("error", "Failed to reset password. Try again.");
            request.getRequestDispatcher("reset_password.jsp").forward(request, response);
        }
    }
}
