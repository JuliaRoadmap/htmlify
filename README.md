![](https://img.shields.io/badge/version-1.0.0-green)

## 构建流程
以下操作应每周/每月一次进行：
1. 准备服务器可以读取的环境（服务器/仓库）
2. 从此仓库releases中获取最新版本（若有）
3. 从`zh/`仓库获取最新文档（需保证README中的HTMLify标签 ≤ 本项目版本）
4. 准备一个目录，用于存放HTML（及相关数据）
5. 从`src/manage.jl`编译此项目中的代码，调用`generate(文档主目录路径,放置HTML的路径)`
6. 测试服务器（静态host）功能

## 注意事项
* 形如`/docs/`的应被重定向至`/docs/index.html`
* 特别地，`/`应被重定向至`/docs/meta/about.html`
* `generate`构建时会调用`@info`和`@error`（若有）
* 位于`src/manage.jl:3`的`buildmessage`应被修改

## todo
- [ ] 在索引页收藏页面
- [x] 双击将数据存入剪贴板
- [x] 评论区（giscus）
- [x] `#header`定位
- [x] `#L-L`定位
- [ ] 完善侧边栏
- [x] `.jl`，`.txt`
- [ ] `jl`长转义
- [ ] `jl`正则表达式
- [ ] 舒适的初始化
- [ ] 允许调整字体大小
- [ ] LaTeX
- [x] 插入html
- [x] 插入条件激发
- [ ] 插入填空题

## 废弃的计划
- [x] ~~评论区（gitalk）~~
	- [ ] ~~gitalk暗色模式~~
