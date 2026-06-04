export class AppColors {
  static readonly BACKGROUND: string = '#EEF3FA';
  static readonly BACKGROUND_DEEP: string = '#E7EEF8';
  static readonly SETTINGS_BG: string = '#F4F6FA';
  static readonly SURFACE: string = '#FFFFFF';
  static readonly SURFACE_MUTED: string = '#EAF1FA';
  static readonly SURFACE_RAISED: string = '#F8FBFF';
  static readonly PRIMARY: string = '#1466FF';
  static readonly PRIMARY_SELECTED: string = '#0A4BDB';
  static readonly PRIMARY_SOFT: string = '#E8F1FF';
  static readonly ACCENT: string = '#00B8D9';
  static readonly ACCENT_SOFT: string = '#E6FAFF';
  static readonly TEXT: string = '#132235';
  static readonly TEXT_SECONDARY: string = '#66778C';
  static readonly MUTED: string = '#9AA8B8';
  static readonly BORDER: string = '#140A2A43';
  static readonly BORDER_STRONG: string = '#2B132235';
  static readonly SUCCESS: string = '#10B981';
  static readonly SUCCESS_SOFT: string = '#E8FFF6';
  static readonly WARNING: string = '#F59E0B';
  static readonly WARNING_SOFT: string = '#FFF5DA';
  static readonly DANGER: string = '#F04438';
  static readonly DANGER_SOFT: string = '#FFF0F0';
  static readonly TAB_NORMAL: string = '#7C8796';

  // 各内容类型的精细配色
  static readonly TONE_FILE: string = '#007DFF';
  static readonly TONE_FILE_BG: string = '#EDF5FF';
  static readonly TONE_IMAGE: string = '#FA2A2D';
  static readonly TONE_IMAGE_BG: string = '#FFF0F0';
  static readonly TONE_TEXT: string = '#F59E0B';
  static readonly TONE_TEXT_BG: string = '#FFFBEB';
  static readonly TONE_LINK: string = '#10B981';
  static readonly TONE_LINK_BG: string = '#ECFDF5';
}

export interface ShadowType {
  radius: number;
  color: string;
  offsetX: number;
  offsetY: number;
}

export class AppShadows {
  static readonly CARD: ShadowType = {
    radius: 14,
    color: '#120B2A4A',
    offsetX: 0,
    offsetY: 6
  };
  static readonly FLOATING: ShadowType = {
    radius: 24,
    color: '#1A0B2A4A',
    offsetX: 0,
    offsetY: 10
  };
}

export class AppSpacing {
  static readonly XS: number = 4;
  static readonly SM: number = 8;
  static readonly MD: number = 12;
  static readonly LG: number = 16;
  static readonly XL: number = 24;
  static readonly XXL: number = 32;
  static readonly PAGE_HORIZONTAL: number = 16;
  static readonly PAGE_TOP: number = 42;
}

export class AppRadius {
  static readonly SM: number = 8;
  static readonly MD: number = 12;
  static readonly LG: number = 18;
  static readonly XL: number = 26;
}

export class AppTypography {
  static readonly DISPLAY: number = 28;
  static readonly TITLE: number = 18;
  static readonly SUBTITLE: number = 16;
  static readonly BODY: number = 16;
  static readonly BODY_SMALL: number = 14;
  static readonly CAPTION: number = 12;
  static readonly TAB: number = 10;
}

export class AppSize {
  static readonly BUTTON_HEIGHT: number = 42;
  static readonly INPUT_HEIGHT: number = 46;
  static readonly LIST_ROW_HEIGHT: number = 48;
  static readonly TAB_BAR_HEIGHT: number = 56;
  static readonly ICON_MD: number = 24;
  static readonly ICON_LG: number = 40;
}
