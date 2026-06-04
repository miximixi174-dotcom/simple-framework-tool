<template>
  <div class="kpi-panel">
    <div class="kpi-note">- 本统计不包含PM</div>
    <div class="kpi-row">
      <span>集团正式：<b>{{ counts['group-formal'] }}</b></span>
      <span>集团实习生：<b>{{ counts['group-intern'] }}</b></span>
    </div>
    <div class="kpi-row">
      <span>子公司：<b>{{ counts['sub-formal'] }}</b></span>
      <span>子公司实习生：<b>{{ counts['sub-intern'] }}</b></span>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useOrgStore } from '../stores/useOrgStore'

const store = useOrgStore()
const counts = computed(() => store.affiliationCounts)
</script>
