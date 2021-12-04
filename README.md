# RISC-V GETTING STARTED

This fork is an experiment in getting Toit running on 64-bit RISC-V hardware.  Below is a **WIP** guide to get Toit running on a SiFive Unmatched dev board or RISC-V VM with QEMU. 

| STATUS | |
| ------------- | ------------- |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | Linux RISC-V environment |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | IDF environment |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | IDF compile sources |
| ![](https://img.shields.io/static/v1?label=&message=FAILURE&color=red) | IDF export [ERROR](https://github.com/dsobotta/toit-riscv/issues/4) |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green)| Toit generate build files |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | Toit compile sources |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green)| Toit generate boot snapshot |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | Toit run examples |
| ![](https://img.shields.io/static/v1?label=&message=PARTIAL&color=yellow) | Cross-compile to riscv64 (Requires manually copying host boot snapshot)|
| ![](https://img.shields.io/static/v1?label=&message=TODO&color=orange) | Embedded RISC-V support |


## 1) RISC-V Environment Setup
Install a Debian-based Linux distro (choose one)
- SiFive Unmatched: [Ubuntu Server 20.04](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-risc-v-hifive-boards#1-overview)
- Virtual Machine: [RISC-V VM with QEMU](https://colatkinson.site/linux/riscv/2021/01/27/riscv-qemu/)

## 2) Install Dependencies
``` sh
apt update
apt install git build-essential cmake python3 python3-pip python-is-python3 libffi-dev libssl-dev cargo golang ninja-build
```

## 3) Clone Sources 
``` sh
#ESP-IDF
git clone https://github.com/dsobotta/esp-idf-riscv.git
pushd esp-idf-riscv/
git checkout patch-head-4.3-3
git submodule update --init --recursive
popd

#Toit
git clone https://github.com/dsobotta/toit-riscv.git

#Add IDF path to environment
export IDF_PATH=PATH_TO_ESP_IDF_RISCV
```

## 4) Compile Toit
``` sh
cd toit-riscv
make tools
```

## 5) Run Examples
``` sh
build/host/bin/toitvm examples/hello.toit
build/host/bin/toitvm examples/bubble_sort.toit
build/host/bin/toitvm examples/http.toit
build/host/bin/toitvm examples/mandelbrot.toit
```
</br>
</br>

# Cross-Compiling for RISC-V/Linux

How to compile the 64-bit RISC-V Toit binaries (toitc and toitvm) from another architecture (ie. amd64)

| STATUS | |
| ------------- | ------------- |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | Linux RISC-V cross-compile environment |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | IDF environment |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | IDF compile sources |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | IDF export |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green)| Toit generate build files |
| ![](https://img.shields.io/static/v1?label=&message=PARTIAL&color=yellow) | Toit compile sources (Works on Debian, [fails to link on Arch](https://github.com/dsobotta/toit-riscv/issues/6)) |
| ![](https://img.shields.io/static/v1?label=&message=FAILURE&color=red)| Toit generate boot snapshot (Requires manually copying host snapshot) |
| ![](https://img.shields.io/static/v1?label=&message=SUCCESS&color=green) | Toit run examples |


## 1) Compile host tools
> *Note: This is a necessary to generate toitvm_boot.snapshot, a dependency for the toitvm runtime.* </br> 
Follow [steps 2-4 above](https://github.com/dsobotta/toit-riscv#2-install-dependencies), on the non-riscv64 host.

## 2) Install dependencies
``` sh
apt update
apt install gcc-riscv64-linux-gnu g++-riscv64-linux-gnu
```

## 3) Cross-compile 64-bit RISC-V Toit
``` sh
cd toit-riscv
make tools-riscv64
```

> Note: the build will fail here when trying to generate the toitvm_boot.snapshot.  This is because the build scripts attempt to run build/riscv64/bin/toitc (a 64-bit RISC-V binary) on a non-riscv64 host.
``` sh
...
[322/322] Generating ../bin/toitvm_boot.snapshot
FAILED: bin/toitvm_boot.snapshot 
cd /root/git/toit-riscv/build/riscv64/src && /usr/bin/cmake -E env ASAN_OPTIONS=detect_leaks=false ASAN_OPTIONS=detect_leaks=false /root/git/toit-riscv/build/riscv64/bin/toitc --dependency-file /root/git/toit-riscv/build/riscv64/src/boot.dep --dependency-format ninja -w /root/git/toit-riscv/build/riscv64/bin/toitvm_boot.snapshot /root/git/toit-riscv/tools/toitvm_boot.toit
/root/git/toit-riscv/build/riscv64/bin/toitc: 1: ELF�X�@8: not found
/root/git/toit-riscv/build/riscv64/bin/toitc: 1: Syntax error: "&" unexpected
ninja: build stopped: subcommand failed.
make: *** [Makefile:38: build/riscv64/bin/toitvm] Error 1
```
</br>

So we'll complete the process by copying the snapshot generated by the host environment: 
``` sh
cp build/host/bin/toitvm_boot.snapshot build/riscv64/bin/
```

## 4) Deploy
A complete Toit environment should now be ready for use on 64-bit RISC-V hardware
``` sh
ubuntu@ubuntu:~/git/toit-riscv$ ls -l build/riscv64/bin/
total 4112
lrwxrwxrwx 1 ubuntu ubuntu      31 Dec  4 07:48 lib -> /home/ubuntu/git/toit-riscv/lib
drwxrwxr-x 7 ubuntu ubuntu    4096 Dec  4 11:19 mbedtls
-rwxrwxr-x 1 ubuntu ubuntu 1806496 Dec  4 07:49 toitc
-rwxrwxr-x 1 ubuntu ubuntu 2189584 Dec  4 07:49 toitvm
-rw-rw-r-- 1 ubuntu ubuntu  202320 Dec  4 11:19 toitvm_boot.snapshot
```
</br>
</br>

# ORIGINAL DOCUMENTATION

# Toit language implementation

This repository contains the Toit language implementation. It is fully open source and consists of the compiler,
virtual machine, and standard libraries that together enable Toit programs to run on an ESP32.

We use [GitHub Discussions](https://github.com/toitlang/toit/discussions) to discuss and learn and
we follow a [code of conduct](CODE_OF_CONDUCT.md) in all our community interactions.

## References

The Toit language is the foundation for the [Toit platform](https://toit.io/) that brings robust serviceability
to your ESP32-based devices. You can read more about the language and the standard libraries in the platform
documentation:

* [Language basics](https://docs.toit.io/language)
* [Standard libraries](https://libs.toit.io/)

## Contributing

We welcome and value your [open source contributions](CONTRIBUTING.md) to the language implementation
and the broader ecosystem. Building or porting drivers to the Toit language is a great place to start.
Read about [how to get started building I2C-based drivers](https://github.com/toitlang/toit/discussions/22) and
get ready to publish your new driver to the [package registry](https://pkg.toit.io).

If you're interested in pitching in, we could use your help with
[these drivers](https://github.com/toitlang/toit/issues?q=is%3Aissue+is%3Aopen+label%3Adriver+label%3A%22help+wanted%22)
and more!

## Licenses

The Toit compiler, the virtual machine, and all the supporting infrastructure is licensed under
the [LGPL-2.1](LICENSE) license. The standard libraries contained in the `lib/` directory
are licensed under the [MIT](lib/LICENSE) license. The examples contained in the `examples/`
directory are licensed under the [0BSD](examples/LICENSE) license.

Certain subdirectories are under their own open source licenses, detailed
in those directories.  These subdirectories are:

* Every subdirectory under `src/third_party`
* Every subdirectory under `src/compiler/third_party`
* Every subdirectory under `lib/font/x11_100dpi`
* The subdirectory `lib/font/matthew_welch`

# Building

## Dependencies

### ESP-IDF

The VM has a requirement to ESP-IDF, both for Linux and ESP32 builds (for Linux it's for the MBedTLS implementation).

We recommend you use Toitware's [ESP-IDF fork](https://github.com/toitware/esp-idf) that comes with a few changes:

* Custom malloc implementation.
* Allocation-fixes for UART, etc.
* LWIP fixes.

``` sh
git clone https://github.com/toitware/esp-idf.git
pushd esp-idf/
git checkout patch-head-4.3-3
git submodule update --init --recursive
popd
```

Remember to add it to your ENV as `IDF_PATH`:

``` sh
export IDF_PATH=...
```

### ESP32 tools

Install the ESP32 tools, if you want to build an image for an ESP32.

On Linux:
``` sh
$IDF_PATH/install.sh
```

For other platforms, see [Espressif's documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/index.html#step-3-set-up-the-tools).

Remember to update your environment variables:

``` sh
. $IDF_PATH/export.sh
```

The build system will automatically use a 32-bit build of the Toit compiler to produce the correct executable image for the ESP32.
Your build might fail if you're on a 64-bit Linux machine and you don't have the support for compiling 32-bit executables installed.
You can install this support on most Linux distributions by installing the `gcc-multilib` and `g++-multilib` packages. If you
use `apt-get`, you can use the following command:

``` sh
sudo apt-get install gcc-multilib g++-multilib
```

## Build for Linux and Mac

Make sure `IDF_PATH` is set, as described above.

Then run the following commands at the root of your checkout.

``` sh
make tools
```

This builds the Toit VM, the compiler, the language server and the package manager.

You should then be able to execute a toit file:

``` sh
build/host/bin/toitvm examples/hello.toit
```

The package manager is found at `build/toitpkg`:

``` sh
build/toitpkg pkg init --project-root=<some-directory>
build/toitpkg pkg install --project-root=<some-directory> <package-id>
```

The language server can be started with:

``` sh
build/toitlsp --toitc=build/host/bin/toitc
```

See the instructions of your IDE on how to integrate the language server.

For VSCode you can also use the [published extension](https://marketplace.visualstudio.com/items?itemName=toit.toit).

### Notes for Mac

The support for building for Mac is still work in progress. For now, it isn't possible
to build firmware images for the ESP32 on a Mac, because it requires compiling and
running 32-bit executables. We are working on
[addressing this](https://github.com/toitlang/toit/issues/24).


## Build for ESP32

Make sure the environment variables for the ESP32 tools are set, as
described in the [dependencies](#dependencies) section.

Build an image for your ESP32 device that can be flashed using `esptool.py`.

``` sh
make esp32
```

By default, the image boots up and runs `examples/hello.toit`. You can use your
own entry point and specify it through the `ESP32_ENTRY` make variable:

``` sh
make esp32 ESP32_ENTRY=examples/mandelbrot.toit
```

### Configuring WiFi for the ESP32

You can easily configure the ESP32's builtin WiFi by setting the `ESP32_WIFI_SSID` and
`ESP32_WIFI_PASSWORD` make variables:

``` sh
make esp32 ESP32_ENTRY=examples/http.toit ESP32_WIFI_SSID=myssid ESP32_WIFI_PASSWORD=mypassword
```

This allows the WiFi to automatically start up when a network interface is opened.
