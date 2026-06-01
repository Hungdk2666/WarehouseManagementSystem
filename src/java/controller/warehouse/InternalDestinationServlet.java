package controller.warehouse;

import dao.InternalDestinationDAO;
import java.io.IOException;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.InternalDestination;
import model.User;

@WebServlet(name = "InternalDestinationServlet", urlPatterns = {"/warehouse/destination"})
public class InternalDestinationServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // RBAC check: Read actions require DESTINATION_VIEW
        if (!loggedInUser.hasPermission("DESTINATION_VIEW")) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view internal destinations.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        InternalDestinationDAO dao = new InternalDestinationDAO();

        switch (action) {
            case "list":
                List<InternalDestination> list = dao.getAllDestinations();
                request.setAttribute("destinationList", list);
                request.getRequestDispatcher("/destinations/destination-list.jsp").forward(request, response);
                break;
            case "add":
                if (!loggedInUser.hasPermission("DESTINATION_ADD")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add destinations.");
                    return;
                }
                request.getRequestDispatcher("/destinations/destination-add.jsp").forward(request, response);
                break;
            case "update":
                if (!loggedInUser.hasPermission("DESTINATION_EDIT")) {
                    response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to modify destinations.");
                    return;
                }
                int updateId = Integer.parseInt(request.getParameter("id"));
                InternalDestination destination = dao.getDestinationById(updateId);
                if (destination == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/destination?action=list");
                    return;
                }
                request.setAttribute("destination", destination);
                request.getRequestDispatcher("/destinations/destination-update.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/destination?action=list");
                break;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            response.sendRedirect(request.getContextPath() + "/warehouse/destination?action=list");
            return;
        }

        // RBAC check: Action-based permissions
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("DESTINATION_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to add destinations.");
                return;
            }
        } else if ("update".equals(action)) {
            if (!loggedInUser.hasPermission("DESTINATION_EDIT")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to modify destinations.");
                return;
            }
        } else if ("toggle".equals(action)) {
            if (!loggedInUser.hasPermission("DESTINATION_TOGGLE")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to enable/disable destinations.");
                return;
            }
        }

        InternalDestinationDAO dao = new InternalDestinationDAO();

        try {
            switch (action) {
                case "add":
                    String destinationName = request.getParameter("destination_name");
                    String destinationType = request.getParameter("destination_type");
                    String address = request.getParameter("address");
                    boolean status = Boolean.parseBoolean(request.getParameter("status"));
                    
                    InternalDestination newDest = new InternalDestination();
                    newDest.setDestinationName(destinationName);
                    newDest.setDestinationType(destinationType);
                    newDest.setAddress(address);
                    newDest.setStatus(status);
                    
                    dao.addDestination(newDest);
                    break;
                case "update":
                    int id = Integer.parseInt(request.getParameter("id"));
                    String updateName = request.getParameter("destination_name");
                    String updateType = request.getParameter("destination_type");
                    String updateAddress = request.getParameter("address");
                    
                    InternalDestination updateDest = new InternalDestination();
                    updateDest.setId(id);
                    updateDest.setDestinationName(updateName);
                    updateDest.setDestinationType(updateType);
                    updateDest.setAddress(updateAddress);
                    
                    dao.updateDestination(updateDest);
                    break;
                case "toggle":
                    int toggleId = Integer.parseInt(request.getParameter("id"));
                    dao.toggleDestinationStatus(toggleId);
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect(request.getContextPath() + "/warehouse/destination?action=list");
    }
}
