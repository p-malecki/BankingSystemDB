import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.Random;

public class TransactionsGenerator{
    public static void main(String[] args) throws SQLException{

        try{
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            String serverName = "localhost";
            String dbName = "DBproject";
            String url = "jdbc:sqlserver://" + serverName + ";DatabaseName=" + dbName + ";encrypt=true;" +
                    "trustServerCertificate=true;integratedSecurity=true";
            Connection connection = DriverManager.getConnection(url);
            Statement state = connection.createStatement();

            String query = "SELECT Account FROM Cards";
            ResultSet rs = state.executeQuery(query);
            Random random = new Random();
            int transactionID = 1;
            while(rs.next()){
                String accountID = rs.getString(1);
                Statement stateLoop = connection.createStatement();
                String queryLoop = "SELECT A.AccountID, Amount, [Date],\n" +
                        "    LEAD([Date], 1) OVER(ORDER BY [Date], Amount DESC)\n" + "FROM(\n" +
                        "    SELECT Account, CardID, Amount, [Date]\n" + "    FROM Cards C\n" +
                        "    JOIN Deposits D ON D.Card = C.CardID\n" + "    UNION ALL\n" +
                        "    SELECT Account, CardID, -Amount, [Date]\n" + "    FROM Cards C\n" +
                        "    JOIN Withdraws W ON W.Card = C.CardID\n" + ") TMP\n" +
                        "JOIN Accounts A ON A.AccountID = TMP.Account\n" +
                        "WHERE Account = '" + accountID + "'";
                ResultSet rsLoop = stateLoop.executeQuery(queryLoop);
                Statement stateCards = connection.createStatement();
                String queryCards = "SELECT C.CardID\n" + "FROM Accounts A\n" +
                        "JOIN Cards C ON C.Account = A.AccountID\n" + "WHERE AccountID = '" + accountID  + "'";
                ResultSet rsCards = stateCards.executeQuery(queryCards);
                ArrayList<String> cards = new ArrayList<>();
                while(rsCards.next())
                    cards.add(rsCards.getString(1));
                ArrayList<String> ibans = new ArrayList<>();
                BufferedReader reader = new BufferedReader(new FileReader("C:\\Users\\Konrad\\Desktop\\ibans.txt"));
                for(String line = reader.readLine(); line != null; line = reader.readLine())
                    ibans.add(line);

                int balance = 0;
                while(rsLoop.next()){
                    String amount = rsLoop.getString(2);
                    balance += Integer.parseInt(amount);
                    String currDate = rsLoop.getString(3);
                    String nextDate = rsLoop.getString(4);
                    if(nextDate == null)
                        continue;

                    if(balance > 0){
                        if(random.nextInt(3) == 0){
                            String usedCard = cards.get(random.nextInt(cards.size()));
                            int payment = random.nextInt((balance / 3) + 1);
                            balance -= payment;
                            String iban = ibans.get(random.nextInt(ibans.size()));
                            String date = DateGenerator.randomDateBetween(currDate, nextDate);
                            date = DateGenerator.format(date);
                            int category = 1;
                            while(category == 1 || category == 11){
                                category = random.nextInt(19) + 1;
                            }

                            System.out.println(transactionID++ + "," + usedCard + "," + iban + "," + payment + "," + date + "," +  category);
                        }
                    }
                }
            }
        }
        catch(ClassNotFoundException | IOException e){
            throw new RuntimeException(e);
        }

    }
}
