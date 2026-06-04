import { AppColors, AppRadius, AppSize, AppSpacing, AppTypography } from '../../common/Theme';

@Component
export struct CdTextField {
  label: string = '';
  placeholder: string = '';
  obscure: boolean = false;
  @Link value: string;

  build() {
    Column({ space: AppSpacing.XS }) {
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(AppTypography.CAPTION)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_SECONDARY)
      }

      TextInput({ placeholder: this.placeholder, text: this.value })
        .width('100%')
        .height(AppSize.INPUT_HEIGHT)
        .type(this.obscure ? InputType.Password : InputType.Normal)
        .fontSize(AppTypography.BODY_SMALL)
        .fontColor(AppColors.TEXT)
        .placeholderColor(AppColors.MUTED)
        .backgroundColor(AppColors.SURFACE)
        .borderRadius(AppRadius.MD)
        .border({ width: 0.7, color: AppColors.BORDER })
        .padding({ left: AppSpacing.MD, right: AppSpacing.MD })
        .onChange((val: string) => {
          this.value = val;
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
