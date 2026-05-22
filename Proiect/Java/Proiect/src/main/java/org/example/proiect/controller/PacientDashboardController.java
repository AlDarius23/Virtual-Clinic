package org.example.proiect.controller;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.HBox;
import javafx.scene.layout.VBox;
import javafx.stage.Modality;
import javafx.stage.Stage;
import org.example.proiect.db.DatabaseManager;
import org.example.proiect.model.IstoricMedical;
import org.example.proiect.model.SesiuneUtilizator;
import oracle.jdbc.OracleTypes;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

public class PacientDashboardController {

    @FXML private Label etichetaBunVenit;
    @FXML private TableView<IstoricMedical> tabelIstoric;
    @FXML private TableColumn<IstoricMedical, String> colData;
    @FXML private TableColumn<IstoricMedical, String> colDiagProv;
    @FXML private TableColumn<IstoricMedical, String> colDiagFinal;
    @FXML private TableColumn<IstoricMedical, String> colReteta;
    @FXML private Label etichetaExpirare;
    @FXML private TableColumn<IstoricMedical, String> colRecomandari;

    @FXML
    public void initialize() {
        String numeComplet = SesiuneUtilizator.getNumeLogat() + " " + SesiuneUtilizator.getPrenumeLogat();
        etichetaBunVenit.setText("Bun venit, " + numeComplet + "!");


        incarcaInfoAbonament();

        colData.setCellValueFactory(new PropertyValueFactory<>("data"));
        colDiagProv.setCellValueFactory(new PropertyValueFactory<>("diagnosticProvizoriu"));
        colDiagFinal.setCellValueFactory(new PropertyValueFactory<>("diagnosticFinal"));
        colReteta.setCellValueFactory(new PropertyValueFactory<>("reteta"));
        colRecomandari.setCellValueFactory(new PropertyValueFactory<>("recomandari"));
        incarcaDateIstoric();
    }

