#!/usr/bin/env bash

set -euxo pipefail

git submodule init
git submodule update

# reset
git submodule foreach 'git clean -ffdx; git checkout .'
rm -rf venv

python3 -m venv venv
source venv/bin/activate

sed -e 's#"/bin:/usr/bin"#"/bin:/usr/bin:'"$(dirname "$(which gcc)"):$(dirname "$(which dtc)")"'","DYLD_LIBRARY_PATH":"'"$(dirname "$(dirname "$(which dtc)")")/lib"'"#'  -i src/platform/ec/zephyr/zmake/zmake/jobserver.py
pip install src/platform/ec/zephyr/zmake

sed -e 's/>=61.0/==68.2.2/' -i src/third_party/u-boot/files/tools/dtoc/pyproject.toml
sed -e 's/"pylibfdt"/"libfdt"/' -i src/third_party/u-boot/files/tools/dtoc/pyproject.toml
pip install src/third_party/u-boot/files/tools/dtoc

sed -e 's/>=61.0/==68.2.2/' -i src/third_party/u-boot/files/tools/binman/pyproject.toml
sed -e 's/"pylibfdt"/"libfdt"/' -i src/third_party/u-boot/files/tools/binman/pyproject.toml
pip install src/third_party/u-boot/files/tools/binman

zmake -j8 build lotus -DCMAKE_MAKE_PROGRAM="$(which ninja)" -DGIT_EXECUTABLE="$(which git)"
