module dbproject.dbprojectgui {
    requires javafx.controls;
    requires javafx.fxml;
    requires java.sql;

    opens dbproject.dbprojectgui to javafx.fxml;
    exports dbproject.dbprojectgui;
    exports dbproject.dbprojectgui.operations;
    opens dbproject.dbprojectgui.operations to javafx.fxml;
}