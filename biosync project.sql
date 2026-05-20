-- to have a clean slate
DROP DATABASE IF EXISTS bio_sync_medicine_vault;




-- DATABASE 

CREATE DATABASE bio_sync_medicine_vault;
USE bio_sync_medicine_vault;

-- TABLES 

CREATE TABLE Patient (
    patient_id      VARCHAR(10)     NOT NULL,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    dob             DATE            NOT NULL,
    blood_group     VARCHAR(5)      NOT NULL,

    CONSTRAINT pk_patient PRIMARY KEY (patient_id),
    CONSTRAINT chk_blood_group CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
);
CREATE TABLE Doctor 
(
    doctor_id       VARCHAR(10)     NOT NULL,
    first_name      VARCHAR(50)     NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    license_no      VARCHAR(20)     NOT NULL,
    specialization  VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_doctor PRIMARY KEY (doctor_id),
    CONSTRAINT uq_license UNIQUE (license_no),
    CONSTRAINT chk_specialization CHECK (specialization IN (
        'Cardiology', 'Oncology', 'Neurology',
        'General Medicine', 'Pharmacogenomics'
    ))
);
CREATE TABLE Medication 
(
    drug_id         VARCHAR(10)     NOT NULL,
    name            VARCHAR(100)    NOT NULL,
    gene_pathway    VARCHAR(100)    NOT NULL,
    standard_dose   VARCHAR(20)     NOT NULL,
    CONSTRAINT pk_medication PRIMARY KEY (drug_id),
    CONSTRAINT uq_drug_name UNIQUE (name)
);
CREATE TABLE Medication_Side_Effects
(
    drug_id         VARCHAR(10)     NOT NULL,
    side_effect     VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_side_effects PRIMARY KEY (drug_id, side_effect),
    CONSTRAINT fk_side_effect_drug
        FOREIGN KEY (drug_id) REFERENCES Medication(drug_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
CREATE TABLE Genomic_Profile (
    profile_id      VARCHAR(10)     NOT NULL,
    seq_id          VARCHAR(20)     NOT NULL,
    variant         VARCHAR(50)     NOT NULL,
    patient_id      VARCHAR(10)     NOT NULL,
    test_date       DATE            NOT NULL,

    CONSTRAINT pk_genomic PRIMARY KEY (profile_id),
    CONSTRAINT uq_seq_id UNIQUE (seq_id),
    CONSTRAINT uq_patient_profile UNIQUE (patient_id),
    CONSTRAINT fk_genomic_patient
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_variant CHECK (variant IN (
        'Normal', 'CYP2C9*2', 'CYP2C9*3',
        'CYP2C19*2', 'CYP2C19*17', 'CYP2D6*4',
        'CYP2D6*6', 'TPMT*3A', 'TPMT*3C',
        'SLCO1B1*5', 'MTHFR_677T', 'BRCA1_mut'
    ))
);
CREATE TABLE Safety_Validation 
(
    validation_id   VARCHAR(10)     NOT NULL,
    validation_date DATE            NOT NULL,
    status          ENUM('Safe', 'Caution', 'Blocked') NOT NULL,
    patient_id      VARCHAR(10)     NOT NULL,
    doctor_id       VARCHAR(10)     NOT NULL,
    drug_id         VARCHAR(10)     NOT NULL,
    CONSTRAINT pk_safety PRIMARY KEY (validation_id),
    CONSTRAINT fk_safety_patient
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_safety_doctor
        FOREIGN KEY (doctor_id) REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_safety_drug
        FOREIGN KEY (drug_id) REFERENCES Medication(drug_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);
CREATE TABLE Clinical_Log 
(
    log_id          VARCHAR(10)     NOT NULL,
    log_date        DATE            NOT NULL,
    heart_rate      INT             NOT NULL,
    temperature     DECIMAL(4,1)    NOT NULL,
    blood_pressure  VARCHAR(10)     NOT NULL,
    outcome         VARCHAR(100)    NOT NULL,
    patient_id      VARCHAR(10)     NOT NULL,
    doctor_id       VARCHAR(10)     NOT NULL,
    CONSTRAINT pk_clinical PRIMARY KEY (log_id),
    CONSTRAINT fk_clinical_patient
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_clinical_doctor
        FOREIGN KEY (doctor_id) REFERENCES Doctor(doctor_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_heart_rate CHECK (heart_rate BETWEEN 30 AND 200),
    CONSTRAINT chk_temperature CHECK (temperature BETWEEN 35.0 AND 42.0),
    CONSTRAINT chk_outcome CHECK (outcome IN ('Stable', 'Improved', 'Fully recovered','Monitoring required', 'Under observation'))
);
CREATE TABLE Log_Symptoms 
(
    log_id          VARCHAR(10)     NOT NULL,
    symptom         VARCHAR(100)    NOT NULL,
    CONSTRAINT pk_log_symptoms PRIMARY KEY (log_id, symptom),
    CONSTRAINT fk_symptom_log
        FOREIGN KEY (log_id) REFERENCES Clinical_Log(log_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
-- TABLE: Genomic_Drug_Compatibility
-- Defines which variants are incompatible with which pathways
-- This is the MASTER compatibility rule table
CREATE TABLE Genomic_Drug_Compatibility 
(
    compatibility_id  VARCHAR(10)  NOT NULL,
    variant           VARCHAR(50)  NOT NULL,
    gene_pathway      VARCHAR(100) NOT NULL,
    compatibility     ENUM('Safe', 'Caution', 'Blocked') NOT NULL,
    reason            VARCHAR(255) NOT NULL,

    CONSTRAINT pk_compatibility PRIMARY KEY (compatibility_id),
    CONSTRAINT uq_variant_pathway UNIQUE (variant, gene_pathway)
);
-- TABLE: Patient_Drug_Dosage
-- Stores recommended dosage for a patient based on their
-- genomic profile — answers your dosage question directly
CREATE TABLE Patient_Drug_Dosage 
(
    dosage_id         VARCHAR(10)   NOT NULL,
    patient_id        VARCHAR(10)   NOT NULL,
    drug_id           VARCHAR(10)   NOT NULL,
    recommended_dose  VARCHAR(50)   NOT NULL,
    standard_dose     VARCHAR(50)   NOT NULL,
    dose_adjustment   VARCHAR(100)  NOT NULL,
    reason            VARCHAR(255)  NOT NULL,

    CONSTRAINT pk_dosage PRIMARY KEY (dosage_id),
    CONSTRAINT uq_patient_drug UNIQUE (patient_id, drug_id),
    CONSTRAINT fk_dosage_patient
        FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
    CONSTRAINT fk_dosage_drug
        FOREIGN KEY (drug_id) REFERENCES Medication(drug_id)
);


-- INDEXES



-- Patient
CREATE INDEX idx_patient_lastname     ON Patient(last_name);
CREATE INDEX idx_patient_blood_group  ON Patient(blood_group);
-- Genomic_Profile
CREATE INDEX idx_genomic_variant      ON Genomic_Profile(variant);
CREATE INDEX idx_genomic_test_date    ON Genomic_Profile(test_date);
-- Safety_Validation
CREATE INDEX idx_safety_status        ON Safety_Validation(status);
CREATE INDEX idx_safety_patient       ON Safety_Validation(patient_id);
CREATE INDEX idx_safety_drug          ON Safety_Validation(drug_id);
CREATE INDEX idx_safety_doctor        ON Safety_Validation(doctor_id);
CREATE INDEX idx_safety_patient_drug  ON Safety_Validation(patient_id, drug_id);
CREATE INDEX idx_safety_date          ON Safety_Validation(validation_date);
-- Clinical_Log
CREATE INDEX idx_clinical_patient      ON Clinical_Log(patient_id);
CREATE INDEX idx_clinical_outcome      ON Clinical_Log(outcome);
CREATE INDEX idx_clinical_date         ON Clinical_Log(log_date);
CREATE INDEX idx_clinical_patient_date ON Clinical_Log(patient_id, log_date);
-- Log_Symptoms
CREATE INDEX idx_symptom_name          ON Log_Symptoms(symptom);
-- Indexes for Genomic_Drug_Compatibility
CREATE INDEX idx_compat_variant
    ON Genomic_Drug_Compatibility(variant);
CREATE INDEX idx_compat_pathway
    ON Genomic_Drug_Compatibility(gene_pathway);
-- Index for Patient_Drug_Dosage
CREATE INDEX idx_dosage_patient
    ON Patient_Drug_Dosage(patient_id);


--  FUNCTIONS 

DELIMITER $$
-- FUNCTION 1: Calculate_Age
-- Returns the current age of a patient in years
CREATE FUNCTION Calculate_Age(p_patient_id VARCHAR(10))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_dob       DATE;
    DECLARE v_age       INT;
	-- Exception: patient not found
    DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Patient ID not found in database.';
    END;
    SELECT dob INTO v_dob
    FROM Patient
    WHERE patient_id = p_patient_id;
    SET v_age = TIMESTAMPDIFF(YEAR, v_dob, CURDATE());
    RETURN v_age;
END$$
-- FUNCTION 2: Get_Safety_Score
-- Returns a numeric safety score for a patient-drug pair
-- Safe = 1, Caution = 2, Blocked = 3, No record = -1
CREATE FUNCTION Get_Safety_Score(
    p_patient_id VARCHAR(10),
    p_drug_id    VARCHAR(10)
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_status    VARCHAR(10);
    DECLARE v_score     INT DEFAULT -1;
    -- Exception handler: no matching validation record
    DECLARE CONTINUE HANDLER FOR NOT FOUND
    BEGIN
        SET v_score = -1;
    END;
    SELECT status INTO v_status
    FROM Safety_Validation
    WHERE patient_id = p_patient_id
      AND drug_id    = p_drug_id
    ORDER BY validation_date DESC
    LIMIT 1;
    IF v_status = 'Safe'    THEN SET v_score = 1;
    ELSEIF v_status = 'Caution'  THEN SET v_score = 2;
    ELSEIF v_status = 'Blocked'  THEN SET v_score = 3;
    END IF;
    RETURN v_score;
END$$
DELIMITER ;

DELIMITER $$
-- Automatically derives safety status from genomic profile instead of relying on manually entered Safety_Validation
CREATE FUNCTION Get_Genomic_Compatibility(
    p_patient_id VARCHAR(10),
    p_drug_id    VARCHAR(10)
)
RETURNS VARCHAR(10)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_variant     VARCHAR(50);
    DECLARE v_pathway     VARCHAR(100);
    DECLARE v_result      VARCHAR(10) DEFAULT 'Safe';

    -- Get patient variant
    SELECT variant INTO v_variant
    FROM Genomic_Profile
    WHERE patient_id = p_patient_id;

    -- Get drug pathway
    SELECT gene_pathway INTO v_pathway
    FROM Medication
    WHERE drug_id = p_drug_id;

    -- Look up compatibility rule
    SELECT compatibility INTO v_result
    FROM Genomic_Drug_Compatibility
    WHERE variant = v_variant
      AND gene_pathway = v_pathway;

    RETURN COALESCE(v_result, 'Safe');
END$$
DELIMITER ;


-- PROCEDURES 


DELIMITER $$
-- PROCEDURE: Generate_Log_Entry
-- Inserts a new clinical log with exception handling
-- Raises GENOMIC_DATA_MISSING if patient has no genomic profile
CREATE PROCEDURE Generate_Log_Entry(
    IN p_log_id       VARCHAR(10),
    IN p_patient_id   VARCHAR(10),
    IN p_doctor_id    VARCHAR(10),
    IN p_heart_rate   INT,
    IN p_temperature  DECIMAL(4,1),
    IN p_bp           VARCHAR(10),
    IN p_outcome      VARCHAR(100)
)
BEGIN
    DECLARE v_genomic_count INT DEFAULT 0;
    DECLARE v_patient_count INT DEFAULT 0;
    DECLARE v_doctor_count  INT DEFAULT 0;
    -- EXCEPTION HANDLERS
    -- Custom exception: GENOMIC_DATA_MISSING
    DECLARE EXIT HANDLER FOR SQLSTATE '45001'
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45001'
        SET MESSAGE_TEXT = 'GENOMIC_DATA_MISSING: No genomic profile found for this patient. Log entry aborted.';
    END;
    -- Duplicate entry exception
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Duplicate log_id. Entry already exists.';
    END;
    -- Foreign key violation
    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Invalid patient_id or doctor_id. Foreign key violation.';
    END;
    -- General SQL exception fallback
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Unexpected error during log entry creation.';
    END;
    -- VALIDATION CHECKS
    START TRANSACTION;
    -- Check patient exists
    SELECT COUNT(*) INTO v_patient_count
    FROM Patient WHERE patient_id = p_patient_id;
    IF v_patient_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Patient not found.';
    END IF;
    -- Check doctor exists
    SELECT COUNT(*) INTO v_doctor_count
    FROM Doctor WHERE doctor_id = p_doctor_id;
    IF v_doctor_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Doctor not found.';
    END IF;
    -- GENOMIC_DATA_MISSING check
    SELECT COUNT(*) INTO v_genomic_count
    FROM Genomic_Profile WHERE patient_id = p_patient_id;
    IF v_genomic_count = 0 THEN
        SIGNAL SQLSTATE '45001'  -- triggers GENOMIC_DATA_MISSING handler
        SET MESSAGE_TEXT = 'GENOMIC_DATA_MISSING';
    END IF;
    -- INSERT THE LOG
    INSERT INTO Clinical_Log (
        log_id, log_date, heart_rate, temperature,
        blood_pressure, outcome, patient_id, doctor_id
    )
    VALUES (
        p_log_id, CURDATE(), p_heart_rate, p_temperature,
        p_bp, p_outcome, p_patient_id, p_doctor_id
    );
    COMMIT;
    SELECT CONCAT('Log entry ', p_log_id, ' created successfully for patient ', p_patient_id) AS result;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE Regenerate_Safety_Validations()
BEGIN
    DECLARE v_val_id      VARCHAR(10);
    DECLARE v_patient_id  VARCHAR(10);
    DECLARE v_drug_id     VARCHAR(10);
    DECLARE v_doctor_id   VARCHAR(10);
    DECLARE v_variant     VARCHAR(50);
    DECLARE v_pathway     VARCHAR(100);
    DECLARE v_status      VARCHAR(10);
    DECLARE v_counter     INT DEFAULT 1;
    DECLARE v_done        INT DEFAULT 0;
    DECLARE cur_pairs CURSOR FOR
        SELECT
            p.patient_id,
            m.drug_id,
            gp.variant,
            m.gene_pathway
        FROM Patient p
        JOIN Genomic_Profile gp ON p.patient_id = gp.patient_id
        CROSS JOIN Medication m
        ORDER BY p.patient_id, m.drug_id;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    DELETE FROM Safety_Validation;
    OPEN cur_pairs;
    gen_loop: LOOP
        FETCH cur_pairs INTO v_patient_id, v_drug_id, v_variant, v_pathway;
        IF v_done = 1 THEN
            LEAVE gen_loop;
        END IF;
        -- ✅ FIXED: uses IFNULL subquery instead of SELECT INTO
        SET v_status = 'Safe';
        SELECT IFNULL(
            (SELECT compatibility
             FROM Genomic_Drug_Compatibility
             WHERE variant      = v_variant
               AND gene_pathway = v_pathway
             LIMIT 1),
            'Safe'
        ) INTO v_status;
        SET v_doctor_id = CONCAT('D', LPAD(((v_counter - 1) MOD 10) + 1, 3, '0'));
        SET v_val_id    = CONCAT('V', LPAD(v_counter, 4, '0'));
        INSERT INTO Safety_Validation VALUES (
            v_val_id,
            DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 1000) DAY),
            v_status,
            v_patient_id,
            v_doctor_id,
            v_drug_id
        );
        SET v_counter = v_counter + 1;
    END LOOP;
    CLOSE cur_pairs;
    SELECT status, COUNT(*) AS Count
    FROM Safety_Validation
    GROUP BY status;
END$$
DELIMITER ;



-- CURSORS


DELIMITER $$
-- PROCEDURE WITH CURSOR: Review_Side_Effects
-- Loops through all side effects of drugs prescribed to a patient and prints a risk summary
CREATE PROCEDURE Review_Side_Effects(IN p_patient_id VARCHAR(10))
BEGIN
    -- Cursor variables
    DECLARE v_drug_id       VARCHAR(10);
    DECLARE v_drug_name     VARCHAR(100);
    DECLARE v_side_effect   VARCHAR(100);
    DECLARE v_status        VARCHAR(10);
    DECLARE v_done          INT DEFAULT 0;
    -- Cursor: fetch all drugs validated for this patient + their side effects
    DECLARE cur_side_effects CURSOR FOR
        SELECT m.drug_id, m.name, mse.side_effect, sv.status
        FROM Safety_Validation sv
        JOIN Medication m            ON sv.drug_id    = m.drug_id
        JOIN Medication_Side_Effects mse ON m.drug_id = mse.drug_id
        WHERE sv.patient_id = p_patient_id
        ORDER BY sv.status DESC, m.name;
    -- Handler: when cursor runs out of rows
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    -- Temp table to collect results
    DROP TEMPORARY TABLE IF EXISTS SideEffectReport;
    CREATE TEMPORARY TABLE SideEffectReport (
        drug_id     VARCHAR(10),
        drug_name   VARCHAR(100),
        side_effect VARCHAR(100),
        risk_status VARCHAR(10)
    );
    OPEN cur_side_effects;
    -- Loop through cursor
    read_loop: LOOP
        FETCH cur_side_effects INTO v_drug_id, v_drug_name, v_side_effect, v_status;
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;
        INSERT INTO SideEffectReport VALUES (v_drug_id, v_drug_name, v_side_effect, v_status);
    END LOOP;
    CLOSE cur_side_effects;
    -- Return the collected report
    SELECT * FROM SideEffectReport ORDER BY risk_status DESC;
    DROP TEMPORARY TABLE IF EXISTS SideEffectReport;
END$$
DELIMITER ;




-- VIEWS



-- 1. Patient Full Profile
CREATE OR REPLACE VIEW vw_patient_genomic_profile AS
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) AS Age,
    p.blood_group,
    g.profile_id,
    g.seq_id,
    g.variant,
    g.test_date
FROM Patient p
JOIN Genomic_Profile g ON p.patient_id = g.patient_id;
-- 2. Safety Validation Detail
CREATE OR REPLACE VIEW vw_safety_validation_detail AS
SELECT
    sv.validation_id,
    sv.validation_date,
    sv.status,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS DoctorName,
    d.specialization,
    m.drug_id,
    m.name AS DrugName,
    m.gene_pathway,
    m.standard_dose
FROM Safety_Validation sv
JOIN Patient p ON sv.patient_id = p.patient_id
JOIN Doctor d ON sv.doctor_id = d.doctor_id
JOIN Medication m ON sv.drug_id = m.drug_id;
-- 3. Blocked Prescriptions (Risk Audit)
CREATE OR REPLACE VIEW vw_blocked_prescriptions AS
SELECT
    sv.validation_id,
    sv.validation_date,
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    g.variant,
    CONCAT(d.first_name, ' ', d.last_name) AS DoctorName,
    m.name AS DrugName,
    m.gene_pathway
FROM Safety_Validation sv
JOIN Patient p ON sv.patient_id = p.patient_id
JOIN Doctor d ON sv.doctor_id = d.doctor_id
JOIN Medication m ON sv.drug_id = m.drug_id
JOIN Genomic_Profile g ON p.patient_id = g.patient_id
WHERE sv.status = 'Blocked';
-- 4. Patient Clinical Summary
-- Note: MySQL doesn't support 'KEEP DENSE_RANK'. We use a subquery for LastOutcome.
CREATE OR REPLACE VIEW vw_patient_clinical_summary AS
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    COUNT(cl.log_id) AS TotalVisits,
    ROUND(AVG(cl.heart_rate), 1) AS AvgHeartRate,
    ROUND(AVG(cl.temperature), 2) AS AvgTemperature,
    MAX(cl.log_date) AS LastVisitDate
FROM Patient p
LEFT JOIN Clinical_Log cl ON p.patient_id = cl.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name;
-- 5. Doctor Workload
CREATE OR REPLACE VIEW vw_doctor_workload AS
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS DoctorName,
    d.specialization,
    COUNT(DISTINCT sv.validation_id) AS TotalValidations,
    SUM(CASE WHEN sv.status = 'Blocked' THEN 1 ELSE 0 END) AS BlockedCount,
    SUM(CASE WHEN sv.status = 'Caution' THEN 1 ELSE 0 END) AS CautionCount,
    SUM(CASE WHEN sv.status = 'Safe' THEN 1 ELSE 0 END) AS SafeCount,
    (SELECT COUNT(*) FROM Clinical_Log cl WHERE cl.doctor_id = d.doctor_id) AS ClinicalEntries
FROM Doctor d
LEFT JOIN Safety_Validation sv ON d.doctor_id = sv.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name, d.specialization;
-- 6. Genetic Risk Drug Mapping (Predictive Analysis)
CREATE OR REPLACE VIEW vw_genetic_risk_drug_mapping AS
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    g.variant,
    m.drug_id,
    m.name AS DrugName,
    m.gene_pathway,
    CASE
        WHEN g.variant = 'Normal' THEN 'LOW RISK'
        WHEN m.gene_pathway LIKE CONCAT('%', SUBSTRING_INDEX(g.variant, '*', 1), '%') THEN 'HIGH RISK'
        ELSE 'MODERATE RISK'
    END AS RiskLevel
FROM Patient p
JOIN Genomic_Profile g ON p.patient_id = g.patient_id
CROSS JOIN Medication m;
-- 7. Symptom Frequency Report
CREATE OR REPLACE VIEW vw_symptom_frequency AS
SELECT
    symptom,
    COUNT(*) AS OccurrenceCount
FROM Log_Symptoms
GROUP BY symptom
ORDER BY OccurrenceCount DESC;
-- 8. Patient Medication History
CREATE OR REPLACE VIEW vw_patient_medication_history AS
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    g.variant,
    m.name AS DrugName,
    sv.status AS ValidationStatus,
    sv.validation_date,
    CONCAT(d.first_name, ' ', d.last_name) AS PrescribingDoctor
FROM Patient p
JOIN Genomic_Profile g ON p.patient_id = g.patient_id
JOIN Safety_Validation sv ON p.patient_id = sv.patient_id
JOIN Medication m ON sv.drug_id = m.drug_id
JOIN Doctor d ON sv.doctor_id = d.doctor_id;
-- 9. High-Risk Patients
CREATE OR REPLACE VIEW vw_high_risk_patients AS
SELECT
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) AS Age,
    g.variant,
    COUNT(sv.validation_id) AS BlockedCount
FROM Patient p
JOIN Genomic_Profile g ON p.patient_id = g.patient_id
JOIN Safety_Validation sv ON p.patient_id = sv.patient_id
WHERE sv.status = 'Blocked'
GROUP BY p.patient_id, p.first_name, p.last_name, p.dob, g.variant;
-- 10. Drug Side Effect Profile
CREATE OR REPLACE VIEW vw_drug_side_effect_profile AS
SELECT
    m.drug_id,
    m.name AS DrugName,
    m.gene_pathway,
    mse.side_effect
FROM Medication m
JOIN Medication_Side_Effects mse ON m.drug_id = mse.drug_id;
-- 11. Clinical Log with Symptoms (Denormalized)
CREATE OR REPLACE VIEW vw_clinical_log_with_symptoms AS
SELECT
    cl.log_id,
    cl.log_date,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    CONCAT(d.first_name, ' ', d.last_name) AS AttendingDoctor,
    cl.heart_rate,
    cl.temperature,
    cl.blood_pressure,
    cl.outcome,
    ls.symptom
FROM Clinical_Log cl
JOIN Patient p ON cl.patient_id = p.patient_id
JOIN Doctor d ON cl.doctor_id = d.doctor_id
JOIN Log_Symptoms ls ON cl.log_id = ls.log_id;
-- 12. Variant Distribution Summary
CREATE OR REPLACE VIEW vw_variant_distribution AS
SELECT
    variant,
    COUNT(*) AS PatientCount,
    ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Genomic_Profile)), 2) AS Percentage
