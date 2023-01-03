package dbproject.dbprojectgui;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.control.*;

import java.io.IOException;
import java.net.URL;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ResourceBundle;

public class HelloController implements Initializable{
    @FXML
    private Label welcomeText;
    @FXML
    private Button clientButton;
    @FXML
    private Button adminButton;

    @Override
    public void initialize(URL url, ResourceBundle resourceBundle){
        ConnectionDB conDB = new ConnectionDB();
        Statement statement = null;
        try{
            statement = conDB.fileConnection().createStatement();
        }
        catch(SQLException e){
            System.out.println("Failed to create the statement");
            throw new RuntimeException(e);
        }
    }

    public void onClickClient(){
        System.out.println("Client logging in...");
        Dialog<String> loginDialog = new Dialog<>();
        loginDialog.initOwner(clientButton.getScene().getWindow());
        loginDialog.setTitle("Log in as client");
        loginDialog.setHeaderText("Enter accountID and password");

        FXMLLoader fxmlLoader = new FXMLLoader();
        fxmlLoader.setLocation(getClass().getResource("clientLoginView.fxml"));
        try{
            loginDialog.getDialogPane().setContent(fxmlLoader.load());
        }
        catch(IOException e){
            System.out.println("Could not load clientLoginView");
            return;
        }
        loginDialog.showAndWait();
        LoginController controller = fxmlLoader.getController();
        String result = controller.returnAccount();
        if(result != null){
            Alert loggedIn = new Alert(Alert.AlertType.INFORMATION);
            loggedIn.setTitle("Login alert");
            loggedIn.setHeaderText("Logged in successfully!");
            loggedIn.setContentText("You have successfully logged in on account " + result);
            loggedIn.showAndWait();
            controlClient(result);
        }
    }

    public void onClickAdmin(){
        System.out.println("admin");
    }

    public void controlClient(String account){
        System.out.println("Opening client's control panel for " + account);
        Dialog<ButtonType> clientPanel = new Dialog<>();
        clientPanel.initOwner(clientButton.getScene().getWindow());
        clientPanel.setTitle("Client control panel");
        clientPanel.getDialogPane().getScene().getWindow()
                .setOnCloseRequest(windowEvent -> clientPanel.getDialogPane().getScene().getWindow().hide());

        FXMLLoader fxmlLoader = new FXMLLoader();
        fxmlLoader.setLocation(getClass().getResource("clientPanelView.fxml"));
        try{
            clientPanel.getDialogPane().setContent(fxmlLoader.load());
        }
        catch(IOException e){
            System.out.println("Could not load clientPanelView");
            return;
        }
        ClientPanelController controller = fxmlLoader.getController();
        controller.loadData(account);
        clientPanel.show();
    }
}
