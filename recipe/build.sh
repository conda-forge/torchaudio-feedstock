#!/bin/bash
set -ex

# Tell setuptools-scm to use the exact recipe version (no "a0" suffix)
export SETUPTOOLS_SCM_PRETEND_VERSION="${version}"
export BUILD_VERSION="${version}"
export TORCHAUDIO_BUILD_VERSION="${version}"

if [[ ${cuda_compiler_version} != "None" ]]; then
  # Set the CUDA arch list from
  # https://github.com/conda-forge/pytorch-cpu-feedstock/blob/main/recipe/build_pytorch.sh
  if [[ ${cuda_compiler_version} == 11.8 ]]; then
    export TORCH_CUDA_ARCH_LIST="3.5;5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9+PTX"
    export CUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME
  elif [[ ${cuda_compiler_version} == 12.0 || ${cuda_compiler_version} == 12.6 || ${cuda_compiler_version} == 12.9 ]]; then
    export TORCH_CUDA_ARCH_LIST="5.0;6.0;6.1;7.0;7.5;8.0;8.6;8.9;9.0+PTX"
    # $CUDA_HOME not set in CUDA 12.0. Using $PREFIX
    export CUDA_TOOLKIT_ROOT_DIR="${PREFIX}"
    # CUDA_HOME must be set for the build to work in torchaudio
    export CUDA_HOME="${PREFIX}"
  else
    echo "unsupported cuda version. edit build.sh"
    exit 1
  fi

  if [[ "${target_platform}" != "${build_platform}" ]]; then
    export CUDA_TOOLKIT_ROOT=${PREFIX}
  fi

  export USE_CUDA=1
  export BUILD_CUDA_CTC_DECODER=1
else
  export USE_CUDA=0
  export BUILD_CUDA_CTC_DECODER=0
fi

export USE_ROCM=0
export USE_OPENMP=1
export BUILD_CPP_TEST=0

# sox is buggy
export BUILD_SOX=0

# FFMPEG is buggy
export USE_FFMPEG=0
# export FFMPEG_ROOT="${PREFIX}"

# RNNT loss is buggy
export BUILD_RNNT=0

export CMAKE_C_COMPILER="$CC"
export CMAKE_CXX_COMPILER="$CXX"
export CMAKE_GENERATOR="Ninja"

# ───────────────────────────────────────────────────────────────
# Cross-compile fix: strip host-CPU –march/–mtune flags that
# were injected when the x86_64 compilers activated.  They break
# the aarch64 tool-chain with "unknown architecture 'nocona'"
# once we switch to it.
# Applies only when build ≠ target platform.
# ───────────────────────────────────────────────────────────────
if [[ "${build_platform}" != "${target_platform}" ]]; then
  for var in CFLAGS CXXFLAGS CPPFLAGS; do
    tmp="$(eval echo \${${var}})"
    # Remove any "-march=FOO" or "-mtune=BAR" fragment
    tmp="${tmp//-march=[^ ]*/}"
    tmp="${tmp//-mtune=[^ ]*/}"
    eval export ${var}='"${tmp}"'
  done
fi

# -------------------------------------------------------------------------------
#   [build.sh diagnostics]                                         (added debug)
# -------------------------------------------------------------------------------
echo "==============================================="
echo "[build.sh diagnostics]"
echo "PREFIX               = ${PREFIX}"
echo "BUILD_PREFIX         = ${BUILD_PREFIX}"
echo "CUDA_HOME            = ${CUDA_HOME}"
echo "CUDA_TOOLKIT_ROOT_DIR= ${CUDA_TOOLKIT_ROOT_DIR}"
echo "nvcc (if any)        = $(command -v nvcc || echo 'nvcc not on PATH')"
echo "PATH                 = ${PATH}"
echo "==============================================="

python -m pip install . -v
