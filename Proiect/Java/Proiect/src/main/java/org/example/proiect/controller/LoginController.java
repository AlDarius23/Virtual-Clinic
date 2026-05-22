package org.example.proiect.controller;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.scene.control.*;
import javafx.scene.layout.VBox;
import javafx.stage.Stage;
import org.example.proiect.db.DatabaseManager;
import org.example.proiect.model.SesiuneUtilizator;

import java.sql.*;
import java.time.LocalDate;

public class LoginController {


    @FXML private TextField campIdLogin;
    @FXML private Label etichetaEroare;



    @FXML private VBox sectiuneInregistrare;
    @FXML private TextField campCnp;
    @FXML private TextField campNume;
    @FXML private TextField campPrenume;
    @FXML private DatePicker campDataNasterii;
    @FXML private TextField campTelefon;
    @FXML private TextField campNumeTutore;
    @FXML private TextField campTelefonTutore;
    @FXML private ComboBox<String> comboAbonament;

    @FXML
    public void initialize() {
        if (comboAbonament != null) {
            comboAbonament.getItems().addAll("LUNAR", "ANUAL");
        }
    }

    @FXML
    protected void actiuneLoginPacient() {
        String idText = campIdLogin.getText();
        if (idText.isEmpty()) {
            etichetaEroare.setStyle("-fx-text-fill: red;");
            etichetaEroare.setText("Eroare: Introduceți ID-ul!");
            return;
        }

        try (Connection conn = DatabaseManager.getConexiune();
             PreparedStatement pstmt = conn.prepareStatement("SELECT nume, prenume FROM PACIENTI WHERE id_pacient = ?")) {

            pstmt.setInt(1, Integer.parseInt(idText));
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                String nume = rs.getString("nume");
                String prenume = rs.getString("prenume");

                String numeComplet;
                if (prenume != null) {
                    numeComplet = nume + " " + prenume;
                } else {
                    numeComplet = nume;
                }

                etichetaEroare.setStyle("-fx-text-fill: green;");
                etichetaEroare.setText("Bun venit, " + numeComplet + "! Se încarcă dashboard-ul");

                SesiuneUtilizator.setUtilizator(Integer.parseInt(idText), nume, prenume);

                FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/org/example/proiect/pacient-dashboard.fxml"));
                javafx.scene.Parent root = fxmlLoader.load();
                Scene scene = new Scene(root);

                Stage stage = (Stage) campIdLogin.getScene().getWindow();
                stage.setScene(scene);
                stage.setMaximized(true);
                stage.centerOnScreen();
                stage.setTitle("Dashboard Pacient - " + numeComplet);

            } else {
                etichetaEroare.setStyle("-fx-text-fill: red;");
                etichetaEroare.setText("Eroare: ID Pacient inexistent!");
            }
        } catch (Exception e) {
            e.printStackTrace();
            etichetaEroare.setText("Eroare tehnica: " + e.getMessage());
        }
    }

    @FXML
    protected void actiuneLoginDoctor() {
        String idText = campIdLogin.getText();
        if (idText.isEmpty()) {
            etichetaEroare.setStyle("-fx-text-fill: red;");
            etichetaEroare.setText("Eroare: Introduceți ID-ul!");
            return;
        }

        try (Connection conn = DatabaseManager.getConexiune();
             PreparedStatement pstmt = conn.prepareStatement(
                     "SELECT * FROM DOCTORI WHERE id_doctor = ?")) {

            pstmt.setInt(1, Integer.parseInt(idText));
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                String numeDoctor = rs.getString("nume");
                String prenumeDoctor = null;

                ResultSetMetaData rsmd = rs.getMetaData();
                int columns = rsmd.getColumnCount();
                for (int i = 1; i <= columns; i++) {
                    if (rsmd.getColumnName(i).equalsIgnoreCase("PRENUME")) {
                        prenumeDoctor = rs.getString("prenume");
                    }
                }

                String numeComplet;
                if (prenumeDoctor != null) {
                    if (prenumeDoctor.isEmpty() == false) {
                        numeComplet = numeDoctor + " " + prenumeDoctor;
                    } else {
                        numeComplet = numeDoctor;
                    }
                } else {
                    numeComplet = numeDoctor;
                }

                SesiuneUtilizator.setUtilizator(Integer.parseInt(idText), numeComplet, "");

                etichetaEroare.setStyle("-fx-text-fill: green;");
                etichetaEroare.setText("Bun venit, " + numeComplet + "! Se încarcă");

                FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/org/example/proiect/doctor-dashboard.fxml"));
                javafx.scene.Parent root = fxmlLoader.load();
                Scene scene = new Scene(root);

                Stage stage = (Stage) campIdLogin.getScene().getWindow();
                stage.setScene(scene);
                stage.setMaximized(true);
                stage.centerOnScreen();
                stage.setTitle("Dashboard Doctor - " + numeComplet);

            } else {
                etichetaEroare.setStyle("-fx-text-fill: red;");
                etichetaEroare.setText("Eroare: ID Doctor inexistent!");
            }
        } catch (Exception e) {
            e.printStackTrace();
            etichetaEroare.setText("Eroare tehnica: " + e.getMessage());
        }
    }
    @FXML
    protected void arataFormularInregistrare() {
        sectiuneInregistrare.setVisible(true);
        sectiuneInregistrare.setManaged(true);
    }

    @FXML
    protected void actiuneInregistrare() {
        String cnp = campCnp.getText();
        String nume = campNume.getText();
        String prenume = campPrenume.getText();
        LocalDate dataNastere = campDataNasterii.getValue();
        String telefon = campTelefon.getText();
        String tipAbonament = comboAbonament.getValue();

        if (cnp.isEmpty() || nume.isEmpty() || prenume.isEmpty() || dataNastere == null || tipAbonament == null) {
            etichetaEroare.setStyle("-fx-text-fill: red;");
            etichetaEroare.setText("Eroare: Completați câmpurile obligatorii și alegeți abonamentul!");
            return;
        }

        if (dataNastere.isAfter(LocalDate.now().minusYears(18))) {
            if (campNumeTutore.getText().isEmpty() || campTelefonTutore.getText().isEmpty()) {
                etichetaEroare.setStyle("-fx-text-fill: red;");
                etichetaEroare.setText("Eroare: Datele tutorelui sunt obligatorii pentru minori!");
                return;
            }
        }

        try (Connection conn = DatabaseManager.getConexiune()) {
            conn.setAutoCommit(false);

            int idPacientNou;
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT NVL(MAX(id_pacient), 0) + 1 FROM PACIENTI")) {
                rs.next();
                idPacientNou = rs.getInt(1);
            }

            String sqlP = "INSERT INTO PACIENTI (id_pacient, cnp, nume, prenume, telefon, data_nasterii, nume_tutore, telefon_tutore) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            try (PreparedStatement psP = conn.prepareStatement(sqlP)) {
                psP.setInt(1, idPacientNou);
                psP.setString(2, cnp);
                psP.setString(3, nume);
                psP.setString(4, prenume);
                psP.setString(5, telefon);
                psP.setDate(6, Date.valueOf(dataNastere));
                psP.setString(7, campNumeTutore.getText());
                psP.setString(8, campTelefonTutore.getText());
                psP.executeUpdate();
            }

            int idAbonamentNou;
            try (Statement stmt = conn.createStatement();
                 ResultSet rs = stmt.executeQuery("SELECT NVL(MAX(id_abonament), 0) + 1 FROM ABONAMENTE")) {
                rs.next();
                idAbonamentNou = rs.getInt(1);
            }

            String sqlA = "INSERT INTO ABONAMENTE (id_abonament, id_pacient, tip, data_creare, data_expirare, cost, stare_curenta) VALUES (?, ?, ?, SYSDATE, SYSDATE + 365, 100, 'ACTIV')";
            try (PreparedStatement psA = conn.prepareStatement(sqlA)) {
                psA.setInt(1, idAbonamentNou);
                psA.setInt(2, idPacientNou);
                psA.setString(3, tipAbonament);
                psA.executeUpdate();
            }

            conn.commit();

            etichetaEroare.setStyle("-fx-text-fill: green;");
            etichetaEroare.setText("Cont creat! ID-ul tău de login este: " + idPacientNou);
            sectiuneInregistrare.setVisible(false);

        } catch (Exception e) {
            etichetaEroare.setStyle("-fx-text-fill: red;");
            etichetaEroare.setText("Eroare la înregistrare: " + e.getMessage());
            e.printStackTrace();
        }
    }
}