# TikZ 插图复刻：执行步骤、文件索引与十轮修改记录

英文对应文档：[note.en.md](note.en.md)。两份文档按相同章节组织。

## 1. 任务范围与最终结果

输入是 [example-image.png](example-image.png)，尺寸为 **243 × 185 像素**。任务是用 TikZ 重建小男孩、风筝和树，删除蓝色“？”、“4 m”、“13 m”及斜向、水平、竖直距离标线，完成 10 轮渲染比较，把中间文件保存在 `tmp/`。

实际风筝线、蓝色鞋子和深蓝色风筝结属于插图，不属于距离标注，予以保留。树冠在原图顶部被裁切，复刻保持这一构图，没有补画完整树顶。

最终源码为 [mwe.tex](mwe.tex)，最终矢量文件为 [mwe.pdf](mwe.pdf)。图形由 TikZ 填充路径、三次 Bézier 曲线和描边构成，没有把原图嵌入 PDF，也没有用像素色块铺成图像。共保存 10 个内容不同的源码快照，每轮均实际编译和渲染。第 1 轮是初版基线，第 2—10 轮是在前一轮基础上的修改。

结果是高相似度矢量近似，不是逐像素完全一致。源图的模糊、压缩痕迹和局部边缘纹理没有重现；被蓝色标注遮住的区域也没有可直接比较的干净原图。

## 2. 按执行顺序列出的具体步骤

### 2.1 检查输入与工具

1. 查看工作目录，确认存在 `example-image.png` 和初始为空的 `mwe.tex`。
2. 打开原图，识别三个蓝色标识、三条距离标线和应保留的真实风筝线。
3. 查阅中文写作与 PDF 渲染工作规范。
4. 使用 `where.exe pdflatex xelatex lualatex pdftoppm python` 检查可执行程序。环境中已有 TeX Live、Poppler 和 Python；实际绘图编译使用 `pdflatex`，实际栅格化使用 `pdftoppm`，没有安装依赖。
5. 检查 Python 中的 Pillow、NumPy、OpenCV、SciPy 和 PyMuPDF（`fitz`）是否可用。
6. 用 Pillow 读取原图并转换为 RGB，确认尺寸，创建 `tmp/`。环境检查与依赖检查只输出到会话，没有另存终端日志。

### 2.2 放大原图、局部裁切与取色

7. 将原图放大至 **972 × 740**，保存为 `tmp/reference-4x.png`。这是参考图放大，不是 TikZ 渲染。
8. 分别裁切男孩、风筝和树，再放大 6 倍：

| 对象 | 原图裁切框 `(left, top, right, bottom)` | 放大后尺寸 | 文件 |
|---|---|---|---|
| 男孩 | `(23,88,62,175)` | 234 × 522 | `tmp/boy-detail.png` |
| 风筝 | `(137,6,163,32)` | 156 × 156 | `tmp/kite-detail.png` |
| 树 | `(104,0,202,175)` | 588 × 1050 | `tmp/tree-detail.png` |

裁切框遵循 Pillow 规则，右侧和底部不包含在裁切范围内。

9. 打开放大图，观察头发、脸、衣服、手脚、风筝面片、树冠凹凸轮廓、树干橙色带和树皮线。
10. 读取若干原图像素的 RGB 值，建立初始配色。后续继续对肤色、风筝颜色和描边进行取样；这些取样值输出到会话，没有独立的取色数据文件。

### 2.3 建立纯 TikZ 初版

