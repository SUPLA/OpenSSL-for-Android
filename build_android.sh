#!/bin/sh

WORKDIR=`pwd`"/work"
OPENSSL="openssl-1.0.2r"
OPENSSLURL="https://www.openssl.org/source/openssl-1.0.2r.tar.gz"
NDKDIR="/Users/przemek/Library/Android/ndk-r14b"
TOOLCHAIN="arm-linux-androideabi-4.8"
PLATFORM="android-12"
archs=(armeabi armeabi-v7a arm64-v8a x86 x86_64)
#archs=(arm64-v8a)

if [ ! -e "$WORKDIR" ]; then
 echo No such $WORKDIR directory
 exit 1
fi

export NDK=$NDKDIR

LIBDIR=`pwd`"/libs"
cd $WORKDIR

[ ! -e "$OPENSSL.tar.gz" ] && wget $OPENSSLURL

for arch in ${archs[@]}; do
    case ${arch} in
        "armeabi")
        export ARCH_FLAGS="-mthumb"
        export ARCH_LINK=""
        CONFIGURE_PLATFORM="android-armv7"
        TOOLCHAINARCH="arm"
        export TOOL=arm-linux-androideabi
        ;;
        "armeabi-v7a")
        export ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
        export ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
        CONFIGURE_PLATFORM="android-armv7"
        TOOLCHAINARCH="arm"
        export TOOL=arm-linux-androideabi
        ;;
        "arm64-v8a")
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        CONFIGURE_PLATFORM="linux-generic64"
        TOOLCHAINARCH="arm64"
        export TOOL=aarch64-linux-android
        PLATFORM="android-21"
        ;;
        "x86")
        export ARCH_FLAGS="-march=i686 -msse3 -mstackrealign -mfpmath=sse"
        export ARCH_LINK="-march=i686"  
        CONFIGURE_PLATFORM="android-x86 no-asm"   
        TOOLCHAINARCH="x86"
        export TOOL=i686-linux-android
        ;;
        "x86_64")
        export ARCH_FLAGS=""
        export ARCH_LINK=""
        CONFIGURE_PLATFORM="linux-generic64"
        TOOLCHAINARCH="x86_64"
        export TOOL=x86_64-linux-android
        PLATFORM="android-21"
        ;;
    esac

    TOOLCHAINROOT=${WORKDIR}/android-toolchain-${TOOLCHAINARCH}

    if [ ! -e "$TOOLCHAINROOT" ]; then
      $NDK/build/tools/make-standalone-toolchain.sh --platform=$PLATFORM --arch=$TOOLCHAINARCH --toolchain=$TOOLCHAIN --install-dir=$TOOLCHAINROOT --verbose
    fi

    if [ ! -e "$TOOLCHAINROOT" ]; then
      echo No such $TOOLCHAINROOT directory
      exit 1
    fi

    export TOOLCHAIN_PATH=${TOOLCHAINROOT}/bin
    export NDK_TOOLCHAIN_BASENAME=${TOOLCHAIN_PATH}/${TOOL}
    export CC=$NDK_TOOLCHAIN_BASENAME-gcc
    export CXX=$NDK_TOOLCHAIN_BASENAME-g++
    export LINK=${CXX}
    export LD=$NDK_TOOLCHAIN_BASENAME-ld
    export AR=$NDK_TOOLCHAIN_BASENAME-ar
    export RANLIB=$NDK_TOOLCHAIN_BASENAME-ranlib
    export STRIP=$NDK_TOOLCHAIN_BASENAME-strip
    export CPPFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
    export CXXFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 -frtti -fexceptions "
    export CFLAGS=" ${ARCH_FLAGS} -fpic -ffunction-sections -funwind-tables -fstack-protector -fno-strict-aliasing -finline-limit=64 "
    export LDFLAGS=" ${ARCH_LINK} "


    rm -rf $OPENSSL
    tar zxvf $OPENSSL.tar.gz
    cd $OPENSSL
    ./Configure $CONFIGURE_PLATFORM
    PATH=$TOOLCHAIN_PATH:$PATH make
   
    cd .. 
    echo "ARCH: $arch"
   
    if [ ! -e "$OPENSSL/libssl.a" ]; then
       echo No such file libssl.a
       exit 1
    fi

    if [ ! -e "$OPENSSL/libcrypto.a" ]; then
       echo No such file libcrypto.a
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

