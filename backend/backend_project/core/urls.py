from django.urls import path
from rest_framework.urlpatterns import format_suffix_patterns

from . import views


urlpatterns = [
    path("register/", views.register, name="user-register"),
]

resource_urlpatterns = [
    path("", views.api_root, name="api-root"),
    path("stations/", views.stations, name="station-list"),
    path("stations/<int:pk>/", views.station_detail, name="station-detail"),
    path("routes/", views.routes, name="route-list"),
    path("routes/<int:pk>/", views.route_detail, name="route-detail"),
    path("route-stations/", views.route_stations, name="routestation-list"),
    path(
        "route-stations/<int:pk>/",
        views.route_station_detail,
        name="routestation-detail",
    ),
    path("vehicles/", views.vehicles, name="vehicle-list"),
    path("vehicles/<int:pk>/", views.vehicle_detail, name="vehicle-detail"),
    path("drivers/", views.drivers, name="driver-list"),
    path("drivers/<int:pk>/", views.driver_detail, name="driver-detail"),
    path("fare-rules/", views.fare_rules, name="farerule-list"),
    path("fare-rules/<int:pk>/", views.fare_rule_detail, name="farerule-detail"),
    path("trips/search/", views.trip_search, name="trip-search"),
    path("trips/", views.trips, name="trip-list"),
    path("trips/<int:pk>/", views.trip_detail, name="trip-detail"),
    path("payments/", views.payments, name="payment-list"),
    path("payments/<int:pk>/", views.payment_detail, name="payment-detail"),
    path("notifications/", views.notifications, name="notification-list"),
    path(
        "notifications/<int:pk>/",
        views.notification_detail,
        name="notification-detail",
    ),
]

urlpatterns += format_suffix_patterns(resource_urlpatterns)