11. 使用 `standalone` 文档类和 TikZ，设置 `border=0pt`。
12. 采用 `x=1bp,y=-1bp`：左上角为坐标原点，向右为正 x，向下为正 y。原图一个像素坐标对应一个绘图单位；这里的 bp 是 PDF 排版单位，并不表示源图的真实印刷 DPI。
13. 把画布和裁切范围固定为 `(0,0)` 到 `(243,185)`，保持原图构图和留白。
14. 定义树叶、树皮、橙色带、皮肤、头发、衣服、短裤、鞋子和风筝等颜色，设置可调整的线宽和位置参数。
15. 按遮挡顺序绘制树干、树干橙色带、树皮线、树冠及树冠内部曲线。
16. 绘制从男孩手部延伸至风筝结的真实风筝线；不建立距离标线与文字节点。
17. 绘制风筝四个交替颜色的面片、边框、交叉骨架和深蓝色结。
18. 按前后关系绘制男孩的手臂、腿、脸和脖子、上衣、短裤、鞋子、头发及眼部短线。
19. 编译初版，生成 `tmp/mwe.pdf`、`tmp/mwe.log`、`tmp/mwe.aux`，并栅格化为 `tmp/initial.png`。这些通用名的 PDF、日志和辅助文件后来被最终编译覆盖；`initial.png` 保留了初版外观。初版的完整独立快照保存在 `tmp/iteration-01/`。
20. 查看初版，发现男孩皮肤和上衣缺少实际描边。这一问题在第 2 轮显式添加 `draw=ink` 后修正。

### 2.4 建立比较与存档机制

21. 创建 `tmp/compare.py`，将参考图读取、蓝色标注屏蔽、区域评分、编译、渲染和三栏对比图封装为函数。
22. 根据颜色阈值识别蓝色标注，并对屏蔽区域进行膨胀，避免把已删除标线附近的抗锯齿边缘当作复刻误差。鞋子和风筝结所在矩形区域先排除出蓝色候选。
23. 保存 `tmp/comparison-valid-mask.png`。它表示全图哪些位置没有被蓝色屏蔽规则排除，不等同于最终四个评分区域的并集。
24. 每次调用 `run_round(number, note)`，先把当时的根目录 `mwe.tex` 复制到本轮目录，再编译 PDF、保存控制台输出、渲染 PNG、计算指标、制作对比图，并更新总记录。
25. 使用模块导入方式加载比较工具。Python 自动生成 `tmp/__pycache__/compare.cpython-312.pyc`，它只是字节码缓存，不是设计成果。
26. 所有正式轮次以 `tmp/iteration-01/` 至 `tmp/iteration-10/` 为准。最早的 `initial.png` 是基线预览，不是第 11 轮。

### 2.5 在轮次之间进行测量和局部检查

27. 在第 2 轮渲染图中，找出接近各填充色的像素，使用 3 × 3 腐蚀减少边缘混色影响，排除蓝色屏蔽区，再从原图同位置取中位 RGB。第 3 轮据此更新了七种颜色。
28. 使用 OpenCV 仿射平移与 SciPy 的 Nelder–Mead 优化，估计男孩和树的亚像素偏移。男孩估计值约为 `(0.195,-0.157)`，第 4 轮采用 `(0.20,-0.16)`；树的估计偏移很小，没有采用，`TreeX`、`TreeY` 保持 0。
29. 在原图 x=62—107 的列上寻找灰褐色风筝线像素，采样线的位置，拟合二次多项式；又尝试用最小二乘拟合 Bézier 控制点。实验只在会话中输出，没有独立结果文件。
30. Bézier 拟合得到的候选控制点没有写入最终源码。实际保留原有中间控制点 `(72.9,79.1)` 和 `(115.0,53.9)`，之后只调整手端坐标与线宽。不能把这一拟合实验描述为已经应用的曲线重构。
31. 第 5 轮后，把原图与该轮渲染图的男孩、风筝局部并排放大，保存 `tmp/boy-round5.png` 和 `tmp/kite-round5.png`。这些图左边为参考，右边为渲染，用于检查轮廓、面片和线宽。
32. 继续读取手、脸、腿、短裤边缘、头发和树冠内部线条附近的原图像素，辅助第 6—8 轮配色和描边调整。
33. 第 7 轮后估计风筝平移约为 `(0.111,0.114)`；第 8 轮采用 `(0.11,0.11)`。
34. 第 8 轮后制作 `tmp/boy-round8.png`、`tmp/kite-round8.png`，比较头发边缘、鞋尖、眼部短线和风筝结，再实施第 9 轮修改。
35. 每轮对照实际渲染与数值结果判断下一步，并在第 10 轮完成树轮廓和风筝线线宽的最后微调。

