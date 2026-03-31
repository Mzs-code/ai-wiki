# HTML 目录锚点跳转修复方案

## 问题描述

`ClaudeCode安装指南-Mac.html` 中存在两套导航：

- **左侧边栏** — HTML 导出工具自动生成，跳转正常
- **正文目录模块** — 从 Markdown 转换而来，点击无法跳转

## 原因分析

目录模块的 `href` 使用 **GitHub Markdown 锚点规则**，而 HTML 导出工具在 heading 上生成的 `<a id="">` 使用**另一套 slug 规则**，两者不匹配。

| 标题 | 目录 href | 实际 heading id | 差异点 |
|------|-----------|-----------------|--------|
| 一、检查网络情况 | `#一检查网络情况` | `一、检查网络情况` | GitHub 去掉 `、`，导出工具保留 |
| 1.1 浏览器验证 | `#11-浏览器验证` | `1-1浏览器验证` | GitHub 去掉 `.` 得 `11`，工具替换为 `-` 得 `1-1` |
| 二、安装 iTerm2 | `#二安装-iterm2` | `二、安装iterm2` | GitHub 用 `-` 分隔单词，工具直接拼接 |
| 三、安装 CC-Switch | `#三安装-cc-switch` | `三、安装cc-switch` | 同上两个差异叠加 |

### 规则对比

| 字符 | GitHub Markdown | HTML 导出工具 |
|------|----------------|---------------|
| `、` | 删除 | 保留 |
| `1.1` | 去掉 `.` → `11` | `.` 替换为 `-` → `1-1` |
| 空格 | 替换为 `-` | 删除 |
| `（）` | 删除 | 保留 |

## 解决方案

在 HTML 文件 `</body>` 前插入以下 JS 脚本，通过归一化比较实现锚点模糊匹配：

```javascript
document.addEventListener('click', function(e) {
  var link = e.target.closest('a[href^="#"]');
  if (!link) return;
  var href = decodeURIComponent(link.getAttribute('href').slice(1));
  if (document.getElementById(href)) return;
  var norm = function(s) {
    return decodeURIComponent(s).toLowerCase()
      .replace(/[、：（）()\.\-\s:~\/]/g, '');
  };
  var target = norm(href);
  var anchors = document.querySelectorAll('a[id]');
  for (var i = 0; i < anchors.length; i++) {
    if (norm(anchors[i].id) === target) {
      e.preventDefault();
      anchors[i].scrollIntoView({ behavior: 'smooth' });
      history.replaceState(null, '', '#' + anchors[i].id);
      return;
    }
  }
});
```

### 脚本逻辑

1. 拦截所有 `#` 开头的锚点链接点击
2. 如果原始 href 能直接匹配到 id，不干预，正常跳转
3. 如果匹配不到，将 href 和所有 heading id 做归一化（去掉 `、`、`：`、`（）`、`.`、`-`、空格等）后比较
4. 匹配成功则平滑滚动到目标，同时更新 URL hash

### 优势

- 不需要逐个修改 40+ 个 href
- 用户重新导出 HTML 后脚本仍然有效
- 左侧边栏不受影响