FROM Genomic_Profile
GROUP BY variant;
-- Complete patient-drug compatibility view with dosage logic
CREATE OR REPLACE VIEW vw_patient_drug_compatibility AS
SELECT
    p.patient_id,
    CONCAT(p.first_name,' ',p.last_name)  AS PatientName,
    gp.variant,
    m.drug_id,
    m.name                                AS DrugName,
    m.gene_pathway,
    m.standard_dose,
    gc.compatibility                      AS RecommendedStatus,
    gc.reason                             AS Reason,
    CASE
        WHEN gc.compatibility = 'Blocked' THEN 'DO NOT ADMINISTER'
        WHEN gc.compatibility = 'Caution' THEN CONCAT('Reduce dose from ', m.standard_dose)
        ELSE m.standard_dose
    END                                   AS RecommendedDose
FROM Patient p
JOIN Genomic_Profile gp ON p.patient_id = gp.patient_id
CROSS JOIN Medication m
LEFT JOIN Genomic_Drug_Compatibility gc
    ON gc.variant = gp.variant
    AND gc.gene_pathway = m.gene_pathway;




-- TRIGGERS


DELIMITER $$
-- TRIGGER 1: Validate dob on Patient insert
CREATE TRIGGER trg_validate_patient_dob
BEFORE INSERT ON Patient
FOR EACH ROW
BEGIN
    IF NEW.dob > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Date of birth cannot be in the future.';
    END IF;
END$$
-- TRIGGER 2: Validate test_date on Genomic_Profile insert
CREATE TRIGGER trg_validate_genomic_date
BEFORE INSERT ON Genomic_Profile
FOR EACH ROW
BEGIN
    IF NEW.test_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Genomic test date cannot be in the future.';
    END IF;
END$$

-- TRIGGER 4: Auto-flag future validation dates
CREATE TRIGGER trg_validate_safety_date
BEFORE INSERT ON Safety_Validation
FOR EACH ROW
BEGIN
    IF NEW.validation_date > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exception: Validation date cannot be in the future.';
    END IF;
END$$
DELIMITER ;








