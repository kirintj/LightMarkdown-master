export function showDeleteConfirm(
  uiContext: UIContext,
  fileName: string,
  onConfirm: () => void
): void {
  uiContext.showAlertDialog({
    title: '确认删除',
    message: `确定要删除「${fileName}」吗？此操作不可恢复。`,
    autoCancel: true,
    alignment: DialogAlignment.Center,
    primaryButton: {
      value: '取消',
      action: () => {}
    },
    secondaryButton: {
      value: '删除',
      action: () => { onConfirm(); }
    }
  });
}
