package controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import dao.UserDAO;
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
        
        UserDAO dao = new UserDAO();
        User user = dao.verifyResetCode(email, code);
        
        if (user != null) {
            HttpSession session = request.getSession();
            session.setAttribute("resetUserId", user.getId());
            response.sendRedirect("reset_password.jsp");
        } else {
            request.setAttribute("error", "Invalid email or reset code. Please ask Admin for the correct code.");
            request.getRequestDispatcher("verify_code.jsp").forward(request, response);
        }
    }
}
