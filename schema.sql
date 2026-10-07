-- ====================================================================
-- EDU-TRACK UNIVERSITY DBMS SCHEMA
-- Normalized to 3NF with Primary Keys, Foreign Keys, Indexes, Triggers & Views
-- ====================================================================

PRAGMA foreign_keys = ON;

-- 1. DEPARTMENTS TABLE
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS instructors;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY AUTOINCREMENT,
    dept_code VARCHAR(10) UNIQUE NOT NULL,
    dept_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    budget DECIMAL(12, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. INSTRUCTORS TABLE
CREATE TABLE instructors (
    instructor_id INTEGER PRIMARY KEY AUTOINCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    salary DECIMAL(10, 2) CHECK(salary >= 0),
    hire_date DATE NOT NULL,
    dept_id INTEGER NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 3. STUDENTS TABLE
CREATE TABLE students (
    student_id INTEGER PRIMARY KEY AUTOINCREMENT,
    roll_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    dob DATE,
    gender VARCHAR(10) CHECK(gender IN ('Male', 'Female', 'Other')),
    enrollment_date DATE DEFAULT (DATE('now')),
    gpa DECIMAL(3, 2) DEFAULT 0.00 CHECK(gpa >= 0.00 AND gpa <= 4.00),
    dept_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'Active' CHECK(status IN ('Active', 'Suspended', 'Graduated', 'Withdrawn')),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 4. COURSES TABLE
CREATE TABLE courses (
    course_id INTEGER PRIMARY KEY AUTOINCREMENT,
    course_code VARCHAR(15) UNIQUE NOT NULL,
    course_title VARCHAR(150) NOT NULL,
    credits INTEGER NOT NULL CHECK(credits > 0 AND credits <= 6),
    dept_id INTEGER NOT NULL,
    instructor_id INTEGER,
    max_capacity INTEGER DEFAULT 40 CHECK(max_capacity > 0),
    semester_offered VARCHAR(20) DEFAULT 'Fall',
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- 5. ENROLLMENTS TABLE (Associative Entity / Junction Table)
CREATE TABLE enrollments (
    enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    student_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    semester VARCHAR(20) NOT NULL,
    academic_year INTEGER NOT NULL,
    grade VARCHAR(2) CHECK(grade IN ('A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F', 'IP', NULL)),
    numeric_grade DECIMAL(4, 2),
    status VARCHAR(20) DEFAULT 'Enrolled' CHECK(status IN ('Enrolled', 'Completed', 'Dropped')),
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, course_id, semester, academic_year),
    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 6. AUDIT LOGS TABLE (To demonstrate DBMS Triggers & Automated Logging)
CREATE TABLE audit_logs (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name VARCHAR(50) NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    record_id INTEGER,
    description TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================
-- PERFORMANCE INDEXES
-- ====================================================================
CREATE INDEX idx_students_dept ON students(dept_id);
CREATE INDEX idx_students_roll ON students(roll_number);
CREATE INDEX idx_courses_dept ON courses(dept_id);
CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_grade ON enrollments(grade);

-- ====================================================================
-- DBMS VIEWS
-- ====================================================================

-- View 1: Detailed Student Enrollment and Grade Report (Multi-Table JOIN)
DROP VIEW IF EXISTS v_student_transcript;
CREATE VIEW v_student_transcript AS
SELECT 
    s.student_id,
    s.roll_number,
    s.first_name || ' ' || s.last_name AS student_name,
    s.email AS student_email,
    d.dept_name,
    c.course_code,
    c.course_title,
    c.credits,
    i.first_name || ' ' || i.last_name AS instructor_name,
    e.semester,
    e.academic_year,
    e.grade,
    e.numeric_grade,
    e.status AS enrollment_status
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id
JOIN departments d ON s.dept_id = d.dept_id
LEFT JOIN instructors i ON c.instructor_id = i.instructor_id;

-- View 2: Department Summary (Aggregate Functions & Group By)
DROP VIEW IF EXISTS v_department_summary;
CREATE VIEW v_department_summary AS
SELECT 
    d.dept_id,
    d.dept_code,
    d.dept_name,
    d.building,
    d.budget,
    COUNT(DISTINCT s.student_id) AS total_students,
    COUNT(DISTINCT c.course_id) AS total_courses,
    COUNT(DISTINCT i.instructor_id) AS total_instructors,
    ROUND(AVG(s.gpa), 2) AS avg_student_gpa
FROM departments d
LEFT JOIN students s ON d.dept_id = s.dept_id
LEFT JOIN courses c ON d.dept_id = c.dept_id
LEFT JOIN instructors i ON d.dept_id = i.dept_id
GROUP BY d.dept_id, d.dept_code, d.dept_name, d.building, d.budget;

-- View 3: Course Analytics View
DROP VIEW IF EXISTS v_course_stats;
CREATE VIEW v_course_stats AS
SELECT 
    c.course_id,
    c.course_code,
    c.course_title,
    c.credits,
    d.dept_name,
    i.first_name || ' ' || i.last_name AS instructor_name,
    c.max_capacity,
    COUNT(e.enrollment_id) AS current_enrollment,
    ROUND(AVG(e.numeric_grade), 2) AS avg_grade_score
FROM courses c
JOIN departments d ON c.dept_id = d.dept_id
LEFT JOIN instructors i ON c.instructor_id = i.instructor_id
LEFT JOIN enrollments e ON c.course_id = e.course_id AND e.status != 'Dropped'
GROUP BY c.course_id, c.course_code, c.course_title, c.credits, d.dept_name, i.first_name, i.last_name, c.max_capacity;

-- ====================================================================
-- DBMS TRIGGERS
-- ====================================================================

-- Trigger 1: Auto-log new student registration
DROP TRIGGER IF EXISTS trg_after_student_insert;
CREATE TRIGGER trg_after_student_insert
AFTER INSERT ON students
BEGIN
    INSERT INTO audit_logs (table_name, action_type, record_id, description)
    VALUES (
        'students', 
        'INSERT', 
        NEW.student_id, 
        'Registered student: ' || NEW.first_name || ' ' || NEW.last_name || ' (' || NEW.roll_number || ')'
    );
END;

-- Trigger 2: Auto-log course creation
DROP TRIGGER IF EXISTS trg_after_course_insert;
CREATE TRIGGER trg_after_course_insert
AFTER INSERT ON courses
BEGIN
    INSERT INTO audit_logs (table_name, action_type, record_id, description)
    VALUES (
        'courses', 
        'INSERT', 
        NEW.course_id, 
        'New course introduced: ' || NEW.course_code || ' - ' || NEW.course_title
    );
END;

-- Trigger 3: Auto-calculate and update student GPA when grade is assigned/updated
DROP TRIGGER IF EXISTS trg_after_enrollment_grade_update;
CREATE TRIGGER trg_after_enrollment_grade_update
AFTER UPDATE OF grade, numeric_grade, status ON enrollments
BEGIN
    UPDATE students
    SET gpa = COALESCE((
        SELECT ROUND(
            SUM(
                CASE 
                    WHEN e.grade = 'A+' THEN 4.0 * c.credits
                    WHEN e.grade = 'A'  THEN 3.75 * c.credits
                    WHEN e.grade = 'B+' THEN 3.3 * c.credits
                    WHEN e.grade = 'B'  THEN 3.0 * c.credits
                    WHEN e.grade = 'C+' THEN 2.5 * c.credits
                    WHEN e.grade = 'C'  THEN 2.0 * c.credits
                    WHEN e.grade = 'D'  THEN 1.0 * c.credits
                    ELSE 0.0
                END
            ) / NULLIF(SUM(CASE WHEN e.grade IS NOT NULL AND e.grade != 'IP' THEN c.credits ELSE 0 END), 0),
            2
        )
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        WHERE e.student_id = NEW.student_id AND e.status = 'Completed' AND e.grade IS NOT NULL
    ), 0.00)
    WHERE student_id = NEW.student_id;

    INSERT INTO audit_logs (table_name, action_type, record_id, description)
    VALUES (
        'enrollments', 
        'UPDATE_GRADE', 
        NEW.enrollment_id, 
        'Updated grade for enrollment #' || NEW.enrollment_id || ' to ' || COALESCE(NEW.grade, 'N/A')
    );
END;
