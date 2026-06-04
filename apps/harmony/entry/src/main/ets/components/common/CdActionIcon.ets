import { AppColors, AppRadius, AppSpacing, AppTypography } from '../../common/Theme';

@Component
export struct CdActionIcon {
  icon: Resource | null = null;
  label: string = '';
  tone: string = AppColors.PRIMARY;
  bgColor: string = AppColors.PRIMARY_SOFT;
  compact: boolean = false;
  onTap: () => void = () => {};

  @State private isPressed: boolean = false;

  build() {
    Column({ space: AppSpacing.XS }) {
      Stack() {
        if (this.icon) {
          Image(this.icon)
            .width(20)
            .height(20)
            .fillColor(this.tone)
        }
      }
      .width(44)
      .height(44)
      .backgroundColor(this.bgColor)
      .borderRadius(AppRadius.LG)
      .border({ width: 0.7, color: this.tone })
      .align(Alignment.Center)

      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(AppTypography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tone)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width(this.compact ? 48 : 64)
    .alignItems(HorizontalAlign.Center)
    .scale({
      x: this.isPressed ? 0.94 : 1,
      y: this.isPressed ? 0.94 : 1
    })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event?: TouchEvent) => {
      if (event === undefined) {
        return;
      }
      if (event.type === TouchType.Down) {
        this.isPressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.isPressed = false;
      }
    })
    .onClick(() => {
      this.onTap();
    })
  }
}
