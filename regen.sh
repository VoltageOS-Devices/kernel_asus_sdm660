export ARCH=arm64 && export SUBARCH=arm64 && make X00TD_defconfig && mv .config arch/arm64/configs/X00TD_defconfig && git add arch/arm64/configs/X00TD_defconfig && git commit -m "defconfig: Regen" -s
