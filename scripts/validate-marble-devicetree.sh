#!/usr/bin/env bash
set -euo pipefail

source config/marble.env
KERNEL_DIR="${KERNEL_DIR:-kernel-source}"
VENDOR_DTS="${KERNEL_DIR}/arch/arm64/boot/dts/vendor"

DTS_MAKEFILE="${KERNEL_DIR}/arch/arm64/boot/dts/Makefile"
if [[ ! -s "${DTS_MAKEFILE}" ]] || ! grep -Fq 'vendor := $(dtstree)/vendor' "${DTS_MAKEFILE}" || ! grep -Fq '$(vendor)/Makefile' "${DTS_MAKEFILE}"; then
  echo "::error::Kernel DTS Makefile does not expose the expected vendor tree integration hook"
  exit 1
fi

required=(
  "${VENDOR_DTS}/Makefile"
  "${VENDOR_DTS}/qcom/Makefile"
  "${VENDOR_DTS}/qcom/ukee.dts"
  "${VENDOR_DTS}/qcom/ukee.dtsi"
  "${VENDOR_DTS}/qcom/marble-sm7475-pm8008-overlay.dts"
)
for path in "${required[@]}"; do
  if [[ ! -s "${path}" ]]; then
    echo "::error::Marble Device Tree file missing: ${path}"
    exit 1
  fi
done

if ! grep -Fq 'marble-sm7475-pm8008-overlay.dtbo' "${VENDOR_DTS}/qcom/Makefile"; then
  echo "::error::External Device Tree Makefile does not declare the Marble SM7475 overlay"
  exit 1
fi
if ! grep -Fq 'marble-sm7475-pm8008-overlay.dtbo-base := ukee.dtb' "${VENDOR_DTS}/qcom/Makefile"; then
  echo "::error::Marble overlay base declaration is missing or changed"
  exit 1
fi

if git -C "${VENDOR_DTS}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Marble Device Tree checkout: $(git -C "${VENDOR_DTS}" rev-parse HEAD)"
fi
echo "Verified external Marble/SM7475 Device Tree source at ${VENDOR_DTS}"
