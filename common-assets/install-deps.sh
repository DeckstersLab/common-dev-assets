#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

# Determine OS type
if [[ $OSTYPE == 'darwin'* ]]; then
  OS="darwin"
else
  OS="linux"
fi

# Function to download files
function download {

  binary=$1
  version=$2
  url=$3
  file=$4
  sumfile=$5
  tmp_dir=$6

  echo
  echo "-- Downloading ${binary} ${version}..."
  curl --retry 3 -fLsS "${url}/${file}" --output "${tmp_dir}/${file}"

  if [ "${sumfile}" != "" ]; then
    curl --retry 3 -fLsS "${url}/${sumfile}" --output "${tmp_dir}/${sumfile}"
  else
    echo "No checksum file passed, skipping verification."
  fi

}

# Function to verify checksum of download file
function verify {

  file=$1
  sumfile=$2
  tmp_dir=$3

  echo "Verifying.."
  checksum=$(< "${tmp_dir}/${sumfile}" grep "${file}" | awk '{ print $1 }')
  echo "${checksum} ${tmp_dir}/${file}" | sha256sum -c

}

# Function to verify checksum of download file (when binary name not in sumfile)
function verify_alternative {

  file=$1
  sumfile=$2
  tmp_dir=$3

  echo "Verifying.."
  checksum=$(cat "${tmp_dir}/${sumfile}")
  echo "${checksum} ${tmp_dir}/${file}" | sha256sum -c

}

# Function to copy and replace binary in /usr/local/bin
function copy_replace_binary {

  binary=$1
  tmp_dir=$2
  dir=/usr/local/bin

  echo "Placing ${binary} binary in ${dir} and making executable.."
  arg=""
  if ! [ -w "${dir}" ]; then
    echo "No write permission to $dir. Attempting to run with sudo..."
    arg=sudo
  fi
  # Need to delete if exists already in case it is a symlink which cannot be overwritten using cp -r
  ${arg} rm -f "${dir}/${binary}"
  ${arg} cp -r "${tmp_dir}/${binary}" "${dir}"
  ${arg} chmod +x "${dir}/${binary}"

}

# Cleanup function
function clean {

  tmp_dir=$1

  echo "Deleting tmp dir: ${tmp_dir}"
  rm -rf "${tmp_dir}"
  echo "COMPLETE"

}

#######################################
# sha256sum
#######################################

if ! sha256sum --version &> /dev/null; then
  # If sha256sum not detected on mac, install coreutils
  if [ "$OS" == "darwin" ]; then
    echo
    echo "-- Installing coreutils..."
    brew install coreutils
  else
    echo "sha256sum must be installed to verify downloads. Please install and retry."
    exit 1
  fi
fi

#######################################
# python
#######################################

if python3 --version &> /dev/null; then
  PYTHON=python3
elif python --version &> /dev/null; then
  PYTHON=python3
else
  echo "python or python3 not detected. Please install python, ensure it is on your \$PATH, and retry."
  exit 1
fi

#######################################
# pip
#######################################

if ! ${PYTHON} -m pip &> /dev/null; then
  echo "Unable to detect pip after running: ${PYTHON} -m pip. Please ensure pip is installed and try again."
  exit 1
fi

#######################################
# pre-commit
#######################################

PRE_COMMIT_VERSION=v2.20.0
PACKAGE=pre-commit
echo
echo "-- Installing ${PACKAGE} ${PRE_COMMIT_VERSION}..."
${PYTHON} -m pip install -q --upgrade ${PACKAGE}==${PRE_COMMIT_VERSION}
echo "COMPLETE"


#######################################
# Shellcheck
#######################################

SHELLCHECK_VERSION=v0.8.0
BINARY=shellcheck
FILE_NAME="shellcheck-${SHELLCHECK_VERSION}.${OS}.x86_64.tar.xz"
URL="https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}"
SUMFILE=""
TMP_DIR=$(mktemp -d /tmp/${BINARY}-XXXXX)

download ${BINARY} ${SHELLCHECK_VERSION} ${URL} ${FILE_NAME} "${SUMFILE}" "${TMP_DIR}"
tar -xf "${TMP_DIR}/${FILE_NAME}" -C "${TMP_DIR}"
copy_replace_binary ${BINARY} "${TMP_DIR}/${BINARY}-${SHELLCHECK_VERSION}"
clean "${TMP_DIR}"
