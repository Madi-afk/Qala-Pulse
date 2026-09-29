FROM python:3.13-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /app
COPY pyproject.toml ./
COPY requirements.lock ./
RUN pip install -r requirements.lock
COPY app ./app
RUN pip install --no-deps . && useradd --uid 10001 --create-home qalapulse
COPY alembic.ini ./
USER qalapulse
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
