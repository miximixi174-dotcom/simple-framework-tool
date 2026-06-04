# ============================================================
# 生成 HIGAME · UI 人力架构图工具 - 产品功能说明书.docx
# 直接构造 OOXML 包，不依赖 node / python / Office
# 风格参考：框架维护工具_PRD_v1.0.docx
# ============================================================
$ErrorActionPreference = "Stop"

$root      = "C:\Users\v_vinciye\Desktop\UI framework tool"
$build     = Join-Path $root ".build_docx"
$assetsDir = Join-Path $root "assets\images"
$outDocx   = Join-Path $root "下载说明书.docx"

# ---------- 1. 清理 & 准备目录 ----------
if (Test-Path $build) { Remove-Item $build -Recurse -Force }
New-Item -ItemType Directory -Path $build | Out-Null
New-Item -ItemType Directory -Path "$build\_rels" | Out-Null
New-Item -ItemType Directory -Path "$build\word" | Out-Null
New-Item -ItemType Directory -Path "$build\word\_rels" | Out-Null
New-Item -ItemType Directory -Path "$build\word\media" | Out-Null
New-Item -ItemType Directory -Path "$build\docProps" | Out-Null

# ---------- 2. 复制图片 & 测量尺寸 ----------
Add-Type -AssemblyName System.Drawing
$imgInfo = @{}
1..10 | ForEach-Object {
    $name = "image$_.png"
    $src  = Join-Path $assetsDir $name
    $dst  = Join-Path "$build\word\media" $name
    Copy-Item $src $dst -Force
    $img  = [System.Drawing.Image]::FromFile($src)
    $imgInfo[$name] = @{ W = $img.Width; H = $img.Height }
    $img.Dispose()
}

# 计算 EMU 尺寸 (1 inch = 914400 EMU; 1 px = 9525 EMU @96dpi)
# 内容宽度 = 约 6 英寸(A4 含 1英寸边距) = 5486400 EMU
function GetImgEmu($name, $maxWidthEmu = 5486400, $maxHeightEmu = 6400000) {
    $w = $imgInfo[$name].W
    $h = $imgInfo[$name].H
    $emuW = $w * 9525
    $emuH = $h * 9525
    if ($emuW -gt $maxWidthEmu) {
        $ratio = $maxWidthEmu / $emuW
        $emuW = [int]$maxWidthEmu
        $emuH = [int]($emuH * $ratio)
    }
    if ($emuH -gt $maxHeightEmu) {
        $ratio = $maxHeightEmu / $emuH
        $emuH = [int]$maxHeightEmu
        $emuW = [int]($emuW * $ratio)
    }
    return @{ W = [int]$emuW; H = [int]$emuH }
}

# ---------- 3. [Content_Types].xml ----------
$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Default Extension="png" ContentType="image/png"/>
    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
    <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
    <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
    <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
    <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
    <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
'@
[System.IO.File]::WriteAllText("$build\[Content_Types].xml", $contentTypes, [System.Text.UTF8Encoding]::new($false))

# ---------- 4. _rels/.rels ----------
$pkgRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
    <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$build\_rels\.rels", $pkgRels, [System.Text.UTF8Encoding]::new($false))

# ---------- 5. docProps ----------
$coreXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <dc:title>HIGAME · UI 人力架构图工具 - 产品功能说明书</dc:title>
    <dc:creator>UI 部门</dc:creator>
    <cp:lastModifiedBy>UI 部门</cp:lastModifiedBy>
    <dcterms:created xsi:type="dcterms:W3CDTF">2026-05-26T08:00:00Z</dcterms:created>
    <dcterms:modified xsi:type="dcterms:W3CDTF">2026-05-26T08:00:00Z</dcterms:modified>
</cp:coreProperties>
'@
[System.IO.File]::WriteAllText("$build\docProps\core.xml", $coreXml, [System.Text.UTF8Encoding]::new($false))

$appXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
    <Application>HIGAME UI Tool</Application>
</Properties>
'@
[System.IO.File]::WriteAllText("$build\docProps\app.xml", $appXml, [System.Text.UTF8Encoding]::new($false))