### 2.6 最终编译、汇总与检查

36. 完成第 10 轮后，直接编译根目录最终 `mwe.tex`，而不是仅复制旧轮次 PDF。这次编译返回码为 0。
37. 最终编译更新 `tmp/mwe.pdf`、`tmp/mwe.log`、`tmp/mwe.aux`；将 PDF 复制到根目录 `mwe.pdf` 作为交付件。
38. 把最终 PDF 渲染为 `tmp/final.png`，并制作 `tmp/final-comparison.png`。
39. 把内存中的十轮记录导出为 `tmp/iterations.csv`；`tmp/iterations.json` 已由每轮流程持续更新。
40. 将十轮渲染缩小到原图尺寸，按 5 列 × 2 行拼成 `tmp/all-iterations.png`，标注轮次和加权误差。
41. 用 PyMuPDF 检查最终 PDF：1 页，页面约 **242.997 × 184.998 PDF 点**，嵌入位图数量为 **0**。与 243 × 185 的细微差异来自单位换算与输出精度。
42. 检查根目录 `mwe.tex` 与第 10 轮源码逐字节一致；确认 10 个轮次均有源码、PDF、PNG、对比图和指标，且 10 份源码内容彼此不同。
43. 再次计算最终图得分，并查看最终渲染、十轮总览和最终对比图，确认没有保留蓝色距离文字或距离标线。
44. 按要求保留所有中间文件，没有清理轮次快照、局部图、日志或 Python 缓存。

## 3. 像素比较方法与局限

### 3.1 分辨率与屏蔽规则

每轮 PDF 先渲染到 **972 × 740**，评分时用 Lanczos 缩回 **243 × 185**。比较对象是 RGB 通道，而不是 PDF 路径坐标。

蓝色候选条件为 `B > R + 16`、`B > G + 19`、`G < 150`，三个条件同时满足。先清除候选掩膜中的鞋子矩形 `x∈[24,51), y∈[158,175)` 和风筝结矩形 `x∈[137,148), y∈[23,34)`，再使用 5 × 5 全 1 核膨胀。

这是自动近似屏蔽，不是人工逐像素分割。膨胀会排除标注附近的一些插图像素；保留区域也不是对物体边缘的精确分割。被屏蔽区域的补画质量需要视觉判断，指标本身无法证明。

### 3.2 区域和公式

| 区域 | 原图范围 `(x0,y0,x1,y1)` | 附加条件 | 权重 |
|---|---|---|---:|
| boy | `(22,89,62,175)` | 排除蓝色屏蔽区 | 0.35 |
| tree | `(105,0,202,175)` | 排除蓝色屏蔽区 | 0.40 |
| kite | `(137,7,163,33)` | 排除蓝色屏蔽区 | 0.20 |
| string | `(53,30,143,105)` | 参考像素最小通道值 < 235，且 x < 108；排除蓝色屏蔽区 | 0.05 |

范围的右侧和底部不包含在内。逐像素误差是三个通道绝对差的平均；区域 MAE 是有效像素误差的平均。总分为：

`weighted_mae = 0.35 × boy + 0.40 × tree + 0.20 × kite + 0.05 × string`

分值越低越好，通道数值范围为 0—255。该指标是自定义区域加权 MAE，不是相似度百分比，也不是全图 MAE、SSIM 或 PSNR。区域并不互斥：树区域包含风筝，风筝线区域也可能包含手部，所以修改一个对象可能改变多个区域得分。风筝线评分只关注参考图中已有的较暗像素，对新增到其他位置的错误线条惩罚不足，因此必须配合看图。

### 3.3 对比图读法

