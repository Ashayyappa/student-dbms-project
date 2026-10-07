import sqlite3
import os
import time
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), 'university.db')
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), 'schema.sql')
SEED_PATH = os.path.join(os.path.dirname(__file__), 'seed_data.sql')

def get_db_connection():
    """Establish connection to SQLite database with foreign keys enabled."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn

def init_db(force_seed=True):
    """Initialize database using schema.sql and seed_data.sql."""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    with open(SCHEMA_PATH, 'r', encoding='utf-8') as f:
        schema_sql = f.read()
    cursor.executescript(schema_sql)
    
    if force_seed and os.path.exists(SEED_PATH):
        with open(SEED_PATH, 'r', encoding='utf-8') as f:
            seed_sql = f.read()
        cursor.executescript(seed_sql)
        
    conn.commit()
    conn.close()
    print("Database initialized successfully.")

def execute_raw_sql(sql_query, params=None):
    """
    Execute any raw SQL query and return:
    - columns list
    - rows list of dicts
    - rows_affected count
    - execution_time in milliseconds
    - error string if any
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    start_time = time.time()
    
    sql_trimmed = sql_query.strip().rstrip(';')
    is_select = sql_trimmed.upper().startswith(('SELECT', 'PRAGMA', 'EXPLAIN', 'WITH'))
    
    result = {
        'columns': [],
        'rows': [],
        'row_count': 0,
        'execution_time_ms': 0.0,
        'query_type': 'SELECT' if is_select else 'DML/DDL',
        'error': None,
        'message': None
    }
    
    try:
        if is_select:
            if params:
                cursor.execute(sql_query, params)
            else:
                cursor.execute(sql_query)
            
            if cursor.description:
                result['columns'] = [col[0] for col in cursor.description]
                rows = cursor.fetchall()
                result['rows'] = [dict(row) for row in rows]
                result['row_count'] = len(rows)
            result['message'] = f"Query executed successfully ({result['row_count']} rows returned)."
        else:
            # DDL or DML (INSERT, UPDATE, DELETE, CREATE, DROP, etc.)
            cursor.executescript(sql_query)
            conn.commit()
            result['row_count'] = cursor.rowcount if cursor.rowcount != -1 else 0
            result['message'] = "SQL statement(s) executed successfully."
            
    except sqlite3.Error as e:
        result['error'] = str(e)
    except Exception as e:
        result['error'] = f"Unexpected error: {str(e)}"
    finally:
        elapsed = (time.time() - start_time) * 1000
        result['execution_time_ms'] = round(elapsed, 2)
        conn.close()
        
    return result

# ----------------- Specialized Operations -----------------

def get_dashboard_stats():
    """Retrieve summarized analytical data for dashboard cards and charts."""
    conn = get_db_connection()
    c = conn.cursor()
    
    c.execute("SELECT COUNT(*) FROM students;")
    total_students = c.fetchone()[0]
    
    c.execute("SELECT COUNT(*) FROM courses;")
    total_courses = c.fetchone()[0]
    
    c.execute("SELECT COUNT(*) FROM enrollments WHERE status = 'Enrolled' OR status = 'Completed';")
    total_enrollments = c.fetchone()[0]
    
    c.execute("SELECT COUNT(*) FROM departments;")
    total_departments = c.fetchone()[0]
    
    c.execute("SELECT ROUND(AVG(gpa), 2) FROM students WHERE gpa > 0;")
    avg_gpa = c.fetchone()[0] or 0.0
    
    c.execute("SELECT COUNT(*) FROM instructors;")
    total_instructors = c.fetchone()[0]
    
    # Department enrollment distribution
    c.execute("""
        SELECT d.dept_name, d.dept_code, COUNT(s.student_id) as student_count
        FROM departments d
        LEFT JOIN students s ON d.dept_id = s.dept_id
        GROUP BY d.dept_id
        ORDER BY student_count DESC;
    """)
    dept_distribution = [dict(row) for row in c.fetchall()]
    
    # Grade distribution
    c.execute("""
        SELECT COALESCE(grade, 'In Progress') as grade, COUNT(*) as count
        FROM enrollments
        GROUP BY grade
        ORDER BY count DESC;
    """)
    grade_distribution = [dict(row) for row in c.fetchall()]
    
    # Top 5 Students
    c.execute("""
        SELECT s.student_id, s.roll_number, s.first_name || ' ' || s.last_name AS name, 
               s.gpa, d.dept_name
        FROM students s
        JOIN departments d ON s.dept_id = d.dept_id
        ORDER BY s.gpa DESC LIMIT 5;
    """)
    top_students = [dict(row) for row in c.fetchall()]
    
    # Recent Audit Logs
    c.execute("""
        SELECT log_id, table_name, action_type, description, logged_at
        FROM audit_logs
        ORDER BY log_id DESC LIMIT 6;
    """)
    recent_logs = [dict(row) for row in c.fetchall()]
    
    conn.close()
    
    return {
        'total_students': total_students,
        'total_courses': total_courses,
        'total_enrollments': total_enrollments,
        'total_departments': total_departments,
        'total_instructors': total_instructors,
        'avg_gpa': avg_gpa,
        'dept_distribution': dept_distribution,
        'grade_distribution': grade_distribution,
        'top_students': top_students,
        'recent_logs': recent_logs
    }