# ---------- 6. word/styles.xml （参考 PRD：H1=18pt 加粗 #0052D9, H2=15pt 加粗 #1F2329, H3=13pt 加粗）----------
# 字号 Word 单位 = 半磅，故 18pt = 36, 15pt = 30, 13pt = 26, 11pt = 22, 22pt = 44 (Title)
$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:docDefaults>
        <w:rPrDefault>
            <w:rPr>
                <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:cs="Microsoft YaHei"/>
                <w:sz w:val="22"/>
                <w:szCs w:val="22"/>
                <w:lang w:val="zh-CN" w:eastAsia="zh-CN"/>
            </w:rPr>
        </w:rPrDefault>
        <w:pPrDefault>
            <w:pPr>
                <w:spacing w:line="360" w:lineRule="auto" w:after="120"/>
            </w:pPr>
        </w:pPrDefault>
    </w:docDefaults>
    <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
        <w:name w:val="Normal"/>
        <w:qFormat/>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Title">
        <w:name w:val="Title"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:spacing w:before="240" w:after="120"/>
            <w:jc w:val="center"/>
        </w:pPr>
        <w:rPr>
            <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
            <w:b/>
            <w:color w:val="0052D9"/>
            <w:sz w:val="44"/>
            <w:szCs w:val="44"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Subtitle">
        <w:name w:val="Subtitle"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:spacing w:before="60" w:after="120"/>
            <w:jc w:val="center"/>
        </w:pPr>
        <w:rPr>
            <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
            <w:color w:val="595959"/>
            <w:sz w:val="28"/>
            <w:szCs w:val="28"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Heading1">
        <w:name w:val="heading 1"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:spacing w:before="360" w:after="180"/>
            <w:outlineLvl w:val="0"/>
        </w:pPr>
        <w:rPr>
            <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
            <w:b/>
            <w:color w:val="0052D9"/>
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
            <w:spacing w:before="240" w:after="120"/>
            <w:outlineLvl w:val="1"/>
        </w:pPr>
        <w:rPr>
            <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
            <w:b/>
            <w:color w:val="1F2329"/>
            <w:sz w:val="30"/>
            <w:szCs w:val="30"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="Heading3">
        <w:name w:val="heading 3"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:spacing w:before="200" w:after="100"/>
            <w:outlineLvl w:val="2"/>
        </w:pPr>
        <w:rPr>
            <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
            <w:b/>
            <w:color w:val="1F2329"/>
            <w:sz w:val="26"/>
            <w:szCs w:val="26"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="ImageCaption">
        <w:name w:val="Image Caption"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:spacing w:before="60" w:after="200"/>
            <w:jc w:val="center"/>
        </w:pPr>
        <w:rPr>
            <w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei"/>
            <w:i/>
            <w:color w:val="666666"/>
            <w:sz w:val="20"/>
            <w:szCs w:val="20"/>
        </w:rPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="ListParagraph">
        <w:name w:val="List Paragraph"/>
        <w:basedOn w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:ind w:left="420"/>
            <w:contextualSpacing/>
        </w:pPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="ImageCenter">
        <w:name w:val="Image Center"/>
        <w:basedOn w:val="Normal"/>
        <w:next w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:spacing w:before="200" w:after="60"/>
            <w:jc w:val="center"/>
        </w:pPr>
    </w:style>
    <w:style w:type="paragraph" w:styleId="InfoBox">
        <w:name w:val="Info Box"/>
        <w:basedOn w:val="Normal"/>
        <w:qFormat/>
        <w:pPr>
            <w:pBdr>
                <w:left w:val="single" w:sz="24" w:space="8" w:color="0052D9"/>
            </w:pBdr>
            <w:shd w:val="clear" w:color="auto" w:fill="F4F8FF"/>
            <w:spacing w:before="120" w:after="120"/>
            <w:ind w:left="240" w:right="120"/>
        </w:pPr>
    </w:style>
    <w:style w:type="table" w:styleId="TableGrid">
        <w:name w:val="Table Grid"/>
        <w:basedOn w:val="TableNormal"/>
        <w:pPr>
            <w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
        </w:pPr>
        <w:tblPr>
            <w:tblBorders>
                <w:top w:val="single" w:sz="4" w:color="BFBFBF"/>
                <w:left w:val="single" w:sz="4" w:color="BFBFBF"/>
                <w:bottom w:val="single" w:sz="4" w:color="BFBFBF"/>
                <w:right w:val="single" w:sz="4" w:color="BFBFBF"/>
                <w:insideH w:val="single" w:sz="4" w:color="BFBFBF"/>
                <w:insideV w:val="single" w:sz="4" w:color="BFBFBF"/>
            </w:tblBorders>
        </w:tblPr>
    </w:style>
    <w:style w:type="table" w:default="1" w:styleId="TableNormal">
        <w:name w:val="Normal Table"/>
        <w:tblPr>
            <w:tblInd w:w="0" w:type="dxa"/>
            <w:tblCellMar>
                <w:top w:w="0" w:type="dxa"/>
                <w:left w:w="108" w:type="dxa"/>
                <w:bottom w:w="0" w:type="dxa"/>
                <w:right w:w="108" w:type="dxa"/>
            </w:tblCellMar>
        </w:tblPr>
    </w:style>
