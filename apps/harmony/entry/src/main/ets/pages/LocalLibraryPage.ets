import router from '@ohos.router';
import { AppColors, AppSpacing, AppTypography } from '../common/Theme';
import {
  CdBanner,
  CdButton,
  CdSearchField,
  CdSegmentedControl,
  CdSectionHeader,
  CdTopBar,
  CdLocalFileCard,
  CdLocalLibraryActions,
  CdLocalFileDetailDrawer,
  CdLocalFileActionBar,
  CdScrollContainer
} from '../components/index';
import { LocalFileEntry } from '../models/LocalFileEntry';
import { LocalLibraryViewModel, LocalLibraryFilter } from '../viewmodels/LocalLibraryViewModel';

@Component
export default struct LocalLibraryPage {
  showBack: boolean = true;
  onSharePrepared: () => void = () => {};
  private viewModel: LocalLibraryViewModel = new LocalLibraryViewModel();

  @State files: LocalFileEntry[] = [];
  @State selectedIds: string[] = [];
  @State isEditMode: boolean = false;
  @State filter: LocalLibraryFilter = 'ALL';
  @State keyword: string = '';
  @State selectedFile: LocalFileEntry | null = null;
  @State bannerText: string = '本地文件库充当内容缓存，可以在多选模式下快速完成批量归档与撤销';
  @State isBannerError: boolean = false;
  @State segmentIndex: number = 0;
  @State currentPage: number = 1;
  private pageSize: number = 5;

  aboutToAppear() {
    this.refreshFiles();
  }

  private refreshFiles() {
    this.files = this.viewModel.loadFiles();
  }

  private getFilteredFiles(): LocalFileEntry[] {
    return this.viewModel.getFilteredFiles(this.files, this.filter, this.keyword);
  }

  private getTotalPages(): number {
    const totalCount = this.getFilteredFiles().length;
    if (totalCount === 0) {
      return 1;
    }
    return Math.ceil(totalCount / this.pageSize);
  }

  private getPagedFiles(): LocalFileEntry[] {
    const safePage = Math.min(Math.max(this.currentPage, 1), this.getTotalPages());
    const startIndex = (safePage - 1) * this.pageSize;
    return this.getFilteredFiles().slice(startIndex, startIndex + this.pageSize);
  }

  private resetPage(): void {
    this.currentPage = 1;
  }

  private clampPage(): void {
    const totalPages = this.getTotalPages();
    if (this.currentPage > totalPages) {
      this.currentPage = totalPages;
    }
    if (this.currentPage < 1) {
      this.currentPage = 1;
    }
  }

  private isAllSelected(): boolean {
    const filtered = this.getFilteredFiles();
    if (filtered.length === 0) return false;
    return filtered.every(file => this.selectedIds.includes(file.id));
  }

  private toggleSelectAll() {
    if (this.isAllSelected()) {
      this.selectedIds = [];
    } else {
      this.selectedIds = this.getFilteredFiles().map(file => file.id);
    }
  }

