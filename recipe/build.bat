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

python -m pip install . -vv
