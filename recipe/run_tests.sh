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

###############################################################################
# Build the long -k skip expression **robustly on Windows**.
# Newlines inside a single-quoted string break pytest's mini-parser when the
# script runs under Git-Bash, producing "expected right parenthesis" errors.
# The fix:
#   1.  Put the list in a here-doc (readable in-source).
#   2.  Collapse all whitespace to single spaces.
#   3.  Feed the one-liner to pytest.
###############################################################################
SKIP="$(cat <<'EOF'
test_cmuarctic_str or test_cmuarctic_path or test_unknown_subtype_warning
or test_pretrain_torchscript_1_wav2vec2_large or test_finetune_torchscript_1_wav2vec2_large
or test_waveform or TestWaveRNN
or test_quantize_torchscript_2_wav2vec2_large_lv60k or test_quantize_torchscript_1_wav2vec2_large
or test_pitch_shift_resample_kernel or test_PitchShift or test_oscillator_bank
or test_paper_configuration or test_pitch_shift_shape__4 or test_pitch_shift_shape_2
or test_souden_mvdr or test_rtf_mvdr or test_mvdr_0_ref_channel or test_masking_iid
or wavlm_large or hubert_pretrain_xlarge or hubert_pretrain_large
or hubert_xlarge or hubert_large or test_forced_align or test_create_mel
or test_simulate_rir or ray_tracing or rnnt or test_deemphasis or TestAutogradLfilterCPU
EOF
)"
# Flatten the whitespace/newlines.
SKIP="$(echo "${SKIP}" | tr -s '[:space:]' ' ')"

# Extra skips for Windows + CUDA (the ones that SIGABRT)
if [[ "${target_platform}" == "win-64" && "${cuda_compiler_version}" != "None" ]]; then
    SKIP="${SKIP} or test_pretrain_torchscript_2_wav2vec2_large_lv60k or test_finetune_torchscript_2_wav2vec2_large_lv60k"
fi

pytest -v test/torchaudio_unittest/ -k "not (${SKIP})"