-- TABLE: Patient
INSERT INTO Patient VALUES ('P001', 'Kavya', 'Pillai', '1985-01-10', 'O+');
INSERT INTO Patient VALUES ('P002', 'Yash', 'Iyer', '1975-08-05', 'AB+');
INSERT INTO Patient VALUES ('P003', 'Rohan', 'Shah', '1999-11-11', 'AB-');
INSERT INTO Patient VALUES ('P004', 'Kiran', 'Thakur', '1967-01-14', 'O+');
INSERT INTO Patient VALUES ('P005', 'Aditi', 'Yadav', '1955-04-01', 'A+');
INSERT INTO Patient VALUES ('P006', 'Dhruv', 'Reddy', '1955-02-17', 'A+');
INSERT INTO Patient VALUES ('P007', 'Priya', 'Chopra', '1992-10-10', 'B+');
INSERT INTO Patient VALUES ('P008', 'Nalini', 'Malhotra', '1995-07-24', 'A-');
INSERT INTO Patient VALUES ('P009', 'Anil', 'Reddy', '1956-02-24', 'A-');
INSERT INTO Patient VALUES ('P010', 'Puneet', 'Chauhan', '1971-02-07', 'AB+');
INSERT INTO Patient VALUES ('P011', 'Ramesh', 'Saxena', '2001-02-09', 'B-');
INSERT INTO Patient VALUES ('P012', 'Neha', 'Kumar', '2003-05-04', 'A+');
INSERT INTO Patient VALUES ('P013', 'Sunita', 'Reddy', '1957-05-10', 'AB+');
INSERT INTO Patient VALUES ('P014', 'Rakesh', 'Saxena', '2002-05-13', 'O-');
INSERT INTO Patient VALUES ('P015', 'Sana', 'Srivastava', '1968-04-29', 'O-');
INSERT INTO Patient VALUES ('P016', 'Ashish', 'Verma', '1973-10-30', 'AB+');
INSERT INTO Patient VALUES ('P017', 'Prakash', 'Kumar', '1976-11-30', 'AB-');
INSERT INTO Patient VALUES ('P018', 'Deepa', 'Reddy', '1956-07-05', 'A+');
INSERT INTO Patient VALUES ('P019', 'Amit', 'Malhotra', '2000-07-05', 'A-');
INSERT INTO Patient VALUES ('P020', 'Uday', 'Pillai', '1998-03-27', 'B-');
INSERT INTO Patient VALUES ('P021', 'Deepak', 'Iyer', '1973-10-17', 'B+');
INSERT INTO Patient VALUES ('P022', 'Chandan', 'Sharma', '1956-03-04', 'B-');
INSERT INTO Patient VALUES ('P023', 'Vijay', 'Yadav', '1975-07-27', 'B+');
INSERT INTO Patient VALUES ('P024', 'Kamal', 'Shah', '1998-09-26', 'O+');
INSERT INTO Patient VALUES ('P025', 'Mamta', 'Rao', '1997-06-15', 'A+');
INSERT INTO Patient VALUES ('P026', 'Manisha', 'Thakur', '1999-10-04', 'O+');
INSERT INTO Patient VALUES ('P027', 'Geeta', 'Pillai', '1959-04-18', 'B+');
INSERT INTO Patient VALUES ('P028', 'Rashmi', 'Tiwari', '1960-05-10', 'A-');
INSERT INTO Patient VALUES ('P029', 'Mohit', 'Agarwal', '1963-12-12', 'O+');
INSERT INTO Patient VALUES ('P030', 'Sneha', 'Chauhan', '1968-11-23', 'O-');
INSERT INTO Patient VALUES ('P031', 'Reena', 'Reddy', '1973-09-07', 'AB-');
INSERT INTO Patient VALUES ('P032', 'Suresh', 'Shah', '1954-07-23', 'A-');
INSERT INTO Patient VALUES ('P033', 'Lalit', 'Rao', '1988-01-01', 'O+');
INSERT INTO Patient VALUES ('P034', 'Naina', 'Dubey', '1950-04-27', 'O-');
INSERT INTO Patient VALUES ('P035', 'Alok', 'Kumar', '1973-07-02', 'B+');
INSERT INTO Patient VALUES ('P036', 'Divya', 'Bose', '1999-06-30', 'AB+');
INSERT INTO Patient VALUES ('P037', 'Amrita', 'Agarwal', '1950-11-13', 'A-');
INSERT INTO Patient VALUES ('P038', 'Ekta', 'Shah', '1963-05-17', 'A+');
INSERT INTO Patient VALUES ('P039', 'Usha', 'Yadav', '2002-04-05', 'B+');
INSERT INTO Patient VALUES ('P040', 'Balraj', 'Malhotra', '1961-06-08', 'A+');
INSERT INTO Patient VALUES ('P041', 'Bhavna', 'Chaudhary', '1982-09-18', 'A+');
INSERT INTO Patient VALUES ('P042', 'Indira', 'Dubey', '1968-11-05', 'B-');
INSERT INTO Patient VALUES ('P043', 'Alka', 'Thakur', '1959-03-23', 'O-');
INSERT INTO Patient VALUES ('P044', 'Aparna', 'Agarwal', '1986-06-17', 'B+');
INSERT INTO Patient VALUES ('P045', 'Aakriti', 'Chauhan', '1964-07-30', 'B+');
INSERT INTO Patient VALUES ('P046', 'Varun', 'Bhatia', '1952-03-23', 'B+');
INSERT INTO Patient VALUES ('P047', 'Aisha', 'Singh', '1986-12-09', 'B-');
INSERT INTO Patient VALUES ('P048', 'Sachin', 'Sharma', '1964-04-13', 'A-');
INSERT INTO Patient VALUES ('P049', 'Jagdish', 'Pandey', '1953-06-22', 'AB-');
INSERT INTO Patient VALUES ('P050', 'Jyoti', 'Iyer', '1967-11-27', 'AB-');
INSERT INTO Patient VALUES ('P051', 'Simran', 'Sharma', '1977-05-19', 'B-');
INSERT INTO Patient VALUES ('P052', 'Nikhil', 'Bhatia', '1952-02-15', 'B-');
INSERT INTO Patient VALUES ('P053', 'Tanvi', 'Kapoor', '1979-06-14', 'O+');
INSERT INTO Patient VALUES ('P054', 'Tarun', 'Chauhan', '1975-01-16', 'O-');
INSERT INTO Patient VALUES ('P055', 'Rachna', 'Bose', '1995-09-14', 'AB+');
INSERT INTO Patient VALUES ('P056', 'Lakshmi', 'Singh', '1998-02-08', 'O-');
INSERT INTO Patient VALUES ('P057', 'Mohan', 'Kumar', '1960-05-07', 'O+');
INSERT INTO Patient VALUES ('P058', 'Harish', 'Bose', '2002-02-01', 'O+');
INSERT INTO Patient VALUES ('P059', 'Nisha', 'Saxena', '1959-09-23', 'AB+');
INSERT INTO Patient VALUES ('P060', 'Chirag', 'Bhatia', '1978-02-21', 'AB+');
INSERT INTO Patient VALUES ('P061', 'Shreya', 'Kapoor', '1995-11-19', 'A-');
INSERT INTO Patient VALUES ('P062', 'Rekha', 'Mishra', '2001-09-23', 'B-');
INSERT INTO Patient VALUES ('P063', 'Vishal', 'Nair', '1953-12-25', 'AB+');
INSERT INTO Patient VALUES ('P064', 'Arjun', 'Pillai', '1996-08-23', 'B-');
INSERT INTO Patient VALUES ('P065', 'Sanjay', 'Sharma', '1988-09-10', 'A-');
INSERT INTO Patient VALUES ('P066', 'Vikram', 'Thakur', '1979-08-16', 'O-');
INSERT INTO Patient VALUES ('P067', 'Vinay', 'Pillai', '1961-03-07', 'O+');
INSERT INTO Patient VALUES ('P068', 'Gaurav', 'Iyer', '1977-09-30', 'AB+');
INSERT INTO Patient VALUES ('P069', 'Zara', 'Mishra', '1986-02-06', 'O+');
INSERT INTO Patient VALUES ('P070', 'Rohit', 'Agarwal', '1961-06-02', 'B-');
INSERT INTO Patient VALUES ('P071', 'Swati', 'Sharma', '1984-01-06', 'B+');
INSERT INTO Patient VALUES ('P072', 'Pankaj', 'Tiwari', '2001-01-21', 'O+');
INSERT INTO Patient VALUES ('P073', 'Renu', 'Rao', '1999-02-27', 'A+');
INSERT INTO Patient VALUES ('P074', 'Manav', 'Chopra', '1975-09-28', 'B-');
INSERT INTO Patient VALUES ('P075', 'Nilesh', 'Malhotra', '2002-01-12', 'O-');
INSERT INTO Patient VALUES ('P076', 'Vibha', 'Bhatia', '1989-08-20', 'AB-');
INSERT INTO Patient VALUES ('P077', 'Sarita', 'Chauhan', '1969-03-04', 'AB-');
INSERT INTO Patient VALUES ('P078', 'Meera', 'Patel', '1957-08-10', 'O+');
INSERT INTO Patient VALUES ('P079', 'Aarav', 'Chaudhary', '1980-01-27', 'A-');
INSERT INTO Patient VALUES ('P080', 'Vikas', 'Chauhan', '1977-11-06', 'B-');
INSERT INTO Patient VALUES ('P081', 'Shalini', 'Bose', '1963-03-22', 'A+');
INSERT INTO Patient VALUES ('P082', 'Babita', 'Dubey', '1971-12-20', 'AB-');
INSERT INTO Patient VALUES ('P083', 'Veena', 'Rao', '1956-07-14', 'AB-');
INSERT INTO Patient VALUES ('P084', 'Anjali', 'Joshi', '2001-08-24', 'B-');
INSERT INTO Patient VALUES ('P085', 'Sonal', 'Shah', '1984-06-13', 'AB-');
INSERT INTO Patient VALUES ('P086', 'Preeti', 'Kapoor', '1971-11-21', 'B+');
INSERT INTO Patient VALUES ('P087', 'Pooja', 'Saxena', '1950-07-01', 'A-');
INSERT INTO Patient VALUES ('P088', 'Madhur', 'Joshi', '1969-08-19', 'B+');
INSERT INTO Patient VALUES ('P089', 'Sunil', 'Shah', '1996-06-20', 'AB-');
INSERT INTO Patient VALUES ('P090', 'Naresh', 'Kumar', '2000-01-04', 'B-');
INSERT INTO Patient VALUES ('P091', 'Hemant', 'Mehta', '1990-12-14', 'B+');
INSERT INTO Patient VALUES ('P092', 'Ritika', 'Chaudhary', '1997-08-26', 'O-');
INSERT INTO Patient VALUES ('P093', 'Rahul', 'Bose', '1995-04-15', 'AB+');
INSERT INTO Patient VALUES ('P094', 'Shiv', 'Chopra', '1990-01-02', 'B+');
INSERT INTO Patient VALUES ('P095', 'Yogesh', 'Tiwari', '1990-05-18', 'O+');
INSERT INTO Patient VALUES ('P096', 'Ananya', 'Kumar', '1974-11-17', 'AB-');
INSERT INTO Patient VALUES ('P097', 'Ankita', 'Chauhan', '1971-06-19', 'O+');
INSERT INTO Patient VALUES ('P098', 'Mukesh', 'Shah', '1956-12-13', 'O+');
INSERT INTO Patient VALUES ('P099', 'Farhan', 'Chauhan', '1974-05-18', 'O-');
INSERT INTO Patient VALUES ('P100', 'Komal', 'Nair', '1998-06-17', 'A-');
INSERT INTO Patient VALUES ('P101', 'Uma', 'Srivastava', '1963-07-14', 'B-');
INSERT INTO Patient VALUES ('P102', 'Rajesh', 'Mishra', '1963-09-17', 'B-');
INSERT INTO Patient VALUES ('P103', 'Isha', 'Chauhan', '1987-03-22', 'AB+');
INSERT INTO Patient VALUES ('P104', 'Vineeta', 'Thakur', '1998-09-06', 'AB-');
INSERT INTO Patient VALUES ('P105', 'Kunal', 'Joshi', '1955-08-03', 'B-');
INSERT INTO Patient VALUES ('P106', 'Ravi', 'Sharma', '1984-12-10', 'A+');
INSERT INTO Patient VALUES ('P107', 'Sakshi', 'Dubey', '1984-02-16', 'AB-');
INSERT INTO Patient VALUES ('P108', 'Shubham', 'Rao', '1981-07-23', 'O+');
INSERT INTO Patient VALUES ('P109', 'Rupali', 'Agarwal', '1987-08-05', 'B-');
INSERT INTO Patient VALUES ('P110', 'Akash', 'Srivastava', '1969-09-08', 'O+');
INSERT INTO Patient VALUES ('P111', 'Jay', 'Malhotra', '1993-07-27', 'A+');
INSERT INTO Patient VALUES ('P112', 'Poonam', 'Agarwal', '1980-02-27', 'AB+');
INSERT INTO Patient VALUES ('P113', 'Kavya', 'Mehta', '1991-12-07', 'B+');
INSERT INTO Patient VALUES ('P114', 'Yash', 'Iyer', '1997-12-02', 'A+');
INSERT INTO Patient VALUES ('P115', 'Rohan', 'Yadav', '2003-02-07', 'A+');
INSERT INTO Patient VALUES ('P116', 'Kiran', 'Agarwal', '1988-06-14', 'B+');
INSERT INTO Patient VALUES ('P117', 'Aditi', 'Chaudhary', '1966-04-21', 'A+');
INSERT INTO Patient VALUES ('P118', 'Dhruv', 'Srivastava', '1984-01-05', 'O-');
INSERT INTO Patient VALUES ('P119', 'Priya', 'Mehta', '1990-10-17', 'O-');
INSERT INTO Patient VALUES ('P120', 'Nalini', 'Nair', '1984-01-06', 'O+');
INSERT INTO Patient VALUES ('P121', 'Anil', 'Sharma', '1972-08-19', 'A-');
INSERT INTO Patient VALUES ('P122', 'Puneet', 'Reddy', '1951-09-28', 'A+');
INSERT INTO Patient VALUES ('P123', 'Ramesh', 'Sharma', '1970-02-12', 'A-');
INSERT INTO Patient VALUES ('P124', 'Neha', 'Iyer', '1953-08-12', 'A+');
INSERT INTO Patient VALUES ('P125', 'Sunita', 'Kumar', '1967-11-20', 'A+');
INSERT INTO Patient VALUES ('P126', 'Rakesh', 'Iyer', '1963-09-03', 'B-');
INSERT INTO Patient VALUES ('P127', 'Sana', 'Verma', '1992-06-26', 'A-');
INSERT INTO Patient VALUES ('P128', 'Ashish', 'Dubey', '1969-07-22', 'AB-');
INSERT INTO Patient VALUES ('P129', 'Prakash', 'Nair', '1972-12-27', 'O-');
INSERT INTO Patient VALUES ('P130', 'Deepa', 'Mehta', '1960-04-11', 'B+');
INSERT INTO Patient VALUES ('P131', 'Amit', 'Patel', '1959-09-13', 'A+');
INSERT INTO Patient VALUES ('P132', 'Uday', 'Patel', '2001-08-28', 'AB+');
INSERT INTO Patient VALUES ('P133', 'Deepak', 'Singh', '1967-10-17', 'A-');
INSERT INTO Patient VALUES ('P134', 'Chandan', 'Joshi', '1971-10-15', 'A-');
INSERT INTO Patient VALUES ('P135', 'Vijay', 'Shah', '1977-01-21', 'A-');
INSERT INTO Patient VALUES ('P136', 'Kamal', 'Dubey', '1953-09-07', 'O-');
INSERT INTO Patient VALUES ('P137', 'Mamta', 'Sharma', '1988-06-07', 'O-');
INSERT INTO Patient VALUES ('P138', 'Manisha', 'Chauhan', '1995-05-24', 'O-');
INSERT INTO Patient VALUES ('P139', 'Geeta', 'Shah', '1987-09-08', 'AB-');
INSERT INTO Patient VALUES ('P140', 'Rashmi', 'Kapoor', '1988-11-22', 'O-');
INSERT INTO Patient VALUES ('P141', 'Mohit', 'Rao', '1991-03-31', 'B+');
INSERT INTO Patient VALUES ('P142', 'Sneha', 'Malhotra', '1965-10-20', 'O+');
INSERT INTO Patient VALUES ('P143', 'Reena', 'Tiwari', '1998-04-13', 'AB-');
INSERT INTO Patient VALUES ('P144', 'Suresh', 'Bhatia', '1989-01-28', 'O+');
INSERT INTO Patient VALUES ('P145', 'Lalit', 'Dubey', '1972-01-10', 'A-');
INSERT INTO Patient VALUES ('P146', 'Naina', 'Chopra', '1990-06-11', 'B-');
INSERT INTO Patient VALUES ('P147', 'Alok', 'Chaudhary', '2001-02-14', 'AB+');
INSERT INTO Patient VALUES ('P148', 'Divya', 'Nair', '1952-07-29', 'AB-');
INSERT INTO Patient VALUES ('P149', 'Amrita', 'Mishra', '1966-04-25', 'AB-');
INSERT INTO Patient VALUES ('P150', 'Ekta', 'Mehta', '1981-10-31', 'O+');

