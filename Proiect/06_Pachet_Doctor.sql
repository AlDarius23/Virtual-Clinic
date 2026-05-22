CREATE OR REPLACE PACKAGE PACHET_DOCTOR AS
    PROCEDURE get_programari_doctor(p_id_doctor IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE finalizare_consultatie(
        p_id_programare IN NUMBER,
        p_diagnostic_final IN VARCHAR2,
        p_reteta IN VARCHAR2,
        p_recomandari IN VARCHAR2,
        p_trimitere IN VARCHAR2
    );
END PACHET_DOCTOR;
/

CREATE OR REPLACE PACKAGE BODY PACHET_DOCTOR AS
    PROCEDURE get_programari_doctor(p_id_doctor IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT 
                p.id_programare, 
                TO_CHAR(p.data_ora_inceput, 'DD.MM.YYYY | HH24:MI'), 
                pac.nume || ' ' || pac.prenume AS nume_pacient, 
                pac.telefon, 
                p.status,
                (SELECT 
                    (SELECT denumire FROM SIMPTOME_CATALOG WHERE id_simptom = e.id_simptom_1) ||
                    NVL((SELECT ', ' || denumire FROM SIMPTOME_CATALOG WHERE id_simptom = e.id_simptom_2), '') ||
                    NVL((SELECT ', ' || denumire FROM SIMPTOME_CATALOG WHERE id_simptom = e.id_simptom_3), '')
                 FROM EVALUARI_SIMPTOME e
                 WHERE e.id_pacient = p.id_pacient
                   AND e.data_evaluare = (SELECT MAX(e2.data_evaluare) FROM EVALUARI_SIMPTOME e2 WHERE e2.id_pacient = p.id_pacient)
                   AND ROWNUM = 1
                ) AS simptome,
                (SELECT e.descriere_pacient 
                 FROM EVALUARI_SIMPTOME e 
                 WHERE e.id_pacient = p.id_pacient 
                   AND e.data_evaluare = (SELECT MAX(e2.data_evaluare) FROM EVALUARI_SIMPTOME e2 WHERE e2.id_pacient = p.id_pacient)
                   AND ROWNUM = 1
                ) AS descriere_pacient
            FROM PROGRAMARI p 
            JOIN PACIENTI pac ON p.id_pacient = pac.id_pacient 
            WHERE p.id_doctor = p_id_doctor 
              AND p.status = 'CONFIRMAT' 
            ORDER BY p.data_ora_inceput ASC;
    END get_programari_doctor;

    PROCEDURE finalizare_consultatie(
        p_id_programare IN NUMBER, p_diagnostic_final IN VARCHAR2, p_reteta IN VARCHAR2, p_recomandari IN VARCHAR2, p_trimitere IN VARCHAR2
    ) IS
        v_exista NUMBER; v_id_fisa_noua NUMBER;
        v_fisier UTL_FILE.FILE_TYPE; v_nume_fisier VARCHAR2(100); v_nume_pacient VARCHAR2(100);
    BEGIN
        UPDATE PROGRAMARI SET status = 'FINALIZAT' WHERE id_programare = p_id_programare;
        SELECT COUNT(*) INTO v_exista FROM FISA_MEDICALA WHERE id_programare = p_id_programare;

        IF v_exista > 0 THEN
            UPDATE FISA_MEDICALA SET diagnostic_final = p_diagnostic_final, reteta_medicamente = p_reteta, recomandari_medicale = p_recomandari, trimitere_spital = p_trimitere
            WHERE id_programare = p_id_programare;
        ELSE
            SELECT NVL(MAX(id_fisa), 0) + 1 INTO v_id_fisa_noua FROM FISA_MEDICALA;
            INSERT INTO FISA_MEDICALA (id_fisa, id_programare, diagnostic_final, reteta_medicamente, recomandari_medicale, trimitere_spital)
            VALUES (v_id_fisa_noua, p_id_programare, p_diagnostic_final, p_reteta, p_recomandari, p_trimitere);
        END IF;

        IF p_trimitere = 'DA' THEN
            SELECT pac.nume || ' ' || pac.prenume INTO v_nume_pacient FROM PROGRAMARI p JOIN PACIENTI pac ON p.id_pacient = pac.id_pacient WHERE p.id_programare = p_id_programare;
            v_nume_fisier := 'Trimitere_Urgenta_Prog_' || p_id_programare || '.txt';
            
            v_fisier := UTL_FILE.FOPEN('DIR_EXPORT', v_nume_fisier, 'W');
            UTL_FILE.PUT_LINE(v_fisier, '=== BILET TRIMITERE URGENTA LA SPITAL ===');
            UTL_FILE.PUT_LINE(v_fisier, 'Data: ' || TO_CHAR(SYSDATE, 'DD.MM.YYYY HH24:MI'));
            UTL_FILE.PUT_LINE(v_fisier, 'Pacient: ' || v_nume_pacient);
            UTL_FILE.PUT_LINE(v_fisier, '-----------------------------------------');
            UTL_FILE.PUT_LINE(v_fisier, 'Diagnostic constatat: ' || p_diagnostic_final);
            UTL_FILE.PUT_LINE(v_fisier, 'Observatii medic: ' || NVL(p_recomandari, 'Nu exista observatii aditionale.'));
            UTL_FILE.PUT_LINE(v_fisier, '=========================================');
            UTL_FILE.FCLOSE(v_fisier);
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF UTL_FILE.IS_OPEN(v_fisier) THEN UTL_FILE.FCLOSE(v_fisier); END IF;
            RAISE;
    END finalizare_consultatie;
END PACHET_DOCTOR;
/