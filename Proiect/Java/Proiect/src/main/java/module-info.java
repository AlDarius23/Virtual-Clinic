module org.example.proiect {
    requires javafx.controls;
    requires javafx.fxml;
    requires java.sql;
    requires com.oracle.database.jdbc;

    opens org.example.proiect to javafx.fxml;
    exports org.example.proiect;

    exports org.example.proiect.db;
    opens org.example.proiect.db to javafx.fxml;

    exports org.example.proiect.controller;
    opens org.example.proiect.controller to javafx.fxml;

    // Liniile noi obligatorii pentru ca Tabelul sa poata citi clasa IstoricMedical
    exports org.example.proiect.model;
    opens org.example.proiect.model to javafx.base;
}