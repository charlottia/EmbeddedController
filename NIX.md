# Nix build environment

## Build in-tree with devShell

```console
$ git clone git@github.com:charlottia/FrameworkEmbeddedController
Cloning into 'FrameworkEmbeddedController'...
remote: Enumerating objects: 270106, done.
remote: Counting objects: 100% (15617/15617), done.
remote: Compressing objects: 100% (515/515), done.
remote: Total 270106 (delta 15232), reused 15336 (delta 15088), pack-reused 254489 (from 1)
Receiving objects: 100% (270106/270106), 107.00 MiB | 8.00 MiB/s, done.
Resolving deltas: 100% (207805/207805), done.
$ cd FrameworkEmbeddedController
$ ls
baseboard       cts                  libc                pyproject.toml
board           DIR_METADATA         LICENSE             README.fmap
BUILD.bazel     docs                 Makefile            README.md
builtin         driver               Makefile.ide        setup.py
chip            extra                Makefile.rules      test
cmake           firmware_builder.py  Makefile.toolchain  third_party
CMakeLists.txt  flake.lock           navbar.md           twister
common          flake.nix            OWNERS              unblocked_terms.txt
core            fuzz                 power               util
CPPLINT.cfg     include              PRESUBMIT.cfg       west.yml
crypto          Kconfig              pylintrc            zephyr
$ nix develop
$ zmake -j8 build lotus
Toolchain <zmake.toolchains.ZephyrToolchain object at 0x7ffff69b2750> selected by probe function.
Building lotus in /home/kivikakk/g/FrameworkEmbeddedController/src/platform/ec/build/zephyr/lotus.
Configuring lotus:ro.
Configuring lotus:rw.
Loading Zephyr default modules (Zephyr base (cached)).
Loading Zephyr default modules (Zephyr base (cached)).
'label' is marked as deprecated in 'properties:' in /nix/store/sgk2c9yi5frylgmp204aq61cjpai6m0l-source/dts/bindings/i2c/nuvoton,npcx-i2c-port.yaml for node /soc-if/io_i2c_ctrl0_port0.
...
/home/kivikakk/g/FrameworkEmbeddedController/build/zephyr/lotus/packer/source.dts:973.38-978.6: Warning (unique_unit_address): /soc-if/io_i2c_ctrl7_port0/ambient_f75303@4d: duplicate unit-address (also used in node /soc-if/io_i2c_ctrl7_port0/apu_f75303@4d)
/home/kivikakk/g/FrameworkEmbeddedController/build/zephyr/lotus/packer/source.dts:979.38-984.6: Warning (unique_unit_address): /soc-if/io_i2c_ctrl7_port0/charger_f75303@4d: duplicate unit-address (also used in node /soc-if/io_i2c_ctrl7_port0/apu_f75303@4d)
$ ls -l src/platform/ec/build/zephyr/lotus/output
total 8332
-rw-r--r-- 1 kivikakk users  524288 dets   7 17:02 ec.bin
-rwxr-xr-x 1 kivikakk users     792 dets   7 17:02 npcx_monitor.bin
-rwxr-xr-x 1 kivikakk users 4000556 dets   7 17:02 zephyr.ro.elf
-rwxr-xr-x 1 kivikakk users 4000504 dets   7 17:02 zephyr.rw.elf
$
```

## Build working copy reproducibly

```console
$ nix build .#lotus
$ ls -l result
lrwxrwxrwx 1 kivikakk users 49 dets   7 17:08 result -> /nix/store/2530fb2xcv4dnki6dsjbg11hydsbkvld-lotus
$ ls -l result/
total 8260
-r--r--r-- 1 root root  524288 jaan   1  1970 ec.bin
-r-xr-xr-x 1 root root     792 jaan   1  1970 npcx_monitor.bin
-r-xr-xr-x 1 root root 3961164 jaan   1  1970 zephyr.ro.elf
-r-xr-xr-x 1 root root 3961120 jaan   1  1970 zephyr.rw.elf
```

(Or `.#azalea`.)

## Build commit (checkout not required)

```console
$ nix build 'github:charlottia/FrameworkEmbeddedController?rev=84e4ed243f3d17f97b2dc89924d3c71aef8c2a28#lotus'
$ ls -l result
lrwxrwxrwx 1 kivikakk users 49 dets   7 17:10 result -> /nix/store/c32jydxf53vqgc99468b5fdqs1d1vdwn-lotus
$ ls -l result/
total 8260
-r--r--r-- 1 root root  524288 jaan   1  1970 ec.bin
-r-xr-xr-x 1 root root     792 jaan   1  1970 npcx_monitor.bin
-r-xr-xr-x 1 root root 3961164 jaan   1  1970 zephyr.ro.elf
-r-xr-xr-x 1 root root 3961120 jaan   1  1970 zephyr.rw.elf
```
