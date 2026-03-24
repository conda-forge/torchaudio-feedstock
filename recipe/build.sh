#!/bin/bash
set -ex

if [[ ${cuda_compiler_version} != "None" ]]; then
  export CUDA_TOOLKIT_ROOT_DIR="${PREFIX}"
  export CUDA_HOME="${PREFIX}"
  if [[ ${cuda_compiler_version} == 12.9 ]]; then
    export TORCH_CUDA_ARCH_LIST="5.0;6.0;7.0;7.5;8.0;8.6;8.9;9.0;10.0;12.0+PTX"
  elif [[ ${cuda_compiler_version} == 13.0 ]]; then
    export TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6;8.9;9.0;10.0;11.0;12.0+PTX"
  else
    echo "unsupported cuda version. edit build.sh"
    exit 1
  fi

  if [[ "${target_platform}" != "${build_platform}" ]]; then
    export CUDA_TOOLKIT_ROOT=${PREFIX}
  fi

  case ${target_platform} in
    linux-64)
        CUDA_TARGET=x86_64-linux
        ;;
    linux-aarch64)
        if [[ "${arm_variant_type}" == "tegra" ]]; then
            CUDA_TARGET=aarch64-linux
        else
            CUDA_TARGET=sbsa-linux
        fi
        ;;
    *)
        echo "unknown CUDA arch, edit build.sh"
        exit 1
  esac

  # cicc is expected in the wrong directory for some reason
  ln -s ${BUILD_PREFIX}/nvvm/bin/cicc ${PREFIX}/bin/../targets/${CUDA_TARGET}/nvvm/bin/cicc

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

python -m pip install . -vv
