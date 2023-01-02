import java.sql.*;
import java.util.Random;

public class DepositsGenerator{
    public static void main(String[] args) throws SQLException{

        try{
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            String serverName = "localhost";
            String dbName = "DBproject";
            String url = "jdbc:sqlserver://" + serverName + ";DatabaseName=" + dbName + ";encrypt=true;" +
                    "trustServerCertificate=true;integratedSecurity=true";
            Connection connection = DriverManager.getConnection(url);
            Statement state = connection.createStatement();

            String query = "SELECT * FROM Cards";
            ResultSet rs = state.executeQuery(query);
            Random random = new Random();
            int operationID = 1;
            while(rs.next()){
                String cardID = rs.getString(1);
                int operationsAmount = random.nextInt(6);
                for(int i = 0; i < operationsAmount; i++){
                    int amount = random.nextInt(2500);
                    amount -= amount % 10;
                    int ATMID = random.nextInt(86) + 1;
                    Statement stateDate = connection.createStatement();
                    String queryDate = "SELECT A.StartDate, A.EndDate\n" + "FROM Accounts A\n" +
                            "JOIN Cards C ON C.Account = A.AccountID\n" + "WHERE C.CardID = '" + cardID + "'";
                    ResultSet rsDate = stateDate.executeQuery(queryDate);
                    rsDate.next();
                    String left = rsDate.getString(1);
                    String right = "2023-01-15";
                    if(rsDate.getString(2) != null)
                        right = rsDate.getString(2);

                    String date = DateGenerator.randomDateBetween(left, right);
                    date = DateGenerator.format(date);
                    System.out.println(operationID++ + "," + cardID + "," + amount + "," + ATMID + "," + date);
                }
            }
        }
        catch(ClassNotFoundException e){
            throw new RuntimeException(e);
        }

    }
}
