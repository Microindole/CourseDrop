import router from '@ohos.router';
import { AppColors, AppRadius, AppSpacing, AppTypography } from '../common/Theme';

@Entry
@Component
struct SplashPage {
  @State private logoScale: number = 0.82;
  @State private logoOpacity: number = 0;
  @State private titleOpacity: number = 0;
  @State private titleOffset: number = 18;
  @State private progressWidth: number = 22;

  aboutToAppear() {
    animateTo({ duration: 420, curve: Curve.EaseOut }, () => {
      this.logoScale = 1;
      this.logoOpacity = 1;
    });
    animateTo({ duration: 560, delay: 120, curve: Curve.EaseOut }, () => {
      this.titleOpacity = 1;
      this.titleOffset = 0;
    });
    animateTo({ duration: 760, delay: 240, curve: Curve.EaseInOut }, () => {
      this.progressWidth = 118;
    });
    setTimeout(() => {
      router.replaceUrl({ url: 'pages/HomePage' });
    }, 980);
  }

  build() {
    Stack() {
      Column() {
        Blank()

        Column({ space: AppSpacing.LG }) {
          Stack() {
            Image($r('app.media.start_icon'))
              .width(96)
              .height(96)
              .scale({ x: this.logoScale, y: this.logoScale })
              .opacity(this.logoOpacity)
          }
          .width(132)
          .height(132)
          .backgroundColor(AppColors.SURFACE)
          .borderRadius(36)
          .shadow({
            radius: 24,
            color: '#241466FF',
            offsetX: 0,
            offsetY: 12
          })

          Column({ space: AppSpacing.SM }) {
            Text('CourseDrop')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT)
              .opacity(this.titleOpacity)
              .translate({ y: this.titleOffset })

            Text('课递')
              .fontSize(AppTypography.BODY_SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
              .opacity(this.titleOpacity)
              .translate({ y: this.titleOffset })
          }
          .alignItems(HorizontalAlign.Center)

          Stack({ alignContent: Alignment.Start }) {
            Row()
              .width(118)
              .height(5)
              .backgroundColor('#D8E8FF')
              .borderRadius(AppRadius.SM)

            Row()
              .width(this.progressWidth)
              .height(5)
              .backgroundColor(AppColors.PRIMARY)
              .borderRadius(AppRadius.SM)
          }
          .width(118)
          .height(5)
          .opacity(this.titleOpacity)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)

        Blank()
      }
      .width('100%')
      .height('100%')
      .padding({ left: AppSpacing.XL, right: AppSpacing.XL })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#EEF7FF')
  }
}
