# 四象限待办

一个 Android 优先的「重要-紧急」四象限待办与日程应用，使用 Flutter 构建。

## 功能

- **标准四象限**：横轴「重要」向右增强，纵轴「紧急」向上增强；Q1 右上（立即做）、Q2 左上（尽快做）、Q3 左下（暂缓做）、Q4 右下（计划做）。坐标轴文字只出现一次。
- **两类事件**：任务与日程共用同一模型。日程包含开始时间、结束时间、地点；日程转为任务时会二次确认，并把时间与地点保留在描述中，不丢数据。
- **北京时间**：所有时间按 Asia/Shanghai 展示和选择，24 小时制，支持跨天日程，结束时间不得早于开始时间。
- **四象限卡片**：每个象限都有「全部」和「添加」入口；未完成的事件始终显示，已完成事件默认折叠为最近 2 条，可展开。
- **排序稳定**：未完成事件按日程开始时间、任务创建时间升序，再按创建时间、ID 打破平局；已完成事件按完成时间降序，再按创建时间、ID 打破平局。
- **完整操作**：新增、查看详情、编辑、完成/取消完成、删除（带确认）、修改重要/紧急属性以移动象限。
- **移动端界面**：Material 3，浅色/深色/跟随系统主题，窄屏、大字号、长文本与长列表均可用。
- **本地持久化**：SQLite 存储，UTC 毫秒时间戳；数据库结构带版本号、约束和显式迁移保护，读取失败时显示错误且不会自动清空数据。
- **测试**：领域规则、时区、排序、控制器、SQLite 仓储、主要页面交互均有自动化测试。

## 四象限映射

| 象限 | 位置 | 重要 | 紧急 | 标题 |
| --- | --- | --- | --- | --- |
| Q1 | 右上 | 是 | 是 | 立即做 |
| Q2 | 左上 | 否 | 是 | 尽快做 |
| Q3 | 左下 | 否 | 否 | 暂缓做 |
| Q4 | 右下 | 是 | 否 | 计划做 |

## 技术栈

- Flutter 3.47.7 / Dart 3.13.5
- Material 3
- `sqflite`（Android SQLite）
- `timezone`（Asia/Shanghai）
- `shared_preferences`（主题偏好）
- `uuid`（事件 ID）
- `intl`（时间格式化）
- 状态管理：`ChangeNotifier` + 注入式仓储，不引入额外状态框架
- 测试：`flutter_test`、`sqflite_common_ffi`、`integration_test`

## 目录结构

```text
lib/
  main.dart                 应用入口与依赖装配
  app.dart                  MaterialApp、主题、本地化
  application/
    event_controller.dart   事件状态、CRUD、排序入口
  core/
    beijing_time.dart       北京时间转换与格式化
  data/
    app_database.dart       SQLite 连接、建表、迁移保护
    sqlite_event_repository.dart
    settings_repository.dart
  domain/
    event.dart              Event / EventDraft / ScheduleDetails
    quadrant.dart           四象限映射
    event_sorting.dart      未完成/已完成排序
    event_validation.dart   输入校验
    event_conversion.dart   日程转任务的数据保留
    event_repository.dart   仓储接口
  ui/
    home/                   四象限首页与卡片
    event/                  编辑器、详情页
    quadrant/               单象限全部列表
    widgets/event_tile.dart 事件行
    theme/                  主题与象限配色
test/                       单元测试与 Widget 测试
integration_test/           模拟器/真机集成测试
```

## 运行与构建

项目在 `android/app/build.gradle.kts` 中显式固定 NDK 30.0.16248370。
构建过程中 Android 工具链曾自动安装 NDK 28.2.13676358 与 CMake 3.22.1。

构建相关的项目内配置：

- `pubspec.yaml` 的 `hooks.user_defines.sqlite3` 设为 `source: system`：宿主机测试使用 Windows 自带的
  `winsqlite3.dll`，Android 使用系统 `libsqlite3.so`，避免构建时从 GitHub 下载原生库。
- `android/gradle.properties` 设置 `kotlin.incremental=false`：pub 缓存在 D 盘、项目在 C 盘时，
  Kotlin 增量编译缓存会因不同盘符根路径报错。

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

构建安装包：

```bash
flutter build apk --debug
flutter build apk --release
```

产物路径：

- Debug：`build/app/outputs/flutter-apk/app-debug.apk`
- Release：`build/app/outputs/flutter-apk/app-release.apk`

Release 构建目前沿用 Flutter 模板的 debug 签名配置，仅适合本地安装验证；正式发布前需要配置自己的签名。

## 数据存储与迁移

- 数据库文件：应用私有目录下的 `quadrant_todo.db`。
- 所有时间以 UTC 毫秒存储，展示时转为 Asia/Shanghai。
- `events` 表包含标题、描述、重要/紧急布尔值、创建/更新/完成时间、日程开始/结束时间与地点。
- 数据库版本为 1。升级时若无对应迁移步骤会直接报错，降级同样报错，均不会删除用户数据。
- 读取到损坏行时，仓储抛出带事件 ID 的 `FormatException`；首页展示错误和重试按钮，数据文件保留。

## 测试

```bash
flutter analyze
flutter test
flutter test integration_test -d emulator-5554
```

当前自动化测试覆盖（宿主机共 59 个测试，另有 1 个设备端集成测试）：

- 四象限映射与轴属性
- 事件/日程模型、校验、类型转换的数据保留
- 未完成与已完成排序及平局规则
- 北京时间转换、24 小时格式、跨天判断、默认开始时间
- 控制器加载、错误处理、增删改、完成切换、通知
- SQLite 往返、更新/删除、重开持久化、约束、损坏行只读报错
- 首页轴标签唯一性、四象限入口、未完成优先、完成折叠、复选框与详情点击分离、新增、删除确认、主题切换、窄屏与大字号
- 编辑器默认日程、必填校验、日程转任务确认/取消、任务切换无噪声、象限预览

## 已知限制

- 仅针对 Android 构建与验证；其他平台未验证。
- 没有提醒/通知、重复日程、搜索、拖拽换象限等扩展功能。
- Release APK 使用模板 debug 签名。
- 主题选择的读取失败会回退到跟随系统，但不会提示用户。
- 集成测试依赖已启动的 Android 模拟器；CI 中需要另行配置设备。

## 交付物

- 源码：本目录
- Debug APK：`build/app/outputs/flutter-apk/app-debug.apk`（约 190 MB）
- Release APK：`build/app/outputs/flutter-apk/app-release.apk`（约 54 MB，53.1 MB）
- Release SHA-256：`6043712af3eff149a24f1351c47f9b5ef5ec8d1b24c8bbf3d725f8911230a021`
- Debug SHA-256：`27cdfc048840c6d836309255fe59acb590da96a2a60b9caff7c1d220c997f500`
- 测试与手动验证结果见本次交付说明。
