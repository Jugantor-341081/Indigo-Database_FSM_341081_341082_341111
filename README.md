Jugantor Boruah 341081
Archit Chauhan 341082
Uddipan Bora 341111


DBMS Report
1. Introduction
Airlines operate some of the most complex transactional systems in the world. From managing thousands of flights daily to ensuring timely passenger check-ins, baggage handling, crew assignments, and maintenance tracking—every component must work together seamlessly.
This project builds a fully functional relational database that models the central operational and commercial activities of a modern airline such as IndiGo.
The system is implemented using MySQL 8 / InnoDB , leveraging relational modelling, constraints, and indexing to ensure high data integrity, accuracy, and scalability. The goal is to create a realistic operational environment that demonstrates both technical and analytical capabilities in database design.

2. Objectives of the Project
2.1 Functional Objectives
The database aims to capture all core elements of airline operations:
•	Create and manage airports, routes, aircraft types, and flight templates.
•	Schedule flights daily with assigned aircraft and capacities.
•	Register passengers and maintain personal travel profiles.
•	Record bookings (PNR) and generate multiple tickets under each booking.
•	Manage baggage check-in, tagging, and tracking.
•	Assign pilots, cabin crew, and ground staff to each scheduled flight.
•	Log preventive and corrective maintenance for each aircraft.
2.2 Data Integrity Objectives
To maintain accuracy across millions of records, the database enforces:
•	Primary keys for uniqueness
•	Foreign keys for referential integrity
•	Unique constraints for business rules (e.g., Flight number, Airport code, PNR code)
•	Check constraints to avoid invalid data (e.g., origin ≠ destination)
•	Cascading rules for dependent deletions

2.3 Analytical Objectives
The airline industry depends heavily on operational analytics. This database supports:
•	Load factor calculation
•	Passenger manifests
•	Fare mix analysis
•	Revenue tracking by route
•	Fleet maintenance planning
These reports help simulate how real airline operations depend on timely data insights.
2.4 Scalability Objectives
Airlines handle huge volumes of data, especially in bookings and tickets. To accommodate this:
•	Indexes target high-frequency query fields (dates, statuses, foreign keys).
•	Conditional creation of indexes ensures scripts can run multiple times.
•	Table structures support future partitioning for massive datasets.

3. Technology Stack
Component	Choice	Explanation
DBMS	MySQL 8 (InnoDB)	ACID compliance, foreign keys, row-level locking
Schema Name	airline_db	Logical separation of project
Design Approach	Normalized Relational Model	Ensures consistency, reduces redundancy
Tools Used	MySQL Workbench ERD, SQL Scripts	For modelling, implementation, and testing

4. Conceptual System Design
The airline system is divided into three major domains:
4.1 Operational Domain
Deals with physical assets and core flight structures:
•	Airports
•	Routes
•	Aircraft & aircraft types
•	Flights
•	Flight schedules
•	Crew & roles
4.2 Commercial Domain
Captures the customer-facing processes:
•	Passengers
•	Bookings (PNR)
•	Tickets
•	Fare classes
•	Baggage
4.3 Support Domain
Ensures backend operations run smoothly:
•	Departments & employees
•	Maintenance records
•	Audit logs
This modular separation ensures clarity in workflow and scalability in real-world airline systems.

5. Detailed Schema Overview
5.1 Master Data Tables
These tables rarely change and define the operational structure.
Airports
Stores IATA/ICAO code, city, country, timezone, elevation, and hub status.
Aircraft Types
Defines characteristics such as:
•	Model name (A320, A321, B789)
•	Range
•	Seating capacity
•	Fuel burn details
Aircraft
Each aircraft receives a unique registration number and stores:
•	Total flight hours
•	Cycles
•	Next maintenance due date
Departments & Employees
Used for:
•	Crew assignment
•	Maintenance technicians
•	Ground operations
Crew Roles & Crew
Defines job roles like Captain, First Officer, Flight Engineer, Cabin Crew, and links employees to their operational certifications.

5.2 Operational Workflow Tables
Routes
Represents pairs of airports (origin → destination), with:
•	Flight distance
•	Estimated flight duration
A check constraint ensures origin and destination are not the same.
Flights
Each route may have multiple flight numbers (e.g., 6E101, 6E102).
These are templates used for:
•	Pricing
•	Scheduling
•	Aircraft assignment
Flight Schedules
This is the heart of airline operations, representing each individual dated flight.
Includes:
•	Flight number
•	Flight date
•	Planned and actual departure/arrival
•	Status: Scheduled, Delayed, Departed, Cancelled
•	Available seats
This table can grow into millions of rows as an airline expands.

5.3 Passenger & Booking System
Passengers
Stores permanent identity and personal information including passport details.
Bookings (PNR)
Each booking has:
•	Unique PNR code
•	Total fare
•	Payment method
•	Special service requests
A booking may contain:
•	One or multiple passengers
•	One or multiple flights
Tickets
Each ticket:
•	Ties a passenger & booking to a single flight
•	Stores fare class, seat number, pricing, discount
•	Tracks status: Issued, Checked-in, Boarded, Cancelled
Baggage
Tracks:
•	Baggage tag number
•	Weight
•	Status: Checked-in, Loaded, Unloaded, Delivered
This table supports lost and delayed baggage queries.

