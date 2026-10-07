import os
import io
import csv
from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, Response, send_file
import database as db

app = Flask(__name__)
app.secret_key = 'edutrack-dbms-secret-key-2024'

# Ensure database exists upon startup
if not os.path.exists(db.DB_PATH):
    print("Database not found. Initializing...")
    db.init_db(force_seed=True)

# ----------------- Web UI Page Routes -----------------

@app.route('/')
def dashboard():
    stats = db.get_dashboard_stats()
    return render_template('index.html', stats=stats)

@app.route('/students')
def students_page():
    search = request.args.get('search', '').strip()
    dept_id = request.args.get('dept_id', type=int)
    students = db.get_all_students(search=search, dept_id=dept_id)
    departments = db.get_all_departments()
    return render_template('students.html', students=students, departments=departments, current_search=search, current_dept=dept_id)

@app.route('/courses')
def courses_page():
    courses = db.get_all_courses()
    departments = db.get_all_departments()
    instructors = db.get_all_instructors()
    return render_template('courses.html', courses=courses, departments=departments, instructors=instructors)

@app.route('/enrollments')
def enrollments_page():
    enrollments = db.get_all_enrollments()
    students = db.get_all_students()
    courses = db.get_all_courses()
    return render_template('enrollments.html', enrollments=enrollments, students=students, courses=courses)

@app.route('/sql-console')
def sql_console():
    return render_template('sql_console.html')

@app.route('/schema-viewer')
def schema_viewer():
    metadata = db.get_schema_metadata()
    return render_template('er_diagram.html', metadata=metadata)

@app.route('/viva-guide')
def viva_guide_page():
    return render_template('viva_prep.html')

# ----------------- Dashboard & Stats API -----------------

@app.route('/api/stats')
def api_stats():
    return jsonify(db.get_dashboard_stats())

# ----------------- Student API & Actions -----------------

@app.route('/api/students', methods=['GET', 'POST'])
def api_students():
    if request.method == 'GET':
        search = request.args.get('search')
        dept_id = request.args.get('dept_id', type=int)
        return jsonify(db.get_all_students(search=search, dept_id=dept_id))
    
    data = request.get_json() or request.form
    res = db.add_student(data)
    if res['success']:
        if request.is_json:
            return jsonify(res), 201
        flash('Student added successfully!', 'success')
        return redirect(url_for('students_page'))
    else:
        if request.is_json:
            return jsonify(res), 400
        flash(f'Error adding student: {res["error"]}', 'danger')
        return redirect(url_for('students_page'))

@app.route('/api/students/<int:student_id>', methods=['GET', 'POST', 'DELETE'])
def api_student_detail(student_id):
    if request.method == 'GET':
        student = db.get_student_by_id(student_id)
        if not student:
            return jsonify({'error': 'Student not found'}), 404
        return jsonify(student)
    
    if request.method == 'DELETE':
        res = db.delete_student(student_id)
        return jsonify(res)
    
    # Handle Update
    data = request.get_json() or request.form
    res = db.update_student(student_id, data)
    if res['success']:
        if request.is_json:
            return jsonify(res)
        flash('Student profile updated successfully!', 'success')
        return redirect(url_for('students_page'))
    else:
        if request.is_json:
            return jsonify(res), 400
        flash(f'Error updating student: {res["error"]}', 'danger')
        return redirect(url_for('students_page'))

@app.route('/students/delete/<int:student_id>', methods=['POST'])
def student_delete_action(student_id):
    res = db.delete_student(student_id)
    if res['success']:
        flash('Student record deleted.', 'info')
    else:
        flash(f'Cannot delete student: {res["error"]}', 'danger')
    return redirect(url_for('students_page'))

# ----------------- Course & Department Actions -----------------

@app.route('/api/courses', methods=['GET', 'POST'])
def api_courses():
    if request.method == 'GET':
        return jsonify(db.get_all_courses())
    data = request.get_json() or request.form
    res = db.add_course(data)
    if res['success']:
        if request.is_json:
            return jsonify(res), 201
        flash('Course created successfully!', 'success')
        return redirect(url_for('courses_page'))
    else:
        if request.is_json:
            return jsonify(res), 400
        flash(f'Error adding course: {res["error"]}', 'danger')
        return redirect(url_for('courses_page'))

