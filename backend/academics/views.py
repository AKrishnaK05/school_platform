from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Student, Attendance, Marks, ParentStudentLink
from .serializers import AttendanceSerializer, MarksSerializer


@api_view(["GET"])
def parent_students(request, parent_id):
    links = ParentStudentLink.objects.filter(parent_id=parent_id)
    students = [link.student for link in links]

    data = [{"id": s.id, "name": s.full_name} for s in students]
    return Response(data)


@api_view(["GET"])
def student_attendance(request, student_id):
    records = Attendance.objects.filter(student_id=student_id)
    serializer = AttendanceSerializer(records, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def student_marks(request, student_id):
    records = Marks.objects.filter(student_id=student_id)
    serializer = MarksSerializer(records, many=True)
    return Response(serializer.data)

