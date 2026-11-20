using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Input;
using PomoPet.App.Services;
using PomoPet.Core;
using Windows.System;

namespace PomoPet.App.Windows;

public sealed partial class BreakOverlayWindow : Window
{
    private readonly PomodoroEngine _engine;
    private readonly PixelSpriteCatalog _catalog;

    public BreakOverlayWindow(PomodoroEngine engine, PixelSpriteCatalog catalog)
    {
        InitializeComponent();
        _engine = engine;
        _catalog = catalog;

        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        var windowId = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(hwnd);
        var appWindow = AppWindow.GetFromWindowId(windowId);
        appWindow.SetPresenter(AppWindowPresenterKind.FullScreen);
    }

    public void UpdateFrame(int animTick)
    {
        OverlayTagText.Text = _engine.Phase == TimerPhase.LongBreak
            ? "LONG BREAK • UNWIND"
            : "TIME TO REST";
        OverlayTimerText.Text = _engine.FormattedTime;
        PromptTitleText.Text = _engine.CurrentStretchPrompt.Title;
        PromptSubtitleText.Text = _engine.CurrentStretchPrompt.Subtitle;

        var frame = _catalog.GetFrame(_engine.Settings.SelectedPet, _engine.PetAnimationState, animTick);
        if (frame is not null)
        {
            OverlayPetImage.Source = PixelBitmapRenderer.ToWriteableBitmap(frame, scale: 8);
        }
    }

    private void Snooze_Click(object sender, RoutedEventArgs e) => _engine.SnoozeBreak(5);
    private void Skip_Click(object sender, RoutedEventArgs e) => _engine.SkipPhase();

    private void Root_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Escape)
        {
            _engine.DismissOverlayOnly();
        }
    }
}
