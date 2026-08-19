@echo on
setlocal

if "%cuda_compiler_version%" == "None" (
  set USE_CUDA=0
  set BUILD_CUDA_CTC_DECODER=0
) else (
  set CUDA_TOOLKIT_ROOT_DIR=%LIBRARY_PREFIX%
  set CUDA_HOME=%LIBRARY_PREFIX%

  if "%cuda_compiler_version:~0,2%"=="12" (
    set "TORCH_CUDA_ARCH_LIST=5.0;6.0;7.0;7.5;8.0;8.6;9.0;10.0;12.0+PTX"
  ) else if "%cuda_compiler_version%" == "13.0" (
    set "TORCH_CUDA_ARCH_LIST=7.5;8.0;8.6;9.0;10.0;11.0;12.0+PTX"
     REM c.f. https://github.com/pytorch/pytorch/pull/161316
    set "TORCH_NVCC_FLAGS=!TORCH_NVCC_FLAGS! -compress-mode=size"
  ) else (
     echo "unsupported cuda version. edit build_pytorch.bat"
     exit /b 1
  )
  set USE_CUDA=1
  set BUILD_CUDA_CTC_DECODER=1
)

set USE_ROCM=0
set USE_OPENMP=1
set BUILD_CPP_TEST=0
set BUILD_SOX=0
set USE_FFMPEG=0
set BUILD_RNNT=0

python -m pip install . -vv --no-deps --no-build-isolation
