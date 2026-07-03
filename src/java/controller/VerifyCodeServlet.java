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

@WebServlet(name = "VerifyCodeServlet", urlPatterns = {"/verify-code"})
public class VerifyCodeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("verify_code.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String email = request.getParameter("email");
        String code = request.getParameter("code");

        UserService userService = new UserService();
        User user = userService.verifyResetCode(email, code);

        if (user != null) {
            HttpSession oldSession = request.getSession(false);
            if (oldSession != null) {
                oldSession.invalidate();
            }
            HttpSession session = request.getSession(true);
            session.setAttribute("resetUserId", user.getId());
            response.sendRedirect("reset_password.jsp");
        } else {
            request.setAttribute("error", "Invalid or expired reset code. The code expires after 10 minutes and you have 5 attempts.");
            request.getRequestDispatcher("verify_code.jsp").forward(request, response);
        }
    }
}
