from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import StudyMaterial, TimetableEntry
from .serializers import StudyMaterialSerializer, TimetableSerializer


@api_view(["GET"])
def timetable_by_class(request, class_id):
	entries = TimetableEntry.objects.filter(class_section_id=class_id)
	serializer = TimetableSerializer(entries, many=True)
	return Response(serializer.data)


@api_view(["GET"])
def study_materials(request):
	data = StudyMaterial.objects.all().order_by("-uploaded_at")
	serializer = StudyMaterialSerializer(data, many=True)
	return Response(serializer.data)
