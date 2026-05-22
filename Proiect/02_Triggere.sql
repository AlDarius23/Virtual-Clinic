CREATE OR REPLACE TRIGGER trg_valideaza_tutore
BEFORE INSERT OR UPDATE ON PACIENTI
FOR EACH ROW
BEGIN
    IF MONTHS_BETWEEN(SYSDATE, :NEW.data_nasterii) / 12 < 18 THEN
        IF :NEW.nume_tutore IS NULL OR :NEW.telefon_tutore IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'EXCEPTIE_PLSQL: Pacientul este minor - datele tutorelui sunt obligatorii!');
        END IF;
    END IF;
END;
/


CREATE OR REPLACE TRIGGER trg_verifica_abonament
BEFORE INSERT ON EVALUARI_SIMPTOME
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM ABONAMENTE
    WHERE id_pacient = :NEW.id_pacient
      AND stare_curenta = 'ACTIV'
      AND data_expirare >= SYSDATE;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'EXCEPTIE_PLSQL: Pacientul nu are un abonament activ! Accesul la servicii este restrictionat.');
    END IF;
END;
/



