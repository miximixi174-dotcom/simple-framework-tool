# ============================================================
# 在已有 docx 上追加：
#   · 快速上手新增 1.3 AI 一键初始化（推荐）  → 原 1.3 顺延为 1.4
#   · 末尾新增 七、附录 · AI 初始化指南（含完整提示词模板）
# 不重建文档，只插入段落，保留你之前所有微调
# ============================================================
$ErrorActionPreference = "Stop"
$root = "C:\Users\v_vinciye\Desktop\UI framework tool"
$srcDocx = Join-Path $root "下载说明书.docx"
$build   = Join-Path $root ".tmp_edit"
$outDocx = Join-Path $root "下载说明书.docx"

# 1. 解压（之前已解压到 .tmp_edit，保险起见再处理一次）
if (-not (Test-Path "$build\word\document.xml")) {
    if (Test-Path $build) { Remove-Item $build -Recurse -Force }
    New-Item -ItemType Directory -Path $build | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($srcDocx, $build)
}

$docPath = "$build\word\document.xml"
$doc = [System.IO.File]::ReadAllText($docPath, [System.Text.UTF8Encoding]::new($false))

# ============================================================
# 公共：构造段落 / 列表 / 信息框
# ============================================================
function X([string]$s) { return $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' }

$rPrCN = '<w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/></w:rPr>'

function PStyle([string]$style, [string]$text) {
    $t = X $text
    return "<w:p><w:pPr><w:pStyle w:val=`"$style`"/></w:pPr><w:r>$rPrCN<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}
function P([string]$text) {
    $t = X $text
    return "<w:p><w:r>$rPrCN<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}
function H1([string]$text) { return PStyle "1" $text }
function H2([string]$text) { return PStyle "2" $text }
function H3([string]$text) { return PStyle "3" $text }
function LI([string]$text) {
    $t = X $text
    return "<w:p><w:pPr><w:pStyle w:val=`"a5`"/><w:numPr><w:ilvl w:val=`"0`"/><w:numId w:val=`"1`"/></w:numPr></w:pPr><w:r>$rPrCN<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}
function NLI([string]$text) {
    $t = X $text
    return "<w:p><w:pPr><w:pStyle w:val=`"a5`"/><w:numPr><w:ilvl w:val=`"0`"/><w:numId w:val=`"2`"/></w:numPr></w:pPr><w:r>$rPrCN<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}
function Info([string]$title, [string]$body) {
    $t1 = X $title; $t2 = X $body
    $rPr1 = '<w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/><w:b/><w:bCs/><w:color w:val="0052D9"/></w:rPr>'
    return "<w:p><w:pPr><w:pStyle w:val=`"InfoBox`"/></w:pPr><w:r>$rPr1<w:t xml:space=`"preserve`">$t1</w:t></w:r><w:r>$rPrCN<w:t xml:space=`"preserve`">$t2</w:t></w:r></w:p>"
}
# 代码块（等宽字体 + 浅灰底）—— 给提示词用
function Code([string]$text) {
    # 多行：按行拆分，每行一个段落
    $lines = $text -split "`n"
    $sb = New-Object System.Text.StringBuilder
    foreach ($ln in $lines) {
        $t = X($ln.TrimEnd())
        $rPrCode = '<w:rPr><w:rFonts w:ascii="Consolas" w:eastAsia="Microsoft YaHei" w:hAnsi="Consolas" w:hint="eastAsia"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>'
        [void]$sb.Append("<w:p><w:pPr><w:pBdr><w:left w:val=`"single`" w:sz=`"24`" w:space=`"6`" w:color=`"BFBFBF`"/></w:pBdr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F5F5F7`"/><w:spacing w:before=`"0`" w:after=`"0`" w:line=`"260`" w:lineRule=`"auto`"/><w:ind w:left=`"160`" w:right=`"60`"/></w:pPr><w:r>$rPrCode<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>")
    }
    return $sb.ToString()
}
# 表格（等宽 + 表头蓝 + 偶数行浅）
function Tbl {
    param([int[]]$ColWidthsDxa, [string[]]$Headers, [array]$Rows)
    $totalW = ($ColWidthsDxa | Measure-Object -Sum).Sum
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<w:tbl><w:tblPr><w:tblStyle w:val=`"TableGrid`"/><w:tblW w:w=`"$totalW`" w:type=`"dxa`"/><w:tblLook w:val=`"04A0`"/></w:tblPr><w:tblGrid>")
    foreach ($w in $ColWidthsDxa) { [void]$sb.Append("<w:gridCol w:w=`"$w`"/>") }
    [void]$sb.Append("</w:tblGrid>")
    # 表头
    [void]$sb.Append("<w:tr><w:trPr><w:tblHeader/></w:trPr>")
    for ($i=0; $i -lt $Headers.Count; $i++) {
        $w = $ColWidthsDxa[$i]
        $h = X $Headers[$i]
        [void]$sb.Append("<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"0052D9`"/><w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:before=`"60`" w:after=`"60`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Microsoft YaHei`" w:eastAsia=`"Microsoft YaHei`" w:hAnsi=`"Microsoft YaHei`" w:hint=`"eastAsia`"/><w:b/><w:color w:val=`"FFFFFF`"/></w:rPr><w:t>$h</w:t></w:r></w:p></w:tc>")
    }
    [void]$sb.Append("</w:tr>")
    $rowIdx = 0
    foreach ($row in $Rows) {
        $rowIdx++
        [void]$sb.Append("<w:tr>")
        for ($i=0; $i -lt $row.Count; $i++) {
            $w = $ColWidthsDxa[$i]
            $t = X([string]$row[$i])
            $shadeXml = ""
            if (($rowIdx % 2) -eq 0) { $shadeXml = '<w:shd w:val="clear" w:color="auto" w:fill="F7F9FC"/>' }
            [void]$sb.Append("<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/>$shadeXml<w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:before=`"60`" w:after=`"60`"/></w:pPr><w:r>$rPrCN<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p></w:tc>")
        }
        [void]$sb.Append("</w:tr>")
    }
    [void]$sb.Append("</w:tbl><w:p/>")
    return $sb.ToString()
}

# ============================================================
# 内容块 1：快速上手 - 新增 1.3 AI 一键初始化
# ============================================================
$block1 = (H2 "1.3 AI 一键初始化（推荐）") + `
    (P "如果你是首次接手团队、手头有现成的图片名单 / Excel 表 / 文字清单，最快的方式不是手输——而是把素材丢给 AI（如 CodeBuddy / ChatGPT），让它直接产出工具能识别的成员数组。整个流程 3 步，1 分钟内完成初始化。") + `
    (Info "三步走：" "① 整理素材  →  ② 把素材+提示词丢给 AI  →  ③ 复制 AI 输出，粘到「重新导入 → JSON 配置导入」框中。") + `
    (P "工具的「组别」和「组长」属于固定骨架（交互 / 视觉 / 重构 / 动效 4 个组，组长锁定），AI 只需要帮你整理「组员列表」，每个组员需要 5 个字段：id、中文名、英文名、所属组、身份。") + `
    (P "完整的提示词模板、字段取值表、3 种素材（图片 / 文字 / Excel）的使用示范，详见本文最后一章「七、附录 · AI 初始化指南」。")

# ============================================================
# 内容块 2：文末追加「七、附录 · AI 初始化指南」
# ============================================================
$promptCommon = @"
你是一个数据整理助手。请把我提供的素材整理成 JS 数组，用于初始化人员架构图工具。

【输出要求】
1. 直接输出可粘贴的 JS 代码，从 export const INITIAL_MEMBERS = [ 开始。
2. 每个成员包含 5 个字段：id, name, enName, group, affiliation。
3. id 命名：m_{组英文缩写}_{两位序号}，如 m_inter_01 / m_visual_03。
4. group 只能是：interaction(交互) / visual(视觉) / refactor(重构) / motion(动效)。
5. affiliation 只能是：group-formal(集团本部) / group-intern(集团实习生) /
   sub-formal(子公司) / sub-intern(子公司实习生)。
6. 没有英文名时，用拼音代替（全小写、无空格）。
7. 不要包含组长（组长是锁定骨架），只输出组员。
8. 注释里按组分块，方便我核对人数。

【骨架人员，请勿在结果中输出，仅供你判断"哪些是组员"】
- 交互组组长：潘佳绮
- 视觉组组长：蒋晓舒
- 重构组组长：魏霓丽
- 动效组组长：杨沫
- PM：赵晨杨

------- 以下是我的素材 -------
"@

$promptImage = @"
素材类型：图片。
请 OCR 识别图中所有姓名，并按图中分组关系归类到 4 个组里。
若图中标注"实习生"或"子公司"，请映射到对应 affiliation；
未标注的默认 sub-formal（子公司正式）。
"@

$promptText = @"
素材类型：纯文字名单。
文字可能用空格、换行、顿号、斜杠分隔。
请识别每个人所属组别，未标注组别的成员请放到末尾用 // TODO 注释列出，
等我手动确认。
"@

$promptExcel = @"
素材类型：Excel 表格（粘贴在下方，制表符分隔的纯文本）。
请按列含义自动映射：
- "组别"列：交互→interaction, 视觉→visual, 重构→refactor, 动效→motion
- "身份"列：集团本部→group-formal, 集团实习生→group-intern,
  子公司→sub-formal, 子公司实习生→sub-intern
- 缺失"英文名"列：自动用拼音填充
- 缺失"身份"列：默认 sub-formal
"@

$promptJson = @"
（如要走「JSON 配置导入」入口，请额外加一句）
请输出标准 JSON 数组（key 加双引号、结尾不能有逗号、无 export 无注释），
方便我直接复制到导入框。
"@

$exampleOutput = @"
export const INITIAL_MEMBERS = [
  // ============ 交互组 ============
  { id: 'm_inter_01', name: '曼波',     enName: 'manbo',   group: 'interaction', affiliation: 'group-formal' },
  { id: 'm_inter_02', name: '哦吗吉利', enName: 'omagiri', group: 'interaction', affiliation: 'sub-formal' },
  { id: 'm_inter_03', name: '鸡你太美', enName: 'jntm',    group: 'interaction', affiliation: 'group-intern' },

  // ============ 视觉组 ============
  { id: 'm_visual_01', name: '阿尔法',  enName: 'alpha',   group: 'visual', affiliation: 'group-formal' },

  // ============ 重构组 ============
  { id: 'm_refactor_01', name: '大鹅',  enName: 'bigegg',  group: 'refactor', affiliation: 'sub-formal' },

  // ============ 动效组 ============
  { id: 'm_motion_01', name: '多普多普', enName: 'dopdop', group: 'motion', affiliation: 'sub-formal' }
]
"@

$block2 = ""
# 章首
$block2 += '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
$block2 += H1 "七、附录 · AI 初始化指南"
$block2 += P "本章解决一个高频痛点：首次接手团队，手头有几十号人的名单 / 截图 / Excel 表，如何最快导入工具？答案是借助 AI（CodeBuddy / ChatGPT）一键转换。本章给你一份『复制即用』的完整流程。"

# 7.1 哪些数据可以被初始化
$block2 += H2 "7.1 哪些数据可以被初始化？"
$block2 += P "工具内的数据分两层："
$block2 += Tbl -ColWidthsDxa @(2400,1800,5160) -Headers @("数据类型","是否可初始化","说明") -Rows @(
    @("骨架（根节点 / 4 个组 / 组长 / PM）","锁定不可改","已写入源码 fixedStructure.js，固定为：交互、视觉、重构、动效 4 组，组长固定"),
    @("组员列表（每个组下的人员）","可批量初始化","写入源码 mockMembers.js，本章 AI 流程要做的就是这部分")
)
$block2 += P "也就是说：「初始化」= 让 AI 帮你把素材整理成「组员数组」。每位组员只需要 5 个字段："
$block2 += Tbl -ColWidthsDxa @(2200,2400,4760) -Headers @("字段","必填","说明 / 示例") -Rows @(
    @("id","是","唯一编号，建议 m_{组缩写}_{序号}，例：m_inter_01"),
    @("name","是","中文名，例：曼波"),
    @("enName","是","英文名 / 拼音，例：manbo"),
    @("group","是","只能是 4 个固定值之一（见下表）"),
    @("affiliation","是","只能是 4 个固定值之一（见下表）")
)

$block2 += H3 "字段取值速查"
$block2 += Tbl -ColWidthsDxa @(2400,6960) -Headers @("group 取值","对应组别") -Rows @(
    @("interaction","交互组"),
    @("visual","视觉组"),
    @("refactor","重构组"),
    @("motion","动效组")
)
$block2 += Tbl -ColWidthsDxa @(2400,6960) -Headers @("affiliation 取值","对应身份") -Rows @(
    @("group-formal","集团本部（正式）"),
    @("group-intern","集团实习生"),
    @("sub-formal","子公司（正式）"),
    @("sub-intern","子公司实习生")
)

# 7.2 三步走流程
$block2 += H2 "7.2 三步走流程"
$block2 += NLI "整理素材：把要导入的人员列出来（任意格式：图片、文字、Excel 都可以）。"
$block2 += NLI "把『通用前缀提示词』+『素材类型补充提示词』+『你的素材』丢给 AI。"
$block2 += NLI "复制 AI 输出的成员数组，按下面 7.5 节的方式应用到工具中。"

# 7.3 通用前缀提示词
$block2 += H2 "7.3 通用前缀提示词（任何素材都先粘这段）"
$block2 += Code $promptCommon

# 7.4 三种素材的补充提示词
$block2 += H2 "7.4 按素材类型 · 补充提示词"

$block2 += H3 "场景 A · 图片素材（截图 / 名单照片 / Figma）"
$block2 += P "把图片连同通用前缀一起发给 AI，并补一句："
$block2 += Code $promptImage
$block2 += Info "提示：" "CodeBuddy 支持直接拖拽 / 粘贴图片识别。如果用 ChatGPT，请使用支持视觉的模型（如 GPT-4o）。"

$block2 += H3 "场景 B · 纯文字（聊天记录 / Word 复制 / 企微名单）"
$block2 += P "通用前缀 + 你的文字 + 补一句："
$block2 += Code $promptText
$block2 += P "示范输入（你只需要这样写）："
$block2 += Code @"
交互组：曼波、哦吗吉利、小黑子、鸡你太美（实习生）
视觉组：阿尔法、欧米伽、嘎子哥、奥利给、耶斯莫拉、栓Q、退退退
重构组：大鹅、小狗、小猪、小马、大鸭子
动效组：多普多普、油哒哒哒
"@

$block2 += H3 "场景 C · Excel 表格"
$block2 += P "推荐用以下表头格式整理 Excel（列名中英文均可）："
$block2 += Tbl -ColWidthsDxa @(2200,2200,2200,2760) -Headers @("中文名","英文名","组别","身份") -Rows @(
    @("曼波","manbo","交互","集团本部"),
    @("鸡你太美","jntm","交互","集团实习生"),
    @("阿尔法","alpha","视觉","集团本部"),
    @("欧米伽","omega","视觉","子公司"),
    @("大鹅","bigegg","重构","子公司"),
    @("多普多普","dopdop","动效","子公司")
)
$block2 += P "粘贴到 AI 对话框前补一句："
$block2 += Code $promptExcel
$block2 += Info "复制方法：" "在 Excel 里选中区域 → Ctrl+C → 直接粘贴到 AI 对话框。会自动转换为制表符分隔文本，AI 能完整识别。"

# 7.5 应用到网页
$block2 += H2 "7.5 把 AI 输出应用到工具的两种姿势"
$block2 += H3 "姿势 ① · 网页内『JSON 配置导入』（推荐 PM / 非开发者）"
$block2 += P "在通用前缀末尾追加这段，让 AI 输出标准 JSON："
$block2 += Code $promptJson
$block2 += P "然后："
$block2 += NLI "复制 AI 输出的 JSON。"
$block2 += NLI "网页顶部「重新导入」 → 「JSON 配置导入」 → 粘贴 → 确认覆盖。"

$block2 += H3 "姿势 ② · 修改源码（一次性永久初始值）"
$block2 += P "适合开发者把数据写死作为默认初始值："
$block2 += NLI "打开 src/data/mockMembers.js。"
$block2 += NLI "用 AI 输出的整段 JS 代码替换原来的 INITIAL_MEMBERS 数组。"
$block2 += NLI "保存 → 浏览器 F12 → Application → Local Storage → 清空对应站点缓存。"
$block2 += NLI "刷新即可看到新初始数据生效。"

# 7.6 AI 输出示例
$block2 += H2 "7.6 AI 输出示例（你应该收到这种格式）"
$block2 += Code $exampleOutput

# 7.7 常见踩坑
$block2 += H2 "7.7 常见踩坑 & 排查"
$block2 += Tbl -ColWidthsDxa @(2800,3200,3360) -Headers @("现象","原因","解决方法") -Rows @(
    @("组员显示不全","id 重复","让 AI 重新编号，确保每条 id 唯一"),
    @("身份标签颜色错乱","affiliation 拼写错误","必须是 4 个固定 key，不能自创"),
    @("改了源码但页面无变化","浏览器缓存未清","清除对应站点的 localStorage 后刷新"),
    @("组长出现在组员列表","AI 没排除骨架人员","提示词里强调『不要包含组长』"),
    @("组别显示『未知』","group 字段写了中文","必须用 4 个英文 key（interaction 等）"),
    @("JSON 导入报语法错","AI 输出了 JS 不是 JSON","让 AI 重输：双引号、无 export、无注释、无尾逗号")
)

# 7.8 一句话快捷指令
$block2 += H2 "7.8 给 AI 的『一句话快捷指令』（熟练后用这个）"
$block2 += P "如果已经熟悉流程，下次只需发："
$block2 += Code @"
帮我整理成 INITIAL_MEMBERS 数组，规则参照《下载说明书》第七章。素材如下：
[贴上你的图片 / 文字 / Excel]
"@
$block2 += Info "再次提醒：" "AI 永远不需要也不能动『骨架』（4 个组、组长、PM）。它只产出『组员列表』。"

# ============================================================
# 插入到 document.xml 中
# ============================================================
# 第①步：把 1.3 块插到原 "1.3 数据如何保存" 之前
# 原 H2: <w:p><w:pPr><w:pStyle w:val="2"/></w:pPr> ... <w:t>1.3 数据如何保存</w:t> ...
$marker13 = '<w:t xml:space="preserve">1.3 数据如何保存</w:t>'
if ($doc -notmatch [regex]::Escape($marker13)) {
    $marker13b = '<w:t>1.3 数据如何保存</w:t>'
    if ($doc -notmatch [regex]::Escape($marker13b)) {
        Write-Error "找不到 1.3 数据如何保存 标记，请检查 document.xml"
        exit 1
    }
    $marker13 = $marker13b
}
# 找到包含该标记的整个 <w:p>...</w:p>
$idxText = $doc.IndexOf($marker13)
$idxPStart = $doc.LastIndexOf('<w:p ', $idxText)
$idxPStartAlt = $doc.LastIndexOf('<w:p>', $idxText)
if ($idxPStartAlt -gt $idxPStart) { $idxPStart = $idxPStartAlt }
# 把 "1.3 数据如何保存" 改名为 "1.4 数据如何保存"
$doc = $doc.Replace($marker13, $marker13.Replace('1.3 数据如何保存','1.4 数据如何保存'))

# 在该段落 <w:p> 之前插入新块
$doc = $doc.Substring(0, $idxPStart) + $block1 + $doc.Substring($idxPStart)

# 第②步：把 block2 追加到文档末尾，紧贴 <w:sectPr> 之前
$idxSect = $doc.IndexOf('<w:sectPr')
if ($idxSect -lt 0) {
    Write-Error "找不到 sectPr，无法定位文档末尾"
    exit 1
}
$doc = $doc.Substring(0, $idxSect) + $block2 + $doc.Substring($idxSect)

# 写回
[System.IO.File]::WriteAllText($docPath, $doc, [System.Text.UTF8Encoding]::new($false))
Write-Host "document.xml updated, new size: $((Get-Item $docPath).Length) bytes"

# ============================================================
# 重新打包为 docx
# ============================================================
if (Test-Path $outDocx) { Remove-Item $outDocx -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($build, $outDocx, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Write-Host ""
Write-Host "========================================"
Write-Host "  生成成功：$outDocx"
Write-Host "  大小：$([math]::Round((Get-Item $outDocx).Length/1KB, 1)) KB"
Write-Host "========================================"

# 清理临时目录
Remove-Item $build -Recurse -Force -ErrorAction SilentlyContinue
