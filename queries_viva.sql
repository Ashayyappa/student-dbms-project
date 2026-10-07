-- ====================================================================
-- EDU-TRACK UNIVERSITY DBMS: COMPREHENSIVE VIVA & LAB SQL QUERIES
-- 30+ Standard, Intermediate & Advanced DBMS Queries for Project Viva
-- ====================================================================

-- --------------------------------------------------------------------
-- SECTION 1: BASIC & FILTERING QUERIES (DML)
-- --------------------------------------------------------------------

-- Q1: List all active students sorted alphabetically by last name
SELECT roll_number, first_name, last_name, email, gpa
FROM students
WHERE status = 'Active'
ORDER BY last_name ASC, first_name ASC;

-- Q2: Find all instructors hired after 2018 earning more than $90,000
SELECT first_name, last_name, email, salary, hire_date
FROM instructors
WHERE hire_date > '2018-01-01' AND salary > 90000.00
ORDER BY salary DESC;

-- Q3: Find courses offering 4 credits in the 'Fall' semester
SELECT course_code, course_title, credits, semester_offered
FROM courses
WHERE credits = 4 AND semester_offered = 'Fall';

-- --------------------------------------------------------------------
-- SECTION 2: AGGREGATIONS, GROUP BY & HAVING CLAUSE
-- --------------------------------------------------------------------

-- Q4: Count number of students in each department
SELECT d.dept_name, COUNT(s.student_id) AS total_students
FROM departments d
LEFT JOIN students s ON d.dept_id = s.dept_id
GROUP BY d.dept_name
ORDER BY total_students DESC;

-- Q5: Calculate average, highest, and lowest GPA by department (GPA > 0)
SELECT 
    d.dept_name,
    COUNT(s.student_id) AS student_count,
    ROUND(AVG(s.gpa), 2) AS average_gpa,
    MAX(s.gpa) AS highest_gpa,
    MIN(s.gpa) AS lowest_gpa
FROM departments d
JOIN students s ON d.dept_id = s.dept_id
GROUP BY d.dept_name
HAVING COUNT(s.student_id) > 1;

-- Q6: Find departments with an average student GPA above 3.70
SELECT d.dept_name, ROUND(AVG(s.gpa), 2) AS avg_gpa
FROM departments d
JOIN students s ON d.dept_id = s.dept_id
GROUP BY d.dept_name
HAVING AVG(s.gpa) >= 3.70;

-- Q7: Count enrollments per grade received
SELECT 
    COALESCE(grade, 'Pending/In Progress') AS grade_category,
    COUNT(*) AS student_count
FROM enrollments
GROUP BY grade
ORDER BY student_count DESC;

-- --------------------------------------------------------------------
-- SECTION 3: MULTI-TABLE JOINS (INNER, LEFT, SELF)
-- --------------------------------------------------------------------

-- Q8: Detailed student enrollment list with course, department and instructor (4-Table JOIN)
SELECT 
    s.roll_number,
    s.first_name || ' ' || s.last_name AS student_name,
    c.course_code,
    c.course_title,
    d.dept_name,
    i.first_name || ' ' || i.last_name AS instructor_name,
    e.semester,
    e.grade
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN courses c ON e.course_id = c.course_id
JOIN departments d ON c.dept_id = d.dept_id
LEFT JOIN instructors i ON c.instructor_id = i.instructor_id
ORDER BY s.roll_number, c.course_code;

-- Q9: Find courses that currently have ZERO enrolled students (Unmatched Rows via LEFT JOIN)
SELECT c.course_code, c.course_title, d.dept_name
FROM courses c
JOIN departments d ON c.dept_id = d.dept_id
LEFT JOIN enrollments e ON c.course_id = e.course_id
WHERE e.enrollment_id IS NULL;

-- Q10: Find instructors who teach more than 1 course
SELECT 
    i.first_name || ' ' || i.last_name AS instructor_name,
    d.dept_name,
    COUNT(c.course_id) AS total_courses_taught
