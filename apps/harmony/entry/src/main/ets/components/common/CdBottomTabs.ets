import { AppColors, AppShadows, AppSpacing, AppSize, AppTypography } from '../../common/Theme';

@Component
export struct CdBottomTabs {
  @Link @Watch('onCurrentIndexChange') currentIndex: number;
  
  @BuilderParam homeContent: () => void = this.defaultContent;
  @BuilderParam shareContent: () => void = this.defaultContent;
  @BuilderParam libraryContent: () => void = this.defaultContent;
  @BuilderParam settingsContent: () => void = this.defaultContent;
  onTabChange: (index: number) => void = (_index: number) => {};

  @Builder
  defaultContent() {}

  @State private clickedIndex: number = -1;
  @State private displayIndex: number = 0;
  @State private previousIndex: number = 0;
  @State private targetIndex: number = 0;
  @State private transitionProgress: number = 1;

  aboutToAppear() {
    this.displayIndex = this.currentIndex;
    this.previousIndex = this.currentIndex;
    this.targetIndex = this.currentIndex;
    this.transitionProgress = 1;
  }

  private onCurrentIndexChange(_propName: string) {
    this.startContentTransition(this.currentIndex);
  }

  private startContentTransition(index: number) {
    if (index === this.targetIndex && this.transitionProgress < 1) {
      return;
    }
    if (index === this.displayIndex && this.transitionProgress === 1) {
      return;
    }
    this.previousIndex = this.displayIndex;
    this.targetIndex = index;
    this.transitionProgress = 0;
    animateTo({ duration: 120, curve: Curve.EaseOut }, () => {
      this.displayIndex = index;
    });
    animateTo({ duration: 260, curve: Curve.FastOutSlowIn }, () => {
      this.transitionProgress = 1;
    });
  }

  private switchTab(index: number) {
    if (index === this.currentIndex && index === this.displayIndex) {
      return;
    }
    this.startContentTransition(index);
    this.currentIndex = index;
    this.onTabChange(index);
  }

  private transitionOffset(): number {
    if (this.displayIndex >= this.previousIndex) {
      return (1 - this.transitionProgress) * 22;
    }
    return (1 - this.transitionProgress) * -22;
  }

  @Builder
  tabItem(index: number, icon: Resource, label: string) {
    Column({ space: 2 }) {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor(this.currentIndex === index ? AppColors.PRIMARY : AppColors.TAB_NORMAL)
        .scale({
          x: this.currentIndex === index ? 1.1 : 1.0,
          y: this.currentIndex === index ? 1.1 : 1.0
        })
        .animation({ duration: 200, curve: Curve.FastOutSlowIn })

      Text(label)
        .fontSize(AppTypography.TAB)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.currentIndex === index ? AppColors.PRIMARY : AppColors.TAB_NORMAL)

      // 底部呼吸小圆点
      Row()
        .width(4)
        .height(4)
        .borderRadius(2)
        .backgroundColor(AppColors.ACCENT)
        .opacity(this.currentIndex === index ? 1 : 0)
        .scale({
          x: this.currentIndex === index ? 1 : 0,
          y: this.currentIndex === index ? 1 : 0
        })
        .animation({ duration: 250, curve: Curve.FastOutSlowIn })
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .scale({
      x: this.clickedIndex === index ? 0.92 : 1.0,
      y: this.clickedIndex === index ? 0.92 : 1.0
    })
    .animation({ duration: 100, curve: Curve.EaseOut })
    .onTouch((event?: TouchEvent) => {
      if (event) {
        if (event.type === TouchType.Down) {
          this.clickedIndex = index;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.clickedIndex = -1;
        }
      }
    })
    .onClick(() => {
      this.switchTab(index);
    })
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          if (this.displayIndex === 0) {
            this.homeContent()
          } else if (this.displayIndex === 1) {
            this.shareContent()
          } else if (this.displayIndex === 2) {
            this.libraryContent()
          } else {
            this.settingsContent()
          }
        }
        .width('100%')
        .height('100%')
        .opacity(this.transitionProgress)
        .translate({ x: this.transitionOffset(), y: 0 })
        .animation({ duration: 260, curve: Curve.FastOutSlowIn })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(AppColors.BACKGROUND)

      // 自定义高质感占位底部导航栏
      Row() {
        this.tabItem(0, $r('app.media.cd_icon_home'), '首页')
        this.tabItem(1, $r('app.media.cd_icon_share'), '分享')
        this.tabItem(2, $r('app.media.cd_icon_library'), '本地库')
        this.tabItem(3, $r('app.media.cd_icon_settings'), '设置')
      }
      .width('100%')
      .height(66)
      .backgroundColor(AppColors.SURFACE_RAISED)
      .border({
        width: { top: 0.5 },
        color: AppColors.BORDER
      })
      .shadow(AppShadows.FLOATING)
      .padding({ bottom: 4 }) // 避开全面屏底部指示条
    }
    .width('100%')
    .height('100%')
  }
}
