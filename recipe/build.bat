@echo On
setlocal enabledelayedexpansion

rem Set BUILD_VERSION to prevent setup.py from using a git-describe-based alpha version
set BUILD_VERSION=%version%

rem ================================================================================
rem   [initial build.bat diagnostics]                         (added for debugging)
rem ================================================================================
echo ================================================================================
echo   BUILD SCRIPT           : %~f0
echo   PREFIX                 : %PREFIX%
echo   BUILD_PREFIX           : %BUILD_PREFIX%
echo   cuda_compiler_version  : %cuda_compiler_version%
echo   CONDA_BUILD_VARIANT    : %CONDA_BUILD_VARIANT%
echo   PATH                   : %PATH%
echo ================================================================================

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
    rem CUDA Toolkit files (including nvcc.exe) live in %PREFIX%\Library on Windows
    set "CUDA_TOOLKIT_ROOT_DIR=!PREFIX!\Library"
    set "CUDA_HOME=!PREFIX!\Library"
    set "CUDAToolkit_ROOT=!PREFIX!\Library"

    rem --------------------------------------------------------------------------
    rem Locate nvcc.exe.  On win‑64 the cuda‑nvcc package now places it in
    rem   %PREFIX%\bin\nvcc.exe        (current layout)
    rem but older layouts used
    rem   %PREFIX%\Library\bin\nvcc.exe
    rem We pick whichever exists; otherwise we leave CUDACXX *unset* so that
    rem CMake can fall back to its own discovery logic instead of dying on a
    rem bogus path.                                               (added for fix)
    rem --------------------------------------------------------------------------

    set "CUDACXX_CANDIDATE_1=!PREFIX!\bin\nvcc.exe"
    set "CUDACXX_CANDIDATE_2=!PREFIX!\bin\nvcc.bat"
    set "CUDACXX_CANDIDATE_3=!PREFIX!\Library\bin\nvcc.exe"
    set "CUDACXX_CANDIDATE_4=!PREFIX!\Library\bin\nvcc.bat"

    rem Assume the CUDA CTC decoder will be built; may be disabled below
    set BUILD_CUDA_CTC_DECODER=1

    rem Search all candidates – the first match wins, no labels required
    for %%f in ("!CUDACXX_CANDIDATE_1!" "!CUDACXX_CANDIDATE_2!" ^
                "!CUDACXX_CANDIDATE_3!" "!CUDACXX_CANDIDATE_4!") do (
        if not defined CUDACXX (
            if exist "%%~f" set "CUDACXX=%%~f"
        )
    )

    rem ------------------------------------------------------------------
    rem Cross-compile or exotic envs: nvcc might be on BUILD_PREFIX or PATH
    rem ------------------------------------------------------------------
    if not defined CUDACXX (
        if exist "!BUILD_PREFIX!\bin\nvcc.exe" set "CUDACXX=!BUILD_PREFIX!\bin\nvcc.exe"
    )
    if not defined CUDACXX (
        for %%i in (nvcc.exe) do (
            set "NVCC_ON_PATH=%%~$PATH:i"
            if not "!NVCC_ON_PATH!"=="" set "CUDACXX=!NVCC_ON_PATH!"
        )
    )

    rem Graceful degradation – skip the CUDA CTC decoder when nvcc is absent
    if not defined CUDACXX (
        echo "nvcc not found – disabling BUILD_CUDA_CTC_DECODER"
        set BUILD_CUDA_CTC_DECODER=0
    )
  ) else (
    echo "unsupported cuda version. edit build.bat"
    exit /b 1
  )

  set USE_CUDA=1
  rem Keep BUILD_CUDA_CTC_DECODER as computed above (0 or 1)
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
rem   1. torchaudio's CMakeLists expects TORCH_PYTHON_LIBRARY to be defined,
rem      but recent PyTorch wheels no longer export it.  We point it at the
rem      import library that ships with PyTorch.
rem   2. The pyproject helper uses POSIX shlex to split %CMAKE_ARGS%; bare '\'
rem      characters are treated as escape sequences and are dropped.  Replace
rem      them with '/' **after** CMAKE_ARGS is fully assembled.
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
    set "CMAKE_ARGS=!CMAKE_ARGS! -DCUDAToolkit_ROOT=!CUDAToolkit_ROOT!"
)

rem ---------------------------------------------------------------------------
rem Increase stack size to prevent deep-recursion segfaults on Windows.
rem 16 MB is the value used by other large C++ projects (e.g. onnxruntime).
rem Apply to EXE, SHARED, and MODULE links.
rem ---------------------------------------------------------------------------
set "CMAKE_ARGS=!CMAKE_ARGS! -DCMAKE_EXE_LINKER_FLAGS=/STACK:16000000 -DCMAKE_SHARED_LINKER_FLAGS=/STACK:16000000 -DCMAKE_MODULE_LINKER_FLAGS=/STACK:16000000"

rem Convert back‑slashes to forward‑slashes once, at the very end.
set "CMAKE_ARGS=!CMAKE_ARGS:\=/!"

echo ================================================================================
echo   [build.bat diagnostics]
echo   PREFIX      = !PREFIX!
echo   BUILD_PREFIX= !BUILD_PREFIX!
echo   CUDACXX     = !CUDACXX!
echo   USE_CUDA    = !USE_CUDA!
echo   BUILD_CUDA_CTC_DECODER = !BUILD_CUDA_CTC_DECODER!
echo   CUDAToolkit_ROOT = !CUDAToolkit_ROOT!
echo   CUDA_HOME   = !CUDA_HOME!
echo   TORCH_CUDA_ARCH_LIST = !TORCH_CUDA_ARCH_LIST!
rem ───────────────────────────────────────────────────────────────
rem Better diagnostics: tell "variable unset" apart from
rem "variable set but file missing", so the path in the message
rem is never blank.
rem ───────────────────────────────────────────────────────────────
if defined CUDACXX (
    if exist "!CUDACXX!" (
        echo   nvcc.exe FOUND at !CUDACXX!
    ) else (
        echo   ** WARNING: nvcc.exe NOT found at !CUDACXX!
        echo   Directory listing of !PREFIX!\bin follows:
        dir /b "!PREFIX!\bin"
        echo   Directory listing of !PREFIX!\Library\bin follows:
        dir /b "!PREFIX!\Library\bin"
    )
) else (
    echo   ** WARNING: nvcc.exe NOT found ^(CUDACXX variable not set^)
    echo   Directory listing of !PREFIX!\bin follows:
    dir /b "!PREFIX!\bin"
    echo   Directory listing of !PREFIX!\Library\bin follows:
    dir /b "!PREFIX!\Library\bin"
)
echo   CMAKE_ARGS  = !CMAKE_ARGS!
echo ================================================================================

python -m pip install . -v
