FROM python:3.12-slim

LABEL maintainer="ground-station-operator"
LABEL description="Ground Station Telecommand API — Zero Trust demo"

RUN useradd --create-home --shell /bin/bash gsoperator

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

RUN chown -R gsoperator:gsoperator /app
USER gsoperator

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
