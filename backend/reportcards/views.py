from io import BytesIO

from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from rest_framework.decorators import api_view
from rest_framework.response import Response

from academics.models import Marks
from schools.models import School

from .models import ReportCard
from .serializers import ReportCardSerializer


@api_view(["GET"])
def student_reportcards(request, student_id):
	records = ReportCard.objects.filter(
		student_id=student_id,
		is_published=True,
	).order_by("-generated_on")
	serializer = ReportCardSerializer(records, many=True)
	return Response(serializer.data)


@api_view(["GET"])
def reportcard_pdf(request, reportcard_id):
	report_card = get_object_or_404(
		ReportCard.objects.select_related("student", "exam"),
		id=reportcard_id,
		is_published=True,
	)

	# If a file is already stored, stream it from disk directly.
	if report_card.pdf_file:
		try:
			with report_card.pdf_file.open("rb") as fh:
				response = HttpResponse(fh.read(), content_type="application/pdf")
				response["Content-Disposition"] = (
					f'inline; filename="report_card_{report_card.id}.pdf"'
				)
				return response
		except OSError:
			# Fall back to dynamically rendering a PDF.
			pass

	marks = Marks.objects.filter(
		student=report_card.student,
		exam=report_card.exam,
	).select_related("subject")
	school = School.objects.first()

	buffer = BytesIO()
	p = canvas.Canvas(buffer, pagesize=A4)
	width, height = A4

	y = height - 50
	p.setFont("Helvetica-Bold", 16)
	p.drawString(50, y, school.name if school else "School Report Card")

	y -= 25
	p.setFont("Helvetica", 11)
	p.drawString(50, y, f"Student: {report_card.student.full_name}")
	y -= 18
	p.drawString(50, y, f"Class: {report_card.student.class_section}")
	y -= 18
	p.drawString(50, y, f"Exam: {report_card.exam.name} ({report_card.exam.academic_year})")

	y -= 28
	p.setFont("Helvetica-Bold", 11)
	p.drawString(50, y, "Subject")
	p.drawString(350, y, "Score")
	y -= 14
	p.line(50, y, width - 50, y)

	p.setFont("Helvetica", 11)
	for mark in marks:
		y -= 18
		if y < 120:
			p.showPage()
			y = height - 50
			p.setFont("Helvetica", 11)
		p.drawString(50, y, mark.subject.name)
		p.drawRightString(width - 60, y, str(mark.score))

	y -= 26
	p.setFont("Helvetica-Bold", 11)
	p.drawString(50, y, f"Total: {report_card.total}")
	y -= 18
	p.drawString(50, y, f"Percentage: {report_card.percentage}%")
	y -= 18
	p.drawString(50, y, f"Grade: {report_card.grade}")

	if report_card.remarks:
		y -= 22
		p.setFont("Helvetica-Bold", 11)
		p.drawString(50, y, "Remarks:")
		y -= 16
		p.setFont("Helvetica", 10)
		text_obj = p.beginText(50, y)
		for line in str(report_card.remarks).splitlines():
			text_obj.textLine(line[:110])
		p.drawText(text_obj)

	p.showPage()
	p.save()
	buffer.seek(0)

	response = HttpResponse(buffer.getvalue(), content_type="application/pdf")
	response["Content-Disposition"] = f'inline; filename="report_card_{report_card.id}.pdf"'
	return response
