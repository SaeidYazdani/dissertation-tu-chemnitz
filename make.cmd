@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
cd /d "%ROOT%" || (
  echo ERROR: Could not enter script directory: %ROOT%
  exit /b 1
)

set "TOOL=latexmk"
set "ACTION=build"
set "PARALLEL=1"
set "MAKE_JOBS=%NUMBER_OF_PROCESSORS%"
if not defined MAKE_JOBS set "MAKE_JOBS=1"

call :parse_args %*
if errorlevel 1 exit /b 1

if /I "%ACTION%"=="help" (
  call :show_help
  exit /b 0
)

echo == Thesis handover build ==
echo Working directory: %CD%
echo Tool: %TOOL%
echo Action: %ACTION%

if /I "%ACTION%"=="clean" (
  call :clean_aux
  exit /b %ERRORLEVEL%
)

if /I "%ACTION%"=="full-clean" (
  call :full_clean
  exit /b %ERRORLEVEL%
)

if /I "%ACTION%"=="rebuild" (
  call :full_clean
  if errorlevel 1 exit /b 1
)

call :require_common_tools
if errorlevel 1 exit /b 1

set "LATEXMK_FLAGS=-pdf -file-line-error -interaction=nonstopmode -synctex=1"
set "LATEXMK_MAKE_FLAGS="
if "%PARALLEL%"=="1" call :configure_make_acceleration

call :ensure_dirs
if errorlevel 1 exit /b 1

call :build_titlepages
if errorlevel 1 exit /b %ERRORLEVEL%

echo.
echo == Building dissertation ==
call :build_document main.tex out
if errorlevel 1 (
  echo ERROR: Dissertation build failed.
  exit /b %ERRORLEVEL%
)

echo.
echo Build complete: %CD%\out\main.pdf
exit /b 0

:parse_args
if "%~1"=="" exit /b 0
if /I "%~1"=="-h" set "ACTION=help" & shift & goto :parse_args
if /I "%~1"=="--help" set "ACTION=help" & shift & goto :parse_args
if /I "%~1"=="/?" set "ACTION=help" & shift & goto :parse_args
if /I "%~1"=="help" set "ACTION=help" & shift & goto :parse_args

if /I "%~1"=="clean" set "ACTION=clean" & shift & goto :parse_args
if /I "%~1"=="--clean" set "ACTION=clean" & shift & goto :parse_args
if /I "%~1"=="/clean" set "ACTION=clean" & shift & goto :parse_args

if /I "%~1"=="full-clean" set "ACTION=full-clean" & shift & goto :parse_args
if /I "%~1"=="--full-clean" set "ACTION=full-clean" & shift & goto :parse_args
if /I "%~1"=="--clean-all" set "ACTION=full-clean" & shift & goto :parse_args
if /I "%~1"=="/full-clean" set "ACTION=full-clean" & shift & goto :parse_args

if /I "%~1"=="rebuild" set "ACTION=rebuild" & shift & goto :parse_args
if /I "%~1"=="--rebuild" set "ACTION=rebuild" & shift & goto :parse_args
if /I "%~1"=="/rebuild" set "ACTION=rebuild" & shift & goto :parse_args

if /I "%~1"=="--no-parallel" set "PARALLEL=0" & shift & goto :parse_args
if /I "%~1"=="/no-parallel" set "PARALLEL=0" & shift & goto :parse_args

