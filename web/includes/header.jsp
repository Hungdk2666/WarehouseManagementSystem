<%@page contentType="text/html" pageEncoding="UTF-8"%>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container">
        <a class="navbar-brand" href="<%= request.getContextPath() %>/index.jsp">WMS Dashboard</a>
        <div class="collapse navbar-collapse">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item">
                    <a class="nav-link text-danger" href="<%= request.getContextPath() %>/logout">Logout</a>
                </li>
            </ul>
        </div>
    </div>
</nav>
