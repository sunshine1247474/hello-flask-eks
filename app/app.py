#!/usr/bin/env python3
"""
Hello Flask Application
DevOps Assignment - Simple Flask API

This is a minimal Flask application for demonstrating
containerization and Kubernetes deployment.
"""

from flask import Flask, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)

# ============================================
# Configuration from Environment
# ============================================
# Best practice: Use environment variables for configuration
# This allows different configs in dev/staging/prod without code changes

PORT = int(os.getenv("PORT", 5000))
ENV = os.getenv("ENVIRONMENT", "development")
VERSION = os.getenv("APP_VERSION", "1.0.0")


# ============================================
# Routes
# ============================================

@app.route("/")
def hello():
    """
    Main endpoint - returns a greeting
    INTERVIEW TIP: "This is the main entry point that proves 
    our app is running and can respond to requests."
    """
    return jsonify({
        "message": "Hello from Flask! 🐍",
        "version": VERSION,
        "environment": ENV,
        "hostname": socket.gethostname(),  # Shows which pod handled the request
        "timestamp": datetime.utcnow().isoformat()
    })


@app.route("/health")
@app.route("/healthcheck")
def health():
    """
    Health check endpoint
    
    WHY Health Check?
    - Kubernetes uses this to determine if pod is alive (liveness)
    - Load balancers use this to route traffic only to healthy pods
    
    INTERVIEW TIP: "Health endpoints are critical for K8s. 
    Liveness probes restart unhealthy pods. Readiness probes 
    prevent traffic to pods that aren't ready."
    """
    return jsonify({
        "status": "healthy",
        "service": "hello-flask",
        "version": VERSION,
        "checks": {
            "app": "ok",
            "memory": "ok"
        }
    }), 200


@app.route("/ready")
def ready():
    """
    Readiness endpoint
    
    WHY separate from Health?
    - Health = "Am I alive?" (restart if no)
    - Ready = "Can I serve traffic?" (don't route if no)
    
    Example: App is alive but waiting for DB connection
    """
    # In real app, you'd check dependencies here
    # (database connection, external services, etc.)
    return jsonify({
        "ready": True,
        "message": "Application is ready to serve traffic"
    }), 200


@app.route("/info")
def info():
    """
    Information endpoint - useful for debugging
    """
    return jsonify({
        "app": "hello-flask",
        "version": VERSION,
        "environment": ENV,
        "hostname": socket.gethostname(),
        "python_version": os.popen("python --version").read().strip(),
        "endpoints": {
            "/": "Main greeting",
            "/health": "Health check",
            "/ready": "Readiness check",
            "/info": "Application info"
        }
    })


# ============================================
# Error Handlers
# ============================================

@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "Not Found",
        "message": "The requested endpoint does not exist",
        "status": 404
    }), 404


@app.errorhandler(500)
def server_error(error):
    return jsonify({
        "error": "Internal Server Error",
        "message": "Something went wrong",
        "status": 500
    }), 500


# ============================================
# Main Entry Point
# ============================================

if __name__ == "__main__":
    print(f"🚀 Starting Flask app on port {PORT}")
    print(f"📍 Environment: {ENV}")
    print(f"📦 Version: {VERSION}")
    
    app.run(
        host="0.0.0.0",  # Listen on all interfaces (required for containers)
        port=PORT,
        debug=(ENV == "development")  # Only debug in dev
    )
