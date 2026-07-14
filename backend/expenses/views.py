from rest_framework import viewsets, permissions
from .models import Category, Expense, Budget
from .serializers import CategorySerializer, ExpenseSerializer, BudgetSerializer

# Die ModelViewSet is a Django REST Framework shortcut that automatically creates API behavior for a model - instead of writing 5 seperate functions.

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
        return Budget.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)