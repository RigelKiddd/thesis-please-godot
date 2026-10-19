/* Shared model and immutable presentation definitions. No DOM side effects. */
(function () {
/* THESIS, PLEASE — modular level editor.
 * No framework, no build step. Everything is local.
 */
'use strict';

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
const clone = (v) => JSON.parse(JSON.stringify(v));
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const asArray = (v) => (Array.isArray(v) ? v : []);
const asText = (v) => (v === null || v === undefined ? '' : String(v));
const num = (v, fallback = 0) => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};

const FILES = ['world.json', 'characters.json', 'cases.json', 'levels.json', 'tasks.json'];
const LOGIC_FILE = 'logic.json';
const CONTENT_VERSION = 'v1.13';

const LOGIC_OPS = [
  ['==', '等于 =='],
  ['!=', '不等于 !='],
  ['>=', '大于等于 >='],
  ['<=', '小于等于 <='],
  ['>', '大于 >'],
  ['<', '小于 <'],
  ['contains', '包含 contains'],
  ['startsWith', '开头是 startsWith'],
  ['in', '属于 in'],
  ['truthy', '为真 truthy'],
];
const LOGIC_RESULTS = [
  ['approve', '通过 / approve'],
  ['return', '退回 / return'],
  ['reject', '拒绝 / reject'],
  ['flag', '转人工 / flag'],
];
const LOGIC_NODE_LABEL = {
  start: '入口',
  condition: '条件',
  all: 'ALL · 全部满足',
  any: 'ANY · 任一满足',
  not: 'NOT · 取反',
  set: '设置字段',
  result: '结果',
};

const STYLE_DEFS = {
  certificate: {
    label: '棉纸证书',
    en: 'CERTIFICATE STOCK',
    accent: '#b08a3e',
    border: '#8a6a32',
    bg: '#f4ecd7',
    desc: '象牙白棉纸、金色双线、红色校印。用于申请表、认定表与名额核定。',
  },
  sealed: {
    label: '密封存档',
    en: 'SEALED RECORD',
    accent: '#a83a2f',
    border: '#7d3329',
    bg: '#f7f0dd',
    desc: '成绩单、查重报告等存档材料。红色双线、圆章压在数据上。',
  },
  mimeo: {
    label: '油印公示',
    en: 'MIMEOGRAPH NOTICE',
    accent: '#2e312c',
    border: '#2d302c',
    bg: '#e5e2d6',
    desc: '班级公示、课程冲突核查。黑灰油印、纸张发青、无装饰边。',
  },
  carbonless: {
    label: '蓝色复写纸',
    en: 'CARBONLESS FORM',
    accent: '#2d4d78',
    border: '#3f5f6e',
    bg: '#dce8ee',
    desc: '请假条、困难认定、家长联系记录。蓝色横线、手写签名、虚线撕口。',
  },
  cardstock: {
    label: '牛皮卡纸',
    en: 'KRAFT CARDSTOCK',
    accent: '#8b382b',
    border: '#5a2f22',
    bg: '#d9b98a',
    desc: '优毕推荐表、名额/预约单。粗纤维、深红抬头带、偏暖。',
  },
  student_id: {
    label: '学生证',
    en: 'STUDENT ID',
    accent: '#2d6d86',
    border: '#2f5666',
    bg: '#e8f0f2',
    desc: '校园卡/学生证。冷青塑料感、证件照片位、磁条与编号。',
  },
  id_card: {
    label: '身份证 / 证件卡',
    en: 'ID CARD',
    accent: '#2b5d78',
    border: '#3d5a6b',
    bg: '#dfeaf0',
    desc: '身份证、临时通行证、考试证。浅蓝底纹、证件字段、照片位。',
  },
  scholarship: {
    label: '奖学金证书',
    en: 'SCHOLARSHIP CERTIFICATE',
    accent: '#b08a3e',
    border: '#8a5a26',
    bg: '#f6ecd2',
    desc: '国家/校级奖学金、荣誉证书。金线、衬线标题、红色校印。',
  },
  admission: {
    label: '录取通知书',
    en: 'OFFER LETTER',
    accent: '#4e6d4f',
    border: '#526846',
    bg: '#f6f1df',
    desc: '国内外大学 offer / 录取通知。绿色信头、正文段落、落款。',
  },
  ledger: {
    label: '财务 / 助学金台账',
    en: 'BURSAR LEDGER',
    accent: '#3f6045',
    border: '#4e6045',
    bg: '#e8edda',
    desc: '学费、住宿费、助学金发放记录。绿色横线、金额栏、财务章。',
  },
  index_card: {
    label: '档案 / 图书馆卡',
    en: 'INDEX CARD',
    accent: '#8b5a2b',
    border: '#7a6548',
    bg: '#eadbb8',
    desc: '学籍档案、图书借阅卡、材料索引。牛皮索引卡、红标题线。',
  },
  passport: {
    label: '护照 / 签证页',
    en: 'PASSPORT PAGE',
    accent: '#2d4d78',
    border: '#344f6b',
    bg: '#dbe4ec',
    desc: '护照资料页、签证、出入境记录。深蓝证件带、机读区、照片位。',
  },
  boarding: {
    label: '登机牌 / 凭证',
    en: 'BOARDING PASS',
    accent: '#2e312c',
    border: '#4a4a42',
    bg: '#e9e7de',
    desc: '登机牌、车票、预约凭证。热敏纸、虚线撕口、条码与编号。',
  },
};
const STYLE_ORDER = [
  'certificate', 'sealed', 'mimeo', 'carbonless', 'cardstock',
  'student_id', 'id_card', 'scholarship', 'admission', 'ledger',
  'index_card', 'passport', 'boarding',
];
const STYLE_TEXTURE = {
  certificate: 'certificate',
  sealed: 'certificate',
  mimeo: 'mimeo',
  carbonless: 'carbonless',
  cardstock: 'cardstock',
  student_id: 'cardstock',
  id_card: 'cardstock',
  scholarship: 'certificate',
  admission: 'certificate',
  ledger: 'mimeo',
  index_card: 'cardstock',
  passport: 'certificate',
  boarding: 'mimeo',
};
const STYLE_BAND = {
  certificate: 'OFFICIAL DOCUMENT / 当面材料',
  sealed: 'SEALED RECORD / 密封存档',
  mimeo: 'MIMEOGRAPH · 公示',
  carbonless: '第一联 · 存根',
  cardstock: 'OFFICIAL RECOMMENDATION / 推荐材料',
  student_id: 'STUDENT ID / 学生证',
  id_card: 'ID CARD / 证件卡',
  scholarship: 'SCHOLARSHIP / 奖学金证书',
  admission: 'OFFICE OF ADMISSIONS / 录取通知',
  ledger: 'BURSAR LEDGER / 财务台账',
  index_card: 'ARCHIVE INDEX / 档案卡',
  passport: 'PASSPORT / 护照 · 签证页',
  boarding: 'BOARDING PASS / 登机牌',
};
const TASK_KINDS = {
  scholarship: { label: '奖学金', color: '#b08a3e' },
  honors: { label: '优毕', color: '#8b382b' },
  leave: { label: '请假', color: '#2d4d78' },
  exchange: { label: '交换', color: '#2d4d78' },
  lab: { label: '实验室', color: '#4e6d4f' },
  internship: { label: '实习', color: '#8b5a2b' },
};
const DOC_KINDS = ['application', 'transcript', 'notice', 'certificate', 'recommend', 'report', 'quota', 'leave', 'slip', 'student_id', 'id_card', 'offer', 'ledger', 'passport', 'boarding', 'generic'];
const DOC_KIND_LABEL = {
  application: '申请表',
  transcript: '成绩单',
  notice: '公示 / 通知',
  certificate: '认定 / 证书',
  recommend: '推荐表',
  report: '查重报告',
  quota: '名额 / 排序',
  leave: '请假条',
  slip: '便函 / 记录',
  student_id: '学生证',
  id_card: '身份证 / 证件卡',
  offer: '录取通知',
  ledger: '财务台账',
  passport: '护照 / 签证',
  boarding: '登机牌 / 凭证',
  generic: '通用材料',
};
const WORLD_MAP = {
  meta: 'meta',
  ruleGroups: 'RULE_GROUPS',
  tabs: 'TABS',
  extraMaterials: 'EXTRA_MATERIALS',
  outcomes: 'OUTCOMES',
  refPool: 'REF_POOL',
  nightScenes: 'NIGHT_SCENES',
  audits: 'audits',
  allocation: 'ALLOCATION',
  collegeGroups: 'COLLEGE_GROUPS',
};

const state = {
  loaded: false,
  view: 'overview',
  content: null,
  selectedLevel: 0,
  selectedCharacter: 0,
  selectedTask: 0,
  selectedDoc: 0,
  selectedChain: 0,
  selectedLogicNode: '',
  logicSelection: [],
  logicClipboard: null,
  logicUndo: [],
  logicRedo: [],
  logicZoom: 1,
  logicNodeQuery: '',
  logicChainQuery: '',
  logicCtx: {},
  logicSim: null,
  logicLinkSource: null,
  baselinePayload: null,
  pendingSave: null,
  charFilter: '',
  dirty: false,
  validation: { errors: [], warnings: [] },
  dirHandle: null,
  contentPrefix: '',
  source: '',
  dragSlot: -1,
  jsonTarget: null,
  pickerTarget: null,
};


const DIALOGUE_SPEAKERS = [
  ['student', '学生'],
  ['player', '我 / 老师'],
  ['auto', '自动回复'],
  ['system', '系统旁白'],
];

const DIALOGUE_STYLES = [
  ['', '不触发夜信'],
  ['checklist', '按清单核对'],
  ['concern', '担心提示'],
  ['desk', '先放桌上'],
];

const LOGIC_SAMPLE = {
  gpa: '3.72',
  rank: '4',
  noticeDays: '1',
  dupRate: '12.6',
  level: 'province',
  visaValid: 'true',
  ielts: '6.5',
  offer: 'true',
};

globalThis.ThesisEditor = { factories: {}, model: { $, $$, clone, esc, asArray, asText, num, FILES, LOGIC_FILE, CONTENT_VERSION, LOGIC_OPS, LOGIC_RESULTS, LOGIC_NODE_LABEL, STYLE_DEFS, STYLE_ORDER, STYLE_TEXTURE, STYLE_BAND, TASK_KINDS, DOC_KINDS, DOC_KIND_LABEL, WORLD_MAP, state, DIALOGUE_SPEAKERS, DIALOGUE_STYLES, LOGIC_SAMPLE } };
})();
