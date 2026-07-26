@echo off
@rem ----------------------------------------------------------------------------
@rem  Hvigor startup script for Windows environment
@rem ----------------------------------------------------------------------------

@rem Resolve script location
setlocal
set "DIRNAME=%~dp0"
if "%DIRNAME%"=="" set "DIRNAME=."
set "APP_HOME=%DIRNAME%"

@rem Determine NODE_HOME
if not defined NODE_HOME (
  where node >nul 2>&1
  if %errorlevel%==0 (
    for /f "delims=" %%i in ('where node') do set "NODE_EXE=%%i"
  ) else (
    echo Error: NODE_HOME is not set and 'node' could not be found in your PATH. >&2
    exit /b 1
  )
) else (
  set "NODE_EXE=%NODE_HOME%\node.exe"
)

@rem Hvigor wrapper script
set "HVIGOR_WRAPPER_SCRIPT=%APP_HOME%\hvigor\hvigor-wrapper.js"
if not exist "%HVIGOR_WRAPPER_SCRIPT%" (
  echo Error: Hvigor wrapper script not found at %HVIGOR_WRAPPER_SCRIPT% >&2
  exit /b 1
)

"%NODE_EXE%" --max-old-space-size=8192 "%HVIGOR_WRAPPER_SCRIPT%" %*
