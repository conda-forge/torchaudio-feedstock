#!/bin/bash
set -ex

# ────────────────────────────────────────────────────────────────
# Detect Windows so we can apply OS-specific skips only when
# needed.  Works under Git-Bash/MSYS and CMD-spawned bash.
# ────────────────────────────────────────────────────────────────
IS_WINDOWS=0
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OS" == "Windows_NT" ]]; then
  IS_WINDOWS=1
fi

export CI=true

export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CMD_APPLY_CMVN_SLIDING="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CMD_COMPUTE_FBANK_FEATS="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CMD_COMPUTE_KALDI_PITCH_FEATS="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CMD_COMPUTE_MFCC_FEATS="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CMD_COMPUTE_SPECTROGRAM_FEATS="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_KALDI="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CUDA="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_HW_ACCEL="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_ON_PYTHON_310="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_AUDIO_OUT_DEVICE="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_MACOS="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_TEMPORARY_DISABLED="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_SOX_DECODER="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_SOX_ENCODER="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_CTC_DECODER="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_MOD_demucs="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_MOD_fairseq="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_QUANTIZATION="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_RIR="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_FFMPEG="true"
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_SOX="true"

## OVERVIEW OF SKIPPED TESTS

# Output 0 of UnbindBackward0 is a view and is being modified inplace.
# This view is the output of a function that returns multiple views.
# Such functions do not allow the output views to be modified inplace.
# You should replace the inplace operation by an out-of-place one.
tests_to_skip="TestAutogradLfilterCPU"
tests_to_skip="test_deemphasis or ${tests_to_skip}"

# 'torchaudio' object has no attribute 'rnnt_loss'
tests_to_skip="rnnt or ${tests_to_skip}"

# 'torchaudio' object has no attribute 'ray_tracing'
tests_to_skip="ray_tracing or ${tests_to_skip}"

# object has no attribute _simulate_rir:
tests_to_skip="test_simulate_rir or ${tests_to_skip}"

# ValueError: invalid version number '0.10.2.post1'
tests_to_skip="test_create_mel or ${tests_to_skip}"

# RuntimeError: torchaudio.functional._alignment.forced_align Requires alignment extension, but TorchAudio is not compiled with it.
# Please build TorchAudio with alignment support.
tests_to_skip="test_forced_align or ${tests_to_skip}"

# Very slow on CI:
tests_to_skip="hubert_large or ${tests_to_skip}"
tests_to_skip="hubert_xlarge or ${tests_to_skip}"
tests_to_skip="hubert_pretrain_large or ${tests_to_skip}"
tests_to_skip="hubert_pretrain_xlarge or ${tests_to_skip}"
tests_to_skip="wavlm_large or ${tests_to_skip}"
tests_to_skip="test_masking_iid or ${tests_to_skip}"
tests_to_skip="test_mvdr_0_ref_channel or ${tests_to_skip}"
tests_to_skip="test_rtf_mvdr or ${tests_to_skip}"
tests_to_skip="test_souden_mvdr or ${tests_to_skip}"

# Segfault on CI (probably due to limited memory):
tests_to_skip="test_pitch_shift_shape_2 or ${tests_to_skip}"
tests_to_skip="test_paper_configuration or ${tests_to_skip}"
tests_to_skip="test_oscillator_bank or ${tests_to_skip}"
tests_to_skip="test_PitchShift or ${tests_to_skip}"
tests_to_skip="test_pitch_shift_resample_kernel or ${tests_to_skip}"
tests_to_skip="test_quantize_torchscript_1_wav2vec2_large or ${tests_to_skip}"
tests_to_skip="test_quantize_torchscript_2_wav2vec2_large_lv60k or ${tests_to_skip}"

# AssertionError: assert 2 == 1 (caused by `FutureWarning: functools.partial` in Python 3.13)
tests_to_skip="test_unknown_subtype_warning or ${tests_to_skip}"

# ValueError: bad delimiter value (in Python 3.13)
tests_to_skip="test_cmuarctic_path or ${tests_to_skip}"
tests_to_skip="test_cmuarctic_str or ${tests_to_skip}"

# Additional skips not in upstream:

# Reason unknown, but historically skipped:
tests_to_skip="test_pretrain_torchscript_1_wav2vec2_large or ${tests_to_skip}"
tests_to_skip="test_finetune_torchscript_1_wav2vec2_large or ${tests_to_skip}"
tests_to_skip="test_waveform or ${tests_to_skip}"
tests_to_skip="TestWaveRNN or ${tests_to_skip}"
tests_to_skip="test_pitch_shift_shape__4 or ${tests_to_skip}"

# OOM on **Windows** CI: these tests load a 480 MB wav2vec2-large checkpoint
# and quantize it, pushing RAM to ~3 GB.  The Azure win-64 runner crashes
# (0xC0000005).  They still run on Linux/macOS, where RAM is sufficient.
if [[ "${IS_WINDOWS}" == 1 ]]; then
    tests_to_skip="test_quantize_0_wav2vec2_large or ${tests_to_skip}"
    tests_to_skip="test_quantize_1_wav2vec2_large or ${tests_to_skip}"

    # ---------------------------------------------------------------------
    # WavLM-Base TorchScript still trips a stack-overflow (0xC0000005)
    # on Azure Windows runners with PyTorch 2.5/CUDA 12.6.  Skip only the
    # two TorchScript cases; keep the rest of TestWavLMModel running.  #32
    # ---------------------------------------------------------------------
    tests_to_skip="test_finetune_torchscript_0_wavlm_base or ${tests_to_skip}"
    tests_to_skip="test_pretrain_torchscript_0_wavlm_base or ${tests_to_skip}"

    # -------------------------------------------------------------------------
    # Windows-only segfault (0xC0000005) in Emformer attention path triggered by
    #   TestSSLModel::test_extract_feature_{0,1}
    # Even with the larger stack, keep this skip as a safety-net on CI.       #32
    # -------------------------------------------------------------------------
    tests_to_skip="TestSSLModel or ${tests_to_skip}"
fi

# -------------------------------------------------------------------------
# Windows-only segfault (0xC0000005) in Conformer-Wav2Vec2 CPU smoke tests.
# Skip as a safety-net until upstream kernel fix lands, even with the
# larger link-time stack.                                      torchaudio-feedstock#32
# -------------------------------------------------------------------------
if [[ "${IS_WINDOWS}" == 1 ]]; then
    tests_to_skip="TestConformerWav2Vec2 or conformer_wav2vec2_test or ${tests_to_skip}"
fi

# ── Windows-specific skips ────────────────────────────────────────────────
# wav2vec2-Large-LV60k TorchScript tests blow up Azure's Windows runners
# (stack-overflow / OOM).  Skip them on every Windows build (CPU *and* CUDA).
if [[ "${IS_WINDOWS}" == 1 ]]; then
    tests_to_skip="${tests_to_skip} or test_pretrain_torchscript_2_wav2vec2_large_lv60k or test_finetune_torchscript_2_wav2vec2_large_lv60k"
fi

# Flatten newlines so pytest -k parses cleanly
tests_to_skip=$(echo "${tests_to_skip}" | tr -s ' ' | tr -d $'\n')

pytest -k "not (${tests_to_skip})" -vv test/torchaudio_unittest/
