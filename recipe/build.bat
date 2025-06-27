@echo On
setlocal enabledelayedexpansion

if not "%cuda_compiler_version%" == "None" (
  rem Set the CUDA arch list from
  rem https://github.com/conda-forge/pytorch-cpu-feedstock/blob/main/recipe/build_pytorch.sh
  if "%cuda_compiler_version%" == "12.6" (
    set TORCH_CUDA_ARCH_LIST=5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX
    rem %CUDA_HOME% not set in CUDA 12.0. Using %PREFIX%
    set CUDA_TOOLKIT_ROOT_DIR=%PREFIX%
    rem CUDA_HOME must be set for the build to work in torchaudio
    set CUDA_HOME=%PREFIX%
    rem -----------------------------------------------------------------
    rem  CMake ≥3.26 looks for CUDAToolkit_ROOT and/or CUDACXX.
    rem  Expose both, in addition to the legacy CUDA_TOOLKIT_ROOT_DIR.
    rem -----------------------------------------------------------------
    set CUDAToolkit_ROOT=%CUDA_HOME%
    set CUDACXX=%CUDAToolkit_ROOT%\bin\nvcc.exe
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

if exist "%Torch_ROOT%\lib\torch_python.lib" (
    set "TORCH_PYTHON_LIBRARY=%Torch_ROOT%\lib\torch_python.lib"
    set "CMAKE_ARGS=%CMAKE_ARGS% -DTORCH_PYTHON_LIBRARY=%TORCH_PYTHON_LIBRARY%"
)
rem Tell CMake explicitly where to find the CUDA toolkit
set "CMAKE_ARGS=%CMAKE_ARGS% -DCUDAToolkit_ROOT=%CUDAToolkit_ROOT%"

rem Keep back‑slashes from being stripped by shlex:
set "CMAKE_ARGS=%CMAKE_ARGS:\=/%"

python -m pip install . -vv
