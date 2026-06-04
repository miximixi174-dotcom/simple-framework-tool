/**
 * ============================================================
 * 树形布局算法 —— 计算每个节点的 (x, y) 像素坐标
 * ------------------------------------------------------------
 * 优化④：单组成员 ≤ 6 → 1列  /  7~12 → 2列  /  > 12 → 3列
 * 输出：
 *   {
 *     rootNode,   // 根节点坐标
 *     groupNodes, // 4 个组长节点坐标
 *     pmNode,     // PM 节点坐标
 *     memberNodes,// 全部成员节点坐标，含 group 字段
 *     edges,      // 所有需要绘制的折线段
 *     groupBoxes, // 各组的视觉外框范围（用于绘制虚线大框）
 *     pmBox,      // PM 独立虚线框
 *     width,      // 画布总宽
 *     height      // 画布总高
 *   }
 * ============================================================
 */

// === 全局尺寸常量 ===
export const NODE_W = 130        // 节点宽
export const NODE_H = 56         // 节点高
export const COL_GAP = 24        // 同组内多列时的列间距
export const ROW_GAP = 12        // 节点行间距
export const GROUP_GAP = 40      // 不同组之间的横向间距
export const GROUP_INNER_TOP = 90 // 组长下方到第一行成员的距离
export const ROOT_TO_GROUP = 80  // 根节点到组长节点的纵向距离
export const PADDING_X = 40      // 画布左右边距
export const PADDING_Y = 40      // 画布上下边距
export const ROOT_W = 120        // 根节点宽度
export const ROOT_H = 56         // 根节点高度

/**
 * 根据成员数量决定分几列
 * @param {number} count
 * @returns {number} 1 / 2 / 3
 */
export function decideColumns(count) {
  if (count <= 6) return 1
  if (count <= 12) return 2
  return 3
}

/**
 * 主布局函数
 * @param {Object} param0
 * @param {Object} root            固定根节点 { name, leader }
 * @param {Array}  groups          固定 4 个组配置
 * @param {Object} membersByGroup  { interaction:[...], visual:[...], ... }
 * @param {Object} pm              PM 配置
 * @returns 完整布局
 */
