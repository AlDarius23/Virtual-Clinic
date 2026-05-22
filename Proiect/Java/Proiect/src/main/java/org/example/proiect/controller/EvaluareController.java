package org.example.proiect.controller;

import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.scene.control.Alert;
import javafx.scene.control.ComboBox;
import javafx.scene.control.TextArea;
import javafx.stage.Stage;
import org.example.proiect.db.DatabaseManager;
import org.example.proiect.model.SesiuneUtilizator;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

public class EvaluareController {

    @FXML private ComboBox<String> comboSimptom1;
    @FXML private ComboBox<String> comboSimptom2;
    @FXML private ComboBox<String> comboSimptom3;
    @FXML private TextArea campDescriere;

    private ObservableList<String> listaSimptome = FXCollections.observableArrayList();

    @FXML
    public void initialize() {
        try (Connection conn = DatabaseManager.getConexiune();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT id_simptom || ' - ' || denumire FROM SIMPTOME_CATALOG")) {

            listaSimptome.add("Niciunul");
            while (rs.next()) {
                listaSimptome.add(rs.getString(1));
            }

            comboSimptom1.setItems(listaSimptome);
            comboSimptom2.setItems(listaSimptome);
            comboSimptom3.setItems(listaSimptome);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @FXML
    protected void trimiteEvaluare() {
        String val1 = comboSimptom1.getValue();
        if (val1 == null || val1.equals("Niciunul")) {
            new Alert(Alert.AlertType.ERROR, "Primul simptom este obligatoriu!").showAndWait();
            return;
        }

        try (Connection conn = DatabaseManager.getConexiune();
             CallableStatement cstmtInit = conn.prepareCall("{call PACHET_TELEMEDICINA.initiaza_evaluare(?, ?, ?, ?, ?, ?)}");
             CallableStatement cstmtProc = conn.prepareCall("{call PACHET_TELEMEDICINA.proceseaza_diagnostic(?)}")) {

            cstmtInit.setInt(1, SesiuneUtilizator.getIdLogat());
            cstmtInit.setInt(2, extrageId(val1));

            String val2 = comboSimptom2.getValue();
            if (val2 != null && !val2.equals("Niciunul")) {
                cstmtInit.setInt(3, extrageId(val2));
            } else {
                cstmtInit.setNull(3, java.sql.Types.NUMERIC);
            }

            String val3 = comboSimptom3.getValue();
            if (val3 != null && !val3.equals("Niciunul")) {
                cstmtInit.setInt(4, extrageId(val3));
            } else {
                cstmtInit.setNull(4, java.sql.Types.NUMERIC);
            }

            String descriereCompleta = campDescriere.getText();
            if (descriereCompleta != null) {
                cstmtInit.setString(5, descriereCompleta);
            } else {
                cstmtInit.setString(5, "");
            }

            cstmtInit.registerOutParameter(6, java.sql.Types.NUMERIC);
            cstmtInit.execute();

            int idEvaluareNoua = cstmtInit.getInt(6);

            cstmtProc.setInt(1, idEvaluareNoua);
            cstmtProc.execute();

            new Alert(Alert.AlertType.INFORMATION, "Evaluare trimisă cu succes!").showAndWait();
            inchideFereastra();

        } catch (Exception e) {
            new Alert(Alert.AlertType.ERROR, "Eroare: " + e.getMessage()).showAndWait();
            e.printStackTrace();
        }
    }

    private int extrageId(String valoareCombo) {
        return Integer.parseInt(valoareCombo.split(" - ")[0]);
    }

    @FXML
    protected void inchideFereastra() {
        Stage stage = (Stage) comboSimptom1.getScene().getWindow();
        stage.close();
    }
}