-- ============================================================
-- TABLE: Doctor
-- ============================================================
INSERT INTO Doctor VALUES ('D001', 'Anand', 'Mehrotra', 'LIC-2000', 'Cardiology');
INSERT INTO Doctor VALUES ('D002', 'Sunita', 'Krishnan', 'LIC-2001', 'Oncology');
INSERT INTO Doctor VALUES ('D003', 'Rajiv', 'Bhatia', 'LIC-2002', 'Neurology');
INSERT INTO Doctor VALUES ('D004', 'Preethi', 'Desai', 'LIC-2003', 'General Medicine');
INSERT INTO Doctor VALUES ('D005', 'Vikram', 'Rao', 'LIC-2004', 'Pharmacogenomics');
INSERT INTO Doctor VALUES ('D006', 'Nandini', 'Jain', 'LIC-2005', 'Cardiology');
INSERT INTO Doctor VALUES ('D007', 'Arun', 'Malhotra', 'LIC-2006', 'Oncology');
INSERT INTO Doctor VALUES ('D008', 'Shweta', 'Chandra', 'LIC-2007', 'Neurology');
INSERT INTO Doctor VALUES ('D009', 'Deepak', 'Pillai', 'LIC-2008', 'General Medicine');
INSERT INTO Doctor VALUES ('D010', 'Harsha', 'Tiwari', 'LIC-2009', 'Pharmacogenomics');

-- ============================================================
-- TABLE: Medication
-- ============================================================
INSERT INTO Medication VALUES ('DR001', 'Warfarin', 'CYP2C9_substrate', '5mg');
INSERT INTO Medication VALUES ('DR002', 'Clopidogrel', 'CYP2C19_substrate', '75mg');
INSERT INTO Medication VALUES ('DR003', 'Codeine', 'CYP2D6_substrate', '30mg');
INSERT INTO Medication VALUES ('DR004', 'Tamoxifen', 'CYP2D6_substrate', '20mg');
INSERT INTO Medication VALUES ('DR005', 'Ibuprofen', 'CYP2C9_substrate', '400mg');
INSERT INTO Medication VALUES ('DR006', 'Simvastatin', 'SLCO1B1_substrate', '40mg');
INSERT INTO Medication VALUES ('DR007', 'Azathioprine', 'TPMT_substrate', '50mg');
INSERT INTO Medication VALUES ('DR008', 'Methotrexate', 'MTHFR_substrate', '15mg');

-- ============================================================
-- TABLE: Medication_Side_Effects
-- ============================================================
INSERT INTO Medication_Side_Effects VALUES ('DR001', 'Bleeding risk');
INSERT INTO Medication_Side_Effects VALUES ('DR001', 'Bruising');
INSERT INTO Medication_Side_Effects VALUES ('DR001', 'Nausea');
INSERT INTO Medication_Side_Effects VALUES ('DR002', 'Rash');
INSERT INTO Medication_Side_Effects VALUES ('DR002', 'Diarrhea');
INSERT INTO Medication_Side_Effects VALUES ('DR002', 'Headache');
INSERT INTO Medication_Side_Effects VALUES ('DR003', 'Respiratory depression');
INSERT INTO Medication_Side_Effects VALUES ('DR003', 'Constipation');
INSERT INTO Medication_Side_Effects VALUES ('DR003', 'Drowsiness');
INSERT INTO Medication_Side_Effects VALUES ('DR004', 'Hot flashes');
INSERT INTO Medication_Side_Effects VALUES ('DR004', 'Nausea');
INSERT INTO Medication_Side_Effects VALUES ('DR004', 'Fatigue');
INSERT INTO Medication_Side_Effects VALUES ('DR005', 'GI upset');
INSERT INTO Medication_Side_Effects VALUES ('DR005', 'Headache');
INSERT INTO Medication_Side_Effects VALUES ('DR005', 'Dizziness');
INSERT INTO Medication_Side_Effects VALUES ('DR006', 'Muscle pain');
INSERT INTO Medication_Side_Effects VALUES ('DR006', 'Liver toxicity');
INSERT INTO Medication_Side_Effects VALUES ('DR006', 'Nausea');
INSERT INTO Medication_Side_Effects VALUES ('DR007', 'Bone marrow suppression');
INSERT INTO Medication_Side_Effects VALUES ('DR007', 'Nausea');
INSERT INTO Medication_Side_Effects VALUES ('DR007', 'Infection risk');
INSERT INTO Medication_Side_Effects VALUES ('DR008', 'Mouth sores');
INSERT INTO Medication_Side_Effects VALUES ('DR008', 'Nausea');
INSERT INTO Medication_Side_Effects VALUES ('DR008', 'Liver toxicity');

