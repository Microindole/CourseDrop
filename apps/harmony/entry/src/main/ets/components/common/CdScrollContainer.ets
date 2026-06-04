import { AppColors, AppSpacing } from '../../common/Theme';

@Component
export struct CdScrollContainer {
  showScrollBar: boolean = false;
  backgroundStyle: 'home' | 'share' | 'library' | 'device' | 'settings' | 'default' = 'default';
  @BuilderParam content: () => void = this.defaultContent;

  @Builder
  defaultContent() {}

  private resolveBaseColor(): string {
    if (this.backgroundStyle === 'home') return '#EAF2FF';
    if (this.backgroundStyle === 'share') return '#EEF4FF';
    if (this.backgroundStyle === 'library') return '#EDF8F6';
    if (this.backgroundStyle === 'device') return '#EEF7FF';
    if (this.backgroundStyle === 'settings') return '#F1F3FF';
    return AppColors.BACKGROUND_DEEP;
  }

  @Builder
  backgroundLayer() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor(this.resolveBaseColor())

        Circle()
          .width(this.backgroundStyle === 'settings' ? 260 : 220)
          .height(this.backgroundStyle === 'settings' ? 260 : 220)
          .fill(this.backgroundStyle === 'library' ? '#6610B981' : this.backgroundStyle === 'device' ? '#6600B8D9' : '#661466FF')
          .blur(70)
          .position({ x: this.backgroundStyle === 'share' ? 210 : -70, y: this.backgroundStyle === 'device' ? 110 : -80 })

        Circle()
          .width(this.backgroundStyle === 'share' ? 230 : 170)
          .height(this.backgroundStyle === 'share' ? 230 : 170)
          .fill(this.backgroundStyle === 'settings' ? '#66A78BFA' : this.backgroundStyle === 'home' ? '#6600B8D9' : '#66F59E0B')
          .blur(76)
          .position({ x: this.backgroundStyle === 'home' ? 260 : -80, y: this.backgroundStyle === 'library' ? 310 : 250 })

        Row()
          .width(this.backgroundStyle === 'device' ? 170 : 130)
          .height(2)
          .backgroundColor(this.backgroundStyle === 'settings' ? '#805B6CFF' : '#801466FF')
          .opacity(0.3)
          .rotate({ angle: this.backgroundStyle === 'library' ? -20 : 24 })
          .position({ x: this.backgroundStyle === 'share' ? 28 : 190, y: this.backgroundStyle === 'home' ? 168 : 92 })

        Row()
          .width(this.backgroundStyle === 'settings' ? 96 : 72)
          .height(this.backgroundStyle === 'settings' ? 96 : 72)
          .borderRadius(this.backgroundStyle === 'settings' ? 30 : 24)
          .border({ width: 1, color: this.backgroundStyle === 'library' ? '#3310B981' : '#331466FF' })
          .opacity(0.45)
          .rotate({ angle: this.backgroundStyle === 'device' ? 18 : -12 })
          .position({ x: this.backgroundStyle === 'library' ? 245 : 26, y: this.backgroundStyle === 'share' ? 170 : 410 })
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.backgroundLayer()

      Scroll() {
        Column({ space: AppSpacing.MD }) {
          this.content()
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .padding({
          top: AppSpacing.PAGE_TOP,
          left: AppSpacing.PAGE_HORIZONTAL,
          right: AppSpacing.PAGE_HORIZONTAL,
          bottom: AppSpacing.XL + 20
        })
      }
      .width('100%')
      .height('100%')
      .align(Alignment.TopStart)
      .scrollBar(this.showScrollBar ? BarState.Auto : BarState.Off)
    }
    .width('100%')
    .height('100%')
  }
}
