package dbproject.dbprojectgui;

import dbproject.dbprojectgui.operations.OperationSetupController;
import dbproject.dbprojectgui.operations.TableViewController;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.control.*;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.ResourceBundle;

public class ClientPanelController implements Initializable{
    @FXML
    private Label nameLabel;
    @FXML
    private Label accountLabel;
    @FXML
    private Label balanceLabel;
    @FXML
    private ChoiceBox operationsChoiceBox;
    @FXML
    private Button operationButton;

    private Statement statement;
    private String accountID;

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

        operationButton.setDisable(true);
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
                this.accountID = accountID;
                balanceLabel.setText(balance);
            }
        }
        catch(SQLException e){
            throw new RuntimeException(e);
        }
    }

    public void setupTableView(String query){
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

        TableViewController controller = fxmlLoader.getController();
        controller.loadData(query);
        tableView.show();
    }

    public void viewAccountHistory(){
        String query = "SELECT Id,Date,Amount,Operation FROM AccountHistory('" + accountID + "')";
        setupTableView(query);
    }

    public void viewOperationsByMonth(){
        String query = "SELECT * FROM AccountOperationsByMonth('" + accountID + "')";
        setupTableView(query);
    }

    public void choiceBoxOnAction(){
        operationButton.setDisable(false);
    }

    public void operationButtonOnClick() throws SQLException{
        String value = (String) operationsChoiceBox.getValue();
        ArrayList<String> data = new ArrayList<>();
        switch(value){
            case ("Withdraw") -> {
                System.out.println("Chose withdraw");
                data.add("Withdraw");
                data.add("Card");
                data.add(accountID);
                data.add("Amount");
                data.add("ATM");
            }
            case ("Deposit") -> {
                System.out.println("Chose deposit");
                data.add("Deposit");
                data.add("Card");
                data.add(accountID);
                data.add("Amount");
                data.add("ATM");
            }
            case ("Transfer") -> {
                System.out.println("Chose transfer");
                data.add("Transfer");
                data.add("Sender");
                data.add(accountID);
                data.add("Receiver");
                data.add("Amount");
                data.add("Title");
                data.add("Category");
            }
            case ("Phone transfer") -> {
                System.out.println("Chose PhoneTransfer");
                data.add("PhoneTransfer");
                data.add("Sender");
                data.add(accountID);
                data.add("Phone of the receiver");
                data.add("Amount");
                data.add("Title");
                data.add("Category");
            }
        }

        Dialog<ButtonType> operationDialog = new Dialog<>();
        operationDialog.initOwner(accountLabel.getScene().getWindow());
        operationDialog.setTitle("Operation setup");
        operationDialog.setHeaderText("To perform " + data.get(0) + " insert the data below and press Done");
        operationDialog.getDialogPane().getScene().getWindow()
                .setOnCloseRequest(windowEvent -> operationDialog.getDialogPane().getScene().getWindow().hide());

        FXMLLoader fxmlLoader = new FXMLLoader();
        fxmlLoader.setLocation(getClass().getResource("operations/operationSetupView.fxml"));
        try{
            operationDialog.getDialogPane().setContent(fxmlLoader.load());
        }
        catch(IOException e){
            System.out.println("Could not load operationSetupView");
            System.out.println(e.getMessage());
            return;
        }

        OperationSetupController controller = fxmlLoader.getController();
        controller.loadData(data);
        operationDialog.showAndWait();

        loadData(accountID);
    }
}