每张 `comparison.png` 为 **2187 × 590**：左栏保留带标注的原图，中栏为 TikZ 渲染，右栏为绝对误差图。红色越明显，差异越大；灰色表示屏蔽区。误差红色强度按 4 倍放大、最高截断至 255；未纳入区域并集的背景为浅灰。

这不是“修复后的无标注真值图”。保留原始参考可以避免把自动补画内容误当作原图证据。

## 4. tmp 中每个文件的对应关系

本次核对时，`tmp/` 共 **100 个文件**：下表 20 个文件，加上 10 个轮次目录各 8 个文件。下文每轮都给出这 8 个文件的独立链接，覆盖全部 100 个文件。

### 4.1 非轮次目录文件：20 项

| 文件 | 生成阶段与用途 |
|---|---|
| [tmp/reference-4x.png](tmp/reference-4x.png) | 原图 4 倍放大，观察整体构图。 |
| [tmp/boy-detail.png](tmp/boy-detail.png) | 初始男孩局部，6 倍放大。 |
| [tmp/kite-detail.png](tmp/kite-detail.png) | 初始风筝局部，6 倍放大。 |
| [tmp/tree-detail.png](tmp/tree-detail.png) | 初始树局部，6 倍放大。 |
| [tmp/initial.png](tmp/initial.png) | 正式记录轮次前生成的初版 TikZ 预览。 |
| [tmp/compare.py](tmp/compare.py) | 编译、评分、存档与三栏对比图函数；不是自动优化器。 |
| [tmp/comparison-valid-mask.png](tmp/comparison-valid-mask.png) | 243 × 185 屏蔽图；白色未排除，黑色被排除。 |
| [tmp/__pycache__/compare.cpython-312.pyc](tmp/__pycache__/compare.cpython-312.pyc) | Python 3.12 导入比较模块后自动生成的字节码缓存。 |
| [tmp/boy-round5.png](tmp/boy-round5.png) | 第 5 轮男孩并排局部对比，624 × 688。 |
| [tmp/kite-round5.png](tmp/kite-round5.png) | 第 5 轮风筝并排局部对比，416 × 216。 |
| [tmp/boy-round8.png](tmp/boy-round8.png) | 第 8 轮男孩并排局部对比，624 × 688。 |
| [tmp/kite-round8.png](tmp/kite-round8.png) | 第 8 轮风筝并排局部对比，416 × 216。 |
| [tmp/iterations.json](tmp/iterations.json) | 十轮修改说明、四个区域 MAE 和加权 MAE，逐轮更新。 |
| [tmp/iterations.csv](tmp/iterations.csv) | 最后导出的同一批记录，便于表格软件读取，UTF-8 BOM 编码。 |
| [tmp/mwe.aux](tmp/mwe.aux) | 根目录最终源码编译产生的 LaTeX 辅助文件；已覆盖初版同名文件。 |
| [tmp/mwe.log](tmp/mwe.log) | 根目录最终源码编译日志；已覆盖初版同名文件。 |
| [tmp/mwe.pdf](tmp/mwe.pdf) | 根目录最终源码的编译结果，也是根目录交付 PDF 的复制来源。 |
| [tmp/final.png](tmp/final.png) | 最终 PDF 的 972 × 740 预览。 |
| [tmp/final-comparison.png](tmp/final-comparison.png) | 最终原图／渲染／误差三栏图。 |
| [tmp/all-iterations.png](tmp/all-iterations.png) | 十轮缩略图与加权分数，1215 × 430。 |

### 4.2 每轮固定的 8 种文件

