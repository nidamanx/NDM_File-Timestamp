#!/usr/bin/env bash
# ---------------------------------------------------------------- APP INFO ----
# Edit these lines to rename the tool or publish a new release.
APP_NAME="NDM File Timestamp"
APP_DESCRIPTION="Proves that a file existed, unchanged, at a given time, with RFC 3161 \
timestamps from several independent Time Stamping Authorities."
APP_AUTHOR="Nicola Davide Mannarelli (@nidamanx)"
APP_VERSION="1.6.0"
APP_RELEASE_DATE="2026-10-28"
APP_COPYRIGHT="Copyright (C) 2023-2026 Nicola Davide Mannarelli (@nidamanx)"
APP_LICENSE="AGPL-3.0-or-later"
APP_URL="https://github.com/nidamanx/NDM_File-Timestamp"
# ------------------------------------------------------------------------------
#
# Copyright (C) 2023-2026  Nicola Davide Mannarelli (@nidamanx)
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# The full license text is in the LICENSE file distributed with this script.
#
# DISCLAIMER
# This software is provided "as is", without warranty of any kind, express or
# implied. In no event shall the author be liable for any claim, damages or other
# liability, including loss of data, timestamps not obtained, proofs that cannot be
# verified or that are not accepted as evidence, arising from the use or misuse of
# this software. You alone are responsible for how you use it, for keeping your files
# and their proofs, and for any decision taken on the basis of its results.
# ------------------------------------------------------------------------------

# HELP-BEGIN
# Usage:   ./ndm_file-timestamp.sh [-d DIR] FILE...            create the timestamps
#          ./ndm_file-timestamp.sh --verify [-d DIR] FILE...   check the files against
#                                                              their timestamps
#          ./ndm_file-timestamp.sh --list [-d DIR]             list the saved proofs
#          ./ndm_file-timestamp.sh --archive [-d DIR] FILE...  pack each file with its
#                                                              proofs and this script
#          ./ndm_file-timestamp.sh --archive [-d DIR] FILE --attach FILE|DIR...
#                                                              the same, with attachments
#          ./ndm_file-timestamp.sh --check-script              compare this script with
#                                                              the published version
#
#          Proves that each FILE existed, exactly as it is now, at the moment the script
#          is run: several independent Time Stamping Authorities (TSA) sign its SHA-256
#          hash together with their own date and time (RFC 3161).
#
# Options: --verify FILE...      check each FILE against ALL its timestamps and show the
#                                dates they certify (UTC and local time), plus the
#                                earliest date proved. Proofs are searched in the
#                                ndm_file-timestamp-proofs/ folder next to this script,
#                                in the current directory and next to FILE (and in DIR
#                                with -d or OUTPUT_DIR), and recognized by the content
#                                of FILE, so a renamed copy is verified too.
#                                Certificates are checked at the date of each timestamp,
#                                so proofs stay verifiable after the TSA certificates
#                                expire. Only the root certificates this script trusts
#                                are used, never those found next to the proofs.
#          -l, --list            list the proofs in the proof folder (or in DIR with -d,
#                                or OUTPUT_DIR): file, date of the run, number of
#                                timestamps
#          -a, --archive FILE... verify each FILE, then pack it with its valid proofs,
#                                the root certificates, this script and its license in
#                                <file>_bundle_<YYYYMMDD>-<HHMMSS>.tar in the
#                                ndm_file-timestamp-archives/ folder next to this script
#                                (or ARCHIVE_DIR), to keep or move them together; next
#                                to it, <archive>.log is the report of that run
#          --attach FILE|DIR     with --archive and one FILE only: also pack FILE, or
#                                every file directly inside DIR, in attachments/ (e.g. a
#                                signed declaration of authorship, PEC receipts), with
#                                their valid proofs. Repeatable. An attachment without
#                                valid timestamps is packed anyway, with a warning
#          -d, --output-dir DIR  save the proofs in DIR instead of the folder next to this
#                                script or OUTPUT_DIR (created if missing; a relative DIR
#                                starts from the current directory)
#          --                    end of the options: what follows are files, even when
#                                their name starts with "-"
#
#          --check-script        compare this script with the one published on GitHub
#                                for its version (exit code 1 if different or if the
#                                comparison is not possible), and say whether a newer
#                                version has been released and how to update (in a git
#                                clone it offers to run git pull)
#          --get-certs           show the root certificates of the TSAs and download the
#                                missing ones, showing every check (see below)
#          --verify-certs        check, offline, that every root certificate is there and
#                                unaltered (its SHA-256), and that nothing else is there
#          --requirements        show the needed tools and how to install them
#          -v, --version         show name, version, author, license and disclaimer
#          -h, --help            show this help
#
# Settings: in ndm_file-timestamp.conf next to this script (start from
#   ndm_file-timestamp.conf.example), or in the environment, which wins over the file;
#   the command line wins over both. The file is only read, never executed.
#          OUTPUT_DIR=DIR             proof folder (relative to the script folder)
#          ARCHIVE_DIR=DIR            folder for --archive (relative to the script folder)
#          TSAS="freetsa digicert sectigo"  TSAs to ask
#          MIN_TIMESTAMPS=1           different TSAs needed for a file to be OK
#          SCRIPT_CHECK=off           on = run --check-script before each run
#          COLORS=on                  off = no colors (also NO_COLOR=1)
#
# TSAs:    freetsa   https://freetsa.org            free public TSA
#          digicert  http://timestamp.digicert.com  used worldwide for code signing
#          sectigo   http://timestamp.sectigo.com   used worldwide for code signing
#
#   Each timestamp is valid on its own; several independent authorities confirming the
#   same hash make the proof stronger. No key, signature or password is needed.
#   Only the SHA-256 hash is sent over the network, never the content of FILE.
#   (DigiCert and Sectigo use plain HTTP: this is normal for RFC 3161, because the
#   response is digitally signed and cannot be altered without detection.)
#   Root certificates: every timestamp is checked only against the root certificate of
#   its TSA, never against one that comes with the proofs. The three roots are kept in
#   ndm_file-timestamp-certs/ next to this script, and recognized by their SHA-256,
#   written in this script and published by the TSAs (FreeTSA on its website; for
#   DigiCert and Sectigo it is the certificate fingerprint, also in the Mozilla CA list
#   and on crt.sh). They are required: when one is missing, before anything else the
#   script explains why, asks on a terminal and downloads them, showing every check;
#   if they are declined or cannot be downloaded, it stops. They can also be got with
#   --get-certs, or downloaded and checked by hand (README, "Root certificates").
#   Authorship is proved by other means (Internet Archive captures, original files,
#   signed declaration), not by this script.
#
# Output:  ndm_file-timestamp-proofs/<file name>_<YYYYMMDD>-<HHMMSS>/   (UTC)
#   In the folder of this script (its real location, also when run through a symbolic
#   link), or in DIR with -d; the folder is created again if it is missing. One
#   subfolder per file and per run, so earlier proofs are never overwritten:
#     README.txt          what each file is and how to verify by hand
#     file-info.txt       SHA-256, size and last-modified date of the file
#     FILE.sha256         SHA-256 checksum, usable with "sha256sum -c"
#     FILE.tsq            RFC 3161 request sent to the TSAs (hash only)
#     FILE.<tsa>.tsr      RFC 3161 response = THE TIMESTAMP (keep it!)
#     FILE.<tsa>.txt      readable timestamp: look for the "Time stamp" line
#     <tsa>-certs.pem     certificates needed to verify FILE.<tsa>.tsr
#     <tsa>-<SHA-256>.pem/.crt  copy of the root certificate of the TSA, for the manual
#                         steps; --verify never trusts this copy
#     <tsa>-verify.txt    result of the verification done right away
#   where <tsa> is freetsa, digicert or sectigo. Next to each folder, <folder>.log is
#   the report of that run, as shown on screen (without colors).
#   FILE itself is NOT copied (--archive packs it with its proofs).
#
# Examples:
#          ./ndm_file-timestamp.sh project.zip
#          ./ndm_file-timestamp.sh contract.pdf drawings.zip notes.odt
#          ./ndm_file-timestamp.sh -d /media/usb/proofs project.zip
#          ./ndm_file-timestamp.sh --verify project.zip
#          ./ndm_file-timestamp.sh --list
#          ./ndm_file-timestamp.sh --archive project.zip
#          ./ndm_file-timestamp.sh --archive project.zip --attach declaration.pdf
#
# Needs:   openssl, curl, sha256sum (coreutils; on macOS shasum) and the system CA
#          certificates (ca-certificates). Runs on Linux, on Windows in WSL, and on
#          macOS (its bash 3.2 and BSD tools are enough).
#          Run with --requirements for the install commands of your system.
#
# Exit codes:
#   0  every file got at least one verified timestamp (MIN_TIMESTAMPS), or --verify
#      found a valid timestamp for the current content of every file, or --archive
#      archived every file; --list always; --check-script: the script is the published
#      one; --get-certs: all the root certificates are there; --verify-certs: they are
#      all there, unaltered, and nothing else is in their folder
#   1  a file got fewer verified timestamps than MIN_TIMESTAMPS (e.g. no network) or,
#      with --verify, has no valid timestamp for its current content (e.g. the file has
#      been MODIFIED); with --archive, a file without valid timestamps (no archive is
#      made); a file or an attachment not found or not readable, a missing tool, or
#      missing root certificates (download declined or failed; --get-certs,
#      --verify-certs)
#   2  invalid command-line usage (unknown option, missing or extra argument) or an
#      invalid setting
#
# Important:
#   - Only the CONTENT of the file counts: its name, folder, dates and permissions do
#     not. A renamed or moved copy keeps its proofs (--verify finds them by content).
#   - Changing a single byte invalidates every proof. The content changes when a zip
#     is re-created, when line endings are converted (FTP in text mode, some mail
#     programs), when a cloud service converts or recompresses the file, when the file
#     is opened and saved again, or when a copy is interrupted. After copying the file,
#     run --verify on the copy before deleting the original.
#   - Keep the file and its proofs in at least two places: --archive packs them
#     together, with this script.
#   - A timestamp is "obtained" when the TSA answered and the .tsr was saved;
#     "verified" means its signature was also checked here against the certificates.
#     Only verified timestamps count for the result; an obtained but unverified .tsr
#     is still kept, and can be checked later with --verify. Certificates are checked
#     at the date signed by the TSA, so a wrong clock on this computer does not matter.
#   - Legal value: these are technical proofs, freely assessed by a judge. None of
#     these TSAs is a qualified eIDAS provider, so they do not give "data certa" in
#     the strict sense of Italian law (qualified timestamp or PEC). When strong
#     protection is needed, use them together with a qualified timestamp, a PEC or a
#     registration with the copyright office of your country.
#   - The "Proofs created" line in file-info.txt is your local clock, not a proof:
#     the dates that count are those signed by the TSAs.
# HELP-END

set -euo pipefail

