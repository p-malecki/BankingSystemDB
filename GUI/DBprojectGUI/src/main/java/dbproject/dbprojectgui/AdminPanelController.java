package dbproject.dbprojectgui;

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
import java.time.LocalDate;
import java.util.*;

public class AdminPanelController implements Initializable{
    @FXML
    public Button allOperationsButton;
    @FXML
    public Button numberOfOperationsByAccountButton;
    @FXML
    public Button numberOfOperationsByClientButton;
    @FXML
    public Button numberOfOperationsByAccountsAndCatergoriesButton;
    @FXML
    public Button chosenClientButton;
    @FXML
    public Button numberOfTransfersByClientButton;
    @FXML
    public Button atmByMonthButton;
    @FXML
    public Button atmMalfunctionsHistoryButton;
    @FXML
    public Button reportAtmMalfunctionButton;
    @FXML
    public Button addNewClientButton;
    @FXML
    public Button addNewAccountButton;
    @FXML
    public Button addNewEmployeeButton;
    @FXML
    public Button numberOfPhoneTransfersByClient;
    @FXML
    private Label adminLabel;
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

    public void setupTableView(String query){
        Dialog<ButtonType> tableView = new Dialog<>();
        tableView.initOwner(adminLabel.getScene().getWindow());
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

    public void allOperationsOnClick(){
        String query = "SELECT * FROM AllOperations";
        setupTableView(query);
    }

    public void numberOfOperationsByAccountOnClick(){
        String query = "SELECT * FROM NumberOfOperationsByAccount";
        setupTableView(query);
    }

    public void numberOfOperationsByClientOnClick(){
        String query = "SELECT * FROM NumberOfOperationsByClient";
        setupTableView(query);
    }

    public void numberOfOperationsByAccountsAndCategoriesOnClick(){
        String query = "SELECT * FROM NumberOfOperationsByAccountsAndCategories";
        setupTableView(query);
    }

    public void chosenAccountOnClick(){
        TextInputDialog dialog = new TextInputDialog("Enter account ID");
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter ID of the account you want to preview");

        Optional<String> result = dialog.showAndWait();
        if(result.isPresent()){
            String query = "SELECT * FROM AccountHistory('" + result.get() + "')";
            System.out.println(query);
            setupTableView(query);
        }
    }

    public void numberOfTransfersByClientOnClick(){
        String query = "SELECT * FROM NumberOfTransfersByClient ORDER BY ClientID";
        setupTableView(query);
    }

    public void numberOfPhoneTransfersByClientOnClick(){
        String query = "SELECT * FROM NumberOfPhoneTransfersByClient ORDER BY ClientID";
        setupTableView(query);
    }

    public void atmByMonthOnClick() throws SQLException{
        List<String> ATMs = new ArrayList<>();
        ResultSet rs = statement.executeQuery("SELECT ATMID, City FROM ATMs");
        while(rs.next())
            ATMs.add(rs.getString(1) + ". " + rs.getString(2));

        ChoiceDialog<String> dialog = new ChoiceDialog<>(ATMs.get(0), ATMs);
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter ID of the ATM you want to preview");

        Optional<String> result = dialog.showAndWait();
        if(result.isPresent()){
            String id = result.get().substring(0, result.get().indexOf("."));
            String query = "SELECT * FROM ATMOperationsByMonth(" + id + ")";
            setupTableView(query);
        }
    }

    public void atmMalfunctionsHistoryOnClick() throws SQLException{
        List<String> ATMs = new ArrayList<>();
        ResultSet rs = statement.executeQuery("SELECT ATMID, City FROM ATMs");
        while(rs.next())
            ATMs.add(rs.getString(1) + ". " + rs.getString(2));

        ChoiceDialog<String> dialog = new ChoiceDialog<>(ATMs.get(0), ATMs);
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter ID of the ATM you want to preview");

        Optional<String> result = dialog.showAndWait();
        if(result.isPresent()){
            String id = result.get().substring(0, result.get().indexOf("."));
            String query = "SELECT * FROM ATM_MalfunctionsHistory(" + id + ")";
            setupTableView(query);
        }
    }

    public void reportAtmMalfunctionOnClick() throws SQLException{
        Dialog<ArrayList<String>> dialog = new Dialog<>();
        final double WIDTH = 250.0;
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter data below to report a malfunction");
        dialog.getDialogPane().getButtonTypes().add(ButtonType.OK);
        dialog.getDialogPane().getButtonTypes().add(ButtonType.CANCEL);

        VBox vBox = new VBox();
        vBox.setAlignment(Pos.CENTER);
        vBox.setSpacing(20);

        List<String> atmList = new ArrayList<>();
        ResultSet rs = statement.executeQuery("SELECT ATMID, City FROM ATMs");
        while(rs.next())
            atmList.add(rs.getString(1) + ". " + rs.getString(2));
        List<String> employeeList = new ArrayList<>();
        rs = statement.executeQuery("SELECT EmployeeID, Name FROM Employees");
        while(rs.next())
            employeeList.add(rs.getString(1) + ". " + rs.getString(2));

        ChoiceBox<String> ATMs = new ChoiceBox<>();
        ATMs.getItems().addAll(atmList);
        ATMs.setMaxWidth(WIDTH);
        TextField description = new TextField("Malfunction description");
        description.setMaxWidth(WIDTH);
        ChoiceBox<String> Employees = new ChoiceBox<>();
        Employees.getItems().addAll(employeeList);
        Employees.setMaxWidth(WIDTH);

        vBox.getChildren().addAll(ATMs, description, Employees);
        dialog.getDialogPane().setContent(vBox);
        dialog.setResultConverter(button -> {
            if(button.equals(ButtonType.OK)){
                ArrayList<String> result = new ArrayList<>();
                result.add(ATMs.getValue().substring(0, ATMs.getValue().indexOf(".")));
                result.add(description.getText());
                result.add(Employees.getValue().substring(0, Employees.getValue().indexOf(".")));

                return result;
            }
            return null;
        });

        Optional<ArrayList<String>> result = dialog.showAndWait();
        if(result.isPresent()){
            ArrayList<String> list = result.get();
            String query = "EXEC reportATMsMalfunction " + list.get(0) + ", '" + list.get(1) + "', " + list.get(2);
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
    }

    public void newClientOnClick(){
        Dialog<ArrayList<String>> dialog = new Dialog<>();
        final double WIDTH = 250.0;
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter data below to add new client to the database");
        dialog.getDialogPane().getButtonTypes().add(ButtonType.OK);
        dialog.getDialogPane().getButtonTypes().add(ButtonType.CANCEL);

        VBox vBox = new VBox();
        vBox.setAlignment(Pos.CENTER);
        vBox.setSpacing(20);

        TextField name = new TextField("Name");
        name.setMaxWidth(WIDTH);
        DatePicker dateOfBirth = new DatePicker(LocalDate.now());
        dateOfBirth.setMaxWidth(WIDTH);
        TextField city = new TextField("City");
        city.setMaxWidth(WIDTH);
        TextField country = new TextField("Country");
        country.setMaxWidth(WIDTH);
        TextField phoneNumber = new TextField("Phone number");
        phoneNumber.setMaxWidth(WIDTH);
        CheckBox allowPhoneTransfer = new CheckBox("Allow phone transfers");
        allowPhoneTransfer.setMaxWidth(WIDTH);

        vBox.getChildren().addAll(name, dateOfBirth, city, country, phoneNumber, allowPhoneTransfer);
        dialog.getDialogPane().setContent(vBox);
        dialog.setResultConverter(button -> {
            if(button.equals(ButtonType.OK)){
                ArrayList<String> result = new ArrayList<>();
                result.add(name.getText());
                result.add(dateOfBirth.getValue().toString());
                result.add(city.getText());
                result.add(country.getText());
                result.add(phoneNumber.getText());
                result.add(allowPhoneTransfer.isSelected() ? "1" : "0");

                return result;
            }
            return null;
        });

        Optional<ArrayList<String>> result = dialog.showAndWait();
        if(result.isPresent()){
            ArrayList<String> list = result.get();
            String query = "EXEC addNewClient '" + list.get(0) + "', CONVERT(DATE,'" + list.get(1) + "',105), '" +
                    list.get(2) + "', '" + list.get(3) + "', '" + list.get(4) + "', " + list.get(5);
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
    }

    public void newAccountOnClick() throws SQLException{
//        @accountID NVARCHAR(100),
//        @clientID INT,
//        @name NVARCHAR(100),
//        @accountType INT,
//        @password NVARCHAR(100),
        Dialog<ArrayList<String>> dialog = new Dialog<>();
        final double WIDTH = 250.0;
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter data below to add new account to client");
        dialog.getDialogPane().getButtonTypes().add(ButtonType.OK);
        dialog.getDialogPane().getButtonTypes().add(ButtonType.CANCEL);

        VBox vBox = new VBox();
        vBox.setAlignment(Pos.CENTER);
        vBox.setSpacing(20);

        List<String> clientsList = new ArrayList<>();
        ResultSet rs = statement.executeQuery("SELECT ClientID, Name FROM Clients");
        while(rs.next())
            clientsList.add(rs.getString(1) + ". " + rs.getString(2));
        List<String> typesList = new ArrayList<>();
        rs = statement.executeQuery("SELECT AccountType, Description FROM AccountTypes");
        while(rs.next())
            typesList.add(rs.getString(1) + ". " + rs.getString(2));

        TextField accountID = new TextField("AccountID");
        accountID.setMaxWidth(WIDTH);
        ChoiceBox<String> clientID = new ChoiceBox<>();
        clientID.getItems().addAll(clientsList);
        clientID.setMaxWidth(WIDTH);
        TextField name = new TextField("Name");
        name.setMaxWidth(WIDTH);
        ChoiceBox<String> accountType = new ChoiceBox<>();
        accountType.getItems().addAll(typesList);
        accountType.setMaxWidth(WIDTH);
        TextField password = new TextField("Password");
        password.setMaxWidth(WIDTH);

        vBox.getChildren().addAll(accountID, clientID, name, accountType, password);
        dialog.getDialogPane().setContent(vBox);
        dialog.setResultConverter(button -> {
            if(button.equals(ButtonType.OK)){
                ArrayList<String> result = new ArrayList<>();
                result.add(accountID.getText());
                result.add(clientID.getValue().substring(0, clientID.getValue().indexOf(".")));
                result.add(name.getText());
                result.add(accountType.getValue().substring(0, accountType.getValue().indexOf(".")));
                result.add(password.getText());

                return result;
            }
            return null;
        });

        Optional<ArrayList<String>> result = dialog.showAndWait();
        if(result.isPresent()){
            ArrayList<String> list = result.get();
            String query = "EXEC addNewAccount '" + list.get(0) + "', " + list.get(1) + ", '" +
                    list.get(2) + "', " + list.get(3) + ", '" + list.get(4) + "'";
            System.out.println(query);
//            try{
//                statement.execute(query);
//            }
//            catch(SQLException e){
//                Alert alert = new Alert(Alert.AlertType.WARNING);
//                alert.setHeaderText(e.getMessage());
//                alert.showAndWait();
//            }
        }
    }

    public void newEmployeeOnClick() throws SQLException{
        Dialog<ArrayList<String>> dialog = new Dialog<>();
        final double WIDTH = 250.0;
        dialog.setTitle("Operation");
        dialog.setHeaderText("Enter data below to add new employee to the database");
        dialog.getDialogPane().getButtonTypes().add(ButtonType.OK);
        dialog.getDialogPane().getButtonTypes().add(ButtonType.CANCEL);

        VBox vBox = new VBox();
        vBox.setAlignment(Pos.CENTER);
        vBox.setSpacing(20);

        List<String> departmentsList = new ArrayList<>();
        ResultSet rs = statement.executeQuery("SELECT DepartmentID, City FROM Departments");
        while(rs.next())
            departmentsList.add(rs.getString(1) + ". " + rs.getString(2));

        TextField name = new TextField("Name");
        name.setMaxWidth(WIDTH);
        DatePicker dateOfSign = new DatePicker(LocalDate.now());
        dateOfSign.setMaxWidth(WIDTH);
        ChoiceBox<String> department = new ChoiceBox<>();
        department.getItems().addAll(departmentsList);
        department.setMaxWidth(WIDTH);

        vBox.getChildren().addAll(name, dateOfSign, department);
        dialog.getDialogPane().setContent(vBox);
        dialog.setResultConverter(button -> {
            if(button.equals(ButtonType.OK)){
                ArrayList<String> result = new ArrayList<>();
                result.add(name.getText());
                result.add(dateOfSign.getValue().toString());
                result.add(department.getValue().substring(0, department.getValue().indexOf(".")));

                return result;
            }
            return null;
        });

        Optional<ArrayList<String>> result = dialog.showAndWait();
        if(result.isPresent()){
            ArrayList<String> list = result.get();
            String query = "EXEC addNewEmployee '" + list.get(0) + "', CONVERT(DATE,'" + list.get(1) + "',105), " +
                    list.get(2);
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
    }
}

