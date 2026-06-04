# HIGAME · UI 人力架构图工具

一个轻量级的人力架构图工具，**架构图为唯一数据源**，柱状图/饼图/数字看板全部由架构图派生。

## ✨ 当前阶段（第 2 步：静态预览版）

- ✅ 完整还原原图三栏布局（架构图 + 柱状图 + 双饼图 + 顶部数字看板）
- ✅ 22 人初始数据（OCR 自原图 `image.6.png`，与原图统计 100% 吻合）
- ✅ 优化④：单组成员超 6 人自动分 2 列（视觉组从 8 行高压缩到 4 行高）
- ✅ 顶部日期自动取系统当前日期
- ✅ ECharts 三图全部接入并实时派生
- ⏳ 第 3 步将加入：成员增 / 删 / 改交互 + 回收池
- ⏳ 第 4 步：图表精修
- ⏳ 第 5 步：整图 PNG/SVG 一键导出

## 🚀 启动方式

```bash
# 1. 安装依赖
npm install

# 2. 开发模式（自动开浏览器）
npm run dev

# 3. 打包为静态站点（dist/）
npm run build

# 4. 本地预览打包结果
npm run preview
```

构建完成后，`dist/` 目录可直接拷贝到内网服务器，或双击 `dist/index.html` 离线运行。

## 📁 目录结构

```
.
├── index.html
├── package.json
├── vite.config.js
└── src/
    ├── main.js                  入口
    ├── App.vue                  总布局
    ├── styles/global.css        全局样式
    ├── config/
    │   └── fixedStructure.js    固定骨架（根/4组/PM/4身份）— 不可变
    ├── data/
    │   └── mockMembers.js       OCR 22 人初始数据
    ├── stores/
    │   └── useOrgStore.js       Pinia 状态中心 + 派生统计
    ├── utils/
    │   └── treeLayout.js        SVG 树形布局算法（含分列规则）
    └── components/
        ├── OrgChart.vue         主架构图 SVG 容器
        ├── OrgNode.vue          单个节点（根/组/成员/PM）
        ├── TopHeader.vue        右上角数字看板
        └── ChartPlaceholder.vue 柱状图 + 双饼图（ECharts）
```

## 🔒 数据规则

| 字段 | 是否可改 |
|------|---------|
| 成员中文/英文姓名 | ✅ |
| 所属组、身份标签 | ❌ 锁定 |
| 组别/组长/PM | ❌ 完全锁定 |

PM（赵晨杨）永远显示，**且不计入任何统计**。
