FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/
COPY do_report.sh ./do_report.sh
RUN chmod +x ./do_report.sh

RUN useradd --create-home --uid 10001 report \
    && chown -R report:report /app
USER report

CMD ["python", "-m", "app"]
