from rest_framework.routers import DefaultRouter
from .views import CategoryViewSet, ExpenseViewSet, BudgetViewSet

# DefaultRouter is another shortcut, the router looks at the ViewSet, and automatically generates the URL patterns

router = DefaultRouter()
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'expenses', ExpenseViewSet, basename='expenses')
router.register(r'budgets', BudgetViewSet, basename='budget')

urlpatterns = router.urls