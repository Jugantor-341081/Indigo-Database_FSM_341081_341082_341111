**OVERVIEW**
Project Title: Airline Reservation & Operations Database (IndiGo-style Commercial Airline)
Database: MySQL 8.x
Schema Name: airline_db
Project Overview
This project designs and implements a production-ready relational database for a commercial airline similar to IndiGo. The database supports:
•	Core airline operations (routes, flights, schedules, aircraft, crew)
•	Passenger bookings (PNR), tickets, and baggage tracking
•	Maintenance management for aircraft
•	Operational reporting (load factor, route revenue, upcoming maintenance)
•	Scalability and performance through indexing and good schema design
The implementation is done in MySQL with realistic sample data for Indian airports and routes.
2. Objectives of the Database
The main objectives of this project are:
1.	To model the end-to-end data flow of an airline:
o	From scheduling flights → booking tickets → boarding passengers → handling baggage.
2.	To enforce data integrity and consistency using:
o	Primary keys, foreign keys, unique constraints, and checks.
3.	To support operational analytics, such as:
o	Daily flight manifests
o	Load factor per flight
o	Route-level revenue
o	Upcoming maintenance schedule
4.	To design with scalability in mind, keeping in view:
o	Millions of tickets and bookings per year
o	Indexing and query optimization strategies.
3. Technology and Design Choices
•	DBMS: MySQL 8 (InnoDB engine)
•	Character of data: Operational + transactional + reporting
•	Key design choices:
o	Separate tables for master data (airports, aircraft types, fare classes, crew roles, departments).
o	Separate transactional tables for bookings, tickets, baggage.
o	A flight_schedules table to represent individual flight instances (date-wise operations).
o	Audit logging via audit_log table for traceability.
4. Schema Overview
The schema consists of the following major table categories:
1.	Core Operations / Master Data
o	departments, employees
o	airports
o	aircraft_types, aircraft
o	routes, flights, flight_schedules
o	fare_classes
o	crew_roles, crew, crew_assignments
o	maintenance_records
2.	Transactional Data
o	passengers
o	bookings (PNR)
o	tickets
o	baggage
3.	Operational / System Tables
o	audit_log
4.1 Key Entities and Their Roles
•	DEPARTMENTS & EMPLOYEES
o	departments: Stores functional units like Operations, Maintenance, IT, Crew, etc.
o	employees: All staff with department, designation, hire date, and active status.
o	Relationship: One department employs many employees (fk_employee_department).
•	AIRPORTS
o	airports: Stores IATA/ICAO codes, city, country, timezone, elevation, hub flag.
o	Acts as both origin and destination for routes.
•	AIRCRAFT & TYPES
o	aircraft_types: Defines model (A320, A321, B738, etc.) and capacities.
o	aircraft: Individual aircraft with registration, flight hours, cycles, and maintenance due dates.
o	Relationship: One aircraft type has many physical aircraft.
•	ROUTES, FLIGHTS & SCHEDULES
o	routes: Links origin and destination airports with distance and time.
o	flights: Flight templates (e.g., flight number 6E101) for specific routes and aircraft types.
o	flight_schedules: Actual dated instances of flights with assigned aircraft and capacity.
•	PASSENGERS, BOOKINGS & TICKETS
o	passengers: Personal details of customers.
o	bookings: Passenger Name Record (PNR) storing total fare, payment method, and status.
o	tickets: Line-items linking a booking to specific flight_schedules, fare class, seat, and pricing.
•	BAGGAGE
o	baggage: Tracks checked-in baggage by ticket_id, tag number, weight, type, and status.
•	CREW & ASSIGNMENTS
o	crew_roles: Roles like Captain, First Officer, Flight Attendant.
o	crew: Links an employee to a crew role with license details and flight hours.
o	crew_assignments: Assigns crew to specific scheduled flights with role and active flag.
•	MAINTENANCE
o	maintenance_records: Logs maintenance activities for aircraft: type, dates, technician, cost, and status.
•	AUDIT_LOG
o	audit_log: Generic table to record changes (INSERT/UPDATE/DELETE) on any table with old and new values in JSON, user, and timestamp.
5. Key Constraints and Integrity Rules
1.	Primary Keys:
o	Every table has a primary key (AUTO_INCREMENT unsigned int).
2.	Unique Constraints:
o	departments.department_code
o	employees.employee_code, employees.email
o	airports.iata_code
o	aircraft.registration
o	fare_classes.class_code
o	bookings.pnr_code
o	passengers.passport_number
o	baggage.baggage_tag_number
3.	Foreign Keys:
o	employees.department_id → departments.department_id
o	aircraft.aircraft_type_id → aircraft_types.aircraft_type_id
o	routes.origin_airport_id / destination_airport_id → airports.airport_id
o	flights.route_id → routes.route_id
o	flight_schedules.flight_id → flights.flight_id
o	flight_schedules.aircraft_id → aircraft.aircraft_id
o	bookings.passenger_id → passengers.passenger_id
o	tickets.booking_id → bookings.booking_id (with ON DELETE CASCADE)
o	tickets.flight_schedule_id → flight_schedules.flight_schedule_id
o	tickets.fare_class_id → fare_classes.fare_class_id
o	baggage.ticket_id → tickets.ticket_id (with ON DELETE CASCADE)
o	crew.employee_id → employees.employee_id
o	crew.crew_role_id → crew_roles.crew_role_id
o	crew_assignments.flight_schedule_id → flight_schedules.flight_schedule_id
o	crew_assignments.crew_id → crew.crew_id
o	maintenance_records.aircraft_id → aircraft.aircraft_id
o	maintenance_records.technician_id → employees.employee_id
o	audit_log.user_id → employees.employee_id
4.	Check Constraint:
o	routes ensures origin_airport_id <> destination_airport_id (no self-route).
5.	Cascading Behavior:
o	Deleting a booking automatically deletes its tickets and dependent baggage due to ON DELETE CASCADE on tickets and baggage.
6. Indexing and Performance Design
To support high-volume operations and reporting, multiple indexes are defined:
6.1 Indexes on Master and Transactional Tables
•	Employees
o	idx_employee_department (department_id)
o	idx_employee_active (is_active)
•	Airports
o	idx_airport_city (city)
o	idx_airport_hub (is_hub)
•	Aircraft
o	idx_aircraft_type (aircraft_type_id)
o	idx_aircraft_active (is_active)
o	idx_aircraft_maintenance (next_maintenance_due)
•	Routes
o	idx_route_origin (origin_airport_id)
o	idx_route_destination (destination_airport_id)
•	Flight Schedules
o	idx_flight_schedule_date (flight_date)
o	idx_flight_schedule_aircraft (aircraft_id)
o	idx_flight_schedule_status (status)
o	idx_flight_schedule_departure (scheduled_departure)
•	Passengers
o	idx_passenger_email (email)
o	idx_passenger_passport (passport_number)
•	Bookings
o	idx_booking_pnr (pnr_code)
o	idx_booking_passenger (passenger_id)
o	idx_booking_status (booking_status)
o	idx_booking_date (booking_date)
•	Tickets
o	idx_ticket_booking (booking_id)
o	idx_ticket_flight_schedule (flight_schedule_id)
o	idx_ticket_status (ticket_status)
o	idx_ticket_seat (flight_schedule_id, seat_number)
6.2 Additional “Safe” Indexes
Indexes are created conditionally using information_schema.statistics and dynamic SQL to prevent duplicate index errors:
•	idx_tickets_flight_fare on (flight_schedule_id, fare_class_id)
•	idx_bookings_date_status on (booking_date, booking_status)
•	idx_flight_schedules_date_status on (flight_date, status)
This design ensures the script can be executed multiple times without index-duplicate errors.
7. Sample Data and Scenario
Realistic sample data is inserted for:
•	Departments & Employees: 7 departments and 7 employees including pilots and cabin crew.
•	Airports: Major Indian airports (DEL, BOM, BLR, HYD, CCU, MAA).
•	Aircraft Types & Fleet: Airbus A320/A321, Boeing 737/787, Embraer E190 with capacities and performance data.
•	Routes & Flights:
o	10 routes like DEL–BOM, BOM–BLR, DEL–HYD etc.
o	10 flight templates (e.g., 6E101, 6E201).
•	Flight Schedules: Instances from 27–29 November 2025 with assigned aircraft and capacities.
•	Fare Classes: Economy, Premium Economy, Business, First.
•	Passengers & Bookings: 10 passengers and corresponding PNRs (ABC123–ABC132).
•	Tickets & Baggage: Sample tickets and baggage records for the above flights.
•	Crew & Maintenance: Crew roles, crew members, crew assignments, and maintenance records on aircraft.
INSERT IGNORE is used for sample data to make the script idempotent (can run multiple times without duplicate key errors).
8. Operational Reports and Queries
Four major reports are implemented as SQL queries at the end of the script.
8.1 Report 1 – Daily Flight Manifest (Passengers per Flight)
Purpose:
To get the list of flights for the current day with:
•	Flight number and route
•	Departure time
•	Total passengers booked (non-voided tickets)
•	Available seats
•	Load factor (%)
•	Fare classes booked (Economy, Business, etc.)
Key points:
•	Filters on fs.flight_date = CURRENT_DATE and excludes cancelled/voided flights.
•	Uses GROUP_CONCAT(DISTINCT fc.class_name) to show fare classes for each flight.
•	Helps operations team monitor today’s load and product mix.
8.2 Report 2 – Load Factor per Flight (Capacity Utilization)
Purpose:
To analyse historical load factor and revenue per scheduled flight for the last 7 days.
Outputs:
•	Flight number and route
•	Flight date
•	Aircraft registration and model
•	Total capacity vs. passengers booked
•	Load factor (%)
•	Total revenue and average fare per passenger
Business use:
•	Revenue management and network planning teams can:
o	Identify flights with low load factor for possible promotions or capacity reduction.
o	Identify high load flights for possible frequency/aircraft up-gauging.
8.3 Report 3 – Upcoming Maintenance Due per Aircraft
Purpose:
To support predictive maintenance and ensure aircraft availability.
Outputs:
•	Aircraft registration and model
•	Total flight hours and manufacture year
•	Last maintenance date and next due date
•	Status: OVERDUE, DUE WITHIN WEEK, DUE WITHIN MONTH, or SCHEDULED
•	Days remaining until maintenance (DATEDIFF)
•	Number of flights scheduled in next 7 days
Business use:
•	The maintenance team can:
o	Quickly see which aircraft are approaching checks.
o	Plan maintenance slots without disrupting schedules.
o	Avoid operating aircraft beyond maintenance limits.
8.4 Report 4 – Revenue per Route per Month
Purpose:
To analyse route-level performance in terms of:
•	Flights operated
•	Tickets sold
•	Seat capacity
•	Average load factor
•	Revenue (base fare, tax, discounts)
•	Average fare per ticket
Key technical points:
•	Groups by YEAR(fs.flight_date), MONTH(fs.flight_date) and route.
•	Uses DATE_FORMAT(fs.flight_date, '%Y-%m') AS year_month for reporting.
•	Compatible with ONLY_FULL_GROUP_BY by including this expression in GROUP BY.
Business use:
•	Management can:
o	Identify profitable routes and underperforming routes.
o	Support seasonal analysis and network planning.
o	Decide where to add or cut capacity.

