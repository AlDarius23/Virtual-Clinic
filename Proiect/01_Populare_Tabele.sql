BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE FISA_MEDICALA CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE PROGRAMARI CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DOCTORI CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE DIAGNOSTICE_AUTOMATE CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE EVALUARI_SIMPTOME CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE REGULI_SIMPTOME CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE REGULI_DIAGNOSTIC CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE SIMPTOME_CATALOG CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE AFECTIUNI_PACIENT CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE ABONAMENTE CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE PACIENTI CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

CREATE TABLE PACIENTI (
    id_pacient NUMBER PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    data_nasterii DATE NOT NULL,
    cnp VARCHAR2(13) UNIQUE NOT NULL,
    telefon VARCHAR2(15) UNIQUE NOT NULL,
    adresa_email VARCHAR2(100) UNIQUE,
    nume_tutore VARCHAR2(100),
    telefon_tutore VARCHAR2(15),
    parola VARCHAR2(100) DEFAULT '1234' NOT NULL
);

CREATE TABLE ABONAMENTE (
    id_abonament NUMBER PRIMARY KEY,
    id_pacient NUMBER NOT NULL REFERENCES PACIENTI(id_pacient),
    tip VARCHAR2(20) CHECK (tip IN ('LUNAR', 'ANUAL')),
    data_creare DATE DEFAULT SYSDATE NOT NULL,
    data_expirare DATE NOT NULL,
    stare_curenta VARCHAR2(20) DEFAULT 'ACTIV' CHECK (stare_curenta IN ('ACTIV', 'EXPIRAT', 'ANULAT')),
    cost NUMBER(10, 2) NOT NULL
);

CREATE TABLE AFECTIUNI_PACIENT (
    id_afectiune NUMBER PRIMARY KEY,
    id_pacient NUMBER NOT NULL REFERENCES PACIENTI(id_pacient),
    denumire_afectiune VARCHAR2(100) NOT NULL,
    grad_risc NUMBER(1) CHECK (grad_risc BETWEEN 1 AND 5),
    an_diagnostic NUMBER(4)
);

CREATE TABLE SIMPTOME_CATALOG (
    id_simptom NUMBER PRIMARY KEY,
    denumire VARCHAR2(100) NOT NULL,
    descriere VARCHAR2(255),
    categorie VARCHAR2(50) CHECK (categorie IN ('CARDIAC', 'RESPIRATOR', 'DIGESTIV', 'NEUROLOGIC', 'PEDIATRIC', 'GENERAL'))
);

CREATE TABLE REGULI_DIAGNOSTIC (
    id_regula NUMBER PRIMARY KEY,
    denumire_regula VARCHAR2(100) NOT NULL,
    diagnostic_probabil VARCHAR2(200) NOT NULL,
    complexitate NUMBER(1) CHECK (complexitate BETWEEN 1 AND 5),
    reteta_automata VARCHAR2(3) DEFAULT 'NU' CHECK (reteta_automata IN ('DA', 'NU')),
    reteta_text VARCHAR2(500)
);

CREATE TABLE REGULI_SIMPTOME (
    id_regula NUMBER NOT NULL REFERENCES REGULI_DIAGNOSTIC(id_regula),
    id_simptom NUMBER NOT NULL REFERENCES SIMPTOME_CATALOG(id_simptom),
    PRIMARY KEY (id_regula, id_simptom)
);

CREATE TABLE EVALUARI_SIMPTOME (
    id_evaluare NUMBER PRIMARY KEY,
    id_pacient NUMBER NOT NULL REFERENCES PACIENTI(id_pacient),
    id_simptom_1 NUMBER NOT NULL REFERENCES SIMPTOME_CATALOG(id_simptom),
    id_simptom_2 NUMBER REFERENCES SIMPTOME_CATALOG(id_simptom),
    id_simptom_3 NUMBER REFERENCES SIMPTOME_CATALOG(id_simptom),
    descriere_pacient VARCHAR2(500),
    data_evaluare DATE DEFAULT SYSDATE NOT NULL
);

