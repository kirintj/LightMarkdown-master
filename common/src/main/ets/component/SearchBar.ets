@Component
export struct SearchBar {
  placeholder: string = '搜索文件';
  onSearch: (keyword: string) => void = () => {};
  onChange: (keyword: string) => void = () => {};

  build() {
    Search({ value: '', placeholder: this.placeholder })
      .width('100%')
      .height(40)
      .onChange((value: string) => { this.onChange(value); })
      .onSubmit((value: string) => { this.onSearch(value); })
  }
}