9. Scalability and Future Enhancements
Although the current implementation does not physically partition tables (MySQL partitioning is discussed conceptually), the design already considers:
1.	High row volumes:
o	bookings, tickets, flight_schedules are expected to grow into millions of records.
2.	Indexing strategy:
o	Indexes are placed on frequently filtered and joined columns, especially dates and foreign keys.
3.	Idempotent sample-data loading:
o	Using INSERT IGNORE allows safe re-execution of scripts during development and testing.
4.	Audit logging:
o	audit_log can be extended with triggers on key tables for full traceability.
5.	Possible future improvements:
o	Partition flight_schedules, tickets, and bookings by date (monthly/quarterly).
o	Add materialized views (or summary tables) for daily and monthly performance.
o	Integrate with an application front-end for real-time booking engine and dashboards.

10. Conclusion
This project implements a comprehensive airline database that:
•	Covers core airline operations (aircraft, routes, flights, crew)
•	Manages customer-facing processes (passengers, bookings, tickets, baggage)
•	Provides useful operational and financial reports
•	Enforces strong data integrity via keys and constraints
•	Is designed with scalability and performance in mind
The schema, sample data, and reports together simulate a realistic operational environment for a commercial airline like IndiGo, fulfilling typical DBMS course objectives of modelling, normalization, integrity, indexing, and query design.

<img width="1449" height="832" alt="image" src="https://github.com/user-attachments/assets/b75a9c9a-a597-4efe-9ffd-6b538f8dc746" />