-- ============================================================
-- TABLE: Genomic_Profile
-- ============================================================
INSERT INTO Genomic_Profile VALUES ('GM001', 'SEQ-5581', 'CYP2D6*6', 'P001', '2025-05-05');
INSERT INTO Genomic_Profile VALUES ('GM002', 'SEQ-5526', 'Normal', 'P002', '2025-02-12');
INSERT INTO Genomic_Profile VALUES ('GM003', 'SEQ-9464', 'CYP2C9*2', 'P003', '2023-01-27');
INSERT INTO Genomic_Profile VALUES ('GM004', 'SEQ-4954', 'CYP2C9*3', 'P004', '2024-04-12');
INSERT INTO Genomic_Profile VALUES ('GM005', 'SEQ-4937', 'TPMT*3C', 'P005', '2025-11-15');
INSERT INTO Genomic_Profile VALUES ('GM006', 'SEQ-9041', 'TPMT*3C', 'P006', '2024-07-06');
INSERT INTO Genomic_Profile VALUES ('GM007', 'SEQ-2524', 'CYP2C9*2', 'P007', '2023-08-26');
INSERT INTO Genomic_Profile VALUES ('GM008', 'SEQ-7625', 'CYP2C19*17', 'P008', '2025-11-17');
INSERT INTO Genomic_Profile VALUES ('GM009', 'SEQ-6016', 'CYP2C19*17', 'P009', '2025-09-21');
INSERT INTO Genomic_Profile VALUES ('GM010', 'SEQ-7046', 'MTHFR_677T', 'P010', '2024-08-27');
INSERT INTO Genomic_Profile VALUES ('GM011', 'SEQ-9698', 'BRCA1_mut', 'P011', '2023-12-06');
INSERT INTO Genomic_Profile VALUES ('GM012', 'SEQ-6419', 'TPMT*3A', 'P012', '2023-12-22');
INSERT INTO Genomic_Profile VALUES ('GM013', 'SEQ-8434', 'Normal', 'P013', '2023-07-09');
INSERT INTO Genomic_Profile VALUES ('GM014', 'SEQ-5118', 'CYP2D6*4', 'P014', '2023-04-18');
INSERT INTO Genomic_Profile VALUES ('GM015', 'SEQ-4155', 'CYP2C9*3', 'P015', '2023-10-09');
INSERT INTO Genomic_Profile VALUES ('GM016', 'SEQ-9779', 'CYP2C9*3', 'P016', '2025-11-14');
INSERT INTO Genomic_Profile VALUES ('GM017', 'SEQ-4138', 'CYP2C19*2', 'P017', '2023-03-20');
INSERT INTO Genomic_Profile VALUES ('GM018', 'SEQ-8933', 'Normal', 'P018', '2023-07-21');
INSERT INTO Genomic_Profile VALUES ('GM019', 'SEQ-9595', 'Normal', 'P019', '2025-05-07');
INSERT INTO Genomic_Profile VALUES ('GM020', 'SEQ-2647', 'CYP2D6*4', 'P020', '2023-02-02');
INSERT INTO Genomic_Profile VALUES ('GM021', 'SEQ-4727', 'CYP2D6*4', 'P021', '2024-01-10');
INSERT INTO Genomic_Profile VALUES ('GM022', 'SEQ-5952', 'CYP2C19*2', 'P022', '2022-01-29');
INSERT INTO Genomic_Profile VALUES ('GM023', 'SEQ-9751', 'Normal', 'P023', '2022-09-17');
INSERT INTO Genomic_Profile VALUES ('GM024', 'SEQ-1745', 'CYP2D6*4', 'P024', '2022-04-22');
INSERT INTO Genomic_Profile VALUES ('GM025', 'SEQ-5786', 'BRCA1_mut', 'P025', '2025-11-29');
INSERT INTO Genomic_Profile VALUES ('GM026', 'SEQ-9042', 'CYP2C19*2', 'P026', '2022-07-30');
INSERT INTO Genomic_Profile VALUES ('GM027', 'SEQ-5658', 'CYP2C9*2', 'P027', '2024-08-19');
INSERT INTO Genomic_Profile VALUES ('GM028', 'SEQ-8216', 'TPMT*3C', 'P028', '2023-11-29');
INSERT INTO Genomic_Profile VALUES ('GM029', 'SEQ-1841', 'CYP2C19*2', 'P029', '2023-06-02');
INSERT INTO Genomic_Profile VALUES ('GM030', 'SEQ-2869', 'TPMT*3C', 'P030', '2022-05-14');
INSERT INTO Genomic_Profile VALUES ('GM031', 'SEQ-9056', 'TPMT*3A', 'P031', '2022-06-01');
INSERT INTO Genomic_Profile VALUES ('GM032', 'SEQ-1878', 'MTHFR_677T', 'P032', '2022-11-07');
INSERT INTO Genomic_Profile VALUES ('GM033', 'SEQ-5978', 'CYP2C19*2', 'P033', '2022-06-24');
INSERT INTO Genomic_Profile VALUES ('GM034', 'SEQ-2940', 'CYP2C19*17', 'P034', '2025-02-16');
INSERT INTO Genomic_Profile VALUES ('GM035', 'SEQ-4697', 'TPMT*3A', 'P035', '2024-12-06');
INSERT INTO Genomic_Profile VALUES ('GM036', 'SEQ-8381', 'TPMT*3A', 'P036', '2024-06-25');
INSERT INTO Genomic_Profile VALUES ('GM037', 'SEQ-8025', 'CYP2D6*4', 'P037', '2023-09-18');
INSERT INTO Genomic_Profile VALUES ('GM038', 'SEQ-1986', 'MTHFR_677T', 'P038', '2025-06-02');
INSERT INTO Genomic_Profile VALUES ('GM039', 'SEQ-2625', 'Normal', 'P039', '2023-03-02');
INSERT INTO Genomic_Profile VALUES ('GM040', 'SEQ-4457', 'SLCO1B1*5', 'P040', '2023-06-26');
INSERT INTO Genomic_Profile VALUES ('GM041', 'SEQ-2330', 'SLCO1B1*5', 'P041', '2022-11-18');
INSERT INTO Genomic_Profile VALUES ('GM042', 'SEQ-3847', 'CYP2C19*17', 'P042', '2025-02-04');
INSERT INTO Genomic_Profile VALUES ('GM043', 'SEQ-3564', 'CYP2C9*3', 'P043', '2022-01-06');
INSERT INTO Genomic_Profile VALUES ('GM044', 'SEQ-8382', 'TPMT*3A',   'P044', '2025-11-12');
INSERT INTO Genomic_Profile VALUES ('GM045', 'SEQ-8699', 'MTHFR_677T', 'P045', '2023-08-20');
INSERT INTO Genomic_Profile VALUES ('GM046', 'SEQ-4792', 'CYP2C9*2', 'P046', '2023-08-14');
INSERT INTO Genomic_Profile VALUES ('GM047', 'SEQ-5632', 'Normal', 'P047', '2025-12-10');
INSERT INTO Genomic_Profile VALUES ('GM048', 'SEQ-2166', 'TPMT*3C', 'P048', '2025-11-08');
INSERT INTO Genomic_Profile VALUES ('GM049', 'SEQ-5334', 'CYP2C19*17', 'P049', '2025-07-04');
INSERT INTO Genomic_Profile VALUES ('GM050', 'SEQ-4241', 'MTHFR_677T', 'P050', '2024-05-20');
INSERT INTO Genomic_Profile VALUES ('GM051', 'SEQ-9922', 'CYP2C9*3', 'P051', '2023-04-06');
INSERT INTO Genomic_Profile VALUES ('GM052', 'SEQ-3441', 'SLCO1B1*5', 'P052', '2023-06-29');
INSERT INTO Genomic_Profile VALUES ('GM053', 'SEQ-2169', 'CYP2C19*2', 'P053', '2022-05-03');
INSERT INTO Genomic_Profile VALUES ('GM054', 'SEQ-6039', 'CYP2C19*2', 'P054', '2025-05-03');
INSERT INTO Genomic_Profile VALUES ('GM055', 'SEQ-5728', 'Normal', 'P055', '2024-06-18');
INSERT INTO Genomic_Profile VALUES ('GM056', 'SEQ-8679', 'CYP2C9*3', 'P056', '2025-11-11');
INSERT INTO Genomic_Profile VALUES ('GM057', 'SEQ-7594', 'CYP2D6*4', 'P057', '2023-07-12');
INSERT INTO Genomic_Profile VALUES ('GM058', 'SEQ-9847', 'BRCA1_mut', 'P058', '2024-10-08');
INSERT INTO Genomic_Profile VALUES ('GM059', 'SEQ-2317', 'TPMT*3C', 'P059', '2025-05-09');
INSERT INTO Genomic_Profile VALUES ('GM060', 'SEQ-8078', 'CYP2C9*2', 'P060', '2023-10-23');
INSERT INTO Genomic_Profile VALUES ('GM061', 'SEQ-5102', 'MTHFR_677T', 'P061', '2022-02-22');
INSERT INTO Genomic_Profile VALUES ('GM062', 'SEQ-4750', 'CYP2C9*3', 'P062', '2025-10-12');
INSERT INTO Genomic_Profile VALUES ('GM063', 'SEQ-1339', 'MTHFR_677T', 'P063', '2025-10-08');
INSERT INTO Genomic_Profile VALUES ('GM064', 'SEQ-1659', 'CYP2D6*4', 'P064', '2022-12-25');
INSERT INTO Genomic_Profile VALUES ('GM065', 'SEQ-9502', 'TPMT*3C', 'P065', '2025-08-27');
INSERT INTO Genomic_Profile VALUES ('GM066', 'SEQ-5557', 'TPMT*3C', 'P066', '2023-01-07');
INSERT INTO Genomic_Profile VALUES ('GM067', 'SEQ-8141', 'MTHFR_677T', 'P067', '2025-07-24');
INSERT INTO Genomic_Profile VALUES ('GM068', 'SEQ-2494', 'TPMT*3C', 'P068', '2024-08-20');
INSERT INTO Genomic_Profile VALUES ('GM069', 'SEQ-7690', 'CYP2D6*6', 'P069', '2023-11-14');
INSERT INTO Genomic_Profile VALUES ('GM070', 'SEQ-2713', 'CYP2D6*6', 'P070', '2022-11-26');
INSERT INTO Genomic_Profile VALUES ('GM071', 'SEQ-7744', 'CYP2D6*6', 'P071', '2025-11-21');
INSERT INTO Genomic_Profile VALUES ('GM072', 'SEQ-5722', 'TPMT*3C', 'P072', '2025-09-18');
INSERT INTO Genomic_Profile VALUES ('GM073', 'SEQ-1601', 'TPMT*3A', 'P073', '2024-07-20');
INSERT INTO Genomic_Profile VALUES ('GM074', 'SEQ-6153', 'CYP2C9*3', 'P074', '2023-06-01');
INSERT INTO Genomic_Profile VALUES ('GM075', 'SEQ-2899', 'CYP2D6*6', 'P075', '2024-04-07');
INSERT INTO Genomic_Profile VALUES ('GM076', 'SEQ-1018', 'BRCA1_mut', 'P076', '2025-09-08');
INSERT INTO Genomic_Profile VALUES ('GM077', 'SEQ-8569', 'BRCA1_mut', 'P077', '2024-04-26');
INSERT INTO Genomic_Profile VALUES ('GM078', 'SEQ-4073', 'CYP2C9*2', 'P078', '2024-11-27');
INSERT INTO Genomic_Profile VALUES ('GM079', 'SEQ-9167', 'CYP2D6*6', 'P079', '2025-07-04');
INSERT INTO Genomic_Profile VALUES ('GM080', 'SEQ-1845', 'TPMT*3C', 'P080', '2023-02-21');
INSERT INTO Genomic_Profile VALUES ('GM081', 'SEQ-9998', 'CYP2D6*4', 'P081', '2022-09-26');
INSERT INTO Genomic_Profile VALUES ('GM082', 'SEQ-8178', 'CYP2D6*4', 'P082', '2025-12-01');
INSERT INTO Genomic_Profile VALUES ('GM083', 'SEQ-2989', 'TPMT*3C', 'P083', '2022-03-01');
INSERT INTO Genomic_Profile VALUES ('GM084', 'SEQ-4920', 'SLCO1B1*5', 'P084', '2025-12-24');
INSERT INTO Genomic_Profile VALUES ('GM085', 'SEQ-6091', 'CYP2C19*2', 'P085', '2025-02-02');
INSERT INTO Genomic_Profile VALUES ('GM086', 'SEQ-7684', 'CYP2C9*2', 'P086', '2022-07-10');
INSERT INTO Genomic_Profile VALUES ('GM087', 'SEQ-2858', 'CYP2C19*17', 'P087', '2024-08-03');
INSERT INTO Genomic_Profile VALUES ('GM088', 'SEQ-3522', 'CYP2C9*3', 'P088', '2024-10-17');
INSERT INTO Genomic_Profile VALUES ('GM089', 'SEQ-5781', 'Normal', 'P089', '2024-11-08');
INSERT INTO Genomic_Profile VALUES ('GM090', 'SEQ-5479', 'Normal', 'P090', '2024-04-30');
INSERT INTO Genomic_Profile VALUES ('GM091', 'SEQ-8736', 'TPMT*3C', 'P091', '2023-05-15');
INSERT INTO Genomic_Profile VALUES ('GM092', 'SEQ-3369', 'TPMT*3C', 'P092', '2024-02-25');
INSERT INTO Genomic_Profile VALUES ('GM093', 'SEQ-9327', 'CYP2C19*17', 'P093', '2022-10-07');
INSERT INTO Genomic_Profile VALUES ('GM094', 'SEQ-5527', 'CYP2C9*3',  'P094', '2024-04-29');
INSERT INTO Genomic_Profile VALUES ('GM095', 'SEQ-9318', 'CYP2D6*6', 'P095', '2023-07-02');
INSERT INTO Genomic_Profile VALUES ('GM096', 'SEQ-5634', 'CYP2C9*2', 'P096', '2023-09-04');
INSERT INTO Genomic_Profile VALUES ('GM097', 'SEQ-9022', 'MTHFR_677T', 'P097', '2022-11-01');
INSERT INTO Genomic_Profile VALUES ('GM098', 'SEQ-9824', 'TPMT*3C', 'P098', '2024-09-18');
INSERT INTO Genomic_Profile VALUES ('GM099', 'SEQ-6446', 'CYP2D6*6', 'P099', '2025-02-04');
INSERT INTO Genomic_Profile VALUES ('GM100', 'SEQ-7180', 'BRCA1_mut', 'P100', '2024-07-21');
INSERT INTO Genomic_Profile VALUES ('GM101', 'SEQ-4090', 'CYP2D6*6', 'P101', '2025-11-29');
INSERT INTO Genomic_Profile VALUES ('GM102', 'SEQ-7274', 'CYP2C19*17', 'P102', '2023-04-24');
INSERT INTO Genomic_Profile VALUES ('GM103', 'SEQ-1715', 'TPMT*3A', 'P103', '2023-10-14');
INSERT INTO Genomic_Profile VALUES ('GM104', 'SEQ-8749', 'Normal', 'P104', '2025-12-15');
INSERT INTO Genomic_Profile VALUES ('GM105', 'SEQ-7325', 'TPMT*3A', 'P105', '2025-09-21');
INSERT INTO Genomic_Profile VALUES ('GM106', 'SEQ-3492', 'SLCO1B1*5', 'P106', '2024-10-11');
INSERT INTO Genomic_Profile VALUES ('GM107', 'SEQ-3068', 'CYP2C9*2', 'P107', '2024-10-25');
INSERT INTO Genomic_Profile VALUES ('GM108', 'SEQ-6439', 'MTHFR_677T', 'P108', '2022-07-25');
INSERT INTO Genomic_Profile VALUES ('GM109', 'SEQ-2633', 'TPMT*3C', 'P109', '2024-12-13');
INSERT INTO Genomic_Profile VALUES ('GM110', 'SEQ-1251', 'TPMT*3C', 'P110', '2022-10-23');
INSERT INTO Genomic_Profile VALUES ('GM111', 'SEQ-3529', 'TPMT*3A', 'P111', '2022-06-03');
INSERT INTO Genomic_Profile VALUES ('GM112', 'SEQ-5342', 'TPMT*3C', 'P112', '2023-11-25');
INSERT INTO Genomic_Profile VALUES ('GM113', 'SEQ-7512', 'MTHFR_677T', 'P113', '2025-08-23');
INSERT INTO Genomic_Profile VALUES ('GM114', 'SEQ-6383', 'CYP2C9*3', 'P114', '2025-10-13');
INSERT INTO Genomic_Profile VALUES ('GM115', 'SEQ-7226', 'BRCA1_mut', 'P115', '2023-10-11');
INSERT INTO Genomic_Profile VALUES ('GM116', 'SEQ-8994', 'SLCO1B1*5', 'P116', '2025-01-13');
INSERT INTO Genomic_Profile VALUES ('GM117', 'SEQ-2121', 'CYP2C9*2', 'P117', '2023-04-26');
INSERT INTO Genomic_Profile VALUES ('GM118', 'SEQ-5708', 'SLCO1B1*5', 'P118', '2023-04-11');
INSERT INTO Genomic_Profile VALUES ('GM119', 'SEQ-2480', 'Normal', 'P119', '2024-06-07');
INSERT INTO Genomic_Profile VALUES ('GM120', 'SEQ-2646', 'CYP2C9*3', 'P120', '2024-06-27');
INSERT INTO Genomic_Profile VALUES ('GM121', 'SEQ-5906', 'CYP2C19*2', 'P121', '2022-03-01');
INSERT INTO Genomic_Profile VALUES ('GM122', 'SEQ-6314', 'CYP2C9*2', 'P122', '2022-04-25');
INSERT INTO Genomic_Profile VALUES ('GM123', 'SEQ-6873', 'CYP2D6*4', 'P123', '2024-02-07');
INSERT INTO Genomic_Profile VALUES ('GM124', 'SEQ-3385', 'TPMT*3A', 'P124', '2023-05-16');
INSERT INTO Genomic_Profile VALUES ('GM125', 'SEQ-7751', 'BRCA1_mut', 'P125', '2025-03-05');
INSERT INTO Genomic_Profile VALUES ('GM126', 'SEQ-3950', 'SLCO1B1*5', 'P126', '2022-12-15');
INSERT INTO Genomic_Profile VALUES ('GM127', 'SEQ-2293', 'CYP2C19*2', 'P127', '2025-06-02');
INSERT INTO Genomic_Profile VALUES ('GM128', 'SEQ-4945', 'TPMT*3A', 'P128', '2024-10-16');
INSERT INTO Genomic_Profile VALUES ('GM129', 'SEQ-3344', 'MTHFR_677T', 'P129', '2023-04-21');
INSERT INTO Genomic_Profile VALUES ('GM130', 'SEQ-5161', 'TPMT*3C', 'P130', '2024-07-30');
INSERT INTO Genomic_Profile VALUES ('GM131', 'SEQ-1153', 'CYP2D6*4', 'P131', '2024-08-10');
INSERT INTO Genomic_Profile VALUES ('GM132', 'SEQ-9955', 'CYP2D6*4', 'P132', '2022-11-20');
INSERT INTO Genomic_Profile VALUES ('GM133', 'SEQ-8237', 'CYP2C9*3', 'P133', '2023-12-09');
INSERT INTO Genomic_Profile VALUES ('GM134', 'SEQ-5901', 'MTHFR_677T', 'P134', '2025-08-01');
INSERT INTO Genomic_Profile VALUES ('GM135', 'SEQ-5097', 'TPMT*3A', 'P135', '2024-07-24');
INSERT INTO Genomic_Profile VALUES ('GM136', 'SEQ-4263', 'CYP2D6*4', 'P136', '2024-02-27');
INSERT INTO Genomic_Profile VALUES ('GM137', 'SEQ-2747', 'TPMT*3C', 'P137', '2023-05-01');
INSERT INTO Genomic_Profile VALUES ('GM138', 'SEQ-6881', 'TPMT*3A', 'P138', '2025-03-23');
INSERT INTO Genomic_Profile VALUES ('GM139', 'SEQ-5837', 'CYP2D6*4', 'P139', '2022-02-14');
INSERT INTO Genomic_Profile VALUES ('GM140', 'SEQ-7484', 'SLCO1B1*5', 'P140', '2023-07-17');
INSERT INTO Genomic_Profile VALUES ('GM141', 'SEQ-1803', 'CYP2C9*2', 'P141', '2025-05-26');
INSERT INTO Genomic_Profile VALUES ('GM142', 'SEQ-9138', 'Normal', 'P142', '2023-08-10');
INSERT INTO Genomic_Profile VALUES ('GM143', 'SEQ-6772', 'CYP2C19*17', 'P143', '2023-03-25');
INSERT INTO Genomic_Profile VALUES ('GM144', 'SEQ-4115', 'SLCO1B1*5', 'P144', '2025-06-25');
INSERT INTO Genomic_Profile VALUES ('GM145', 'SEQ-3240', 'CYP2D6*4', 'P145', '2025-07-10');
INSERT INTO Genomic_Profile VALUES ('GM146', 'SEQ-1645', 'CYP2C9*3', 'P146', '2023-09-25');
INSERT INTO Genomic_Profile VALUES ('GM147', 'SEQ-1546', 'TPMT*3C', 'P147', '2025-04-01');
INSERT INTO Genomic_Profile VALUES ('GM148', 'SEQ-3153', 'CYP2D6*6', 'P148', '2022-07-04');
INSERT INTO Genomic_Profile VALUES ('GM149', 'SEQ-6352', 'CYP2D6*4', 'P149', '2024-04-30');
INSERT INTO Genomic_Profile VALUES ('GM150', 'SEQ-4289', 'CYP2C19*2', 'P150', '2022-09-28');




