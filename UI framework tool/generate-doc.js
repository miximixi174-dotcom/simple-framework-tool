/**
 * HIGAME · UI 人力架构图工具 - 产品使用说明书生成器
 * 纯 Node.js 内置库实现（zlib + fs + crypto），不依赖任何 npm 包。
 * .docx 本质是 ZIP 包含 XML，这里手工构造。
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const crypto = require('crypto');

// ========= ZIP 构造（最小可用 ZIP，含 deflate 压缩） =========
function crc32(buf) {
    const table = crc32.table || (crc32.table = (() => {
        const t = new Uint32Array(256);
        for (let n = 0; n < 256; n++) {
            let c = n;
            for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
            t[n] = c >>> 0;
        }
        return t;
    })());
    let crc = 0xFFFFFFFF;
    for (let i = 0; i < buf.length; i++) crc = (crc >>> 8) ^ table[(crc ^ buf[i]) & 0xFF];
    return (crc ^ 0xFFFFFFFF) >>> 0;
}

function buildZip(files) {
    // files: [{ name: 'word/document.xml', content: Buffer }]
    const localParts = [];
    const centralParts = [];
    let offset = 0;

    for (const f of files) {
        const nameBuf = Buffer.from(f.name, 'utf8');
        const raw = Buffer.isBuffer(f.content) ? f.content : Buffer.from(f.content, 'utf8');
        const compressed = zlib.deflateRawSync(raw);
        const crc = crc32(raw);

        // Local file header
        const local = Buffer.alloc(30 + nameBuf.length);
        local.writeUInt32LE(0x04034b50, 0);    // signature
        local.writeUInt16LE(20, 4);             // version
        local.writeUInt16LE(0, 6);              // flags
        local.writeUInt16LE(8, 8);              // method = deflate
        local.writeUInt16LE(0, 10);             // mod time
        local.writeUInt16LE(0x21, 12);          // mod date
        local.writeUInt32LE(crc, 14);
        local.writeUInt32LE(compressed.length, 18);
        local.writeUInt32LE(raw.length, 22);
        local.writeUInt16LE(nameBuf.length, 26);
        local.writeUInt16LE(0, 28);             // extra len
        nameBuf.copy(local, 30);
        localParts.push(local, compressed);

        // Central directory header
        const central = Buffer.alloc(46 + nameBuf.length);
        central.writeUInt32LE(0x02014b50, 0);
        central.writeUInt16LE(20, 4);
        central.writeUInt16LE(20, 6);
        central.writeUInt16LE(0, 8);
        central.writeUInt16LE(8, 10);
        central.writeUInt16LE(0, 12);
        central.writeUInt16LE(0x21, 14);
        central.writeUInt32LE(crc, 16);
        central.writeUInt32LE(compressed.length, 20);
        central.writeUInt32LE(raw.length, 24);
        central.writeUInt16LE(nameBuf.length, 28);
        central.writeUInt16LE(0, 30);
        central.writeUInt16LE(0, 32);
        central.writeUInt16LE(0, 34);
        central.writeUInt16LE(0, 36);
        central.writeUInt32LE(0, 38);
        central.writeUInt32LE(offset, 42);
        nameBuf.copy(central, 46);
        centralParts.push(central);

        offset += local.length + compressed.length;
    }

    const centralBuf = Buffer.concat(centralParts);
    const eocd = Buffer.alloc(22);
    eocd.writeUInt32LE(0x06054b50, 0);
    eocd.writeUInt16LE(0, 4);
    eocd.writeUInt16LE(0, 6);
    eocd.writeUInt16LE(files.length, 8);
    eocd.writeUInt16LE(files.length, 10);
    eocd.writeUInt32LE(centralBuf.length, 12);
    eocd.writeUInt32LE(offset, 16);
    eocd.writeUInt16LE(0, 20);

    return Buffer.concat([...localParts, centralBuf, eocd]);
}

// ========= XML 转义 =========
const xmlEscape = (s) => String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');

// ========= 核心：段落/表格/样式构造 =========
const FONT = 'Microsoft YaHei';

// run：一个 <w:r> 文本片段
function runXml(text, opts = {}) {
    const sz = opts.size || 22;        // half-points
    const bold = opts.bold ? '<w:b/><w:bCs/>' : '';
    const italic = opts.italic ? '<w:i/><w:iCs/>' : '';
    const color = opts.color ? `<w:color w:val="${opts.color}"/>` : '';
    const font = `<w:rFonts w:ascii="${FONT}" w:hAnsi="${FONT}" w:eastAsia="${FONT}" w:cs="${FONT}"/>`;
    const sizeXml = `<w:sz w:val="${sz}"/><w:szCs w:val="${sz}"/>`;
    const rPr = `<w:rPr>${font}${bold}${italic}${color}${sizeXml}</w:rPr>`;
    const breakXml = opts.break ? '<w:br/>' : '';
    return `<w:r>${rPr}${breakXml}<w:t xml:space="preserve">${xmlEscape(text || '')}</w:t></w:r>`;
}

function pageBreakXml() {
    return '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';
}

// 段落
function paraXml(runs, opts = {}) {
    const align = opts.align ? `<w:jc w:val="${opts.align}"/>` : '';
    const styleId = opts.style ? `<w:pStyle w:val="${opts.style}"/>` : '';
    const numXml = opts.num
        ? `<w:numPr><w:ilvl w:val="${opts.num.level || 0}"/><w:numId w:val="${opts.num.id}"/></w:numPr>`
        : '';
    const before = opts.before !== undefined ? opts.before : 80;
    const after = opts.after !== undefined ? opts.after : 80;
    const line = opts.line || 360;
    const spacing = `<w:spacing w:before="${before}" w:after="${after}" w:line="${line}" w:lineRule="auto"/>`;
    const shading = opts.shading
        ? `<w:shd w:val="clear" w:color="auto" w:fill="${opts.shading}"/>`
        : '';
    const border = opts.leftBorder
        ? `<w:pBdr><w:left w:val="single" w:sz="18" w:space="6" w:color="${opts.leftBorder}"/></w:pBdr>`
        : (opts.bottomBorder
            ? `<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="${opts.bottomBorder}"/></w:pBdr>`
            : '');
    const indL = (opts.indentLeft !== undefined) ? opts.indentLeft : (opts.num ? 720 : 0);
    const indH = opts.num ? 360 : 0;
    const indent = (indL || indH) ? `<w:ind w:left="${indL}" w:hanging="${indH}"/>` : '';
    const pPr = `<w:pPr>${styleId}${numXml}${spacing}${indent}${border}${shading}${align}</w:pPr>`;
    const runsXml = (runs || []).map(r => {
        if (typeof r === 'string') return runXml(r);
        if (r._raw) return r._raw;
        return runXml(r.text, r);
    }).join('');
    return `<w:p>${pPr}${runsXml}</w:p>`;
}

// 标题
const h1 = (text) => paraXml(
    [{ text, bold: true, size: 36, color: '1E3A8A' }],
    { style: 'Heading1', before: 360, after: 200 }
);
const h2 = (text) => paraXml(
    [{ text, bold: true, size: 28, color: '1E40AF' }],
    { style: 'Heading2', before: 280, after: 140 }
);
const h3 = (text) => paraXml(
    [{ text, bold: true, size: 24, color: '334155' }],
    { style: 'Heading3', before: 200, after: 100 }
);

const para = (text, opts = {}) => paraXml([{ text, ...(opts.run || {}) }], opts);
const richPara = (runs, opts = {}) => paraXml(runs, opts);

// 项目符号
const bullet = (text) => paraXml(
    [{ text }],
    { num: { id: 1, level: 0 }, before: 40, after: 40, line: 340 }
);
const richBullet = (runs) => paraXml(
    runs,
    { num: { id: 1, level: 0 }, before: 40, after: 40, line: 340 }
);
// 编号
const numbered = (text) => paraXml(
    [{ text }],
    { num: { id: 2, level: 0 }, before: 60, after: 60, line: 340 }
);

// 引用块
function callout(lines, color = '1E40AF', bg = 'EEF2FF') {
    // 多行：每行一个段落，左侧粗蓝条 + 浅色底
    return lines.map((line, i) => {
        const runs = Array.isArray(line)
            ? line
            : [{ text: line }];
        return paraXml(runs, {
            leftBorder: color,
            shading: bg,
            before: i === 0 ? 100 : 20,
            after: i === lines.length - 1 ? 100 : 20,
            line: 340,
            indentLeft: 200,
        });
    }).join('');
}

// 表格
function tableCell(text, opts = {}) {
    const isHeader = opts.header === true;
    const align = opts.align || 'left';
    const fill = opts.fill || (isHeader ? '1E40AF' : 'FFFFFF');
    const color = opts.color || (isHeader ? 'FFFFFF' : '1F2937');
    const bold = opts.bold !== undefined ? opts.bold : isHeader;
    const width = opts.width;
    const lines = String(text).split('\n');

    const tcW = width ? `<w:tcW w:w="${width}" w:type="dxa"/>` : '';
    const tcShd = `<w:shd w:val="clear" w:color="auto" w:fill="${fill}"/>`;
    const tcBorders = `
        <w:tcBorders>
            <w:top w:val="single" w:sz="4" w:color="CBD5E1"/>
            <w:left w:val="single" w:sz="4" w:color="CBD5E1"/>
            <w:bottom w:val="single" w:sz="4" w:color="CBD5E1"/>
            <w:right w:val="single" w:sz="4" w:color="CBD5E1"/>
        </w:tcBorders>`;
    const tcMar = `
        <w:tcMar>
            <w:top w:w="80" w:type="dxa"/>
            <w:left w:w="120" w:type="dxa"/>
            <w:bottom w:w="80" w:type="dxa"/>
            <w:right w:w="120" w:type="dxa"/>
        </w:tcMar>`;
    const tcPr = `<w:tcPr>${tcW}${tcShd}${tcBorders}${tcMar}<w:vAlign w:val="center"/></w:tcPr>`;

    const paras = lines.map(ln => paraXml(
        [{ text: ln, bold, color, size: 21 }],
        { align, before: 0, after: 0, line: 320 }
    )).join('');
    return `<w:tc>${tcPr}${paras}</w:tc>`;
}

function buildTable(rows, colWidths) {
    const sum = colWidths.reduce((a, b) => a + b, 0);
    const grid = colWidths.map(w => `<w:gridCol w:w="${w}"/>`).join('');

    const tblXml = rows.map((row, ri) => {
        const cells = row.map((cell, ci) => {
            if (typeof cell === 'object') {
                return tableCell(cell.text, { ...cell, header: ri === 0, width: colWidths[ci] });
            }
            return tableCell(cell, { header: ri === 0, width: colWidths[ci] });
        }).join('');
        const trH = ri === 0 ? '<w:trPr><w:tblHeader/></w:trPr>' : '';
        return `<w:tr>${trH}${cells}</w:tr>`;
    }).join('');

    return `
        <w:tbl>
            <w:tblPr>
                <w:tblW w:w="${sum}" w:type="dxa"/>
                <w:tblBorders>
                    <w:top w:val="single" w:sz="4" w:color="CBD5E1"/>
                    <w:left w:val="single" w:sz="4" w:color="CBD5E1"/>
                    <w:bottom w:val="single" w:sz="4" w:color="CBD5E1"/>
                    <w:right w:val="single" w:sz="4" w:color="CBD5E1"/>
                    <w:insideH w:val="single" w:sz="4" w:color="CBD5E1"/>
                    <w:insideV w:val="single" w:sz="4" w:color="CBD5E1"/>
                </w:tblBorders>
                <w:tblLayout w:type="fixed"/>
            </w:tblPr>
            <w:tblGrid>${grid}</w:tblGrid>
            ${tblXml}
        </w:tbl>
        <w:p><w:pPr><w:spacing w:before="0" w:after="120"/></w:pPr></w:p>`;
}

// ========= 内容构造 =========
const body = [];

// ===== 封面 =====
body.push(paraXml(
    [{ text: 'HIGAME · UI 人力架构图工具', bold: true, size: 56, color: '1E3A8A' }],
    { align: 'center', before: 1800, after: 200 }
));
body.push(paraXml(
    [{ text: '产品使用说明书', bold: true, size: 40, color: '334155' }],
    { align: 'center', before: 100, after: 100 }
));
body.push(paraXml(
    [{ text: 'Product User Manual', italic: true, size: 24, color: '64748B' }],
    { align: 'center', before: 40, after: 800 }
));

body.push(buildTable([
    [{ text: '项目', header: true, align: 'center' }, { text: '内容', header: true, align: 'center' }],
    ['产品名称', 'HIGAME · UI 人力架构图工具（人员架构图工具.html）'],
    ['版本号', 'v2.0'],
    ['适用对象', 'UI 部门 PM、团队负责人、HR 协同人员'],
    ['部署方式', '单文件 HTML，浏览器双击即用'],
    ['文档日期', '2026-05-25'],
    ['编制', '产品研发组'],
], [3120, 6240]));

body.push(pageBreakXml());

// ===== 目录（手动列出，避免 TOC 复杂依赖）=====
body.push(h1('目录'));
const toc = [
    '第一章 · 产品概述',
    '   1.1 产品定位',
    '   1.2 核心特性概览',
    '   1.3 系统要求',
    '第二章 · 快速上手',
    '   2.1 三步开始使用',
    '   2.2 界面整体布局',
    '第三章 · 初始导入向导（核心功能）',
    '   3.1 入口 A：OCR 图片识别',
    '   3.2 入口 B：文本粘贴导入',
    '   3.3 入口 C：AI 对话导入',
    '   3.4 入口 D：JSON 配置导入',
    '   3.5 入口 E：使用默认示例',
    '   3.6 统一预览校对页（核心防呆机制）',
    '第四章 · 主界面功能模块详解',
    '   4.1 顶栏操作区',
    '   4.2 组织架构图（左侧 SVG 区）',
    '   4.3 公司编制占比（右上）',
    '   4.4 各组占比（右中）',
    '   4.5 人员回收池（右下）',
    '第五章 · 人员生命周期管理',
    '   5.1 添加成员',
    '   5.2 编辑成员',
    '   5.3 删除人员（核心流程）',
    '   5.4 自动到期检测机制',
    '   5.5 恢复人员',
    '第六章 · 数据持久化与备份',
    '   6.1 自动保存机制',
    '   6.2 持久化数据范围',
    '   6.3 数据迁移与团队交接',
    '   6.4 数据重置选项',
    '第七章 · 常见问题 FAQ',
    '第八章 · 附录：文本格式速查表',
];
toc.forEach(line => body.push(paraXml([{ text: line, size: 22 }], { before: 30, after: 30, line: 320 })));
body.push(pageBreakXml());

// ===== 第一章 =====
body.push(h1('第一章 · 产品概述'));

body.push(h2('1.1 产品定位'));
body.push(para('HIGAME · UI 人力架构图工具是一款面向 UI 部门 PM 设计的轻量化、零部署的团队组织架构可视化与人员流动管理工具。整个工具由单个 HTML 文件承载，浏览器双击即可运行，无需服务端、无需数据库，所有数据基于浏览器本地存储（localStorage）自动持久化保存。'));
body.push(para('工具围绕"组织架构图为唯一数据源"的设计理念，所有右侧统计图表（公司编制占比饼图、各组占比环形图）、回收池数据均由架构图实时派生，确保数据一致性。'));

body.push(h2('1.2 核心特性概览'));
body.push(buildTable([
    [
        { text: '能力维度', header: true, align: 'center' },
        { text: '功能特性', header: true, align: 'center' },
        { text: '业务价值', header: true, align: 'center' },
    ],
    ['零门槛启动', '单 HTML 文件\n双击即用\n无需安装', '降低使用门槛\n面向全体 PM'],
    ['三模导入', 'OCR 图片识别\n文本智能解析\nAI 对话引导式导入', '快速搭建团队\n适应不同录入习惯'],
    ['可视化架构', 'SVG 渲染\n80% 自适应缩放\n滚轮缩放/拖拽平移', '清晰直观\n大团队也能呈现'],
    ['多维统计', '实时编制饼图\n组别环形图\n四类身份分布', '辅助决策\n一目了然'],
    ['完整生命周期', '增/改/删/恢复\n回收池机制\n避免误删', '人员流动可追溯'],
    ['本地持久化', 'localStorage 自动保存\nJSON 导入导出', '刷新不丢数据\n支持团队交接'],
    ['离职管理', '三种删除原因\n预设离职日期\n自动到期转移', '满足真实业务\n支持远期规划'],
], [2400, 3680, 3280]));

body.push(h2('1.3 系统要求'));
body.push(richBullet([{ text: '浏览器：', bold: true }, { text: 'Chrome 90+ / Edge 90+ / Firefox 88+（推荐 Chrome 最新版）' }]));
body.push(richBullet([{ text: '网络：', bold: true }, { text: '首次打开需联网加载 CDN 资源（Vue 3、ECharts 5、Tesseract.js 5），之后可离线使用' }]));
body.push(richBullet([{ text: '分辨率：', bold: true }, { text: '推荐 1920×1080，最低 1366×768' }]));
body.push(richBullet([{ text: '存储空间：', bold: true }, { text: '浏览器 localStorage 容量约 5MB，可支持万人级别团队数据' }]));

// ===== 第二章 =====
body.push(pageBreakXml());
body.push(h1('第二章 · 快速上手'));

body.push(h2('2.1 三步开始使用'));
body.push(numbered('双击打开「人员架构图工具.html」文件，浏览器自动加载界面'));
body.push(numbered('首次打开自动弹出导入向导，选择适合您的录入方式'));
body.push(numbered('在统一预览页校对无误后，点击"✓ 确认导入"完成初始化'));

body.push(callout([
    [{ text: '💡 小白建议：', bold: true, color: '1E40AF' }, { text: '第一次可点击"🚀 使用默认示例"先体验功能，熟悉后再点顶栏"📥 重新导入"录入您的真实团队数据。' }],
]));

body.push(h2('2.2 界面整体布局'));
body.push(para('工具采用「左 70% 架构图 + 右 30% 统计面板」的经典工作台布局：'));
body.push(buildTable([
    [
        { text: '区域', header: true, align: 'center' },
        { text: '位置', header: true, align: 'center' },
        { text: '主要内容', header: true, align: 'center' },
    ],
    ['顶栏', '页面顶部', '更新时间、重新导入、恢复默认、添加组别、添加成员'],
    ['组织架构图', '左侧 70%', 'SVG 全图渲染，包含总负责人、UI PM、各组组长、组员'],
    ['公司编制占比', '右上', '集团本部 / 集团实习生 / 子公司 / 子公司实习生 占比'],
    ['各组占比', '右中', '各业务组人员数量与百分比环形图'],
    ['人员回收池', '右下', '已离职人员列表，支持恢复、备注编辑、永久删除'],
], [1800, 1800, 5760]));

// ===== 第三章 =====
body.push(pageBreakXml());
body.push(h1('第三章 · 初始导入向导（核心功能）'));

body.push(para('导入向导是工具推广至所有 PM 的关键能力。在两种场景下会自动弹出：（1）首次打开工具时；（2）点击顶栏「📥 重新导入」按钮时。向导提供 5 种入口 + 1 个统一预览页，满足任何录入习惯。'));

body.push(h2('3.1 入口 A：OCR 图片识别'));
body.push(richPara([{ text: '适用场景：', bold: true }, { text: '已有团队架构图截图（PPT 截图、Excel 截图、钉钉群截图、白板拍照等）' }]));

body.push(h3('操作步骤'));
body.push(numbered('在向导首页点击「🖼️ OCR 图片识别」卡片'));
body.push(numbered('支持两种上传方式：① 点击上传区选择文件；② 直接拖拽图片到上传区'));
body.push(numbered('支持格式：PNG、JPG、JPEG'));
body.push(numbered('点击底部「开始识别」按钮，等待进度条完成'));
body.push(numbered('识别完成后在文本框中人工修订错字、漏字'));
body.push(numbered('点击「解析为预览 →」进入校对页'));

body.push(h3('注意事项'));
body.push(callout([
    [{ text: '⚠️ 首次识别：', bold: true, color: 'B45309' }, { text: '会下载约 15MB 的中文语言包，请保持网络畅通，约 10-30 秒' }],
    [{ text: '⚠️ 图片质量：', bold: true, color: 'B45309' }, { text: '清晰度 ≥ 1080p，文字非斜体，无复杂背景，识别率最高' }],
    [{ text: '💡 务必校对：', bold: true, color: '1E40AF' }, { text: 'OCR 不保证 100% 准确，识别后请重点检查组别名、人名错字' }],
], 'F59E0B', 'FFFBEB'));

body.push(h2('3.2 入口 B：文本粘贴导入'));
body.push(richPara([{ text: '适用场景：', bold: true }, { text: '已有花名册 Excel 表格、Word 文档、微信群聊天记录等结构化或半结构化文本' }]));

body.push(h3('支持的三种文本格式'));

body.push(h3('格式 ① 缩进树形（推荐）'));
body.push(callout([
    '张三（总负责人）',
    '  李四（A组组长）',
    '    王五',
    '    赵六',
    '  孙七（B组组长）',
    '    周八',
    '    钱九',
], '475569', 'F8FAFC'));

body.push(h3('格式 ② 一行一组'));
body.push(callout([
    '总负责人：张三',
    'UI PM：陈十',
    'A组：李四（组长）、王五、赵六',
    'B组组长是孙七，成员有周八、钱九',
], '475569', 'F8FAFC'));

body.push(h3('格式 ③ CSV 表格'));
body.push(callout([
    '姓名,角色,组别',
    '张三,总负责人,',
    '李四,组长,A组',
    '王五,组员,A组',
    '孙七,组长,B组',
], '475569', 'F8FAFC'));

body.push(h3('解析关键词识别规则'));
body.push(buildTable([
    [
        { text: '关键字', header: true, align: 'center' },
        { text: '识别结果', header: true, align: 'center' },
    ],
    ['总负责人 / 负责人 / UI 职能', '👑 总负责人'],
    ['UI PM / UIPM / PM / 产品经理', '📌 UI PM'],
    ['组长 / Leader / Lead / (组长) / （组长）', '⭐ 组长'],
    ['其他人名', '👤 组员'],
    ['A组 / 交互组 / 视觉组 / 【设计组】', '🗂️ 组别声明'],
], [4680, 4680]));

body.push(h2('3.3 入口 C：AI 对话导入'));
body.push(richPara([{ text: '适用场景：', bold: true }, { text: 'PM 不想一次性写完，希望边聊边搭建团队结构' }]));

body.push(callout([
    [{ text: '🔒 数据安全说明：', bold: true, color: '16A34A' }, { text: '本工具的"AI"为前端规则解析，不连接任何外部 API，对话内容永不上传外部，请放心使用敏感人员信息。' }],
], '16A34A', 'F0FDF4'));

body.push(h3('支持的对话句式'));
body.push(buildTable([
    [
        { text: '示例输入', header: true, align: 'center' },
        { text: '系统理解', header: true, align: 'center' },
    ],
    ['总负责人 张三', '设置全局总负责人为张三'],
    ['UI PM 陈十', '设置 UI PM 为陈十'],
    ['A组组长是李四', '创建 A 组并指定李四为组长'],
    ['A组加入 王五 赵六', '向 A 组追加成员王五、赵六'],
    ['B组成员有 周八、钱九', '向 B 组追加成员周八、钱九'],
], [4680, 4680]));

body.push(h3('交互特性'));
body.push(bullet('左侧聊天窗口逐句输入，右侧实时显示当前已搭建的结构'));
body.push(bullet('每条机器人回复下方提供快捷选项气泡，可点击直接发送'));
body.push(bullet('完成后点击「完成对话 · 进入预览 →」'));

body.push(h2('3.4 入口 D：JSON 配置导入'));
body.push(richPara([{ text: '适用场景：', bold: true }, { text: '从其他 PM 处接收到导出的 .json 配置文件，或团队交接时数据迁移' }]));
body.push(numbered('在向导首页点击「📂 导入 JSON 配置」'));
body.push(numbered('选择本地的 .json 文件'));
body.push(numbered('系统自动覆盖当前所有数据（含回收池），并显示二次确认提示'));

body.push(h2('3.5 入口 E：使用默认示例'));
body.push(para('选择此入口将加载内置的 22 人示例团队（含交互组、视觉组、重构组、动效组），用于熟悉工具功能。所有数据可后续随时通过"重新导入"覆盖。'));

body.push(h2('3.6 统一预览校对页（核心防呆机制）'));
body.push(para('所有 5 种入口完成解析后，都会汇聚到此页面。这是导入前的最后一道把关，PM 可在此页对每一项进行精修：'));

body.push(h3('可校对项目'));
body.push(buildTable([
    [
        { text: '区块', header: true, align: 'center' },
        { text: '可编辑字段', header: true, align: 'center' },
        { text: '操作', header: true, align: 'center' },
    ],
    ['👑 总负责人', '中文姓名 / 英文名 / 归属类型', '直接修改输入框'],
    ['📌 UI PM', '中文姓名 / 英文名（留空则不显示）', '直接修改输入框'],
    ['🗂️ 每个组别', '组名、每位成员的姓名/英文名/角色', '可添加/删除成员、删除整组'],
    ['➕ 新增组别', '底部"+ 新增一个组别"按钮', '一键添加空组'],
], [2400, 4080, 2880]));

body.push(callout([
    [{ text: '📌 重要提示：', bold: true, color: 'B45309' }, { text: '归属类型默认留空（按产品需求），导入后请在主界面双击人员卡片逐人后补：集团本部 / 集团实习生 / 子公司 / 子公司实习生。' }],
    [{ text: '⚠️ 覆盖警告：', bold: true, color: 'DC2626' }, { text: '点击"✓ 确认导入"将覆盖当前所有数据（包括回收池），系统会弹出二次确认。' }],
], 'F59E0B', 'FFFBEB'));

// ===== 第四章 =====
body.push(pageBreakXml());
body.push(h1('第四章 · 主界面功能模块详解'));

body.push(h2('4.1 顶栏操作区'));
body.push(buildTable([
    [
        { text: '按钮', header: true, align: 'center' },
        { text: '功能说明', header: true, align: 'center' },
        { text: '使用场景', header: true, align: 'center' },
    ],
    ['🕐 更新时间', '显示数据最近一次变动时间，每次操作自动刷新', '查看数据时效'],
    ['📥 重新导入', '重新触发导入向导，覆盖当前数据', '换团队、季度调整'],
    ['⟲ 恢复默认', '清空 localStorage，回到内置 22 人示例数据', '调试、教学、重置'],
    ['＋ 添加组别', '弹窗录入：组名 + 组长（手输或选现有）+ 组别颜色', '新增业务组'],
    ['＋ 添加新成员', '弹窗录入：姓名 / 组别 / 编制 / 离职时间（可选）', '日常入职登记'],
], [2400, 4280, 2680]));

body.push(h2('4.2 组织架构图（左侧 SVG 区）'));

body.push(h3('视图特性'));
body.push(bullet('全 SVG 矢量渲染，无任何位图，缩放无损'));
body.push(bullet('始终保持容器内 80% 比例显示（FIT_RATIO = 0.8）'));
body.push(bullet('支持鼠标滚轮缩放（30% ~ 300%）'));
body.push(bullet('支持按住空白处拖拽平移'));
body.push(bullet('右上角工具栏提供：缩小、当前比例显示、放大、一键重置 80%'));

body.push(h3('节点层级与样式'));
body.push(buildTable([
    [
        { text: '节点类型', header: true, align: 'center' },
        { text: '默认色', header: true, align: 'center' },
        { text: '尺寸', header: true, align: 'center' },
        { text: '显示信息', header: true, align: 'center' },
    ],
    ['UI 职能总负责人', '深蓝 #1E40AF', '220×96', '中文名 / 英文名 / 编制'],
    ['UI PM（虚线连接）', '紫色 #6366F1', '110×60', '中文名 / 英文名'],
    ['组长（彩色卡）', '组色（4 色）', '240×88', '组名 / 中英文姓名 / 编制'],
    ['组员（白底彩条）', '白色 + 组色侧条', '240×45', '中英文姓名 / 编制标签'],
], [2400, 2280, 1640, 3040]));

body.push(h3('组别默认配色'));
body.push(buildTable([
    [
        { text: '业务组', header: true, align: 'center' },
        { text: '配色', header: true, align: 'center' },
        { text: '色值', header: true, align: 'center' },
    ],
    ['交互组', '蓝色', '#4F7CD9'],
    ['视觉组', '绿色', '#7CC576'],
    ['重构组', '黄色', '#F4B942'],
    ['动效组', '红色', '#E15B5B'],
], [3120, 3120, 3120]));

body.push(h3('交互行为'));
body.push(bullet('单击任意节点 → 弹出编辑模态框，可修改姓名、英文名、编制、离职状态'));
body.push(bullet('鼠标悬停在组长卡上 → 右上角浮现「✎ 重命名」「✕ 删除组」操作'));
body.push(bullet('鼠标悬停在组员卡上 → 右侧浮现「✕ 删除」按钮'));
body.push(bullet('待离职成员卡片整体半透明（opacity: 0.6），右下角显示离职日期'));

body.push(h2('4.3 公司编制占比（右上）'));
body.push(para('采用环形饼图展示四类身份分布，由 ECharts 5 渲染，鼠标悬停高亮当前扇区并显示精确人数与百分比。'));
body.push(buildTable([
    [
        { text: '编制类型', header: true, align: 'center' },
        { text: '配色', header: true, align: 'center' },
        { text: '说明', header: true, align: 'center' },
    ],
    ['集团本部', '深蓝 #1E3A8A', '腾讯总部正职'],
    ['集团实习生', '中蓝 #3B82F6', '腾讯总部实习'],
    ['子公司', '浅蓝 #60A5FA', '子公司正职'],
    ['子公司实习生', '最浅蓝 #BFDBFE', '子公司实习'],
], [2880, 2880, 3600]));

body.push(h2('4.4 各组占比（右中）'));
body.push(para('环形图 + 数字网格双视图，左侧为 ECharts 环形图，右侧为每组的「人数 + 百分比 + 标签」垂直列表，悬停时左侧色条向右平移 2px 提供视觉反馈。'));

body.push(h2('4.5 人员回收池（右下）'));
body.push(para('回收池是已离职人员的"垃圾桶"，但与系统垃圾桶不同，所有人员均可恢复或永久删除。'));

body.push(h3('每条记录的展示信息'));
body.push(bullet('姓名（粗体）'));
body.push(bullet('编制类型 · 删除原因（误删 / 填写错误 / 将要离职 / 已离职 自动）'));
body.push(bullet('· 操作时间：用户点击"确认删除"的精确时刻（YYYY-MM-DD HH:mm:ss）'));
body.push(bullet('· 生效时间：实际离职生效时间（橙色显示，与操作时间不同时才显示）'));
body.push(bullet('· 离职日期：预设离职日期（橙色）'));
body.push(bullet('· 备注：自定义文本说明'));

body.push(h3('支持的操作'));
body.push(buildTable([
    [
        { text: '操作', header: true, align: 'center' },
        { text: '触发方式', header: true, align: 'center' },
        { text: '说明', header: true, align: 'center' },
    ],
    ['修改离职原因', '点击原因标签上的 ✎', '系统自动转入的不可改\n手动删除的可任意切换'],
    ['修改预设日期', '原因切到"将要离职"时显示日期选择', '编辑回收池中的离职日期'],
    ['编辑/添加备注', '点击"+ 添加备注"或备注旁的 ✎', '回车保存，Esc 取消'],
    ['恢复成员', '点击「恢复」按钮', '弹出二次确认\n清除所有离职字段'],
    ['彻底删除', '点击「彻底删除」按钮', '永久移除\n不可恢复'],
], [2400, 3280, 3680]));

// ===== 第五章 =====
body.push(pageBreakXml());
body.push(h1('第五章 · 人员生命周期管理'));

body.push(h2('5.1 添加成员'));
body.push(numbered('点击顶栏「＋ 添加新成员」按钮'));
body.push(numbered('在姓名输入框中混合输入中英文名（支持任意顺序）：例如 "molinyang(杨沫)" 或 "杨沫 molinyang"'));
body.push(numbered('系统自动识别拆分为中文 + 英文，并实时显示识别结果预览'));
body.push(numbered('选择所属组别（下拉框）'));
body.push(numbered('选择身份归属（4 选 1）'));
body.push(numbered('（可选）填写离职时间，用于预设未来离职'));
body.push(numbered('点击「确认添加」，新成员立即出现在架构图对应组下'));

body.push(callout([
    [{ text: '🤖 智能姓名识别规则：', bold: true, color: '1E40AF' }],
    '① 括号格式："molinyang(杨沫)" → 中文：杨沫，英文：molinyang',
    '② 中英混合："杨沫 molinyang" → 中文：杨沫，英文：molinyang',
    '③ 仅中文："杨沫" → 中文：杨沫，英文：（空）',
    '④ 仅英文："molinyang" → 中文：（空），英文：molinyang',
]));

body.push(h2('5.2 编辑成员'));
body.push(para('在架构图中单击任意人员卡片（包括总负责人、UI PM、组长、组员），即弹出编辑模态框。可修改字段：'));
body.push(bullet('中文姓名（必填）'));
body.push(bullet('英文名（可选）'));
body.push(bullet('公司编制（4 选 1，UI PM 不可选）'));
body.push(bullet('离职状态：在职 / 将要离职（总负责人和 UI PM 不可选）'));
body.push(bullet('离职时间：当离职状态选"将要离职"时出现日期选择器'));

body.push(h2('5.3 删除人员（核心流程）'));
body.push(para('删除人员是工具最复杂、最严谨的流程，体现产品对真实业务场景的深度考虑。'));

body.push(h3('完整流程图'));
body.push(callout([
    [{ text: 'Step 1', bold: true, color: '1E40AF' }, { text: ' 点击成员卡片右侧的 ✕ 删除按钮' }],
    [{ text: 'Step 2', bold: true, color: '1E40AF' }, { text: ' 弹出"删除原因选择"模态框' }],
    [{ text: 'Step 3', bold: true, color: '1E40AF' }, { text: ' 选择删除时间类型（立即 / 预设）' }],
    [{ text: 'Step 4', bold: true, color: '1E40AF' }, { text: ' 选择删除原因（误删 / 填写错误 / 将要离职）' }],
    [{ text: 'Step 5', bold: true, color: '1E40AF' }, { text: ' （可选）填写备注说明' }],
    [{ text: 'Step 6', bold: true, color: '1E40AF' }, { text: ' 点击"确认删除"，根据时间类型分别处理' }],
]));

body.push(h3('两种删除时间类型的差异'));
body.push(buildTable([
    [
        { text: '维度', header: true, align: 'center' },
        { text: '立即删除', header: true, align: 'center' },
        { text: '预设离职时间', header: true, align: 'center' },
    ],
    ['触发时机', '点击确认即刻', '到达预设日期后系统自动'],
    ['人员去向', '直接进入回收池', '保留架构图\n显示半透明 + 离职日期'],
    ['操作时间', '记为当前时刻', '记为当前时刻'],
    ['生效时间', '= 操作时间', '= 实际转移时间'],
    ['可否恢复', '可', '可（在到达日期前从架构图改回在职即可）'],
    ['典型场景', '员工已离职\n误删需修正', '员工提交辞职\n2026-12-31 离职'],
], [1800, 3680, 3880]));

body.push(h3('三种删除原因的语义'));
body.push(buildTable([
    [
        { text: '原因', header: true, align: 'center' },
        { text: '业务含义', header: true, align: 'center' },
        { text: '建议时间类型', header: true, align: 'center' },
    ],
    ['❌ 误删', '把人删错了\n需要恢复', '立即'],
    ['✏️ 填写错误', '初始录入信息有误\n需要清理重录', '立即'],
    ['🚪 将要离职', '员工正式提出离职\n或 HR 通知', '通常为预设'],
], [2080, 4280, 3000]));

body.push(callout([
    [{ text: '⚠️ 业务规则：', bold: true, color: 'DC2626' }],
    '• 总负责人和组长不可被自动转移（防止架构断层）',
    '• 删除组长前必须先更换组长，否则提示警告',
    '• 至少保留 1 个组别，最后一个组别不可删除',
], 'DC2626', 'FEF2F2'));

body.push(h2('5.4 自动到期检测机制'));
body.push(para('系统会在以下时机自动扫描所有成员，检测是否有人员的"预设离职日期"已到达：'));
body.push(bullet('应用初始化时（页面加载）'));
body.push(bullet('每次添加 / 编辑 / 删除操作后'));
body.push(bullet('（未来可扩展）定时器周期检查'));
body.push(para('对于检测到已到期的人员，系统将自动：'));
body.push(numbered('从架构图中移除'));
body.push(numbered('追加到回收池'));
body.push(numbered('删除原因标记为"已离职（自动）"'));
body.push(numbered('记录"实际生效时间 = 自动转移时刻"'));
body.push(numbered('备注栏自动写入：「系统于 YYYY-MM-DD HH:mm:ss 检测到预设离职日期到达，已自动转入回收池」'));

body.push(h2('5.5 恢复人员'));
body.push(para('从回收池恢复人员需要二次确认，恢复操作将清除所有离职相关字段，把人员重置为"正常在职"状态。'));

body.push(h3('恢复流程'));
body.push(numbered('在回收池条目点击「恢复」按钮'));
body.push(numbered('弹出"恢复人员确认"模态框，显示将被清除的字段'));
body.push(numbered('点击「确认恢复」，系统执行：'));
body.push(bullet('从回收池移除该条目'));
body.push(bullet('清除 deleteReason / deleteReasonLabel / deleteTime / operationTime'));
body.push(bullet('清除 effectiveDepartureTime / departureDate'));
body.push(bullet('设置 status = "active"'));
body.push(bullet('重新加入 members 列表'));
body.push(bullet('记录到 restoreLogs（操作日志）'));

// ===== 第六章 =====
body.push(pageBreakXml());
body.push(h1('第六章 · 数据持久化与备份'));

body.push(h2('6.1 自动保存机制'));
body.push(buildTable([
    [
        { text: '配置项', header: true, align: 'center' },
        { text: '说明', header: true, align: 'center' },
    ],
    ['存储介质', '浏览器 localStorage'],
    ['存储键名', 'higame-ui-data-v1'],
    ['存储格式', 'JSON 字符串'],
    ['触发时机', '任何变更操作后自动写入'],
    ['手动保存', '不需要，全自动'],
    ['容量限制', '单域名约 5MB（可容纳数千人级团队）'],
], [3120, 6240]));

body.push(h2('6.2 持久化数据范围'));
body.push(bullet('groups —— 组别配置（含 key、name、leaderId）'));
body.push(bullet('rootLeader —— 总负责人信息'));
body.push(bullet('uiPM —— UI PM 信息'));
body.push(bullet('members —— 全部在职/待离职成员'));
body.push(bullet('recycleMembers —— 回收池所有记录'));
body.push(bullet('groupColors —— 自定义组别配色'));
body.push(bullet('restoreLogs —— 人员恢复操作日志'));

body.push(h2('6.3 数据迁移与团队交接'));
body.push(buildTable([
    [
        { text: '场景', header: true, align: 'center' },
        { text: '建议方案', header: true, align: 'center' },
    ],
    ['同电脑跨浏览器', '不支持（localStorage 浏览器隔离），建议导出 JSON'],
    ['换电脑', '通过浏览器开发者工具导出 localStorage 内容\n或导出 JSON 后在新设备导入'],
    ['团队交接', '将 HTML 文件 + JSON 配置一起转交\n新 PM 通过"📂 导入 JSON 配置"恢复'],
    ['多人协作', '当前版本不支持云端同步\n属于单机工具'],
], [2400, 6960]));

body.push(h2('6.4 数据重置选项'));
body.push(buildTable([
    [
        { text: '按钮', header: true, align: 'center' },
        { text: '影响范围', header: true, align: 'center' },
        { text: '是否需要确认', header: true, align: 'center' },
    ],
    ['⟲ 恢复默认', '清空全部本地数据\n回到内置示例', '是（弹窗确认）'],
    ['📥 重新导入', '覆盖全部数据（含回收池）\n保留浏览器存储位置', '是（在最后导入步骤）'],
    ['浏览器清除缓存', '所有 localStorage 数据丢失', '由用户主动操作'],
], [2400, 4280, 2680]));

// ===== 第七章 FAQ =====
body.push(pageBreakXml());
body.push(h1('第七章 · 常见问题 FAQ'));

const faqs = [
    {
        q: 'Q1：打开后白屏怎么办？',
        a: [
            '请按以下顺序排查：',
            '① 检查是否联网（首次打开需加载 Vue / ECharts / Tesseract CDN）',
            '② 检查浏览器是否禁用了 JavaScript',
            '③ 按 F12 打开开发者工具，查看 Console 错误信息并反馈',
            '④ 尝试更换浏览器（推荐 Chrome 最新版）',
        ],
    },
    {
        q: 'Q2：OCR 识别失败或进度条卡住？',
        a: [
            '① 检查网络（首次需下载约 15MB 中文语言包）',
            '② 确认图片格式为 PNG / JPG / JPEG',
            '③ 复杂图片（手写、模糊、斜拍）建议改用「文本粘贴」方式',
            '④ 关闭浏览器其他大型标签页释放内存',
        ],
    },
    {
        q: 'Q3：刷新后数据丢失？',
        a: [
            '① 是否使用了「无痕/隐私模式」？无痕模式不会保留 localStorage',
            '② 是否清理过浏览器缓存或 Cookie？',
            '③ 是否切换了浏览器或电脑？localStorage 不跨设备共享',
        ],
    },
    {
        q: 'Q4：人员卡片显示位置错乱？',
        a: ['在组织架构图右上角工具栏点击「⟲ 80%」按钮，重置视图为默认 80%。或滚轮缩放后再次调整。'],
    },
    {
        q: 'Q5：怎么撤销刚才的删除操作？',
        a: [
            '打开右下「♻️ 人员回收池」，找到该人员条目，点击「恢复」按钮。',
            '系统会弹出二次确认，恢复后人员立即回到组织架构图。',
        ],
    },
    {
        q: 'Q6：归属类型导入后是空的？',
        a: [
            '这是产品设计——导入只识别「姓名 + 组别 + 角色」三项。',
            '归属类型（集团本部 / 实习生 / 子公司）请在主界面：',
            '① 双击人员卡片 → 弹出编辑窗口 → 修改"公司编制"',
            '② 或在添加成员时直接选择',
        ],
    },
    {
        q: 'Q7：能否多人协同编辑？',
        a: [
            '当前 v2.0 版本是单机工具，不支持云端协同。',
            '可通过 JSON 导出/导入实现异步交接：',
            '① A 同学操作完毕后导出 JSON',
            '② 通过邮件 / 企微发给 B 同学',
            '③ B 同学打开自己的工具，使用「📂 导入 JSON 配置」恢复',
        ],
    },
    {
        q: 'Q8：删除组长会影响什么？',
        a: [
            '直接删除组长会被系统拦截，提示"该成员是组长，请先更换组长后再删除"。',
            '请先：① 添加新成员或将其他组员任命为新组长 → ② 在组别管理中切换 leaderId → ③ 再删除原组长',
        ],
    },
    {
        q: 'Q9：预设离职日期已过，但人员没自动转移？',
        a: [
            '系统在以下时机扫描：① 页面加载；② 任何 增/改/删 操作后。',
            '如果工具长时间不操作，预设到期不会自动触发。',
            '解决方法：进行任意操作（如刷新页面或点击空白处），即可触发检测。',
        ],
    },
    {
        q: 'Q10：能修改默认的组别颜色吗？',
        a: [
            '可以。在「＋ 添加组别」时即可从 10 色调色板中选择。',
            '已有组别的颜色修改：当前版本暂未提供 UI 入口，建议通过 JSON 导出修改 groupColors 字段后重新导入。',
        ],
    },
];

faqs.forEach(faq => {
    body.push(h3(faq.q));
    faq.a.forEach(line => body.push(para(line)));
});

// ===== 第八章 =====
body.push(pageBreakXml());
body.push(h1('第八章 · 附录：文本格式速查表'));

body.push(h2('8.1 角色识别关键字'));
body.push(buildTable([
    [
        { text: '关键字（不区分大小写）', header: true, align: 'center' },
        { text: '识别为', header: true, align: 'center' },
        { text: '优先级', header: true, align: 'center' },
    ],
    ['总负责人 / 负责人 / UI 职能', '👑 总负责人', '最高'],
    ['UI PM / UIPM / PM / 产品经理', '📌 UI PM', '高'],
    ['组长 / Leader / Lead', '⭐ 组长', '中'],
    ['（其他人名）', '👤 组员', '默认'],
], [4080, 2680, 2600]));

body.push(h2('8.2 组别识别模式'));
body.push(buildTable([
    [
        { text: '写法示例', header: true, align: 'center' },
        { text: '是否识别', header: true, align: 'center' },
        { text: '建议', header: true, align: 'center' },
    ],
    ['A组：李四（组长）', '✅', '推荐用法'],
    ['A组', '✅', '可'],
    ['交互组 / 视觉组', '✅', '业务命名'],
    ['【设计组】 / [设计组]', '✅', '中括号亦可'],
    ['第一小组', '❌', '建议改为 "A组"'],
    ['Group-A', '❌', '建议改为 "A组"'],
], [3120, 2080, 4160]));

body.push(h2('8.3 推荐工作流（新 PM 上手 5 步）'));
body.push(numbered('打开 HTML，弹出向导后选择「📥 重新导入」'));
body.push(numbered('根据手头资料选择 OCR / 文本 / 对话 / JSON 任一入口'));
body.push(numbered('在统一预览页校对，重点核对组别名、姓名、角色'));
body.push(numbered('点击「✓ 确认导入」完成初始化'));
body.push(numbered('在主界面双击每位人员后补"公司编制"信息（导入时留空）'));

body.push(h2('8.4 业务规则约束总览'));
body.push(buildTable([
    [
        { text: '规则', header: true, align: 'center' },
        { text: '约束', header: true, align: 'center' },
    ],
    ['总负责人', '同时是某组组员，删除/编辑会同步更新组员表'],
    ['UI PM', '虚线连接到总负责人，不计入任何统计，可留空不显示'],
    ['组长', '由 group.leaderId 关联到 members 中某个成员'],
    ['组别', '至少保留 1 个，颜色可在添加时自由选择'],
    ['离职检测', '总负责人和组长不参与自动到期检测'],
    ['身份归属', '4 选 1，分别对应饼图 4 个色块'],
    ['数据持久化', 'localStorage 自动保存，无需手动操作'],
], [2400, 6960]));

// ===== 结尾页 =====
body.push(pageBreakXml());
body.push(paraXml(
    [{ text: '— 文档结束 —', bold: true, size: 28, color: '1E3A8A' }],
    { align: 'center', before: 1200, after: 200 }
));
body.push(paraXml(
    [{ text: '感谢使用 HIGAME · UI 人力架构图工具', size: 22, color: '475569' }],
    { align: 'center', before: 200, after: 200 }
));
body.push(paraXml(
    [{ text: 'Wishing your team management both efficient and elegant.', italic: true, size: 20, color: '94A3B8' }],
    { align: 'center', before: 100, after: 100 }
));
body.push(paraXml(
    [{ text: '版本：v2.0  |  发布日期：2026-05-25  |  内部资料', size: 18, color: '64748B' }],
    { align: 'center', before: 600, after: 100 }
));

// ========= 文档 XML 模板 =========
const documentXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
            xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
<w:body>
${body.join('\n')}
<w:sectPr>
    <w:pgSz w:w="12240" w:h="15840"/>
    <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
    <w:cols w:space="708"/>
    <w:docGrid w:linePitch="360"/>
</w:sectPr>
</w:body>
</w:document>`;

const stylesXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:docDefaults>
        <w:rPrDefault>
            <w:rPr>
                <w:rFonts w:ascii="${FONT}" w:hAnsi="${FONT}" w:eastAsia="${FONT}" w:cs="${FONT}"/>
                <w:sz w:val="22"/>
                <w:szCs w:val="22"/>
                <w:lang w:val="zh-CN" w:eastAsia="zh-CN" w:bidi="ar-SA"/>
            </w:rPr>
        </w:rPrDefault>
        <w:pPrDefault>
            <w:pPr>
                <w:spacing w:before="80" w:after="80" w:line="360" w:lineRule="auto"/>
            </w:pPr>
        </w:pPrDefault>
    </w:docDefaults>
    <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
        <w:name w:val="Normal"/>
        <w:qFormat/>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Heading1">
        <w:name w:val="heading 1"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:keepNext/>
            <w:keepLines/>
            <w:spacing w:before="360" w:after="200"/>
            <w:outlineLvl w:val="0"/>
        </w:pPr>
        <w:rPr>
            <w:b/>
            <w:bCs/>
            <w:color w:val="1E3A8A"/>
            <w:sz w:val="36"/>
            <w:szCs w:val="36"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Heading2">
        <w:name w:val="heading 2"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:keepNext/>
            <w:keepLines/>
            <w:spacing w:before="280" w:after="140"/>
            <w:outlineLvl w:val="1"/>
        </w:pPr>
        <w:rPr>
            <w:b/>
            <w:bCs/>
            <w:color w:val="1E40AF"/>
            <w:sz w:val="28"/>
            <w:szCs w:val="28"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Heading3">
        <w:name w:val="heading 3"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:keepNext/>
            <w:keepLines/>
            <w:spacing w:before="200" w:after="100"/>
            <w:outlineLvl w:val="2"/>
        </w:pPr>
        <w:rPr>
            <w:b/>
            <w:bCs/>
            <w:color w:val="334155"/>
            <w:sz w:val="24"/>
            <w:szCs w:val="24"/>
        </w:rPr>
    </w:style>
</w:styles>`;

const numberingXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:abstractNum w:abstractNumId="0">
        <w:lvl w:ilvl="0">
            <w:start w:val="1"/>
            <w:numFmt w:val="bullet"/>
            <w:lvlText w:val="•"/>
            <w:lvlJc w:val="left"/>
            <w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>
            <w:rPr><w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/></w:rPr>
        </w:lvl>
    </w:abstractNum>
    <w:abstractNum w:abstractNumId="1">
        <w:lvl w:ilvl="0">
            <w:start w:val="1"/>
            <w:numFmt w:val="decimal"/>
            <w:lvlText w:val="%1."/>
            <w:lvlJc w:val="left"/>
            <w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr>
        </w:lvl>
    </w:abstractNum>
    <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
    <w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>
</w:numbering>`;

const contentTypesXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
    <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
    <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
    <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
    <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>`;

const rootRelsXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
    <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>`;

const docRelsXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
</Relationships>`;

const coreXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                   xmlns:dc="http://purl.org/dc/elements/1.1/"
                   xmlns:dcterms="http://purl.org/dc/terms/"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <dc:title>HIGAME · UI 人力架构图工具 - 产品使用说明书</dc:title>
    <dc:creator>HIGAME UI Team</dc:creator>
    <cp:lastModifiedBy>HIGAME UI Team</cp:lastModifiedBy>
    <cp:revision>1</cp:revision>
    <dcterms:created xsi:type="dcterms:W3CDTF">2026-05-25T00:00:00Z</dcterms:created>
    <dcterms:modified xsi:type="dcterms:W3CDTF">2026-05-25T00:00:00Z</dcterms:modified>
</cp:coreProperties>`;

const appXml = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
            xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
    <Application>HIGAME UI Doc Generator</Application>
    <DocSecurity>0</DocSecurity>
    <Lines>1</Lines>
    <Paragraphs>1</Paragraphs>
    <ScaleCrop>false</ScaleCrop>
    <Company>HIGAME</Company>
    <LinksUpToDate>false</LinksUpToDate>
    <SharedDoc>false</SharedDoc>
    <HyperlinksChanged>false</HyperlinksChanged>
    <AppVersion>16.0000</AppVersion>
</Properties>`;

// ========= 打包 =========
const files = [
    { name: '[Content_Types].xml', content: contentTypesXml },
    { name: '_rels/.rels', content: rootRelsXml },
    { name: 'word/document.xml', content: documentXml },
    { name: 'word/styles.xml', content: stylesXml },
    { name: 'word/numbering.xml', content: numberingXml },
    { name: 'word/_rels/document.xml.rels', content: docRelsXml },
    { name: 'docProps/core.xml', content: coreXml },
    { name: 'docProps/app.xml', content: appXml },
];

const zipBuf = buildZip(files);
const outPath = path.join(__dirname, 'HIGAME-UI人力架构图工具-产品使用说明书-v2.0.docx');
fs.writeFileSync(outPath, zipBuf);
console.log('✅ 文档生成成功：' + outPath);
console.log('   文件大小：' + (zipBuf.length / 1024).toFixed(1) + ' KB');
console.log('   段落数：约 ' + body.length);