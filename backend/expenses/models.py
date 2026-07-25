from django.db import models
from django.contrib.auth.models import User

class Category(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='categories') # Link die category aan 'n spesifieke ingelogde gebruiker, sodat jou categories en iemand anders sn nie meng nie.
    name = models.CharField(max_length=100) # category name bv. Inkopies
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'name') # Voorkom dat jy dalk dieselfde kategorie bv. Inkopies twee keer skep.
    
    def __str__(self):
        return self.name

# Link die Expense model aan die User en Category models. Elke expense behoort aan 'n spesifieke gebruiker en kategorie.
class Expense(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='expenses')
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='expenses')
    amount = models.DecimalField(max_digits=10, decimal_places=2) 
    description = models.TextField(max_length=255, blank=True)
    date = models.DateField() # Die datum van die expense. Anders as created at, want jy kan dalk 'n expense van 3 dae terug nou eers invoer met 'n ander datum as vandag.
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date']
    
    def __str__(self):
        return f'{self.description or self.category.name} - {self.amount}'

# Link die Budget model aan die User en Category models. Elke budget behoort aan 'n spesifieke gebruiker en kategorie.
class Budget(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='budgets')
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='budgets')
    monthly_limit = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        unique_together = ('user', 'category')
    
    def __str__(self):
        return f"{self.category.name} budget: {self.monthly_limit}"

class Income(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='income')
    monthly_income = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.user.username}'s income: {self.monthly_income}"  