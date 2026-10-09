#!/usr/bin/env bash
set -euo pipefail

CC=${1}
XXD=${2}
INPUT_FILE=${3}
OUTPUT_DIR=${4}
OUTPUT_FILENAME=${5}
LLVM_DIS=${6}
TARGET=${7:-}
SYSROOT=${8:-}

BC_FILENAME="$(basename "${INPUT_FILE}").bc"
FLAGS=()
if [[ -n "${TARGET}" ]]; then
    FLAGS+=("--target=${TARGET}")
fi
if [[ -n "${SYSROOT}" ]]; then
    FLAGS+=("--sysroot=${SYSROOT}")
fi

cd "${OUTPUT_DIR}"
"${CC}" "${FLAGS[@]}" -Os -emit-llvm -c "${INPUT_FILE}" -o "${BC_FILENAME}"
EXPECTED_TARGET=$("${CC}" "${FLAGS[@]}" -print-effective-triple)
ACTUAL_TARGET=$("${LLVM_DIS}" "${BC_FILENAME}" -o - | sed -n 's/^target triple = "\(.*\)"/\1/p')
if [[ "${ACTUAL_TARGET}" != "${EXPECTED_TARGET}" ]]; then
    echo "Decoder target mismatch: expected ${EXPECTED_TARGET}, got ${ACTUAL_TARGET}" >&2
    exit 1
fi
"${XXD}" -i "${BC_FILENAME}" > "${OUTPUT_FILENAME}"