| 文件名 | 含义 |
|---|---|
| `mwe.tex` | 该轮当时的完整源码快照，不会随根目录源码后续修改而改变。 |
| `mwe.pdf` | 该轮源码实际编译出的单页矢量图。 |
| `mwe.png` | 该轮 PDF 的 972 × 740 栅格化结果。 |
| `comparison.png` | 原始参考、该轮渲染和屏蔽后误差图。 |
| `metrics.json` | 轮次、英文修改说明、boy/tree/kite/string 得分、weighted_mae。 |
| `mwe.log` | TeX 引擎写入的详细编译日志。 |
| `mwe-console.txt` | Python 保存的编译标准输出与标准错误拼接文本；不是全部交互会话记录，也不是单独的 Poppler 日志。 |
| `mwe.aux` | LaTeX 自动生成的辅助状态文件。 |

## 5. 复现入口与验证边界

在项目根目录执行以下命令可重新编译最终源码。`tmp/` 在本项目中已经存在。

```sh
pdflatex -interaction=nonstopmode -halt-on-error -output-directory=tmp mwe.tex
pdftoppm -scale-to-x 972 -scale-to-y 740 -singlefile -png tmp/mwe.pdf tmp/final
```

上述命令更新 `tmp/` 内的最终 PDF 和预览，不会自动更新根目录 `mwe.pdf` 副本，也不会重建十轮总览。

`compare.py` 提供 `score(image)`、`compile_tex(source,outdir,stem='mwe')`、`comparison(image,destination)` 和 `run_round(number,note)`。直接运行脚本不会自动执行 10 轮；十轮源码修改、取色、平移估计和最终总览制作是在交互会话中进行的，并没有全部封装进该脚本。

导入脚本会重写 `comparison-valid-mask.png`。`history` 初始为空，`run_round` 会重写总 JSON，也会写入同编号目录。因此不要为了查看历史而直接再次调用它，否则可能覆盖存档。查看既有结果应读取对应快照、JSON、CSV 和图片。

实际执行的验证包括：最终源码独立编译成功、PDF 页数与页面尺寸检查、嵌入图像计数、源码快照一致性、10 份快照互异、轮次文件完整性和最终图像目视检查。没有进行“每个像素完全相同”的验证，也没有据此声称达到逐像素一致。

## 6. 十轮修改逐项记录

以下参数变化通过相邻轮次 `mwe.tex` 差异核对，分数来自各轮 `metrics.json`。每轮 8 个链接与第 4.2 节的文件说明对应。

### 第 1 轮：建立基线

- 手工构建全部 Bézier 轮廓、填充、层次和初始颜色；从一开始就不绘制蓝色距离标注。
- 初始线宽：树 0.90 bp、男孩 0.95 bp、风筝 0.80 bp、风筝线 0.64 bp；树和男孩位移参数均为 0。
- 编译并保存首个完整基线。此时皮肤和上衣描边尚未正常显示。
- 加权 MAE：**12.407693**。
- 文件：[源码](tmp/iteration-01/mwe.tex) · [PDF](tmp/iteration-01/mwe.pdf) · [渲染](tmp/iteration-01/mwe.png) · [对比](tmp/iteration-01/comparison.png) · [指标](tmp/iteration-01/metrics.json) · [TeX 日志](tmp/iteration-01/mwe.log) · [控制台](tmp/iteration-01/mwe-console.txt) · [辅助文件](tmp/iteration-01/mwe.aux)。

### 第 2 轮：修复男孩缺失描边

- 在两条手臂、两条腿、脸／脖子及上衣的六个 `\path` 中显式加入 `draw=ink`。
- 没有改动这些路径的坐标；此轮解决实际描边启用问题，不是形状重画。
- 加权 MAE：**9.862437**。
- 文件：[源码](tmp/iteration-02/mwe.tex) · [PDF](tmp/iteration-02/mwe.pdf) · [渲染](tmp/iteration-02/mwe.png) · [对比](tmp/iteration-02/comparison.png) · [指标](tmp/iteration-02/metrics.json) · [TeX 日志](tmp/iteration-02/mwe.log) · [控制台](tmp/iteration-02/mwe-console.txt) · [辅助文件](tmp/iteration-02/mwe.aux)。

### 第 3 轮：按内部像素中位数校准颜色

