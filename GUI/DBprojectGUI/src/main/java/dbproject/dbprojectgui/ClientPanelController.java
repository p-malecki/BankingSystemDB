package dbproject.dbprojectgui;

import dbproject.dbprojectgui.operations.TableViewController;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.control.ButtonType;
import javafx.scene.control.Dialog;
import javafx.scene.control.Label;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ResourceBundle;

public class ClientPanelController implements Initializable{
    @FXML
    private Label nameLabel;
    @FXML
    private Label accountLabel;
    @FXML
    private Label balanceLabel;
    private Statement statement;

    @Override
    public void initialize(URL url, ResourceBundle resourceBundle){
        ConnectionDB conDB = new ConnectionDB();
        statement = null;
        try{
            statement = conDB.fileConnection().createStatement();
        }
        catch(SQLException e){
            System.out.println("Failed to create the statement");
            throw new RuntimeException(e);
        }
    }

    public void loadData(String account){
        String query = "SELECT C.Name, A.AccountID, A.CurrentBalance\n" + "FROM Accounts A\n" +
                "JOIN Clients C ON C.ClientID = A.ClientID\n" + "WHERE A.AccountID = '" + account + "'";
        try{
            ResultSet rs = statement.executeQuery(query);
            if(rs.next()){
                String name = rs.getString(1);
                String accountID = rs.getString(2);
                String balance = rs.getString(3) + "$";

                nameLabel.setText(name);
                accountLabel.setText(accountID);
                balanceLabel.setText(balance);
            }
        }
        catch(SQLException e){
            throw new RuntimeException(e);
        }
    }

    public void viewAccountHistory(){
        Dialog<ButtonType> tableView = new Dialog<>();
        tableView.initOwner(accountLabel.getScene().getWindow());
        tableView.setTitle("Display query");
        tableView.getDialogPane().getScene().getWindow()
                .setOnCloseRequest(windowEvent -> tableView.getDialogPane().getScene().getWindow().hide());
        tableView.getDialogPane().getButtonTypes().add(ButtonType.OK);

        FXMLLoader fxmlLoader = new FXMLLoader();
        fxmlLoader.setLocation(getClass().getResource("operations/tableView.fxml"));
        try{
            tableView.getDialogPane().setContent(fxmlLoader.load());
        }
        catch(IOException e){
            System.out.println("Could not load tableView");
            System.out.println(e.getMessage());
            return;
        }

        String query = "SELECT * FROM AccountHistory('"+ accountLabel.getText() + "')";

        TableViewController controller = fxmlLoader.getController();
        controller.loadData(query);
        tableView.show();
    }

    public void viewOperationsByMonth(){

    }
}
