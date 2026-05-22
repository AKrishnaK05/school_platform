import base64
import os

ROOT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'snitch')
os.makedirs(ROOT, exist_ok=True)

files = [
    'parent_dashboard.png',
    'attendance_tracking.png',
    'communication_center.png',
    'grades_performance.png',
    'student_timetable.png',
]
# 1x1 transparent PNG
b64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII='
data = base64.b64decode(b64)
for f in files:
    path = os.path.join(ROOT, f)
    with open(path, 'wb') as fh:
        fh.write(data)
print('Wrote', len(files), 'placeholder PNGs to', ROOT)
