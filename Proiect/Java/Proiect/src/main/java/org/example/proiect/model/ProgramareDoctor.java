package org.example.proiect.model;

public class ProgramareDoctor {
    private int idProgramare;
    private String data;
    private String numePacient;
    private String telefon;
    private String status;
    private String simptome;
    private String descrierePacient; // Nou

    public ProgramareDoctor(int idProgramare, String data, String numePacient, String telefon, String status, String simptome, String descrierePacient) {
        this.idProgramare = idProgramare;
        this.data = data;
        this.numePacient = numePacient;
        this.telefon = telefon;
        this.status = status;
        this.simptome = simptome;
        this.descrierePacient = descrierePacient;
    }

    public int getIdProgramare() { return idProgramare; }
    public String getData() { return data; }
    public String getNumePacient() { return numePacient; }
    public String getTelefon() { return telefon; }
    public String getStatus() { return status; }
    public String getSimptome() { return simptome; }
    public String getDescrierePacient() { return descrierePacient; }
}