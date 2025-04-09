ARG PYTHON_VERSION=3.9

FROM python:${PYTHON_VERSION}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY myapp/requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY myapp/ .

EXPOSE 5000

CMD ["python", "app.py"]
