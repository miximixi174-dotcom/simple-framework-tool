import { defineStore } from 'pinia'
import { ROOT, GROUPS, PM, AFFILIATIONS } from '../config/fixedStructure'
import { INITIAL_MEMBERS } from '../data/mockMembers'

const STORAGE_KEY = 'higame_ui_org_data_v1'

/**
 * useOrgStore —— 唯一数据中心
 *  · members: 可变成员（非组长、非PM）
 *  · recyclePool: 删除回收池
 *  · 所有派生统计（KPI / 柱状图 / 饼图）均通过 getter 计算
 */
export const useOrgStore = defineStore('org', {
  state: () => {
    // 尝试从 localStorage 读取持久化数据
    let saved = null
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) saved = JSON.parse(raw)
    } catch (e) {
      saved = null
    }
    return {
      members: saved?.members ?? [...INITIAL_MEMBERS],
      recyclePool: saved?.recyclePool ?? []
    }
  },

  getters: {
    /** 组长列表（来自固定骨架，参与统计） */
    leaders() {
      return GROUPS.map((g) => ({
        id: `leader_${g.key}`,
        name: g.leader,
        group: g.key,
        affiliation: g.leaderAffiliation,
        isLeader: true
      }))
    },

    /** 全员（含组长，不含PM）—— 所有统计的基础集合 */
    allCountable() {
      return [...this.leaders, ...this.members]
    },

    /** 顶部数字看板：4 种身份的人数 */
    affiliationCounts() {
      const result = {}
      AFFILIATIONS.forEach((a) => (result[a.key] = 0))
      this.allCountable.forEach((m) => {
        if (result[m.affiliation] !== undefined) result[m.affiliation]++
      })
      return result
    },

    /** 各组人数（柱状图） */
    groupCounts() {
      const result = {}
      GROUPS.forEach((g) => (result[g.key] = 0))
      this.allCountable.forEach((m) => {
        if (result[m.group] !== undefined) result[m.group]++
      })
      return result
    },

    /** 总人数（不含PM） */
    totalCount() {
      return this.allCountable.length
    },

    /** 按组分组的可变成员（用于架构图渲染） */
    membersByGroup() {
      const result = {}
      GROUPS.forEach((g) => (result[g.key] = []))
      this.members.forEach((m) => {
        if (result[m.group]) result[m.group].push(m)
      })
      return result
    },

    /** 饼图1 数据：人员归属占比 */
    pieAffiliationData() {
      return AFFILIATIONS.map((a) => ({
        name: a.label,
        value: this.affiliationCounts[a.key] || 0,
        itemStyle: { color: a.dot }
      }))
    },

    /** 饼图2 数据：组别分布占比 */
    pieGroupData() {
      return GROUPS.map((g) => ({
        name: g.name,
        value: this.groupCounts[g.key] || 0,
        itemStyle: { color: g.color }
      }))
    },

    /** 柱状图数据 */
    barData() {
      // 与原图一致的顺序：动效 / 重构 / 视觉 / 交互（自下而上 → 数组逆序）
      const order = ['interaction', 'visual', 'refactor', 'motion']
      return order.map((key) => {
        const g = GROUPS.find((x) => x.key === key)
        return { name: g.name, value: this.groupCounts[key] || 0 }
      })
    }
  },

  actions: {
    /** 持久化 */
    persist() {
      try {
        localStorage.setItem(
          STORAGE_KEY,
          JSON.stringify({
            members: this.members,
            recyclePool: this.recyclePool
          })
        )
      } catch (e) {
        console.warn('持久化失败', e)
      }
    },

    /** 新增成员 —— 第3步会用到 */
    addMember(payload) {
      const id = `m_${payload.group}_${Date.now()}`
      this.members.push({ id, ...payload })
      this.persist()
    },

    /** 编辑成员（仅允许改姓名） */
    updateMemberName(id, { name, enName }) {
      const m = this.members.find((x) => x.id === id)
      if (!m) return
      if (name !== undefined) m.name = name
      if (enName !== undefined) m.enName = enName
      this.persist()
    },

    /** 删除成员 → 进入回收池 */
    softDeleteMember(id) {
      const idx = this.members.findIndex((x) => x.id === id)
      if (idx < 0) return
      const [m] = this.members.splice(idx, 1)
      this.recyclePool.push({
        id: `rec_${Date.now()}`,
        deletedAt: new Date().toISOString(),
        member: m
      })
      this.persist()
    },

    /** 还原成员 */
    restoreFromRecycle(recId) {
      const idx = this.recyclePool.findIndex((x) => x.id === recId)
      if (idx < 0) return
      const [rec] = this.recyclePool.splice(idx, 1)
      this.members.push(rec.member)
      this.persist()
    },

    /** 永久删除回收池条目 */
    purgeFromRecycle(recId) {
      this.recyclePool = this.recyclePool.filter((x) => x.id !== recId)
      this.persist()
    },

    /** 重置为初始 OCR 数据 */
    resetToInitial() {
      this.members = [...INITIAL_MEMBERS]
      this.recyclePool = []
      this.persist()
    }
  }
})

// 导出固定骨架引用，避免组件重复 import
export { ROOT, GROUPS, PM, AFFILIATIONS }
