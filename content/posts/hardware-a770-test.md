+++
title = "A770的AI使用体验"
date = "2025-09-26"
updated = "2025-09-26"
description = "Testing the Intel Arc A770 for AI: The good, the bad, and the reality of using an Intel GPU for OLLAMA and ComfyUI"
tags = ["Hardware", "AI", "LLM"]
+++

## 引

8月底把游戏本出了装机，想搞一张能跑ai绘画顺便能打打游戏的显卡。

1.  我对显存有要求，至少12G显存。
2.  性价比高。
3.  不是特别在意游戏性能。
4.  不折腾也不要太牢的卡，像Tesla V100，MI50这种的卡也不想要。

挑显卡时偶然看到了Intel Arc A770 16G在海鲜市场二手价格1200元。以较低价格购买一张16G显存并且比较像样的显卡，是比较有吸引力的。
主要担心的是，Intel显卡徒有其表，虽然规格看上去很美丽，跑分也很美丽，但实际用起来就不是那么美丽了。
在参考了[【Stable Diffusion】AIイラストにおすすめなグラボをガチで検証【GPU別の生成速度】](https://chimolog.co/bto-gpu-stable-diffusion-specs/)的显卡ai绘画大横评后，我认为A770这张卡看起来还行，于是搞了一张A770公版。

## 驱动

### Windows驱动

直接官网下载安装即可。我使用最新驱动，如果打游戏，应该去找找之前版本的驱动，因为A770驱动在2025年是负优化居多，而A770的游戏表现比较依赖驱动的优化。

### Linux驱动

正常显示是没问题的，默认使用intel的i915开源驱动。
以下是为了满足使用A770在Linux上进行计算、推理和跑ai。
首先，对系统有要求：

1.  最好是内核6.0以上(not sure)
    使用以下命令查看。

```bash
uname -r
```

2.  内核带有GuC/HuC firmware
    使用以下命令查看。

```bash
dmesg | grep -i -e 'huc' -e 'guc'
```

一般来说，使用比较新的内核都会自动加载。
没有的话查看[这个](https://wiki.archlinux.org/title/Intel_graphics#Enable_GuC_/_HuC_firmware_loading)来安装和开启。

3.  Intel Compute Runtime
    可能需要用对应系统的包管理器安装。

4.  Level Zero
    可能需要用对应系统的包管理器安装。

#### Ubuntu

Intel有为他们的显卡在Ubuntu平台上开发驱动。
应按照此篇[官方教程](https://dgpu-docs.intel.com/driver/client/overview.html#ubuntu-latest)安装驱动。

#### Cachyos (Arch 发行版)

正常安装系统后，需要用包管理器安装`Intel Compute Runtime`和`Level Zero`。

```bash
sudo pacman -S intel-compute-runtime level-zero-loader level-zero-headers
```

#### 其他Linux发行版

没有测试过，检查是否满足4个条件。

#### 如何检查驱动是否安装成功

检测是否安装成功可以使用`torch.xpu`。

> 推荐直接使用python venv虚拟环境。我在Ubuntu 24.04.3上面使用conda会识别不到我的A770。

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/xpu
python -c "import torch;print(f"XPU available: {torch.xpu.is_available()}");print(f"Device count: {torch.xpu.device_count()}");print(f"Device name: {torch.xpu.get_device_name(0)}");"
```

如果xpu可用显示true，arc显卡计数不为0，以及可以显示arc显卡名字，则驱动安装成功。
如果xpu可用显示flase，arc显卡计数为0，以及不能显示arc显卡名字，则驱动安装失败。需要再检查检查哪里没安装好。

#### 将i915驱动替换为xe驱动

i915驱动是linux默认为intel gpu启用的驱动。可以手动切换到xe驱动以提高性能。
[该篇文章](https://www.phoronix.com/review/intel-i915-xe-linux-2025)是2种驱动对比。文章有5页，记得翻页看。

在arch wiki中也有[切换Xe驱动的教程](https://wiki.archlinux.org/title/Intel_graphics#Testing_the_new_experimental_Xe_driver)

##### 检查启用Xe驱动的前置条件

来自archwiki

- linux 6.8 内核及其更新的版本
- Tiger Lake架构(11代酷睿)以及更新的集显, 或者独显。
- mesa.

###### 查看intel 显卡的pci id

看看自己的intel显卡是否支持xe驱动

```bash
lspci -k | grep -EA3 'VGA|3D|Display'
```

我的示例如下，可以看到Kernel modules: i915, xe,支持i915和xe。
当前使用的是i915。

```
03:00.0 VGA compatible controller: Intel Corporation DG2 [Arc A770] (rev 08)
    Subsystem: Intel Corporation Device 1020
    Kernel driver in use: i915
    Kernel modules: i915, xe
```

查看pci id：

```bash
lspci -nnd ::03xx
```

找8086后面的4位，对于下面这个例子则为`9a49`，请替换为你自己的。

```
00:02.0 VGA compatible controller [0300]: Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics] [8086:9a49] (rev 01)
```

### 写内核参数

需要添加的内核参数为：

```
i915.force_probe=!pci-id xe.force_probe=pci-id
```

由于例子的pci id为`9a49`,替换`pci-id`为

```
i915.force_probe=!9a49 xe.force_probe=9a49
```

##### 添加内核参数(grub)

编辑`/etc/default/grub`

```bash
sudo nano /etc/default/grub
```

找到这行`GRUB_CMDLINE_LINUX_DEFAULT`并在其中添加上内核参数。
添加后如

```/etc/default/grub
...
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash i915.force_probe=!9a49 xe.force_probe=9a49"
...
```

还有其他参数的话，每一个参数用空格隔开，一起写进去，默认只有`quiet splash`这2个参数。
然后保存并退出。
更新grub:

```bash
sudo update-grub
```

重启后就用上xe驱动了。

##### 检查是否切换成功

可以使用下面的命令检查

```bash
lspci -k | grep -EA3 'VGA|3D|Display'
```

结果：

```
03:00.0 VGA compatible controller: Intel Corporation DG2 [Arc A770] (rev 08)
    Subsystem: Intel Corporation Device 1020
    Kernel driver in use: xe
    Kernel modules: i915, xe
```

看到Kernel driver in use为xe就大功告成了。

### BSD驱动

#### FreeBSD

https://forums.freebsd.org/threads/intel-arc-gpu-support.89343/

https://github.com/freebsd/drm-kmod/issues/315
测试过FreeBSD 14.3 release，使用drm-61-kmod，复现出上述问题。无法启动系统。

#### 其他BSD

不支持。

## 测试环节

详细请参照：

- ai性能
  [【Stable Diffusion】AIイラストにおすすめなグラボをガチで検証【GPU別の生成速度】](https://chimolog.co/bto-gpu-stable-diffusion-specs/)
  [【Wan2.2】動画生成AIにおすすめなグラボをガチで検証【GPU別の生成速度】](https://chimolog.co/bto-gpu-wan22-specs/)
- 游戏性能
  B站上找测评。
- tom hardware
  [Stable Diffusion Benchmarks: 45 Nvidia, AMD, and Intel GPUs Compared](https://www.tomshardware.com/pc-components/gpus/stable-diffusion-benchmarks) 这个测评感觉不准，一是2023年的测评，intel驱动都更新好几波了，可能有影响。二是仅对Nvida和AMD的显卡使用pytorch。而对英特尔显卡使用[openvino](https://github.com/bes-dev/stable_diffusion.openvino)，。

**事先声明**：受限于个人水平和硬件限制，我仅进行ai性能的简单测试，无法覆盖较多的场景，无法控制测试平台变量，但是理论上我找的测试平台不会对显卡造成瓶颈，结果仅作为参考。

### 环境安装

torch均使用最新稳定版。

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
# Intel
python -m pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/xpu
# Nvidia
python -m pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu129
# AMD
python -m pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/rocm6.4
```

### xpu速度测试

`torch.xpu`可以代替`torch.cuda`，想测试xpu速度如何。
[测试脚本来源](https://discuss.pytorch.org/t/timings-for-intel-arc-graphics-xpu-vs-nvidia-rtx-3000-gpu-on-a-laptop/218200)

```python
import torch
print (torch.__version__)

import time

torch.manual_seed (2025)

device = 'cpu'
if  torch.cuda.is_available():
    print ('version.cuda:', torch.version.cuda)
    print (torch.cuda.get_device_name())
    print (torch.cuda.get_device_properties())
    device = 'cuda'
if  torch.xpu.is_available():
    print ('version.xpu:', torch.version.xpu)
    print (torch.xpu.get_device_name())
    print (torch.xpu.get_device_properties())
    device = 'xpu'

print ('device:', device)

vBatch = 100000
nBatch = 100000
nHidden = 512
nEpoch = 1000
# nPrint = 100

def fitFunction (x):
    return (1 * x).sin()

lossFn = torch.nn.MSELoss()

model = torch.nn.Sequential (
    torch.nn.Linear (1, nHidden),
    torch.nn.Sigmoid(),
    torch.nn.Linear (nHidden, nHidden),
    torch.nn.Sigmoid(),
    torch.nn.Linear (nHidden, 1)
)

opt = torch.optim.SGD (model.parameters(), lr = 0.01, momentum = 0.9)

model.to (device)

inputVal = torch.randn (vBatch, 1, device = device)
targetVal = fitFunction (inputVal)

lossInit = lossFn (model (inputVal), targetVal)
print ('lossInit:', lossInit)

if device == 'cuda':  torch.cuda.synchronize()
if device == 'xpu':   torch.xpu.synchronize()
tBeg = time.time()

for  i in range (nEpoch):
    inp = torch.randn (nBatch, 1, device = device)
    trg = fitFunction (inp)
    loss = lossFn (model (inp), trg)
    opt.zero_grad()
    loss.backward()
    opt.step()

if  device == 'cuda':  torch.cuda.synchronize()
if device == 'xpu':   torch.xpu.synchronize()
tEnd = time.time()

lossFinl = lossFn (model (inputVal), targetVal)
print ('lossFinl:', lossFinl)

print ('device:', device, ' time:', '{0:.4f}'.format (tEnd - tBeg), '   nBatch:', nBatch, ' nEpoch:', nEpoch)
```

根据脚本作者提出的主要局限性：这是一个不切实际的简单测试模型（旨在饱和 GPU）。各种其他张量运算和更真实的模型可能会运行得更快或慢，只测试了float32。所以测试简单且不严谨，结果仅供参考。

`跑完脚本所用时间`应该越少越好。

| 代称              | Linux发行版        | Linux内核         | torch cuda/xpu版本 | 用时     |
| ----------------- | ------------------ | ----------------- | ------------------ | -------- |
| A770(1)           | CachyOS            | 6.16.7-2-cachyos  | 2.8.0+xpu          | 20.0945  |
| A770(2)           | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+xpu          | 20.3105  |
| 5060ti 16G        | CachyOS            | 6.17.2-2-cachyos  | 2.8.0+cu129        | 20.2183  |
| 5060              | ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 23.0996  |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 26.2080  |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 33.4658  |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 46.5181  |
| Tesla T4(1)       | Ubuntu 20.04.6 LTS | 5.4.0-166-generic | 2.8.0+cu129        | 49.9113  |
| Tesla T4(2)       | Ubuntu 22.04.5 LTS | 6.6.97+           | 2.8.0+cu126        | 50.2602  |
| GTX 1650 laptop   | Linux Mint 22.2    | 6.14.0-29-generic | 2.8.0+cu126        | 100.8302 |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "脚本测试"
    x-axis ["A770(1)", "A770(2)", "5060ti 16G", "5060","4060ti 16G", "4060 laptop", "4050 laptop", "Tesla T4(1)", "Tesla T4(2)", "GTX 1650 laptop"]
    y-axis "跑完测试脚本所用时间 s" 0 --> 60
    %% Green bar
    bar [20.0945, 20.3105, 20.2183, 23.0996, 26.2080, 33.4658, 46.5181, 49.9113, 50.2602,100.8302 ]
    %% Blue bar
    bar [20.0945, 20.3105]
    line [20.0945, 20.3105, 20.2183, 23.0996, 26.2080, 33.8658, 46.5181, 49.9113, 50.2602,100.8302 ]
") }}

看起来xpu的速度还可以。

### ollama测试

#### 运行ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve
```

另外一个终端

```bash
ollama run deepseek-r1:7b
# or
ollama run deepseek-r1:8b
```

#### 问答前清理记忆并切换到输出模式

```
>>> /clear
>>> /set verbose
Set 'verbose' mode.
```

问题:宇宙的外面是什么

#### deepseek-r1:7b

`tokens/s`越大越好

| 代称              | Linux发行版        | Linux内核         | ollama版本                                                                               | tokens/s |
| ----------------- | ------------------ | ----------------- | ---------------------------------------------------------------------------------------- | -------- |
| A770              | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.9.3([ipex-llm 2.3](https://github.com/ipex-llm/ipex-llm/releases/tag/v2.3.0-nightly)) | 63.80    |
| 5060              | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.12.2                                                                                  | 72.07    |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.11.10                                                                                 | 50.91    |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.11.10                                                                                 | 48.67    |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.11.10                                                                                 | 26.09    |
| Tesla T4(1)       | Ubuntu 20.04.6 LTS | 5.4.0-166-generic | v0.12.3                                                                                  | 34.40    |
| Tesla T4(2)       | Ubuntu 22.04.5 LTS | 6.6.97+           | v0.12.2                                                                                  | 25.97    |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "deepseek-r1:7b测试"
    x-axis ["A770", "5060", "4060ti 16G", "4060 laptop", "4050 laptop", "Tesla T4(1)", "Tesla T4(2)"]
    y-axis "每秒输出token数 tokens/s" 0 --> 80
    %% Green bar
    bar [63.80, 72.07, 50.91, 48.67, 26.09, 34.40, 25.97]
    %% Blue bar
    bar [63.80]
    line [63.80, 72.07, 50.91, 48.67, 26.09, 34.40, 25.97]
") }}

#### deepseek-r1:8b

| 代称              | Linux发行版        | Linux内核         | ollama版本                                                                               | tokens/s |
| ----------------- | ------------------ | ----------------- | ---------------------------------------------------------------------------------------- | -------- |
| A770              | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.9.3([ipex-llm 2.3](https://github.com/ipex-llm/ipex-llm/releases/tag/v2.3.0-nightly)) | 51.38    |
| 5060ti 16G        | CachyOS            | 6.17.2-2-cachyos  | v0.11.10                                                                                 | 67.07    |
| 5060              | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.12.3                                                                                  | 63.86    |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.11.10                                                                                 | 45.04    |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.11.10                                                                                 | 43.08    |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | v0.11.10                                                                                 | 20.68    |
| Tesla T4(1)       | Ubuntu 20.04.6 LTS | 5.4.0-166-generic | v0.12.2                                                                                  | 31.91    |
| Tesla T4(2)       | Ubuntu 22.04.5 LTS | 6.6.97+           | v0.12.10                                                                                 | 25.44    |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "deepseek-r1:8b测试"
    x-axis ["A770", "5060ti 16G", "5060", "4060ti 16G", "4060 laptop", "4050 laptop", "Tesla T4(1)", "Tesla T4(2)"]
    y-axis "每秒输出token数 tokens/s" 0 --> 80
    %% Green bar
    bar [51.38, 67.07, 63.86, 45.04, 43.08, 20.68, 31.91, 25.44]
    %% Blue bar
    bar [51.38]
    line [51.38, 67.07, 63.86, 45.04, 43.08, 20.68, 31.91, 25.44]
") }}

### Comfyui测试

连续执行10次绘画任务，去除极端值取平均值。
不考虑模型加载时间，仅测试比较其每秒迭代多少次即迭代速度(it/s)。

#### 工作流官方示例 默认 -> 文生图(就是那个水瓶)

> 除了图片大小和批量大小，其他均为默认设置，模型也为默认模型。

`it/s`应该越大越好。

| 代称              | Linux发行版        | Linux内核         | torch cuda/xpu版本 | it/s  |
| ----------------- | ------------------ | ----------------- | ------------------ | ----- |
| A770(1)           | CachyOS            | 6.16.7-2-cachyos  | 2.8.0+xpu          | 9.81  |
| A770(2)           | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+xpu          | 9.04  |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 15.05 |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 11.14 |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 8.59  |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "512x512 批量大小:1"
    x-axis ["A770(1)", "A770(2)", "4060ti 16G", "4060 laptop", "4050 laptop"]
    y-axis "每秒迭代数 it/s" 0 --> 20
    %% Green bar
    bar [9.81, 9.04, 15.05, 11.14, 8.59]
    %% Blue bar
    bar [9.81, 9.04]
    line [9.81, 9.04, 15.05, 11.14, 8.59]
") }}

| 代称              | Linux发行版        | Linux内核         | torch cuda/xpu版本 | it/s |
| ----------------- | ------------------ | ----------------- | ------------------ | ---- |
| A770(1)           | CachyOS            | 6.16.7-2-cachyos  | 2.8.0+xpu          | 2.40 |
| A770(2)           | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+xpu          | 2.30 |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 3.05 |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 2.11 |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 1.63 |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "1024x1024 批量大小:1"
    x-axis ["A770(1)", "A770(2)", "4060ti 16G", "4060 laptop", "4050 laptop"]
    y-axis "每秒迭代数 it/s" 0 --> 5
    %% Green bar
    bar [2.40, 2.30, 3.05, 2.11, 1.63]
    %% Blue bar
    bar [2.40, 2.30]
    line [2.40, 2.30, 3.05, 2.11, 1.63]
") }}

由于4050迭代速度太慢，已经自动转为用s/it(每次迭代需要多少秒)显示，为了方便与其他显卡比较，故这里将4050的成绩`1.02s/it`转换为`0.98it/s`。

| 代称              | Linux发行版        | Linux内核         | torch cuda/xpu版本 | it/s |
| ----------------- | ------------------ | ----------------- | ------------------ | ---- |
| A770(1)           | CachyOS            | 6.16.7-2-cachyos  | 2.8.0+xpu          | 1.79 |
| A770(2)           | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+xpu          | 1.70 |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 1.70 |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 1.29 |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 0.98 |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "512x512 批量大小:10"
    x-axis ["A770(1)", "A770(2)", "4060ti 16G", "4060 laptop", "4050 laptop"]
    y-axis "每秒迭代数 it/s" 0 --> 3
    %% Green bar
    bar [1.79, 1.70, 1.70, 1.29, 0.98]
    %% Blue bar
    bar [1.79, 1.70]
    line [1.79, 1.70, 1.70, 1.29, 0.98]
") }}

接下来，由于生成压力过大，迭代速度均变为s/it(每次迭代需要多少秒)。
该值越小越好。

| 代称              | Linux发行版        | Linux内核         | torch cuda/xpu版本 | s/it |
| ----------------- | ------------------ | ----------------- | ------------------ | ---- |
| A770(1)           | CachyOS            | 6.16.7-2-cachyos  | 2.8.0+xpu          | 4.05 |
| A770(2)           | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+xpu          | 4.11 |
| 4060ti 16G        | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 3.44 |
| 4060 laptop       | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 4.78 |
| 4050 laptop [60w] | Ubuntu 24.04.3 LTS | 6.14.0-29-generic | 2.8.0+cu129        | 6.16 |

{{ mermaid("
---
config:
  xyChart:
    chartOrientation: horizontal
    showDataLabel: true
  themeVariables:
    xyChart:
      plotColorPalette: '#00FF00, #0000FF, #000000'
---
xychart-beta
    title "1024x1024 批量大小:10"
    x-axis ["A770(1)", "A770(2)", "4060ti 16G", "4060 laptop", "4050 laptop"]
    y-axis "每次迭代需要多少秒 it/s" 0 --> 10
    %% Green bar
    bar [4.05, 4.11, 3.44, 4.78, 6.16]
    %% Blue bar
    bar [4.05, 4.11]
    line [4.05, 4.11, 3.44, 4.78, 6.16]
") }}

## 使用体验

### 影视压制

#### Linux

linux上使用`handbrake`进行压制，但是，`handbrake`的支持英特尔硬解的插件需要使用`flatpak`上面的版本。

### AI Playground(ToDo)

https://github.com/intel/AI-Playground

### 优点

1.  在跑特定的ai任务(如ai绘画，大语言模型)的时候，性能会有优势(还得看模型，比较主流的模型支持的都还不错)。
2.  非矿，价格较低，大显存。
3.  拿来剪辑非常不错。
4.  支持avi硬编码，可用于影视资源的压制。
5.  考虑其价格的话，游戏帧率其实还不错
6.  支持`pytorch`以及`tensorflow`推理框架。
7.  可以软件级别进行多卡交火，十分炫酷。
8.  公版好看，灯带不灵不灵的，十分带感。

### 缺点

1.  待机功耗高
    无敌了，由于英特尔A系列驱动的缺陷，显卡待机功耗非常高，我这个A770待机有40w。
    在Window下，该问题可以缓解，缓解后降低到16w，请按照[英特尔官方教程](https://www.intel.cn/content/www/cn/zh/support/articles/000092564/graphics.html)，待机时手动降低刷新率，关闭屏幕HDR，设置bios中pcie的asmp为L1子状态，以及在windows的电源设置中设置pcie省电为最大节能，详细请看官方教程。
    而在linux下，待机37w，貌似是无解，十分的逆天。
2.  对主板bios要有要求，最好能关闭csm(即完全使用UEFI)，能启用4G以上解码和能启用`resizable bar`。老主板不推荐。
3.  训练来说不是很适合，首先启用xpu训练还是较为折腾，其次，对于纯`pytorch`以及`tensorflow`还可以，如果更复杂的训练情况就不行了。最后，硬件有限制，之前遇到过不支持fp64精度的问题。
4.  一部分游戏性能不太行(dx9和dx11)。网游看风评也不太好，极度依赖驱动优化，而2025年驱动优化英特尔还做的依托。
5.  跑ai大模型的功能是由intel开源的ipex-llm打包的，虽然可以使用英特尔显卡，但是版本会过旧，可能跑不了一些比较新的模型（在我写这篇文章的时候，最新可用的是[ipex-llm 2.3](https://github.com/ipex-llm/ipex-llm/releases/tag/v2.3.0-nightly)，其ollama版本为`v0.9.3` 无法跑最新的qwen3。并且，英特尔并没有提供自己编译的教程，无法编译最新版本的ollama）。此外除了`ollama`，`llama.cpp`等，其他的ai大模型框架有赖于英特尔的适配。
6.  显卡（我的是公版，其他的版本也会有类似问题）在高负载下会有啸叫声。是A770的设计问题，显卡电子元件设计的太密了，在高负载下电流通过电感产生谐波，导致电感发出特殊的声音会更明显。
7.  在Linux下，无法读取显存信息。使用\`xe\`驱动后，\`intel-gpu-tools\`无法获取显卡信息。

### 总结

总之不推荐购买A770。

如果你打游戏，加钱上5060体验会好很多。二手同价位加一点点钱可以上3060ti,3070,6750gre。预算有限，我觉得现阶段16G显存对打游戏不是强需求，12G以内完全够用。

如果你跑ai，老老实实换n卡，环境不需要折腾，用的省心。如果要大显存可以4060ti和5060ti。如果想要便宜3060 12G也不是不可以考虑。计算卡选Telsa T10会比Tesla V100更稳定一点。

如果你能折腾，Tesla V100,MI50是更好的选择。

适合的场景是

- 剪辑视频
- 预算实在有限，想跑的ai，又不想整MI50，V100，2080ti这种花活，且非常想要16G显存。
- 预算实在有限，想玩游戏，并确定你要玩的游戏是A770支持良好的，如dx12游戏。
