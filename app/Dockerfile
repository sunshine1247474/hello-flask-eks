# ============================================
# Multi-Stage Dockerfile for Flask Application
# ============================================
# WHY Multi-Stage?
# - Smaller final image (no build tools)
# - Better security (less attack surface)
# - Faster deployments
#
# INTERVIEW TIP: "We use multi-stage builds to separate 
# build dependencies from runtime. The final image only 
# contains what's needed to run the app."

# ============================================
# Stage 1: Builder
# ============================================
# Install dependencies in a separate stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies (if any compiled packages)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install requirements first (layer caching!)
# INTERVIEW TIP: "By copying requirements.txt first, Docker 
# caches this layer. Dependencies only rebuild when requirements change."
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ============================================
# Stage 2: Runtime
# ============================================
# Minimal image with only runtime dependencies
FROM python:3.12-slim

# ============================================
# Security: Non-root user
# ============================================
# WHY Non-root?
# - Security best practice
# - Limits damage if container is compromised
# - Required by many K8s security policies
#
# INTERVIEW TIP: "Running as root in containers is a security 
# risk. If an attacker exploits the app, they'd have root access 
# to the container. Non-root limits the blast radius."

RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY . .

# Set ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Add local pip packages to PATH
ENV PATH=/home/appuser/.local/bin:$PATH

# ============================================
# Environment Variables
# ============================================
# Defaults that can be overridden at runtime
ENV PORT=5000
ENV ENVIRONMENT=production
ENV PYTHONUNBUFFERED=1

# ============================================
# Expose Port
# ============================================
# INTERVIEW TIP: "EXPOSE is documentation - it doesn't 
# actually publish the port. You still need -p in docker run 
# or containerPort in K8s."
EXPOSE 5000

# ============================================
# Health Check
# ============================================
# WHY HEALTHCHECK in Dockerfile?
# - Docker can monitor container health
# - Works with docker-compose
# - K8s uses its own probes (livenessProbe, readinessProbe)

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# ============================================
# Start Application
# ============================================
# WHY Gunicorn instead of Flask dev server?
# - Production-grade WSGI server
# - Multiple workers for better performance
# - Better handling of concurrent requests
#
# INTERVIEW TIP: "Flask's built-in server is for development only.
# In production, we use Gunicorn which is a proper WSGI server 
# that can handle concurrent requests and worker management."

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "app:app"]
