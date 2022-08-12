#!/bin/sh

#set -e

WORKDIR=`pwd`"/work"
OPENSSL="openssl-3.0.5"
OPENSSLURL="https://www.openssl.org/source/${OPENSSL}.tar.gz"
export ANDROID_NDK_ROOT="/Users/przemek/Library/Android/ndk-r23b"
TOOLCHAIN_BIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin"
ANDROID_API=21

archs=(armeabi-v7a arm64-v8a x86 x86_64)
#archs=(x86)

export PATH=$TOOLCHAIN_BIN:$PATH


if [ ! -e "$WORKDIR" ]; then
 echo No such $WORKDIR directory
 exit 1
fi


LIBDIR=`pwd`"/libs"
cd $WORKDIR

[ ! -e "$OPENSSL.tar.gz" ] && wget $OPENSSLURL

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
    
    rm -rf $OPENSSL
    tar zxvf $OPENSSL.tar.gz
    
    cd $OPENSSL
    ./Configure $CONFIG_ARGS -D__ANDROID_API__=$ANDROID_API -static no-shared no-tests
    make
   
    cd .. 
    echo "ARCH: $arch"
   
    if [ ! -e "$OPENSSL/libssl.a" ]; then
       echo No such file $OPENSSL/libssl.a
       exit 1
    fi

    if [ ! -e "$OPENSSL/libcrypto.a" ]; then
       echo No such file $OPENSSL/libcrypto.a
       exit 1
    fi

    [ ! -e "$LIBDIR/$arch" ] && mkdir -p "$LIBDIR/$arch"

    cp "$OPENSSL/libssl.a" "$LIBDIR/$arch/"
    cp "$OPENSSL/libcrypto.a" "$LIBDIR/$arch/"
done

cd ..

[ -e ./include ] && rm -r ./include
cp -r ${WORKDIR}/${OPENSSL}/include ./include

echo DONE

