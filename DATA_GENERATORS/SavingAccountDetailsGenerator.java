import java.sql.*;
import java.util.Random;

public class SavingAccountDetailsGenerator{
    public static void main(String[] args) throws SQLException{

        try{
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            String serverName = "localhost";
            String dbName = "DBproject";
            String url = "jdbc:sqlserver://" + serverName + ";DatabaseName=" + dbName + ";encrypt=true;" +
                    "trustServerCertificate=true;integratedSecurity=true";
            Connection connection = DriverManager.getConnection(url);
            Statement state = connection.createStatement();

            String query = "SELECT AccountID\n" + "FROM Accounts\n" + "WHERE AccountType = 3";
            ResultSet rs = state.executeQuery(query);
            Random random = new Random();
            String[] frequencyArray = {"monthly", "quarter", "half year", "yearly"};
            while(rs.next()){
                String accountID = rs.getString(1);
                String frequency = frequencyArray[random.nextInt(frequencyArray.length)];
                int rateInt = random.nextInt(55) + 1;
                String rate = ((float) rateInt / 10) + "";
                System.out.println(accountID + "," + frequency + "," + rate);
            }
        }
        catch(ClassNotFoundException e){
            throw new RuntimeException(e);
        }

    }
}