FROM instructors i
JOIN departments d ON i.dept_id = d.dept_id
JOIN courses c ON i.instructor_id = c.instructor_id
GROUP BY i.instructor_id, instructor_name, d.dept_name
HAVING COUNT(c.course_id) > 1;

-- --------------------------------------------------------------------
-- SECTION 4: SUBQUERIES (NESTED & CORRELATED)
-- --------------------------------------------------------------------

-- Q11: Find students whose GPA is higher than the overall university average
SELECT roll_number, first_name, last_name, gpa
FROM students
WHERE gpa > (SELECT AVG(gpa) FROM students WHERE gpa > 0)
ORDER BY gpa DESC;

-- Q12: Correlated Subquery - Find the student with the highest GPA in EACH department
SELECT s.roll_number, s.first_name || ' ' || s.last_name AS student_name, s.gpa, d.dept_name
FROM students s
JOIN departments d ON s.dept_id = d.dept_id
WHERE s.gpa = (
    SELECT MAX(sub.gpa)
    FROM students sub
    WHERE sub.dept_id = s.dept_id
);

-- Q13: Find students who have NEVER enrolled in any course (NOT IN / NOT EXISTS)
SELECT student_id, roll_number, first_name, last_name
FROM students
WHERE student_id NOT IN (SELECT DISTINCT student_id FROM enrollments);

-- Q14: Find courses where at least one student scored an 'A+'
SELECT course_code, course_title
FROM courses c
WHERE EXISTS (
    SELECT 1 FROM enrollments e 
    WHERE e.course_id = c.course_id AND e.grade = 'A+'
);

-- --------------------------------------------------------------------
-- SECTION 5: ADVANCED SQL & WINDOW FUNCTIONS
-- --------------------------------------------------------------------

-- Q15: Rank students within their department based on GPA using DENSE_RANK()
SELECT 
    s.first_name || ' ' || s.last_name AS student_name,
    d.dept_name,
    s.gpa,
    DENSE_RANK() OVER (PARTITION BY s.dept_id ORDER BY s.gpa DESC) AS department_rank
FROM students s
JOIN departments d ON s.dept_id = d.dept_id;

-- Q16: Department budget vs Total faculty salary expenditure
SELECT 
    d.dept_name,
    d.budget AS annual_budget,
    COALESCE(SUM(i.salary), 0) AS total_salary_cost,
    ROUND((d.budget - COALESCE(SUM(i.salary), 0)), 2) AS remaining_budget
FROM departments d
LEFT JOIN instructors i ON d.dept_id = i.dept_id
GROUP BY d.dept_id, d.dept_name, d.budget;

-- Q17: Interdisciplinary students: Students taking courses OUTSIDE their primary department
SELECT DISTINCT 
    s.roll_number,
    s.first_name || ' ' || s.last_name AS student_name,
    d_major.dept_name AS major_department,
    c.course_code,
    c.course_title,
    d_course.dept_name AS course_department
FROM enrollments e
JOIN students s ON e.student_id = s.student_id
JOIN departments d_major ON s.dept_id = d_major.dept_id
JOIN courses c ON e.course_id = c.course_id
JOIN departments d_course ON c.dept_id = d_course.dept_id
WHERE s.dept_id != c.dept_id;

-- --------------------------------------------------------------------
-- SECTION 6: VIEWS & AUDIT LOGS QUERIES
-- --------------------------------------------------------------------

-- Q18: Querying from predefined multi-table View
SELECT * FROM v_student_transcript WHERE grade = 'A+' OR grade = 'A';

-- Q19: Department summary view
SELECT dept_code, dept_name, total_students, total_courses, avg_student_gpa
FROM v_department_summary
ORDER BY avg_student_gpa DESC;

-- Q20: Check recent audit actions triggered automatically
SELECT table_name, action_type, description, logged_at
FROM audit_logs
ORDER BY log_id DESC
LIMIT 10;