    private void incarcaInfoAbonament() {
        try (Connection conn = DatabaseManager.getConexiune();
             CallableStatement cstmt = conn.prepareCall("{call PACHET_DASHBOARD.get_info_abonament(?, ?)}")) {

            cstmt.setInt(1, SesiuneUtilizator.getIdLogat());
            cstmt.registerOutParameter(2, java.sql.Types.VARCHAR);
            cstmt.execute();

            String dataExp = cstmt.getString(2);
            etichetaExpirare.setText("Abonament valabil până la: " + dataExp);

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    @FXML
    protected void incarcaDateIstoric() {
        tabelIstoric.getItems().clear();

        try (Connection conn = DatabaseManager.getConexiune();
             CallableStatement pstmt = conn.prepareCall("{call PACHET_DASHBOARD.get_istoric_pacient(?, ?)}")) {

            pstmt.setInt(1, SesiuneUtilizator.getIdLogat());
            pstmt.registerOutParameter(2, OracleTypes.CURSOR);
            pstmt.execute();

            try (ResultSet rs = (ResultSet) pstmt.getObject(2)) {
                while (rs.next()) {
                    tabelIstoric.getItems().add(new IstoricMedical(
                            rs.getString(1),
                            rs.getString(2),
                            rs.getString(3),
                            rs.getString(4),
                            rs.getString(5)
                    ));
                }
            }

            tabelIstoric.refresh();

        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    @FXML
    protected void deschideEvaluare() {
        try {
            FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/org/example/proiect/evaluare.fxml"));
            Parent root = fxmlLoader.load();
            Stage stage = new Stage();
            stage.initModality(Modality.APPLICATION_MODAL);
            stage.setTitle("Evaluare Nouă");
            stage.setScene(new Scene(root));

            stage.showAndWait();

            incarcaDateIstoric();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @FXML
    protected void arataBiletProgramare() {
        try (Connection conn = DatabaseManager.getConexiune();
             CallableStatement pstmt = conn.prepareCall("{call PACHET_DASHBOARD.get_bilet_programare(?, ?)}")) {

            pstmt.setInt(1, SesiuneUtilizator.getIdLogat());
            pstmt.registerOutParameter(2, OracleTypes.CURSOR);
            pstmt.execute();

            try (ResultSet rs = (ResultSet) pstmt.getObject(2)) {
                if (rs.next()) {
                    Stage stageBilet = new Stage();
                    stageBilet.setTitle("Bilet Programare Digital");

                    VBox containerPrincipal = new VBox();
                    containerPrincipal.getStyleClass().add("card-programare");

                    HBox header = new HBox();
                    header.getStyleClass().add("header-bilet");
                    Label titlu = new Label("CONFIRMARE PROGRAMARE");
                    titlu.getStyleClass().add("titlu-bilet");
                    header.getChildren().add(titlu);

                    VBox corp = new VBox(10);
                    corp.getStyleClass().add("corp-bilet");

                    Button btnReprogrameaza = new Button("Nu pot ajunge");
                    btnReprogrameaza.setStyle("-fx-background-color: #ef4444; -fx-text-fill: white; -fx-font-weight: bold; -fx-cursor: hand;");
                    btnReprogrameaza.setOnAction(e -> reprogrameaza(stageBilet));

                    corp.getChildren().addAll(
                            creeazaRandInfo("PACIENT", SesiuneUtilizator.getNumeLogat() + " " + SesiuneUtilizator.getPrenumeLogat()),
                            creeazaRandInfo("MEDIC", rs.getString(2)),
                            creeazaRandInfo("SPECIALIZARE", rs.getString(3)),
                            new Separator(),
                            creeazaRandInfo("DATA ȘI ORA", rs.getString(1)),
                            new Separator(),
                            btnReprogrameaza
                    );

                    containerPrincipal.getChildren().addAll(header, corp);
                    VBox rootNode = new VBox(containerPrincipal);
                    rootNode.getStyleClass().add("fereastra-bilet");
                    rootNode.getStylesheets().add(getClass().getResource("/org/example/proiect/style.css").toExternalForm());

                    stageBilet.setScene(new Scene(rootNode, 380, 500));

                    stageBilet.show();
                } else {
                    Alert alert = new Alert(Alert.AlertType.INFORMATION);
                    alert.setContentText("Nu aveți nicio programare activă în acest moment.");
                    alert.showAndWait();
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    private void reprogrameaza(Stage stageBilet) {
        try (Connection conn = DatabaseManager.getConexiune();
             CallableStatement cstmt = conn.prepareCall("{call PACHET_DASHBOARD.reprogrameaza(?, ?)}")) {

            cstmt.setInt(1, SesiuneUtilizator.getIdLogat());
            cstmt.registerOutParameter(2, Types.VARCHAR);
            cstmt.execute();


            String mesaj = cstmt.getString(2);

            Alert alert = new Alert(Alert.AlertType.INFORMATION);
            alert.setTitle("Reprogramare");
            alert.setHeaderText(null);
            alert.setContentText(mesaj);
            alert.showAndWait();

            stageBilet.close();
            incarcaDateIstoric();

        } catch (SQLException ex) {
            ex.printStackTrace();
        }
    }

    private VBox creeazaRandInfo(String eticheta, String valoare) {
        VBox rand = new VBox(2);
        Label lblEticheta = new Label(eticheta + ":");
        lblEticheta.getStyleClass().add("eticheta-info");

        Label lblValoare = new Label(valoare);
        lblValoare.getStyleClass().add("valoare-info");

        rand.getChildren().addAll(lblEticheta, lblValoare);
        return rand;
    }

    @FXML
    protected void logout() {
        try {
            FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/org/example/proiect/login.fxml"));
            javafx.scene.Parent root = fxmlLoader.load();
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


    @FXML
    protected void reinnoiesteAbonament() {
        java.util.List<String> optiuni = java.util.Arrays.asList("LUNAR", "ANUAL");
        ChoiceDialog<String> dialog = new ChoiceDialog<>("LUNAR", optiuni);
        dialog.setTitle("Abonament Nou");
        dialog.setHeaderText("Alegeți tipul de abonament dorit:");
        dialog.setContentText("Opțiune:");

        java.util.Optional<String> rezultat = dialog.showAndWait();

        if (rezultat.isPresent()) {
            String tipAles = rezultat.get();
            String detalii = "";

            if (tipAles.equals("LUNAR")) {
                detalii = "Cost: 50 RON\nDurată: 30 de zile";
            } else if (tipAles.equals("ANUAL")) {
                detalii = "Cost: 500 RON\nDurată: 365 de zile";
            }

            Alert confirmare = new Alert(Alert.AlertType.CONFIRMATION);
            confirmare.setTitle("Confirmare Plată");
            confirmare.setHeaderText("Detaliile abonamentului selectat:");
            confirmare.setContentText(detalii + "\n\nSunteți sigur că doriți să continuați?");

            if (confirmare.showAndWait().get() == ButtonType.OK) {
                try (Connection conn = org.example.proiect.db.DatabaseManager.getConexiune();
                     CallableStatement cstmt = conn.prepareCall("{call PACHET_DASHBOARD.prelungeste_abonament(?, ?, ?)}")) {

                    cstmt.setInt(1, SesiuneUtilizator.getIdLogat());
                    cstmt.setString(2, tipAles);
                    cstmt.registerOutParameter(3, java.sql.Types.VARCHAR);
                    cstmt.execute();

                    Alert succes = new Alert(Alert.AlertType.INFORMATION);
                    succes.setTitle("Finalizat");
                    succes.setHeaderText(null);
                    succes.setContentText(cstmt.getString(3));
                    succes.showAndWait();

                    incarcaInfoAbonament();

                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}