# Every TSA the script knows: name | timestamp URL. TSAS in the config file chooses
# among them.
TSA_CATALOG=(
  "freetsa|https://freetsa.org/tsr"
  "digicert|http://timestamp.digicert.com"
  "sectigo|http://timestamp.sectigo.com"
)
# The only root certificates ever trusted: TSA | download URL | SHA-256 of that file |
# SHA-256 fingerprint of the certificate (of its DER form). Never a certificate that
# comes with the proofs: whoever made fake proofs could have made that certificate too.
# Anyone can compare these values: FreeTSA publishes the SHA-256 of its file on
# https://freetsa.org; the DigiCert and Sectigo .crt files are the bare certificates, so
# file SHA-256 and fingerprint are the same, as in the Mozilla CA list (ca-certificates)
# and on crt.sh. A file is accepted when either value matches (the fingerprint only for
# a file with one certificate): so a TSA that reformats its file, with the same
# certificate inside, does not break anything. A plain-HTTP download is fine: any other
# file is never kept. A TSA may have several roots: when it moves to a new one, a new
# version of this script adds it, and the old ones stay for older timestamps.
TSA_ROOTS=(
  "freetsa|https://freetsa.org/files/cacert.pem|2151b61137ffa86bf664691ba67e7da0b19f98c758e3d228d5d8ebf27e044438|a6379e7cecc05faa3cbf076013d745e327bbbaa38c0b9af22469d4701d18aabc"
  "digicert|http://cacerts.digicert.com/DigiCertTrustedRootG4.crt|552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988|552f7bdcf1a7af9e6ce672017f4f12abf77240c78e761ac203d1d9d20ac89988"
  "sectigo|http://crt.usertrust.com/USERTrustRSACertificationAuthority.crt|e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2|e793c9b02fd8aa13e21c31228accb08119643b749c898964b1746d46c3d4cbd2"
)
# A root that expires within this time is announced when stamping: before it expires, the
# TSA moves to a new root, and new timestamps need a newer version of this script
ROOT_EXPIRY_WARNING_DAYS=730
# Upper limit for every download: an RFC 3161 response or a root certificate is a few KB,
# so a bigger answer is refused instead of filling the disk
MAX_DOWNLOAD_BYTES=1048576
# System CA bundle, needed by curl for the HTTPS downloads: the path depends on the system
SYSTEM_CA_PATHS=(
  /etc/ssl/certs/ca-certificates.crt    # Debian, Ubuntu, Arch, Alpine
  /etc/pki/tls/certs/ca-bundle.crt      # Fedora, RHEL, CentOS
  /etc/ssl/ca-bundle.pem                # openSUSE
  /etc/ssl/cert.pem                     # macOS
)
SYSTEM_CA="${SYSTEM_CA_PATHS[0]}"
for _ca in "${SYSTEM_CA_PATHS[@]}"; do
  if [[ -f "$_ca" ]]; then SYSTEM_CA="$_ca"; break; fi
done
unset _ca

