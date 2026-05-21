# 项目资料同步说明

## 已纳入仓库同步

PDF 原始资料通过 Git LFS 管理，避免超过 GitHub 普通 Git 的单文件限制：

- `画册扫描.pdf`
- `上实集团成立45周年特别活动策划方案0505.pdf`
- `上实集团“十五五”发展规划0323职代会vfinal.pdf`

## 不纳入仓库同步

- `work/pages/`

该目录为 PDF 渲染导出的页面图片，体积较大且可由脚本重新生成，因此保留在本地，不随仓库提交。

## 重新生成页面图片

```powershell
node scripts/render-pdf-pages.mjs
```
