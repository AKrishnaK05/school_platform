from django.urls import path

from .views import (
    download_class_report_cards_pdf,
    download_report_card_pdf,
    enter_marks,
    generate_report_cards,
    manage_timetable,
    mark_attendance,
    post_announcement,
    reply_message,
    teacher_dashboard,
    teacher_login,
    teacher_logout,
    teacher_messages,
    upload_material,
)

urlpatterns = [
    path("login/", teacher_login, name="teacher_login"),
    path("dashboard/", teacher_dashboard, name="teacher_dashboard"),
    path("attendance/<int:class_id>/", mark_attendance, name="mark_attendance"),
    path("timetable/", manage_timetable, name="manage_timetable"),
    path("marks/", enter_marks, name="enter_marks"),
    path("report-cards/", generate_report_cards, name="generate_report_cards"),
    path(
        "report-cards/pdf/<int:student_id>/<int:exam_id>/",
        download_report_card_pdf,
        name="download_report_card_pdf",
    ),
    path(
        "report-cards/pdf/class/<int:class_id>/<int:exam_id>/",
        download_class_report_cards_pdf,
        name="download_class_report_cards_pdf",
    ),
    path("materials/", upload_material, name="upload_material"),
    path("announcements/", post_announcement, name="post_announcement"),
    path("messages/", teacher_messages, name="teacher_messages"),
    path("reply/", reply_message, name="reply_message"),
    path("logout/", teacher_logout, name="logout"),
]
