/**
 * ============================================================
 * 初始 Mock 成员数据 · 来源：用户提供的对照名单（截止 2026.05.20）
 * ------------------------------------------------------------
 * 编制结构（不含 PM 赵晨杨）：
 *   交互组（组长 潘佳绮 judgepan · 集团本部）：4 名组员
 *     - 王莹蕾 yingleiwang（集团本部）
 *     - 薛婷文 tingwenxue（子公司）
 *     - 方坤   ikunfang（子公司）
 *     - 徐子昂 ziangxu（集团实习生）
 *
 *   视觉组（组长 蒋晓舒 sudajiang · 集团本部）：7 名组员
 *     - 蔡倍瑜 beiyucai（集团本部）
 *     - 张云施 yunshizhang（子公司）
 *     - 王博文 bowennwang（子公司）
 *     - 周鹏   dapengzhou（子公司）
 *     - 易辉   yihuikkllyi（子公司）
 *     - 曾瀚玉 vivazeng（子公司）
 *     - 胡振豪 nyckhu（子公司）
 *
 *   重构组（组长 魏霓丽 aglaiawei · 子公司）：5 名组员
 *     - 吴春燕 cynthywu（子公司）
 *     - 梁成龙 ciongliang（子公司）
 *     - 全志财 zhicaiquan（子公司）
 *     - 陈俊伟 jjweichen（子公司）
 *     - 朱磊   upzhu（子公司）
 *
 *   动效组（组长 杨沫 molinyang · 子公司）：2 名组员
 *     - 于天阳 emberyu（子公司）
 *     - 林雅婷 yatinglin（子公司）
 *
 *   合计（含组长，不含 PM）= 22
 *     - 集团本部正式：4   - 集团实习生：1
 *     - 子公司正式 ：17   - 子公司实习生：0
 * ============================================================
 */

export const INITIAL_MEMBERS = [
  // ====================== 交互组（4 人，组长另计） ======================
  { id: 'm_inter_01', name: '王莹蕾',   enName: 'yingleiwang', group: 'interaction', affiliation: 'group-formal' },
  { id: 'm_inter_02', name: '薛婷文',   enName: 'tingwenxue',  group: 'interaction', affiliation: 'sub-formal' },
  { id: 'm_inter_03', name: '方坤',     enName: 'ikunfang',    group: 'interaction', affiliation: 'sub-formal' },
  { id: 'm_inter_04', name: '徐子昂',   enName: 'ziangxu',     group: 'interaction', affiliation: 'group-intern' },

  // ====================== 视觉组（7 人，组长另计） ======================
  { id: 'm_visual_01', name: '蔡倍瑜',  enName: 'beiyucai',    group: 'visual', affiliation: 'group-formal' },
  { id: 'm_visual_02', name: '张云施',  enName: 'yunshizhang', group: 'visual', affiliation: 'sub-formal' },
  { id: 'm_visual_03', name: '王博文',  enName: 'bowennwang',  group: 'visual', affiliation: 'sub-formal' },
  { id: 'm_visual_04', name: '周鹏',    enName: 'dapengzhou',  group: 'visual', affiliation: 'sub-formal' },
  { id: 'm_visual_05', name: '易辉',    enName: 'yihuikkllyi', group: 'visual', affiliation: 'sub-formal' },
  { id: 'm_visual_06', name: '曾瀚玉',  enName: 'vivazeng',    group: 'visual', affiliation: 'sub-formal' },
  { id: 'm_visual_07', name: '胡振豪',  enName: 'nyckhu',      group: 'visual', affiliation: 'sub-formal' },

  // ====================== 重构组（5 人，组长另计） ======================
  { id: 'm_refactor_01', name: '吴春燕', enName: 'cynthywu',   group: 'refactor', affiliation: 'sub-formal' },
  { id: 'm_refactor_02', name: '梁成龙', enName: 'ciongliang', group: 'refactor', affiliation: 'sub-formal' },
  { id: 'm_refactor_03', name: '全志财', enName: 'zhicaiquan', group: 'refactor', affiliation: 'sub-formal' },
  { id: 'm_refactor_04', name: '陈俊伟', enName: 'jjweichen',  group: 'refactor', affiliation: 'sub-formal' },
  { id: 'm_refactor_05', name: '朱磊',   enName: 'upzhu',      group: 'refactor', affiliation: 'sub-formal' },

  // ====================== 动效组（2 人，组长另计） ======================
  { id: 'm_motion_01', name: '于天阳',   enName: 'emberyu',    group: 'motion', affiliation: 'sub-formal' },
  { id: 'm_motion_02', name: '林雅婷',   enName: 'yatinglin',  group: 'motion', affiliation: 'sub-formal' }
]
