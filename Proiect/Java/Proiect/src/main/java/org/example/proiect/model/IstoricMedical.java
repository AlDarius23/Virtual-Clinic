package org.example.proiect.model;

public class IstoricMedical {
    private String data;
    private String diagnosticProvizoriu;
    private String diagnosticFinal;
    private String reteta;
    private String recomandari;

    public IstoricMedical(String data, String dp, String df, String r, String rec) {
        this.data = data;
        this.diagnosticProvizoriu = dp;
        this.diagnosticFinal = df;
        this.reteta = r;
        this.recomandari = rec;
    }

    public String getData() { return data; }
    public String getDiagnosticProvizoriu() { return diagnosticProvizoriu; }
    public String getDiagnosticFinal() { return diagnosticFinal; }
    public String getReteta() { return reteta; }
    public String getRecomandari() { return recomandari; }
}