| 颜色 | 原 RGB | 新 RGB |
|---|---|---|
| leaf | 171,205,82 | 169,208,79 |
| bark | 233,198,160 | 232,195,159 |
| band | 240,170,107 | 240,169,107 |
| hair | 71,70,68 | 71,71,71 |
| shirt | 251,248,188 | 252,247,191 |
| shorts | 244,67,36 | 250,73,37 |
| shoe | 40,107,139 | 42,105,142 |

- 此轮没有改几何坐标。
- 加权 MAE：**9.592780**。
- 文件：[源码](tmp/iteration-03/mwe.tex) · [PDF](tmp/iteration-03/mwe.pdf) · [渲染](tmp/iteration-03/mwe.png) · [对比](tmp/iteration-03/comparison.png) · [指标](tmp/iteration-03/metrics.json) · [TeX 日志](tmp/iteration-03/mwe.log) · [控制台](tmp/iteration-03/mwe-console.txt) · [辅助文件](tmp/iteration-03/mwe.aux)。

### 第 4 轮：对齐男孩整体位置

- `BoyX: 0 → 0.20`，`BoyY: 0 → -0.16`，即向右 0.20、向上 0.16 个原图坐标单位。
- 平移整个男孩 scope，而不是逐个改身体部位；此时独立风筝线起点尚未随之移动。
- 加权 MAE：**9.446124**。
- 文件：[源码](tmp/iteration-04/mwe.tex) · [PDF](tmp/iteration-04/mwe.pdf) · [渲染](tmp/iteration-04/mwe.png) · [对比](tmp/iteration-04/comparison.png) · [指标](tmp/iteration-04/metrics.json) · [TeX 日志](tmp/iteration-04/mwe.log) · [控制台](tmp/iteration-04/mwe-console.txt) · [辅助文件](tmp/iteration-04/mwe.aux)。

### 第 5 轮：加粗男孩与风筝描边

- `BoyWidth: 0.95 → 1.20 bp`。
- `KiteWidth: 0.80 → 1.15 bp`。
- 此轮不改变形状坐标；随后生成第 5 轮男孩和风筝局部对比图。
- 加权 MAE：**8.982546**。
- 文件：[源码](tmp/iteration-05/mwe.tex) · [PDF](tmp/iteration-05/mwe.pdf) · [渲染](tmp/iteration-05/mwe.png) · [对比](tmp/iteration-05/comparison.png) · [指标](tmp/iteration-05/metrics.json) · [TeX 日志](tmp/iteration-05/mwe.log) · [控制台](tmp/iteration-05/mwe-console.txt) · [辅助文件](tmp/iteration-05/mwe.aux)。

### 第 6 轮：调整肤色、风筝配色和树线宽

- `skin: (242,195,141) → (239,186,130)`。
- `pink: (211,128,184) → (221,122,177)`。
- `cyan: (140,208,218) → (136,209,223)`。
- `TreeWidth: 0.90 → 1.10 bp`。
- 树冠上侧内部曲线 `0.75 → 0.95 bp`，下侧内部曲线 `0.80 → 1.00 bp`。
- 加权 MAE：**8.595287**。
- 文件：[源码](tmp/iteration-06/mwe.tex) · [PDF](tmp/iteration-06/mwe.pdf) · [渲染](tmp/iteration-06/mwe.png) · [对比](tmp/iteration-06/comparison.png) · [指标](tmp/iteration-06/metrics.json) · [TeX 日志](tmp/iteration-06/mwe.log) · [控制台](tmp/iteration-06/mwe-console.txt) · [辅助文件](tmp/iteration-06/mwe.aux)。

### 第 7 轮：调整真实风筝线