@app.route('/api/departments', methods=['GET', 'POST'])
def api_departments():
    if request.method == 'GET':
        return jsonify(db.get_all_departments())
    data = request.get_json() or request.form
    res = db.add_department(data)
    if res['success']:
        if request.is_json:
            return jsonify(res), 201
        flash('Department added successfully!', 'success')
        return redirect(url_for('courses_page'))
    else:
        if request.is_json:
            return jsonify(res), 400
        flash(f'Error adding department: {res["error"]}', 'danger')
        return redirect(url_for('courses_page'))

# ----------------- Enrollment & Grading Actions -----------------

@app.route('/api/enrollments', methods=['GET', 'POST'])
def api_enrollments():
    if request.method == 'GET':
        student_id = request.args.get('student_id', type=int)
        course_id = request.args.get('course_id', type=int)
        return jsonify(db.get_all_enrollments(student_id=student_id, course_id=course_id))
    
    data = request.get_json() or request.form
    res = db.create_enrollment(data)
    if res['success']:
        if request.is_json:
            return jsonify(res), 201
        flash('Student enrolled successfully!', 'success')
        return redirect(url_for('enrollments_page'))
    else:
        if request.is_json:
            return jsonify(res), 400
        flash(f'Enrollment failed: {res["error"]}', 'danger')
        return redirect(url_for('enrollments_page'))

@app.route('/api/enrollments/<int:enrollment_id>/grade', methods=['POST'])
def api_update_grade(enrollment_id):
    data = request.get_json() or request.form
    grade = data.get('grade')
    numeric_grade = data.get('numeric_grade', type=float)
    status = data.get('status', 'Completed')
    res = db.update_enrollment_grade(enrollment_id, grade, numeric_grade, status)
    if res['success']:
        if request.is_json:
            return jsonify(res)
        flash('Grade updated & GPA recalculated automatically by Trigger!', 'success')
        return redirect(url_for('enrollments_page'))
    else:
        if request.is_json:
            return jsonify(res), 400
        flash(f'Failed to update grade: {res["error"]}', 'danger')
        return redirect(url_for('enrollments_page'))

@app.route('/enrollments/delete/<int:enrollment_id>', methods=['POST'])
def enrollment_delete_action(enrollment_id):
    res = db.delete_enrollment(enrollment_id)
    if res['success']:
        flash('Enrollment record removed.', 'info')
    else:
        flash(f'Failed to remove enrollment: {res["error"]}', 'danger')
    return redirect(url_for('enrollments_page'))

# ----------------- Raw SQL Console API -----------------

@app.route('/api/sql/execute', methods=['POST'])
def api_sql_execute():
    data = request.get_json()
    if not data or 'query' not in data:
        return jsonify({'error': 'SQL query string required.'}), 400
    
    query = data['query']
    result = db.execute_raw_sql(query)
    return jsonify(result)

# ----------------- Database Maintenance & Export -----------------

@app.route('/api/db/reset', methods=['POST'])
def api_db_reset():
    try:
        db.init_db(force_seed=True)
        return jsonify({'success': True, 'message': 'Database re-initialized and seeded successfully.'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/db/export/students-csv')
def export_students_csv():
    students = db.get_all_students()
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(['Student ID', 'Roll Number', 'First Name', 'Last Name', 'Email', 'Phone', 'DOB', 'Gender', 'Department', 'GPA', 'Status'])
    for s in students:
        writer.writerow([s['student_id'], s['roll_number'], s['first_name'], s['last_name'], s['email'], s['phone'], s['dob'], s['gender'], s['dept_name'], s['gpa'], s['status']])
    
    output.seek(0)
    return Response(
        output.getvalue(),
        mimetype="text/csv",
        headers={"Content-Disposition": "attachment;filename=students_export.csv"}
    )

if __name__ == '__main__':
    print("\n" + "="*60)
    print(" 🚀 EduTrack DBMS Server Starting...")
    print(" 🌐 Access application at: http://127.0.0.1:5050")
    print("="*60 + "\n")
    app.run(host='0.0.0.0', port=5050, debug=True)
