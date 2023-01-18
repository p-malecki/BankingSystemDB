package dbproject.dbprojectgui;

import dbproject.dbprojectgui.operations.OperationSetupController;
import dbproject.dbprojectgui.operations.TableViewController;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.geometry.Pos;
import javafx.scene.control.*;
import javafx.scene.layout.VBox;

import java.io.IOException;
import java.net.URL;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
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
    private ChoiceBox changeChoiceBox;
    @FXML
    private Button operationButton;
    @FXML
    private Button changeButton;

    private Statement statement;
    private String accountID;
    private String clientID;

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
        changeButton.setDisable(true);
    }

    public void loadData(String account){
        String query = "SELECT C.Name, A.AccountID, A.CurrentBalance, C.ClientID\n" + "FROM Accounts A\n" +
                "JOIN Clients C ON C.ClientID = A.ClientID\n" + "WHERE A.AccountID = '" + account + "'";
        try{
            ResultSet rs = statement.executeQuery(query);
            if(rs.next()){
                String clientName = rs.getString(1);
                String accountID = rs.getString(2);
                String balance = rs.getString(3) + "$";
                String clientID = rs.getString(4);

                nameLabel.setText(clientName);
                accountLabel.setText(accountID);
                balanceLabel.setText(balance);
                this.clientID = clientID;
                this.accountID = accountID;
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

    public void viewCardsAndDetails(){
        String query =
                "SELECT CD.* FROM Cards C JOIN CardDetails CD ON CD.CardID = C.CardID " + "WHERE C.Account " + "=" +
                        " '" + accountID + "'";
        setupTableView(query);
    }

    public void viewOperationsByOperationType(){
        String query = "SELECT * FROM ClientOperationsByOperationType(" + clientID + ")";
        System.out.println(query);
        setupTableView(query);
    }

    public void viewClientOperationsByCategories(){
        String query = "SELECT T.Description, C.Operations FROM ClientOperationsByCategories(" + clientID +
                ") C JOIN TransactionCategories T ON T.CategoryID = C.Category";
        setupTableView(query);
    }

    public void operationsChoiceBoxOnAction(){
        operationButton.setDisable(false);
    }

    public void changeChoiceBoxOnAction(){
        changeButton.setDisable(false);
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
            case ("Transfer to own account") -> {
                System.out.println("Chose transfer to own account");
                data.add("Transfer");
                data.add("Sender");
                data.add(accountID);
                data.add("Sender other account");
                data.add(clientID);
                data.add("Amount");
                data.add("Title");
                data.add("Category");
            }
            case ("Create new card") -> {
                Dialog<ArrayList<String>> dialog = new Dialog<>();
                final double WIDTH = 250.0;
                dialog.setTitle("Operation");
                dialog.setHeaderText("Type card ID, limit and PIN");
                dialog.getDialogPane().getButtonTypes().add(ButtonType.OK);
                dialog.getDialogPane().getButtonTypes().add(ButtonType.CANCEL);

                VBox vBox = new VBox();
                vBox.setAlignment(Pos.CENTER);
                vBox.setSpacing(20);

                TextField accountId = new TextField("Account ID");
                accountId.setMaxWidth(WIDTH);
                accountId.setText(accountID);
                accountId.setDisable(true);
                TextField cardId = new TextField("Card ID");
                accountId.setMaxWidth(WIDTH);
                TextField limit = new TextField("Limit");
                limit.setMaxWidth(WIDTH);
                TextField PIN = new TextField("PIN");
                PIN.setMaxWidth(WIDTH);

                vBox.getChildren().addAll(accountId, cardId, limit, PIN);
                dialog.getDialogPane().setContent(vBox);
                dialog.setResultConverter(button -> {
                    if(button.equals(ButtonType.OK)){
                        ArrayList<String> result = new ArrayList<>();
                        result.add(cardId.getText());
                        result.add(accountId.getText());
                        result.add(limit.getText());
                        result.add(PIN.getText());
                        return result;
                    }
                    return null;
                });

                Optional<ArrayList<String>> result = dialog.showAndWait();
                if(result.isPresent()){
                    ArrayList<String> list = result.get();
                    String query =
                            "EXEC addNewCard '" + list.get(0) + "', '" + list.get(1) + "', " + list.get(2) + ", '" +
                                    list.get(3) + "'";
                    System.out.println(query);
                    try{
                        statement.execute(query);
                    }
                    catch(SQLException e){
                        Alert alert = new Alert(Alert.AlertType.WARNING);
                        alert.setHeaderText(e.getMessage());
                        alert.showAndWait();
                    }
                }
                return;
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

    public void changeButtonOnClick() throws SQLException{
        String value = (String) changeChoiceBox.getValue();
        Dialog<String> dialog = new Dialog<>();
        dialog.getDialogPane().getButtonTypes().add(ButtonType.OK);
        dialog.getDialogPane().getButtonTypes().add(ButtonType.CANCEL);

        VBox vBox = new VBox();
        vBox.setAlignment(Pos.CENTER);
        vBox.setSpacing(20);
        final double WIDTH = 250.0;

        switch(value){
            case ("Card PIN") -> {
                dialog.setTitle("Change PIN");
                dialog.setHeaderText("Choose card and enter new PIN");

                List<String> cardsList = new ArrayList<>();
                ResultSet rs = statement.executeQuery("SELECT CardID FROM Cards WHERE Account = '" + accountID + "'");
                while(rs.next())
                    cardsList.add(rs.getString(1));

                ChoiceBox<String> cards = new ChoiceBox<>();
                cards.getItems().addAll(cardsList);
                cards.setMaxWidth(WIDTH);
                TextField oldPIN = new TextField("Old PIN");
                oldPIN.setMaxWidth(WIDTH);
                TextField newPIN = new TextField("New PIN");
                newPIN.setMaxWidth(WIDTH);

                vBox.getChildren().addAll(cards, oldPIN, newPIN);
                dialog.getDialogPane().setContent(vBox);
                dialog.setResultConverter(button -> {
                    if(button.equals(ButtonType.OK))
                        return "EXEC changeCardPIN '" + cards.getValue() + "', '" + oldPIN.getText() + "', '" +
                                newPIN.getText() + "'";

                    return null;
                });
            }
            case ("Card Limit") -> {
                dialog.setTitle("Change Limit");
                dialog.setHeaderText("Choose card and enter new limit");

                List<String> cardsList = new ArrayList<>();
                ResultSet rs = statement.executeQuery("SELECT CardID FROM Cards WHERE Account = '" + accountID + "'");
                while(rs.next())
                    cardsList.add(rs.getString(1));

                ChoiceBox<String> cards = new ChoiceBox<>();
                cards.getItems().addAll(cardsList);
                cards.setMaxWidth(WIDTH);
                TextField PIN = new TextField("Current PIN");
                PIN.setMaxWidth(WIDTH);
                TextField limit = new TextField("New limit");
                limit.setMaxWidth(WIDTH);

                vBox.getChildren().addAll(cards, PIN, limit);
                dialog.getDialogPane().setContent(vBox);
                dialog.setResultConverter(button -> {
                    if(button.equals(ButtonType.OK)){
                        ResultSet rs2 = null;
                        try{
                            rs2 = statement.executeQuery("SELECT dbo.GetPIN('" + cards.getValue() + "')");
                            if(rs2.next()){
                                return "EXEC changeCardLimit '" + cards.getValue() + "', " + limit.getText() + ", " +
                                        "'" + PIN.getText() + "'";
                            }
                        }
                        catch(SQLException e){
                            return null;
                        }
                    }
                    return null;
                });
            }
            case ("Password") -> {
                dialog.setTitle("Change password");
                dialog.setHeaderText("Enter old and new password");

                TextField oldPassword = new TextField("Old password");
                oldPassword.setMaxWidth(WIDTH);
                TextField newPassword = new TextField("New password");
                newPassword.setMaxWidth(WIDTH);

                vBox.getChildren().addAll(oldPassword, newPassword);
                dialog.getDialogPane().setContent(vBox);
                dialog.setResultConverter(button -> {
                    if(button.equals(ButtonType.OK)){
                        try{
                            ResultSet rs = statement.executeQuery("SELECT dbo.GetPassword('" + accountID + "')");
                            if(rs.next() && rs.getString(1).equals(oldPassword.getText()))
                                return "EXEC changeAccountPassword '" + accountID + "', '" + oldPassword.getText() +
                                        "', '" + newPassword.getText() + "'";
                            else{
                                Alert alert = new Alert(Alert.AlertType.WARNING);
                                alert.setHeaderText("Wrong password");
                                alert.showAndWait();
                                return null;
                            }
                        }
                        catch(SQLException e){
                            return null;
                        }
                    }
                    return null;
                });
            }
        }

        Optional<String> result = dialog.showAndWait();
        if(result.isPresent()){
            try{
                statement.execute(result.get());
            }
            catch(SQLException e){
                Alert alert = new Alert(Alert.AlertType.WARNING);
                alert.setHeaderText(e.getMessage());
                alert.showAndWait();
            }
        }
    }
}
