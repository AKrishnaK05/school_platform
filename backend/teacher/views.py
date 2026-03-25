from django.contrib.auth import authenticate, login
from django.contrib.auth.decorators import login_required
from django.shortcuts import redirect, render

from accounts.models import TeacherProfile


def teacher_login(request):
    if request.method == "POST":
        username = request.POST["username"]
        password = request.POST["password"]

        user = authenticate(request, username=username, password=password)

        if user and TeacherProfile.objects.filter(user=user).exists():
            login(request, user)
            return redirect("teacher_dashboard")

    return render(request, "teacher/login.html")


@login_required(login_url="teacher_login")
def teacher_dashboard(request):
    teacher = TeacherProfile.objects.filter(user=request.user).first()
    if teacher is None:
        return redirect("teacher_login")

    return render(request, "teacher/dashboard.html", {"teacher": teacher})
