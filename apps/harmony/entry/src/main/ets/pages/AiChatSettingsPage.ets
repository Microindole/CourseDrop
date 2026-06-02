import router from '@ohos.router';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../common/Theme';
import { AiChatViewModel } from '../viewmodels';
import type { AiChatConfigForm } from '../viewmodels';

@Entry
@Component
struct AiChatSettingsPage {
  private viewModel: AiChatViewModel = new AiChatViewModel();

  @State aiEnabled: boolean = false;
  @State apiKey: string = '';
  @State baseUrl: string = '';
  @State model: string = '';
  @State thinkingEnabled: boolean = false;
  @State autoAnalyzeFiles: boolean = false;
  @State statusText: string = '';

  aboutToAppear(): void {
    const config = this.viewModel.getConfig();
    this.aiEnabled = config.enabled;
    this.apiKey = config.apiKey;
    this.baseUrl = config.baseUrl;
    this.model = config.model;
    this.thinkingEnabled = config.thinkingEnabled;
    this.autoAnalyzeFiles = config.autoAnalyzeFiles;
  }

  private save(): void {
    const form: AiChatConfigForm = {
      enabled: this.aiEnabled,
      apiKey: this.apiKey,
      baseUrl: this.baseUrl,
      model: this.model,
      thinkingEnabled: this.thinkingEnabled,
      autoAnalyzeFiles: this.autoAnalyzeFiles
    };
    this.viewModel.saveConfig(form);
    this.statusText = '已保存 DeepSeek 配置';
  }

  @Builder
  HeaderIcon(icon: Resource, onTap: () => void) {
    Stack() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(AppColors.TEXT)
    }
    .width(42)
    .height(42)
    .borderRadius(21)
    .onClick(() => {
      onTap();
    })
  }

  @Builder
  InputRow(label: string, placeholder: string, value: string, onChange: (value: string) => void) {
    Column({ space: 8 }) {
      Text(label)
        .fontSize(AppTypography.CAPTION)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_SECONDARY)

      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(46)
        .fontSize(AppTypography.BODY_SMALL)
        .fontColor(AppColors.TEXT)
        .placeholderColor(AppColors.MUTED)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(AppRadius.MD)
        .border({ width: 0.7, color: AppColors.BORDER })
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .onChange((next: string) => {
          onChange(next);
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SwitchRow(title: string, description: string, value: boolean, onChange: (value: boolean) => void) {
    Row({ space: AppSpacing.MD }) {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(AppTypography.BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)

        Text(description)
          .fontSize(AppTypography.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .lineHeight(18)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(AppColors.PRIMARY)
        .onChange((next: boolean) => {
          onChange(next);
        })
    }
    .width('100%')
  }

  build() {
    Column() {
      Row() {
        this.HeaderIcon($r('app.media.cd_icon_prev'), () => {
          router.back();
        })

        Text('AI 配置')
          .fontSize(AppTypography.BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        this.HeaderIcon($r('app.media.cd_icon_done'), () => {
          this.save();
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 8, right: 8 })
      .backgroundColor(AppColors.SURFACE)

      Scroll() {
        Column({ space: AppSpacing.LG }) {
          Text('DeepSeek')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT)

          Text('默认按普通文本聊天回答；文件分析是可选能力，不会强制要求文件。')
            .fontSize(AppTypography.BODY_SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .lineHeight(20)

          this.SwitchRow('启用 AI 助手', '关闭后不会请求模型接口。', this.aiEnabled, (value: boolean) => {
            this.aiEnabled = value;
          })

          this.InputRow('API Key', 'sk-...', this.apiKey, (value: string) => {
            this.apiKey = value;
          })

          this.InputRow('Base URL', 'https://api.deepseek.com', this.baseUrl, (value: string) => {
            this.baseUrl = value;
          })

          this.InputRow('模型', 'deepseek-v4-flash', this.model, (value: string) => {
            this.model = value;
          })

          this.SwitchRow('思考模式', '开启后会传递 DeepSeek thinking 参数。', this.thinkingEnabled, (value: boolean) => {
            this.thinkingEnabled = value;
          })

          this.SwitchRow('自动分析文件', '默认关闭。开启后，后续接入附件时会自动读取可解析文件。', this.autoAnalyzeFiles, (value: boolean) => {
            this.autoAnalyzeFiles = value;
          })

          if (this.statusText.length > 0) {
            Text(this.statusText)
              .fontSize(AppTypography.BODY_SMALL)
              .fontColor(AppColors.SUCCESS)
              .padding(12)
              .backgroundColor(AppColors.SUCCESS_SOFT)
              .borderRadius(AppRadius.MD)
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 20, right: 20, top: 24, bottom: 28 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND_DEEP)
  }
}
