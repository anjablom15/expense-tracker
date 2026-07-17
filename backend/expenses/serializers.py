from rest_framework import serializers
from .models import Category, Expense, Budget

# Die velde -> die velde wat jy wil hê die serializer moet insluit. Die read_only_fields -> die velde wat jy nie wil hê die gebruiker moet kan verander nie.
#              user is nie in die fields nie, want dit sal outomaties ingestel word op die ingelogde gebruiker in die view.
#              jy wil nie he die user kan die user veld verander nie, want dit sal jou data beskadig.

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category # Watter model hierdie serializer voor is
        fields = ['id', 'name', 'created_at']
        read_only_fields = ['id', 'created_at']

class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = ['id', 'category', 'category_name','amount', 'description', 'date', 'created_at']
        read_only_fields = ['id', 'created_at']

class BudgetSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True) # Voeg 'n veld by wat die kategorie naam van die budget sal wys. Dit is nie 'n veld in die model nie, maar dit is 'n veld wat jy kan gebruik in die serializer.
    class Meta:
        model = Budget
        fields = ['id', 'category', 'category_name', 'monthly_limit']
        read_only_fields = ['id']