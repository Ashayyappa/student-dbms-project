-- ====================================================================
-- EDU-TRACK DBMS SEED DATA
-- Comprehensive sample dataset for University Management System
-- ====================================================================

-- 1. Insert Departments
INSERT INTO departments (dept_id, dept_code, dept_name, building, budget) VALUES
(1, 'CS', 'Computer Science & Engineering', 'Turing Hall', 1250000.00),
(2, 'EE', 'Electrical & Electronics Engineering', 'Tesla Complex', 980000.00),
(3, 'ME', 'Mechanical Engineering', 'Newton Center', 850000.00),
(4, 'DS', 'Data Science & Artificial Intelligence', 'Ada Lovelace Building', 1450000.00),
(5, 'BA', 'School of Business & Analytics', 'Adam Smith Wing', 1100000.00);

-- 2. Insert Instructors
INSERT INTO instructors (instructor_id, first_name, last_name, email, phone, salary, hire_date, dept_id) VALUES
(1, 'Alan', 'Turing', 'a.turing@university.edu', '+1-555-0101', 95000.00, '2018-08-15', 1),
(2, 'Grace', 'Hopper', 'g.hopper@university.edu', '+1-555-0102', 98000.00, '2017-01-10', 1),
(3, 'Nikola', 'Tesla', 'n.tesla@university.edu', '+1-555-0103', 92000.00, '2019-03-20', 2),
(4, 'Claude', 'Shannon', 'c.shannon@university.edu', '+1-555-0104', 94000.00, '2020-07-01', 2),
(5, 'Isaac', 'Newton', 'i.newton@university.edu', '+1-555-0105', 89000.00, '2016-09-01', 3),
(6, 'Geoffrey', 'Hinton', 'g.hinton@university.edu', '+1-555-0106', 105000.00, '2021-02-15', 4),
(7, 'Fei-Fei', 'Li', 'ff.li@university.edu', '+1-555-0107', 102000.00, '2021-08-10', 4),
(8, 'Michael', 'Porter', 'm.porter@university.edu', '+1-555-0108', 91000.00, '2019-11-05', 5);

-- 3. Insert Courses
INSERT INTO courses (course_id, course_code, course_title, credits, dept_id, instructor_id, max_capacity, semester_offered) VALUES
(1, 'CS101', 'Introduction to Database Systems', 4, 1, 1, 45, 'Fall'),
(2, 'CS202', 'Data Structures & Algorithms', 4, 1, 2, 40, 'Spring'),
(3, 'CS305', 'Operating Systems & Architecture', 3, 1, 1, 35, 'Fall'),
(4, 'EE201', 'Digital Logic & Circuit Design', 4, 2, 3, 30, 'Fall'),
(5, 'EE304', 'Signals and Systems', 3, 2, 4, 30, 'Spring'),
(6, 'ME101', 'Engineering Thermodynamics', 3, 3, 5, 40, 'Fall'),
(7, 'DS201', 'Applied Machine Learning & Deep Learning', 4, 4, 6, 50, 'Fall'),
(8, 'DS302', 'Big Data Engineering & Cloud Data Warehouses', 4, 4, 7, 40, 'Spring'),
(9, 'BA101', 'Financial Accounting & Management', 3, 5, 8, 50, 'Fall'),
(10, 'BA202', 'Strategic Marketing & Business Intelligence', 3, 5, 8, 45, 'Spring');

