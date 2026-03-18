from rest_framework import serializers
from django.contrib.auth import authenticate
from .models import User


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        username_input = data["username"].strip()
        resolved_username = username_input

        matched_user = User.objects.filter(username__iexact=username_input).first()
        if matched_user:
            resolved_username = matched_user.username

        user = authenticate(
            username=resolved_username,
            password=data["password"]
        )
        if not user:
            raise serializers.ValidationError("Invalid credentials")

        return user