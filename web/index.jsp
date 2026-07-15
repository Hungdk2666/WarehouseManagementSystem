<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%


    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }

    String target;
    if (user.hasPermission("USER_VIEW") || user.hasPermission("ROLE_VIEW")) {
        target = "/dashboard/system-admin.jsp";
    } else if (user.hasPermission("DASHBOARD_VIEW")) {
        target = "/dashboard/business-admin.jsp";
    } else if (user.hasPermission("STOCKTAKE_APPROVE_L1") || user.hasPermission("WAREHOUSE_EDIT")) {
        target = "/dashboard/warehouse-manager.jsp";
    } else if (user.hasPermission("TICKET_CONFIRM_IN") || user.hasPermission("TICKET_CONFIRM_OUT")) {
        target = "/dashboard/warehouse-staff.jsp";
    } else {
        target = "/dashboard/sales-staff.jsp";
    }
    request.getRequestDispatcher(target).forward(request, response);
%>
