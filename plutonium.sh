#!/bin/sh

# This patch script is for use with the felddy/foundryvtt Docker container.
# See: https://github.com/felddy/foundryvtt-docker#readme

# Installs the Plutonium module if it is not yet installed, and then patches the
# Foundry server to call the Plutonium backend.

MAIN_JS="${FOUNDRY_HOME}/resources/app/main.mjs"
MODULE_BACKEND_JS="/data/Data/modules/plutonium/server/v9/plutonium-backend.mjs"
MODULE_DIR="/data/Data/modules"
MODULE_URL="https://github.com/TheGiddyLimit/plutonium-next/raw/master/plutonium-foundry9.zip"
MODULE_DOC_URL="https://wiki.5e.tools/index.php/FoundryTool_Install"
SUPPORTED_VERSIONS="9.269"
WORKDIR=$(mktemp -d)
ZIP_FILE="${WORKDIR}/plutonium.zip"

log "Installing Plutonium module and backend."
log "See: ${MODULE_DOC_URL}"
if [ -z "${SUPPORTED_VERSIONS##*$FOUNDRY_VERSION*}" ] ; then
  log "This patch has been tested with Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
else
  log_warn "This patch has not been tested with Foundry Virtual Tabletop ${FOUNDRY_VERSION}"
fi
if [ ! -f $MODULE_BACKEND_JS ]; then
  log "Downloading Plutonium module."
  curl -LJo "${ZIP_FILE}" "${MODULE_URL}" 2>&1 | tr "\r" "\n"
  log "Ensuring module directory exists."
  mkdir -p "${MODULE_DIR}"
  log "Installing Plutonium module."
  unzip -o "${ZIP_FILE}" -d "${MODULE_DIR}"
fi
log "Installing Plutonium backend."
cp "${MODULE_BACKEND_JS}" "${FOUNDRY_HOME}/resources/app/"
log "Patching main.js to use plutonium-backend."
sed --file=- --in-place=.orig ${MAIN_JS} << SED_SCRIPT
s/})();/;\n(await import(\".\/plutonium-backend.mjs\")).Plutonium.init();\n})();/;
s/init.default/await init.default/
w plutonium_patchlog.txt
SED_SCRIPT
if [ -s plutonium_patchlog.txt ]; then
  log "Plutonium backend patch was applied successfully."
  log "Plutonium art and media tools will be enabled."
else
  log_error "Plutonium backend patch could not be applied."
  log_error "main.js did not contain the expected source lines."
  log_warn "Foundry Virtual Tabletop will still operate without the art and media tools enabled."
  log_warn "Update this patch file to a version that supports Foundry Virtual Tabletop ${FOUNDRY_VERSION}."
fi
log "Cleaning up."
rm -r ${WORKDIR}