# Real location of this script (following symlinks): the proof folder lives next to it.
# readlink without -f, which macOS does not have.
SCRIPT_PATH=${BASH_SOURCE[0]}
while [[ -L $SCRIPT_PATH ]]; do
  link_target=$(readlink "$SCRIPT_PATH")
  if [[ $link_target == /* ]]; then SCRIPT_PATH=$link_target
  else SCRIPT_PATH="$(dirname "$SCRIPT_PATH")/$link_target"; fi
done
SCRIPT_DIR=$(cd "$(dirname "$SCRIPT_PATH")" && pwd -P)
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$SCRIPT_PATH")"
unset link_target

# Fixed, so that renaming the script does not hide the existing proofs
OUT_DIR_NAME="ndm_file-timestamp-proofs"
# Default folder of the archives made by --archive, next to the script like the proofs
ARCHIVE_DIR_NAME="ndm_file-timestamp-archives"
# Folder of the --attach files inside an archive
ATTACH_DIR_NAME="attachments"
# Root certificates of the TSAs (TSA_ROOTS), downloaded once and checked; next to the
# script, and inside every archive
CERTS_DIR_NAME="ndm_file-timestamp-certs"
# Name of the script in the repository and in the archives made by --archive
PUBLISHED_NAME="ndm_file-timestamp.sh"
OUT_ROOT="${SCRIPT_DIR}/${OUT_DIR_NAME}"
CERTS_ROOT="${SCRIPT_DIR}/${CERTS_DIR_NAME}"

# --------------------------------------------------------- configuration ----
# Optional, next to the script, with a fixed name like the proof folder. Personal: it is
# in .gitignore, only ndm_file-timestamp.conf.example is versioned.
CONFIG_FILE="$SCRIPT_DIR/ndm_file-timestamp.conf"

# Read KEY=value lines from the config file (never executed). A variable already set
# in the environment is left untouched, so the environment wins over the file.
load_config() {
  local key value
  [[ -r $CONFIG_FILE ]] || return 0
  while IFS='=' read -r key value || [[ -n $key ]]; do
    key=$(printf '%s' "$key" | tr -d '[:space:]')
    [[ -z $key || $key == \#* ]] && continue
    value=$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
      -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/")
    case $key in
      OUTPUT_DIR|ARCHIVE_DIR|TSAS|MIN_TIMESTAMPS|SCRIPT_CHECK|COLORS)
        declare -p "$key" >/dev/null 2>&1 || printf -v "$key" '%s' "$value" ;;
    esac
  done <"$CONFIG_FILE"
}
load_config

# Defaults (checked in the main block, after the command line has been read)
OUTPUT_DIR="${OUTPUT_DIR:-}"          # empty = the proof folder next to the script
ARCHIVE_DIR="${ARCHIVE_DIR:-}"        # empty = the archive folder next to the script
TSAS="${TSAS:-freetsa digicert sectigo}"
# Expanded unquoted below: a glob character would match file names of the current directory
TSAS=${TSAS//[*?[]/}
MIN_TIMESTAMPS="${MIN_TIMESTAMPS:-1}"
SCRIPT_CHECK="${SCRIPT_CHECK:-off}"
COLORS="${COLORS:-on}"

# Colors (COLORS=on, the default) only on a terminal, and never when NO_COLOR is set
# (https://no-color.org): files, pipes and logs get plain text
if [[ $COLORS == off || -n ${NO_COLOR:-} ]]; then USE_COLORS=""; else USE_COLORS=1; fi
if [[ -t 1 && -n $USE_COLORS ]]; then C_SAY=$'\033[1;32m' C_OUT=$'\033[0m'; else C_SAY="" C_OUT=""; fi
if [[ -t 2 && -n $USE_COLORS ]]; then
  C_WARN=$'\033[1;33m' C_ERR=$'\033[1;31m' C_END=$'\033[0m'
else
  C_WARN="" C_ERR="" C_END=""
fi
# While stamping or archiving, every line shown is also written, without colors, to the
# log of the run (<proof folder>.log, set by stamp; <archive>.log, set by archive). A log
# that cannot be written never stops the run.
LOG_FILE=""
log_line() { [[ -z $LOG_FILE ]] || printf '%s\n' "$*" >> "$LOG_FILE" 2>/dev/null || true; }
say()  { printf '%s==>%s %s\n' "$C_SAY" "$C_OUT" "$*"; log_line "==> $*"; }
warn() { printf '%s!!%s  %s\n' "$C_WARN" "$C_END" "$*" >&2; log_line "!!  $*"; }
err()  { printf '%sxx%s  %s\n' "$C_ERR" "$C_END" "$*" >&2; log_line "xx  $*"; }
line() { printf '%s\n' "$*"; log_line "$*"; }
die()  { err "$*"; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------- portability ----
# GNU tools (Linux, WSL) are always tried first; the BSD forms (macOS) are used only
# when the GNU ones are missing, so on Linux the commands are exactly the GNU ones.
# Bash 3.2 (macOS) has no mapfile and, with set -u, fails on "${empty_array[@]}":
# hence the while-read loops and the ${arr[@]+"${arr[@]}"} expansions below.

if date -d @0 +%s >/dev/null 2>&1; then GNU_DATE=1; else GNU_DATE=""; fi
if stat -c %s / >/dev/null 2>&1; then GNU_STAT=1; else GNU_STAT=""; fi

# SHA-256 of a file (hash only). Read from stdin: with a file name argument, sha256sum
# puts a "\" before the hash when the name contains a backslash or a newline.
sha256_of() {
  if have sha256sum; then
    sha256sum < "$1" | cut -d' ' -f1
  else
    shasum -a 256 < "$1" | cut -d' ' -f1
  fi
}

# Absolute path of an existing file or directory. A relative path gets "./" in front,
# so that a name starting with "-" is never read as an option.
abs_path() {
  local path=$1
  [[ $path == /* ]] || path="./$path"
  if have realpath; then
    realpath "$path"
  elif [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  else
    printf '%s/%s\n' "$(cd "$(dirname "$path")" && pwd -P)" "$(basename "$path")"
  fi
}

file_size() {
  if [[ -n $GNU_STAT ]]; then stat -c %s "$1"; else stat -f %z "$1"; fi
}

file_mtime() {
  if [[ -n $GNU_STAT ]]; then stat -c %y "$1"; else stat -f '%Sm' -t '%Y-%m-%d %H:%M:%S %z' "$1"; fi
}

# Epoch of a date as printed by openssl ts ("Oct 26 06:01:40 2026 GMT")
ts_epoch() {
  if [[ -n $GNU_DATE ]]; then
    date -d "$1" +%s
  else
    LC_ALL=C date -j -u -f '%b %d %H:%M:%S %Y %Z' "$(sed -E 's/\.[0-9]+ / /' <<< "$1")" +%s
  fi
}

# Format an epoch: fmt_epoch EPOCH +FORMAT [-u]
fmt_epoch() {
  local e=$1 fmt=$2
  shift 2
  if [[ -n $GNU_DATE ]]; then
    date ${1+"$@"} -d "@$e" "$fmt"
  else
    date ${1+"$@"} -r "$e" "$fmt"
  fi
}

# SHA-256 of this script, computed once (SCRIPT_SHA): call before using it
load_script_sha() {
  [[ -n ${SCRIPT_SHA:-} ]] || SCRIPT_SHA="$(sha256_of "$SCRIPT_PATH")"
}

# ----------------------------------------------------------------- setup ----
REQUIRED_TOOLS="openssl curl sha256sum"

# Package that provides a tool (or "ca" for the CA certificates), for a package manager.
pkg_for() {
  local tool=$2
  case $tool in
    sha256sum) [[ $1 == brew ]] || echo coreutils ;;   # macOS has shasum
    ca) [[ $1 == brew ]] || echo ca-certificates ;;    # macOS has /etc/ssl/cert.pem
    *) echo "$tool" ;;
  esac
}

# Install command for a package manager and a list of tools (deduplicated packages).
install_cmd() {
  local pm=$1; shift
  local pkgs="" t p
  for t in "$@"; do
    p=$(pkg_for "$pm" "$t")
    [[ -n $p && " $pkgs " != *" $p "* ]] && pkgs+="${pkgs:+ }$p"
  done
  [[ -z $pkgs ]] && return
  case $pm in
    apt) echo "sudo apt install $pkgs" ;;      dnf) echo "sudo dnf install $pkgs" ;;
    yum) echo "sudo yum install $pkgs" ;;      zypper) echo "sudo zypper install $pkgs" ;;
    pacman) echo "sudo pacman -S $pkgs" ;;     apk) echo "sudo apk add $pkgs" ;;
    brew) echo "brew install $pkgs" ;;
  esac
}

detect_pm() {
  local pm
  for pm in apt-get dnf yum zypper pacman apk brew; do
    if have "$pm"; then echo "${pm%-get}"; return; fi
  done
}

# Missing tools (and "ca" when no CA bundle is found), one per line.
# Arguments: the tools to check (default: REQUIRED_TOOLS).
missing_requirements() {
  local t
  # shellcheck disable=SC2086  # word splitting of the tool list is intended
  (($#)) || set -- $REQUIRED_TOOLS
  for t in "$@"; do
    case $t in
      sha256sum) have sha256sum || have shasum || echo "$t" ;;
      *) have "$t" || echo "$t" ;;
    esac
  done
  # curl needs them for the HTTPS downloads; the TSA roots themselves come from TSA_ROOTS
  if [[ " $* " == *" curl "* && ! -f "$SYSTEM_CA" ]]; then echo ca; fi
}

# Stop with a clear message when a requirement is missing (before stamp, verify, archive).
# Arguments: the tools to check (default: REQUIRED_TOOLS).
check_requirements() {
  local miss
  miss=$(missing_requirements ${1+"$@"} | tr '\n' ' ')
  [[ -z $miss ]] || die "Missing: ${miss% } (run with --requirements to see how to install)"
}

# Explain what is missing and how to install it, for this system and the common others.
requirements_help() {
  local miss=() pm all t
  while IFS= read -r t; do miss+=("$t"); done < <(missing_requirements)
  echo "Requirements (all required)"
  echo "  tools:            $REQUIRED_TOOLS (macOS: shasum instead of sha256sum)"
  echo "  CA certificates:  ${SYSTEM_CA}"
  echo "                    (package ca-certificates: used by curl for HTTPS)"
  echo "  system:           Linux (also WSL on Windows) or macOS"
  echo
  if ((${#miss[@]} == 0)); then
    echo "Everything is installed."
    return
  fi
  echo "  MISSING: ${miss[*]/#ca/CA certificates}"
  echo
  pm=$(detect_pm)
  if [[ -n $pm ]]; then
    echo "Install on this system ($pm):"
    echo "  $(install_cmd "$pm" "${miss[@]}")"
    echo
  fi
  all="$REQUIRED_TOOLS ca"
  echo "All requirements, other systems:"
  # shellcheck disable=SC2086  # word splitting of the tool list is intended
  {
    printf '  %-16s %s\n' "Debian/Ubuntu" "$(install_cmd apt $all)"
    printf '  %-16s %s\n' "Fedora/RHEL 8+" "$(install_cmd dnf $all)"
    printf '  %-16s %s\n' "CentOS/RHEL 7" "$(install_cmd yum $all)"
    printf '  %-16s %s\n' "openSUSE" "$(install_cmd zypper $all)"
    printf '  %-16s %s\n' "Arch/Manjaro" "$(install_cmd pacman $all)"
    # Alpine has no bash by default: without it this script cannot even start
    printf '  %-16s %s\n' "Alpine" "$(install_cmd apk bash $all)"
    printf '  %-16s %s\n' "macOS (Homebrew)" "$(install_cmd brew $all)"
  }
  echo "  (Alpine: bash is not installed by default and is needed to run this script.)"
}

# Name, version, release date, description and author (used by --version and --help).
version_info() {
  printf '%s %s (released %s)\n' "$APP_NAME" "$APP_VERSION" "$APP_RELEASE_DATE"
  printf '%s\n' "$APP_DESCRIPTION" | fold -s -w 88 | sed 's/ *$//'
  printf 'Author: %s\n' "$APP_AUTHOR"
  echo
  printf '%s\n' "$APP_COPYRIGHT"
  printf 'License %s: GNU AGPL version 3 or later <https://www.gnu.org/licenses/agpl-3.0.html>\n' \
    "$APP_LICENSE"
  echo 'This is free software: you are free to change and redistribute it.'
  echo 'Provided "as is", WITHOUT ANY WARRANTY: the author is not liable for any damage'
  echo 'arising from its use. See the LICENSE file and the header of this script.'
}

usage() {
  version_info
  echo
  # The help text is the comment block between the HELP-BEGIN and HELP-END markers.
  awk '/^# HELP-BEGIN/ {f = 1; next} /^# HELP-END/ {exit} f {sub(/^# ?/, ""); print}' "${BASH_SOURCE[0]}"
}

# Extract the certificates embedded in a timestamp response (PEM)
token_certs() {
  openssl ts -reply -in "$1" -token_out 2>/dev/null \
    | openssl pkcs7 -inform DER -print_certs 2>/dev/null || true
}

# Verify one .tsr against the SHA-256 of the file (already computed, so a big file is not
# read again for every timestamp); returns 0 if the signature is valid.
# Optional 6th argument: epoch at which the certificates must be valid
# (the timestamp date), so that expired TSA certificates do not fail old proofs
tsr_verify() {
  local hash="$1" tsr="$2" cafile="$3" untrusted="$4" log="$5" attime="${6:-}"
  local opts=()
  [[ -n "$attime" && -n $TS_ATTIME ]] && opts=(-attime "$attime")
  # OpenSSL 3 splits the -untrusted path at spaces, and the proof folder is named after
  # the file: run from that folder and pass only the certificate file name, which never
  # contains spaces. The other paths are absolute and may contain spaces.
  ( cd "$(dirname "$untrusted")" &&
    openssl ts -verify -digest "$hash" -in "$tsr" -CAfile "$cafile" \
      -untrusted "$(basename "$untrusted")" ${opts[@]+"${opts[@]}"} ) > "$log" 2>&1
}

# Does "openssl ts -verify" accept -attime? OpenSSL 1.1+ does; LibreSSL (the openssl
# of macOS) may not: then certificates are checked at the current date. The help is
# read whole (no grep -q in a pipe: with pipefail an early exit would read as "no").
ts_attime_supported() {
  local help
  help=$(openssl ts -help 2>&1 || true)
  [[ $help == *-attime* ]]
}
TS_ATTIME=1

# Is a failed verification due to this openssl rather than to the timestamp? When the
# token's ESS list names more than one certificate, OpenSSL before 3 and LibreSSL require
# every certificate of the chain in it, the trusted root too; Sectigo lists its own
# certificates but not the root, so its timestamps never verify there. OpenSSL 3 only
# requires every listed certificate to be in the chain.
ess_limit() {
  local re='^OpenSSL ([3-9]|[1-9][0-9])\.'
  [[ ! $(openssl version 2>/dev/null) =~ $re ]] &&
    grep -qi 'ess signing certificate error' "$1" 2>/dev/null
}

# Name and version of the openssl in use, e.g. "LibreSSL 3.3.6"
openssl_name() {
  openssl version 2>/dev/null | awk '{print $1, $2}' || true
}

# Readable "Time stamp" line of a .tsr
tsr_time() {
  openssl ts -reply -in "$1" -text 2>/dev/null | grep 'Time stamp' | sed 's/^ *//' || true
}

# Temporary folder of this run (root certificates converted to PEM, openssl reports),
# created when first needed and removed at the end
RUN_TMP=""
run_tmp() {
  if [[ -z $RUN_TMP ]]; then
    RUN_TMP="$(mktemp -d "${TMPDIR:-/tmp}/ndm_file-timestamp.XXXXXX")"
    CLEANUP+=("$RUN_TMP")
    # Absolute: openssl runs from the proof folder, where a relative TMPDIR would not work
    RUN_TMP=$(cd "$RUN_TMP" && pwd -P)
  fi
}

# SHA-256 fingerprint of the certificate in a file (PEM or DER); empty when the file is
# not a certificate or holds more than one PEM block of any kind ("-----BEGIN"): with
# -CAfile, as in the manual steps, openssl would trust every certificate in the file
cert_fp() {
  local n
  n=$(grep -ac -- '-----BEGIN' "$1" 2>/dev/null || true)
  ((n <= 1)) || return 0
  { openssl x509 -in "$1" -noout -fingerprint -sha256 2>/dev/null \
    || openssl x509 -inform DER -in "$1" -noout -fingerprint -sha256 2>/dev/null; } \
    | sed 's/.*=//; s/://g' | tr 'A-F' 'a-f'
}

# The TSA_ROOTS entry (by its file SHA-256, used as its identifier) that a file is: its
# SHA-256 is the published one, or it holds just the same certificate. Returns 1 if none.
root_of_file() {
  local e r_tsa r_url r_sha r_fp h fp=""
  h=$(sha256_of "$1")
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    [[ $h != "$r_sha" ]] || { printf '%s\n' "$r_sha"; return 0; }
  done
  fp=$(cert_fp "$1")
  [[ -n $fp ]] || return 1
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    [[ $fp != "$r_fp" ]] || { printf '%s\n' "$r_sha"; return 0; }
  done
  return 1
}

# Root certificates present in CERTS_ROOT, recognized by their content whatever their file
# name, so that one downloaded by hand only has to be put there. ROOT_FILES gets one
# "id|path" line (id = file SHA-256 in TSA_ROOTS) for each file that is a trusted root;
# other files are ignored.
ROOT_FILES="" ROOTS_SCANNED=""
scan_roots() {
  local f id
  ROOT_FILES=""
  for f in "$CERTS_ROOT"/*; do
    [[ -f $f ]] || continue
    if id=$(root_of_file "$f"); then ROOT_FILES+="$id|$f"$'\n'; fi
  done
  ROOTS_SCANNED=1
  # Converted copies made before this scan may be out of date
  [[ -z $RUN_TMP ]] || rm -f "$RUN_TMP"/*.pem
}

# Standard file name of a trusted root: <tsa>-<start of its SHA-256>.<pem|crt>, used when
# it is downloaded and for its copies in proof folders and archives
root_name() {
  local e r_tsa r_url r_sha r_fp
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    [[ $r_sha != "$1" ]] || { printf '%s-%s.%s\n' "$r_tsa" "${r_sha:0:16}" "${r_url##*.}"; return 0; }
  done
  return 1
}

# Identifier (file SHA-256) of the first trusted root of a TSA
roots_of() {
  local e r_tsa r_url r_sha r_fp
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    [[ $r_tsa != "$1" ]] || { printf '%s\n' "$r_sha"; return 0; }
  done
  return 1
}

# File of a trusted root (by identifier) in CERTS_ROOT; returns 1 when it is not there
root_file() {
  local l
  while IFS= read -r l; do
    [[ ${l%%|*} != "$1" ]] || { printf '%s\n' "${l#*|}"; return 0; }
  done <<< "$ROOT_FILES"
  return 1
}

# Entries of TSA_ROOTS whose certificate is not in CERTS_ROOT, one per line
missing_roots() {
  local e r_tsa r_url r_sha r_fp
  [[ -n $ROOTS_SCANNED ]] || scan_roots
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    root_file "$r_sha" >/dev/null || printf '%s\n' "$e"
  done
}

# Root certificates to trust for a TSA: its TSA_ROOTS entries present in CERTS_ROOT,
# converted to one PEM file for openssl (-CAfile); only the certificate is kept, not any
# text around it. The main block has made sure, with ensure_roots, that the needed ones
# are there. Sets ROOT_CA (the PEM file), ROOT_SRC (the original files) and ROOT_SHAS
# (their identifiers), or ROOT_WHY and returns 1.
trusted_root() {
  local tsa=$1 e f known="" r_tsa r_url r_sha r_fp
  ROOT_CA="" ROOT_WHY="" ROOT_SRC=() ROOT_SHAS=()
  [[ -n $ROOTS_SCANNED ]] || scan_roots
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    [[ $r_tsa == "$tsa" ]] || continue
    known=1
    if f=$(root_file "$r_sha"); then ROOT_SRC+=("$f"); ROOT_SHAS+=("$r_sha"); fi
  done
  if [[ -z $known ]]; then
    ROOT_WHY="unknown TSA: this script trusts no root certificate for it"
    return 1
  fi
  if ((${#ROOT_SRC[@]} == 0)); then
    ROOT_WHY="its root certificate is not in $CERTS_DIR_NAME/ (see --get-certs)"
    return 1
  fi
  run_tmp
  ROOT_CA="$RUN_TMP/$tsa.pem"
  if [[ ! -s $ROOT_CA ]]; then
    for f in "${ROOT_SRC[@]}"; do
      openssl x509 -in "$f" 2>/dev/null || openssl x509 -inform DER -in "$f"
    done > "$ROOT_CA"
  fi
}

# The root certificates are required: without them no timestamp can be checked here, and
# nothing would show that a date really comes from a TSA. Called before any TSA is
# contacted or any folder is created: the missing ones (for stamp, those of the TSAs in
# TSAS; otherwise all, as proofs may hold timestamps of any TSA) are listed and, after
# asking on a terminal (without one: downloading and saying so), downloaded with every
# check shown. Declined or failed: the script stops.
ensure_roots() {
  local e need="" r_tsa r_url r_sha r_fp ans=""
  # In this shell: missing_roots runs in a subshell, whose scan would be lost
  [[ -n $ROOTS_SCANNED ]] || scan_roots
  while IFS= read -r e; do
    [[ -n $e ]] || continue
    if [[ $MODE == stamp && " ${TSA_ACTIVE[*]} " != *" ${e%%|*}|"* ]]; then continue; fi
    need+="$e"$'\n'
  done < <(missing_roots)
  [[ -n $need ]] || return 0
  need=${need%$'\n'}
  warn "Root certificates are needed to verify the timestamps, and these are not in"
  warn "    $CERTS_ROOT/"
  while IFS='|' read -r r_tsa r_url r_sha r_fp; do
    warn "$(printf '    %-9s %s' "$r_tsa" "$r_url")"
    warn "    $(printf '%-9s' '') SHA-256 $r_sha"
  done <<< "$need"
  warn "    Each one is kept only if its SHA-256 is the value above, which you can compare"
  warn "    with the one the TSA publishes. You can also download and check them by hand"
  warn "    (README.md, \"Root certificates\") or with --get-certs."
  if [[ -t 0 && -t 2 ]]; then
    printf 'Download and check them now? [Y/n] ' >&2
    read -r ans || ans=n
    [[ -z $ans || $ans == [Yy]* ]] || roots_stop "Not downloaded."
  else
    warn "    No terminal to ask: downloading them now."
  fi
  download_roots "$need" || roots_stop "Not all of them could be downloaded and checked."
}

roots_stop() {
  err "$1 Without the root certificates no timestamp can be verified:"
  err "the script stops. Get them with:  ./$PUBLISHED_NAME --get-certs"
  err "or download and check them by hand (README.md, \"Root certificates\")."
  exit 1
}

# Announce, when stamping, the roots of the TSAs in TSAS that expire within
# ROOT_EXPIRY_WARNING_DAYS: older timestamps stay valid, but new ones will soon be signed
# under a new root, which only a newer version of this script knows
warn_expiring_roots() {
  local e r_tsa r_url r_sha r_fp f end
  [[ -n $ROOTS_SCANNED ]] || scan_roots
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    [[ " ${TSA_ACTIVE[*]} " == *" $r_tsa|"* ]] || continue
    f=$(root_file "$r_sha") || continue
    # -checkend also prints "Certificate will (not) expire" on stdout: only its status counts
    if ! { openssl x509 -in "$f" -noout -checkend $((ROOT_EXPIRY_WARNING_DAYS * 86400)) &>/dev/null \
        || openssl x509 -inform DER -in "$f" -noout -checkend $((ROOT_EXPIRY_WARNING_DAYS * 86400)) &>/dev/null; }; then
      end=$( { openssl x509 -in "$f" -noout -enddate 2>/dev/null \
        || openssl x509 -inform DER -in "$f" -noout -enddate 2>/dev/null; } | sed 's/^notAfter=//')
      warn "The root certificate of $r_tsa expires on $end."
      warn "    Your timestamps stay valid, but $r_tsa will soon sign under a new root:"
      warn "    look for a newer version of this script ($APP_URL)."
    fi
  done
}

# Download root certificates (TSA_ROOTS lines) into CERTS_ROOT, showing for each one the
# expected and the obtained SHA-256. A file is kept when its SHA-256 is the published one,
# or when it holds just the same certificate (a TSA may reformat its file); any other
# file is not kept. Returns 1 if any of them could not be saved.
download_roots() {
  local r_tsa r_url r_sha r_fp tmp got fp f rc=0
  if ! have curl; then warn "    curl is missing: cannot download them."; return 1; fi
  if ! mkdir -p "$CERTS_ROOT" 2>/dev/null; then warn "    Cannot write in $CERTS_ROOT"; return 1; fi
  while IFS='|' read -r r_tsa r_url r_sha r_fp; do
    say "Root certificate of $r_tsa: $r_url"
    line "    expected SHA-256: $r_sha"
    if ! tmp="$(mktemp "$CERTS_ROOT/.download.XXXXXX" 2>/dev/null)"; then
      err "    Cannot write in $CERTS_ROOT"
      rc=1
      continue
    fi
    CLEANUP+=("$tmp")
    if ! curl -fsS -m 30 --max-filesize "$MAX_DOWNLOAD_BYTES" "$r_url" -o "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      err "    download failed (no network?): not saved"
      rc=1
      continue
    fi
    got=$(sha256_of "$tmp")
    line "    obtained SHA-256: $got"
    if [[ $got == "$r_sha" ]]; then
      line "    same as expected"
    else
      fp=$(cert_fp "$tmp")
      if [[ -n $fp && $fp == "$r_fp" ]]; then
        line "    the file differs, but it holds the same certificate (fingerprint $fp)"
      else
        rm -f "$tmp"
        err "    DIFFERENT, and not the same certificate: file REJECTED, not saved"
        rc=1
        continue
      fi
    fi
    f="$CERTS_ROOT/$(root_name "$r_sha")"
    mv "$tmp" "$f"
    # mktemp makes it readable by its owner only; a certificate is public
    chmod 644 "$f" 2>/dev/null || true
    line "    saved as $CERTS_DIR_NAME/$(basename "$f")"
  done <<< "$1"
  echo >&2
  scan_roots
  return $rc
}

# --get-certs: state of every root certificate, and download of the missing ones
get_certs() {
  local e r_tsa r_url r_sha r_fp miss f
  scan_roots
  say "Root certificates in $CERTS_ROOT"
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    if f=$(root_file "$r_sha"); then
      printf '    %-9s OK       %s\n' "$r_tsa" "$(basename "$f")"
    else
      printf '    %-9s MISSING  %s\n' "$r_tsa" "$r_url"
    fi
  done
  miss=$(missing_roots)
  if [[ -z $miss ]]; then
    echo "    All present: each one matches the values written in this script (TSA_ROOTS)."
    return 0
  fi
  echo
  download_roots "$miss"
}

# --verify-certs: offline check of CERTS_ROOT, nothing is downloaded or changed. Every
# trusted root must be there (its exact file, or a file with just the same certificate);
# any other file is reported: ALTERED when it has the name of a trusted root, otherwise
# as not a trusted root. Returns 1 on any problem.
verify_certs() {
  local e r_tsa r_url r_sha r_fp f h n rc=0 names="" info how
  scan_roots
  say "Root certificates in $CERTS_ROOT"
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    names+=" $(root_name "$r_sha") "
    if ! f=$(root_file "$r_sha"); then
      printf '    %-9s MISSING  (get it with --get-certs, or by hand)\n' "$r_tsa"
      rc=1
      continue
    fi
    info=$( { openssl x509 -in "$f" -noout -subject -enddate 2>/dev/null \
      || openssl x509 -inform DER -in "$f" -noout -subject -enddate 2>/dev/null; } \
      | sed -e 's/^subject= *//' -e 's/^notAfter=/valid until /' | tr '\n' '|')
    if [[ $(sha256_of "$f") == "$r_sha" ]]; then
      how="SHA-256 $r_sha"
    else
      how="same certificate as the published file (fingerprint $r_fp)"
    fi
    printf '    %-9s OK       %s\n' "$r_tsa" "$(basename "$f")"
    printf '    %-9s          %s\n' "" "${info%%|*}"
    info=${info#*|}
    printf '    %-9s          %s\n' "" "${info%|}"
    printf '    %-9s          %s\n' "" "$how"
  done
  for f in "$CERTS_ROOT"/*; do
    [[ -f $f ]] || continue
    [[ $ROOT_FILES != *"|$f"$'\n'* ]] || continue
    h=$(sha256_of "$f")
    n=$(basename "$f")
    if [[ $names == *" $n "* ]]; then
      err "    ALTERED: $n is not the published file (SHA-256 $h): delete it"
    else
      err "    $n is not a trusted root (SHA-256 $h): delete it"
    fi
    rc=1
  done
  echo
  if ((rc == 0)); then
    echo "    All the trusted roots are present and unaltered: each one matches the values"
    echo "    written in this script (TSA_ROOTS), published by the TSAs (README, \"Root"
    echo "    certificates\")."
  else
    echo "    Fix the problems above: --get-certs downloads the missing roots."
  fi
  echo "    The check is as good as this script: verify the script itself with --check-script,"
  echo "    or better with the independent check in the README."
  return $rc
}

# Is a failed verification due to a certificate chain that leads to no trusted root?
# (forged proofs, or a TSA that moved to a root this version of the script does not know)
unknown_root() {
  grep -qE 'unable to get (local )?issuer certificate|self.signed certificate in certificate chain' "$1" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Create the timestamps
# ---------------------------------------------------------------------------
# One file. Sets RESULT (0 = at least MIN_TIMESTAMPS verified timestamps) and RESULT_NOTE
# for the final summary; it never returns an error code, so that set -e keeps working
# inside it. Only a verified timestamp counts: one that was obtained but could not be
# verified is kept (it can be checked later) but never reported as a success.
stamp() {
  local file="$1"
  local name now dir abs
  abs="$(abs_path "$file")"
  name="$(basename "$abs")"
  now="$(date -u +%Y%m%d-%H%M%S)"
  dir="${PROOF_ROOT}/${name}_${now}"
  # Proofs of two runs (or of two files with the same name) must never share a folder:
  # in the same second, wait for the next one
  if ! mkdir "$dir" 2>/dev/null; then
    sleep 1
    now="$(date -u +%Y%m%d-%H%M%S)"
    dir="${PROOF_ROOT}/${name}_${now}"
    mkdir "$dir" 2>/dev/null || die "Cannot create the proof folder $dir"
  fi
  LOG_FILE="${dir}.log"
  : > "$LOG_FILE" 2>/dev/null || LOG_FILE=""
  say "Output folder: $dir"

  # --- File fingerprint -------------------------------------------------
  local hash
  hash="$(sha256_of "$abs")"
  {
    echo "File:             $name"
    echo "SHA-256:          $hash"
    echo "Size (bytes):     $(file_size "$abs")"
    echo "Last modified:    $(file_mtime "$abs")"
    echo "Proofs created:   $(date -u '+%Y-%m-%d %H:%M:%S UTC') (local clock, not a proof)"
    echo "Created with:     $APP_NAME $APP_VERSION"
    echo "Script SHA-256:   $SCRIPT_SHA"
  } > "$dir/file-info.txt"
  echo "$hash  $name" > "$dir/${name}.sha256"
  say "SHA-256: $hash"

  # --- One request (hash only), sent to every TSA -------------------------
  # Built from the hash already computed: the file is read only once
  local tsq="$dir/${name}.tsq" query_err
  query_err="$(openssl ts -query -digest "$hash" -sha256 -cert -no_nonce -out "$tsq" 2>&1)" \
    || die "Could not create the timestamp request (openssl ts -query): $query_err"

  local total=${#TSA_ACTIVE[@]} i=0 obtained=0 verified=0 summary="" entry
  local tsa url tsr certs status stamped root when epoch
  for entry in "${TSA_ACTIVE[@]}"; do
    i=$((i + 1))
    IFS='|' read -r tsa url <<< "$entry"
    tsr="$dir/${name}.${tsa}.tsr"
    certs="$dir/${tsa}-certs.pem"
    say "$i/$total $tsa ($url)"

    # Ask for the timestamp and accept it only if the TSA granted it
    if ! curl -fsS -m 30 --max-filesize "$MAX_DOWNLOAD_BYTES" \
        -H "Content-Type: application/timestamp-query" \
        --data-binary @"$tsq" "$url" -o "$tsr" 2>/dev/null \
       || [[ "$(openssl ts -reply -in "$tsr" -text 2>/dev/null || true)" != *"Status: Granted"* ]]; then
      warn "    no timestamp from $tsa (network error or request refused)"
      rm -f "$tsr"
      summary+="$(printf '    %-9s NO' "$tsa")"$'\n'
      continue
    fi
    obtained=$((obtained + 1))
    openssl ts -reply -in "$tsr" -text > "$dir/${name}.${tsa}.txt" 2>/dev/null || true
    stamped="$(tsr_time "$tsr")"
    # Certificates checked at the date signed by the TSA, as --verify does: so a wrong
    # clock on this computer does not make a good timestamp fail
    when=${stamped#Time stamp: } epoch=""
    [[ -z $when ]] || epoch=$(ts_epoch "$when" 2>/dev/null) || epoch=""

    # Certificates: those embedded in the response, plus the trusted root
    token_certs "$tsr" > "$certs"
    if ! trusted_root "$tsa"; then
      # No verification was run: record why, so the message below points to a real file
      {
        echo "Not verified: $ROOT_WHY."
        echo "The timestamp ${name}.${tsa}.tsr is kept: verify it later with --verify, or by"
        echo "hand with the root certificate, as described in README.txt."
      } > "$dir/${tsa}-verify.txt"
      status="NOT verified here, .tsr kept (see ${tsa}-verify.txt)"
    else
      # Copies of the TSA's roots, for the manual steps of README.txt (--verify never
      # trusts them: it uses those in CERTS_ROOT)
      for root in "${!ROOT_SRC[@]}"; do
        cp -p "${ROOT_SRC[root]}" "$dir/$(root_name "${ROOT_SHAS[root]}")"
      done
      if tsr_verify "$hash" "$tsr" "$ROOT_CA" "$certs" "$dir/${tsa}-verify.txt" "$epoch"; then
        status="verified"
        verified=$((verified + 1))
      else
        status="NOT verified here, .tsr kept (see ${tsa}-verify.txt)"
        if unknown_root "$dir/${tsa}-verify.txt"; then
          warn "    its certificates lead to no root this script trusts: a fake answer, or a"
          warn "    new root of $tsa, known to a newer version of this script"
        elif ess_limit "$dir/${tsa}-verify.txt"; then
          warn "    this openssl ($(openssl_name)) cannot check the certificate list of $tsa:"
          warn "    verify it with OpenSSL 3 (README, \"Requirements\")"
        fi
      fi
    fi
    if [[ $status == verified ]]; then
      say "    OK - $stamped - $status"
    else
      warn "    obtained but NOT verified: ${stamped:-no readable date}"
      warn "    (.tsr kept, see ${tsa}-verify.txt)"
    fi
    summary+="$(printf '    %-9s %s - %s' "$tsa" "$stamped" "$status")"$'\n'
  done

  write_readme "$dir" "$name"

  line
  say "Summary for $name"
  line "${summary%$'\n'}"
  RESULT_NOTE="$verified of $total timestamps verified"
  if ((obtained == 0)); then
    err "No timestamp obtained: check the network and retry"
    RESULT=1
  elif ((verified == 0)); then
    err "No timestamp could be verified: see the <tsa>-verify.txt files in the proof folder"
    RESULT=1
  elif ((verified < MIN_TIMESTAMPS)); then
    err "Only $verified verified timestamp(s), MIN_TIMESTAMPS is $MIN_TIMESTAMPS: check the network and retry"
    RESULT=1
  fi
  LOG_FILE=""
  # Without any timestamp the folder proves nothing: removed, so that it is never
  # mistaken for proofs (--list, --verify). Unverified timestamps are kept instead.
  if ((obtained == 0)); then
    rm -rf "$dir" "${dir}.log"
    echo "    Nothing was saved: the empty proof folder was removed."
  fi
}

# ---------------------------------------------------------------------------
# Verify a file against all its proofs
# ---------------------------------------------------------------------------
# One file. Sets RESULT (0 = valid timestamps from at least MIN_TIMESTAMPS different TSAs)
# and RESULT_NOTE; like stamp, it never returns an error code. Also sets V_ABS, V_NAME,
# V_HASH and VALID_DIRS for archive, so that the file is hashed only once.
verify() {
  local file="$1"
  local name abs hash
  abs="$(abs_path "$file")"
  name="$(basename "$abs")"
  hash="$(sha256_of "$abs")"
  V_ABS=$abs V_NAME=$name V_HASH=$hash
  say "File:    $abs"
  say "SHA-256: $hash"

  # Proof folders (next to the script, in DIR given with -d, in the current directory
  # and next to the file, the last two for proofs that were moved there), oldest first.
  # A folder "<name>_<YYYYMMDD>-<HHMMSS>" belongs to this file when it has the same
  # SHA-256, so a renamed copy is still found, or the same name, so that a modified file
  # is reported as such.
  local roots=() root d base pname phash dirs=() searched=""
  for root in "$OUT_ROOT" "$PROOF_ROOT" "$(pwd)/$OUT_DIR_NAME" \
      "$(dirname "$abs")/$OUT_DIR_NAME"; do
    [[ ", $searched, " == *", $root, "* ]] || searched+="${searched:+, }$root"
    [[ -d "$root" ]] && roots+=("$(abs_path "$root")")
  done
  for root in ${roots[@]+"${roots[@]}"}; do
    for d in "$root"/*_*; do
      base="${d##*/}"
      [[ -d "$d" && $base =~ _[0-9]{8}-[0-9]{6}$ ]] || continue
      pname="${base%_*}"
      phash=""
      read -r phash _ 2>/dev/null < "$d/$pname.sha256" || true
      if [[ $pname == "$name" || $phash == "$hash" ]]; then
        dirs+=("$d")
      fi
    done
  done
  if ((${#dirs[@]} == 0)); then
    err "No proofs found for $name in: $searched"
    RESULT=1 RESULT_NOTE="no proofs found"
    return 0
  fi

  local sorted=()
  while IFS= read -r d; do sorted+=("$d"); done < <(printf '%s\n' "${dirs[@]}" | sort -u)
  dirs=("${sorted[@]}")

  local dir tsr tsa cafile untrusted when epoch earliest="" earliest_tsa="" valid=0 dir_valid
  local valid_tsas="" n_tsas=0 since n_tsr tsr_sha seen=" "
  VALID_DIRS=()
  for dir in "${dirs[@]}"; do
    line
    say "Proofs: $(basename "$dir")"
    base="${dir##*/}"
    pname="${base%_*}"
    phash=""
    read -r phash _ 2>/dev/null < "$dir/${pname}.sha256" || true
    if [[ $phash != "$hash" ]]; then
      warn "    different content (SHA-256): the file has been MODIFIED since these proofs"
      warn "    were made, or they are the proofs of another file with the same name"
      continue
    fi
    [[ $pname == "$name" ]] || line "$(printf '    made for the same content under the name: %s' "$pname")"
    dir_valid="" n_tsr=0
    for tsr in "$dir/${pname}".*.tsr; do
      [[ -f "$tsr" ]] || continue
      n_tsr=$((n_tsr + 1))
      tsa="${tsr%.tsr}"; tsa="${tsa##*.}"
      # Only roots this script trusts (TSA_ROOTS): never a root of the proof folder
      if ! trusted_root "$tsa"; then
        line "$(printf '    %-9s NOT VERIFIED  %s' "$tsa" "$ROOT_WHY")"
        continue
      fi
      cafile=$ROOT_CA
      untrusted="$dir/${tsa}-certs.pem"

      when="$(tsr_time "$tsr")"; when="${when#Time stamp: }"
      # An empty string would be parsed by date as today's midnight
      if [[ -z "$when" ]] || ! epoch="$(ts_epoch "$when" 2>/dev/null)"; then
        line "$(printf '    %-9s NOT VERIFIED  unreadable timestamp date: %s' "$tsa" "${when:-<none>}")"
        continue
      fi
      if tsr_verify "$hash" "$tsr" "$cafile" "$untrusted" "$RUN_TMP/verify.txt" "$epoch"; then
        line "$(printf '    %-9s VALID     %s  (local time: %s)' "$tsa" \
          "$(fmt_epoch "$epoch" '+%Y-%m-%d %H:%M:%S UTC' -u)" "$(fmt_epoch "$epoch" '+%Y-%m-%d %H:%M:%S %Z')")"
        dir_valid=1
        # The same proofs kept in two places (e.g. a copy next to the file) are one proof
        tsr_sha=$(sha256_of "$tsr")
        if [[ $seen == *" $tsr_sha "* ]]; then
          line "$(printf '    %-9s           (the same timestamp as above, counted once)' "")"
        else
          seen+="$tsr_sha "
          valid=$((valid + 1))
        fi
        if [[ " $valid_tsas " != *" $tsa "* ]]; then valid_tsas+=" $tsa"; n_tsas=$((n_tsas + 1)); fi
        if [[ -z "$earliest" || "$epoch" -lt "$earliest" ]]; then earliest="$epoch"; earliest_tsa="$tsa"; fi
      elif unknown_root "$RUN_TMP/verify.txt"; then
        line "$(printf '    %-9s NOT VERIFIED  %s' "$tsa" "$when")"
        line "              its certificates lead to no root this script trusts: forged, or"
        line "              signed under a newer root that a newer version of the script knows"
      elif ess_limit "$RUN_TMP/verify.txt"; then
        line "$(printf '    %-9s NOT VERIFIED  %s' "$tsa" "$when")"
        line "$(printf '              this openssl (%s) cannot check the certificate list of %s:' "$(openssl_name)" "$tsa")"
        line '              verify it with OpenSSL 3 (README, "Requirements")'
      else
        line "$(printf '    %-9s NOT VERIFIED  %s' "$tsa" "$when")"
      fi
    done
    ((n_tsr)) || line "    no timestamps in this folder (no TSA answered when it was made)"
    [[ -z $dir_valid ]] || VALID_DIRS+=("$dir")
  done

  line
  if [[ -n "$earliest" ]]; then
    since="$(fmt_epoch "$earliest" '+%d/%m/%Y %H:%M:%S %Z')"
    say "Result: $name existed, unchanged, at least since"
    line "$(printf '    %s  (%s)' "$since" "$earliest_tsa")"
    line "$(printf '    confirmed by %d valid timestamp(s)' "$valid")"
    RESULT_NOTE="existed at least since $since"
    if ((n_tsas < MIN_TIMESTAMPS)); then
      warn "Result: only $n_tsas different TSA(s) confirm it, MIN_TIMESTAMPS is $MIN_TIMESTAMPS"
      RESULT=1 RESULT_NOTE="only $n_tsas TSA(s), $MIN_TIMESTAMPS required"
    fi
  else
    warn "Result: no valid timestamp for the current content of $name"
    RESULT=1 RESULT_NOTE="no valid timestamp"
  fi
}

# ---------------------------------------------------------------------------
# Archive: the file, its valid proofs and this script, to keep or move together
# ---------------------------------------------------------------------------
# One file. Verifies it first: an archive is made only when at least one timestamp is
# valid, and it holds only the proof folders with a valid timestamp. Sets RESULT and
# RESULT_NOTE like stamp and verify. The attachments (ATTACH_FILES, absolute paths) are
# verified too and packed in attachments/ whatever the result: a PEC receipt or a
# registration certificate has a value of its own, without our timestamps. Sets
# ARCHIVE_OUT to the archive made, if any.
archive_file() {
  local file="$1"
  verify "$file"
  ((RESULT == 0)) || { RESULT_NOTE="no archive: $RESULT_NOTE"; return 0; }

  local abs=$V_ABS name=$V_NAME hash=$V_HASH now bundle out tmp d e dup i
  local dirs=("${VALID_DIRS[@]}") n_dirs=${#VALID_DIRS[@]} att_abs=() att_names=()
  local att_hashes=() att_notes=() att n_att_ok=0 att_text="" att_verify=""
  for att in ${ATTACH_FILES[@]+"${ATTACH_FILES[@]}"}; do
    line
    line
    say "Attachment $((${#att_names[@]} + 1)) of ${#ATTACH_FILES[@]}"
    # verify leaves VALID_DIRS untouched when no proof folder is found
    RESULT=0 RESULT_NOTE="" VALID_DIRS=()
    verify "$att"
    att_abs+=("$V_ABS"); att_names+=("$V_NAME"); att_hashes+=("$V_HASH")
    if ((RESULT == 0)); then
      att_notes+=("timestamped: $RESULT_NOTE")
      att_verify+="  ./$PUBLISHED_NAME --verify \"$ATTACH_DIR_NAME/$V_NAME\""$'\n'
      n_att_ok=$((n_att_ok + 1))
    else
      att_notes+=("NOT confirmed by this script's timestamps ($RESULT_NOTE)")
      warn "Packed anyway as an attachment, without valid timestamps: $V_NAME"
    fi
    for d in ${VALID_DIRS[@]+"${VALID_DIRS[@]}"}; do
      dup=""
      for e in "${dirs[@]}"; do [[ $e != "$d" ]] || dup=1; done
      [[ -n $dup ]] || dirs+=("$d")
    done
  done
  RESULT=0 RESULT_NOTE=""

  now="$(date -u +%Y%m%d-%H%M%S)"
  bundle="${name}_bundle_${now}"
  out="${ARCHIVE_ROOT}/${bundle}.tar"
  # Like stamp: an archive of the same file in the same second waits for the next one
  if [[ -e "$out" ]]; then
    sleep 1
    now="$(date -u +%Y%m%d-%H%M%S)"
    bundle="${name}_bundle_${now}"
    out="${ARCHIVE_ROOT}/${bundle}.tar"
  fi
  if [[ -e "$out" ]]; then
    err "Archive already exists: $out"
    RESULT=1 RESULT_NOTE="archive already exists"
    return 0
  fi
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/ndm_file-timestamp.XXXXXX")"
  CLEANUP+=("$tmp" "$out.partial")
  mkdir -p "$tmp/$bundle/$OUT_DIR_NAME"
  cp -p "$abs" "$tmp/$bundle/$name"
  for d in "${dirs[@]}"; do
    cp -Rp "$d" "$tmp/$bundle/$OUT_DIR_NAME/"
    [[ ! -f "$d.log" ]] || cp -p "$d.log" "$tmp/$bundle/$OUT_DIR_NAME/"
  done
  if ((${#att_names[@]})); then
    mkdir "$tmp/$bundle/$ATTACH_DIR_NAME"
    for i in "${!att_names[@]}"; do
      cp -p "${att_abs[i]}" "$tmp/$bundle/$ATTACH_DIR_NAME/${att_names[i]}"
      att_text+="        ${att_names[i]}"$'\n'"            ${att_notes[i]}"$'\n'
    done
  fi
  # The checked TSA roots, so that the archive verifies offline even if a TSA is gone:
  # the script inside the archive accepts them only if their SHA-256 is in TSA_ROOTS
  [[ -n $ROOTS_SCANNED ]] || scan_roots
  while IFS= read -r e; do
    [[ -n $e ]] || continue
    mkdir -p "$tmp/$bundle/$CERTS_DIR_NAME"
    cp -p "${e#*|}" "$tmp/$bundle/$CERTS_DIR_NAME/$(root_name "${e%%|*}")"
  done <<< "$ROOT_FILES"
  # Always under its published name, so that it can be compared with the released file
  cp -p "$SCRIPT_PATH" "$tmp/$bundle/$PUBLISHED_NAME"
  # The license must travel with the program (GNU AGPL)
  [[ ! -f "$SCRIPT_DIR/LICENSE" ]] || cp -p "$SCRIPT_DIR/LICENSE" "$tmp/$bundle/LICENSE"
  {
    printf '%s  %s\n' "$hash" "$name"
    for i in ${att_names[@]+"${!att_names[@]}"}; do
      printf '%s  %s\n' "${att_hashes[i]}" "$ATTACH_DIR_NAME/${att_names[i]}"
    done
    printf '%s  %s\n' "$SCRIPT_SHA" "$PUBLISHED_NAME"
  } > "$tmp/$bundle/SHA256SUMS"
  write_bundle_readme "$tmp/$bundle" "$name" "$PUBLISHED_NAME" "$att_text" "$att_verify" \
    "$([[ -d "$tmp/$bundle/$CERTS_DIR_NAME" ]] && echo 1)"

  # The copies in the archive must be byte for byte the files that were verified
  if [[ "$(sha256_of "$tmp/$bundle/$name")" != "$hash" ]]; then
    rm -rf "$tmp"
    err "The copy of $name differs from the original: archive not created"
    RESULT=1 RESULT_NOTE="archive not created"
    return 0
  fi
  for i in ${att_names[@]+"${!att_names[@]}"}; do
    if [[ "$(sha256_of "$tmp/$bundle/$ATTACH_DIR_NAME/${att_names[i]}")" != "${att_hashes[i]}" ]]; then
      rm -rf "$tmp"
      err "The copy of the attachment ${att_names[i]} differs from the original: archive not created"
      RESULT=1 RESULT_NOTE="archive not created"
      return 0
    fi
  done
  # "./" so that a name starting with "-" is not read as an option by tar. Not compressed:
  # the files people timestamp (zip, pdf, images) are mostly compressed already, and gzip
  # would take ten times longer for almost no space saved
  if ! tar -C "$tmp" -cf "$out.partial" "./$bundle" 2>/dev/null \
      || ! tar -tf "$out.partial" >/dev/null 2>&1; then
    rm -rf "$tmp" "$out.partial"
    err "Could not create the archive $out"
    RESULT=1 RESULT_NOTE="archive not created"
    return 0
  fi
  mv "$out.partial" "$out"
  rm -rf "$tmp"
  line
  say "Archive: $out"
  line "    $name, $n_dirs proof folder(s), $PUBLISHED_NAME $APP_VERSION and its LICENSE."
  if ((${#att_names[@]})); then
    line "    $ATTACH_DIR_NAME/: ${#att_names[@]} file(s), $n_att_ok with valid timestamps."
  fi
  line "    To check it later: extract it, then run in the extracted folder"
  line "      ./$PUBLISHED_NAME --verify \"$name\""
  while IFS= read -r e; do
    [[ -z $e ]] || line "    $e"
  done <<< "$att_verify"
  RESULT_NOTE="archive $(basename "$out")"
  ((${#att_names[@]} == 0)) || RESULT_NOTE+=", ${#att_names[@]} attachment(s)"
  ARCHIVE_OUT=$out
}

# Like stamp, every line shown is also written to a log of the run; the name of the
# archive is known only at the end, so the log is kept aside until then, and moved next
# to the archive (<archive>.log) only if the archive was made.
archive() {
  ARCHIVE_OUT=""
  run_tmp
  LOG_FILE="$RUN_TMP/archive.log"
  : > "$LOG_FILE" 2>/dev/null || LOG_FILE=""
  archive_file "$1"
  if [[ -n $ARCHIVE_OUT && -n $LOG_FILE ]]; then
    mv "$LOG_FILE" "${ARCHIVE_OUT%.tar}.log" 2>/dev/null || true
  fi
  rm -f "$RUN_TMP/archive.log"
  LOG_FILE=""
}

# README.txt of an archive. The 4th argument lists the attachments (one name and one
# status line each), the 5th the --verify lines of the timestamped ones; both are empty
# without attachments. The 6th is not empty when the archive holds CERTS_DIR_NAME.
write_bundle_readme() {
  local dir="$1" name="$2" script="$3" att_text="${4:-}" att_verify="${5:-}" certs="${6:-}"
  local sums="SHA-256 of the file and of the script (sha256sum -c SHA256SUMS;
      macOS: shasum -a 256 -c SHA256SUMS)"
  if [[ -n $att_text ]]; then
    att_text=${att_text%$'\n'}
    sums="SHA-256 of the file, of the attachments and of the script
      (sha256sum -c SHA256SUMS; macOS: shasum -a 256 -c SHA256SUMS)"
  fi
  {
    cat <<EOF
Timestamp archive for: $name
==========================================================

Made on $(date -u '+%Y-%m-%d %H:%M:%S UTC') (local clock) with $APP_NAME $APP_VERSION.
Keep this archive as it is: it holds everything needed to verify the timestamps.

Contents
  $name
      the file, byte for byte the one that was timestamped
  $OUT_DIR_NAME/
      its proofs: RFC 3161 timestamps, certificates, README.txt with manual steps
EOF
    if [[ -n $att_text ]]; then
      cat <<EOF
  $ATTACH_DIR_NAME/
      documents that go with the file (e.g. a signed declaration, receipts);
      their proofs, if any, are in $OUT_DIR_NAME/ too. One that is
      not confirmed by this script's timestamps has only the value it has on
      its own (e.g. a PEC receipt):
$att_text
EOF
    fi
    if [[ -n $certs ]]; then
      cat <<EOF
  $CERTS_DIR_NAME/
      the root certificates of the TSAs, used by the script only if their
      SHA-256 is the one written in it (TSA_ROOTS), which anyone can compare
      with the value the TSA publishes; so the archive verifies even offline
EOF
    fi
    cat <<EOF
  $script
      the script that made and verifies the proofs (version $APP_VERSION)
  LICENSE
      the license of the script (GNU AGPL v3)
  SHA256SUMS
      $sums

Verify, from inside this folder:
  ./$script --verify "$name"
EOF
    printf '%s' "$att_verify"
    cat <<EOF
or by hand with openssl, as described in the README.txt of each proof folder.

The script is published at $APP_URL
(tag v$APP_VERSION): its SHA-256 in SHA256SUMS can be compared with that version.
EOF
  } > "$dir/README.txt"
}

# ---------------------------------------------------------------------------
# List the saved proofs
# ---------------------------------------------------------------------------
list_proofs() {
  local d base name run n t hash rows=()
  say "Proofs in $PROOF_ROOT"
  for d in "$PROOF_ROOT"/*_*; do
    [[ -d "$d" ]] || continue
    base="${d##*/}"
    [[ $base =~ _([0-9]{8})-([0-9]{6})$ ]] || continue
    run="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}"
    name="${base%_*}"
    [[ -f "$d/$name.sha256" ]] || continue
    n=0
    for t in "$d/$name".*.tsr; do [[ -f "$t" ]] && n=$((n + 1)); done
    hash=""
    read -r hash _ 2>/dev/null < "$d/$name.sha256" || true
    rows+=("$run|$n|${hash:0:16}|$name")
  done
  if ((${#rows[@]} == 0)); then
    echo "    none"
    return 0
  fi
  printf '    %-19s  %-10s  %-16s  %s\n' "Run (UTC)" "Timestamps" "SHA-256 (start)" "File"
  while IFS='|' read -r run n hash name; do
    printf '    %s-%s-%s %s:%s:%s  %-10s  %-16s  %s\n' "${run:0:4}" "${run:4:2}" "${run:6:2}" \
      "${run:9:2}" "${run:11:2}" "${run:13:2}" "$n" "$hash" "$name"
  done < <(printf '%s\n' "${rows[@]}" | sort)
  echo
  echo "    ${#rows[@]} proof folder(s). The run dates come from the local clock; the dates"
  echo "    that count are those signed by the TSAs: see them with --verify FILE."
}

# ---------------------------------------------------------------------------
# README kept with the proofs
# ---------------------------------------------------------------------------
# The trusted root certificates, as listed in the README.txt of every proof folder
roots_table() {
  local e r_tsa r_url r_sha r_fp
  for e in "${TSA_ROOTS[@]}"; do
    IFS='|' read -r r_tsa r_url r_sha r_fp <<< "$e"
    printf '       %-9s %s\n' "$r_tsa" "$(root_name "$r_sha")"
    printf '       %-9s SHA-256 %s\n' "" "$r_sha"
  done
}

write_readme() {
  local dir="$1" name="$2"
  cat > "$dir/README.txt" <<EOF
Timestamp proofs for: $name
==========================================================

Keep this folder together with an UNCHANGED copy of $name.

Contents
  file-info.txt          SHA-256, size, last-modified date of the file
  $name.sha256           SHA-256 checksum (sha256sum -c; macOS: shasum -a 256 -c)
  $name.tsq              RFC 3161 request (contains only the hash)
  $name.<tsa>.tsr        RFC 3161 timestamp signed by <tsa>   <- THE PROOF
  $name.<tsa>.txt        Human-readable timestamp (look for "Time stamp")
  <tsa>-certs.pem        Certificates needed to verify the .tsr
  <tsa>-<SHA-256>.pem/.crt  Copy of the root certificate of <tsa> (see step 2)
  <tsa>-verify.txt       Result of the verification done when stamping
Next to this folder, <this folder>.log is the report of the run, as shown on screen.

Manual verification (example: FreeTSA)
  1. The file is unchanged, from the folder that contains $name:
       sha256sum -c "<this folder>/$name.sha256"     (macOS: shasum -a 256 -c ...)
  2. The root certificate is the real one: its SHA-256 (sha256sum FILE; macOS:
     shasum -a 256 FILE) must be the value the TSA publishes, the same as here:
$(roots_table)
     Never trust a root certificate only because it is next to the proofs.
     (If the TSA has reformatted its file, compare instead the certificate
     fingerprint: openssl x509 -in FILE -noout -fingerprint -sha256)
  3. The timestamp is valid, from INSIDE this folder (openssl does not accept spaces
     in the -untrusted path, so the certificate files are given by name):
       openssl ts -verify -data "<path of $name>" -in "$name.freetsa.tsr" \\
           -CAfile $(root_name "$(roots_of freetsa)") -untrusted freetsa-certs.pem
     A .crt root (DigiCert, Sectigo) must first be converted to PEM, e.g.:
       openssl x509 -inform DER -in $(root_name "$(roots_of digicert)") -out digicert-root.pem
     then use -CAfile digicert-root.pem.
If the TSA certificate has expired, add: -attime <epoch of the "Time stamp" line>
  (e.g. -attime \$(date -d "Oct 26 05:06:07 2026 GMT" +%s); on macOS:
   -attime \$(date -j -u -f '%b %d %H:%M:%S %Y %Z' "Oct 26 05:06:07 2026 GMT" +%s))

Legal note
  These proofs are technical evidence, freely assessed by a judge. They are not
  "data certa" in the strict sense of Italian law (qualified eIDAS timestamp or PEC).
EOF
}

# ---------------------------------------------------------------------------
# Is this script the one published for its version? 0 = same, 1 = different,
# 2 = cannot tell (no network, or this version is not published). This catches damage and
# careless edits; a deliberate attacker could change this check too, so the independent
# check in the README (sha256sum of the published file) is the one that really counts.
# Afterwards it says whether a newer release exists and how to update: information only,
# the return code is the one of the comparison. "offer" (only --check-script, never before
# a stamp) also offers to update a git clone right away.
script_check() {
  local rc=0
  script_compare || rc=$?
  release_check "${1:-}"
  return "$rc"
}

script_compare() {
  local raw tmp mine theirs
  raw="https://raw.githubusercontent.com/${APP_URL#https://github.com/}/v${APP_VERSION}/${PUBLISHED_NAME}"
  have curl || { warn "Script check: curl is missing, cannot compare with the published version"; return 2; }
  tmp="$(mktemp "${TMPDIR:-/tmp}/ndm_file-timestamp.XXXXXX")"
  if ! curl -fsS -m 30 --max-filesize "$MAX_DOWNLOAD_BYTES" "$raw" -o "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    warn "Script check: cannot compare with the published v$APP_VERSION (no network, or not published)"
    warn "    $raw"
    return 2
  fi
  load_script_sha
  mine=$SCRIPT_SHA
  theirs="$(sha256_of "$tmp")"
  rm -f "$tmp"
  if [[ $mine == "$theirs" ]]; then
    say "Script check: identical to the published v$APP_VERSION (SHA-256 $mine)"
    return 0
  fi
  err "Script check: this script is DIFFERENT from the published v$APP_VERSION"
  err "    this script:  $mine  $SCRIPT_PATH"
  err "    published:    $theirs  $raw"
  err "    It may have been modified: download it again from $APP_URL"
  return 1
}

# Is version $1 newer than $2? Both X.Y.Z; compared field by field as numbers (sort -V
# is missing on macOS)
version_newer() {
  local a b i
  IFS=. read -r -a a <<< "$1"
  IFS=. read -r -a b <<< "$2"
  for i in 0 1 2; do
    ((10#${a[i]} == 10#${b[i]})) || { ((10#${a[i]} > 10#${b[i]})); return; }
  done
  return 1
}

# The latest release comes from the redirect of .../releases/latest to .../releases/tag/vX.Y.Z:
# no JSON to parse and no API rate limit. Anything else (no network, no release, another
# page) means "cannot tell", never a wrong answer.
release_check() {
  local page="$APP_URL/releases/latest" url="" latest re
  have curl || return 0
  url="$(curl -sS -m 30 --max-filesize "$MAX_DOWNLOAD_BYTES" -o /dev/null \
              -w '%{redirect_url}' "$page" 2>/dev/null)" || url=""
  re="^$APP_URL/releases/tag/v((0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8}))$"
  if [[ ! $url =~ $re ]]; then
    warn "Script check: cannot tell whether a newer version exists (no network, or no answer from GitHub)"
    return 0
  fi
  latest=${BASH_REMATCH[1]}
  if version_newer "$latest" "$APP_VERSION"; then
    warn "Script check: a newer version v$latest is available: $url"
    update_help "$1"
  elif [[ $latest == "$APP_VERSION" ]]; then
    say "Script check: v$APP_VERSION is the latest version"
  else
    say "Script check: v$APP_VERSION is newer than the latest published version (v$latest)"
  fi
}

# Why the folder of this script cannot be updated with git pull, or nothing when it can:
# a clone of this repository, on branch main, without local changes to versioned files
# (proofs, certificates and settings are not versioned, so they never count)
git_update_blocker() {
  local top origin re
  have git || { echo "git is not installed"; return; }
  top="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)" || top=""
  [[ -n $top && $(cd "$top" && pwd -P) == "$SCRIPT_DIR" ]] \
    || { echo "the script folder is not a git clone"; return; }
  origin="$(git -C "$SCRIPT_DIR" config --get remote.origin.url 2>/dev/null)" || origin=""
  re="^(https://github\.com/|git@github\.com:|ssh://git@github\.com/)${APP_URL#https://github.com/}(\.git)?/?$"
  [[ $origin =~ $re ]] || { echo "the clone does not come from $APP_URL"; return; }
  [[ $(git -C "$SCRIPT_DIR" symbolic-ref --short -q HEAD) == main ]] \
    || { echo "the clone is not on branch main"; return; }
  [[ -z $(git -C "$SCRIPT_DIR" status --porcelain --untracked-files=no) ]] \
    || echo "the clone has local changes (git status shows them)"
}

# How to update, after the notice of a newer version. In a clean git clone, with "offer"
# and a terminal, it asks and runs git pull; then it stops, because bash reads a script
# while running it, and the new file must not be run halfway. Never without asking.
update_help() {
  local why cmd ans="" new
  why="$(git_update_blocker)"
  if [[ -n $why ]]; then
    warn "    To update, see \"Updating\" in the README: $APP_URL#updating"
    have git && warn "    (no automatic update: $why)"
    return 0
  fi
  cmd="git -C $(printf '%q' "$SCRIPT_DIR") pull --ff-only"
  warn "    This is a git clone of the repository: update it with"
  warn "      $cmd"
  [[ $1 == offer && -t 0 && -t 2 ]] || return 0
  printf 'Update now? [Y/n] ' >&2
  read -r ans || ans=n
  [[ -z $ans || $ans == [Yy]* ]] || return 0
  if ! git -C "$SCRIPT_DIR" pull --ff-only >&2; then
    err "Update failed: see the message above, or \"Updating\" in the README"
    return 0
  fi
  new="$(sed -n 's/^APP_VERSION="\(.*\)"$/\1/p' "$SCRIPT_PATH")"
  say "Updated: the script is now v${new:-?}. Run --check-script again to compare it with"
  say "    the published version, then run your command again."
  exit 0
}

# ---------------------------------------------------------------------------
# Invalid command-line usage: message on stderr, exit code 2
bad_usage() { printf '%s (see --help)\n' "$1" >&2; exit 2; }
# Invalid value in the config file or the environment: exit code 2 too
bad_setting() {
  local from="the environment"
  [[ ! -r $CONFIG_FILE ]] || from="$CONFIG_FILE or the environment"
  printf 'Invalid setting: %s (from %s)\n' "$1" "$from" >&2
  exit 2
}

# Temporary files (archive being built, certificate being downloaded): removed at the end,
# also when the run is interrupted (Ctrl-C), so that nothing half-made is left behind
CLEANUP=()
cleanup() { ((${#CLEANUP[@]} == 0)) || rm -rf "${CLEANUP[@]}"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# The informational options work only alone
case "${1:-}" in
  "") usage; exit 0 ;;
  -h|--help|-v|--version|--requirements|--check-script|--get-certs|--verify-certs)
    (($# == 1)) || bad_usage "Option $1 takes no argument"
    case $1 in
      -h|--help) usage ;;
      -v|--version) version_info ;;
      --requirements) requirements_help ;;
      --check-script) rc=0; script_check offer || rc=$?; ((rc == 0)) || exit 1 ;;
      --get-certs) get_certs || exit 1 ;;
      --verify-certs) verify_certs || exit 1 ;;
    esac
    exit 0 ;;
esac

MODE="" OUT_DIR_CLI="" FILES=() ATTACH_ARGS=()
set_mode() {
  [[ -z $MODE || $MODE == "$1" ]] || bad_usage "Only one of --verify, --list and --archive can be used"
  MODE=$1
}
while (($#)); do
  case $1 in
    --verify) set_mode verify ;;
    -l|--list) set_mode list ;;
    -a|--archive) set_mode archive ;;
    -d|--output-dir)
      if (($# < 2)) || [[ -z $2 || $2 == -* ]]; then bad_usage "Option $1 needs a directory"; fi
      OUT_DIR_CLI=$2; shift ;;
    --output-dir=*)
      OUT_DIR_CLI=${1#*=}
      [[ -n $OUT_DIR_CLI ]] || bad_usage "Option --output-dir needs a directory" ;;
    --attach)
      if (($# < 2)) || [[ -z $2 || $2 == -* ]]; then bad_usage "Option $1 needs a file or a folder"; fi
      ATTACH_ARGS+=("$2"); shift ;;
    --attach=*)
      [[ -n ${1#*=} ]] || bad_usage "Option --attach needs a file or a folder"
      ATTACH_ARGS+=("${1#*=}") ;;
    -h|--help|-v|--version|--requirements|--check-script|--get-certs|--verify-certs) bad_usage "Option $1 must be used alone" ;;
    --) shift; FILES+=("$@"); break ;;
    -*) bad_usage "Unknown option: $1" ;;
    *) FILES+=("$1") ;;
  esac
  shift
done
MODE=${MODE:-stamp}
# Attachments belong to one work: with several files it would be unclear to which
if ((${#ATTACH_ARGS[@]})); then
  [[ $MODE == archive ]] || bad_usage "Option --attach works only with --archive"
  ((${#FILES[@]} == 1)) || bad_usage "Option --attach needs exactly one FILE to archive"
fi

# Settings from the config file or the environment
[[ $COLORS == on || $COLORS == off ]] || bad_setting "COLORS=$COLORS (on or off)"
[[ $SCRIPT_CHECK == on || $SCRIPT_CHECK == off ]] || bad_setting "SCRIPT_CHECK=$SCRIPT_CHECK (on or off)"
TSA_ACTIVE=()
for want in ${TSAS//,/ }; do
  found=""
  for entry in "${TSA_CATALOG[@]}"; do
    if [[ ${entry%%|*} == "$want" ]]; then
      [[ " ${TSA_ACTIVE[*]+${TSA_ACTIVE[*]}} " == *" $entry "* ]] || TSA_ACTIVE+=("$entry")
      found=1
    fi
  done
  [[ -n $found ]] || bad_setting "TSAS: unknown TSA '$want' (known: freetsa digicert sectigo)"
done
((${#TSA_ACTIVE[@]})) || bad_setting "TSAS is empty"
# No leading zero: bash would read "08" as a wrong octal number
if ! [[ $MIN_TIMESTAMPS =~ ^[1-9][0-9]?$ ]] || ((MIN_TIMESTAMPS > ${#TSA_ACTIVE[@]})); then
  bad_setting "MIN_TIMESTAMPS=$MIN_TIMESTAMPS (a number from 1 to ${#TSA_ACTIVE[@]}, the TSAs in TSAS)"
fi

# Where the proofs are saved (and listed): DIR from -d (relative to the current
# directory), else OUTPUT_DIR (relative to the script folder), else next to the script
if [[ -n $OUT_DIR_CLI ]]; then
  [[ $OUT_DIR_CLI == /* ]] || OUT_DIR_CLI="$(pwd)/$OUT_DIR_CLI"
  PROOF_ROOT=${OUT_DIR_CLI%/}
elif [[ -n $OUTPUT_DIR ]]; then
  [[ $OUTPUT_DIR == /* ]] || OUTPUT_DIR="$SCRIPT_DIR/$OUTPUT_DIR"
  PROOF_ROOT=${OUTPUT_DIR%/}
else
  PROOF_ROOT=$OUT_ROOT
fi
# Where --archive writes: ARCHIVE_DIR (relative to the script folder), else the archive
# folder next to the script
if [[ -n $ARCHIVE_DIR ]]; then
  [[ $ARCHIVE_DIR == /* ]] || ARCHIVE_DIR="$SCRIPT_DIR/$ARCHIVE_DIR"
  ARCHIVE_ROOT=${ARCHIVE_DIR%/}
else
  ARCHIVE_ROOT="${SCRIPT_DIR}/${ARCHIVE_DIR_NAME}"
fi

if [[ $MODE == list ]]; then
  ((${#FILES[@]} == 0)) || bad_usage "Option --list takes no file"
  list_proofs
  exit 0
fi
((${#FILES[@]})) || bad_usage "No file given"

# Every file must exist and be readable before anything is sent to a TSA or checked
check_file() {
  [[ ! -d "$1" ]] || die "$1 is a folder: pack it into one file first (e.g. a zip), then stamp that file"
  [[ -f "$1" || ! -e "$1" ]] || die "$1 is not a regular file (a pipe or a device?)"
  [[ -f "$1" ]] || die "File not found: $1"
  [[ -r "$1" ]] || die "Cannot read $1 (permissions)"
}
for f in "${FILES[@]}"; do
  check_file "$f"
done
# Attachments: each file, or every file directly inside a folder (hidden files and
# subfolders skipped), as absolute paths without duplicates. Their names must differ
# from each other and from the file, so that each keeps its own proofs in the archive.
ATTACH_FILES=()
attach_add() {
  local a n prev
  [[ -r "$1" ]] || die "Cannot read the attachment $1 (permissions)"
  a="$(abs_path "$1")"
  n="${a##*/}"
  [[ $n != "$(basename "$(abs_path "${FILES[0]}")")" ]] || die "An attachment has the same name as the file to archive: $1"
  for prev in ${ATTACH_FILES[@]+"${ATTACH_FILES[@]}"}; do
    [[ $prev != "$a" ]] || return 0
    [[ ${prev##*/} != "$n" ]] || die "Two attachments have the same name: $n"
  done
  ATTACH_FILES+=("$a")
}
for a in ${ATTACH_ARGS[@]+"${ATTACH_ARGS[@]}"}; do
  if [[ -d "$a" ]]; then
    found=""
    for f in "$a"/*; do
      [[ -f "$f" ]] || continue
      attach_add "$f"
      found=1
    done
    [[ -n $found ]] || die "No files in the attachment folder: $a"
  elif [[ -f "$a" ]]; then
    attach_add "$a"
  else
    die "Attachment not found: $a"
  fi
done
if [[ $SCRIPT_CHECK == on ]]; then
  rc=0; script_check || rc=$?
  ((rc != 1)) || die "Stopped: the script differs from the published version (SCRIPT_CHECK=on)"
  echo
fi
if [[ $MODE == stamp ]]; then
  check_requirements
  # Without -attime (LibreSSL) a new timestamp is checked at the current date: it works
  # as long as the clock is right, so no warning is needed here
  ts_attime_supported || TS_ATTIME=""
  ensure_roots
  warn_expiring_roots
  # The default folder is versioned empty (only .gitkeep); created again if it was removed
  mkdir -p "$PROOF_ROOT" 2>/dev/null || die "Cannot create $PROOF_ROOT: is that folder writable?"
else
  check_requirements openssl sha256sum     # curl only to download missing root certificates
  ensure_roots
  if [[ $MODE == archive ]]; then
    have tar || die "Missing: tar (needed by --archive)"
    # The default folder is versioned empty (only .gitkeep); created again if it was removed
    mkdir -p "$ARCHIVE_ROOT" 2>/dev/null || die "Cannot create $ARCHIVE_ROOT: is that folder writable?"
  fi
  if ! ts_attime_supported; then
    TS_ATTIME=""
    warn "this openssl has no -attime (LibreSSL?): a timestamp whose TSA certificate has"
    warn "expired will not verify. OpenSSL 3 does not have this limit (README, \"Requirements\")."
  fi
fi
[[ $MODE == verify ]] || load_script_sha

failed=0 overview="" first=1
for f in "${FILES[@]}"; do
  ((first)) || { echo; echo; }
  first=0
  RESULT=0 RESULT_NOTE=""
  "$MODE" "$f"
  if ((RESULT == 0)); then
    overview+="$(printf '    OK  %s  (%s)' "$f" "$RESULT_NOTE")"$'\n'
  else
    failed=$((failed + 1))
    overview+="$(printf '    NO  %s  (%s)' "$f" "$RESULT_NOTE")"$'\n'
  fi
done
if ((${#FILES[@]} > 1)); then
  echo
  echo
  case $MODE in
    stamp) say "All files: $((${#FILES[@]} - failed)) of ${#FILES[@]} got verified timestamps" ;;
    verify) say "All files: $((${#FILES[@]} - failed)) of ${#FILES[@]} verified" ;;
    archive) say "All files: $((${#FILES[@]} - failed)) of ${#FILES[@]} archived" ;;
  esac
  printf '%s' "$overview"
fi
((failed == 0)) || exit 1
