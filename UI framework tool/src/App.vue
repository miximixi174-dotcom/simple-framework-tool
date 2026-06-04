<template>
  <!-- 顶部居中主标题 -->
  <h1 class="app-title">HIGAME - UI人力架构</h1>

  <div class="app-shell">
    <!-- 左上：截止日期（自动取系统当前日期） -->
    <div class="deadline-text">截止 {{ currentDate }}</div>

    <!-- 右上：数字看板 -->
    <TopHeader />

    <!-- 主体：左侧架构图 + 左下柱状图，右侧两饼图 -->
    <div class="main-area">
      <div class="left-col">
        <OrgChart />
        <ChartPlaceholder
          title="各组人数 · 横向柱状图"
          height="260px"
          chart-type="bar"
        />
      </div>

      <div class="right-col">
        <ChartPlaceholder
          title="人员归属 · 饼图"
          height="280px"
          chart-type="pie-affiliation"
        />
        <ChartPlaceholder
          title="组别分布 · 饼图"
          height="280px"
          chart-type="pie-group"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import TopHeader from './components/TopHeader.vue'
import OrgChart from './components/OrgChart.vue'
import ChartPlaceholder from './components/ChartPlaceholder.vue'

// 自动取系统当前日期 → 格式 2026.05.20
const currentDate = computed(() => {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}.${m}.${day}`
})
</script>