def get_all_students(search=None, dept_id=None):
    conn = get_db_connection()
    c = conn.cursor()
    query = """
        SELECT s.*, d.dept_name, d.dept_code,
               (SELECT COUNT(*) FROM enrollments e WHERE e.student_id = s.student_id) AS course_count
        FROM students s
        JOIN departments d ON s.dept_id = d.dept_id
        WHERE 1=1
    """
    params = []
    if search:
        query += " AND (s.first_name LIKE ? OR s.last_name LIKE ? OR s.roll_number LIKE ? OR s.email LIKE ?)"
        term = f"%{search}%"
        params.extend([term, term, term, term])
    if dept_id:
        query += " AND s.dept_id = ?"
        params.append(dept_id)
        
    query += " ORDER BY s.student_id DESC;"
    c.execute(query, params)
    students = [dict(row) for row in c.fetchall()]
    conn.close()
    return students

def get_student_by_id(student_id):
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("""
        SELECT s.*, d.dept_name, d.dept_code
        FROM students s
        JOIN departments d ON s.dept_id = d.dept_id
        WHERE s.student_id = ?;
    """, (student_id,))
    student = c.fetchone()
    if not student:
        conn.close()
        return None
    
    student_dict = dict(student)
    # Fetch transcript
    c.execute("""
        SELECT e.enrollment_id, c.course_code, c.course_title, c.credits, 
               i.first_name || ' ' || i.last_name AS instructor_name,
               e.semester, e.academic_year, e.grade, e.numeric_grade, e.status
        FROM enrollments e
        JOIN courses c ON e.course_id = c.course_id
        LEFT JOIN instructors i ON c.instructor_id = i.instructor_id
        WHERE e.student_id = ?
        ORDER BY e.academic_year DESC, e.semester DESC;
    """, (student_id,))
    student_dict['enrollments'] = [dict(row) for row in c.fetchall()]
    conn.close()
    return student_dict

def add_student(data):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("""
            INSERT INTO students (roll_number, first_name, last_name, email, phone, dob, gender, enrollment_date, dept_id, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """, (
            data['roll_number'],
            data['first_name'],
            data['last_name'],
            data['email'],
            data.get('phone'),
            data.get('dob'),
            data.get('gender', 'Male'),
            data.get('enrollment_date', datetime.today().strftime('%Y-%m-%d')),
            data['dept_id'],
            data.get('status', 'Active')
        ))
        new_id = c.lastrowid
        conn.commit()
        return {'success': True, 'student_id': new_id}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def update_student(student_id, data):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("""
            UPDATE students 
            SET first_name = ?, last_name = ?, email = ?, phone = ?, dob = ?, gender = ?, dept_id = ?, status = ?
            WHERE student_id = ?;
        """, (
            data['first_name'],
            data['last_name'],
            data['email'],
            data.get('phone'),
            data.get('dob'),
            data.get('gender'),
            data['dept_id'],
            data.get('status', 'Active'),
            student_id
        ))
        conn.commit()
        return {'success': True}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def delete_student(student_id):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("DELETE FROM students WHERE student_id = ?;", (student_id,))
        conn.commit()
        return {'success': True}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def get_all_courses():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("""
        SELECT c.*, d.dept_name, d.dept_code,
               i.first_name || ' ' || i.last_name AS instructor_name,
               (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.course_id AND e.status != 'Dropped') AS enrolled_students
        FROM courses c
        JOIN departments d ON c.dept_id = d.dept_id
        LEFT JOIN instructors i ON c.instructor_id = i.instructor_id
        ORDER BY c.course_id ASC;
    """)
    courses = [dict(row) for row in c.fetchall()]
    conn.close()
    return courses

