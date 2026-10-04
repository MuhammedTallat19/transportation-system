from django.db.models import Prefetch, QuerySet
from django.shortcuts import get_object_or_404
from rest_framework import serializers, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.exceptions import NotFound
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.reverse import reverse

from .dependencies import get_trip_service
from .models import (
    Driver,
    FareRule,
    Notification,
    Payment,
    Route,
    RouteStation,
    Station,
    Trip,
    Vehicle,
)
from .serializers import (
    DriverSerializer,
    FareRuleSerializer,
    NotificationSerializer,
    PaymentSerializer,
    RouteSerializer,
    RouteStationSerializer,
    StationSerializer,
    TripSearchSerializer,
    TripSerializer,
    UserRegistrationSerializer,
    UserSerializer,
    VehicleSerializer,
)
from .services.trip_service import StationsNotFoundError


def _collection_api(
    request: Request,
    queryset: QuerySet,
    serializer_class: type[serializers.BaseSerializer],
) -> Response:
    if request.method == "GET":
        return Response(serializer_class(queryset, many=True).data)

    serializer = serializer_class(data=request.data)
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data, status=status.HTTP_201_CREATED)


def _detail_api(
    request: Request,
    queryset: QuerySet,
    serializer_class: type[serializers.BaseSerializer],
    resource_id: int,
) -> Response:
    instance = get_object_or_404(queryset, pk=resource_id)

    if request.method == "GET":
        return Response(serializer_class(instance).data)
    if request.method == "DELETE":
        instance.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    serializer = serializer_class(
        instance,
        data=request.data,
        partial=request.method == "PATCH",
    )
    serializer.is_valid(raise_exception=True)
    serializer.save()
    return Response(serializer.data)


def _trip_queryset() -> QuerySet:
    return Trip.objects.select_related(
        "route",
        "vehicle",
        "driver__user",
        "start_station",
        "destination_station",
        "created_by",
    ).prefetch_related(
        Prefetch(
            "payments",
            queryset=Payment.objects.order_by("pk")[:1],
            to_attr="api_first_payment",
        )
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def api_root(request: Request, format: str | None = None) -> Response:
    resources = (
        ("stations", "station-list"),
        ("routes", "route-list"),
        ("route-stations", "routestation-list"),
        ("vehicles", "vehicle-list"),
        ("drivers", "driver-list"),
        ("fare-rules", "farerule-list"),
        ("trips", "trip-list"),
        ("payments", "payment-list"),
        ("notifications", "notification-list"),
    )
    return Response({
        resource: reverse(view_name, request=request, format=format)
        for resource, view_name in resources
    })


@api_view(["POST"])
@permission_classes([AllowAny])
def register(request: Request, format: str | None = None) -> Response:
    serializer = UserRegistrationSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def stations(request: Request, format: str | None = None) -> Response:
    return _collection_api(
        request,
        Station.objects.filter(is_active=True),
        StationSerializer,
    )


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def station_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    return _detail_api(
        request,
        Station.objects.filter(is_active=True),
        StationSerializer,
        pk,
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def routes(request: Request, format: str | None = None) -> Response:
    queryset = Route.objects.prefetch_related(
        "route_stations__station",
    )
    return _collection_api(request, queryset, RouteSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def route_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    queryset = Route.objects.prefetch_related("route_stations__station")
    return _detail_api(request, queryset, RouteSerializer, pk)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def route_stations(request: Request, format: str | None = None) -> Response:
    queryset = RouteStation.objects.select_related("station")
    return _collection_api(request, queryset, RouteStationSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def route_station_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    queryset = RouteStation.objects.select_related("station")
    return _detail_api(
        request,
        queryset,
        RouteStationSerializer,
        pk,
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def vehicles(request: Request, format: str | None = None) -> Response:
    return _collection_api(request, Vehicle.objects.all(), VehicleSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def vehicle_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    return _detail_api(
        request,
        Vehicle.objects.all(),
        VehicleSerializer,
        pk,
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def drivers(request: Request, format: str | None = None) -> Response:
    queryset = Driver.objects.select_related("user", "vehicle")
    return _collection_api(request, queryset, DriverSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def driver_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    queryset = Driver.objects.select_related("user", "vehicle")
    return _detail_api(request, queryset, DriverSerializer, pk)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def fare_rules(request: Request, format: str | None = None) -> Response:
    queryset = FareRule.objects.select_related("route")
    return _collection_api(request, queryset, FareRuleSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def fare_rule_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    queryset = FareRule.objects.select_related("route")
    return _detail_api(
        request,
        queryset,
        FareRuleSerializer,
        pk,
    )


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def trips(request: Request, format: str | None = None) -> Response:
    if request.method == "GET":
        return Response(TripSerializer(_trip_queryset(), many=True).data)

    serializer = TripSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    trip = get_trip_service().create_trip(serializer.validated_data)
    return Response(TripSerializer(trip).data, status=status.HTTP_201_CREATED)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def trip_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    return _detail_api(request, _trip_queryset(), TripSerializer, pk)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def trip_search(request: Request, format: str | None = None) -> Response:
    serializer = TripSearchSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)

    try:
        results = get_trip_service().search_routes(
            serializer.validated_data["start_station_id"],
            serializer.validated_data["destination_station_id"],
        )
    except StationsNotFoundError as error:
        raise NotFound(str(error)) from error

    return Response({
        "results": [
            {
                "route": RouteSerializer(result.route).data,
                "fare": f"{result.fare:.2f}",
                "estimated_travel_time": result.estimated_travel_time,
            }
            for result in results
        ]
    })


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def payments(request: Request, format: str | None = None) -> Response:
    queryset = Payment.objects.select_related("trip")
    return _collection_api(request, queryset, PaymentSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def payment_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    queryset = Payment.objects.select_related("trip")
    return _detail_api(request, queryset, PaymentSerializer, pk)


@api_view(["GET", "POST"])
@permission_classes([IsAuthenticated])
def notifications(request: Request, format: str | None = None) -> Response:
    queryset = Notification.objects.select_related("user")
    return _collection_api(request, queryset, NotificationSerializer)


@api_view(["GET", "PUT", "PATCH", "DELETE"])
@permission_classes([IsAuthenticated])
def notification_detail(
    request: Request,
    pk: int,
    format: str | None = None,
) -> Response:
    queryset = Notification.objects.select_related("user")
    return _detail_api(
        request,
        queryset,
        NotificationSerializer,
        pk,
    )
