import java.sql.*;
import java.util.Random;

public class LoansGenerator{
    public static void main(String[] args) throws SQLException{

        try{
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
            String serverName = "localhost";
            String dbName = "DBproject";
            String url = "jdbc:sqlserver://" + serverName + ";DatabaseName=" + dbName + ";encrypt=true;" +
                    "trustServerCertificate=true;integratedSecurity=true";
            Connection connection = DriverManager.getConnection(url);
            Statement state = connection.createStatement();

            String query =
                    "SELECT AccountID, StartDate, EndDate\n" + "FROM Accounts\n" + "WHERE AccountType NOT IN (2,3);";
            ResultSet rs = state.executeQuery(query);
            Random random = new Random();
            int loanID = 1;
            while(rs.next()){
                if(random.nextInt(3) == 2)
                    continue;
                int i = random.nextInt(15) + 1;
                do{
                    String accountID = rs.getString(1);
                    String accountStart = rs.getString(2);
                    String accountEnd = rs.getString(3) == null ? "2023-01-15" : rs.getString(3);
                    String startDate = DateGenerator.randomDateBetween(accountStart, accountEnd);
                    String endDate = DateGenerator.randomDateBetween(startDate, accountEnd);
                    startDate = DateGenerator.format(startDate);
                    endDate = DateGenerator.format(endDate);

                    int amount = 0;
                    int randInt = random.nextInt(10);
                    if(randInt < 1){ // big value
                        amount = random.nextInt(250_000) + 100_000;
                        amount -= amount % 10_000;
                    }
                    else if(randInt < 5){
                        amount = random.nextInt(30_000) + 15_000;
                        amount -= amount % 1_000;
                    }
                    else{
                        amount = random.nextInt(9000) + 3000;
                        amount -= amount % 100;
                    }

                    int employeeID = random.nextInt(112) + 1;

                    System.out.println(
                            loanID++ + "," + accountID + "," + amount + "," + startDate + "," + endDate + "," +
                                    employeeID);

                    i++;
                }
                while(i < 4);

            }
        }
        catch(ClassNotFoundException e){
            throw new RuntimeException(e);
        }

    }
}