def add_course(data):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("""
            INSERT INTO courses (course_code, course_title, credits, dept_id, instructor_id, max_capacity, semester_offered)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """, (
            data['course_code'],
            data['course_title'],
            data['credits'],
            data['dept_id'],
            data.get('instructor_id') or None,
            data.get('max_capacity', 40),
            data.get('semester_offered', 'Fall')
        ))
        new_id = c.lastrowid
        conn.commit()
        return {'success': True, 'course_id': new_id}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def get_all_departments():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("""
        SELECT d.*, 
               (SELECT COUNT(*) FROM students s WHERE s.dept_id = d.dept_id) AS student_count,
               (SELECT COUNT(*) FROM courses c WHERE c.dept_id = d.dept_id) AS course_count,
               (SELECT COUNT(*) FROM instructors i WHERE i.dept_id = d.dept_id) AS instructor_count
        FROM departments d
        ORDER BY d.dept_id ASC;
    """)
    depts = [dict(row) for row in c.fetchall()]
    conn.close()
    return depts

def add_department(data):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("""
            INSERT INTO departments (dept_code, dept_name, building, budget)
            VALUES (?, ?, ?, ?);
        """, (
            data['dept_code'],
            data['dept_name'],
            data.get('building'),
            data.get('budget', 0.0)
        ))
        new_id = c.lastrowid
        conn.commit()
        return {'success': True, 'dept_id': new_id}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def get_all_instructors():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("""
        SELECT i.*, d.dept_name, d.dept_code,
               (SELECT COUNT(*) FROM courses c WHERE c.instructor_id = i.instructor_id) AS courses_taught
        FROM instructors i
        JOIN departments d ON i.dept_id = d.dept_id
        ORDER BY i.instructor_id ASC;
    """)
    instructors = [dict(row) for row in c.fetchall()]
    conn.close()
    return instructors

def get_all_enrollments(student_id=None, course_id=None):
    conn = get_db_connection()
    c = conn.cursor()
    query = """
        SELECT e.*, s.roll_number, s.first_name || ' ' || s.last_name AS student_name,
               c.course_code, c.course_title, c.credits, d.dept_code
        FROM enrollments e
        JOIN students s ON e.student_id = s.student_id
        JOIN courses c ON e.course_id = c.course_id
        JOIN departments d ON s.dept_id = d.dept_id
        WHERE 1=1
    """
    params = []
    if student_id:
        query += " AND e.student_id = ?"
        params.append(student_id)
    if course_id:
        query += " AND e.course_id = ?"
        params.append(course_id)
        
    query += " ORDER BY e.enrollment_id DESC;"
    c.execute(query, params)
    enrollments = [dict(row) for row in c.fetchall()]
    conn.close()
    return enrollments

def create_enrollment(data):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("""
            INSERT INTO enrollments (student_id, course_id, semester, academic_year, grade, numeric_grade, status)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """, (
            data['student_id'],
            data['course_id'],
            data.get('semester', 'Fall'),
            data.get('academic_year', 2024),
            data.get('grade'),
            data.get('numeric_grade'),
            data.get('status', 'Enrolled')
        ))
        new_id = c.lastrowid
        conn.commit()
        return {'success': True, 'enrollment_id': new_id}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def update_enrollment_grade(enrollment_id, grade, numeric_grade=None, status='Completed'):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("""
            UPDATE enrollments 
            SET grade = ?, numeric_grade = ?, status = ?
            WHERE enrollment_id = ?;
        """, (grade, numeric_grade, status, enrollment_id))
        conn.commit()
        return {'success': True}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def delete_enrollment(enrollment_id):
    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("DELETE FROM enrollments WHERE enrollment_id = ?;", (enrollment_id,))
        conn.commit()
        return {'success': True}
    except Exception as e:
        conn.rollback()
        return {'success': False, 'error': str(e)}
    finally:
        conn.close()

def get_schema_metadata():
    """Retrieve full database metadata for interactive ER visualizer."""
    conn = get_db_connection()
    c = conn.cursor()
    
    # Get all tables
    c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
    tables = [row[0] for row in c.fetchall()]
    
    schema = {}
    for tbl in tables:
        c.execute(f"PRAGMA table_info({tbl});")
        cols = [dict(row) for row in c.fetchall()]
        
        c.execute(f"PRAGMA foreign_key_list({tbl});")
        fks = [dict(row) for row in c.fetchall()]
        
        c.execute(f"SELECT COUNT(*) FROM {tbl};")
        row_count = c.fetchone()[0]
        
        schema[tbl] = {
            'columns': cols,
            'foreign_keys': fks,
            'row_count': row_count
        }
        
    # Get Views
    c.execute("SELECT name, sql FROM sqlite_master WHERE type='view';")
    views = [dict(row) for row in c.fetchall()]
    
    # Get Triggers
    c.execute("SELECT name, tbl_name, sql FROM sqlite_master WHERE type='trigger';")
    triggers = [dict(row) for row in c.fetchall()]
    
    conn.close()
    return {
        'tables': schema,
        'views': views,
        'triggers': triggers
    }