-- 4. Insert Students
INSERT INTO students (student_id, roll_number, first_name, last_name, email, phone, dob, gender, enrollment_date, gpa, dept_id, status) VALUES
(1, 'STU2023001', 'Alex', 'Johnson', 'alex.j@student.edu', '+1-555-1001', '2003-04-12', 'Male', '2023-08-20', 3.85, 1, 'Active'),
(2, 'STU2023002', 'Sophia', 'Martinez', 'sophia.m@student.edu', '+1-555-1002', '2004-01-25', 'Female', '2023-08-20', 3.92, 1, 'Active'),
(3, 'STU2023003', 'Liam', 'Chen', 'liam.c@student.edu', '+1-555-1003', '2003-09-18', 'Male', '2023-08-20', 3.65, 4, 'Active'),
(4, 'STU2023004', 'Emma', 'Watson', 'emma.w@student.edu', '+1-555-1004', '2003-11-05', 'Female', '2023-08-20', 3.78, 4, 'Active'),
(5, 'STU2023005', 'Noah', 'Williams', 'noah.w@student.edu', '+1-555-1005', '2002-06-30', 'Male', '2022-08-20', 3.45, 2, 'Active'),
(6, 'STU2023006', 'Olivia', 'Davis', 'olivia.d@student.edu', '+1-555-1006', '2003-03-14', 'Female', '2023-08-20', 3.90, 2, 'Active'),
(7, 'STU2023007', 'Ethan', 'Miller', 'ethan.m@student.edu', '+1-555-1007', '2002-12-08', 'Male', '2022-08-20', 3.20, 3, 'Active'),
(8, 'STU2023008', 'Ava', 'Wilson', 'ava.w@student.edu', '+1-555-1008', '2004-05-22', 'Female', '2023-08-20', 3.70, 3, 'Active'),
(9, 'STU2023009', 'Lucas', 'Taylor', 'lucas.t@student.edu', '+1-555-1009', '2003-08-19', 'Male', '2023-08-20', 3.55, 5, 'Active'),
(10, 'STU2023010', 'Mia', 'Anderson', 'mia.a@student.edu', '+1-555-1010', '2004-02-17', 'Female', '2023-08-20', 3.88, 5, 'Active'),
(11, 'STU2023011', 'Benjamin', 'Thomas', 'ben.t@student.edu', '+1-555-1011', '2003-10-02', 'Male', '2023-08-20', 3.40, 1, 'Active'),
(12, 'STU2023012', 'Chloe', 'Jackson', 'chloe.j@student.edu', '+1-555-1012', '2004-07-11', 'Female', '2023-08-20', 3.95, 4, 'Active');

-- 5. Insert Enrollments
INSERT INTO enrollments (enrollment_id, student_id, course_id, semester, academic_year, grade, numeric_grade, status) VALUES
(1, 1, 1, 'Fall', 2023, 'A', 94.0, 'Completed'),
(2, 1, 2, 'Spring', 2024, 'A+', 98.0, 'Completed'),
(3, 1, 3, 'Fall', 2024, 'B+', 88.0, 'Completed'),
(4, 2, 1, 'Fall', 2023, 'A+', 99.0, 'Completed'),
(5, 2, 2, 'Spring', 2024, 'A', 95.0, 'Completed'),
(6, 2, 7, 'Fall', 2024, 'A', 93.0, 'Completed'),
(7, 3, 7, 'Fall', 2023, 'A', 92.0, 'Completed'),
(8, 3, 8, 'Spring', 2024, 'B+', 87.0, 'Completed'),
(9, 3, 1, 'Fall', 2024, 'B', 83.0, 'Completed'),
(10, 4, 7, 'Fall', 2023, 'A', 95.0, 'Completed'),
(11, 4, 8, 'Spring', 2024, 'A', 94.0, 'Completed'),
(12, 5, 4, 'Fall', 2023, 'B', 82.0, 'Completed'),
(13, 5, 5, 'Spring', 2024, 'B+', 86.0, 'Completed'),
(14, 6, 4, 'Fall', 2023, 'A+', 97.0, 'Completed'),
(15, 6, 5, 'Spring', 2024, 'A', 93.0, 'Completed'),
(16, 7, 6, 'Fall', 2023, 'B', 80.0, 'Completed'),
(17, 8, 6, 'Fall', 2023, 'A', 91.0, 'Completed'),
(18, 9, 9, 'Fall', 2023, 'B+', 88.0, 'Completed'),
(19, 9, 10, 'Spring', 2024, 'B', 84.0, 'Completed'),
(20, 10, 9, 'Fall', 2023, 'A+', 98.0, 'Completed'),
(21, 10, 10, 'Spring', 2024, 'A', 94.0, 'Completed'),
(22, 11, 1, 'Fall', 2024, NULL, NULL, 'Enrolled'),
(23, 12, 7, 'Fall', 2024, 'A+', 99.0, 'Completed'),
(24, 12, 1, 'Fall', 2024, NULL, NULL, 'Enrolled');

-- 6. Insert Sample Audit Logs
INSERT INTO audit_logs (table_name, action_type, record_id, description, logged_at) VALUES
('system', 'INIT', 0, 'Database initialised with core university schema', '2023-08-01 09:00:00'),
('departments', 'INSERT', 1, 'Added Computer Science & Engineering department', '2023-08-01 09:10:00'),
('departments', 'INSERT', 2, 'Added Electrical & Electronics Engineering department', '2023-08-01 09:15:00'),
('courses', 'INSERT', 1, 'New course introduced: CS101 - Introduction to Database Systems', '2023-08-05 10:00:00'),
('students', 'INSERT', 1, 'Registered student: Alex Johnson (STU2023001)', '2023-08-20 11:30:00'),
('enrollments', 'UPDATE_GRADE', 1, 'Updated grade for enrollment #1 to A', '2023-12-15 14:20:00');
