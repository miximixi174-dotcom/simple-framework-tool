<template>
  <!-- 用 <g> 包裹方便整组定位 -->
  <g :transform="`translate(${node.x}, ${node.y})`" class="org-node">
    <!-- 节点底框 -->
    <rect
      :width="node.w"
      :height="node.h"
      rx="6"
      ry="6"
      :fill="bgColor"
      :stroke="strokeColor"
      :stroke-width="node.type === 'root' ? 1.4 : 1"
    />

    <!-- 根节点：UI职能 + 组长 -->
    <template v-if="node.type === 'root'">
      <text
        :x="node.w / 2"
        :y="node.h / 2 - 6"
        text-anchor="middle"
        class="text-name root"
      >
        {{ node.name }}
      </text>
      <text
        :x="node.w / 2"
        :y="node.h / 2 + 14"
        text-anchor="middle"
        class="text-leader"
      >
        {{ node.leader }}
      </text>
    </template>

    <!-- 组长节点：交互：潘佳绮 + 身份色块 -->
    <template v-else-if="node.type === 'group'">
      <text
        :x="node.w / 2"
        :y="22"
        text-anchor="middle"
        class="text-name group"
      >
        {{ node.name }}：{{ node.leader }}
      </text>
      <!-- 身份色块 -->
      <g v-if="affMeta" :transform="`translate(${node.w / 2 - chipW(affMeta) / 2}, 32)`">
        <rect
          :width="chipW(affMeta)"
          height="18"
          rx="4"
          ry="4"
          :fill="affMeta.bg"
        />
        <text
          :x="chipW(affMeta) / 2"
          y="13"
          text-anchor="middle"
          class="text-chip"
          :fill="affMeta.fg"
        >
          {{ affMeta.label }}
        </text>
      </g>
    </template>

    <!-- 成员节点：英文ID(中文名) + 身份色块 -->
    <template v-else-if="node.type === 'member'">
      <text
        :x="node.w / 2"
        :y="20"
        text-anchor="middle"
        class="text-en"
      >
        {{ node.enName }}({{ node.name }})
      </text>
      <g v-if="affMeta" :transform="`translate(${node.w / 2 - chipW(affMeta) / 2}, 30)`">
        <rect
          :width="chipW(affMeta)"
          height="18"
          rx="4"
          ry="4"
          :fill="affMeta.bg"
        />
        <text
          :x="chipW(affMeta) / 2"
          y="13"
          text-anchor="middle"
          class="text-chip"
          :fill="affMeta.fg"
        >
          {{ affMeta.label }}
        </text>
      </g>
    </template>

    <!-- PM 节点：纵向排列 -->
    <template v-else-if="node.type === 'pm'">
      <text
        :x="node.w / 2"
        :y="22"
        text-anchor="middle"
        class="text-name group"
      >
        UI PM
      </text>
      <text
        :x="node.w / 2"
        :y="42"
        text-anchor="middle"
        class="text-en"
      >
        {{ node.name }}
      </text>
    </template>
  </g>
</template>

<script setup>
import { computed } from 'vue'
import { AFFILIATION_MAP } from '../config/fixedStructure'

const props = defineProps({
  node: { type: Object, required: true }
})

// 身份元信息
const affMeta = computed(() =>
  props.node.affiliation ? AFFILIATION_MAP[props.node.affiliation] : null
)

// 不同类型节点的背景色
const bgColor = computed(() => {
  switch (props.node.type) {
    case 'root':
      return '#3b82f6' // 实蓝（与原图一致）
    case 'group':
      return '#dbeafe'
    case 'member':
      return '#eff6ff'
    case 'pm':
      return '#ffffff'
    default:
      return '#ffffff'
  }
})

const strokeColor = computed(() => {
  switch (props.node.type) {
    case 'root':
      return '#1d4ed8'
    case 'pm':
      return '#cbd5e1'
    default:
      return '#93c5fd'
  }
})

// 简易宽度估算：以中文 2 个字、英文1个字符约 8px 估算
function chipW(meta) {
  const len = meta.label.length
  return Math.max(56, len * 12 + 12)
}
</script>

<style scoped>
.text-name.root {
  fill: #ffffff;
  font-size: 14px;
  font-weight: 700;
}
.text-leader {
  fill: #ffffff;
  font-size: 12px;
  font-weight: 500;
}
.text-name.group {
  fill: #1e3a8a;
  font-size: 13px;
  font-weight: 600;
}
.text-en {
  fill: #1f2937;
  font-size: 11px;
  font-weight: 500;
}
.text-chip {
  font-size: 10px;
  font-weight: 500;
}
</style>
