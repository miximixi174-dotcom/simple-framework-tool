<template>
  <div class="org-chart-wrap panel">
    <div class="panel-title">人员架构图（唯一数据源）</div>
    <div class="svg-scroll">
      <svg
        :viewBox="`0 0 ${layout.width} ${layout.height}`"
        :width="layout.width"
        :height="layout.height"
        xmlns="http://www.w3.org/2000/svg"
      >
        <!-- 1. 虚线大框（包围所有组） -->
        <rect
          v-for="(box, i) in layout.groupBoxes"
          :key="`box-${i}`"
          :x="box.x"
          :y="box.y"
          :width="box.w"
          :height="box.h"
          rx="10"
          ry="10"
          fill="rgba(219, 234, 254, 0.18)"
          stroke="#60a5fa"
          stroke-width="1.2"
          stroke-dasharray="6 4"
        />
        <!-- PM 独立虚线框 -->
        <rect
          :x="layout.pmBox.x"
          :y="layout.pmBox.y"
          :width="layout.pmBox.w"
          :height="layout.pmBox.h"
          rx="8"
          ry="8"
          fill="rgba(219, 234, 254, 0.18)"
          stroke="#60a5fa"
          stroke-width="1.2"
          stroke-dasharray="6 4"
        />

        <!-- 2. 折线 -->
        <path
          v-for="(edge, i) in layout.edges"
          :key="`edge-${i}`"
          :d="pointsToPath(edge.points)"
          stroke="#94a3b8"
          stroke-width="1"
          fill="none"
        />

        <!-- 3. 节点 -->
        <OrgNode :node="layout.rootNode" />
        <OrgNode
          v-for="g in layout.groupNodes"
          :key="g.id"
          :node="g"
        />
        <OrgNode :node="layout.pmNode" />
        <OrgNode
          v-for="m in layout.memberNodes"
          :key="m.id"
          :node="m"
        />
      </svg>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import OrgNode from './OrgNode.vue'
import { useOrgStore, GROUPS, ROOT, PM } from '../stores/useOrgStore'
import { computeLayout, pointsToPath } from '../utils/treeLayout'

const store = useOrgStore()

const layout = computed(() =>
  computeLayout({
    root: ROOT,
    groups: GROUPS,
    membersByGroup: store.membersByGroup,
    pm: PM
  })
)
</script>

<style scoped>
.org-chart-wrap {
  width: 100%;
}
.svg-scroll {
  width: 100%;
  overflow-x: auto;
}
svg {
  display: block;
  background: #ffffff;
}
</style>
