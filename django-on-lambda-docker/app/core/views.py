from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.shortcuts import render
import asyncio

async def sleep_view(request):
    try:
        sleep_time = int(request.GET.get('seconds', 1))
        # Limit maximum sleep time to prevent abuse
        sleep_time = min(sleep_time, 300)  # API Gateway timeout is 29 seconds
        
        await asyncio.sleep(sleep_time)
        return HttpResponse(f"Slept for {sleep_time} seconds")
    except ValueError:
        return HttpResponse("Please provide a valid number of seconds", status=400)

def sleep_form(request):
    return render(request, 'sleep_form.html')
