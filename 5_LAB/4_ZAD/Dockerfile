ARG ALPINE_VERSION=3.17

FROM alpine:${ALPINE_VERSION}

ARG PYTHON_VERSION=3.10
ARG APP_PORT=8000

ENV PYTHON_VERSION=${PYTHON_VERSION} \
    APP_PORT=${APP_PORT} \
    APP_HOME=/app \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apk update && \
    apk add --no-cache \
        python${PYTHON_VERSION} \
        py${PYTHON_VERSION}-pip \
        tzdata \
        bash \
        curl && \
    ln -sf python${PYTHON_VERSION} /usr/bin/python && \
    ln -sf pip${PYTHON_VERSION} /usr/bin/pip && \
    pip install --upgrade pip

WORKDIR ${APP_HOME}

COPY requirements.txt ${APP_HOME}/

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ${APP_HOME}/

VOLUME ["${APP_HOME}/data", "${APP_HOME}/logs"]

EXPOSE ${APP_PORT}

LABEL volumes.data="${APP_HOME}/data" \
      volumes.logs="${APP_HOME}/logs"

CMD ["sh", "-c", "python app.py --port ${APP_PORT}"]
