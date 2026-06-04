<template>
  <div class="panel chart-card">
    <div class="panel-title">{{ title }}</div>
    <div ref="chartRef" :style="{ width: '100%', height: height }"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import * as echarts from 'echarts'
import { useOrgStore } from '../stores/useOrgStore'

const props = defineProps({
  title: { type: String, default: '' },
  height: { type: String, default: '260px' },
  // 'bar' | 'pie-affiliation' | 'pie-group'
  chartType: { type: String, required: true }
})

const store = useOrgStore()
const chartRef = ref(null)
let chart = null

function buildOption() {
  if (props.chartType === 'bar') {
    const data = store.barData
    return {
      grid: { left: 50, right: 30, top: 30, bottom: 30 },
      tooltip: { trigger: 'axis' },
      legend: { data: ['人数'], top: 0, right: 10 },
      xAxis: { type: 'value', minInterval: 1 },
      yAxis: { type: 'category', data: data.map((d) => d.name).reverse() },
      series: [
        {
          name: '人数',
          type: 'bar',
          data: data.map((d) => d.value).reverse(),
          itemStyle: { color: '#5b8def', borderRadius: [0, 4, 4, 0] },
          label: { show: true, position: 'inside', color: '#fff', fontWeight: 600 },
          barWidth: 18
        }
      ]
    }
  }

  if (props.chartType === 'pie-affiliation') {
    return {
      tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
      legend: { top: 0, left: 'center', itemWidth: 12, itemHeight: 12 },
      series: [
        {
          name: '人员归属',
          type: 'pie',
          radius: ['0%', '62%'],
          center: ['50%', '58%'],
          data: store.pieAffiliationData,
          label: { formatter: '{b}({d}%)', fontSize: 11 },
          labelLine: { length: 8, length2: 6 }
        }
      ]
    }
  }

  if (props.chartType === 'pie-group') {
    return {
      tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
      legend: { top: 0, left: 'center', itemWidth: 12, itemHeight: 12 },
      series: [
        {
          name: '组别分布',
          type: 'pie',
          radius: ['0%', '62%'],
          center: ['50%', '58%'],
          data: store.pieGroupData,
          label: { formatter: '{b}({d}%)', fontSize: 11 },
          labelLine: { length: 8, length2: 6 }
        }
      ]
    }
  }
  return {}
}

function render() {
  if (!chart) return
  chart.setOption(buildOption(), true)
}

onMounted(async () => {
  await nextTick()
  chart = echarts.init(chartRef.value)
  render()
  window.addEventListener('resize', resizeChart)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', resizeChart)
  chart?.dispose()
  chart = null
})

function resizeChart() {
  chart?.resize()
}

// 数据变化 → 自动重绘（保证派生关系生效）
watch(
  () => [store.barData, store.pieAffiliationData, store.pieGroupData],
  () => render(),
  { deep: true }
)
</script>

<style scoped>
.chart-card {
  width: 100%;
}
</style>
