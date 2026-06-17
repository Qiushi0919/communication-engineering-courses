# 通信工程课程资料总览

这个仓库用于整理通信工程本科课程资料。

- GitHub 仓库：https://github.com/Qiushi0919/communication-engineering-courses
- GitHub Pages：已关闭；仓库当前为 Public。

- `main` 分支：主页与仓库说明
- `index.html`：GitHub Pages 主页
- `课程总览.html`：主页的中文备份文件名
- `course/...` 分支：每门有资料目录的课程分支
- `course-branches.json`：课程名称、分支名、资料路径映射
- `notability-course-notes.json`：Notability 课程笔记目录统计，暂不上传笔记原文件
- `scripts/create-course-branches.ps1`：根据映射重新生成课程分支

## 建议的 GitHub 设置

1. 新建一个 GitHub 仓库，建议先设为 Private。
2. 推送 `main` 分支。
3. 在 GitHub 仓库 Settings -> Pages 中选择 `main` 分支、根目录 `/`。
4. 需要课程分支时，运行：

```powershell
.\scripts\create-course-branches.ps1
```

5. 推送所有课程分支：

```powershell
git push origin main
git push origin 'course/*'
```

## 重要说明

这个文件夹包含成绩、学号、课堂资料、教材、视频和实验工程文件。`.gitignore` 默认排除了成绩单、成绩排名表、压缩包、视频和常见工程生成文件，避免超过 GitHub 100 MB 单文件限制，也减少隐私和版权风险。

如果确实要上传大型文件，建议使用 Git LFS、GitHub Releases，或继续保存在 OneDrive，只在 README 或主页里放链接。

## Notability 笔记

部分手写笔记位于 `E:\OneDrive\Notability`，不在本仓库目录下。当前已记录课程相关目录统计，但不会自动把日记、待办、入党、地图等非课程目录纳入公开仓库。
