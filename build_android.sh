#!/bin/sh

#set -e

OPENSSL="openssl-3.6.0"
ANDROID_API=24


if [ -n "$ANDROID_NDK_ROOT" ]; then
    echo "[INFO] Using global ANDROID_NDK_ROOT: $ANDROID_NDK_ROOT"
else
    echo "[INFO] ANDROID_NDK_ROOT not set, setting to default value"
    export ANDROID_NDK_ROOT="/Users/przemek/Library/Android/ndk-r27d"
fi

if [ ! -d "$ANDROID_NDK_ROOT" ]; then
  echo "[ERROR] NDK not found in $ANDROID_NDK_ROOT"
  exit 1
fi

archs=(armeabi-v7a arm64-v8a x86 x86_64)
#archs=(x86)

TOOLCHAIN_BIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin"
export PATH=$TOOLCHAIN_BIN:$PATH

WORKDIR=`pwd`"/work"
if [ ! -e "$WORKDIR" ]; then
 echo "No such $WORKDIR directory"
 exit 1
fi

LIBDIR=`pwd`"/libs"
cd $WORKDIR

OPENSSLURL="https://github.com/openssl/openssl/releases/download/${OPENSSL}/${OPENSSL}.tar.gz"
if [ ! -e "$OPENSSL.tar.gz" ]; then
  echo "[INFO] OpenSSL not found, downloading using $OPENSSLURL"
  curl -LO $OPENSSLURL
  
  if [ "$?" -gt 0 ]; then
    echo "[ERROR] Download failed."
    exit 1
  fi
fi

## https://developer.android.com/ndk/guides/abis

for arch in ${archs[@]}; do
    case ${arch} in
        "armeabi-v7a")
        CONFIG_ARGS="android-arm"
        CC="armv7a-linux-androideabi${ANDROID_API}-clang"
        CXX="armv7a-linux-androideabi${ANDROID_API}-clang++"
        ;;
        "arm64-v8a")
        CONFIG_ARGS="android-arm64"
        CC="aarch64-linux-android${ANDROID_API}-clang"
        CXX="aarch64-linux-android${ANDROID_API}-clang++"
        ;;
        "x86")
        CONFIG_ARGS="android-x86 no-asm"
        CC="i686-linux-android${ANDROID_API}-clang"
        CXX="i686-linux-android${ANDROID_API}-clang++"
        ;;
        "x86_64")
        CONFIG_ARGS="android-x86_64"
        CC="x86_64-linux-android${ANDROID_API}-clang"
        CXX="x86_64-linux-android${ANDROID_API}-clang++"
        ;;
    esac

    export CPPFLAGS="-fPIC"
    export CXXFLAGS="-fPIC"
    
    echo "[INFO] Unziping OpenSSL $OPENSSL"
    rm -rf $OPENSSL
    tar zxf $OPENSSL.tar.gz
    
    echo "[INFO] Configuring OpenSSL"
    cd $OPENSSL
    ./Configure $CONFIG_ARGS -D__ANDROID_API__=$ANDROID_API no-tests
    
# SSL must be compilied for multi threading. If this check fails verify
# if multi threading is still properly configured.
    CONF_FILE="include/openssl/configuration.h"
    if ! grep -q "OPENSSL_THREADS" "$CONF_FILE"; then
        echo "[ERROR] Configuration did not define OPENSSL_THREADS makro"
        exit 1
    fi
    
    echo "[INFO] Building OpenSSL for arch: $arch"
    make
   
    cd .. 
   
    if [ ! -e "$OPENSSL/libssl.so" ]; then
       echo No such file $OPENSSL/libssl.so
       exit 1
    fi

    if [ ! -e "$OPENSSL/libcrypto.so" ]; then
       echo No such file $OPENSSL/libcrypto.so
       exit 1
    fi

    [ ! -e "$LIBDIR/$arch" ] && mkdir -p "$LIBDIR/$arch"

    cp "$OPENSSL/libssl.so" "$LIBDIR/$arch/"
    cp "$OPENSSL/libcrypto.so" "$LIBDIR/$arch/"
done

cd ..

[ -e ./include ] && rm -r ./include
cp -r ${WORKDIR}/${OPENSSL}/include ./include

echo "[INFO] OpenSSL built successfully!"