CREATE TABLE DIAGNOSTICE_AUTOMATE (
    id_diagnostic_auto NUMBER PRIMARY KEY,
    id_evaluare NUMBER UNIQUE NOT NULL REFERENCES EVALUARI_SIMPTOME(id_evaluare),
    id_regula_aplicata NUMBER NOT NULL REFERENCES REGULI_DIAGNOSTIC(id_regula),
    diagnostic_provizoriu VARCHAR2(200) NOT NULL,
    complexitate NUMBER(1) NOT NULL
);

CREATE TABLE DOCTORI (
    id_doctor NUMBER PRIMARY KEY,
    nume VARCHAR2(50) NOT NULL,
    prenume VARCHAR2(50) NOT NULL,
    specializare VARCHAR2(100) NOT NULL,
    ora_start NUMBER(2) CHECK (ora_start BETWEEN 0 AND 23),
    ora_sfarsit NUMBER(2) CHECK (ora_sfarsit BETWEEN 0 AND 24),
    parola VARCHAR2(100) DEFAULT '1234' NOT NULL
);

CREATE TABLE PROGRAMARI (
    id_programare NUMBER PRIMARY KEY,
    id_pacient NUMBER NOT NULL REFERENCES PACIENTI(id_pacient),
    id_doctor NUMBER NOT NULL REFERENCES DOCTORI(id_doctor),
    data_ora_inceput DATE NOT NULL,
    durata_minute NUMBER(3) DEFAULT 20 NOT NULL,
    status VARCHAR2(20) DEFAULT 'CONFIRMAT' CHECK (status IN ('CONFIRMAT', 'ANULAT', 'FINALIZAT', 'FINALIZAT_AUTOMAT'))
);

CREATE TABLE FISA_MEDICALA (
    id_fisa NUMBER PRIMARY KEY,
    id_programare NUMBER UNIQUE NOT NULL REFERENCES PROGRAMARI(id_programare),
    diagnostic_final VARCHAR2(500) NOT NULL,
    reteta_medicamente VARCHAR2(1000),
    recomandari_medicale VARCHAR2(1000),
    trimitere_spital VARCHAR2(3) DEFAULT 'NU' CHECK (trimitere_spital IN ('DA', 'NU'))
);


