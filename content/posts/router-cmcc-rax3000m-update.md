+++
title = "升级cmcc rax3000m emmc路由器,刷入ImmortWrt24.10.2"
date = "2025-07-23"
updated = "2025-07-23"
description = "Upgrading the CMCC RAX3000M eMMC variant and installing ImmortalWrt 24.10.2."
tags = ["Router", "Hardware"]
+++

## 引

去年偶得一个cmcc rax3000m emmc路由器，为`immortalwrt21`，使用[该固件](https://github.com/AngelaCooljx/Actions-rax3000m-emmc)，近来只觉十分陈旧，遂萌生刷写新固件之意。

## 准备

> 之前使用的是[hanwckf大佬的uboot](https://cmi.hanwckf.top/p/mt798x-uboot-usage/)。
> 由于该的uboot不支持新的itb文件，所以需重新刷入一个uboot。
> 这里使用[1715173329大佬的uboot](https://www.right.com.cn/forum/thread-8400306-1-1.html)，有web界面的uboot和自动dhcp,使用起来更方便。

下载：

- [openwrt主线gpt](https://downloads.openwrt.org/releases/24.10.2/targets/mediatek/filogic/openwrt-24.10.2-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin)
- [openwrt主线bl2](https://downloads.openwrt.org/releases/24.10.2/targets/mediatek/filogic/openwrt-24.10.2-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin)
- [1715173329大佬的uboot文件](https://drive.wrt.moe/uboot/mediatek/mt7981-cmcc_rax3000m-emmc-fip-fit.bin)

然后将这些文件通过scp或者其他方式上传到路由器的`/tmp`目录下面。

## 刷uboot

先ssh连接到路由器,我的路由器ip是192.168.6.1。

```bash
ssh root@192.168.6.1
```

在路由器那边执行

```bash
# 刷入官方gpt
dd if=openwrt-24.10.2-mediatek-filogic-cmcc_rax3000m-emmc-gpt.bin of=/dev/mmcblk0 bs=512 seek=0 count=34 conv=fsync

echo 0 > /sys/block/mmcblk0boot0/force_ro

dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8192 conv=fsync
# 刷入官方bl2
dd if=openwrt-24.10.2-mediatek-filogic-cmcc_rax3000m-emmc-preloader.bin of=/dev/mmcblk0boot0 bs=512 conv=fsync

dd if=/dev/zero of=/dev/mmcblk0 bs=512 seek=13312 count=8192 conv=fsync
# 刷入1715173329大大的改版 U-Boot
dd if=mt7981-cmcc_rax3000m-emmc-fip-fit.bin of=/dev/mmcblk0 bs=512 seek=13312 conv=fsync
```

> 这一步比较关键，如果出错，不要断开ssh，反复检查一下，不然就爆炸了。

然后重启路由器。

## 刷固件

重启路由器后，应该会直接进入uboot。需要一根网线，一端接路由器lan口，另一端接电脑。

uboot自带dhcp,自带给你电脑设置完ip了，直接输入`http://192.168.1.1`访问uboot网页界面。

首先需要刷入一个recovery。

以官方固件为例，也可自行寻找固件。

下载recovery固件https://downloads.immortalwrt.org/releases/24.10.2/targets/mediatek/filogic/immortalwrt-24.10.2-mediatek-filogic-cmcc_rax3000m-initramfs-recovery.itb

然后在`http://192.168.1.1`uboot网页界面，上传该固件并刷写。

等待一会，直到看到路由器红灯闪烁后变绿，就是刷写完成，已经进入recovery了，接着需要在recovery中刷入squashfs-sysupgrade.itb。

下载squashfs-sysupgrade.itb固件https://downloads.immortalwrt.org/releases/24.10.2/targets/mediatek/filogic/immortalwrt-24.10.2-mediatek-filogic-cmcc_rax3000me-squashfs-sysupgrade.itb

使用scp或者其他方式上传到路由器的`/tmp`目录下面。

ssh再次连接路由器。

```bash
# 官方固件的路由器默认ip为192.168.1.1
ssh root@192.168.1.1
```

在路由器执行

```bash
sysupgrade -n -F /tmp/immortalwrt-24.10.2-mediatek-filogic-cmcc_rax3000me-squashfs-sysupgrade.itb
```

等待一会，直到看到路由器红灯闪烁后变绿，就是刷写完成，此时已经正式刷写完成。

## 刷写后进入uboot页面

如果刷写后还想进入uboot页面以刷写其他recovery，需要先将路由器断电，然后找一个牙签或者小螺丝刀或其他什么东西，将路由器的reset孔里面的按钮捅住。然后给路由器接电，直到看到路由器红灯亮起，才可以松手，不再按住reset孔里面的按钮。此时红灯应该是常亮而不会闪烁，说明进入uboot。

插上网线，输入`http://192.168.1.1`即可访问uboot网页界面。
