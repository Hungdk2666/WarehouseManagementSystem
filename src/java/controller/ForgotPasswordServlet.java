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

@WebServlet(name = "ForgotPasswordServlet", urlPatterns = {"/forgot-password"})
public class ForgotPasswordServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("forgot_password.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String email = request.getParameter("email");
        UserService userService = new UserService();
        User user = userService.getUserByEmail(email);
        
        if (user != null) {
            String resetCode = String.valueOf((int) (Math.random() * 900000) + 100000); // 6-digit code
            userService.setResetCode(user.getId(), resetCode);
            HttpSession session = request.getSession();
            session.setAttribute("resetEmail", user.getEmail());
            response.sendRedirect("verify_code.jsp");
        } else {
            request.setAttribute("error", "Email not found in our system!");
            request.getRequestDispatcher("forgot_password.jsp").forward(request, response);
        }
    }
}