5.4 Crew Assignments
Each scheduled flight requires:
•	Minimum 2 pilots
•	Cabin crew
•	Engineers (sometimes)
This table logs:
•	Crew member
•	Assigned flight
•	Role on that flight

5.5 Maintenance Records
Stores maintenance tasks with:
•	Type: Routine Check / A-Check / Engine Inspection
•	Technician name
•	Cost
•	Parts replaced
•	Status
Helps avoid aircraft operating with overdue maintenance.

5.6 Audit Log System
Captures:
•	Table name
•	Operation (INSERT/UPDATE/DELETE)
•	Old values (JSON)
•	New values (JSON)
•	Timestamp
•	Employee performing the change
Useful for compliance, troubleshooting, and tracking data changes.

6. Constraints, Integrity Rules & Relationships
6.1 Primary Keys
Every table uses an integer auto-increment primary key.
6.2 Unique Fields
Ensures data correctness, such as:
•	Flight number
•	Aircraft registration
•	Airport code
•	Passport number
•	Baggage tag number
6.3 Foreign Keys
Strictly enforce relational links between tables.
6.4 Cascading Deletes
Booking → Tickets → Baggage
If a booking is deleted, all related records are removed automatically.
6.5 Check Constraints
Prevents creation of invalid route data and ensures status values remain consistent.

7. Indexing and Performance Optimization
Airlines generate huge volumes of data. To ensure fast response times, indexes are applied on:
7.1 Date-Based Fields
•	flight_schedules.flight_date
•	bookings.booking_date
7.2 Frequent Lookup Fields
•	PNR
•	Ticket status
•	Passport number
•	Crew role
•	Aircraft registration
7.3 Composite Indexes
Examples:
•	(flight_schedule_id, seat_number)
•	(flight_date, status)
These significantly reduce query time for operational reports.
7.4 Conditional Indexing
Indexed only if missing—ideal for repeated development cycles.

8. Sample Data Generation
To ensure realistic simulation:
•	10 airports were inserted.
•	Multiple aircraft across Airbus, Boeing, and Embraer fleets were created.
•	Flight templates, routes, and scheduled flights for multiple dates were prepared.
•	10 passengers with different nationalities were added.
•	PNRs and tickets were issued for multiple flights.
•	Crew members like Captain, First Officer, and Cabin Crew were assigned to flights.
•	Maintenance logs were created for upcoming A-checks.
INSERT IGNORE ensures the sample data script can run repeatedly without duplication errors.

9. Operational and Analytical Reports
9.1 Daily Flight Manifest
Shows:
•	Flight number
•	Route
•	Departure time
•	Passenger list
•	Fare class mix
•	Load factor
Used by airport ground staff.

9.2 Load Factor and Revenue Tracking
Helps:
•	Revenue management team
•	Network planning team
Outputs include:
•	Seats booked vs. total capacity
•	Load factor (%)
•	Total revenue per flight
•	Average fare

9.3 Aircraft Maintenance Due Report
Supports maintenance planners by showing:
•	Aircraft registration
•	Manufacture year
•	Hours flown
•	Days remaining until next maintenance
•	Overdue warnings

9.4 Monthly Revenue per Route
Provides:
•	Number of flights on each route
•	Total passengers
•	Total revenue
•	Average load factor
Helps identify:
•	High-performing sectors
•	Routes needing capacity reduction
•	Seasonal fluctuations

10. Scalability, Reliability & Future Enhancements
10.1 Partitioning
Tables like flight_schedules, tickets, and bookings can be partitioned by month or year.
10.2 Views & Materialized Views
Precomputed summaries can speed up dashboards.
10.3 Trigger-Based Auditing
Automating audit_log entries per insert/update/delete.
10.4 Integration with Front-End
The database can be used as the backend for:
•	Airline booking systems
•	Mobile apps
•	Airport operational dashboards
10.5 AI & Predictive Analysis
Future additions may include:
•	Predictive maintenance
•	Fare forecasting
•	Crew fatigue analysis
•	Passenger behaviour modelling

11. Conclusion
This project successfully demonstrates how to design a robust, scalable, and realistic airline operations database. The system closely resembles real-world architectures used by commercial airlines, while also providing room for analytical reporting and operational automation.
The project effectively combines:
•	Strong relational modelling
•	Integrity constraints
•	Scalable indexing
•	Realistic datasets
•	Practical SQL reporting queries
It serves as a comprehensive DBMS coursework project and lays the foundation for more advanced features such as web integration, predictive analytics, and real-time dashboards.

![WhatsApp Image 2025-12-03 at 23 05 45_56f74e37](https://github.com/user-attachments/assets/72c12b5d-357d-4759-92be-9405e61cb649)
