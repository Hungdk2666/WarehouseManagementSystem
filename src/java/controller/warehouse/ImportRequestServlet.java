package controller.warehouse;

import dao.ImportRequestDAO;
import dao.SupplierDAO;
import dao.ProductDAO;
import java.io.IOException;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.ImportRequest;
import model.ImportRequestDetail;
import model.Supplier;
import model.Product;
import model.User;

@WebServlet(name = "ImportRequestServlet", urlPatterns = {"/warehouse/po"})
public class ImportRequestServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        User loggedInUser = (User) session.getAttribute("user");

        if (loggedInUser == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) {
            action = "list";
        }

        // Permission Checks
        if ("list".equals(action) || "detail".equals(action)) {
            if (!loggedInUser.hasPermission("PO_VIEW")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to view POs.");
                return;
            }
        } else if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("PO_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create POs.");
                return;
            }
        }

        ImportRequestDAO dao = new ImportRequestDAO();

        switch (action) {
            case "list":
                List<ImportRequest> list = dao.getAllImportRequests();
                request.setAttribute("poList", list);
                request.getRequestDispatcher("/po/po-list.jsp").forward(request, response);
                break;
            case "detail":
                int id = Integer.parseInt(request.getParameter("id"));
                ImportRequest req = dao.getImportRequestById(id);
                if (req == null) {
                    response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
                    return;
                }
                dao.ImportTicketDAO ticketDao = new dao.ImportTicketDAO();
                List<model.ImportTicket> tickets = ticketDao.getImportTicketsByRequestId(id);
                
                request.setAttribute("po", req);
                request.setAttribute("ticketList", tickets);
                request.getRequestDispatcher("/po/po-detail.jsp").forward(request, response);
                break;
            case "add":
                SupplierDAO sDao = new SupplierDAO();
                ProductDAO pDao = new ProductDAO();
                
                List<Supplier> suppliers = sDao.getAllSuppliers();
                List<Product> products = pDao.getAllProducts();
                
                request.setAttribute("supplierList", suppliers);
                request.setAttribute("productList", products);
                request.getRequestDispatcher("/po/po-add.jsp").forward(request, response);
                break;
            default:
                response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
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
            response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
            return;
        }
        
        if ("add".equals(action)) {
            if (!loggedInUser.hasPermission("PO_ADD")) {
                response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to create POs.");
                return;
            }
        }
        
        ImportRequestDAO dao = new ImportRequestDAO();
        
        try {
            switch (action) {
                case "add":
                    int supplierId = Integer.parseInt(request.getParameter("supplier_id"));
                    Date expectedDate = Date.valueOf(request.getParameter("expected_date"));
                    
                    String[] productIds = request.getParameterValues("product_id");
                    String[] quantities = request.getParameterValues("quantity");
                    String[] unitPrices = request.getParameterValues("unit_price");
                    
                    if (productIds != null && productIds.length > 0) {
                        List<ImportRequestDetail> details = new ArrayList<>();
                        for (int i = 0; i < productIds.length; i++) {
                            if (productIds[i] == null || productIds[i].trim().isEmpty()) continue;
                            int pId = Integer.parseInt(productIds[i]);
                            int qty = Integer.parseInt(quantities[i]);
                            double price = Double.parseDouble(unitPrices[i]);
                            
                            ImportRequestDetail d = new ImportRequestDetail();
                            d.setProductId(pId);
                            d.setQuantity(qty);
                            d.setUnitPrice(price);
                            details.add(d);
                        }
                        
                        ImportRequest req = new ImportRequest();
                        req.setSupplierId(supplierId);
                        req.setCreatorId(loggedInUser.getId());
                        req.setExpectedDate(expectedDate);
                        
                        boolean success = dao.addImportRequest(req, details);
                        if (!success) {
                            request.setAttribute("error", "Failed to save Purchase Order. Please try again.");
                            response.sendRedirect(request.getContextPath() + "/warehouse/po?action=add");
                            return;
                        }
                    }
                    break;
                case "approve":
                    int approveId = Integer.parseInt(request.getParameter("id"));
                    dao.updateStatus(approveId, "APPROVED", loggedInUser.getId());
                    break;
                case "reject":
                    int rejectId = Integer.parseInt(request.getParameter("id"));
                    dao.updateStatus(rejectId, "REJECTED", loggedInUser.getId());
                    break;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        response.sendRedirect(request.getContextPath() + "/warehouse/po?action=list");
    }
}
