# Virtual Clinic

A desktop healthcare platform featuring a JavaFX user interface and a robust Oracle Database backend. The application automates patient symptom evaluation, health profiling (pediatric, geriatric, or chronic risk assessment), and smart doctor appointment scheduling via database-level logic.

## Features

- **Dual Dashboards:** Custom FXML-based graphical user interfaces for both Patients and Doctors.
- **Automated Medical Triage:** A specialized PL/SQL engine (`PACHET_TELEMEDICINA`) that processes symptoms, determines provisional complexity, and auto-generates prescriptions for low-risk cases.
- **Smart Appointment Scheduling:** Automatically scans doctor timetables and schedules an appointment within a 7-day window based on the matching medical specialization (e.g., Cardiology, Neurology, Pediatrics).
- **Relational Database Schema:** Comprehensive model handling patient subscriptions, chronic illnesses, symptom catalogs, and automated logs.

## Tech Stack

- **Frontend:** JavaFX, FXML, Custom CSS
- **Backend:** Java
- **Database:** Oracle Database (Express Edition / XE)
- **Database Logic:** PL/SQL (Packages, Stored Procedures, Triggers, Views)
- **Build Tool:** Maven

## Setup & Installation

1. **Database Configuration:**
   - Ensure a local Oracle Database instance is running on port `1521`.
   - Create a schema/user with the username `STUDENT` and password `STUDENT`.
   - Run the SQL scripts in order to set up the tables and populate data:
     1. `01_Populare_Tabele.sql`
     2. `05_Pachet_Body.sql` (and other package scripts).

2. **Run the Application:**
   - Open a terminal in the root directory where `pom.xml` is located.
   - Run the following Maven command to compile and launch the JavaFX application:
     ```bash
     mvn clean javafx:run
     ```
