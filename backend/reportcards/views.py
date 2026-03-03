from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import ReportCard
from .serializers import ReportCardSerializer


@api_view(["GET"])
def student_reportcards(request, student_id):
	records = ReportCard.objects.filter(student_id=student_id).order_by("-generated_on")
	serializer = ReportCardSerializer(records, many=True)
	return Response(serializer.data)
