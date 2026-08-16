#!/data/data/com.termux/files/usr/bin/bash
# Re-pin @whiskeysockets/baileys to 7.0.0-rc12 for the global openclaw install.
# Fixes GHSA-qvv5-jq5g-4cgg (apply again after any `npm update -g openclaw`).
set -euo pipefail

version="7.0.0-rc12"
npm install -g "@whiskeysockets/baileys@${version}"

root="${PREFIX}/lib/node_modules/openclaw"
nested="${root}/node_modules/@whiskeysockets/baileys"
global_wa="${PREFIX}/lib/node_modules/@whiskeysockets/baileys"

rm -rf "${nested}"
mkdir -p "$(dirname "${nested}")"
cp -r "${global_wa}" "${nested}"

node -e "console.log('nested baileys =', require('${nested}/package.json').version)"
