#!/bin/bash

set -e
# 如果没有build目录 创建该目录
if [ ! -d "lib" ]; then
    mkdir lib
fi
# 如果没有build目录 创建该目录
if [ ! -d "build" ]; then
    mkdir build
fi

rm -fr build/*
cd build &&
    cmake .. &&
    make

# 回到项目根目录
cd ..

# 把头文件拷贝到 /usr/include/muduo-core     .so库拷贝到 /usr/lib
if [ ! -d /usr/include/muduo-core ]; then
    sudo mkdir /usr/include/muduo-core 
fi

# 拷贝头文件
for header in include/*.h; do
    sudo cp "$header" /usr/include/muduo-core 
done

# 拷贝动态库
sudo cp lib/libmuduo_core.so /usr/lib

# 更新动态链接库缓存
sudo ldconfig