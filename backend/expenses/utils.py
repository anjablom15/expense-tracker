from datetime import date
import calendar


def get_current_period_start(cycle_day):
    today = date.today()

    if today.day >= cycle_day:
        year = today.year
        month = today.month
    else:
        year = today.year
        month = today.month - 1
        if month == 0:
            month = 12
            year -= 1

    last_day_of_month = calendar.monthrange(year, month)[1]
    actual_day = min(cycle_day, last_day_of_month)

    return date(year, month, actual_day)