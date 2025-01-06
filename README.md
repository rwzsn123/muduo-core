# muduo-core

【代码随想录知识星球】项目分享-muduo核心实现
## 项目介绍

本项目是参考 muduo 实现的基于 多Reactor 模型的多线程网络库。使用 C++ 11 编写去除 muduo 对 boost 的依赖。

项目已经实现了 Channel 模块、Poller 模块、事件循环模块、日志模块、线程池模块、一致性哈希轮询算法。

## 开发环境

* linux kernel version 5.15.0(ubuntu 20.04.6)
* gcc version 9.4.0
* cmake version 3.26.4

## 并发模型

![image.png](https://cdn.nlark.com/yuque/0/2022/png/26752078/1670853134528-c88d27f2-10a2-46d3-b308-48f7632a2f09.png?x-oss-process=image%2Fresize%2Cw_937%2Climit_0)

项目采用主从 多Reactor多线程 模型，MainReactor 只负责监听派发新连接，在 MainReactor 中通过 Acceptor 接收新连接并通过设计好的轮询算法派发给 SubReactor，SubReactor 负责此连接的读写事件。

调用 TcpServer 的 start 函数后，会内部创建线程池。每个线程独立的运行一个事件循环，即 SubReactor。MainReactor 从线程池中轮询获取 SubReactor 并派发给它新连接，处理读写事件的 SubReactor 个数一般和 CPU 核心数相等。使用主从 Reactor 模型有诸多优点：

1. 响应快，不必为单个同步事件所阻塞，虽然 Reactor 本身依然是同步的；
2. 可以最大程度避免复杂的多线程及同步问题，并且避免多线程/进程的切换；
3. 扩展性好，可以方便通过增加 Reactor 实例个数充分利用 CPU 资源；
4. 复用性好，Reactor 模型本身与具体事件处理逻辑无关，具有很高的复用性；

## 构建项目

安装Cmake

```shell
sudo apt-get update
sudo apt-get install cmake
```

下载项目

```shell
git clone https://github.com/youngyangyang04/muduo-core.git
```

执行脚本构建项目，别忘记先增加

```shell
chmod +x build.sh && ./build.sh
```

## 功能介绍

- **事件轮询与分发模块**：`EventLoop.*`、`Channel.*`、`Poller.*`、`EPollPoller.*`负责事件轮询检测，并实现事件分发处理。`EventLoop`对`Poller`进行轮询，`Poller`底层由`EPollPoller`实现。
- **线程与事件绑定模块**：`Thread.*`、`EventLoopThread.*`、`EventLoopThreadPool.*`绑定线程与事件循环，完成`one loop per thread`模型。
- **网络连接模块**：`TcpServer.*`、`TcpConnection.*`、`Acceptor.*`、`Socket.*`实现`mainloop`对网络连接的响应，并分发到各`subloop`。
- **缓冲区模块**：`Buffer.*`提供自动扩容缓冲区，保证数据有序到达。

## 技术亮点

1.`muduo`采用`Reactor`多模型多线程的结合，实现了高并发非阻塞的网络库
2. `TcpConnection`继承自`enable_shared_from_this`，其目的是防止在不该被释放对象的地方释放对象，导致悬空指针的产生。避免了用户可能在处理`OnMessage`事件中删除，保证了`TcpConnection`正确释放对象的方式。
3.`EventLoop`中使用了`eventfd`来调用`wakeup()`，让`mainloop`唤醒`subloop`的`epoll_wait`阻塞。
4. 新增`ConsistenHash`头文件采用一致性哈希轮询算法，将`EventLoop`合理分发给每一个`TcpConnection`对象，并且可以自定义哈希函数，满足高并发的需求，但需要注意虚拟节点数量不能太少。
5.在`Thread`中通过`C++lambda`表达式以及信号量机制保证线程创建有序确保线程正常创建好，才去执行线程函数。
6.`Buffer.*`是muduo网络库非阻塞的核心当触发了相应的读、写事件，内核缓冲区不一定有足够的空间进行一次性的发送这个时候就两种选择，第一是将其变成非阻塞但是会造成cpu忙等待，第二阻塞等到内核缓冲区有空间发送位置，但是效率非常低下。所以这里采用将多余的数据存放在`Buffer`并且注册相应的读、写事件监听等到再次触发的时候再一起发送出去。
7.`Logger`可以设置日志等级，调试代码时可以开启`DEBUG`打印日志；若启动服务器，由于日志会影响服务器性能，可适当关闭`DEBUG`相关日志输出

## 优化方向

- 完善内存池和完善异步日志缓冲区、定时器、连接池。
- 增加更多的测试用例,如HTTP、RPC。
- 可以考虑引入协程库等模块

## 致谢

- [作者-Shangyizhou]https://github.com/Shangyizhou/A-Tiny-Network-Library/tree/main
- [作者-S1mpleBug]https://github.com/S1mpleBug/muduo_cpp11?tab=readme-ov-file
- [作者-chenshuo]https://github.com/chenshuo/muduo
- 《Linux高性能服务器编程》
- 《Linux多线程服务端编程：使用muduo C++网络库》