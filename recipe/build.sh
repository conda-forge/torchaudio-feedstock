#!/bin/bash
set -ex

if [[ ${cuda_compiler_version} != "None" ]]; then
  export CUDA_TOOLKIT_ROOT_DIR="${PREFIX}"
  export CUDA_HOME="${PREFIX}"
  export TORCH_CUDA_ARCH_LIST="${CF_TORCH_CUDA_ARCH_LIST}"

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

python -m pip install . -vv --no-deps --no-build-isolation
