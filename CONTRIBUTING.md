# 参与贡献

感谢你帮助改进菲比。提交改动前，请先确认问题或提案与 Codex Desktop 自定义桌宠有关，并尽量保持改动范围小而清晰。

## 开发流程

1. Fork 仓库并从 `main` 创建分支。
2. 修改后在 Windows PowerShell 5.1 或更高版本运行：

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\tests\Test-Package.ps1
   ```

3. 确认仓库中没有本机绝对路径、生成提示词、调试素材或个人信息。
4. 提交 Pull Request，说明动机、影响范围和验证结果。动画或外观变更请附预览图或 GIF。

## 资源与兼容性

- 保持包 ID 为 `feibi`，除非维护者明确决定进行不兼容迁移。
- `pet.json` 与 `spritesheet.webp` 必须作为一套资源同步更新。
- 安装脚本只能处理菲比自己的目标目录，不得修改其他桌宠或更广泛的 Codex 配置。
- 新增的代码与资源应能按项目的 MIT License 分发；请勿提交无权再分发的内容。

安全漏洞请按 [SECURITY.md](SECURITY.md) 私下报告，不要提交公开 Issue。

