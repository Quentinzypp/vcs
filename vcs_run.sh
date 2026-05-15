#!/bin/csh -f
# 指定该脚本使用 csh 解释器执行
# -f 表示启动 csh 时不读取用户的 .cshrc 配置文件，避免环境配置干扰脚本执行

set nc_def = ""
# 定义变量 nc_def，当前值为空字符串
# 这个变量后面用于 VCS 的 +define+ 选项，表示 Verilog 编译宏定义
# 如果写成 set nc_def = "SIM"，后面就会变成 +define+SIM

set flist = "./flist.f" ;
# 定义变量 flist，表示源文件列表文件是 ./flist.f
# VCS 后面会通过 -f $flist 读取这个文件中的 Verilog/SystemVerilog 文件路径

set notiming = "+nospecify";
# 定义变量 notiming，值为 +nospecify
# +nospecify 表示让 VCS 忽略 Verilog 中的 specify timing block
# 常用于 RTL 仿真，避免进行 specify 路径延迟和时序检查

vcs -full64 \
# 调用 VCS 编译器
# -full64 表示使用 64 位模式运行 VCS

-debug_access+all \
# 开启完整调试访问权限
# 方便后续用 DVE/Verdi 查看层次结构和内部信号

-line \
# 保留源代码行号信息
# 编译报错或调试时可以定位到具体代码行

+vcsd \
# 开启 VCS 调试相关功能
# 通常用于配合 VCS/DVE 调试

+vpi \
# 启用 VPI 接口支持
# 如果仿真中需要调用 VPI/PLI 外部接口，需要该选项

+plusarg_save \
# 保存仿真运行时传入的 plusargs 参数
# plusargs 一般是形如 +TEST=xxx 这样的运行参数

-Mupdate \
# 启用增量编译
# 如果部分文件没有变化，下一次编译时可以复用之前结果，加快编译速度

+cli+3 \
# 开启 VCS 命令行交互调试能力
# 数字 3 表示较高等级的 CLI 调试支持

+error+10 \
# 当错误数量达到 10 个时停止编译
# 避免错误太多导致日志过长

+v2k \
# 启用 Verilog-2001 语法支持
# v2k 即 Verilog 2000/2001

+ntb_exit_on_error=10 \
# 针对 testbench 的错误控制选项
# 当仿真错误达到 10 个时退出

-timescale=1ns/100ps \
# 设置默认仿真时间单位和时间精度
# 时间单位是 1ns，时间精度是 100ps
# 如果源文件中没有写 `timescale，就使用这个默认值

-negdelay \
# 允许负延迟
# 常用于带 SDF 反标或门级时序仿真的场景

+neg_tchk \
# 允许负的 timing check
# 也是时序仿真相关选项

+memcbk \
# 开启 memory callback 支持
# 常用于调试工具观察 memory/array 变化

+sdfverbose \
# 如果进行 SDF 反标，输出更详细的 SDF 信息
# 方便查看 SDF 标注情况

+define+$nc_def \
# 给 Verilog 编译添加宏定义
# 由于当前 nc_def 为空，这里实际展开可能是 +define+
# 如果 nc_def="SIM"，则展开为 +define+SIM

+warn=all \
# 打开所有 warning 提示

+warn=noTFIPC \
# 关闭 TFIPC 类型的 warning
# 具体 warning 类型由 VCS 定义

$notiming \
# 展开前面定义的 notiming 变量
# 当前等价于 +nospecify

+warn=noWSUM \
# 关闭 WSUM 类型的 warning
# 用于减少某些不想看的 warning

-l vcs.log \
# 指定 VCS 编译日志输出到 vcs.log 文件

-f $flist
# 指定 VCS 从 flist 文件中读取待编译的源文件列表
# 当前 $flist 等价于 ./flist.f

if ($status != 0) then
# 判断上一条命令，也就是 vcs 编译命令，是否执行失败
# 在 csh 中，$status 表示上一条命令的返回值
# 0 表示成功，非 0 表示失败

/bin/echo -e "\t@@@ RTL Compile FAILED"
# 如果编译失败，打印提示信息：RTL Compile FAILED
# \t 表示前面加一个 Tab 缩进

/bin/echo -e ""
# 打印一个空行，让日志显示更清楚

exit 0
# 退出脚本
# 注意：这里 exit 0 表示“正常退出”
# 如果希望编译失败时让外部工具也知道失败，更推荐写 exit 1

endif
# if 判断结束

./simv +vcs+lic+wait -l ./simv.log
# 如果编译成功，运行 VCS 生成的仿真可执行文件 simv
# +vcs+lic+wait 表示如果 VCS license 暂时不可用，就等待 license
# -l ./simv.log 表示把仿真运行日志保存到 simv.log