  @Builder
  PaginationBar() {
    if (this.getTotalPages() > 1) {
      Row({ space: AppSpacing.MD }) {
        CdButton({
          label: '上一页',
          variant: 'tonal',
          interactive: this.currentPage > 1,
          onTap: () => {
            if (this.currentPage > 1) {
              this.currentPage -= 1;
            }
          }
        })
        .layoutWeight(1)

        Text(`${this.currentPage} / ${this.getTotalPages()}`)
          .fontSize(AppTypography.BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        CdButton({
          label: '下一页',
          variant: 'tonal',
          interactive: this.currentPage < this.getTotalPages(),
          onTap: () => {
            if (this.currentPage < this.getTotalPages()) {
              this.currentPage += 1;
            }
          }
        })
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      CdScrollContainer({ showScrollBar: true, backgroundStyle: 'library' }) {
        CdTopBar({
          title: '本地文件库',
          subtitle: `管理本机已索引的 ${this.getFilteredFiles().length} 项内容`,
          leadingText: this.showBack ? '返回' : '',
          trailingText: this.isEditMode ? '取消' : '批量管理',
          onLeadingTap: () => {
            router.back();
          },
          onTrailingTap: () => {
            animateTo({ duration: 200 }, () => {
              this.isEditMode = !this.isEditMode;
              if (!this.isEditMode) {
                this.selectedIds = [];
              }
            });
          }
        })

        CdBanner({
          title: this.bannerText,
          description: '本地文件由应用专属目录管理，只有生成分享或直连传输时才进入发送流程。',
          tone: this.isBannerError ? 'danger' : 'info'
        })

        CdLocalLibraryActions({
          isEditMode: this.isEditMode,
          onImportFile: () => {
            this.viewModel.importFiles('FILE').then((msg) => {
              this.bannerText = msg;
              this.isBannerError = false;
              this.refreshFiles();
              this.clampPage();
            });
          },
          onImportMedia: () => {
            this.viewModel.importFiles('IMAGE').then((msg) => {
              this.bannerText = msg;
              this.isBannerError = false;
              this.refreshFiles();
              this.clampPage();
            });
          },
          onCreateDebug: () => {
            const msg = this.viewModel.createDebugTextFile();
            this.bannerText = msg;
            this.isBannerError = false;
            this.refreshFiles();
            this.clampPage();
          }
        })

        CdSearchField({
          placeholder: '搜索本地库文件名',
          value: $keyword,
          onChangeValue: (value: string) => {
            this.keyword = value;
            this.resetPage();
          }
        })

        CdSegmentedControl({
          options: ['全部', '文件', '图片', '文本', '链接'],
          selectedIndex: $segmentIndex,
          onChange: (index: number) => {
            if (index === 1) this.filter = 'FILE';
            else if (index === 2) this.filter = 'IMAGE';
            else if (index === 3) this.filter = 'TEXT';
            else if (index === 4) this.filter = 'LINK';
            else this.filter = 'ALL';
            this.resetPage();
          }
        })

        CdSectionHeader({
          title: this.isEditMode ? '选择文件内容' : '全部文件列表',
          actionText: this.isEditMode ? (this.isAllSelected() ? '取消全选' : '全选') : '',
          onAction: () => {
            if (this.isEditMode) {
              this.toggleSelectAll();
            }
          }
        })

        // 文件卡片列表
        Column({ space: AppSpacing.MD }) {
          if (this.getFilteredFiles().length === 0) {
            Column({ space: AppSpacing.MD }) {
              Image($r('app.media.cd_icon_library'))
                .width(44)
                .height(44)
                .fillColor(AppColors.MUTED)

              Text(this.keyword.length > 0 ? '无相关搜索结果' : '本地文件库暂无内容')
                .fontSize(AppTypography.BODY)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.TEXT)

              Text(this.keyword.length > 0 ? '请更换搜索词重新输入' : '您可以点击上方导入按钮导入文件，或者生成模拟测试项。')
                .fontSize(AppTypography.BODY_SMALL)
                .fontColor(AppColors.TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
                .lineHeight(18)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ top: AppSpacing.XL, bottom: AppSpacing.XL })
          } else {
            ForEach(this.getPagedFiles(), (file: LocalFileEntry) => {
              CdLocalFileCard({
                file: file,
                isEditMode: this.isEditMode,
                selectedIds: $selectedIds,
                selectedFile: $selectedFile
              })
            }, (file: LocalFileEntry) => file.id)
          }
        }
        .width('100%')
        .padding({ bottom: this.isEditMode ? 100 : 40 })

        this.PaginationBar();
      }

      // 悬浮多选批量控制栏
      if (this.isEditMode && this.selectedIds.length > 0) {
        CdLocalFileActionBar({
          isEditMode: this.isEditMode,
          selectedIds: $selectedIds,
          isAllSelected: this.isAllSelected(),
          onShareSelected: () => {
            const msg = this.viewModel.shareSelected(this.selectedIds);
            this.bannerText = msg;
            this.isBannerError = false;
            this.selectedIds = [];
            this.isEditMode = false;
            this.refreshFiles();
            this.clampPage();
            this.onSharePrepared();
          },
          onDeleteSelected: () => {
            const msg = this.viewModel.deleteSelected(this.selectedIds);
            this.bannerText = msg;
            this.isBannerError = false;
            this.selectedIds = [];
            this.isEditMode = false;
            this.refreshFiles();
            this.clampPage();
          }
        })
      }

      // 详细查看 Sheet 面板
      if (this.selectedFile !== null) {
        CdLocalFileDetailDrawer({
          selectedFile: $selectedFile,
          onShare: (id) => {
            const msg = this.viewModel.shareSelected([id]);
            this.bannerText = msg;
            this.isBannerError = false;
            this.refreshFiles();
            this.clampPage();
            this.onSharePrepared();
          },
          onDelete: (id) => {
            const msg = this.viewModel.deleteSelected([id]);
            this.bannerText = msg;
            this.isBannerError = false;
            this.refreshFiles();
            this.clampPage();
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
