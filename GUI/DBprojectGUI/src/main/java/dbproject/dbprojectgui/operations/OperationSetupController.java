package dbproject.dbprojectgui.operations;

import dbproject.dbprojectgui.ConnectionDB;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.Node;
import javafx.scene.control.Alert;
import javafx.scene.control.ChoiceBox;
import javafx.scene.control.TextField;
import javafx.scene.layout.VBox;

import java.net.URL;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.ResourceBundle;

public class OperationSetupController implements Initializable{
    @FXML
    public VBox mainVBox;
    private Statement statement;

    private String operation;

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

    public void loadData(ArrayList<String> data) throws SQLException{
        Iterator<String> iterator = data.iterator();
        operation = iterator.next();
        while(iterator.hasNext()){
            String value = iterator.next();

            switch(value){
                case ("Card") -> {
                    ObservableList<String> cards = FXCollections.observableArrayList();
                    String query = "SELECT CardID FROM Accounts JOIN Cards ON Account = AccountID WHERE AccountID = '" +
                            iterator.next() + "'";
                    ResultSet rs = statement.executeQuery(query);
                    while(rs.next())
                        cards.add(rs.getString(1));

                    ChoiceBox<String> choiceBox = new ChoiceBox<>(cards);
                    choiceBox.setPrefWidth(300.0);
                    mainVBox.getChildren().add(choiceBox);
                    choiceBox.setValue("Card");
                }
                case ("Sender") -> {
                    TextField textField = new TextField();
                    textField.setText(iterator.next());
                    textField.setDisable(true);
                    textField.setMaxWidth(300.0);
                    mainVBox.getChildren().add(textField);
                }
                case ("Category") -> {
                    ObservableList<String> categories = FXCollections.observableArrayList();
                    String query = "SELECT * FROM TransactionCategories";
                    ResultSet rs = statement.executeQuery(query);
                    while(rs.next())
                        categories.add(rs.getString(1) + ". " + rs.getString(2));
                    ChoiceBox<String> choiceBox = new ChoiceBox<>(categories);
                    choiceBox.setPrefWidth(300.0);
                    mainVBox.getChildren().add(choiceBox);
                    choiceBox.setValue("Category");
                }
                default -> {
                    TextField textField = new TextField();
                    textField.setPromptText(value);
                    textField.setMaxWidth(300.0);
                    mainVBox.getChildren().add(textField);
                }
            }
        }
    }

    public void submit(){
        StringBuilder queryBuilder = new StringBuilder("EXEC ");
        queryBuilder.append("addNew").append(operation).append(" ");

        ObservableList<Node> list = mainVBox.getChildren();
        for(Node node : list){
            if(node instanceof TextField textField){
                queryBuilder.append("'").append(textField.getText()).append("', ");
            }
            else if(node instanceof ChoiceBox<?>){
                ChoiceBox<String> choiceBox = (ChoiceBox<String>) node;
                String value = choiceBox.getValue();
                if(value.contains(".")) // category
                    queryBuilder.append("'").append(value, 0, value.indexOf(".")).append("', ");
                else // card
                    queryBuilder.append("'").append(value).append("', ");
            }
        }
        queryBuilder.delete(queryBuilder.length() - 2, queryBuilder.length());
        System.out.println("Query: " + queryBuilder);
        try{
            statement.execute(queryBuilder.toString());
        }
        catch(SQLException e){
            Alert alert = new Alert(Alert.AlertType.WARNING);
            alert.setHeaderText(e.getMessage());
            alert.showAndWait();
        }
        exit();
    }

    public void exit(){
        mainVBox.getScene().getWindow().hide();
    }
}
