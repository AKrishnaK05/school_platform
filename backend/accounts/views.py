from rest_framework.decorators import api_view
from rest_framework.response import Response
from .serializers import LoginSerializer
from .models import ParentProfile


@api_view(["POST"])
def login_view(request):
	serializer = LoginSerializer(data=request.data)

	if serializer.is_valid():
		user = serializer.validated_data

		parent_profile = ParentProfile.objects.filter(user=user).first()

		return Response({
			"user_id": user.id,
			"parent_id": parent_profile.id if parent_profile else None,
		})

	return Response(serializer.errors, status=400)
