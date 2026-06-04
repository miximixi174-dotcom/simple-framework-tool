/**
 * ============================================================
 * 固定骨架配置 —— 不可被前端 UI 修改
 * ------------------------------------------------------------
 * 规则：
 *  · 根节点 ROOT、四大组 GROUPS、PM 节点完全锁定
 *  · 组别本身不可增删改
 *  · 组长姓名属于骨架的一部分，前端不允许编辑
 *  · PM 永远显示"赵晨杨"，且不计入任何统计
 * ============================================================
 */

// 4 种身份标签 + 配色（用于色块 chip）
export const AFFILIATIONS = [
  { key: 'group-formal', label: '集团本部', bg: '#dbeafe', fg: '#1d4ed8', dot: '#3b82f6' },
  { key: 'group-intern', label: '集团实习生', bg: '#e0f2fe', fg: '#0369a1', dot: '#7dd3fc' },
  { key: 'sub-formal', label: '子公司', bg: '#fef3c7', fg: '#b45309', dot: '#f59e0b' },
  { key: 'sub-intern', label: '子公司实习生', bg: '#fef9c3', fg: '#a16207', dot: '#fcd34d' }
]

export const AFFILIATION_MAP = AFFILIATIONS.reduce((m, a) => {
  m[a.key] = a
  return m
}, {})

// 根节点
export const ROOT = {
  id: 'root',
  type: 'fixed-root',
  name: 'UI职能',
  leader: '潘佳绮',
  locked: true
}

// 四大组（含组长信息）
export const GROUPS = [
  {
    id: 'g_inter',
    type: 'fixed-group',
    key: 'interaction',
    name: '交互',
    leader: '潘佳绮',
    leaderAffiliation: 'group-formal',
    color: '#3b82f6',
    locked: true
  },
  {
    id: 'g_visual',
    type: 'fixed-group',
    key: 'visual',
    name: '视觉',
    leader: '蒋晓舒',
    leaderAffiliation: 'group-formal',
    color: '#22c55e',
    locked: true
  },
  {
    id: 'g_refactor',
    type: 'fixed-group',
    key: 'refactor',
    name: '重构',
    leader: '魏霓丽',
    leaderAffiliation: 'sub-formal',
    color: '#f59e0b',
    locked: true
  },
  {
    id: 'g_motion',
    type: 'fixed-group',
    key: 'motion',
    name: '动效',
    leader: '杨沫',
    leaderAffiliation: 'sub-formal',
    color: '#ef4444',
    locked: true
  }
]

// PM（固定，不计入统计）
export const PM = {
  id: 'pm',
  type: 'fixed-pm',
  name: 'UI PM',
  members: [{ id: 'pm_001', name: '赵晨杨', enName: 'chenyangzhao' }],
  excludeFromStats: true,
  locked: true
}

// 工具：根据 group key 找组配置
export function getGroupByKey(key) {
  return GROUPS.find((g) => g.key === key)
}
