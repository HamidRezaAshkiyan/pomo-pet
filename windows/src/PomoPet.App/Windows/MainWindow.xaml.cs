using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using PomoPet.App.Services;
using PomoPet.Core;
using Windows.Graphics;

namespace PomoPet.App.Windows;

public sealed partial class MainWindow : Window
{
    private readonly PomodoroEngine _engine;
    private readonly PixelSpriteCatalog _catalog;
    private readonly TaskbarProgressService _taskbarProgress;
    private readonly IntPtr _hwnd;

    public MainWindow(
        PomodoroEngine engine,
        PixelSpriteCatalog catalog,
        TaskbarProgressService taskbarProgress)
    {
        InitializeComponent();
        _engine = engine;
        _catalog = catalog;
        _taskbarProgress = taskbarProgress;
        _hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);

        var windowId = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(_hwnd);
        var appWindow = AppWindow.GetFromWindowId(windowId);
        appWindow.Resize(new SizeInt32(400, 480));
        ExtendsContentIntoTitleBar = true;

        var version = typeof(MainWindow).Assembly.GetName().Version;
        if (version is not null)
        {
            VersionText.Text = $"v{version.Major}.{version.Minor}.{version.Build}";
        }
    }

    public void RefreshUi(int animTick)
    {
        PhaseBadgeText.Text = _engine.PhaseTitle;
        TimerText.Text = _engine.FormattedTime;
        SubtitleText.Text = _engine.StatusSubtitle;
        StartPauseButton.Content = _engine.IsRunning ? "Pause" : "Start";
        SessionProgressRing.Value = Math.Max(2, _engine.Progress * 100.0);
        TodayCountText.Text = $"Today: {_engine.TotalCompletedToday} {(_engine.TotalCompletedToday == 1 ? "session" : "sessions")}";

        var frame = _catalog.GetFrame(_engine.Settings.SelectedPet, _engine.PetAnimationState, animTick);
        if (frame is not null)
        {
            PetImage.Source = PixelBitmapRenderer.ToWriteableBitmap(frame, scale: 6);
        }

        _taskbarProgress.UpdateProgress(
            _hwnd,
            _engine.Progress,
            _engine.IsRunning,
            _engine.Phase != TimerPhase.Focus
        );
    }

    private void StartPause_Click(object sender, RoutedEventArgs e) => _engine.Toggle();
    private void Reset_Click(object sender, RoutedEventArgs e) => _engine.Reset();
    private void Skip_Click(object sender, RoutedEventArgs e) => _engine.SkipPhase();
    private void PreviewBreak_Click(object sender, RoutedEventArgs e) => _engine.TriggerBreakPreview();
    private void SelectCat_Click(object sender, RoutedEventArgs e) => _engine.SelectPet(PetKind.Cat);
    private void SelectDog_Click(object sender, RoutedEventArgs e) => _engine.SelectPet(PetKind.Dog);
    private void SelectCapybara_Click(object sender, RoutedEventArgs e) => _engine.SelectPet(PetKind.Capybara);
}
