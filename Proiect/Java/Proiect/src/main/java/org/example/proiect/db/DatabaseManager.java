package org.example.proiect.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseManager {


    private static final String URL_BD = "jdbc:oracle:thin:@localhost:1521:xe";
    private static final String UTILIZATOR = "STUDENT";
    private static final String PAROLA = "STUDENT";

    public static Connection getConexiune() {
        Connection conexiune = null;

        try {

            Class.forName("oracle.jdbc.driver.OracleDriver");


            conexiune = DriverManager.getConnection(URL_BD, UTILIZATOR, PAROLA);
            System.out.println("Conexiune la baza de date reusita!");

        } catch (ClassNotFoundException e) {
            System.out.println("Eroare: Nu gasesc driverul ojdbc8! Verifica fisierul pom.xml.");
            e.printStackTrace();
        } catch (SQLException e) {
            System.out.println("Eroare la conectarea cu baza de date Oracle!");
            e.printStackTrace();
        }

        return conexiune;
    }
}