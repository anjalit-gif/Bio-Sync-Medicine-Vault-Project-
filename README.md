# Bio-Sync-Medicine-Vault-Project-
Bio Sync Medicine Vault is a database-driven safety system that sits at the intersection of pharmacogenomics and health informatics. It prevents adverse drug reactions (ADRs) by cross-referencing a patient's unique genomic profile against medications before they are administered.
The core idea: a patient's DNA is the ultimate safety filter. Before any drug enters their treatment plan, the system checks whether their genetic variant is compatible with that drug's metabolic pathway. If not — the system blocks it.


TECH STACK:
Primary Database - MySQL 8.0 
DB Client - MySQL Workbench 
Python Environment - Google Colab 
Lightweight DB - SQLite (Colab replica) 
REST API - Flask 
API Tunnelling - ngrok 
Python Libraries - sqlite3, tabulate, flask, pyngrok 

FEATURES:
Database
- 9 normalized tables (3NF) with 1,200 auto-generated safety validations
- 3 stored functions — age derivation, safety scoring, genomic compatibility
- 2 stored procedures — clinical log entry with ACID transactions, safety matrix regeneration
- 1 cursor — patient drug risk and side effect report
- 4 triggers — date validation, safety gatekeeper (blocks at-risk patients)
- 13 views — compatibility reports, risk analysis, workload summaries
- 13 strategic indexes for optimized clinical queries
- Custom exception — `GENOMIC_DATA_MISSING` (SQLSTATE 45001)

Python — Level 2 (Menu CLI)
- Interactive menu covering all 6 DB components
- Live function, procedure, cursor and trigger demos
- 10 view reports and 7 analytical queries
- SQLite replica with Python-generated 1,200 validation records

Python — Level 3 (REST API)
- 19 Flask endpoints (GET + POST)
- Public URL via ngrok tunnel
- JSON responses for all patient, doctor, medication and safety data
- Full exception handling mapped to HTTP status codes

Medical Safety Engine
- 17 CPIC-aligned genomic compatibility rules
- Automated Safe / Caution / Blocked classification per patient-drug pair
- Dosage recommendations derived from genomic variant
- Clinical log gatekeeper — no treatment logged for genomically at-risk patients
