@echo off

odin build src/ -out:bin/app.exe -debug

if "%~1" == "run" (
    .\bin\app.exe
)
