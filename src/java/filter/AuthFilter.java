package filter;

import dao.UserDAO;
import java.io.IOException;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.User;

@WebFilter(urlPatterns = {"/*"})
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        String uri = httpRequest.getRequestURI();
        
        // Bỏ qua các file tĩnh (css, js, images...)
        if (uri.matches(".*\\.(css|js|png|jpg|jpeg|gif|ico|woff|woff2|ttf|svg)$")) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = httpRequest.getSession(false);
        if (session != null && session.getAttribute("user") != null) {
            User loggedInUser = (User) session.getAttribute("user");
            UserDAO dao = new UserDAO();
            User latestUser = dao.getUserById(loggedInUser.getId());
            
            if (latestUser != null) {
                // Nếu tài khoản bị vô hiệu hóa, tự động đăng xuất
                if (!latestUser.isStatus()) {
                    session.invalidate();
                    if (!uri.endsWith("/login")) {
                        httpResponse.sendRedirect(httpRequest.getContextPath() + "/login");
                        return;
                    }
                } else {
                    // Luôn cập nhật lại session để thông tin cá nhân và danh sách permissions luôn thực tế (Real-time RBAC)
                    session.setAttribute("user", latestUser);
                }
            } else {
                // Nếu tài khoản bị xóa khỏi database
                session.invalidate();
                if (!uri.endsWith("/login")) {
                    httpResponse.sendRedirect(httpRequest.getContextPath() + "/login");
                    return;
                }
            }
        }
        
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}
