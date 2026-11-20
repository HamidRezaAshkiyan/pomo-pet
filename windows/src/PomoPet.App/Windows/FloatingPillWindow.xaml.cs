using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using PomoPet.App.Services;
using PomoPet.Core;
using Windows.Graphics;

namespace PomoPet.App.Windows;

/// <summary>
/// Compact borderless always-on-top mini-pill docked near the bottom-right
/// Windows taskbar for an always-visible live pet & countdown preview.
/// </summary>
public sealed partial class FloatingPillWindow : Window
{
    private readonly PomodoroEngine _engine;
    private readonly PixelSpriteCatalog _catalog;

    public FloatingPillWindow(PomodoroEngine engine, PixelSpriteCatalog catalog)
    {
        InitializeComponent();
        _engine = engine;
        _catalog = catalog;

        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        var windowId = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(hwnd);
        var appWindow = AppWindow.GetFromWindowId(windowId);

        if (appWindow.Presenter is OverlappedPresenter presenter)
        {
            presenter.IsAlwaysOnTop = true;
            presenter.IsResizable = false;
            presenter.IsMinimizable = false;
            presenter.IsMaximizable = false;
            presenter.SetBorderAndTitleBar(false, false);
        }

        appWindow.IsShownInSwitchers = false;
        const int pillWidth = 152;
        const int pillHeight = 46;
        appWindow.Resize(new SizeInt32(pillWidth, pillHeight));

        var display = DisplayArea.GetFromWindowId(windowId, DisplayAreaFallback.Primary);
        var workArea = display.WorkArea;
        appWindow.Move(new PointInt32(
            workArea.X + workArea.Width - pillWidth - 16,
            workArea.Y + workArea.Height - pillHeight - 12));
    }

    public void RefreshUi(int animTick)
    {
        PillTimerText.Text = _engine.FormattedTime;
        PillToggleButton.Content = _engine.IsRunning ? "⏸" : "▶";
        var frame = _catalog.GetFrame(_engine.Settings.SelectedPet, _engine.PetAnimationState, animTick);
        if (frame is not null)
        {
            PillPetImage.Source = PixelBitmapRenderer.ToWriteableBitmap(frame, scale: 3);
        }
    }

    private void Toggle_Click(object sender, RoutedEventArgs e) => _engine.Toggle();
}
