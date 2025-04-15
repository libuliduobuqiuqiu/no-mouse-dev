## tmux

移动pane:
```
<ctrl-a>/<ctrl-b>  h/j/k/l
```
设置pane宽度和高度:
```
<ctrl-a>/<ctrl-b>  H/J/K/L
```
将当前的pane最大化并且新建一个Window:
```
<ctrl-a>/<ctrl-b> + 
```
### Session

退出保存当前会话（detach):
```
<ctrl-a>/<ctrl-b> d
```
连接指定的会话（attach）:
```
<ctrl-a>/<ctrl-b> attach -t <session-name>
```

### Window

新建一个Window:
```
<ctrl-a>/<ctrl-b> !
```
窗口最大化（恢复窗口）:
```
<ctrl-a>/<ctrl-b> z
```
切换Window(指定编号):
```
<ctrl-a>/<ctrl-b> <Number>
```
新增窗口
```
<ctrl-a><ctrl-b> c
```
删除当前窗口
```
<ctrl-a><ctrl-b> &
```
交换窗口
```
<ctrl-a><ctrl-b> >
```

### Mode
进入Copy-Mode模式
```
<prefix> Enter
```
开启鼠标操作
```
<prefix> m
```

### 备注

文档备注：
- <prefix>为导航键，为<ctrl-a>或者<ctrl-b>

修改状态栏背景颜色（设置为default)：
- tmux_conf_theme_status_right_bg(右边状态栏)
- tmux_conf_theme_status_bg（全局）
