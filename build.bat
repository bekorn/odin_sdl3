@echo off

odin build src/ -out:bin/app.exe -debug
if %errorlevel% neq 0 (
    exit /b 1
)

:: Copy SDL3.dll into bin\
for /f "delims=" %%I in ('odin root') do set "sdl_src=%%I"
set "sdl_src=%sdl_src%vendor\sdl3\SDL3.dll"

set "sdl_dst=.\bin\SDL3.dll"

if not exist "%sdl_dst%" (
    copy "%sdl_src%" "%sdl_dst%"
)


if "%~1" == "run" (
    .\bin\app.exe
)
