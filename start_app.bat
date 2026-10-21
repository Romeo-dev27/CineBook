@echo off
title CineBook Launcher
echo ============================================================
echo   CineBook - Demarrage de l'application Full-Stack
echo ============================================================
echo.

cd /d C:\Projets_ESST\CineBook

echo [1/2] Lancement du Backend FastAPI (port 8000)...
start "CineBook - Backend FastAPI" cmd /k ".venv\Scripts\python.exe -m uvicorn backend.main:app --reload --port 8000"

echo [2/2] Lancement du Frontend Flutter Web (port 8080)...
cd frontend
set PATH=D:\flutter\bin;%PATH%
start "CineBook - Frontend Flutter" cmd /k "flutter run -d edge --web-port 8080"

echo.
echo ============================================================
echo   Application en cours de demarrage !
echo   - Frontend : http://localhost:8080
echo   - Backend API Docs : http://127.0.0.1:8000/docs
echo ============================================================
pause
