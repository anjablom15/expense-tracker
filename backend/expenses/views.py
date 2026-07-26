from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import viewsets, permissions
from django.contrib.auth.models import User
from .models import Category, Expense, Budget, Income
from .serializers import CategorySerializer, ExpenseSerializer, BudgetSerializer, IncomeSerializer, RegisterSerializer
from .utils import get_current_period_start

# Die ModelViewSet is a Django REST Framework shortcut that automatically creates API behavior for a model - instead of writing 5 seperate functions.

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        if User.objects.filter(username=request.data.get('username')).exists():
            return Response(
                {'error': 'Username already taken'},
                status=400,
            )

        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {'message': 'User created successfully'},
                status=201,
            )
        return Response(serializer.errors, status=400)
    
class CategoryViewSet(viewsets.ModelViewSet):
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAuthenticated]  # User must be logged in to use any of the eindpoints at all.

    # Important security: Makes sure that when someone asks for "my expenses", they only see the expenses that matches the logged in user, never anyone else's data.
    def get_queryset(self):
        return Category.objects.filter(user=self.request.user)

    # When creating a new expense/category/budget, automatically attach it to whoever is currently logged in, rather than trusting the app to say who it belongs to.
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class ExpenseViewSet(viewsets.ModelViewSet):
    serializer_class = ExpenseSerializer
    permission_classes = [permissions.IsAuthenticated]  

    def get_queryset(self):
        return Expense.objects.filter(user=self.request.user)
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class BudgetViewSet(viewsets.ModelViewSet):
    serializer_class = BudgetSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        queryset = Budget.objects.filter(user=self.request.user)

        period_start = self.request.query_params.get('period_start')
        if period_start:
            queryset = queryset.filter(period_start=period_start)

        return queryset

    def perform_create(self, serializer):
        income, created = Income.objects.get_or_create(
            user=self.request.user,
            defaults={'monthly_income': 0}
        )
        period_start = get_current_period_start(income.budget_cycle_day)
        serializer.save(user=self.request.user, period_start=period_start)

class IncomeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        income, created = Income.objects.get_or_create(
            user=request.user,
            defaults={'monthly_income': 0}
        )
        serializer = IncomeSerializer(income)
        return Response(serializer.data)

    def put(self, request):
        income, created = Income.objects.get_or_create(
            user=request.user,
            defaults={'monthly_income': 0}
        )
        serializer = IncomeSerializer(income, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)