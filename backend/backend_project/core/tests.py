from django.contrib.auth import get_user_model
from django.db import IntegrityError
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Driver, FareRule, Payment, Route, RouteStation, Station, Trip, Vehicle
from .services.trip_service import TripService


class TransportApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = get_user_model().objects.create_user(
            username='tester',
            email='tester@example.com',
            password='secret123',
            role='admin',
        )
        self.client.force_authenticate(self.user)

    def test_route_search_and_fare_calculation(self):
        start = Station.objects.create(name='Start Station', latitude=30.0, longitude=31.0, is_active=True)
        middle = Station.objects.create(name='Middle Station', latitude=30.1, longitude=31.1, is_active=True)
        end = Station.objects.create(name='End Station', latitude=30.2, longitude=31.2, is_active=True)

        route = Route.objects.create(name='Route A', status='active')
        RouteStation.objects.create(route=route, station=start, sequence_order=1)
        RouteStation.objects.create(route=route, station=middle, sequence_order=2)
        RouteStation.objects.create(route=route, station=end, sequence_order=3)

        FareRule.objects.create(
            route=route,
            rule_type='fixed',
            amount=15.00,
            is_active=True,
        )

        response = self.client.post('/api/trips/search/', {
            'start_station_id': start.id,
            'destination_station_id': end.id,
        }, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['results'][0]['route']['id'], route.id)
        self.assertEqual(response.data['results'][0]['fare'], '15.00')

    def test_trip_creation_creates_payment_record(self):
        start = Station.objects.create(name='Alpha', latitude=1.0, longitude=1.0, is_active=True)
        end = Station.objects.create(name='Beta', latitude=2.0, longitude=2.0, is_active=True)
        route = Route.objects.create(name='Alpha-Beta', status='active')
        RouteStation.objects.create(route=route, station=start, sequence_order=1)
        RouteStation.objects.create(route=route, station=end, sequence_order=2)
        FareRule.objects.create(route=route, rule_type='fixed', amount=8.50, is_active=True)

        vehicle = Vehicle.objects.create(registration_number='ABC-123', capacity=30, status='active')
        driver = Driver.objects.create(user=self.user, vehicle=vehicle, status='active')

        response = self.client.post('/api/trips/', {
            'route': route.id,
            'vehicle': vehicle.id,
            'driver': driver.id,
            'start_station': start.id,
            'destination_station': end.id,
            'status': 'scheduled',
            'fare_amount': '8.50',
        }, format='json')

        self.assertEqual(response.status_code, 201)
        self.assertTrue(Trip.objects.filter(route=route).exists())
        self.assertEqual(response.data['payment']['amount'], '8.50')

    def test_trip_creation_is_atomic_when_payment_creation_fails(self):
        start = Station.objects.create(name='Atomic Start', latitude=1.0, longitude=1.0)
        end = Station.objects.create(name='Atomic End', latitude=2.0, longitude=2.0)
        route = Route.objects.create(name='Atomic Route')

        class FailingTripRepository:
            def create_trip_with_payment(self, validated_data):
                Trip.objects.create(**validated_data)
                raise IntegrityError('Payment could not be created.')

        with self.assertRaises(IntegrityError):
            TripService(FailingTripRepository()).create_trip({
                'route': route,
                'start_station': start,
                'destination_station': end,
                'fare_amount': '4.00',
            })

        self.assertFalse(Trip.objects.filter(route=route).exists())

    def test_trip_list_prefetches_the_first_payment_for_all_trips(self):
        start = Station.objects.create(name='List Start', latitude=1.0, longitude=1.0)
        end = Station.objects.create(name='List End', latitude=2.0, longitude=2.0)
        route = Route.objects.create(name='List Route')
        for fare in ('4.00', '5.00'):
            trip = Trip.objects.create(
                route=route,
                start_station=start,
                destination_station=end,
                fare_amount=fare,
            )
            Payment.objects.create(trip=trip, amount=fare)

        with self.assertNumQueries(2):
            response = self.client.get('/api/trips/')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2)
        self.assertEqual(
            {item['payment']['amount'] for item in response.data},
            {'4.00', '5.00'},
        )

    def test_station_collection_and_detail_keep_crud_behavior(self):
        response = self.client.post('/api/stations/', {
            'name': 'Created Station',
            'latitude': 1.0,
            'longitude': 2.0,
            'is_active': True,
        }, format='json')
        self.assertEqual(response.status_code, 201)
        station_id = response.data['id']

        response = self.client.patch(
            f'/api/stations/{station_id}/',
            {'name': 'Updated Station'},
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['name'], 'Updated Station')

        response = self.client.get(f'/api/stations/{station_id}/')
        self.assertEqual(response.status_code, 200)

        response = self.client.delete(f'/api/stations/{station_id}/')
        self.assertEqual(response.status_code, 204)
        self.assertEqual(self.client.get(f'/api/stations/{station_id}/').status_code, 404)

    def test_management_endpoints_remain_authenticated(self):
        response = APIClient().get('/api/stations/')
        self.assertEqual(response.status_code, 401)

    def test_every_resource_collection_route_is_available(self):
        for resource in (
            'stations',
            'routes',
            'route-stations',
            'vehicles',
            'drivers',
            'fare-rules',
            'trips',
            'payments',
            'notifications',
        ):
            with self.subTest(resource=resource):
                response = self.client.get(f'/api/{resource}/')
                self.assertEqual(response.status_code, 200)
                self.assertIsInstance(response.data, list)

    def test_api_root_and_format_suffix_are_preserved(self):
        response = self.client.get('/api/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            set(response.data),
            {
                'stations',
                'routes',
                'route-stations',
                'vehicles',
                'drivers',
                'fare-rules',
                'trips',
                'payments',
                'notifications',
            },
        )

        response = self.client.get('/api/stations.json')
        self.assertEqual(response.status_code, 200)


class UserRegistrationApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.registration_data = {
            'username': 'new_passenger',
            'first_name': 'New',
            'last_name': 'Passenger',
            'email': 'new.passenger@example.com',
            'phone_number': '+15551234567',
            'password': 'Different-strong-pass-123!',
            'role': 'admin',
        }

    def test_registration_creates_passenger_and_allows_login(self):
        response = self.client.post('/api/register/', self.registration_data, format='json')

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['username'], self.registration_data['username'])
        self.assertEqual(response.data['role'], 'passenger')
        self.assertNotIn('password', response.data)

        user = get_user_model().objects.get(username=self.registration_data['username'])
        self.assertTrue(user.check_password(self.registration_data['password']))

        token_response = self.client.post('/api/token/', {
            'username': self.registration_data['username'],
            'password': self.registration_data['password'],
        }, format='json')
        self.assertEqual(token_response.status_code, 200)
        self.assertIn('access', token_response.data)

    def test_registration_rejects_duplicate_email(self):
        get_user_model().objects.create_user(
            username='existing_passenger',
            email=self.registration_data['email'].upper(),
            password='Different-strong-pass-123!',
        )

        response = self.client.post('/api/register/', self.registration_data, format='json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('email', response.data)
        self.assertFalse(get_user_model().objects.filter(
            username=self.registration_data['username']
        ).exists())

    def test_registration_rejects_weak_password(self):
        self.registration_data['password'] = '12345678'

        response = self.client.post('/api/register/', self.registration_data, format='json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('password', response.data)
        self.assertFalse(get_user_model().objects.filter(
            username=self.registration_data['username']
        ).exists())
