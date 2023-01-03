package dbproject.dbprojectgui.operations;

import dbproject.dbprojectgui.ConnectionDB;
import javafx.beans.property.SimpleStringProperty;
import javafx.beans.value.ObservableValue;
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.util.Callback;

import java.net.URL;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ResourceBundle;

public class TableViewController implements Initializable{
    @FXML
    private TableView<ObservableList<String>> table;
    private Statement statement;
    private ObservableList<ObservableList<String>> data;

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
        data = FXCollections.observableArrayList();
    }

    public void loadData(String query){
        try{
            ResultSet rs = statement.executeQuery(query);
            ResultSetMetaData rsmd = rs.getMetaData();
            int columnCount = rsmd.getColumnCount();

            for(int i = 1; i <= columnCount; i++){
                final int j = i - 1;
                TableColumn column = new TableColumn(rsmd.getColumnName(i));
                column.setCellValueFactory(
                        (Callback<TableColumn.CellDataFeatures<ObservableList, String>, ObservableValue<String>>) param -> new SimpleStringProperty(
                                param.getValue().get(j).toString()));

                table.getColumns().addAll(column);
            }

            while(rs.next()){
                ObservableList<String> row = FXCollections.observableArrayList();
                for(int i = 1; i <= columnCount; i++)
                    row.add(rs.getString(i));
                data.add(row);
            }
            table.setItems(data);
        }
        catch(SQLException e){
            throw new RuntimeException(e);
        }
    }
}
