package utils;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBUtils {
    // Database connection details
    private static final String URL = "jdbc:mysql://localhost:3306/wms_db?useUnicode=true&characterEncoding=UTF-8";
    private static final String USER = "root";
    private static final String PASSWORD = "Vietanh14032000@";

    public static Connection getConnection() throws Exception {
        // Load the MySQL JDBC Driver
        Class.forName("com.mysql.cj.jdbc.Driver");
        // Establish the connection
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
