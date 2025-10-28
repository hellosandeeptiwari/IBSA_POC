"""
Simple API Startup Script - Avoids Windows PowerShell Unicode Issues
"""
import os
import sys

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    os.environ['PYTHONIOENCODING'] = 'utf-8'

# Import and run
if __name__ == "__main__":
    import uvicorn
    
    print("=" * 80)
    print("IBSA AI CALL SCRIPT GENERATOR API - STARTING")
    print("=" * 80)
    print("\nServer Configuration:")
    print("  URL: http://localhost:8000")
    print("  Docs: http://localhost:8000/docs")
    print("  Health Check: http://localhost:8000/health")
    print("\nPress CTRL+C to stop the server")
    print("=" * 80)
    print()
    
    # Run server directly (not as module to avoid multiprocessing issues)
    from phase6e_fastapi_production_api import app
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info",
        access_log=True
    )
