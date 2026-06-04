# ============================================================
# 修正版：
# 1) 删除上一版错误的 "1.3 AI 一键初始化" 段落（含其下三段）
# 2) 删除上一版错误的"七、附录·AI 初始化指南"整章
# 3) 把 "1.4 数据如何保存" 改回 "1.3 数据如何保存"
# 4) 重新插入正确版（组别/组长/组员都是可由用户/AI整理的）
# ============================================================
$ErrorActionPreference = "Stop"
$root    = "C:\Users\v_vinciye\Desktop\UI framework tool"
$build   = Join-Path $root ".tmp_edit"
$outDocx = Join-Path $root "下载说明书.docx"
$docPath = "$build\word\document.xml"

# 读入
$doc = [System.IO.File]::ReadAllText($docPath, [System.Text.UTF8Encoding]::new($false))

# ============================================================
# 工具函数（同上一版）
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
function Code([string]$text) {
    $lines = $text -split "`n"
    $sb = New-Object System.Text.StringBuilder
    foreach ($ln in $lines) {
        $t = X($ln.TrimEnd())
        $rPrCode = '<w:rPr><w:rFonts w:ascii="Consolas" w:eastAsia="Microsoft YaHei" w:hAnsi="Consolas" w:hint="eastAsia"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>'
        [void]$sb.Append("<w:p><w:pPr><w:pBdr><w:left w:val=`"single`" w:sz=`"24`" w:space=`"6`" w:color=`"BFBFBF`"/></w:pBdr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F5F5F7`"/><w:spacing w:before=`"0`" w:after=`"0`" w:line=`"260`" w:lineRule=`"auto`"/><w:ind w:left=`"160`" w:right=`"60`"/></w:pPr><w:r>$rPrCode<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>")
    }
    return $sb.ToString()
}
function Tbl {
    param([int[]]$ColWidthsDxa, [string[]]$Headers, [array]$Rows)
    $totalW = ($ColWidthsDxa | Measure-Object -Sum).Sum
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append("<w:tbl><w:tblPr><w:tblStyle w:val=`"TableGrid`"/><w:tblW w:w=`"$totalW`" w:type=`"dxa`"/><w:tblLook w:val=`"04A0`"/></w:tblPr><w:tblGrid>")
    foreach ($w in $ColWidthsDxa) { [void]$sb.Append("<w:gridCol w:w=`"$w`"/>") }
    [void]$sb.Append("</w:tblGrid>")
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
# 第①步：先把上一版错误内容剔除
# ============================================================

# 1. 把 "1.4 数据如何保存" 改回 "1.3 数据如何保存"
$doc = $doc.Replace('1.4 数据如何保存', '1.3 数据如何保存')

# 2. 删除从「1.3 AI 一键初始化（推荐）」标题段开始 → 直到「1.3 数据如何保存」之前的所有段落
#    使用正则跨行匹配
[regex]$reBlock1 = '(?s)<w:p>\s*<w:pPr>\s*<w:pStyle\s+w:val="2"\s*/>\s*</w:pPr>\s*<w:r>[^<]*<w:rPr[^>]*>.*?</w:rPr>\s*<w:t[^>]*>1\.3 AI 一键初始化（推荐）</w:t>.*?</w:p>(?=.*?<w:t[^>]*>1\.3 数据如何保存)'
# 上面这种 lookahead 不可靠，改用更直接的方式：找到两个锚点位置，删中间
$markerStart = '<w:t xml:space="preserve">1.3 AI 一键初始化（推荐）</w:t>'
$markerStartAlt = '<w:t>1.3 AI 一键初始化（推荐）</w:t>'
$markerEnd = '<w:t xml:space="preserve">1.3 数据如何保存</w:t>'
$markerEndAlt = '<w:t>1.3 数据如何保存</w:t>'

# 找到 1.3 AI 一键初始化 标题段的起点（向前回溯到 <w:p）
$idxStartText = $doc.IndexOf($markerStart)
if ($idxStartText -lt 0) { $idxStartText = $doc.IndexOf($markerStartAlt) }
if ($idxStartText -ge 0) {
    $idxStart_p1 = $doc.LastIndexOf('<w:p ', $idxStartText)
    $idxStart_p2 = $doc.LastIndexOf('<w:p>', $idxStartText)
    $idxStart = [Math]::Max($idxStart_p1, $idxStart_p2)
    
    # 找 1.3 数据如何保存 标题段的起点
    $idxEndText = $doc.IndexOf($markerEnd)
    if ($idxEndText -lt 0) { $idxEndText = $doc.IndexOf($markerEndAlt) }
    $idxEnd_p1 = $doc.LastIndexOf('<w:p ', $idxEndText)
    $idxEnd_p2 = $doc.LastIndexOf('<w:p>', $idxEndText)
    $idxEnd = [Math]::Max($idxEnd_p1, $idxEnd_p2)
    
    if ($idxEnd -gt $idxStart -and $idxStart -ge 0) {
        $doc = $doc.Substring(0, $idxStart) + $doc.Substring($idxEnd)
        Write-Host "已删除上一版 1.3 AI 一键初始化 段（$($idxEnd - $idxStart) 字节）"
    }
}

# 3. 删除「七、附录 · AI 初始化指南」整章 —— 从其前的 PageBreak（包含w:br type="page"）的整段开始 → 到 <w:sectPr 之前
$markerCh7 = '<w:t xml:space="preserve">七、附录 · AI 初始化指南</w:t>'
$markerCh7Alt = '<w:t>七、附录 · AI 初始化指南</w:t>'
$idxCh7Text = $doc.IndexOf($markerCh7)
if ($idxCh7Text -lt 0) { $idxCh7Text = $doc.IndexOf($markerCh7Alt) }
if ($idxCh7Text -ge 0) {
    # 向前找到包含分页符的 <w:p>（也就是这一章的起点）
    $idxCh7_p1 = $doc.LastIndexOf('<w:p ', $idxCh7Text)
    $idxCh7_p2 = $doc.LastIndexOf('<w:p>', $idxCh7Text)
    $idxCh7Title = [Math]::Max($idxCh7_p1, $idxCh7_p2)
    # 章节起点：再往前一段（PageBreak 段）
    $idxBefore_p1 = $doc.LastIndexOf('<w:p ', $idxCh7Title - 1)
    $idxBefore_p2 = $doc.LastIndexOf('<w:p>', $idxCh7Title - 1)
    $idxPageBreak = [Math]::Max($idxBefore_p1, $idxBefore_p2)
    # 检查这段是否真的含 w:br type="page"
    $maybeSect = $doc.IndexOf('<w:sectPr', $idxCh7Text)
    if ($maybeSect -gt 0) {
        # 检查 PageBreak 段是否含分页符
        $segCheck = $doc.Substring($idxPageBreak, $idxCh7Title - $idxPageBreak)
        if ($segCheck -match 'w:br[^>]*w:type="page"') {
            $doc = $doc.Substring(0, $idxPageBreak) + $doc.Substring($maybeSect)
            Write-Host "已删除上一版 七、附录 整章（含分页符）"
        } else {
            $doc = $doc.Substring(0, $idxCh7Title) + $doc.Substring($maybeSect)
            Write-Host "已删除上一版 七、附录 整章（无分页符）"
        }
    }
}

Write-Host "清理后 document.xml 长度：$($doc.Length)"

# ============================================================
# 第②步：构造新版正确内容
# ============================================================

# ----------- 快速上手 1.3 AI 一键初始化（推荐） —— 简短版 -----------
$block1 = (H2 "1.3 AI 一键初始化（推荐）") + `
    (P "如果你是首次接手团队、手头有图片名单 / Excel 表 / 文字清单，最快的方式不是手输——而是把素材丢给 AI（如 CodeBuddy / ChatGPT），让它直接产出工具能识别的完整团队架构数据。整个流程 3 步，1 分钟内完成初始化。") + `
    (Info "三步走：" "① 整理素材  →  ② 把素材+提示词丢给 AI  →  ③ 复制 AI 输出，粘到「重新导入 → JSON 配置导入」框中。") + `
    (P "AI 需要帮你整理 3 类信息：组别（组名）、组长、组员。每一项都是可由你自定义的，不存在写死的限制——每个团队的组架构、组长、人员都不一样，AI 会根据你的素材识别。") + `
    (P "完整的提示词模板、字段说明、3 种素材（图片 / 文字 / Excel）的使用示范，详见本文最后一章「七、附录 · AI 初始化指南」。")

# ----------- 七、附录 · AI 初始化指南 —— 修正版 -----------

$promptCommon = @"
你是一个数据整理助手。请把我提供的素材整理成"团队架构 JSON"，用于初始化人员架构图工具。

【需要输出的数据结构】
{
  "groups": [
    {
      "key": "组英文缩写（用于 id 前缀，如 inter / visual / refactor / motion）",
      "name": "组中文名（如 交互 / 视觉 / 重构 / 动效）",
      "leader": "组长中文姓名",
      "leaderEnName": "组长英文名（无则用拼音）",
      "leaderAffiliation": "组长身份（4 选 1，见下方说明）"
    }
  ],
  "members": [
    {
      "id": "唯一编号，建议 m_{组key}_{两位序号}，如 m_inter_01",
      "name": "中文姓名",
      "enName": "英文名（无则用拼音）",
      "group": "对应 groups[].key",
      "affiliation": "成员身份（4 选 1）"
    }
  ]
}

【affiliation 字段固定 4 选 1】（这是工具内置的统计标签，请严格使用）
- group-formal  = 集团本部正式
- group-intern  = 集团实习生
- sub-formal    = 子公司正式
- sub-intern    = 子公司实习生

【输出要求】
1. 输出严格的 JSON：所有 key 加双引号、字符串用双引号、最后一项不加逗号、无注释。
2. groups 中包含所有组（不限数量，按素材识别 1~N 个组）。
3. members 中"不要包含组长"——组长信息已经写在 groups 里，重复会被工具去重。
4. 没有英文名时，enName / leaderEnName 用全小写拼音填充，无空格。
5. 素材中找不到身份信息时，默认 sub-formal（子公司正式）。

------- 以下是我的素材 -------
"@

$promptImage = @"
素材类型：图片。
请你 OCR 识别图片中所有文字，识别出每个组的"组名 + 组长 + 组员"，
按上述 JSON 结构输出。如果图中标注"组长 / Leader / 负责人"，请把该人员放入 groups[].leader 字段，
不要重复出现在 members 中。
"@

$promptText = @"
素材类型：纯文字名单。
文字可能用空格、换行、顿号、斜杠分隔。请识别每个组的组长和组员。
组长一般会被标注为"组长/负责人/Leader"，或者出现在每个组的第一个位置。
"@

$promptExcel = @"
素材类型：Excel 表格（粘贴在下方，制表符分隔的纯文本）。
请按列含义自动映射：
- "组别"列 → groups[].name；同名归为一组。
- "中文名 / 姓名"列 → name 或 leader。
- "英文名"列 → enName 或 leaderEnName；无则用拼音。
- "身份"列：集团本部→group-formal, 集团实习生→group-intern,
  子公司→sub-formal, 子公司实习生→sub-intern。
- "角色"列：组长 → 写入 groups[].leader，其他人 → 写入 members。
- 缺失"角色"列时，默认每个组的第一行人员为组长。
"@

$exampleOutput = @"
{
  "groups": [
    {
      "key": "interaction",
      "name": "交互",
      "leader": "潘佳绮",
      "leaderEnName": "panjiaqi",
      "leaderAffiliation": "group-formal"
    },
    {
      "key": "visual",
      "name": "视觉",
      "leader": "蒋晓舒",
      "leaderEnName": "jiangxiaoshu",
      "leaderAffiliation": "group-formal"
    },
    {
      "key": "refactor",
      "name": "重构",
      "leader": "魏霓丽",
      "leaderEnName": "weinili",
      "leaderAffiliation": "sub-formal"
    },
    {
      "key": "motion",
      "name": "动效",
      "leader": "杨沫",
      "leaderEnName": "yangmo",
      "leaderAffiliation": "sub-formal"
    }
  ],
  "members": [
    { "id": "m_inter_01", "name": "曼波",     "enName": "manbo",   "group": "interaction", "affiliation": "group-formal" },
    { "id": "m_inter_02", "name": "鸡你太美", "enName": "jntm",    "group": "interaction", "affiliation": "group-intern" },
    { "id": "m_visual_01","name": "阿尔法",   "enName": "alpha",   "group": "visual",      "affiliation": "group-formal" },
    { "id": "m_refactor_01","name": "大鹅",   "enName": "bigegg",  "group": "refactor",    "affiliation": "sub-formal" },
    { "id": "m_motion_01","name": "多普多普", "enName": "dopdop",  "group": "motion",      "affiliation": "sub-formal" }
  ]
}
"@

$quickPrompt = @"
帮我整理成团队架构 JSON（含 groups 和 members 两块，按《下载说明书》第七章规则）。素材如下：
[贴上你的图片 / 文字 / Excel]
"@

# 构造 block2：从分页符开始
$block2 = ""
$block2 += '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
$block2 += H1 "七、附录 · AI 初始化指南"
$block2 += P "本章解决一个高频痛点：首次接手团队，手头有几十号人的名单 / 截图 / Excel 表，如何最快导入工具？答案是借助 AI（CodeBuddy / ChatGPT）一键转换。本章给你一份『复制即用』的完整流程。"

# 7.1 哪些数据需要整理
$block2 += H2 "7.1 哪些数据需要 AI 帮你整理？"
$block2 += P "工具内的数据由 3 类组成。每个团队的实际情况都不同——有的是 4 个组、有的是 6 个组；组长可能是 A 也可能是 B；成员人数从十几到几十不等。所以这 3 类信息全部都需要 AI 根据你的素材整理出来，不存在写死的限制。"
$block2 += Tbl -ColWidthsDxa @(1800,2000,5560) -Headers @("数据类别","可否自定义","说明") -Rows @(
    @("① 组别（组名）","完全自定义","你的团队有几个组、叫什么名字，全部由 AI 根据素材识别（如：交互、视觉、重构、动效，或其它）"),
    @("② 组长 + 组长身份","完全自定义","每个组的组长姓名、英文名、身份标签，AI 都会根据素材填入"),
    @("③ 组员（含中英文名 + 身份）","完全自定义","每个组下的成员列表，AI 整理后即可批量导入")
)

$block2 += H3 "唯一固定的：4 个身份标签（affiliation）"
$block2 += P "用于颜色区分和顶部数字看板统计，固定 4 个值，请严格使用："
$block2 += Tbl -ColWidthsDxa @(2400,2200,4760) -Headers @("affiliation 取值","对应身份","用在哪") -Rows @(
    @("group-formal","集团本部（正式）","组长 + 组员都可使用"),
    @("group-intern","集团实习生","通常用于组员"),
    @("sub-formal","子公司（正式）","组长 + 组员都可使用"),
    @("sub-intern","子公司实习生","通常用于组员")
)

# 7.2 三步走
$block2 += H2 "7.2 三步走流程"
$block2 += NLI "整理素材：把团队的"组、组长、组员"信息收集到一起（图片/文字/Excel 都可以）。"
$block2 += NLI "把『通用前缀提示词』+『素材类型补充提示词』+『你的素材』一起发给 AI。"
$block2 += NLI "复制 AI 输出的 JSON，按 7.5 节方式应用到工具。"

# 7.3 通用前缀
$block2 += H2 "7.3 通用前缀提示词（任何素材都先粘这段）"
$block2 += Code $promptCommon

# 7.4 三种素材
$block2 += H2 "7.4 按素材类型 · 补充提示词"

$block2 += H3 "场景 A · 图片素材（截图 / 名单照片 / Figma）"
$block2 += P "把图片连同通用前缀一起发给 AI，并补一句："
$block2 += Code $promptImage
$block2 += Info "提示：" "CodeBuddy 支持直接拖拽 / 粘贴图片识别。如果用 ChatGPT，请使用支持视觉的模型（如 GPT-4o）。"

$block2 += H3 "场景 B · 纯文字（聊天记录 / Word 复制 / 企微名单）"
$block2 += P "通用前缀 + 你的文字 + 补一句："
$block2 += Code $promptText
$block2 += P "示范输入（你只需要这样写，组长在第一位）："
$block2 += Code @"
交互组（组长：潘佳绮）：曼波、哦吗吉利、小黑子、鸡你太美（实习生）
视觉组（组长：蒋晓舒）：阿尔法、欧米伽、嘎子哥、奥利给
重构组（组长：魏霓丽）：大鹅、小狗、小猪、小马
动效组（组长：杨沫）：多普多普、油哒哒哒
"@

$block2 += H3 "场景 C · Excel 表格"
$block2 += P "推荐用以下表头格式整理 Excel（列名中英文均可）："
$block2 += Tbl -ColWidthsDxa @(1700,1700,1700,1700,2560) -Headers @("中文名","英文名","组别","角色","身份") -Rows @(
    @("潘佳绮","panjiaqi","交互","组长","集团本部"),
    @("曼波","manbo","交互","组员","集团本部"),
    @("鸡你太美","jntm","交互","组员","集团实习生"),
    @("蒋晓舒","jiangxiaoshu","视觉","组长","集团本部"),
    @("阿尔法","alpha","视觉","组员","集团本部"),
    @("魏霓丽","weinili","重构","组长","子公司"),
    @("大鹅","bigegg","重构","组员","子公司"),
    @("杨沫","yangmo","动效","组长","子公司"),
    @("多普多普","dopdop","动效","组员","子公司")
)
$block2 += P "粘贴到 AI 对话框前补一句："
$block2 += Code $promptExcel
$block2 += Info "复制方法：" "在 Excel 里选中区域 → Ctrl+C → 直接粘贴到 AI 对话框，会自动转换为制表符分隔文本，AI 能完整识别。"

# 7.5 应用到工具
$block2 += H2 "7.5 把 AI 输出应用到工具"
$block2 += H3 "姿势 ① · 网页内『JSON 配置导入』（推荐 PM / 非开发者）"
$block2 += NLI "确认 AI 输出的是标准 JSON（key 加双引号、无注释、无尾逗号、含 groups 和 members 两块）。"
$block2 += NLI "复制全部 JSON。"
$block2 += NLI "网页顶部「重新导入」 → 「JSON 配置导入」 → 粘贴 → 确认覆盖。"
$block2 += NLI "页面自动刷新架构图与扇形图。"

$block2 += H3 "姿势 ② · 修改源码（一次性永久初始值，开发者使用）"
$block2 += NLI "把 AI 输出 JSON 的 groups 数据 → 改写到 src/config/fixedStructure.js 的 GROUPS 数组（保留 color 字段不变）。"
$block2 += NLI "把 AI 输出 JSON 的 members 数据 → 改写到 src/data/mockMembers.js 的 INITIAL_MEMBERS 数组。"
$block2 += NLI "保存 → F12 → Application → Local Storage → 清除对应站点的缓存（重要）。"
$block2 += NLI "刷新页面，新数据生效。"

# 7.6 输出示例
$block2 += H2 "7.6 AI 输出示例（你应该收到这种格式）"
$block2 += Code $exampleOutput

# 7.7 常见踩坑
$block2 += H2 "7.7 常见踩坑 & 排查"
$block2 += Tbl -ColWidthsDxa @(2800,3200,3360) -Headers @("现象","原因","解决方法") -Rows @(
    @("身份标签颜色错乱","affiliation 拼写错误","必须是 4 个固定值（group-formal 等），不能自创"),
    @("组长重复显示","members 中也包含了组长","让 AI 重输：组长只放在 groups[].leader 字段"),
    @("组员显示不全","id 重复","让 AI 重新编号，确保每条 id 唯一"),
    @("JSON 导入报语法错","AI 输出了 JS 而非 JSON","让 AI 重输：双引号 key、无注释、无尾逗号"),
    @("改了源码但页面无变化","浏览器 localStorage 缓存未清","F12 清除该站点的 localStorage 后刷新"),
    @("某组完全消失","groups 缺该项 / key 拼错","核对 groups 中 key 与 members[].group 必须一致")
)

# 7.8 一句话快捷指令
$block2 += H2 "7.8 给 AI 的『一句话快捷指令』（熟练后用这个）"
$block2 += P "如果已经熟悉流程，下次只需发："
$block2 += Code $quickPrompt
$block2 += Info "再次提醒：" "AI 整理的是『团队架构数据』本身，包括组别、组长、组员——这些都由你的素材决定，工具不会写死任何组名 / 组长。AI 唯一需要严格遵守的是 affiliation 字段的 4 个枚举值。"

# ============================================================
# 第③步：插入到 document.xml
# ============================================================

# 在 "1.3 数据如何保存" 之前插入新版 1.3 AI 一键初始化
$marker13 = '<w:t xml:space="preserve">1.3 数据如何保存</w:t>'
if ($doc -notmatch [regex]::Escape($marker13)) {
    $marker13 = '<w:t>1.3 数据如何保存</w:t>'
}
$idx13 = $doc.IndexOf($marker13)
if ($idx13 -lt 0) {
    Write-Error "找不到 1.3 数据如何保存"
    exit 1
}
$idx13_p1 = $doc.LastIndexOf('<w:p ', $idx13)
$idx13_p2 = $doc.LastIndexOf('<w:p>', $idx13)
$idx13_p = [Math]::Max($idx13_p1, $idx13_p2)
$doc = $doc.Substring(0, $idx13_p) + $block1 + $doc.Substring($idx13_p)
Write-Host "已在 1.3 数据如何保存 之前插入新版 1.3 AI 一键初始化"

# 在 <w:sectPr 之前追加 七、附录
$idxSect = $doc.IndexOf('<w:sectPr')
if ($idxSect -lt 0) { Write-Error "找不到 sectPr"; exit 1 }
$doc = $doc.Substring(0, $idxSect) + $block2 + $doc.Substring($idxSect)
Write-Host "已在文末追加新版 七、附录"

# 写回
[System.IO.File]::WriteAllText($docPath, $doc, [System.Text.UTF8Encoding]::new($false))
Write-Host "document.xml 最终长度：$((Get-Item $docPath).Length)"

# ============================================================
# 重新打包
# ============================================================
if (Test-Path $outDocx) { Remove-Item $outDocx -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($build, $outDocx, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Write-Host ""
Write-Host "========================================"
Write-Host "  生成成功：$outDocx"
Write-Host "  大小：$([math]::Round((Get-Item $outDocx).Length/1KB, 1)) KB"
Write-Host "========================================"

Remove-Item $build -Recurse -Force -ErrorAction SilentlyContinue