</w:styles>
'@
[System.IO.File]::WriteAllText("$build\word\styles.xml", $stylesXml, [System.Text.UTF8Encoding]::new($false))

# ---------- 7. word/numbering.xml （项目符号 + 数字编号）----------
$numberingXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:abstractNum w:abstractNumId="0">
        <w:lvl w:ilvl="0">
            <w:start w:val="1"/>
            <w:numFmt w:val="bullet"/>
            <w:lvlText w:val="●"/>
            <w:lvlJc w:val="left"/>
            <w:pPr><w:ind w:left="420" w:hanging="280"/></w:pPr>
            <w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/></w:rPr>
        </w:lvl>
    </w:abstractNum>
    <w:abstractNum w:abstractNumId="1">
        <w:lvl w:ilvl="0">
            <w:start w:val="1"/>
            <w:numFmt w:val="decimal"/>
            <w:lvlText w:val="%1."/>
            <w:lvlJc w:val="left"/>
            <w:pPr><w:ind w:left="420" w:hanging="280"/></w:pPr>
        </w:lvl>
    </w:abstractNum>
    <w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>
    <w:num w:numId="2"><w:abstractNumId w:val="1"/></w:num>
</w:numbering>
'@
[System.IO.File]::WriteAllText("$build\word\numbering.xml", $numberingXml, [System.Text.UTF8Encoding]::new($false))

# ---------- 8. word/settings.xml ----------
$settingsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:zoom w:percent="100"/>
    <w:defaultTabStop w:val="420"/>
    <w:characterSpacingControl w:val="compressPunctuation"/>
    <w:compat>
        <w:doNotExpandShiftReturn/>
        <w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>
    </w:compat>
</w:settings>
'@
[System.IO.File]::WriteAllText("$build\word\settings.xml", $settingsXml, [System.Text.UTF8Encoding]::new($false))

