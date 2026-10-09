# 已确认 GF 8HP：优先使用此启动方式

保存并正常关闭旧 Cadence。在 Linux terminal 粘贴：

```tcsh
cd ~/ELEC3400/HW3/cadence-drawing-skill
git pull --ff-only
cd cadence-drawing/assets/P4_CADENCE_TRANSFER
tcsh launch_gf_p4.csh
```

启动器使用已确认的 `/dfs/app/gf/gf130HPSIGE_8XP/V1_8_6_0b`，
设置 GF_PDK_HOME/CDSHOME，使用官方 wireopt413 库配置（schematic 仿真），
在 HW3 下新建 GF_P4_时间_PID 项目。只在学校机器的新项目中复制官方
初始化文件；公开仓库不含 PDK 代码或模型。Spectre 使用21.1。

此脚本尚未在远程执行；出现错误请发 P4.log 的末尾。
新 GF_SETUP 窗口打开后，按下方说明配置 npn_inh，再生成两张 P4 图。

---

# P4 Cadence 传输包

本包只生成新的 P4 电路，不打开或复制以前的作业 schematic。

## 文件和共享位置

Windows: `C:\Users\A\Documents\FYP\P4_CADENCE_TRANSFER`
远程 Linux 预计: `~/tsclient/FYP/P4_CADENCE_TRANSFER`
包含 `p4_draw.il`、`launch_p4.csh`、`inspect_gf.sh` 和本说明。

## 先检查 GF 候选安装（Linux terminal）

```tcsh
cd ~/tsclient/FYP/P4_CADENCE_TRANSFER
bash inspect_gf.sh
```

把输出发给我。`/dfs/app/gf/gf130HPSIGE_8XP` 是候选目录；还没确认其中
有作业要求的 GF 8HP `npn_inh`。本包不会猜测 PDK 注册名或模型文件。

若共享文件夹暂未刷新，可在已授权的 Git 仓库更新后使用：

```tcsh
cd ~/ELEC3400/HW3/cadence-drawing-skill
git pull --ff-only
cd cadence-drawing/assets/P4_CADENCE_TRANSFER
bash inspect_gf.sh
```

## PDK 加载后启动（Linux terminal）

先正常保存并关闭旧 Cadence 会话。使用学校提供的 GF 项目初始化方法。
若 GF 已注册在 HW2/cds.lib，直接在本包目录运行：

```tcsh
tcsh launch_p4.csh
```

若课程另有已配置项目，先 `setenv P4_COURSE_PROJECT` 为那个真实目录，
再运行启动脚本；不要使用未经确认的示例路径。
脚本使用 IC23.1 和本机已验证可运行的 Spectre21.1。

若启动提示没有 npn_inh，说明 PDK 未加载。程序会停止，不生成错误替代模型。
PDK 后续加载成功后，可在该会话 CIW 输入 `P4Start()`。
不要重复 load 文件或 P4Start，已经创建的目标库不会覆盖。

## 新设备及新电路（Virtuoso CIW 与 schematic）

脚本建立新的 HW3_P4_时间_PID 库，并打开 NEW `GF_SETUP` 空 schematic。
在此放置一个课程 GF `npn_inh`，方向 R0，用正常属性窗口设置：
Emitter Length=12u、Multiplicity=10、Performance/Breakdown=High_Breakdown。
其余默认值不变。保存，选中这一个设备，保持该窗口打开。
在 **CIW 底部命令框** 输入（不要粘到 Linux terminal）：

```lisp
FreshCapture("GF")
FreshBuildP4()
```

生成 `P4_CURVES_FRESH` 和 `P4_BIAS_FRESH`。设备仅可来自本次新库。
这两张图复制的是本次新配置的 GF 实例，以保留 PDK 属性；不是旧 schematic。
打开两张图，Check and Save，按 F 居中。先检查 netlist 再仿真。

## 仿真要求

### P4(a)：七条曲线

P4_CURVES_FRESH → Launch → ADE Explorer。
Design Variables 加入 VCE 和 IB。DC 扫 VCE=0..2.5V，step=0.1V；
参数扫 IB=0,5u,10u,15u,20u,25u,30u。输出选 Q0 collector current，
正方向为流入 collector。保存七条 IC-VCE 曲线及 ADE setup。

### P4(b)：四电阻偏置

P4_BIAS_FRESH 的初值：VCC=2.5V，R2(上)=10k，R1(下)=7.5k，
RC=100Ω，RE=74.285714Ω。做无 sweep 的 DC operating point。
记录初始 IB、IC、IE、β=IC/IB、VBE=VB-VE、VCE=VC-VE。

IC<5mA 时减小 RE；IC>5mA 时增大 RE，反复 DC 仿真至目标。
保持 RC=100Ω，目标 IC=5mA 对应 VC=2.0V（不是 VCE=2.0V）。
记录最终 RE 和所有 Q 点参数，gm、rπ、ro 从实际 GF model OP 数据读取。
不要套用 P3 的 BF=75 或 VAF=75。

## 目前状态

传输文件已准备；共享位置与压缩包已保存。P3 已有成功仿真截图。
P4 的 GF PDK 注册、实际生成和仿真尚未验证；不会填写虚构结果。
