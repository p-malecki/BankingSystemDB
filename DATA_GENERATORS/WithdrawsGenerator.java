import java.sql.*;
import java.util.Random;

public class WithdrawsGenerator{
    public static void main(String[] args) throws SQLException{

        try{
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            String serverName = "localhost";
            String dbName = "DBproject";
            String url = "jdbc:sqlserver://" + serverName + ";DatabaseName=" + dbName + ";encrypt=true;" +
                    "trustServerCertificate=true;integratedSecurity=true";
            Connection connection = DriverManager.getConnection(url);
            Statement state = connection.createStatement();

            String query = "SELECT DISTINCT Account FROM Deposits D JOIN Cards C ON C.CardID = D.Card";
            ResultSet rs = state.executeQuery(query);
            Random random = new Random();
            int operationID = 1;
            while(rs.next()){
                String accountID = rs.getString(1);
                String subQuery = "SELECT C.Account,\n" + "    D.Card,\n" + "    D.Amount,\n" + "    D.[Date],\n" +
                        "    LEAD(D.[Date],1) OVER(ORDER BY D.[Date])\n" + "FROM Deposits D \n" +
                        "JOIN Cards C ON C.CardID = D.Card \n" + "WHERE C.Account = '" + accountID + "'\n" +
                        "ORDER BY Account";
                Statement subState = connection.createStatement();
                ResultSet subRs = subState.executeQuery(subQuery);
                int accountSum = 0;
                while(subRs.next()){
                    String date = subRs.getString(4);
                    String nextDate = subRs.getString(5);
                    String card = subRs.getString(2);

                    int amount = Integer.parseInt(subRs.getString(3));
                    accountSum += amount;

                    if(nextDate != null){
                        int max = (accountSum / 3) + 1;
                        int withdraw = random.nextInt(max);
                        withdraw -= withdraw % 10;
                        if(withdraw > 0){
                            accountSum -= withdraw;
                            String newDate = DateGenerator.randomDateBetween(date, nextDate);
                            newDate = DateGenerator.format(newDate);

                            int ATMID = random.nextInt(86) + 1;
                            System.out.println(
                                    operationID++ + "," + card + "," + withdraw + "," + ATMID + "," + newDate);
                        }
                    }
                }
            }
        }
        catch(ClassNotFoundException e){
            throw new RuntimeException(e);
        }

    }
}
