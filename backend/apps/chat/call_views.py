from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from . import calls
from .models import Call


class CallStartSerializer(serializers.Serializer):
    kind = serializers.ChoiceField(choices=Call.CallKind.choices, default=Call.CallKind.AUDIO)


class CallInviteSerializer(serializers.Serializer):
    user_ids = serializers.ListField(child=serializers.IntegerField(), max_length=50)


class ConversationCalls(APIView):
    @extend_schema(tags=["calls"], responses=dict)
    def get(self, request, pk):
        return Response([calls.call_payload(c) for c in calls.conversation_calls(request.user, pk)])

    @extend_schema(tags=["calls"], request=CallStartSerializer, responses={201: dict})
    def post(self, request, pk):
        data = CallStartSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        call = calls.start_call(request.user, pk, data.validated_data["kind"])
        return Response(calls.call_payload(call), status=status.HTTP_201_CREATED)


class CallDetail(APIView):
    @extend_schema(tags=["calls"], responses=dict)
    def get(self, request, pk):
        return Response(calls.call_payload(calls.get_call_for(request.user, pk)))


class CallAnswer(APIView):
    @extend_schema(tags=["calls"], request=None, responses=dict)
    def post(self, request, pk):
        return Response(calls.call_payload(calls.answer_call(request.user, pk)))


class CallDecline(APIView):
    @extend_schema(tags=["calls"], request=None, responses=dict)
    def post(self, request, pk):
        return Response(calls.call_payload(calls.decline_call(request.user, pk)))


class CallEnd(APIView):
    @extend_schema(tags=["calls"], request=None, responses=dict)
    def post(self, request, pk):
        return Response(calls.call_payload(calls.end_call(request.user, pk)))


class CallInvite(APIView):
    @extend_schema(tags=["calls"], request=CallInviteSerializer, responses=dict)
    def post(self, request, pk):
        data = CallInviteSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        return Response(calls.call_payload(calls.invite_to_call(request.user, pk, data.validated_data["user_ids"])))
