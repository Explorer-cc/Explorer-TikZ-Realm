### 使用path 绘制路径的中点的箭头

使用tikz宏包可以实现许多高度自定义的绘制效果，一种常见的使用场景是在路径的`pos=0.5`处添加箭头。通过使用`decorations.markings`库可以做如下实现：

```latex
\documentclass[border=8pt,tikz]{standalone}
\usetikzlibrary{decorations.markings,arrows.meta}
\begin{document}
\begin{tikzpicture}[
    ->-/.style = {decoration={markings,
                    mark=at position .6 with {\arrow{Stealth[scale=1.2]}},},
                    postaction={decorate},cap=round}]
    \draw[->-,magenta] (0,0) -- (up:1);
    \draw[->-,blue] (0,0) to (1,1);
    \draw[->-,violet] (1,1) -- ++(down:2);
    \draw[->-,orange] (1,-1) to ++(1,2);
\end{tikzpicture}
\end{document}
```

![{842B2EE1-BC79-4A2D-A938-7EDF4004B171}](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/%7B842B2EE1-BC79-4A2D-A938-7EDF4004B171%7D.png)

上面的位置`0.6`是因为`Stealth`本身有一定的宽度，`0.6`实际上是一个不准确的经验值，我们也可以看到，当我们需要对多个`path`路径分段绘制时，由于`->-`样式是`\path`的特征并无法实现想要的效果，而**只能是针对整个路径**，如下：

![{26169A32-A573-4CA7-AE21-5DD6162735FA}](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/%7B26169A32-A573-4CA7-AE21-5DD6162735FA%7D.png)

根据`Qrrbrbirlbel`老师（是我最尊敬的一位`TikZ`老师）提供的基于`\pgfarrowdraw`和`pic`的方法，我们可以有如下更优雅的实现（虽然这里面使用的**trick**不是一般的多）：

```latex
\documentclass[border=8pt,tikz]{standalone}
\usetikzlibrary{arrows.meta}
\tikzset{
    arrow shift factor/.initial=.5, % arrow shift option
    pics/arrow/.style={
        /tikz/sloped, /tikz/allow upside down,
        % /tikz/sloped用于让arrow与路径方向平行
        % /tikz/allow upside down关闭tikz自动调整side的功能
        setup code=\pgfarrowtotallength{#1}\pgftransformxshift{(\pgfkeysvalueof{/tikz/arrow shift factor})*\csname pgf@x\endcsname},%基于pgf提供的\pgfarrowdraw控制箭头
        code=\pgfarrowdraw{#1}}, 
      pics/arrow/.default=>,
    } % handle设置默认值 .default
\begin{document}
    \begin{tikzpicture}[
            midwayarrow/.style={
            thick, cap=round,
            % every to句柄将自动合并在每个to(--)选项之后
            every to/.append style={edge node={pic[midway]{arrow={Stealth[scale=1.2]}}}}
        },]
        \draw[midwayarrow] (0,0) to (1,2) to (right:1) to (down:2) to ++(-1,-1) to (up:3);
    \end{tikzpicture}
\end{document}arrowdraw
```

![{4DAA3990-4EEB-4258-AF53-3654C8B391E4}](https://fig-lianxh.oss-cn-shenzhen.aliyuncs.com/%7B4DAA3990-4EEB-4258-AF53-3654C8B391E4%7D.png)

Happy TikZing!