DECLARE
    
    TYPE t_str_arr IS VARRAY(30) OF VARCHAR2(100);
    TYPE t_cnp_arr IS VARRAY(20) OF VARCHAR2(13);
    TYPE t_tel_arr IS VARRAY(20) OF VARCHAR2(15);

    v_nume_doc t_str_arr := t_str_arr('Popescu', 'Ionescu', 'Marinescu', 'Radu', 'Stan', 'Dumitru', 'Tudor', 'Gheorghe', 'Ilie', 'Vasile', 'Dobre', 'Nicolae', 'Marin', 'Badea', 'Cretu');
    v_prenume_doc t_str_arr := t_str_arr('Ion', 'Mihai', 'Elena', 'Ana', 'Cristian', 'Diana', 'George', 'Laura', 'Florin', 'Andreea', 'Catalin', 'Gabriela', 'Daniel', 'Roxana', 'Adrian');

    
    v_nume_pac t_str_arr := t_str_arr('Oprea', 'Balan', 'Dragomir', 'Voicu', 'Manea', 'Mocanu', 'Guta', 'Lazar', 'Toma', 'Puscasu', 'Vlad', 'Diaconu', 'Ene', 'Matei', 'Ciobanu', 'Iancu', 'Nistor', 'Grosu', 'Sava', 'Dima');
    v_prenume_pac t_str_arr := t_str_arr('Vasile', 'Ioana', 'Alexandru', 'Maria', 'Ionut', 'Cornel', 'Mircea', 'Alina', 'Simona', 'Bogdan', 'Andrei', 'Marius', 'Carmen', 'Sorin', 'Mihaela', 'Liviu', 'Stefan', 'Valentina', 'Oana', 'Razvan');
    v_cnp t_cnp_arr := t_cnp_arr('1850512123456', '2901023123456', '1780115123456', '6150809123456', '1651205123456', '2880330123456', '1950719123456', '2821111123456', '1700225123456', '2930914123456', '1800404123456', '5180618123456', '2751230123456', '1980108123456', '2860522123456', '1910816123456', '2840303123456', '1691010123456', '2960727123456', '1721105123456');
    v_tel t_tel_arr := t_tel_arr('0722111222', '0733222333', '0744333444', '0755444555', '0766555666', '0777666777', '0788777888', '0799888999', '0721123123', '0731234234', '0741345345', '0751456456', '0761567567', '0771678678', '0781789789', '0791890890', '0722901901', '0733012012', '0744123123', '0755234234');

    
    v_simptome t_str_arr := t_str_arr('Durere in piept', 'Palpitatii', 'Tensiune crescuta', 'Puls accelerat', 'Edeme picioare', 'Tuse seaca', 'Tuse productiva', 'Lipsa de aer', 'Wheezing', 'Durere la inspiratie', 'Greata', 'Durere abdominala', 'Balonare', 'Diaree', 'Arsuri la stomac', 'Cefalee', 'Ameteala', 'Slabiciune', 'Amorteala', 'Tulburari vedere', 'Eruptie', 'Iritabilitate', 'Refuz alimentatie', 'Plans', 'Letargie', 'Febra', 'Oboseala', 'Frisoane', 'Scadere greutate', 'Transpiratii');
    v_diag_probabil t_str_arr := t_str_arr('Suspiciune Infarct Miocardic', 'Aritmie minora', 'Pneumonie virala', 'Bronsita acuta', 'Gastrita', 'Toxiinfectie alimentara', 'Migrena', 'Sindrom Vertiginos', 'Infectie cutanata', 'Gripa sezoniera', 'Otita', 'Anemie', 'Diabet', 'Hipertensiune arteriala', 'Astm bronsic', 'Alergie', 'Lombalgie', 'Insuficienta cardiaca', 'Ulcer gastric', 'Spondiloza');
    v_retete t_str_arr := t_str_arr('Aspirina', 'Paracetamol', 'Ibuprofen', 'Antibiotic spectru larg', 'Antiacid', 'Smecta si saruri rehidratare', 'Sumatriptan', 'Betaserc', 'Unguent antibiotic', 'Tamiflu', 'Picaturi auriculare', 'Fier', 'Insulina', 'Captopril', 'Inhalator Salbutamol', 'Antihistaminic', 'Antiinflamator local', 'Diuretic usor', 'Inhibitor pompa protoni', 'Recomandare fizioterapie');

    v_categorii t_str_arr := t_str_arr('CARDIAC', 'RESPIRATOR', 'DIGESTIV', 'NEUROLOGIC', 'PEDIATRIC', 'GENERAL');
    v_specializari t_str_arr := t_str_arr('Cardiologie', 'Pneumologie', 'Gastroenterologie', 'Neurologie', 'Pediatrie', 'Medicina Interna');

    v_rand_idx NUMBER;
    v_cat_idx NUMBER;
    v_reteta_auto VARCHAR2(3);
    v_tip_ab VARCHAR2(20);
    v_trim VARCHAR2(3);
    v_ora_prog NUMBER;
    v_zile_in_urma NUMBER;
    v_data_prog DATE;

