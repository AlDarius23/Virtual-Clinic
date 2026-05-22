CREATE OR REPLACE PACKAGE PACHET_TELEMEDICINA IS
    exc_lipsa_locuri EXCEPTION;

    PROCEDURE initiaza_evaluare(
        p_id_pacient IN NUMBER,
        p_id_simptom_1 IN NUMBER,
        p_id_simptom_2 IN NUMBER,
        p_id_simptom_3 IN NUMBER,
        p_descriere_pacient IN VARCHAR2,
        p_id_evaluare_generata OUT NUMBER
    );

    PROCEDURE proceseaza_diagnostic(p_id_evaluare IN NUMBER);

END PACHET_TELEMEDICINA;
/

CREATE OR REPLACE PACKAGE BODY PACHET_TELEMEDICINA IS

    PROCEDURE initiaza_evaluare(
        p_id_pacient IN NUMBER,
        p_id_simptom_1 IN NUMBER,
        p_id_simptom_2 IN NUMBER,
        p_id_simptom_3 IN NUMBER,
        p_descriere_pacient IN VARCHAR2,
        p_id_evaluare_generata OUT NUMBER
    ) IS
        v_id_eval_noua NUMBER;
    BEGIN
        SELECT NVL(MAX(id_evaluare), 0) + 1 INTO v_id_eval_noua FROM EVALUARI_SIMPTOME;
        
        INSERT INTO EVALUARI_SIMPTOME (id_evaluare, id_pacient, id_simptom_1, id_simptom_2, id_simptom_3, descriere_pacient, data_evaluare)
        VALUES (v_id_eval_noua, p_id_pacient, p_id_simptom_1, p_id_simptom_2, p_id_simptom_3, p_descriere_pacient, SYSDATE);
        
        p_id_evaluare_generata := v_id_eval_noua;
        COMMIT;
    END initiaza_evaluare;



    PROCEDURE proceseaza_diagnostic(p_id_evaluare IN NUMBER) IS
        v_id_pacient          NUMBER;
        v_id_simptom_1        NUMBER;
        v_cat_simptom         VARCHAR2(50);
        v_specializare_aleasa VARCHAR2(100);
        v_varsta              NUMBER;
        v_cronice             NUMBER;
        v_id_regula           NUMBER;
        v_diagnostic          VARCHAR2(500);
        v_complexitate        NUMBER;
        v_reteta_auto         VARCHAR2(3);
        v_reteta_text         VARCHAR2(1000);

        v_id_doctor_ales NUMBER := NULL;
        v_data_prog      DATE;
        v_data_test      DATE;
        v_gasit          NUMBER;
        v_id_prog_noua   NUMBER;
        v_id_diag_noua   NUMBER;
        v_id_fisa_noua   NUMBER;

        CURSOR c_doctori (p_spec VARCHAR2) IS
            SELECT id_doctor, ora_start, ora_sfarsit FROM DOCTORI WHERE specializare = p_spec;
    BEGIN
        SELECT id_pacient, id_simptom_1 INTO v_id_pacient, v_id_simptom_1 FROM EVALUARI_SIMPTOME WHERE id_evaluare = p_id_evaluare;

        SELECT FLOOR(MONTHS_BETWEEN(SYSDATE, data_nasterii) / 12) INTO v_varsta FROM PACIENTI WHERE id_pacient = v_id_pacient;

        SELECT COUNT(*) INTO v_cronice FROM AFECTIUNI_PACIENT WHERE id_pacient = v_id_pacient;
        SELECT categorie INTO v_cat_simptom FROM SIMPTOME_CATALOG WHERE id_simptom = v_id_simptom_1;

        IF v_cat_simptom = 'CARDIAC' THEN
            v_specializare_aleasa := 'Cardiologie';
        ELSIF v_cat_simptom = 'NEUROLOGIC' THEN
            v_specializare_aleasa := 'Neurologie';
        ELSIF v_cat_simptom = 'DIGESTIV' THEN
            v_specializare_aleasa := 'Gastroenterologie';
        ELSIF v_cat_simptom = 'RESPIRATOR' THEN
            v_specializare_aleasa := 'Pneumologie';
        ELSIF v_cat_simptom = 'PEDIATRIC' THEN
            v_specializare_aleasa := 'Pediatrie';
        ELSE
            v_specializare_aleasa := 'Medicina Interna';
        END IF;

        BEGIN
            SELECT r.id_regula, r.diagnostic_probabil, r.complexitate, r.reteta_automata, r.reteta_text
            INTO v_id_regula, v_diagnostic, v_complexitate, v_reteta_auto, v_reteta_text
            FROM REGULI_DIAGNOSTIC r JOIN REGULI_SIMPTOME rs ON r.id_regula = rs.id_regula
            WHERE rs.id_simptom = v_id_simptom_1 AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_id_regula := 15; v_diagnostic := 'Simptom nespecific'; v_complexitate := 1; v_reteta_auto := 'NU'; v_reteta_text := NULL;
        END;

        IF v_varsta < 5 THEN
            v_complexitate := v_complexitate + 1;
            v_diagnostic := '[PEDIATRIC] ' || v_diagnostic;
        ELSIF v_varsta > 65 THEN
            v_complexitate := v_complexitate + 1;
            v_diagnostic := '[GERIATRIC] ' || v_diagnostic;
        END IF;

        IF v_cronice > 0 THEN
            v_complexitate := v_complexitate + 1;
            v_diagnostic := '[RISC CRONIC] ' || v_diagnostic;
        END IF;

        SELECT NVL(MAX(id_diagnostic_auto), 0) + 1 INTO v_id_diag_noua FROM DIAGNOSTICE_AUTOMATE;
        INSERT INTO DIAGNOSTICE_AUTOMATE (id_diagnostic_auto, id_evaluare, id_regula_aplicata, diagnostic_provizoriu, complexitate)
        VALUES (v_id_diag_noua, p_id_evaluare, v_id_regula, v_diagnostic, v_complexitate);

        IF v_complexitate <= 2 AND v_reteta_auto = 'DA' THEN
            SELECT NVL(MAX(id_programare), 0) + 1 INTO v_id_prog_noua FROM PROGRAMARI;
            INSERT INTO PROGRAMARI (id_programare, id_pacient, id_doctor, data_ora_inceput, durata_minute, status)
            VALUES (v_id_prog_noua, v_id_pacient, 1, SYSDATE + 1/1440, 10, 'FINALIZAT_AUTOMAT');

            SELECT NVL(MAX(id_fisa), 0) + 1 INTO v_id_fisa_noua FROM FISA_MEDICALA;
            INSERT INTO FISA_MEDICALA (id_fisa, id_programare, diagnostic_final, reteta_medicamente, recomandari_medicale, trimitere_spital)
            VALUES (v_id_fisa_noua, v_id_prog_noua, v_diagnostic, v_reteta_text, 'Odihna si hidratare.', 'NU');
        ELSE
            FOR v_zi IN 1..7 LOOP
                FOR v_doc IN c_doctori(v_specializare_aleasa) LOOP
                    FOR v_ora IN v_doc.ora_start..(v_doc.ora_sfarsit - 1) LOOP
                        v_data_test := TRUNC(SYSDATE) + v_zi + (v_ora / 24);

                        SELECT COUNT(*) INTO v_gasit FROM PROGRAMARI WHERE id_doctor = v_doc.id_doctor AND status = 'CONFIRMAT' AND data_ora_inceput = v_data_test;

                        IF v_gasit = 0 THEN
                            v_id_doctor_ales := v_doc.id_doctor;
                            v_data_prog := v_data_test;
                            EXIT;
                        END IF;
                    END LOOP;
                    IF v_id_doctor_ales IS NOT NULL THEN EXIT; END IF;
                END LOOP;
                IF v_id_doctor_ales IS NOT NULL THEN EXIT; END IF;
            END LOOP;

            IF v_id_doctor_ales IS NOT NULL THEN
                SELECT NVL(MAX(id_programare), 0) + 1 INTO v_id_prog_noua FROM PROGRAMARI;
                INSERT INTO PROGRAMARI (id_programare, id_pacient, id_doctor, data_ora_inceput, durata_minute, status)
                VALUES (v_id_prog_noua, v_id_pacient, v_id_doctor_ales, v_data_prog, 20, 'CONFIRMAT');
            ELSE
                RAISE exc_lipsa_locuri;
            END IF;
        END IF;

        COMMIT;
    EXCEPTION
        WHEN exc_lipsa_locuri THEN
            DBMS_OUTPUT.PUT_LINE('Eroare: Nu s-a putut gasi un slot liber pentru pacient.');
    END proceseaza_diagnostic;



END PACHET_TELEMEDICINA;
/