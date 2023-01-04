package dbproject.dbprojectgui;

import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;

import java.net.URL;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ResourceBundle;

public class LoginController implements Initializable{
    @FXML
    private TextField accountField;
    @FXML
    private PasswordField passwordField;
    @FXML
    private Label errorLabel;
    private Statement statement;
    private String account;

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

    public boolean checkData() throws SQLException{
        String login = accountField.getText();
//        String login = "NO1086289381692";
        String password = passwordField.getText();
//        String password = "123";

        String query = "SELECT dbo.IfAccountExists('" + login + "'), dbo.GetPassword('" + login + "')";
        ResultSet rs = statement.executeQuery(query);
        if(rs.next()){
            if(rs.getString(1).equals("1") && rs.getString(2).equals(password)){
                account = login;
                return true;
            }
        }

        errorLabel.setVisible(true);
        return false;
    }

    public String returnAccount(){
        return account;
    }

    public void onClickLogin() throws SQLException{
        if(checkData())
            errorLabel.getScene().getWindow().hide();
    }

    public void onClickCancel(){
        errorLabel.getScene().getWindow().hide();
    }

}