if /I "%~1"=="--jobs" (
  if "%~2"=="" echo ERROR: --jobs requires a number. & exit /b 1
  set "MAKE_JOBS=%~2"
  shift
  shift
  goto :parse_args
)
set "ARG=%~1"
if /I "%ARG:~0,7%"=="--jobs=" (
  set "MAKE_JOBS=%ARG:~7%"
  shift
  goto :parse_args
)
if /I "%~1"=="/jobs" (
  if "%~2"=="" echo ERROR: /jobs requires a number. & exit /b 1
  set "MAKE_JOBS=%~2"
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--tool" (
  if "%~2"=="" echo ERROR: --tool requires latexmk or pdflatex. & exit /b 1
  set "TOOL=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%ARG:~0,7%"=="--tool=" (
  set "TOOL=%ARG:~7%"
  shift
  goto :parse_args
)
if /I "%~1"=="/tool" (
  if "%~2"=="" echo ERROR: /tool requires latexmk or pdflatex. & exit /b 1
  set "TOOL=%~2"
  shift
  shift
  goto :parse_args
)

echo ERROR: Unknown argument: %~1
echo Run make.cmd --help for usage.
exit /b 1

:show_help
echo Usage:
echo   make.cmd [options]
echo.
echo Default:
echo   make.cmd
echo     Build title pages and dissertation using latexmk.
echo.
echo Actions:
echo   --clean, /clean            Remove auxiliary build files, keep PDFs.
echo   --full-clean, /full-clean  Remove the out directory and generated title-page PDF.
echo   --rebuild, /rebuild        Full clean, then build.
echo   --help, -h, /?             Show this help.
echo.
echo Tool selection:
echo   --tool latexmk             Use latexmk dependency tracking. Default.
echo   --tool pdflatex            Run pdflatex + biber + pdflatex + pdflatex directly.
echo.
echo Build tuning:
echo   --jobs N, /jobs N          Use N jobs for make-backed dependency generation.
echo   --no-parallel              Disable latexmk -use-make and MAKEFLAGS.
echo.
echo Examples:
echo   make.cmd --rebuild
echo   make.cmd --tool pdflatex
echo   make.cmd --jobs 8
exit /b 0

:require_common_tools
if /I "%TOOL%"=="latexmk" (
  call :require_tool latexmk
  if errorlevel 1 exit /b 1
) else if /I "%TOOL%"=="pdflatex" (
  call :require_tool pdflatex
  if errorlevel 1 exit /b 1
) else (
  echo ERROR: Unsupported tool "%TOOL%". Use latexmk or pdflatex.
  exit /b 1
)
call :require_tool biber
if errorlevel 1 exit /b 1
exit /b 0

:require_tool
where "%~1" >nul 2>nul
if errorlevel 1 (
  echo ERROR: Required command not found on PATH: %~1
  exit /b 1
)
exit /b 0

:configure_make_acceleration
where make >nul 2>nul
if errorlevel 1 (
  echo Parallel dependency builds unavailable: make not found; using normal latexmk mode.
  exit /b 0
)
set "MAKEFLAGS=-j%MAKE_JOBS% %MAKEFLAGS%"
set "LATEXMK_MAKE_FLAGS=-use-make"
echo Parallel dependency builds enabled via make -j%MAKE_JOBS%.
exit /b 0

:ensure_dirs
if not exist out mkdir out
if errorlevel 1 (
  echo ERROR: Could not create output directory: out
  exit /b 1
)
if not exist out\tuc-titlepages mkdir out\tuc-titlepages
if errorlevel 1 (
  echo ERROR: Could not create output directory: out\tuc-titlepages
  exit /b 1
)
exit /b 0

:build_titlepages
echo.
echo == Building TUC title pages ==
pushd frontmatter || (
  echo ERROR: Could not enter frontmatter directory.
  exit /b 1
)
call :build_document univerlag_publisher_filler.tex ..\out\tuc-titlepages
if errorlevel 1 (
  popd
  echo ERROR: TUC titlepage build failed.
  exit /b 1
)
popd
call :copy_if_changed out\tuc-titlepages\univerlag_publisher_filler.pdf frontmatter\univerlag_publisher_filler.pdf
if errorlevel 1 exit /b 1
exit /b 0

:build_document
set "SOURCE=%~1"
set "OUTDIR=%~2"
set "STEM=%~n1"
if /I "%TOOL%"=="latexmk" (
  latexmk %LATEXMK_FLAGS% %LATEXMK_MAKE_FLAGS% -outdir="%OUTDIR%" "%SOURCE%"
  exit /b %ERRORLEVEL%
)
pdflatex -file-line-error -interaction=nonstopmode -synctex=1 -output-directory="%OUTDIR%" "%SOURCE%"
call :accept_pdf_or_fail "%OUTDIR%\%STEM%.pdf"
if errorlevel 1 exit /b 1
if exist "%OUTDIR%\%STEM%.bcf" (
  biber "%OUTDIR%\%STEM%"
  if errorlevel 1 exit /b %ERRORLEVEL%
)
pdflatex -file-line-error -interaction=nonstopmode -synctex=1 -output-directory="%OUTDIR%" "%SOURCE%"
call :accept_pdf_or_fail "%OUTDIR%\%STEM%.pdf"
if errorlevel 1 exit /b 1
pdflatex -file-line-error -interaction=nonstopmode -synctex=1 -output-directory="%OUTDIR%" "%SOURCE%"
call :accept_pdf_or_fail "%OUTDIR%\%STEM%.pdf"
if errorlevel 1 exit /b 1
echo Direct pdflatex build complete for %SOURCE%.
exit /b 0

:accept_pdf_or_fail
if not errorlevel 1 exit /b 0
if exist "%~1" (
  echo WARNING: pdflatex returned a nonzero status, but produced %~1.
  exit /b 0
)
exit /b 1

:copy_if_changed
set "SRC=%~1"
set "DST=%~2"
if not exist "%SRC%" (
  echo ERROR: Missing build output: %SRC%
  exit /b 1
)
if not exist "%DST%" (
  copy /Y "%SRC%" "%DST%" >nul
  exit /b %ERRORLEVEL%
)
fc /B "%SRC%" "%DST%" >nul
if errorlevel 1 (
  copy /Y "%SRC%" "%DST%" >nul
  if errorlevel 1 exit /b 1
  exit /b 0
)
echo TUC titlepage PDF unchanged; keeping existing frontmatter copy.
exit /b 0

:clean_aux
echo == Cleaning auxiliary files ==
if exist out (
  if /I "%TOOL%"=="latexmk" (
    latexmk -c -outdir=out main.tex
    if exist out\tuc-titlepages (
      pushd frontmatter
      latexmk -c -outdir=..\out\tuc-titlepages univerlag_publisher_filler.tex
      popd
    )
  ) else (
    del /Q out\*.aux out\*.bbl out\*.bcf out\*.blg out\*.fdb_latexmk out\*.fls out\*.glo out\*.log out\*.out out\*.run.xml out\*.synctex.gz out\*.toc 2>nul
    del /Q out\tuc-titlepages\*.aux out\tuc-titlepages\*.fdb_latexmk out\tuc-titlepages\*.fls out\tuc-titlepages\*.log out\tuc-titlepages\*.out out\tuc-titlepages\*.synctex.gz 2>nul
  )
)
echo Clean complete.
exit /b 0

:full_clean
echo == Full clean ==
if exist out rmdir /S /Q out
if exist frontmatter\univerlag_publisher_filler.pdf del /Q frontmatter\univerlag_publisher_filler.pdf
echo Full clean complete.
exit /b 0
