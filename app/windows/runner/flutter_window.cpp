#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Window class name of a standard Win32 modal dialog. The printing plugin
// opens its "Print Setup" dialog through the standard PrintDlg (COMMDLG),
// which is an instance of this class.
constexpr wchar_t kStandardDialogClassName[] = L"#32770";

// Search context passed to the window enumeration callback.
struct DialogSearchContext {
  DWORD process_id = 0;
  HWND dialog = nullptr;
};

// Locates a standard modal dialog owned by this process. Used to dismiss the
// printing plugin's Print Setup dialog before the window teardown begins.
BOOL CALLBACK FindStandardDialogProc(HWND window, LPARAM lparam) {
  auto* context = reinterpret_cast<DialogSearchContext*>(lparam);
  DWORD window_process_id = 0;
  GetWindowThreadProcessId(window, &window_process_id);
  if (window_process_id != context->process_id) {
    return TRUE;
  }
  wchar_t class_name[128] = {};
  if (GetClassNameW(window, class_name, 128) == 0) {
    return TRUE;
  }
  if (wcscmp(class_name, kStandardDialogClassName) != 0) {
    return TRUE;
  }
  context->dialog = window;
  return FALSE;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_CLOSE: {
      // The printing plugin's Print Setup dialog is a standard modal dialog
      // (PrintDlg) that runs a nested message loop while the plugin's
      // printPdf flow is in flight. If that dialog is still open when the
      // window is torn down, the controller (and with it the channel
      // messenger) is destroyed while printPdf is still running, and the
      // plugin's next InvokeMethod use-after-frees the messenger.
      //
      // Dismiss the dialog first (IDCANCEL ends PrintDlg), so the print flow
      // completes while the messenger is still alive, then re-post WM_CLOSE
      // and continue through the normal destroy path. The modal loop sees the
      // IDCANCEL before the re-posted WM_CLOSE, so the flow has fully unwound
      // by the time this handler runs again.
      DialogSearchContext context{GetCurrentProcessId(), nullptr};
      EnumWindows(FindStandardDialogProc, reinterpret_cast<LPARAM>(&context));
      if (context.dialog) {
        if (!close_pending_) {
          close_pending_ = true;
          ShowWindow(hwnd, SW_HIDE);
          PostMessageW(context.dialog, WM_COMMAND, IDCANCEL, 0);
          PostMessageW(hwnd, WM_CLOSE, 0, 0);
        }
        return 0;
      }
      break;
    }
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
