CREATE OR REPLACE PACKAGE PACHET_DASHBOARD AS
    PROCEDURE get_istoric_pacient(p_id_pacient IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE get_bilet_programare(p_id_pacient IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE reprogrameaza(p_id_pacient IN NUMBER, p_mesaj OUT VARCHAR2);
    PROCEDURE prelungeste_abonament(p_id_pacient IN NUMBER, p_tip IN VARCHAR2, p_mesaj OUT VARCHAR2);
    PROCEDURE get_info_abonament(p_id_pacient IN NUMBER, p_data_exp OUT VARCHAR2);
END PACHET_DASHBOARD;
/

CREATE OR REPLACE PACKAGE BODY PACHET_DASHBOARD AS

    PROCEDURE get_istoric_pacient(p_id_pacient IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT 
                NVL(TO_CHAR(data_programare, 'DD.MM.YYYY HH24:MI') || ' (' || nume_doctor || ')', TO_CHAR(data_evaluare, 'DD.MM.YYYY')), 
                diagnostic_provizoriu, 
                diagnostic_final, 
                reteta_medicamente,
                recomandari_medicale
            FROM VIEW_ISTORIC_PACIENT 
            WHERE id_pacient = p_id_pacient 
            ORDER BY data_evaluare DESC;
    END get_istoric_pacient;

    PROCEDURE get_bilet_programare(p_id_pacient IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT TO_CHAR(p.data_ora_inceput, 'DD.MM.YYYY | HH24:MI'), d.nume || ' ' || d.prenume, d.specializare 
            FROM PROGRAMARI p JOIN DOCTORI d ON p.id_doctor = d.id_doctor 
            WHERE p.id_pacient = p_id_pacient AND p.status = 'CONFIRMAT' ORDER BY p.id_programare DESC;
    END get_bilet_programare;
    
    

    PROCEDURE reprogrameaza(p_id_pacient IN NUMBER, p_mesaj OUT VARCHAR2) IS
        v_id_prog NUMBER; v_data DATE; v_doc NUMBER; v_gasit NUMBER; v_zi NUMBER;
        v_test_data DATE;
    BEGIN
        BEGIN
            SELECT id_programare, data_ora_inceput, id_doctor INTO v_id_prog, v_data, v_doc FROM PROGRAMARI 
            WHERE id_pacient = p_id_pacient AND status = 'CONFIRMAT' AND ROWNUM = 1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
            p_mesaj := 'Eroare: Nu aveti o programare activa!';
            RETURN;
        END;
        v_zi := 1;
        v_gasit := 0;
        WHILE v_zi <= 14 AND v_gasit = 0 LOOP
            v_test_data := v_data + v_zi;
            SELECT COUNT(*) INTO v_gasit FROM PROGRAMARI WHERE id_doctor = v_doc AND data_ora_inceput = v_test_data AND status = 'CONFIRMAT';
            IF v_gasit = 0 THEN
                v_data := v_test_data;
                v_gasit := 1;
            ELSE
                v_gasit := 0;
            END IF;
            v_zi := v_zi + 1;
        END LOOP;
        IF v_gasit = 1 THEN
            UPDATE PROGRAMARI SET data_ora_inceput = v_data WHERE id_programare = v_id_prog;
            p_mesaj := 'Programarea a fost mutata!';
        ELSE 
            p_mesaj := 'Eroare: Nu s-au gasit locuri libere.'; 
        END IF;
        COMMIT;
    END reprogrameaza;



    PROCEDURE prelungeste_abonament(p_id_pacient IN NUMBER, p_tip IN VARCHAR2, p_mesaj OUT VARCHAR2) IS
        v_cost NUMBER; v_zile NUMBER; v_data_baza DATE; v_stare VARCHAR2(20);
    BEGIN
        IF p_tip = 'LUNAR' THEN 
            v_cost := 50; 
            v_zile := 30;
        ELSIF p_tip = 'ANUAL' THEN 
            v_cost := 500; 
            v_zile := 365;
        ELSE 
            p_mesaj := 'Eroare: Tip necunoscut.'; 
            RETURN; 
        END IF;

        SELECT stare_curenta, data_expirare INTO v_stare, v_data_baza FROM ABONAMENTE WHERE id_pacient = p_id_pacient;
        IF v_stare = 'ACTIV' AND v_data_baza > SYSDATE THEN 
            v_data_baza := v_data_baza + v_zile;
        ELSE 
            v_data_baza := SYSDATE + v_zile; 
        END IF;
        
        UPDATE ABONAMENTE SET tip = p_tip, data_expirare = v_data_baza, cost = v_cost, stare_curenta = 'ACTIV' WHERE id_pacient = p_id_pacient;
        p_mesaj := 'Abonament prelungit cu succes!';
        COMMIT;
    END prelungeste_abonament;



    PROCEDURE get_info_abonament(p_id_pacient IN NUMBER, p_data_exp OUT VARCHAR2) IS
        v_stare VARCHAR2(20); v_data DATE;
    BEGIN
        SELECT stare_curenta, data_expirare INTO v_stare, v_data FROM ABONAMENTE WHERE id_pacient = p_id_pacient;
        IF v_stare = 'ACTIV' AND v_data >= SYSDATE THEN
            p_data_exp := TO_CHAR(v_data, 'DD.MM.YYYY');
        ELSE 
            p_data_exp := 'Inactiv / Expirat'; 
        END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
        p_data_exp := 'Fara Abonament';
    END get_info_abonament;
END PACHET_DASHBOARD;
/