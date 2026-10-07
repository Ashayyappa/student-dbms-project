/**
 * EduTrack DBMS Client-side Application Logic
 */

document.addEventListener('DOMContentLoaded', () => {
    initModals();
    initSqlConsole();
    initGradeUpdaters();
});

// ----------------- Modal Handling -----------------
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.add('active');
        document.body.style.overflow = 'hidden';
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('active');
        document.body.style.overflow = 'auto';
    }
}

function initModals() {
    // Close modal on background click
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                overlay.classList.remove('active');
                document.body.style.overflow = 'auto';
            }
        });
    });

    // Close on Escape key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            document.querySelectorAll('.modal-overlay.active').forEach(m => {
                m.classList.remove('active');
            });
            document.body.style.overflow = 'auto';
        }
    });
}

// ----------------- Student Transcript Drawer / Modal -----------------
async function viewStudentTranscript(studentId) {
    try {
        const res = await fetch(`/api/students/${studentId}`);
        if (!res.ok) throw new Error('Could not fetch student details');
        const s = await res.json();

        document.getElementById('transcriptStudentName').innerText = `${s.first_name} ${s.last_name}`;
        document.getElementById('transcriptRollNumber').innerText = s.roll_number;
        document.getElementById('transcriptDept').innerText = s.dept_name;
        document.getElementById('transcriptEmail').innerText = s.email;
        document.getElementById('transcriptGPA').innerText = s.gpa ? parseFloat(s.gpa).toFixed(2) : '0.00';
        document.getElementById('transcriptStatus').innerText = s.status;

        const tableBody = document.getElementById('transcriptEnrollmentsBody');
        tableBody.innerHTML = '';

        if (!s.enrollments || s.enrollments.length === 0) {
            tableBody.innerHTML = `<tr><td colspan="6" style="text-align:center; color:var(--text-muted); padding:20px;">No courses enrolled yet.</td></tr>`;
        } else {
            s.enrollments.forEach(e => {
                const gradeBadge = e.grade ? `<span class="badge badge-success">${e.grade}</span>` : `<span class="badge badge-neutral">IP</span>`;
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td><strong>${e.course_code}</strong></td>
                    <td>${e.course_title}</td>
                    <td>${e.credits}</td>
                    <td>${e.instructor_name || 'TBA'}</td>
                    <td>${e.semester} ${e.academic_year}</td>
                    <td>${gradeBadge}</td>
                `;
                tableBody.appendChild(row);
            });
        }

        openModal('studentTranscriptModal');
    } catch (err) {
        alert('Error loading student transcript: ' + err.message);
    }
}

// ----------------- Edit Student Modal -----------------
async function openEditStudentModal(studentId) {
    try {
        const res = await fetch(`/api/students/${studentId}`);
        if (!res.ok) throw new Error('Student data unavailable');
        const s = await res.json();

        document.getElementById('editStudentForm').action = `/api/students/${studentId}`;
        document.getElementById('edit_roll_number').value = s.roll_number;
        document.getElementById('edit_first_name').value = s.first_name;
        document.getElementById('edit_last_name').value = s.last_name;
        document.getElementById('edit_email').value = s.email;
        document.getElementById('edit_phone').value = s.phone || '';
        document.getElementById('edit_dob').value = s.dob || '';
        document.getElementById('edit_gender').value = s.gender || 'Male';
        document.getElementById('edit_dept_id').value = s.dept_id;
        document.getElementById('edit_status').value = s.status || 'Active';

        openModal('editStudentModal');
    } catch (err) {
        alert('Error loading student details: ' + err.message);
    }
}

// ----------------- Interactive Grade Updaters -----------------
function openGradeModal(enrollmentId, currentGrade, currentScore, studentName, courseCode) {
    document.getElementById('gradeEnrollmentId').value = enrollmentId;
    document.getElementById('gradeModalForm').action = `/api/enrollments/${enrollmentId}/grade`;
    document.getElementById('gradeStudentInfo').innerText = `${studentName} - ${courseCode}`;
    document.getElementById('gradeSelect').value = currentGrade || 'A';
    document.getElementById('gradeNumeric').value = currentScore || '90';
    openModal('updateGradeModal');
}

function initGradeUpdaters() {
    // Preset grade score automatic mapping
    const gradeSelect = document.getElementById('gradeSelect');
    const numericInput = document.getElementById('gradeNumeric');
    if (gradeSelect && numericInput) {
        const gradeMap = {
            'A+': 98, 'A': 94, 'B+': 88, 'B': 83, 'C+': 78, 'C': 73, 'D': 65, 'F': 45
        };
        gradeSelect.addEventListener('change', () => {
            const val = gradeSelect.value;
            if (gradeMap[val]) {
                numericInput.value = gradeMap[val];
            }
        });
    }
}

// ----------------- SQL Console Execution -----------------
function initSqlConsole() {
    const runBtn = document.getElementById('runSqlBtn');
    const clearBtn = document.getElementById('clearSqlBtn');
    const sqlTextarea = document.getElementById('sqlQueryInput');

    if (!runBtn || !sqlTextarea) return;

    runBtn.addEventListener('click', () => {
        executeSqlQuery(sqlTextarea.value);
    });

    if (clearBtn) {
        clearBtn.addEventListener('click', () => {
            sqlTextarea.value = '';
            document.getElementById('sqlResultsOutput').innerHTML = `
                <div style="text-align:center; padding: 40px; color: var(--text-muted);">
                    <p>Enter an SQL query above and click <strong>Execute Query</strong>.</p>
                </div>
            `;
            document.getElementById('queryExecTime').innerText = '0.00 ms';
            document.getElementById('queryRowCount').innerText = '0 rows';
        });
    }

    // Ctrl+Enter or Cmd+Enter to run
    sqlTextarea.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
            e.preventDefault();
            executeSqlQuery(sqlTextarea.value);
        }
    });
}

function setSqlPreset(queryText) {
    const sqlTextarea = document.getElementById('sqlQueryInput');
    if (sqlTextarea) {
        sqlTextarea.value = queryText.trim();
        executeSqlQuery(queryText.trim());
    }
}

async function executeSqlQuery(sqlQuery) {
    if (!sqlQuery || !sqlQuery.trim()) {
        alert('Please enter an SQL query first.');
        return;
    }

    const resultsBox = document.getElementById('sqlResultsOutput');
    const timeBadge = document.getElementById('queryExecTime');
    const rowBadge = document.getElementById('queryRowCount');
    const runBtn = document.getElementById('runSqlBtn');

    if (runBtn) {
        runBtn.disabled = true;
        runBtn.innerHTML = 'Executing...';
    }

    resultsBox.innerHTML = `
        <div style="text-align:center; padding: 30px; color: var(--text-secondary);">
            <div style="display:inline-block; animation: spin 1s linear infinite; font-size:24px;">⚙️</div>
            <p style="margin-top:8px;">Running query against SQLite database...</p>
        </div>
    `;

    try {
        const res = await fetch('/api/sql/execute', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ query: sqlQuery })
        });

        const data = await res.json();

        timeBadge.innerText = `${data.execution_time_ms} ms`;
        rowBadge.innerText = `${data.row_count} rows`;

        if (data.error) {
            resultsBox.innerHTML = `
                <div style="padding:16px; background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.3); border-radius: 8px; color: #F87171;">
                    <strong>❌ SQL Execution Error:</strong>
                    <pre style="margin-top:8px; font-family:var(--font-mono); font-size:0.88rem; white-space:pre-wrap;">${data.error}</pre>
                </div>
            `;
            return;
        }

        if (data.columns && data.columns.length > 0) {
            let tableHtml = `
                <div class="table-responsive">
                    <table class="custom-table">
                        <thead>
                            <tr>
                                ${data.columns.map(col => `<th>${col}</th>`).join('')}
                            </tr>
                        </thead>
                        <tbody>
            `;

            if (data.rows.length === 0) {
                tableHtml += `<tr><td colspan="${data.columns.length}" style="text-align:center; color:var(--text-muted);">Query returned 0 rows.</td></tr>`;
            } else {
                data.rows.forEach(row => {
                    tableHtml += `<tr>`;
                    data.columns.forEach(col => {
                        const val = row[col] !== null ? row[col] : '<span style="color:var(--text-muted); font-style:italic;">NULL</span>';
                        tableHtml += `<td>${val}</td>`;
                    });
                    tableHtml += `</tr>`;
                });
            }

            tableHtml += `
                        </tbody>
                    </table>
                </div>
            `;
            resultsBox.innerHTML = tableHtml;
        } else {
            resultsBox.innerHTML = `
                <div style="padding:16px; background: rgba(16, 185, 129, 0.15); border: 1px solid rgba(16, 185, 129, 0.3); border-radius: 8px; color: #34D399;">
                    <strong>✅ ${data.message || 'Statement executed successfully.'}</strong>
                    <p style="margin-top:6px; font-size:0.85rem; color:var(--text-secondary);">Rows affected: ${data.row_count}</p>
                </div>
            `;
        }

    } catch (err) {
        resultsBox.innerHTML = `
            <div style="padding:16px; background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.3); border-radius: 8px; color: #F87171;">
                <strong>Network / System Error:</strong> ${err.message}
            </div>
        `;
    } finally {
        if (runBtn) {
            runBtn.disabled = false;
            runBtn.innerHTML = '⚡ Execute Query (Ctrl+Enter)';
        }
    }
}

// ----------------- Database Quick Reset -----------------
async function resetDatabase() {
    if (!confirm('Are you sure you want to reset and re-seed the entire database to original sample records?')) {
        return;
    }
    try {
        const res = await fetch('/api/db/reset', { method: 'POST' });
        const data = await res.json();
        if (data.success) {
            alert('Database reset & re-seeded successfully!');
            window.location.reload();
        } else {
            alert('Failed to reset database: ' + data.error);
        }
    } catch (e) {
        alert('Network error while resetting database.');
    }
}
