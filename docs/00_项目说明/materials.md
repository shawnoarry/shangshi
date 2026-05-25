# 项目资料同步说明

本仓库的资料分两类：原始大文件用 Git LFS 管理；可检索、可复用的文本成果直接纳入 Git。这样远程推送后，其他设备克隆下来就能继续查资料、写方案，不需要重新跑完整 OCR。

如果需要判断当前资料、旧稿、灵感稿和正式大纲的取用优先级，先看 `工作流程与资料取用规则.md`。

## 已纳入仓库同步

### 原始资料

以下 PDF 通过 Git LFS 管理，避免超过 GitHub 普通 Git 的单文件限制：

- `画册扫描.pdf`
- `上实集团成立45周年特别活动策划方案0505.pdf`
- `上实集团“十五五”发展规划0323职代会vfinal.pdf`

### OCR 文本

以下文件由本项目 PDF 资料 OCR / 文本抽取生成，已纳入普通 Git 跟踪，便于跨设备直接检索：

- `work/上实百廿.txt`
- `work/上实百廿.pages.jsonl`
- `work/45周年策划方案.txt`
- `work/45周年策划方案.pages.jsonl`
- `work/十五五规划.txt`
- `work/十五五规划.pages.jsonl`

`txt` 适合全文阅读和搜索；`jsonl` 保留了分页结构，后续如果要按页码追溯事实依据会更方便。OCR 文本已经做了基础清洗，但仍可能存在识别错误，涉及年份、人名、金额、机构名时仍建议回看 PDF 原页确认。

## 不纳入仓库同步

- `node_modules/`
- `package-lock.json`
- `work/pages/`
- `work/*.ocr.*`

`work/pages/` 是 PDF 渲染导出的页面图片，体积较大且可由脚本重新生成，因此保留在本地，不随仓库提交。

## 其他设备克隆复用

首次使用建议先安装 Git LFS，然后克隆仓库：

```powershell
git lfs install
git clone https://github.com/shawnoarry/shangshi.git
cd shangshi
git lfs pull
```

克隆完成后，`docs/` 中的策划文档和 `work/` 中的可检索文本可直接使用；只有在需要重新 OCR 或重建页面图片时，才需要安装 Node 依赖并运行生成脚本。

当前仓库不要求安装新的 npm 依赖或 agent skill；已有脚本依赖以 `package.json` 和 `工作流程与资料取用规则.md` 为准。

## 重新生成 OCR

```powershell
npm.cmd install
node scripts/render-pdf-pages.mjs "画册扫描.pdf" work/pages 1-264 1800
powershell -ExecutionPolicy Bypass -File scripts/ocr-windows-pages.ps1 -InputDir work/pages -OutText work/上实百廿.txt -OutJsonl work/上实百廿.pages.jsonl
```
