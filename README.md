# 灵译 XJ Translator

一个现代化的Flutter翻译应用，界面精美，功能完善，支持多种翻译模式。

## 🚀 功能特色

- **多语言支持**：支持多种主流语言的即时翻译、文本翻译和语音翻译。
- **精美 UI 设计**：
  - 动态主题：支持深色/浅色模式，并可自定义主色调。
  - 胶囊式导航：底部导航栏采用创新的胶囊设计，交互流畅。
  - 流体渐变：页面各模块采用流体渐变背景，视觉效果极佳。
- **核心功能**：
  - 即时翻译：快速输入，即时查看翻译结果。
  - 文本翻译：支持多段落输入与翻译，并可进行多轮对话式翻译。
  - 语音翻译：实时语音输入识别与翻译（模拟实现）。
- **扩展功能**：
  - 文档翻译：支持文档（PDF/Word）翻译和文档管理中心（模拟实现）。
  - 图片翻译：支持图片内容提取与翻译（模拟实现）。
  - 翻译历史：自动保存历史翻译记录，方便查阅。
- **用户中心**：个人信息、设置、登录/注册功能。

## 📂 项目结构

```
xj_translator/
├── lib/
│   ├── main.dart             # 应用入口
│   ├── core/
│   │   ├── theme/
│   │   │   └── app_theme.dart  # 统一主题管理，支持动态主色和深浅色模式
│   │   └── constants/
│   │       └── app_constants.dart # 常量定义
│   ├── logic/
│   │   ├── providers/
│   │   │   ├── theme_provider.dart  # 主题状态管理
│   │   │   ├── translation_provider.dart # 翻译状态管理
│   │   │   └── auth_provider.dart   # 认证状态管理
│   │   └── services/
│   │       └── api_service.dart     # API 服务（模拟）
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── home_screen.dart       # 主页（即时翻译、文本翻译等）
│   │   │   ├── document_center_screen.dart # 文档翻译中心
│   │   │   ├── translation_history_screen.dart # 翻译历史
│   │   │   ├── user_profile_screen.dart # 用户中心
│   │   │   └── auth_screen.dart       # 登录/注册页
│   │   └── components/
│   │       ├── custom_button.dart     # 自定义按钮组件
│   │       ├── fluid_card.dart        # 流体卡片背景组件
│   │       └── language_selector.dart # 语言选择组件
│   └── data/
│       └── repositories/
│           ├── translation_repository.dart # 翻译数据仓库（模拟）
│           └── auth_repository.dart     # 认证数据仓库（模拟）
```

## 🛠️ 开发指南

### 依赖

本应用使用 `provider` 管理状态，`dio` 进行网络请求（此处主要为模拟数据），`shared_preferences` 存储数据。

```bash
flutter pub get
```

### 运行

```bash
flutter run
```

### 配置主题

修改 `lib/core/theme/app_theme.dart` 中的 `AppTheme` 类可以调整默认主题颜色和样式。

### API 模拟

所有翻译功能目前使用模拟数据返回，位于 `lib/logic/services/api_service.dart`。
如需接入真实翻译 API，请替换相关实现。
