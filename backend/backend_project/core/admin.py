from django.contrib import admin

from .models import Driver, FareRule, Notification, Payment, Route, RouteStation, Station, Trip, User, Vehicle

admin.site.site_header = 'Transportation App'
admin.site.site_title = 'Transportation App'
admin.site.index_title = 'Administration'


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'email', 'role', 'phone_number', 'created_at')


@admin.register(Station)
class StationAdmin(admin.ModelAdmin):
    list_display = ('name', 'governorate', 'latitude', 'longitude', 'is_active')


@admin.register(Route)
class RouteAdmin(admin.ModelAdmin):
    list_display = ('name', 'distance_km', 'duration_minutes', 'status')


@admin.register(RouteStation)
class RouteStationAdmin(admin.ModelAdmin):
    list_display = ('route', 'station', 'sequence_order')


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = ('registration_number', 'capacity', 'status')


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = ('user', 'vehicle', 'status')


@admin.register(FareRule)
class FareRuleAdmin(admin.ModelAdmin):
    list_display = ('route', 'rule_type', 'amount', 'is_active')


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = ('route', 'vehicle', 'driver', 'status', 'fare_amount', 'created_at')


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('trip', 'amount', 'payment_method', 'status', 'paid_at')


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'notification_type', 'is_read', 'created_at')
