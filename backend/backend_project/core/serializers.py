from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from .models import Driver, FareRule, Notification, Payment, Route, RouteStation, Station, Trip, User, Vehicle


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'role', 'phone_number', 'profile_photo_url')


class UserRegistrationSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone_number = serializers.CharField(
        max_length=20, required=False, allow_blank=True, allow_null=True
    )
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    class Meta:
        model = User
        fields = ('username', 'first_name', 'last_name', 'email', 'phone_number', 'password')

    def validate_email(self, value):
        email = value.strip()
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError('A user with this email address already exists.')
        return email

    def validate(self, attrs):
        prospective_user = User(
            username=attrs.get('username'),
            first_name=attrs.get('first_name'),
            last_name=attrs.get('last_name'),
            email=attrs.get('email'),
        )
        try:
            validate_password(attrs['password'], user=prospective_user)
        except DjangoValidationError as error:
            raise serializers.ValidationError({'password': error.messages}) from error
        return attrs

    def create(self, validated_data):
        return User.objects.create_user(**validated_data, role='passenger')


class StationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Station
        fields = '__all__'


class RouteStationSerializer(serializers.ModelSerializer):
    station = StationSerializer(read_only=True)

    class Meta:
        model = RouteStation
        fields = '__all__'


class RouteSerializer(serializers.ModelSerializer):
    route_stations = RouteStationSerializer(many=True, read_only=True)

    class Meta:
        model = Route
        fields = '__all__'


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = '__all__'


class DriverSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = Driver
        fields = '__all__'


class FareRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = FareRule
        fields = '__all__'


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'


class TripSerializer(serializers.ModelSerializer):
    payment = serializers.SerializerMethodField()

    class Meta:
        model = Trip
        fields = '__all__'

    def get_payment(self, obj):
        if hasattr(obj, 'api_first_payment'):
            payments = obj.api_first_payment
            payment = payments[0] if payments else None
        else:
            payment = obj.payments.first()
        if payment is None:
            return None
        return PaymentSerializer(payment).data

class TripSearchSerializer(serializers.Serializer):
    start_station_id = serializers.IntegerField()
    destination_station_id = serializers.IntegerField()

    def validate(self, attrs):
        start_station_id = attrs.get('start_station_id')
        destination_station_id = attrs.get('destination_station_id')
        if start_station_id == destination_station_id:
            raise serializers.ValidationError('Start and destination stations must be different.')
        return attrs
