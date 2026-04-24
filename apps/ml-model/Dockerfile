FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY models/ ./models/

ENV APP_VERSION=1.0.0
ENV PYTHONUNBUFFERED=1

EXPOSE 8001

# Train model at build time if not already present
RUN python -m src.train || true

CMD ["uvicorn", "src.serve:app", "--host", "0.0.0.0", "--port", "8001"]
