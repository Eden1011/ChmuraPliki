FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --index-url https://pypi.org/simple/

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
