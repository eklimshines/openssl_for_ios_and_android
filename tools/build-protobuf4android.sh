#!/bin/bash
#
# Copyright 2016 leenjewel
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -u

SOURCE="$0"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
pwd_path="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

source ./_shared.sh

# Setup architectures, library name and other vars + cleanup from previous runs
ARCHS=("android" "android-armeabi" "android64-aarch64" "android-x86" "android64" "android-mips" "android-mips64")
OUTNAME=("armeabi" "armeabi-v7a" "arm64-v8a" "x86" "x86_64" "mips" "mips64")
TOOLS_ROOT=${pwd_path}
LIB_NAME="protobuf"
LIB_VERSION="3.1.0"
LIB_FILENAME=${LIB_NAME}-${LIB_VERSION}
LIB_DEST_DIR=${TOOLS_ROOT}/../output/android
NDK=$ANDROID_NDK_ROOT
ANDROID_API="23"
# rm -rf ${LIB_DEST_DIR}
[ -f ${LIB_FILENAME}.tar.gz ] || wget https://github.com/google/${LIB_NAME}/archive/v${LIB_VERSION}.tar.gz -O ${LIB_FILENAME}.tar.gz
# Unarchive library, then configure and make for specified architectures
configure_make() {
  ARCH=$1; OUT=$2;
  
  [ -d ${LIB_FILENAME} ] && rm -rf "${LIB_FILENAME}"
  tar xfz "${LIB_FILENAME}.tar.gz"
  pushd "${LIB_FILENAME}";

  PREFIX_DIR=${LIB_DEST_DIR}/protobuf-android-${OUT}
  if [ -d "${PREFIX_DIR}" ]; then
      rm -fr ${PREFIX_DIR}
  fi

  export LDFLAGS="-static-libstdc++"
  export LIBS="-lc++_static -latomic"
  configure $* "clang"
  # fix CXXFLAGS
  export CXXFLAGS=${CXXFLAGS/"-finline-limit=64"/""}
  ./autogen.sh
  ./configure --prefix=${PREFIX_DIR} \
              --with-sysroot=${SYSROOT} \
              --with-protoc=`which protoc` \
              --with-zlib \
              --host=${TOOL} \
              --enable-static \
              --disable-shared \
              --enable-cross-compile
  PATH=$TOOLCHAIN_PATH:$PATH
  if make -j4
  then
    mkdir -p ${LIB_DEST_DIR}/${OUT}
    make install
  fi;
  popd;
}



for ((i=0; i < ${#ARCHS[@]}; i++))
do
  if [[ $# -eq 0 ]] || [[ "$1" == "${ARCHS[i]}" ]]; then
    configure_make "${ARCHS[i]}" "${OUTNAME[i]}"
  fi
done