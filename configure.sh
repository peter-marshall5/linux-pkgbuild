#!/bin/bash

cd linux
make LLVM=1 -j$(($(nproc)+1)) oldconfig
make LLVM=1 -j$(($(nproc)+1)) nconfig