export function computeLayout({ root, groups, membersByGroup, pm }) {
  // ---- 1. 计算每组宽度（列数 × 节点宽 + 列间距） ----
  const groupMetas = groups.map((g) => {
    const list = membersByGroup[g.key] || []
    const cols = decideColumns(list.length)
    const rows = Math.ceil(list.length / cols) || 1
    const width = cols * NODE_W + (cols - 1) * COL_GAP
    const height = rows * NODE_H + (rows - 1) * ROW_GAP
    return { ...g, members: list, cols, rows, width, height }
  })

  // ---- 2. 计算 X 起点：每组并排放置 ----
  let cursorX = PADDING_X
  groupMetas.forEach((gm) => {
    gm.x = cursorX                        // 该组内容的左边界
    gm.centerX = cursorX + gm.width / 2   // 该组的水平中心
    cursorX += gm.width + GROUP_GAP
  })

  // PM 框紧跟最后一个组之后
  const pmX = cursorX
  const pmW = NODE_W
  const pmContentRight = pmX + pmW

  // ---- 3. 整体画布宽度 ----
  const totalWidth = pmContentRight + PADDING_X

  // ---- 4. Y 轴坐标 ----
  // 根节点
  const rootY = PADDING_Y
  const rootX = totalWidth / 2 - ROOT_W / 2

  // 组长节点
  const groupLeaderY = rootY + ROOT_H + ROOT_TO_GROUP

  // 成员区起点
  const memberStartY = groupLeaderY + GROUP_INNER_TOP

  // 找出最高的成员区
  const maxMemberHeight = Math.max(...groupMetas.map((g) => g.height), 0)
  const totalHeight = memberStartY + maxMemberHeight + PADDING_Y

  // ---- 5. 节点坐标 ----
  const rootNode = {
    id: root.id,
    type: 'root',
    name: root.name,
    leader: root.leader,
    x: rootX,
    y: rootY,
    w: ROOT_W,
    h: ROOT_H
  }

  const groupNodes = groupMetas.map((gm) => ({
    id: gm.id,
    type: 'group',
    key: gm.key,
    name: gm.name,
    leader: gm.leader,
    affiliation: gm.leaderAffiliation,
    x: gm.centerX - NODE_W / 2,
    y: groupLeaderY,
    w: NODE_W,
    h: NODE_H,
    color: gm.color
  }))

  const pmNode = {
    id: pm.id,
    type: 'pm',
    name: pm.members[0].name,
    enName: pm.members[0].enName,
    x: pmX,
    y: groupLeaderY,
    w: pmW,
    h: NODE_H
  }

  // 成员坐标：每组内按列优先填充
  const memberNodes = []
  groupMetas.forEach((gm) => {
    gm.members.forEach((m, idx) => {
      const col = idx % gm.cols
      const row = Math.floor(idx / gm.cols)
      const x = gm.x + col * (NODE_W + COL_GAP)
      const y = memberStartY + row * (NODE_H + ROW_GAP)
      memberNodes.push({
        id: m.id,
        type: 'member',
        name: m.name,
        enName: m.enName,
        affiliation: m.affiliation,
        group: m.group,
        x,
        y,
        w: NODE_W,
        h: NODE_H
      })
    })
  })

  // ---- 6. 折线 edges ----
  const edges = []

  // 6.1 根节点 → 横向汇流线 → 各组长 / PM
  // 横向汇流线 Y 位置：组长节点正上方一段距离
  const busY = groupLeaderY - 30
  const rootBottomX = rootX + ROOT_W / 2
  const rootBottomY = rootY + ROOT_H

  // 根 → 汇流线（向下垂直段）
  edges.push({
    type: 'orthogonal',
    points: [
      [rootBottomX, rootBottomY],
      [rootBottomX, busY]
    ]
  })

  // 汇流线水平延伸：左到第一个组中线、右到 PM 中线
  const busLeftX = groupNodes[0].x + NODE_W / 2
  const busRightX = pmNode.x + pmW / 2
  edges.push({
    type: 'orthogonal',
    points: [
      [busLeftX, busY],
      [busRightX, busY]
    ]
  })

  // 汇流线 → 每个组长 / PM 顶部
  groupNodes.forEach((gn) => {
    const cx = gn.x + NODE_W / 2
    edges.push({
      type: 'orthogonal',
      points: [
        [cx, busY],
        [cx, gn.y]
      ]
    })
  })
  // 汇流线 → PM 顶部
  edges.push({
    type: 'orthogonal',
    points: [
      [pmNode.x + pmW / 2, busY],
      [pmNode.x + pmW / 2, pmNode.y]
    ]
  })

  // 6.2 各组长 → 该组成员
  groupMetas.forEach((gm, gi) => {
    const gn = groupNodes[gi]
    const leaderBottomX = gn.x + NODE_W / 2
    const leaderBottomY = gn.y + NODE_H

    // 该组的水平汇流线（在 leaderBottom 与 memberStartY 之间）
    const groupBusY = memberStartY - 24

    // 组长 → 组内汇流线
    edges.push({
      type: 'orthogonal',
      points: [
        [leaderBottomX, leaderBottomY],
        [leaderBottomX, groupBusY]
      ]
    })

    if (gm.members.length === 0) return

    // 找出本组所有成员的 x 范围（用于汇流线左右边界）
    const memberCenters = gm.members.map((m, idx) => {
      const col = idx % gm.cols
      return gm.x + col * (NODE_W + COL_GAP) + NODE_W / 2
    })
    const minCX = Math.min(...memberCenters)
    const maxCX = Math.max(...memberCenters)

    // 组内水平汇流线（仅当跨多列或与 leaderBottomX 不同时绘制）
    edges.push({
      type: 'orthogonal',
      points: [
        [Math.min(leaderBottomX, minCX), groupBusY],
        [Math.max(leaderBottomX, maxCX), groupBusY]
      ]
    })

    // 每个成员 → 自己上方水平线
    gm.members.forEach((m, idx) => {
      const col = idx % gm.cols
      const row = Math.floor(idx / gm.cols)
      const cx = gm.x + col * (NODE_W + COL_GAP) + NODE_W / 2
      const y = memberStartY + row * (NODE_H + ROW_GAP)

      // 第一行：直接从汇流线垂直接到节点顶部
      if (row === 0) {
        edges.push({
          type: 'orthogonal',
          points: [
            [cx, groupBusY],
            [cx, y]
          ]
        })
      } else {
        // 后续行：从该列上一行节点底部连到本节点顶部
        const prevY = memberStartY + (row - 1) * (NODE_H + ROW_GAP) + NODE_H
        edges.push({
          type: 'orthogonal',
          points: [
            [cx, prevY],
            [cx, y]
          ]
        })
      }
    })
  })

  // ---- 7. 虚线大框 ----
  // 包围"全部 4 个组长节点 + 它们的成员"的大框
  const allInsideNodes = [...groupNodes, ...memberNodes]
  const minX = Math.min(...allInsideNodes.map((n) => n.x)) - 16
  const minY = groupLeaderY - 16
  const maxX = Math.max(...allInsideNodes.map((n) => n.x + n.w)) + 16
  const maxY = Math.max(...allInsideNodes.map((n) => n.y + n.h)) + 16

  const groupBoxes = [
    {
      x: minX,
      y: minY,
      w: maxX - minX,
      h: maxY - minY
    }
  ]

  // PM 独立虚线框
  const pmBox = {
    x: pmNode.x - 12,
    y: pmNode.y - 16,
    w: pmW + 24,
    h: pmNode.h + 32
  }

  return {
    rootNode,
    groupNodes,
    pmNode,
    memberNodes,
    edges,
    groupBoxes,
    pmBox,
    width: Math.max(totalWidth, pmBox.x + pmBox.w + PADDING_X),
    height: totalHeight
  }
}

/**
 * 把 edge.points 转成 SVG path 'M x y L x y' 字符串
 */
export function pointsToPath(points) {
  if (!points || points.length === 0) return ''
  return points
    .map((p, i) => `${i === 0 ? 'M' : 'L'} ${p[0]} ${p[1]}`)
    .join(' ')
}
