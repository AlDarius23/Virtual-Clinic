package org.example.proiect.model;

public class SesiuneUtilizator {
    private static int idLogat;
    private static String numeLogat;
    private static String prenumeLogat;

    public static void setUtilizator(int id, String nume, String prenume) {
        idLogat = id;
        numeLogat = nume;
        prenumeLogat = prenume;
    }

    public static int getIdLogat() { return idLogat; }
    public static String getNumeLogat() { return numeLogat; }
    public static String getPrenumeLogat() { return prenumeLogat; }
}