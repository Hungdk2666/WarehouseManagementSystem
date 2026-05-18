package controller;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;
import dao.UserDAO;

@WebServlet(name = "ProfileServlet", urlPatterns = {"/profile"})
public class ProfileServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");
        
        if (loggedInUser == null) {
            response.sendRedirect("login");
            return;
        }
        
        // Refresh user data from DB to ensure it's up to date
        UserDAO dao = new UserDAO();
        User freshUser = dao.getUserById(loggedInUser.getId());
        session.setAttribute("user", freshUser);
        
        request.getRequestDispatcher("profile.jsp").forward(request, response);
    }
}
