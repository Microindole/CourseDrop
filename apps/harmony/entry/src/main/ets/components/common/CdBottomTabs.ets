import { AppColors, AppShadows, AppSpacing, AppSize, AppTypography } from '../../common/Theme';

@Component
export struct CdBottomTabs {
  @Link currentIndex: number;
  private tabsController: TabsController = new TabsController();
  
  @BuilderParam homeContent: () => void = this.defaultContent;
  @BuilderParam shareContent: () => void = this.defaultContent;
  @BuilderParam libraryContent: () => void = this.defaultContent;
  @BuilderParam deviceContent: () => void = this.defaultContent;
  @BuilderParam settingsContent: () => void = this.defaultContent;
  onTabChange: (index: number) => void = (_index: number) => {};

  @Builder
  defaultContent() {}

  @State private clickedIndex: number = -1;

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
      this.currentIndex = index;
      this.tabsController.changeIndex(index);
      this.onTabChange(index);
    })
  }

  build() {
    Column() {
      // 原生 Tabs 容器，隐藏自带 tabBar，占据剩余高度
      Tabs({
        barPosition: BarPosition.End,
        controller: this.tabsController
      }) {
        TabContent() {
          this.homeContent()
        }
        .backgroundColor(AppColors.BACKGROUND)

        TabContent() {
          this.shareContent()
        }
        .backgroundColor(AppColors.BACKGROUND)

        TabContent() {
          this.libraryContent()
        }
        .backgroundColor(AppColors.BACKGROUND)

        TabContent() {
          this.deviceContent()
        }
        .backgroundColor(AppColors.BACKGROUND)

        TabContent() {
          this.settingsContent()
        }
        .backgroundColor(AppColors.BACKGROUND)
      }
      .width('100%')
      .layoutWeight(1) // 撑满除底部栏外的剩余高度
      .barHeight(0) // 完全隐藏原生 tabBar
      .scrollable(false) // 禁用滑动切换，防止与底栏状态脱节
      .onChange((index: number) => {
        this.currentIndex = index;
        this.onTabChange(index);
      })

      // 自定义高质感占位底部导航栏
      Row() {
        this.tabItem(0, $r('app.media.cd_icon_home'), '首页')
        this.tabItem(1, $r('app.media.cd_icon_share'), '分享')
        this.tabItem(2, $r('app.media.cd_icon_library'), '本地库')
        this.tabItem(3, $r('app.media.cd_icon_devices'), '设备')
        this.tabItem(4, $r('app.media.cd_icon_settings'), '设置')
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
