from rest_framework.decorators import api_view
from rest_framework.response import Response

from academics.models import Timetable
from .models import StudyMaterial, TimetableEntry
from .serializers import StudyMaterialSerializer, TimetableSerializer


@api_view(["GET"])
def timetable_by_class(request, class_id):
	# Primary source: class-teacher managed timetable entries.
	entries = Timetable.objects.filter(class_section_id=class_id).select_related(
		"subject", "teacher", "class_section"
	)

	if entries.exists():
		day_display_map = dict(Timetable.DAYS_OF_WEEK)
		data = [
			{
				"day_of_week": day_display_map.get(entry.day, entry.day),
				"period_number": entry.period,
				"subject": str(entry.subject) if entry.subject else "",
				"teacher": str(entry.teacher) if entry.teacher else "",
				"class_section": str(entry.class_section),
			}
			for entry in entries
		]
		return Response(data)

	# Backward compatibility: return legacy timetable entries if new entries are not yet created.
	legacy_entries = TimetableEntry.objects.filter(class_section_id=class_id)
	serializer = TimetableSerializer(legacy_entries, many=True)
	return Response(serializer.data)


@api_view(["GET"])
def study_materials(request):
    data = StudyMaterial.objects.all().order_by("-uploaded_at")
    serializer = StudyMaterialSerializer(data, many=True)
    return Response(serializer.data)