BEGIN
    
    FOR i IN 1..15 LOOP
        v_cat_idx := MOD(i, 6);
        IF v_cat_idx = 0 THEN v_cat_idx := 6; END IF;
        
        INSERT INTO DOCTORI (id_doctor, nume, prenume, specializare, ora_start, ora_sfarsit, parola)
        VALUES (i, v_nume_doc(i), v_prenume_doc(i), v_specializari(v_cat_idx), 8, 16, '1234');
    END LOOP;


    FOR i IN 1..30 LOOP
        v_cat_idx := TRUNC((i - 1) / 5) + 1;
        INSERT INTO SIMPTOME_CATALOG (id_simptom, denumire, descriere, categorie)
        VALUES (i, v_simptome(i), 'Pacientul prezinta ' || v_simptome(i) || ' cu debut recent.', v_categorii(v_cat_idx));
    END LOOP;

    
    FOR i IN 1..20 LOOP
        IF MOD(i, 2) = 0 THEN v_reteta_auto := 'DA'; ELSE v_reteta_auto := 'NU'; END IF;
        
        INSERT INTO REGULI_DIAGNOSTIC (id_regula, denumire_regula, diagnostic_probabil, complexitate, reteta_automata, reteta_text)
        VALUES (i, 'Triaj automat ' || i, v_diag_probabil(i), MOD(i, 5) + 1, v_reteta_auto, v_retete(i) || ' - Administrare o data pe zi.');

        INSERT INTO REGULI_SIMPTOME (id_regula, id_simptom)
        VALUES (i, i);
    END LOOP;

  
    FOR i IN 1..20 LOOP
       
        INSERT INTO PACIENTI (id_pacient, nume, prenume, data_nasterii, cnp, telefon, adresa_email, parola)
        VALUES (i, v_nume_pac(i), v_prenume_pac(i), TO_DATE('1980-01-01', 'YYYY-MM-DD') + MOD(i * 123, 10000), v_cnp(i), v_tel(i), 'pacient' || i || '@test.ro', '1234');

      
        IF MOD(i, 2) = 0 THEN v_tip_ab := 'LUNAR'; ELSE v_tip_ab := 'ANUAL'; END IF;
        INSERT INTO ABONAMENTE (id_abonament, id_pacient, tip, data_creare, data_expirare, stare_curenta, cost)
        VALUES (i, i, v_tip_ab, SYSDATE - 100, SYSDATE + 100, 'ACTIV', 150);

        
        IF i <= 10 THEN
            INSERT INTO AFECTIUNI_PACIENT (id_afectiune, id_pacient, denumire_afectiune, grad_risc, an_diagnostic)
            VALUES (i, i, 'Afectiune preexistenta in monitorizare', MOD(i, 5) + 1, 2018);
        END IF;

        
        v_rand_idx := MOD(i * 7, 30);
        IF v_rand_idx = 0 THEN v_rand_idx := 30; END IF;
        
        INSERT INTO EVALUARI_SIMPTOME (id_evaluare, id_pacient, id_simptom_1, descriere_pacient, data_evaluare)
        VALUES (i, i, v_rand_idx, 'Starea generala este alterata, am ' || v_simptome(v_rand_idx) || ' si nu cedeaza.', SYSDATE - MOD(i, 15) - 1);

       
        v_rand_idx := MOD(i, 20) + 1;
        INSERT INTO DIAGNOSTICE_AUTOMATE (id_diagnostic_auto, id_evaluare, id_regula_aplicata, diagnostic_provizoriu, complexitate)
        VALUES (i, i, v_rand_idx, v_diag_probabil(v_rand_idx) || ' - Necesita confirmare clinica', MOD(i, 5) + 1);

     
        v_rand_idx := MOD(i * 3, 15);
        IF v_rand_idx = 0 THEN v_rand_idx := 15; END IF;

        v_ora_prog := 8 + MOD(i * 5, 8); 
        v_zile_in_urma := MOD(i * 2, 30) + 1; 
        v_data_prog := TRUNC(SYSDATE) - v_zile_in_urma + (v_ora_prog / 24);

        INSERT INTO PROGRAMARI (id_programare, id_pacient, id_doctor, data_ora_inceput, durata_minute, status)
        VALUES (i, i, v_rand_idx, v_data_prog, 20, 'FINALIZAT');

        
        
        v_rand_idx := MOD(i, 20) + 1;
        IF MOD(i, 3) = 0 THEN v_trim := 'DA'; ELSE v_trim := 'NU'; END IF;
        
        INSERT INTO FISA_MEDICALA (id_fisa, id_programare, diagnostic_final, reteta_medicamente, recomandari_medicale, trimitere_spital)
        VALUES (i, i, v_diag_probabil(v_rand_idx) || ' confirmat de medic', v_retete(v_rand_idx) || ' administrat conform schemei', 'Repaus la pat, dieta usoara', v_trim);
    END LOOP;
    
    COMMIT;
END;
/

