@echo On
setlocal enabledelayedexpansion

rem ════════════════════════════════════════════════════════════════════
rem Global Azure/conda-build verbosity
rem ════════════════════════════════════════════════════════════════════
@echo ON
set CONDA_BLD_DEBUG=3
set CONDA_BLD_VERBOSE=3
set MAMBA_NO_PROMPT=1

rem ════════════════════════════════════════════════════════════════════
rem Snapshot before we touch anything
rem ════════════════════════════════════════════════════════════════════
echo ========= RAW ENV (before) =========
set
echo ====================================

if not "%cuda_compiler_version%" == "None" (
  rem Set the CUDA arch list from
  rem https://github.com/conda-forge/pytorch-cpu-feedstock/blob/main/recipe/build_pytorch.sh
  if "%cuda_compiler_version%" == "12.6" (
    set "TORCH_CUDA_ARCH_LIST=5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"

    rem ────────────────────────────────────────────────────────────────
    rem CUDA toolkit discovery – conda‑forge layout (CUDA 12.6)
    rem   * nvcc.exe lives in  %PREFIX%\Library\bin
    rem   * CMake ≥3.26 honours        CUDAToolkit_ROOT  or  CUDACXX
    rem ────────────────────────────────────────────────────────────────
    rem Use delayed‑expansion so %PREFIX% is resolved *now*, not left
    rem literally in the value.  A literal "%PREFIX%" breaks CMake's
    rem CUDA compiler detection on Windows.
    set "CUDA_TOOLKIT_ROOT_DIR=!PREFIX!"
    set "CUDA_HOME=!PREFIX!"
    set "CUDAToolkit_ROOT=!PREFIX!"
    set "CUDACXX=!PREFIX!\Library\bin\nvcc.exe"

echo ========= CUDA DEBUG =========
echo cuda_compiler_version   = %cuda_compiler_version%
echo CUDA_TOOLKIT_ROOT_DIR   = %CUDA_TOOLKIT_ROOT_DIR%
echo CUDA_HOME               = %CUDA_HOME%
echo CUDAToolkit_ROOT        = %CUDAToolkit_ROOT%
echo CUDACXX                 = %CUDACXX%
echo USE_CUDA                = %USE_CUDA%
echo TORCH_CUDA_ARCH_LIST    = %TORCH_CUDA_ARCH_LIST%
where nvcc || echo "where nvcc -> NOT FOUND"
if exist "%CUDACXX%" (
  echo nvcc FOUND exactly where we expect
) else (
  echo nvcc **MISSING** at %CUDACXX%
  dir "%PREFIX%\Library\bin"
)
echo ==============================

  ) else (
    echo "unsupported cuda version. edit build.bat"
    exit /b 1
  )

  set USE_CUDA=1
  set BUILD_CUDA_CTC_DECODER=1
) else (
  set USE_CUDA=0
  set BUILD_CUDA_CTC_DECODER=0
)

set USE_ROCM=0
set USE_OPENMP=1
set BUILD_CPP_TEST=0

rem sox is buggy
set BUILD_SOX=0

rem FFMPEG is buggy
set USE_FFMPEG=0
rem set FFMPEG_ROOT="${PREFIX}"

rem RNNT loss is buggy
set BUILD_RNNT=0

set CMAKE_C_COMPILER=%CC%
set CMAKE_CXX_COMPILER=%CXX%
set CMAKE_GENERATOR=Ninja

set Torch_ROOT=%SP_DIR%\torch


rem ---------------------------------------------------------------------------
rem Fixes needed only on Windows
rem   1. torchaudio’s CMakeLists expects TORCH_PYTHON_LIBRARY to be defined,
rem      but recent PyTorch wheels no longer export it.  We point it at the
rem      import library that ships with PyTorch.
rem   2. The pyproject helper uses POSIX shlex to split %CMAKE_ARGS%; bare ‘\’
rem      characters are treated as escape sequences and are dropped.  Replace
rem      them with ‘/’ **after** CMAKE_ARGS is fully assembled.
rem ---------------------------------------------------------------------------

:: ---------------------------------------------------------------------------
:: Correctly *append* extra flags instead of replacing everything that
:: rattler‑build has already put into CMAKE_ARGS.  Always use delayed
:: expansion (!VAR!) so that %PREFIX% never survives into the final value.
:: ---------------------------------------------------------------------------

if exist "!Torch_ROOT!\lib\torch_python.lib" (
    set "TORCH_PYTHON_LIBRARY=!Torch_ROOT!\lib\torch_python.lib"
    set "CMAKE_ARGS=!CMAKE_ARGS! -DTORCH_PYTHON_LIBRARY=!TORCH_PYTHON_LIBRARY!"
)

if defined CUDAToolkit_ROOT (
    set "CMAKE_ARGS=!CMAKE_ARGS! -DCUDAToolkit_ROOT=!PREFIX!"
)

rem Convert back‑slashes to forward‑slashes once, at the very end.
set "CMAKE_ARGS=!CMAKE_ARGS:\=/!"

echo ================================================================================
echo   [build.bat diagnostics]
echo   PREFIX      = !PREFIX!
echo   BUILD_PREFIX= !BUILD_PREFIX!
echo   CUDACXX     = !CUDACXX!
if exist "!CUDACXX!" (
    echo   nvcc.exe FOUND at !CUDACXX!
) else (
    echo   ** WARNING: nvcc.exe NOT found at !CUDACXX!
    echo   Directory listing of !PREFIX!\Library\bin follows:
    dir /b "!PREFIX!\Library\bin"
)
echo   CMAKE_ARGS  = !CMAKE_ARGS!
echo ================================================================================

rem ── Crank CMake/Ninja verbosity to 11 ───────────────────────────────
set CMAKE_VERBOSE_MAKEFILE=ON
set CMAKE_FIND_DEBUG_MODE=1
set VERBOSE=1
set Ninja_FLAGS=-v
set "CMAKE_ARGS=!CMAKE_ARGS! -DCMAKE_VERBOSE_MAKEFILE=ON --debug-find"

python -m pip install . -vv

echo ========= RAW ENV (after) =========
set
echo ===================================
