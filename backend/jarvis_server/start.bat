@echo off
REM Quick start script for J.A.R.V.I.S Server (Windows)

echo ========================================
echo J.A.R.V.I.S Server Quick Start
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate
echo.

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt
echo.

REM Check if .env exists
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Please copy .env.example to .env and add your OpenAI API key
    echo.
    pause
    exit /b 1
)

REM Start server
echo Starting J.A.R.V.I.S Server...
echo Server will be available at http://localhost:8000
echo API docs at http://localhost:8000/docs
echo.
python main.py