- `StringWidth: 0.64 → 0.95 bp`。
- 手端起点 `(55.6,102.6) → (55.8,102.44)`，与男孩整体位移一致。
- 保留中间控制点和靠近风筝的曲线路径，没有采用此前最小二乘拟合的候选控制点。
- 加权 MAE：**8.043661**；风筝线区域误差从上一轮约 24.731 降到 14.258。
- 文件：[源码](tmp/iteration-07/mwe.tex) · [PDF](tmp/iteration-07/mwe.pdf) · [渲染](tmp/iteration-07/mwe.png) · [对比](tmp/iteration-07/comparison.png) · [指标](tmp/iteration-07/metrics.json) · [TeX 日志](tmp/iteration-07/mwe.log) · [控制台](tmp/iteration-07/mwe-console.txt) · [辅助文件](tmp/iteration-07/mwe.aux)。

### 第 8 轮：风筝亚像素对齐与男孩边缘强化

- 给整个风筝 scope 添加 `shift={(0.11,0.11)}`，风筝和结向右、向下各移动 0.11；独立的风筝线路径不在该 scope 内。
- `shortedge: (156,80,44) → (139,59,35)`，加深短裤描边。
- 头发独立描边 `0.75 → 1.05 bp`。
- 生成第 8 轮男孩和风筝局部对比图。
- 加权 MAE：**7.960093**。
- 文件：[源码](tmp/iteration-08/mwe.tex) · [PDF](tmp/iteration-08/mwe.pdf) · [渲染](tmp/iteration-08/mwe.png) · [对比](tmp/iteration-08/comparison.png) · [指标](tmp/iteration-08/metrics.json) · [TeX 日志](tmp/iteration-08/mwe.log) · [控制台](tmp/iteration-08/mwe-console.txt) · [辅助文件](tmp/iteration-08/mwe.aux)。

### 第 9 轮：鞋尖、眼部和风筝结细节

- `knot: (47,91,138) → (47,54,126)`，使风筝结更接近深蓝紫色。
- 收窄右鞋鞋尖：上侧 Bézier 两控制点从 `(47.1,167.7)`、`(49.8,168.2)` 改为 `(46.6,167.7)`、`(49.0,168.2)`，鞋尖端点从 `(49.7,170.2)` 改为 `(48.9,170.2)`；返回曲线第一控制点从 `(49.3,172.8)` 改为 `(48.5,172.8)`。
- 眼部短线宽度 `0.65 → 0.95 bp`；两端从 `(47.2,103.7)–(47.5,105.4)` 改为 `(47.0,103.6)–(47.3,105.3)`。
- 加权 MAE：**7.898198**。
- 文件：[源码](tmp/iteration-09/mwe.tex) · [PDF](tmp/iteration-09/mwe.pdf) · [渲染](tmp/iteration-09/mwe.png) · [对比](tmp/iteration-09/comparison.png) · [指标](tmp/iteration-09/metrics.json) · [TeX 日志](tmp/iteration-09/mwe.log) · [控制台](tmp/iteration-09/mwe-console.txt) · [辅助文件](tmp/iteration-09/mwe.aux)。

### 第 10 轮：最终线宽微调与源码说明

- `TreeWidth: 1.10 → 1.20 bp`。
- `StringWidth: 0.95 → 1.15 bp`。
- 添加四行源码注释，说明十轮存档位置、删除的标注、保留的插图元素，以及没有复现位图模糊和压缩的限制。
- 加权 MAE：**7.797865**。相对第 1 轮下降约 **37.153%**，这是误差下降比例，不是“97% 相似”之类的相似度结论。
- 男孩区域 MAE 从第 9 轮的 9.621779 小幅上升到 9.632924，而树和风筝线等区域改善，使加权总分下降；并非每个区域在每轮都单调改善。
- 文件：[源码](tmp/iteration-10/mwe.tex) · [PDF](tmp/iteration-10/mwe.pdf) · [渲染](tmp/iteration-10/mwe.png) · [对比](tmp/iteration-10/comparison.png) · [指标](tmp/iteration-10/metrics.json) · [TeX 日志](tmp/iteration-10/mwe.log) · [控制台](tmp/iteration-10/mwe-console.txt) · [辅助文件](tmp/iteration-10/mwe.aux)。
