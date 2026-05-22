package org.example.proiect.controller;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Insets;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import org.example.proiect.db.DatabaseManager;
import org.example.proiect.model.ProgramareDoctor;
import org.example.proiect.model.SesiuneUtilizator;
import oracle.jdbc.OracleTypes;

import java.sql.*;
import java.util.Optional;

public class DoctorDashboardController {

    @FXML private Label etichetaBunVenit;
    @FXML private TableView<ProgramareDoctor> tabelProgramari;
    @FXML private TableColumn<ProgramareDoctor, String> colData;
    @FXML private TableColumn<ProgramareDoctor, String> colPacient;
    @FXML private TableColumn<ProgramareDoctor, String> colTelefon;
    @FXML private TableColumn<ProgramareDoctor, String> colSimptome;
    @FXML private TableColumn<ProgramareDoctor, String> colDescrierePacient;
    @FXML private TableColumn<ProgramareDoctor, String> colStatus;

    @FXML
    public void initialize() {
        etichetaBunVenit.setText("Bun venit, " + SesiuneUtilizator.getNumeLogat() + "!");

        colData.setCellValueFactory(new PropertyValueFactory<>("data"));
        colPacient.setCellValueFactory(new PropertyValueFactory<>("numePacient"));
        colTelefon.setCellValueFactory(new PropertyValueFactory<>("telefon"));
        colSimptome.setCellValueFactory(new PropertyValueFactory<>("simptome"));
        colDescrierePacient.setCellValueFactory(new PropertyValueFactory<>("descrierePacient"));
        colStatus.setCellValueFactory(new PropertyValueFactory<>("status"));

        incarcaProgramari();
    }

    @FXML
    protected void incarcaProgramari() {
        tabelProgramari.getItems().clear();

        try (Connection conn = DatabaseManager.getConexiune();
             CallableStatement cstmt = conn.prepareCall("{call PACHET_DOCTOR.get_programari_doctor(?, ?)}")) {

            cstmt.setInt(1, SesiuneUtilizator.getIdLogat());
            cstmt.registerOutParameter(2, OracleTypes.CURSOR);
            cstmt.execute();

            try (ResultSet rs = (ResultSet) cstmt.getObject(2)) {
                while (rs.next()) {
                    tabelProgramari.getItems().add(new ProgramareDoctor(
                            rs.getInt(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getString(4),
                            rs.getString(5),
                            rs.getString(6),
                            rs.getString(7)
                    ));
                }
            }
            tabelProgramari.refresh();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    @FXML
    protected void finalizeazaConsultatie() {
        ProgramareDoctor selectata = tabelProgramari.getSelectionModel().getSelectedItem();

        if (selectata == null) {
            new Alert(Alert.AlertType.WARNING, "Selectați o programare din tabel!").showAndWait();
            return;
        }

        if (!selectata.getStatus().equals("CONFIRMAT")) {
            new Alert(Alert.AlertType.WARNING, "Doar programările cu status CONFIRMAT pot fi finalizate!").showAndWait();
            return;
        }

        Dialog<ButtonType> dialog = new Dialog<>();
        dialog.setTitle("Finalizare Consultație");
        dialog.setHeaderText("Pacient: " + selectata.getNumePacient() + "\nSimptome: " + selectata.getSimptome() + "\nDescriere: " + selectata.getDescrierePacient());
        dialog.getDialogPane().getButtonTypes().addAll(ButtonType.OK, ButtonType.CANCEL);

        TextField campDiagnostic = new TextField();
        campDiagnostic.setPromptText("Diagnostic final (obligatoriu)...");

        TextArea campReteta = new TextArea();
        campReteta.setPromptText("Rețetă medicamente...");
        campReteta.setPrefRowCount(3);

        TextArea campRecomandari = new TextArea();
        campRecomandari.setPromptText("Recomandări medicale...");
        campRecomandari.setPrefRowCount(3);

        ComboBox<String> comboTrimitere = new ComboBox<>();
        comboTrimitere.getItems().addAll("NU", "DA");
        comboTrimitere.setValue("NU");

        VBox content = new VBox(8);
        content.setPadding(new Insets(10));
        content.getChildren().addAll(
                new Label("Diagnostic final:"), campDiagnostic,
                new Label("Rețetă:"), campReteta,
                new Label("Recomandări:"), campRecomandari,
                new Label("Trimitere spital:"), comboTrimitere
        );
        dialog.getDialogPane().setContent(content);

        Optional<ButtonType> result = dialog.showAndWait();

        if (result.isPresent()) {
            if (result.get() == ButtonType.OK) {
                if (campDiagnostic.getText().trim().isEmpty()) {
                    new Alert(Alert.AlertType.ERROR, "Diagnosticul final este obligatoriu!").showAndWait();
                    return;
                }

                try (Connection conn = DatabaseManager.getConexiune();
                     CallableStatement cstmt = conn.prepareCall("{call PACHET_DOCTOR.finalizare_consultatie(?, ?, ?, ?, ?)}")) {

                    cstmt.setInt(1, selectata.getIdProgramare());
                    cstmt.setString(2, campDiagnostic.getText());
                    cstmt.setString(3, campReteta.getText());
                    cstmt.setString(4, campRecomandari.getText());
                    cstmt.setString(5, comboTrimitere.getValue());
                    cstmt.execute();

                    new Alert(Alert.AlertType.INFORMATION, "Consultația a fost finalizată cu succes!").showAndWait();
                    incarcaProgramari();

                } catch (SQLException e) {
                    new Alert(Alert.AlertType.ERROR, "Eroare: " + e.getMessage()).showAndWait();
                    e.printStackTrace();
                }
            }
        }
    }

    @FXML
    protected void logout() {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/org/example/proiect/login.fxml"));
            javafx.scene.Parent root = loader.load();
            Scene scene = new Scene(root);
            Stage stage = (Stage) etichetaBunVenit.getScene().getWindow();
            stage.setScene(scene);
            stage.setMaximized(true);
            stage.centerOnScreen();
            stage.setTitle("Sistem Telemedicină");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}