-- Drop trigger before Clinical_Log historical data load
DROP TRIGGER IF EXISTS trg_check_safety_before_log;
-- ============================================================
-- TABLE: Clinical_Log
-- ============================================================


INSERT INTO Clinical_Log VALUES ('L001', '2024-11-27', 100, 36.7, '113/83', 'Under observation', 'P001', 'D005');
INSERT INTO Clinical_Log VALUES ('L002', '2025-03-25', 66, 37.7, '114/70', 'Monitoring required', 'P002', 'D004');
INSERT INTO Clinical_Log VALUES ('L003', '2024-06-26', 86, 37.7, '138/85', 'Fully recovered', 'P003', 'D001');
INSERT INTO Clinical_Log VALUES ('L004', '2025-01-25', 78, 36.9, '130/71', 'Stable', 'P003', 'D008');
INSERT INTO Clinical_Log VALUES ('L005', '2023-08-13', 94, 37.9, '137/71', 'Improved', 'P004', 'D006');
INSERT INTO Clinical_Log VALUES ('L006', '2023-10-15', 71, 38.3, '111/82', 'Fully recovered', 'P005', 'D002');
INSERT INTO Clinical_Log VALUES ('L007', '2025-05-08', 78, 38.2, '110/79', 'Monitoring required', 'P007', 'D009');
INSERT INTO Clinical_Log VALUES ('L008', '2023-11-16', 81, 36.8, '130/87', 'Monitoring required', 'P007', 'D010');
INSERT INTO Clinical_Log VALUES ('L009', '2025-04-15', 68, 38.1, '124/78', 'Improved', 'P008', 'D008');
INSERT INTO Clinical_Log VALUES ('L010', '2023-03-10', 81, 36.5, '124/90', 'Under observation', 'P008', 'D005');
INSERT INTO Clinical_Log VALUES ('L011', '2024-04-29', 60, 37.9, '135/79', 'Monitoring required', 'P009', 'D008');
INSERT INTO Clinical_Log VALUES ('L012', '2023-07-25', 71, 37.6, '130/82', 'Fully recovered', 'P009', 'D006');
INSERT INTO Clinical_Log VALUES ('L013', '2025-01-07', 65, 37.1, '113/75', 'Improved', 'P009', 'D006');
INSERT INTO Clinical_Log VALUES ('L014', '2024-01-25', 80, 38.3, '110/78', 'Fully recovered', 'P010', 'D005');
INSERT INTO Clinical_Log VALUES ('L015', '2024-03-10', 88, 37.9, '140/80', 'Under observation', 'P011', 'D002');
INSERT INTO Clinical_Log VALUES ('L016', '2024-05-13', 76, 37.7, '132/77', 'Stable', 'P012', 'D006');
INSERT INTO Clinical_Log VALUES ('L017', '2024-02-29', 89, 36.8, '122/86', 'Under observation', 'P012', 'D002');
INSERT INTO Clinical_Log VALUES ('L018', '2023-01-07', 100, 38.3, '119/81', 'Monitoring required', 'P013', 'D003');
INSERT INTO Clinical_Log VALUES ('L019', '2023-10-26', 74, 38.4, '125/74', 'Fully recovered', 'P013', 'D005');
INSERT INTO Clinical_Log VALUES ('L020', '2024-05-29', 86, 37.8, '139/85', 'Monitoring required', 'P013', 'D003');
INSERT INTO Clinical_Log VALUES ('L021', '2025-12-16', 75, 37.7, '129/72', 'Monitoring required', 'P017', 'D007');
INSERT INTO Clinical_Log VALUES ('L022', '2025-07-07', 93, 37.8, '112/88', 'Stable', 'P018', 'D008');
INSERT INTO Clinical_Log VALUES ('L023', '2025-10-29', 95, 38.3, '116/88', 'Monitoring required', 'P019', 'D008');
INSERT INTO Clinical_Log VALUES ('L024', '2023-03-31', 70, 36.9, '126/84', 'Stable', 'P019', 'D004');
INSERT INTO Clinical_Log VALUES ('L025', '2023-05-05', 97, 37.3, '138/86', 'Fully recovered', 'P020', 'D001');
INSERT INTO Clinical_Log VALUES ('L026', '2025-04-02', 89, 36.4, '123/84', 'Monitoring required', 'P020', 'D008');
INSERT INTO Clinical_Log VALUES ('L027', '2023-06-18', 95, 37.2, '135/79', 'Stable', 'P021', 'D002');
INSERT INTO Clinical_Log VALUES ('L028', '2023-10-31', 76, 38.1, '133/76', 'Monitoring required', 'P021', 'D006');
INSERT INTO Clinical_Log VALUES ('L029', '2025-11-01', 62, 37.1, '132/72', 'Monitoring required', 'P023', 'D008');
INSERT INTO Clinical_Log VALUES ('L030', '2025-06-03', 64, 38.5, '125/71', 'Under observation', 'P023', 'D010');
INSERT INTO Clinical_Log VALUES ('L031', '2024-03-18', 71, 37.9, '134/90', 'Fully recovered', 'P024', 'D002');
INSERT INTO Clinical_Log VALUES ('L032', '2024-11-25', 84, 37.2, '139/82', 'Fully recovered', 'P025', 'D007');
INSERT INTO Clinical_Log VALUES ('L033', '2025-03-28', 94, 36.4, '137/81', 'Stable', 'P025', 'D008');
INSERT INTO Clinical_Log VALUES ('L034', '2025-05-24', 94, 37.0, '114/77', 'Stable', 'P026', 'D006');
INSERT INTO Clinical_Log VALUES ('L035', '2023-07-13', 79, 37.2, '133/87', 'Fully recovered', 'P027', 'D002');
INSERT INTO Clinical_Log VALUES ('L036', '2024-10-02', 74, 36.7, '121/74', 'Under observation', 'P029', 'D005');
INSERT INTO Clinical_Log VALUES ('L037', '2023-08-01', 67, 36.2, '131/83', 'Monitoring required', 'P029', 'D006');
INSERT INTO Clinical_Log VALUES ('L038', '2024-04-07', 75, 36.6, '113/89', 'Stable', 'P030', 'D008');
INSERT INTO Clinical_Log VALUES ('L039', '2024-04-08', 98, 37.7, '137/71', 'Improved', 'P031', 'D010');
INSERT INTO Clinical_Log VALUES ('L040', '2024-07-02', 85, 37.2, '127/76', 'Stable', 'P032', 'D010');
INSERT INTO Clinical_Log VALUES ('L041', '2024-12-21', 92, 38.5, '117/88', 'Under observation', 'P033', 'D006');
INSERT INTO Clinical_Log VALUES ('L042', '2024-01-10', 75, 36.8, '114/86', 'Improved', 'P033', 'D001');
INSERT INTO Clinical_Log VALUES ('L043', '2023-05-26', 79, 36.8, '127/88', 'Improved', 'P034', 'D007');
INSERT INTO Clinical_Log VALUES ('L044', '2023-07-09', 95, 37.3, '121/90', 'Fully recovered', 'P035', 'D001');
INSERT INTO Clinical_Log VALUES ('L045', '2025-07-21', 86, 37.1, '119/82', 'Improved', 'P036', 'D007');
INSERT INTO Clinical_Log VALUES ('L046', '2024-09-30', 75, 38.1, '119/74', 'Fully recovered', 'P036', 'D006');
INSERT INTO Clinical_Log VALUES ('L047', '2023-11-20', 95, 37.1, '123/87', 'Monitoring required', 'P037', 'D003');
INSERT INTO Clinical_Log VALUES ('L048', '2024-07-14', 84, 36.7, '116/80', 'Stable', 'P037', 'D002');
INSERT INTO Clinical_Log VALUES ('L049', '2025-06-26', 83, 36.3, '133/76', 'Stable', 'P038', 'D008');
INSERT INTO Clinical_Log VALUES ('L050', '2024-07-14', 84, 37.7, '129/71', 'Stable', 'P038', 'D007');
INSERT INTO Clinical_Log VALUES ('L051', '2024-12-08', 97, 37.8, '127/76', 'Fully recovered', 'P039', 'D002');
INSERT INTO Clinical_Log VALUES ('L052', '2024-09-24', 81, 36.8, '139/70', 'Improved', 'P040', 'D009');
INSERT INTO Clinical_Log VALUES ('L053', '2024-03-09', 67, 37.9, '134/85', 'Improved', 'P042', 'D005');
INSERT INTO Clinical_Log VALUES ('L054', '2023-02-11', 85, 38.3, '127/80', 'Under observation', 'P046', 'D007');
INSERT INTO Clinical_Log VALUES ('L055', '2023-06-11', 89, 37.4, '121/79', 'Under observation', 'P046', 'D008');
INSERT INTO Clinical_Log VALUES ('L056', '2025-04-10', 92, 38.2, '124/73', 'Fully recovered', 'P047', 'D010');
INSERT INTO Clinical_Log VALUES ('L057', '2024-08-16', 73, 37.0, '123/71', 'Monitoring required', 'P047', 'D007');
INSERT INTO Clinical_Log VALUES ('L058', '2025-01-14', 69, 36.1, '127/88', 'Monitoring required', 'P049', 'D008');
INSERT INTO Clinical_Log VALUES ('L059', '2024-05-14', 78, 36.5, '120/77', 'Fully recovered', 'P050', 'D002');
INSERT INTO Clinical_Log VALUES ('L060', '2023-06-14', 91, 37.4, '140/80', 'Under observation', 'P051', 'D009');
INSERT INTO Clinical_Log VALUES ('L061', '2023-06-07', 91, 37.2, '133/81', 'Improved', 'P052', 'D003');
INSERT INTO Clinical_Log VALUES ('L062', '2025-11-10', 94, 37.3, '139/87', 'Stable', 'P052', 'D009');
INSERT INTO Clinical_Log VALUES ('L063', '2023-11-02', 64, 38.4, '131/71', 'Stable', 'P053', 'D006');
INSERT INTO Clinical_Log VALUES ('L064', '2023-11-10', 68, 38.1, '117/72', 'Improved', 'P055', 'D010');
INSERT INTO Clinical_Log VALUES ('L065', '2024-10-26', 73, 37.3, '121/71', 'Monitoring required', 'P056', 'D010');
INSERT INTO Clinical_Log VALUES ('L066', '2023-04-26', 91, 36.1, '127/87', 'Fully recovered', 'P057', 'D005');
INSERT INTO Clinical_Log VALUES ('L067', '2025-08-03', 61, 37.4, '118/87', 'Under observation', 'P058', 'D005');
INSERT INTO Clinical_Log VALUES ('L068', '2023-03-19', 92, 38.1, '131/83', 'Improved', 'P058', 'D008');
INSERT INTO Clinical_Log VALUES ('L069', '2024-01-23', 66, 37.4, '117/76', 'Monitoring required', 'P060', 'D008');
INSERT INTO Clinical_Log VALUES ('L070', '2025-09-04', 82, 36.7, '122/72', 'Under observation', 'P060', 'D006');
INSERT INTO Clinical_Log VALUES ('L071', '2025-10-30', 89, 37.5, '132/77', 'Under observation', 'P061', 'D002');
INSERT INTO Clinical_Log VALUES ('L072', '2023-03-25', 62, 36.3, '122/82', 'Monitoring required', 'P061', 'D003');
INSERT INTO Clinical_Log VALUES ('L073', '2025-06-21', 63, 37.6, '132/75', 'Stable', 'P062', 'D008');
INSERT INTO Clinical_Log VALUES ('L074', '2024-08-02', 87, 37.6, '120/88', 'Stable', 'P063', 'D006');
INSERT INTO Clinical_Log VALUES ('L075', '2023-04-20', 74, 36.6, '137/88', 'Fully recovered', 'P063', 'D006');
INSERT INTO Clinical_Log VALUES ('L076', '2023-07-13', 62, 38.3, '131/78', 'Monitoring required', 'P064', 'D006');
INSERT INTO Clinical_Log VALUES ('L077', '2025-03-03', 71, 38.3, '120/70', 'Improved', 'P064', 'D009');
INSERT INTO Clinical_Log VALUES ('L078', '2023-10-18', 85, 38.3, '119/75', 'Monitoring required', 'P065', 'D002');
INSERT INTO Clinical_Log VALUES ('L079', '2025-02-13', 96, 38.1, '122/87', 'Under observation', 'P066', 'D009');
INSERT INTO Clinical_Log VALUES ('L080', '2025-01-14', 68, 38.0, '132/72', 'Monitoring required', 'P067', 'D001');
INSERT INTO Clinical_Log VALUES ('L081', '2024-01-08', 63, 36.3, '117/72', 'Under observation', 'P067', 'D005');
INSERT INTO Clinical_Log VALUES ('L082', '2024-08-29', 80, 36.2, '118/84', 'Fully recovered', 'P068', 'D002');
INSERT INTO Clinical_Log VALUES ('L083', '2025-12-17', 82, 37.4, '122/83', 'Improved', 'P069', 'D009');
INSERT INTO Clinical_Log VALUES ('L084', '2023-09-26', 65, 38.0, '119/77', 'Stable', 'P070', 'D006');
INSERT INTO Clinical_Log VALUES ('L085', '2025-01-19', 77, 36.5, '132/90', 'Improved', 'P071', 'D007');
INSERT INTO Clinical_Log VALUES ('L086', '2024-08-09', 80, 37.0, '112/70', 'Under observation', 'P072', 'D010');
INSERT INTO Clinical_Log VALUES ('L087', '2025-06-22', 83, 37.9, '113/74', 'Stable', 'P073', 'D006');
INSERT INTO Clinical_Log VALUES ('L088', '2024-02-13', 87, 37.2, '127/86', 'Fully recovered', 'P074', 'D003');
INSERT INTO Clinical_Log VALUES ('L089', '2025-07-11', 61, 36.3, '127/72', 'Monitoring required', 'P076', 'D005');
INSERT INTO Clinical_Log VALUES ('L090', '2023-10-30', 84, 36.1, '123/82', 'Stable', 'P076', 'D009');
INSERT INTO Clinical_Log VALUES ('L091', '2024-12-17', 96, 37.4, '131/82', 'Improved', 'P077', 'D008');
INSERT INTO Clinical_Log VALUES ('L092', '2025-04-30', 77, 36.8, '125/74', 'Stable', 'P077', 'D001');
INSERT INTO Clinical_Log VALUES ('L093', '2025-02-06', 87, 36.8, '119/85', 'Stable', 'P078', 'D009');
INSERT INTO Clinical_Log VALUES ('L094', '2023-03-21', 76, 38.4, '133/90', 'Fully recovered', 'P081', 'D003');
INSERT INTO Clinical_Log VALUES ('L095', '2025-08-27', 89, 36.4, '119/70', 'Fully recovered', 'P081', 'D005');
INSERT INTO Clinical_Log VALUES ('L096', '2023-02-10', 99, 37.0, '137/80', 'Fully recovered', 'P082', 'D002');
INSERT INTO Clinical_Log VALUES ('L097', '2025-12-17', 87, 38.1, '137/90', 'Monitoring required', 'P083', 'D010');
INSERT INTO Clinical_Log VALUES ('L098', '2023-04-10', 79, 36.9, '140/76', 'Fully recovered', 'P084', 'D002');
INSERT INTO Clinical_Log VALUES ('L099', '2025-07-28', 71, 38.4, '140/80', 'Under observation', 'P085', 'D010');
INSERT INTO Clinical_Log VALUES ('L100', '2025-06-01', 96, 38.0, '120/82', 'Under observation', 'P087', 'D005');
INSERT INTO Clinical_Log VALUES ('L101', '2024-12-24', 83, 36.4, '128/76', 'Monitoring required', 'P087', 'D001');
INSERT INTO Clinical_Log VALUES ('L102', '2025-05-06', 95, 36.2, '133/84', 'Improved', 'P087', 'D004');
INSERT INTO Clinical_Log VALUES ('L103', '2025-12-09', 78, 38.1, '112/83', 'Fully recovered', 'P088', 'D002');
INSERT INTO Clinical_Log VALUES ('L104', '2025-08-23', 100, 36.8, '118/74', 'Fully recovered', 'P089', 'D007');
INSERT INTO Clinical_Log VALUES ('L105', '2025-03-06', 64, 37.2, '129/85', 'Monitoring required', 'P089', 'D001');
INSERT INTO Clinical_Log VALUES ('L106', '2023-05-19', 94, 37.3, '139/83', 'Monitoring required', 'P090', 'D006');
INSERT INTO Clinical_Log VALUES ('L107', '2024-05-08', 83, 37.8, '135/87', 'Monitoring required', 'P090', 'D006');
INSERT INTO Clinical_Log VALUES ('L108', '2023-04-01', 66, 37.9, '131/81', 'Improved', 'P091', 'D003');
INSERT INTO Clinical_Log VALUES ('L109', '2023-04-02', 96, 38.5, '131/90', 'Fully recovered', 'P092', 'D004');
INSERT INTO Clinical_Log VALUES ('L110', '2024-09-28', 87, 36.4, '113/78', 'Improved', 'P093', 'D006');
INSERT INTO Clinical_Log VALUES ('L111', '2025-01-02', 88, 37.0, '124/88', 'Monitoring required', 'P094', 'D005');
INSERT INTO Clinical_Log VALUES ('L112', '2024-07-03', 82, 38.5, '125/73', 'Under observation', 'P096', 'D009');
INSERT INTO Clinical_Log VALUES ('L113', '2023-06-13', 65, 36.4, '140/74', 'Under observation', 'P097', 'D007');
INSERT INTO Clinical_Log VALUES ('L114', '2024-08-26', 81, 37.2, '116/86', 'Fully recovered', 'P098', 'D009');
INSERT INTO Clinical_Log VALUES ('L115', '2025-06-28', 90, 36.3, '133/84', 'Under observation', 'P100', 'D003');
INSERT INTO Clinical_Log VALUES ('L116', '2025-07-06', 79, 36.2, '132/73', 'Stable', 'P100', 'D006');
INSERT INTO Clinical_Log VALUES ('L117', '2025-06-10', 66, 37.7, '115/77', 'Monitoring required', 'P101', 'D006');
INSERT INTO Clinical_Log VALUES ('L118', '2025-04-12', 95, 36.5, '127/83', 'Fully recovered', 'P102', 'D002');
INSERT INTO Clinical_Log VALUES ('L119', '2025-11-19', 85, 37.6, '115/90', 'Fully recovered', 'P102', 'D006');
INSERT INTO Clinical_Log VALUES ('L120', '2025-06-19', 61, 37.9, '138/76', 'Fully recovered', 'P103', 'D003');
INSERT INTO Clinical_Log VALUES ('L121', '2024-04-28', 84, 36.1, '116/76', 'Under observation', 'P103', 'D002');
INSERT INTO Clinical_Log VALUES ('L122', '2023-03-10', 96, 36.3, '137/87', 'Improved', 'P104', 'D010');
INSERT INTO Clinical_Log VALUES ('L123', '2023-11-13', 80, 36.6, '113/78', 'Fully recovered', 'P104', 'D010');
INSERT INTO Clinical_Log VALUES ('L124', '2025-01-31', 98, 37.0, '122/88', 'Stable', 'P104', 'D008');
INSERT INTO Clinical_Log VALUES ('L125', '2023-10-09', 82, 38.1, '129/75', 'Under observation', 'P105', 'D010');
INSERT INTO Clinical_Log VALUES ('L126', '2023-08-22', 68, 36.9, '117/79', 'Stable', 'P106', 'D004');
INSERT INTO Clinical_Log VALUES ('L127', '2024-01-18', 83, 37.8, '126/82', 'Fully recovered', 'P106', 'D001');
INSERT INTO Clinical_Log VALUES ('L128', '2023-08-31', 96, 37.0, '115/85', 'Monitoring required', 'P107', 'D009');
INSERT INTO Clinical_Log VALUES ('L129', '2024-06-19', 95, 36.5, '119/74', 'Improved', 'P107', 'D005');
INSERT INTO Clinical_Log VALUES ('L130', '2024-02-17', 88, 37.6, '137/81', 'Stable', 'P108', 'D008');
INSERT INTO Clinical_Log VALUES ('L131', '2025-07-17', 68, 36.6, '122/87', 'Monitoring required', 'P108', 'D002');
INSERT INTO Clinical_Log VALUES ('L132', '2023-06-30', 86, 37.7, '123/84', 'Fully recovered', 'P109', 'D008');
INSERT INTO Clinical_Log VALUES ('L133', '2023-11-19', 65, 37.5, '135/77', 'Under observation', 'P110', 'D005');
INSERT INTO Clinical_Log VALUES ('L134', '2023-02-26', 77, 36.6, '119/75', 'Fully recovered', 'P111', 'D008');
INSERT INTO Clinical_Log VALUES ('L135', '2025-01-27', 95, 37.3, '128/73', 'Under observation', 'P111', 'D006');
INSERT INTO Clinical_Log VALUES ('L136', '2023-06-27', 94, 38.1, '111/84', 'Monitoring required', 'P112', 'D010');
INSERT INTO Clinical_Log VALUES ('L137', '2025-04-23', 87, 36.3, '136/90', 'Improved', 'P113', 'D009');
INSERT INTO Clinical_Log VALUES ('L138', '2023-06-01', 62, 37.2, '121/72', 'Fully recovered', 'P113', 'D007');
INSERT INTO Clinical_Log VALUES ('L139', '2024-01-11', 75, 36.6, '133/88', 'Under observation', 'P115', 'D003');
INSERT INTO Clinical_Log VALUES ('L140', '2025-06-05', 70, 37.6, '135/76', 'Improved', 'P115', 'D003');
INSERT INTO Clinical_Log VALUES ('L141', '2024-10-23', 96, 36.9, '118/89', 'Monitoring required', 'P116', 'D003');
INSERT INTO Clinical_Log VALUES ('L142', '2024-12-11', 80, 38.4, '119/79', 'Monitoring required', 'P116', 'D004');
INSERT INTO Clinical_Log VALUES ('L143', '2024-07-19', 92, 38.5, '131/73', 'Improved', 'P117', 'D004');
INSERT INTO Clinical_Log VALUES ('L144', '2025-12-29', 63, 38.5, '137/90', 'Improved', 'P117', 'D010');
INSERT INTO Clinical_Log VALUES ('L145', '2023-11-15', 75, 36.5, '120/77', 'Fully recovered', 'P118', 'D003');
INSERT INTO Clinical_Log VALUES ('L146', '2024-11-25', 69, 37.5, '118/90', 'Fully recovered', 'P119', 'D010');
INSERT INTO Clinical_Log VALUES ('L147', '2025-05-05', 88, 36.3, '135/72', 'Fully recovered', 'P120', 'D004');
INSERT INTO Clinical_Log VALUES ('L148', '2025-09-16', 83, 37.2, '125/80', 'Monitoring required', 'P121', 'D005');
INSERT INTO Clinical_Log VALUES ('L149', '2025-04-11', 65, 37.9, '124/90', 'Under observation', 'P121', 'D004');
INSERT INTO Clinical_Log VALUES ('L150', '2023-11-23', 94, 37.1, '140/83', 'Improved', 'P122', 'D001');
INSERT INTO Clinical_Log VALUES ('L151', '2023-10-23', 77, 36.9, '119/80', 'Monitoring required', 'P123', 'D006');
INSERT INTO Clinical_Log VALUES ('L152', '2025-11-20', 96, 38.1, '135/80', 'Stable', 'P124', 'D006');
INSERT INTO Clinical_Log VALUES ('L153', '2023-08-06', 66, 37.6, '136/84', 'Stable', 'P124', 'D009');
INSERT INTO Clinical_Log VALUES ('L154', '2024-05-23', 70, 37.2, '110/83', 'Improved', 'P125', 'D008');
INSERT INTO Clinical_Log VALUES ('L155', '2023-07-20', 79, 36.5, '139/78', 'Stable', 'P125', 'D003');
INSERT INTO Clinical_Log VALUES ('L156', '2025-05-06', 76, 36.3, '131/90', 'Improved', 'P126', 'D007');
INSERT INTO Clinical_Log VALUES ('L157', '2023-02-17', 85, 37.6, '133/77', 'Fully recovered', 'P129', 'D008');
INSERT INTO Clinical_Log VALUES ('L158', '2025-03-17', 66, 36.1, '125/72', 'Improved', 'P129', 'D002');
INSERT INTO Clinical_Log VALUES ('L159', '2025-10-10', 93, 37.7, '110/70', 'Under observation', 'P130', 'D005');
INSERT INTO Clinical_Log VALUES ('L160', '2023-01-20', 87, 37.8, '125/72', 'Improved', 'P131', 'D009');
INSERT INTO Clinical_Log VALUES ('L161', '2025-06-03', 65, 37.9, '113/73', 'Under observation', 'P131', 'D002');
INSERT INTO Clinical_Log VALUES ('L162', '2025-03-31', 79, 36.4, '134/74', 'Improved', 'P132', 'D001');
INSERT INTO Clinical_Log VALUES ('L163', '2024-02-06', 93, 37.5, '129/90', 'Improved', 'P132', 'D001');
INSERT INTO Clinical_Log VALUES ('L164', '2025-03-20', 82, 37.8, '130/74', 'Fully recovered', 'P134', 'D002');
INSERT INTO Clinical_Log VALUES ('L165', '2025-01-21', 73, 36.3, '113/74', 'Stable', 'P134', 'D009');
INSERT INTO Clinical_Log VALUES ('L166', '2023-03-23', 82, 38.4, '120/74', 'Improved', 'P136', 'D001');
INSERT INTO Clinical_Log VALUES ('L167', '2025-11-23', 65, 36.7, '129/89', 'Monitoring required', 'P137', 'D003');
INSERT INTO Clinical_Log VALUES ('L168', '2024-09-05', 61, 38.1, '131/79', 'Improved', 'P138', 'D010');
INSERT INTO Clinical_Log VALUES ('L169', '2025-11-12', 85, 36.8, '111/77', 'Fully recovered', 'P138', 'D009');
INSERT INTO Clinical_Log VALUES ('L170', '2025-01-24', 67, 36.7, '130/89', 'Stable', 'P139', 'D001');
INSERT INTO Clinical_Log VALUES ('L171', '2023-08-16', 83, 38.3, '114/82', 'Monitoring required', 'P139', 'D006');
INSERT INTO Clinical_Log VALUES ('L172', '2024-04-11', 83, 37.4, '115/85', 'Stable', 'P140', 'D005');
INSERT INTO Clinical_Log VALUES ('L173', '2025-12-09', 97, 36.3, '118/76', 'Stable', 'P140', 'D003');
INSERT INTO Clinical_Log VALUES ('L174', '2023-03-09', 85, 37.3, '130/86', 'Fully recovered', 'P141', 'D004');
INSERT INTO Clinical_Log VALUES ('L175', '2023-08-15', 85, 36.3, '127/87', 'Monitoring required', 'P141', 'D010');
INSERT INTO Clinical_Log VALUES ('L176', '2025-04-26', 77, 36.3, '112/86', 'Improved', 'P142', 'D003');
INSERT INTO Clinical_Log VALUES ('L177', '2025-04-22', 94, 36.9, '128/90', 'Stable', 'P142', 'D004');
INSERT INTO Clinical_Log VALUES ('L178', '2025-11-29', 87, 37.9, '137/77', 'Stable', 'P143', 'D003');
INSERT INTO Clinical_Log VALUES ('L179', '2024-10-27', 65, 38.3, '113/84', 'Monitoring required', 'P143', 'D004');
INSERT INTO Clinical_Log VALUES ('L180', '2025-12-12', 79, 37.7, '131/75', 'Stable', 'P143', 'D008');
INSERT INTO Clinical_Log VALUES ('L181', '2025-12-29', 68, 37.8, '115/85', 'Under observation', 'P144', 'D008');
INSERT INTO Clinical_Log VALUES ('L182', '2024-05-19', 70, 37.0, '133/78', 'Stable', 'P145', 'D004');
INSERT INTO Clinical_Log VALUES ('L183', '2024-09-05', 81, 38.0, '118/86', 'Stable', 'P145', 'D005');
INSERT INTO Clinical_Log VALUES ('L184', '2024-10-13', 96, 37.6, '125/84', 'Monitoring required', 'P146', 'D008');
INSERT INTO Clinical_Log VALUES ('L185', '2025-02-17', 63, 37.3, '128/75', 'Under observation', 'P147', 'D002');
INSERT INTO Clinical_Log VALUES ('L186', '2024-03-15', 76, 38.0, '138/88', 'Stable', 'P149', 'D008');
INSERT INTO Clinical_Log VALUES ('L187', '2024-07-09', 92, 36.1, '137/70', 'Improved', 'P149', 'D004');
INSERT INTO Clinical_Log VALUES ('L188', '2024-05-05', 90, 37.0, '139/74', 'Improved', 'P150', 'D002');
INSERT INTO Clinical_Log VALUES ('L189', '2023-04-15', 95, 38.0, '132/90', 'Fully recovered', 'P150', 'D004');


