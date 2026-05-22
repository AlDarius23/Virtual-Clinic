CREATE OR REPLACE VIEW VIEW_ISTORIC_PACIENT AS
WITH ProgramariAsociate AS (
    SELECT e.id_evaluare, MIN(p.id_programare) AS id_programare_corecta
    FROM EVALUARI_SIMPTOME e
    JOIN PROGRAMARI p
      ON p.id_pacient = e.id_pacient
     AND p.data_ora_inceput >= e.data_evaluare
    GROUP BY e.id_evaluare
)
SELECT
    e.id_pacient,
    e.id_evaluare,
    e.data_evaluare,
    da.diagnostic_provizoriu,
    pr.data_ora_inceput AS data_programare,
    d.nume || ' ' || d.prenume AS nume_doctor,
    da.complexitate,
    fm.diagnostic_final,
    fm.reteta_medicamente,
    fm.recomandari_medicale,
    fm.trimitere_spital
FROM EVALUARI_SIMPTOME e
LEFT JOIN DIAGNOSTICE_AUTOMATE da ON e.id_evaluare = da.id_evaluare
LEFT JOIN ProgramariAsociate pa ON e.id_evaluare = pa.id_evaluare
LEFT JOIN PROGRAMARI pr ON pr.id_programare = pa.id_programare_corecta
LEFT JOIN DOCTORI d ON pr.id_doctor = d.id_doctor
LEFT JOIN FISA_MEDICALA fm ON fm.id_programare = pr.id_programare;
/