# ---------- 9. word/_rels/document.xml.rels ----------
$docRelsLines = @()
$docRelsLines += '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
$docRelsLines += '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
$docRelsLines += '    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
$docRelsLines += '    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>'
$docRelsLines += '    <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>'
for ($i=1; $i -le 10; $i++) {
    $rid = 100 + $i
    $docRelsLines += "    <Relationship Id=`"rId$rid`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image`" Target=`"media/image$i.png`"/>"
}
$docRelsLines += '</Relationships>'
[System.IO.File]::WriteAllText("$build\word\_rels\document.xml.rels", ($docRelsLines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))

# ============================================================
# 10. word/document.xml —— 正文
# ============================================================
$sb = New-Object System.Text.StringBuilder

function Add-Line($s) { [void]$sb.AppendLine($s) }

# XML escape
function X($s) {
    return $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;'
}

# 段落（多 run，可指定加粗段）
function Para {
    param(
        [string]$Style = "",
        [hashtable[]]$Runs,
        [string]$Align = ""
    )
    $pPr = ""
    if ($Style -or $Align) {
        $pPr += "<w:pPr>"
        if ($Style) { $pPr += "<w:pStyle w:val=`"$Style`"/>" }
        if ($Align) { $pPr += "<w:jc w:val=`"$Align`"/>" }
        $pPr += "</w:pPr>"
    }
    $runsXml = ""
    foreach ($r in $Runs) {
        $rPr = "<w:rPr><w:rFonts w:ascii=`"Microsoft YaHei`" w:eastAsia=`"Microsoft YaHei`" w:hAnsi=`"Microsoft YaHei`" w:hint=`"eastAsia`"/>"
        if ($r.Bold) { $rPr += "<w:b/><w:bCs/>" }
        if ($r.Color) { $rPr += "<w:color w:val=`"$($r.Color)`"/>" }
        if ($r.Size) { $rPr += "<w:sz w:val=`"$($r.Size)`"/><w:szCs w:val=`"$($r.Size)`"/>" }
        $rPr += "</w:rPr>"
        $text = X($r.Text)
        $runsXml += "<w:r>$rPr<w:t xml:space=`"preserve`">$text</w:t></w:r>"
    }
    Add-Line "<w:p>$pPr$runsXml</w:p>"
}

# 简化文本段
function P($text, $style = "") {
    Para -Style $style -Runs @(@{Text=$text})
}

# 列表项
function LI($text) {
    $pPr = '<w:pPr><w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr></w:pPr>'
    $rPr = '<w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/></w:rPr>'
    $t = X($text)
    Add-Line "<w:p>$pPr<w:r>$rPr<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}

# 编号列表
function NLI($text) {
    $pPr = '<w:pPr><w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="2"/></w:numPr></w:pPr>'
    $rPr = '<w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/></w:rPr>'
    $t = X($text)
    Add-Line "<w:p>$pPr<w:r>$rPr<w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}

# 信息框（带边框背景的段落）
function Info($title, $body) {
    $pPr = '<w:pPr><w:pStyle w:val="InfoBox"/></w:pPr>'
    $rPr1 = '<w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/><w:b/><w:bCs/><w:color w:val="0052D9"/></w:rPr>'
    $rPr2 = '<w:rPr><w:rFonts w:ascii="Microsoft YaHei" w:eastAsia="Microsoft YaHei" w:hAnsi="Microsoft YaHei" w:hint="eastAsia"/></w:rPr>'
    $t1 = X($title)
    $t2 = X($body)
    Add-Line "<w:p>$pPr<w:r>$rPr1<w:t xml:space=`"preserve`">$t1</w:t></w:r><w:r>$rPr2<w:t xml:space=`"preserve`">$t2</w:t></w:r></w:p>"
}

# 图片
$imgUid = 1
function Image($name, $caption) {
    $script:imgUid++
    $rid = 100 + [int]($name -replace '[^0-9]','')
    $sz = GetImgEmu $name
    $w = $sz.W
    $h = $sz.H
    $imgXml = @"
<w:p>
<w:pPr><w:pStyle w:val="ImageCenter"/></w:pPr>
<w:r>
<w:drawing>
<wp:inline distT="0" distB="0" distL="0" distR="0" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
<wp:extent cx="$w" cy="$h"/>
<wp:effectExtent l="0" t="0" r="0" b="0"/>
<wp:docPr id="$imgUid" name="$name"/>
<wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr>
<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
<pic:nvPicPr><pic:cNvPr id="$imgUid" name="$name"/><pic:cNvPicPr/></pic:nvPicPr>
<pic:blipFill><a:blip xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" r:embed="rId$rid"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>
<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$w" cy="$h"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>
</pic:pic>
</a:graphicData>
</a:graphic>
</wp:inline>
</w:drawing>
</w:r>
</w:p>
"@
    Add-Line $imgXml
    if ($caption) {
        $cap = X($caption)
        Add-Line "<w:p><w:pPr><w:pStyle w:val=`"ImageCaption`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Microsoft YaHei`" w:eastAsia=`"Microsoft YaHei`" w:hAnsi=`"Microsoft YaHei`" w:hint=`"eastAsia`"/><w:i/><w:color w:val=`"666666`"/><w:sz w:val=`"20`"/></w:rPr><w:t xml:space=`"preserve`">$cap</w:t></w:r></w:p>"
    }
}

# 表格
function Table {
    param(
        [int[]]$ColWidthsDxa,
        [string[]]$Headers,
        [array]$Rows
    )
    $totalW = ($ColWidthsDxa | Measure-Object -Sum).Sum
    $tbl = "<w:tbl>"
    $tbl += "<w:tblPr><w:tblStyle w:val=`"TableGrid`"/><w:tblW w:w=`"$totalW`" w:type=`"dxa`"/><w:tblLook w:val=`"04A0`"/></w:tblPr>"
    $tbl += "<w:tblGrid>"
    foreach ($w in $ColWidthsDxa) { $tbl += "<w:gridCol w:w=`"$w`"/>" }
    $tbl += "</w:tblGrid>"
    # 表头
    $tbl += "<w:tr><w:trPr><w:tblHeader/></w:trPr>"
    for ($i=0; $i -lt $Headers.Count; $i++) {
        $w = $ColWidthsDxa[$i]
        $h = X($Headers[$i])
        $tbl += "<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"0052D9`"/><w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:before=`"60`" w:after=`"60`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Microsoft YaHei`" w:eastAsia=`"Microsoft YaHei`" w:hAnsi=`"Microsoft YaHei`" w:hint=`"eastAsia`"/><w:b/><w:color w:val=`"FFFFFF`"/></w:rPr><w:t>$h</w:t></w:r></w:p></w:tc>"
    }
    $tbl += "</w:tr>"
    # 数据行
    $rowIdx = 0
    foreach ($row in $Rows) {
        $rowIdx++
        $tbl += "<w:tr>"
        for ($i=0; $i -lt $row.Count; $i++) {
            $w = $ColWidthsDxa[$i]
            $t = X([string]$row[$i])
            $shadeXml = ""
            if (($rowIdx % 2) -eq 0) {
                $shadeXml = '<w:shd w:val="clear" w:color="auto" w:fill="F7F9FC"/>'
            }
            $tbl += "<w:tc><w:tcPr><w:tcW w:w=`"$w`" w:type=`"dxa`"/>$shadeXml<w:vAlign w:val=`"center`"/></w:tcPr><w:p><w:pPr><w:spacing w:before=`"60`" w:after=`"60`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Microsoft YaHei`" w:eastAsia=`"Microsoft YaHei`" w:hAnsi=`"Microsoft YaHei`" w:hint=`"eastAsia`"/></w:rPr><w:t xml:space=`"preserve`">$t</w:t></w:r></w:p></w:tc>"
        }
        $tbl += "</w:tr>"
    }
    $tbl += "</w:tbl>"
    Add-Line $tbl
    # 表格后空段（必须，否则下一段紧贴）
    Add-Line "<w:p/>"
}

# 分页符
function PageBreak {
    Add-Line '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
}

# ============================================================
# 文档头
# ============================================================
Add-Line '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
Add-Line '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
Add-Line '<w:body>'

# ============================================================
# 封面
# ============================================================
P "HIGAME · UI 人力架构图工具" "Title"
P "产品功能说明书 · Product Function Manual" "Subtitle"
P "Version 2.0 · 2026.05" "Subtitle"
Add-Line '<w:p/>'
Add-Line '<w:p/>'

# 文档信息表
P "文档信息" "Heading2"
Table -ColWidthsDxa @(2200,7160) -Headers @("项目","内容") -Rows @(
    @("产品名称","HIGAME · UI 人力架构图工具（人员架构图工具.html）"),
    @("版本号","v2.0"),
    @("适用对象","UI 部门 PM、团队负责人、HR 协同人员"),
    @("部署方式","单文件 HTML，浏览器双击即用"),
    @("文档日期","2026-05-26"),
    @("文档维护","UI 部门")
)

PageBreak

# ============================================================
# 一、快速上手
# ============================================================
P "一、快速上手（5 分钟）" "Heading1"
P "本章面向只想立刻用起来的使用者。无需阅读后续章节，按以下三步即可完成首次部署与日常维护。"

P "1.1 三步开始使用" "Heading2"

P "Step 1 · 打开工具" "Heading3"
P "双击 人员架构图工具.html，使用 Chrome / Edge 浏览器即开即用，无需安装。"

P "Step 2 · 导入团队数据" "Heading3"
P "点击顶部「重新导入」，从「图片 / Excel / 文字 / JSON / AI」中任选一种方式批量初始化。"

P "Step 3 · 日常维护" "Heading3"
P "点击成员可改名；点击 ✕ 进入回收池；新人通过「添加组员」加入；扇形图自动同步统计。"

P "1.2 常用操作速查" "Heading2"
Table -ColWidthsDxa @(2800,2600,3960) -Headers @("我想做什么","在哪操作","怎么做") -Rows @(
    @("把现有团队批量导入","顶部「重新导入」","选 5 种方式之一，按引导操作"),
    @("新增一个成员","顶部「添加组员」","填中英文名（支持企微一键粘贴）→ 选组 → 确认"),
    @("新增一个组","顶部「添加组别」","填组名 → 选组长 → 确认"),
    @("修改成员信息","架构图中点击该成员","修改姓名 / 组别 / 在职状态 / 集团属性"),
    @("删除离职人员","成员卡片右上角 ✕","填写离职原因 → 二次确认 → 进入回收池"),
    @("将要离职预告","点击成员 → 状态选「将要离职」","填写离职日期，到期自动入池"),
    @("恢复误删人员","右下「人员回收池」","点对应成员的「恢复」按钮"),
    @("调整图表大小","架构图右上角缩放控件","默认 80%，可拖动至舒适比例")
)

P "1.3 数据如何保存" "Heading2"
Info "本地浏览器自动保存：" "所有操作（新增 / 修改 / 删除 / 回收池）会通过浏览器 localStorage 实时保存为 JSON。即便关闭页面重新打开，数据依旧存在，无需手动保存。"
Info "跨设备迁移：" "如需迁移到其他电脑，请通过「重新导入 → JSON 配置导入」方式同步。"
Info "重要提示：" "清理浏览器缓存或使用「无痕模式」会清空本地数据。重要数据建议定期使用 JSON 导出 留档备份。"

PageBreak

# ============================================================
# 二、产品介绍
# ============================================================
P "二、产品介绍" "Heading1"

P "2.1 产品定位" "Heading2"
P "HIGAME · UI 人力架构图工具是一款简洁、轻量、即开即用的人员架构图制作与维护工具。它专注于「快速导入原始数据 + 长时间维护」这一核心场景，专为团队 PM、负责人、HR 协同岗位设计。"

P "2.2 设计初衷" "Heading2"
P "市面上 Xmind、Visio、ProcessOn 等工具功能虽强大，但都存在两个共同问题："
LI "功能过剩：大量 PM 用不到的脑图、模板、协作功能反而拖慢操作效率。"
LI "不贴合人员高频变动场景：每次有人入职 / 离职 / 转组都要手动改图、调位置，统计还需另开 Excel。"
P "本工具的研发起点，正是要 ""刚刚好"" 满足 UI 部门 PM 维护高变动人员架构图的痛点，砍掉不必要的功能，把精力集中在三件事上："
LI "① 快速初始化：5 种导入方式总有一种适合你，从零搭建只需几分钟。"
LI "② 高频变更友好：点击即改、点 ✕ 即删、回收池防误操作。"
LI "③ 自动同步统计：扇形图、占比数据 100% 自动更新，无需手算。"

P "2.3 核心特性" "Heading2"
Table -ColWidthsDxa @(2400,6960) -Headers @("特性","说明") -Rows @(
    @("单文件部署","纯 HTML，浏览器打开即用，可离线运行"),
    @("5 种导入方式","图片 OCR / Excel / 文字粘贴 / JSON / AI"),
    @("自动统计","ECharts 实时绑定，扇形图自动更新"),
    @("本地持久化","localStorage 自动落盘，关闭/刷新不丢"),
    @("回收池防误删","二次确认 + 一键恢复"),
    @("将要离职预告","灰色显示 + 到期自动入池"),
    @("中英文识别","企微一键粘贴自动拆分中英文名"),
    @("缩放友好","默认 80%，可自由调整阅读比例")
)

PageBreak

# ============================================================
# 三、主界面介绍
# ============================================================
P "三、主界面介绍" "Heading1"
P "打开 人员架构图工具.html 后进入主界面。整个页面由 5 大区域组成，覆盖了人员架构图从导入到维护的全部场景。"

Image "image1.png" "图 3-1 　主界面整体布局（含顶栏、组织架构图、双扇形图与人员回收池）"

P "3.1 五大区域概览" "Heading2"
Table -ColWidthsDxa @(900,2200,6260) -Headers @("区域","名称","核心职责") -Rows @(
    @("①","顶栏操作区","显示更新时间，提供「重新导入」「添加组员」「添加组别」三个核心操作入口"),
    @("②","组织架构图","页面最核心区域，可视化展示根 → 组 → 成员/PM 的树形结构，支持点击修改、✕ 删除"),
    @("③","公司编制占比图","右上扇形图，按集团 / 工作室 / 项目组等维度自动统计编制比例"),
    @("④","各组占比图","右中扇形图，按组别维度自动统计人数占比"),
    @("⑤","人员回收池","右下区域，存储已离职人员，便于统计、备注离职原因，也可在误删时一键恢复")
)

P "3.2 各区域职责说明" "Heading2"

P "① 顶栏" "Heading3"
P "顶部由「更新时间（自动取系统当日日期）」+「三个按钮（重新导入 / 添加组员 / 添加组别）」组成。"

P "② 组织架构图（核心）" "Heading3"
P "由 SVG 渲染的可视化树形图。所有变更（新增、删除、改名、转组、状态变更）的操作起点都在这里。"

P "③ ④ 双扇形图" "Heading3"
P "实时同步架构图数据。任何成员变更都会立刻反映到占比上，100% 自动准确，PM 无需手算。"

P "⑤ 人员回收池" "Heading3"
P "已删除/已离职人员的归档区。支持一键恢复、修改离职原因和时间，方便后续 HR 统计。"

PageBreak

# ============================================================
# 四、功能介绍
# ============================================================
P "四、功能介绍" "Heading1"

# 4.1 重新导入
P "F1 · 重新导入（5 种初始化方式）" "Heading2"

P "F1.1 设计原因" "Heading3"
P "考虑到不同组前期已积累的原始数据格式各不相同（截图、Excel、Word、Figma 链接、企微名单等），单一导入方式无法覆盖所有场景，因此设计了 5 种导入方式 以保证初始化效率与高适配性。"

P "F1.2 功能介绍" "Heading3"
P "5 种方式涵盖：图片识别（OCR）、Excel 表、文字粘贴、JSON 代码、AI 对话导入，外加手动调整。总有一种方法适合你的初始化数据。"

P "F1.3 操作步骤" "Heading3"
NLI "点击顶部信息栏「重新导入」按钮，弹出导入方式选择面板。"
NLI "点击对应方式，查看该方式的图文引导。"
NLI "按引导上传 / 粘贴 / 录入数据。"
NLI "系统校验数据完整性 → 显示导入预览 → 用户确认覆盖。"
NLI "导入成功后，组织架构图和扇形图实时更新，最后更新时间自动刷新。"

Image "image2.png" "图 4-1 　重新导入弹窗：5 种初始化方式入口"

# 4.2 添加组员与组别
P "F2 · 添加组员与组别" "Heading2"

P "F2.1 设计原因" "Heading3"
P "基于「长期维护」与「方便变更」两个核心诉求，设计了「添加组员」「添加组别」两个独立的轻量入口，以应对日常人员入职、组织调整等高频场景。"

P "F2.2 添加组员操作步骤" "Heading3"
NLI "点击操作区「添加组员」按钮。"
NLI "粘贴企微复制的姓名（系统自动区分中文名 / 英文工号）。"
NLI "选择所属组别（下拉选择已有组别，或新建）。"
NLI "选择身份（普通成员 / 组长 / 实习生）。"
NLI "选择集团属性（公司 / 工作室 / 项目组等）。"
NLI "确认提交，架构图与统计图同步更新。"

Image "image3.png" "图 4-2 　添加组员弹窗（支持企微一键粘贴中英文）"

P "F2.3 添加组别操作步骤" "Heading3"
NLI "点击操作区「添加组别」按钮。"
NLI "输入组别名称（如""动效组""）。"
NLI "选择组长（联想已有人员）。"
NLI "选择已有人员加入新组（多选），或留空创建空组。"
NLI "确认提交。"

Image "image4.png" "图 4-3 　添加组别弹窗（联想已有人员）"

# 4.3 回收池 + 删除
P "F3 · 长期维护：回收池 + 删除成员" "Heading2"

P "F3.1 设计原因" "Heading3"
P "基于「长期维护」的理念，必须确保人员变更能够有迹可循，方便后续统计与历史留存，避免「删除即丢失」。"

P "F3.2 功能介绍" "Heading3"
P "删除时可填写：入池原因、离职原因、操作时间。进入回收池时需要二次确认，确保数据正确，杜绝误删。"

P "F3.3 操作步骤" "Heading3"
NLI "在架构图节点上，点击成员卡片右上角的「×」。"
NLI "弹出「入池确认」对话框，必须填写：入池原因（下拉：离职 / 转岗 / 借调 / 其他）、详细备注（最少 5 字）、生效时间（默认当前时间）。"
NLI "点击「确认删除」，进入二次确认弹窗。"
NLI "二次确认通过后，成员从架构图移除并进入回收池；架构图与扇形图实时刷新。"

Image "image5.png" "图 4-4 　Step 1：点击成员卡片 ✕ 触发删除"
Image "image6.png" "图 4-5 　Step 2：填写入池原因与离职备注"
Image "image7.png" "图 4-6 　Step 3：选择操作时间 / 离职日期"
Image "image8.png" "图 4-7 　Step 4：二次确认 → 进入回收池"

# 4.4 恢复 + 将要离职
P "F4 · 长期维护：恢复人员 + 将要离职" "Heading2"

P "F4.1 设计原因" "Heading3"
P "依旧基于长期维护理念：当出现人员变更信息错误时要能快速恢复；当人员即将离职时也需要提前备注，方便 PM 在后续排期中清晰把握人员动态。"

P "F4.2 恢复人员" "Heading3"
P "误删或变更错误的人员，可以从回收池一键恢复到架构图中。"
P "操作路径：右下「人员回收池」→ 找到目标成员 → 点「恢复」按钮。"

Image "image9.png" "图 4-8 　从回收池恢复人员"

P "F4.3 将要离职" "Heading3"
P "状态切换为「将要离职」后，成员在架构图上以灰色显示；到达离职日期当天，自动进入回收池。"
P "操作路径：点击成员卡片 → 在弹窗中将状态切换为「将要离职」 → 选择具体离职时间。"

Image "image10.png" "图 4-9 　设置将要离职状态与离职日期"

Info "实用提示：" "「将要离职」是一个非常实用的过渡状态。PM 在做下个迭代排期时，可以一眼看到「灰色」的成员，避免给即将离职的人员安排长期任务。"

PageBreak

# ============================================================
# 五、其他功能与设计
# ============================================================
P "五、其他功能与设计" "Heading1"
P "本章介绍工具中提升日常使用效率的其他设计细节。"

P "5.1 修改个人信息" "Heading2"
P "在架构图中点击任一成员，即可在弹窗中修改其："
LI "中文姓名 / 英文姓名"
LI "所属组别"
LI "集团属性（公司 / 工作室 / 项目组等）"
LI "在职状态（在职 / 将要离职 / 已离职）"

P "5.2 中英文识别功能" "Heading2"
Info "从企微复制中英文名后直接粘贴：" "工具会自动按字符类型拆分中英文，分别填入对应字段，无需手动整理。"

P "5.3 人力架构图缩放" "Heading2"
P "架构图默认显示比例为 80%。使用者可基于自己显示器尺寸、人员数量、阅读偏好，滚动调整到舒适的比例。"

P "5.4 ECharts 自动统计" "Heading2"
P "右侧两张扇形图均由 ECharts 渲染，并与组织架构图实时绑定。无论增加 / 删除组别或成员，统计数据都会百分百准确自动更新。"

P "5.5 本地数据持久化" "Heading2"
Info "实现方式：" "本工具采用纯前端 JSON 储存于浏览器 localStorage。每次操作都会即时落盘。"
Info "典型场景：" "例如对某成员设置「将要离职 + 离职日期为今天」，刷新页面即可看到该成员自动进入回收池的效果。"

# ============================================================
# 六、附录
# ============================================================
P "六、附录" "Heading1"

P "6.1 浏览器与系统要求" "Heading2"
Table -ColWidthsDxa @(2400,6960) -Headers @("项目","推荐配置") -Rows @(
    @("浏览器","Chrome 90+ / Edge 90+ / Safari 14+"),
    @("操作系统","Windows 10+ / macOS 11+ / Linux"),
    @("分辨率","1366×768 及以上（推荐 1920×1080）"),
    @("是否需要联网","否（首次加载 ECharts CDN 后可完全离线使用）")
)

P "6.2 常见问题（FAQ）" "Heading2"

P "Q1：刷新或关闭页面会丢失数据吗？" "Heading3"
P "不会。所有数据通过浏览器 localStorage 自动保存，关闭后再次打开依然存在。"

P "Q2：如何在另一台电脑上恢复数据？" "Heading3"
P "在原电脑上将数据通过「JSON 导出」功能保存，再到新电脑上「重新导入 → JSON 配置导入」即可。"

P "Q3：删除的人员能恢复吗？" "Heading3"
P "可以。在右下「人员回收池」中找到目标成员，点击「恢复」即可一键还原至架构图。"

P "Q4：扇形图统计数据不准怎么办？" "Heading3"
P "扇形图与架构图实时双向绑定，理论上不会出错。如果出现异常，请刷新页面重新加载即可。"

# 文档结束 + 页面属性
Add-Line @'
<w:sectPr>
    <w:pgSz w:w="11906" w:h="16838"/>
    <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="851" w:footer="992" w:gutter="0"/>
    <w:cols w:space="425"/>
    <w:docGrid w:type="lines" w:linePitch="312"/>
</w:sectPr>
</w:body>
</w:document>
'@

[System.IO.File]::WriteAllText("$build\word\document.xml", $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

# ============================================================
# 11. 打包为 .docx (zip)
# ============================================================
if (Test-Path $outDocx) { Remove-Item $outDocx -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($build, $outDocx, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Write-Host ""
Write-Host "========================================"
Write-Host "  生成成功：$outDocx"
Write-Host "  大小：$([math]::Round((Get-Item $outDocx).Length/1KB, 1)) KB"
Write-Host "========================================"

# 清理临时构建目录
Remove-Item $build -Recurse -Force
