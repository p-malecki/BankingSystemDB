package dbproject.dbprojectgui;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class ConnectionDB{
    public final String serverName = "LAPTOP-UI0RMMIG";
    private final String dbName = "DBproject";
    private final String url = "jdbc:sqlserver://" + serverName + ";DatabaseName=" + dbName + ";encrypt=true;" +
            "trustServerCertificate=true;integratedSecurity=true";

    public Connection fileConnection(){

        try{
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            Connection connection = DriverManager.getConnection(url);
            System.out.println("Successfully connected to the database");
            return connection;
        }
        catch(ClassNotFoundException | SQLException e){
            System.out.println("Failed to connect to the database");
            return null;
        }
    }
}