-- TRIGGER 3: Updated for Universal Safety
DELIMITER $$
CREATE TRIGGER trg_check_safety_before_log
BEFORE INSERT ON Clinical_Log
FOR EACH ROW
BEGIN
    DECLARE v_blocked_count INT DEFAULT 0;

    -- Look for ANY blocked status for this patient, ignoring the doctor_id
    SELECT COUNT(*) INTO v_blocked_count
    FROM Safety_Validation
    WHERE patient_id = NEW.patient_id
      -- AND doctor_id = NEW.doctor_id  <-- REMOVE OR COMMENT OUT THIS LINE
      AND status     = 'Blocked';

    IF v_blocked_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'SAFETY ALERT: Blocked safety validation exists for this patient. Review genomic profile before logging.';
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- TABLE: Log_Symptoms
-- ============================================================
INSERT INTO Log_Symptoms VALUES ('L001', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L001', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L002', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L002', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L002', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L003', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L003', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L003', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L004', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L005', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L005', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L005', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L006', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L006', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L007', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L007', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L008', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L009', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L010', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L010', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L010', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L011', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L011', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L012', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L012', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L012', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L013', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L014', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L015', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L015', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L015', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L016', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L017', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L017', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L017', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L018', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L018', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L018', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L019', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L020', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L020', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L020', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L021', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L022', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L022', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L023', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L023', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L023', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L024', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L024', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L024', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L025', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L025', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L026', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L026', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L027', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L027', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L028', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L028', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L029', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L030', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L031', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L032', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L033', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L033', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L034', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L035', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L035', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L036', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L036', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L037', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L038', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L039', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L039', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L039', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L040', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L041', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L041', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L041', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L042', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L042', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L042', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L043', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L044', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L044', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L045', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L046', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L047', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L048', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L049', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L050', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L050', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L051', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L051', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L051', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L052', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L053', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L053', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L053', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L054', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L054', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L055', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L055', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L056', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L056', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L056', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L057', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L058', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L058', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L058', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L059', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L060', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L060', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L061', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L062', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L062', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L062', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L063', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L063', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L064', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L065', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L065', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L066', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L066', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L067', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L068', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L069', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L069', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L069', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L070', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L070', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L071', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L071', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L072', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L073', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L073', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L073', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L074', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L075', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L075', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L075', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L076', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L077', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L077', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L077', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L078', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L079', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L079', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L080', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L081', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L081', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L081', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L082', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L082', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L082', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L083', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L083', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L083', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L084', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L085', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L086', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L086', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L086', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L087', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L088', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L088', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L088', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L089', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L089', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L089', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L090', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L091', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L091', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L091', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L092', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L093', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L093', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L093', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L094', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L094', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L095', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L096', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L096', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L096', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L097', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L097', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L097', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L098', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L098', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L098', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L099', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L099', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L099', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L100', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L100', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L100', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L101', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L102', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L102', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L102', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L103', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L104', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L104', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L104', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L105', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L105', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L106', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L106', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L106', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L107', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L107', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L108', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L108', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L108', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L109', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L110', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L111', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L111', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L112', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L112', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L113', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L113', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L114', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L115', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L115', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L115', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L116', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L117', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L117', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L118', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L118', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L119', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L119', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L120', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L121', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L121', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L121', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L122', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L122', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L122', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L123', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L123', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L123', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L124', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L125', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L126', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L126', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L127', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L127', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L127', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L128', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L129', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L129', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L130', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L131', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L131', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L132', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L133', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L133', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L133', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L134', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L135', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L136', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L137', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L138', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L138', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L139', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L139', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L139', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L140', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L141', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L141', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L142', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L142', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L143', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L143', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L144', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L145', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L145', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L145', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L146', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L147', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L147', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L147', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L148', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L148', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L149', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L149', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L149', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L150', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L150', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L151', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L151', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L151', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L152', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L153', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L154', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L155', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L156', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L156', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L157', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L158', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L158', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L158', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L159', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L160', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L160', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L160', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L161', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L161', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L161', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L162', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L163', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L164', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L164', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L164', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L165', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L165', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L166', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L166', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L167', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L167', 'Weakness');
INSERT INTO Log_Symptoms VALUES ('L167', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L168', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L169', 'Headache');
INSERT INTO Log_Symptoms VALUES ('L169', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L170', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L171', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L171', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L172', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L172', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L172', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L173', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L174', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L174', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L175', 'Nausea');
INSERT INTO Log_Symptoms VALUES ('L175', 'Palpitations');
INSERT INTO Log_Symptoms VALUES ('L176', 'Insomnia');
INSERT INTO Log_Symptoms VALUES ('L177', 'Dry mouth');
INSERT INTO Log_Symptoms VALUES ('L177', 'Anxiety');
INSERT INTO Log_Symptoms VALUES ('L177', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L178', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L178', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L178', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L179', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L179', 'Rash');
INSERT INTO Log_Symptoms VALUES ('L180', 'Blurred vision');
INSERT INTO Log_Symptoms VALUES ('L180', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L180', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L181', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L182', 'Mild fever');
INSERT INTO Log_Symptoms VALUES ('L183', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L183', 'Joint pain');
INSERT INTO Log_Symptoms VALUES ('L184', 'Loss of appetite');
INSERT INTO Log_Symptoms VALUES ('L185', 'Fatigue');
INSERT INTO Log_Symptoms VALUES ('L185', 'Chest pain');
INSERT INTO Log_Symptoms VALUES ('L185', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L186', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L187', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L188', 'Dizziness');
INSERT INTO Log_Symptoms VALUES ('L188', 'Back pain');
INSERT INTO Log_Symptoms VALUES ('L189', 'Shortness of breath');
INSERT INTO Log_Symptoms VALUES ('L189', 'Edema');
INSERT INTO Log_Symptoms VALUES ('L189', 'Back pain');
-- Master compatibility rules based on pharmacogenomics
INSERT INTO Genomic_Drug_Compatibility VALUES
('GC001', 'CYP2C9*2',   'CYP2C9_substrate',   'Caution', 'Reduced CYP2C9 activity — lower dose needed'),
('GC002', 'CYP2C9*3',   'CYP2C9_substrate',   'Blocked', 'Severely reduced CYP2C9 — drug contraindicated'),
('GC003', 'CYP2C19*2',  'CYP2C19_substrate',  'Blocked', 'Poor metabolizer — drug ineffective or toxic'),
('GC004', 'CYP2C19*17', 'CYP2C19_substrate',  'Caution', 'Ultra-rapid metabolizer — higher dose may be needed'),
('GC005', 'CYP2D6*4',   'CYP2D6_substrate',   'Blocked', 'Poor metabolizer — drug accumulates to toxic levels'),
('GC006', 'CYP2D6*6',   'CYP2D6_substrate',   'Blocked', 'Poor metabolizer — drug accumulates to toxic levels'),
('GC007', 'TPMT*3A',    'TPMT_substrate',     'Blocked', 'Severely reduced TPMT — risk of fatal toxicity'),
('GC008', 'TPMT*3C',    'TPMT_substrate',     'Blocked', 'Reduced TPMT activity — dose reduction required'),
('GC009', 'SLCO1B1*5',  'SLCO1B1_substrate',  'Caution', 'Reduced drug transport — monitor for side effects'),
('GC010', 'MTHFR_677T', 'MTHFR_substrate',    'Caution', 'Reduced folate metabolism — supplement required'),
('GC011', 'BRCA1_mut',  'CYP2D6_substrate',   'Caution', 'BRCA1 mutation — increased cancer drug sensitivity'),
('GC012', 'Normal',     'CYP2C9_substrate',   'Safe',    'Normal metabolizer — standard dose applies'),
('GC013', 'Normal',     'CYP2C19_substrate',  'Safe',    'Normal metabolizer — standard dose applies'),
('GC014', 'Normal',     'CYP2D6_substrate',   'Safe',    'Normal metabolizer — standard dose applies'),
('GC015', 'Normal',     'TPMT_substrate',     'Safe',    'Normal metabolizer — standard dose applies'),
('GC016', 'Normal',     'SLCO1B1_substrate',  'Safe',    'Normal metabolizer — standard dose applies'),
('GC017', 'Normal',     'MTHFR_substrate',    'Safe',    'Normal metabolizer — standard dose applies');
-- Generate Safety_Validation data from genomic rules
SET SQL_SAFE_UPDATES = 0;
CALL Regenerate_Safety_Validations();
SET SQL_SAFE_UPDATES = 1;



-- TEST QUERIES

-- 1. Test Calculate_Age
-- SELECT Calculate_Age('P001') AS PatientAge;

-- 2. Test Get_Safety_Score
-- SELECT Get_Safety_Score('P001', 'DR003') AS SafetyScore;

-- 3. Test Get_Genomic_Compatibility
-- SELECT Get_Genomic_Compatibility('P001', 'DR003') AS Compatibility;

-- 4. Test cursor
-- CALL Review_Side_Effects('P001');

-- 5. Test procedure - success
CALL Generate_Log_Entry('L999', 'P010', 'D004', 78, 37.1, '120/80', 'Stable');

-- 6. Test GENOMIC_DATA_MISSING
-- INSERT INTO Patient VALUES ('P999', 'Test', 'Patient', '1990-01-01', 'O+');
-- CALL Generate_Log_Entry('L998', 'P999', 'D001', 80, 37.0, '120/80', 'Stable');

-- 7. Row count verification
-- SELECT 'Patient'                      AS tbl, COUNT(*) AS total FROM Patient
-- UNION ALL SELECT 'Doctor',                     COUNT(*) FROM Doctor
-- UNION ALL SELECT 'Medication',                 COUNT(*) FROM Medication
-- UNION ALL SELECT 'Medication_Side_Effects',    COUNT(*) FROM Medication_Side_Effects
-- UNION ALL SELECT 'Genomic_Profile',            COUNT(*) FROM Genomic_Profile
-- UNION ALL SELECT 'Genomic_Drug_Compatibility', COUNT(*) FROM Genomic_Drug_Compatibility
-- UNION ALL SELECT 'Safety_Validation',          COUNT(*) FROM Safety_Validation
-- UNION ALL SELECT 'Clinical_Log',               COUNT(*) FROM Clinical_Log
-- UNION ALL SELECT 'Log_Symptoms',               COUNT(*) FROM Log_Symptoms;

-- 8. Patient drug compatibility
-- SELECT PatientName, variant, DrugName, standard_dose, RecommendedStatus, RecommendedDose, Reason
-- FROM vw_patient_drug_compatibility
-- WHERE patient_id = 'P001';

-- SELECT 
 --   COUNT(*)             AS TotalValidations,
 --   SUM(status = 'Safe')    AS Safe,
 --   SUM(status = 'Caution') AS Caution,
 --   SUM(status = 'Blocked') AS Blocked
-- FROM Safety_Validation;