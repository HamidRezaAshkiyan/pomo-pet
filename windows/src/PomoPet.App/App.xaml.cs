using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using PomoPet.App.Services;
using PomoPet.App.Windows;
using PomoPet.Core;

namespace PomoPet.App;

public partial class App : Application
{
    public PomodoroEngine Engine { get; } = new();
    public PixelSpriteCatalog Catalog { get; } = PixelSpriteCatalog.LoadEmbedded();
    public TaskbarProgressService TaskbarProgress { get; } = new();
    public ToastNotificationService ToastService { get; } = new();

    private MainWindow? _mainWindow;
    private FloatingPillWindow? _floatingPill;
    private BreakOverlayWindow? _breakOverlay;
    private TrayIconService? _trayIcon;
    private IpcServerService? _ipcServer;
    private DispatcherQueueTimer? _secondTimer;
    private DispatcherQueueTimer? _animTimer;
    private int _animTick;

    public App()
    {
        InitializeComponent();
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        ToastService.Initialize();

        _mainWindow = new MainWindow(Engine, Catalog, TaskbarProgress);
        _mainWindow.Activate();

        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(_mainWindow);
        _trayIcon = new TrayIconService(hwnd);

        if (Engine.Settings.ShowFloatingMiniPill)
        {
            _floatingPill = new FloatingPillWindow(Engine, Catalog);
            _floatingPill.Activate();
        }

        Engine.BreakStarted += OnBreakStarted;
        Engine.FocusStarted += OnFocusStarted;
        Engine.OverlayDismissed += OnOverlayDismissed;
        Engine.StateChanged += RefreshAllSurfaces;

        // Handle pomopet:// URI arguments if launched with one
        var cmdArgs = Environment.GetCommandLineArgs();
        if (cmdArgs.Length > 1 && ProtocolUriParser.Parse(cmdArgs[1]) is { } uriReq)
        {
            HandleIpcCommand(uriReq);
        }

        var dq = _mainWindow.DispatcherQueue;
        _ipcServer = new IpcServerService(req =>
        {
            IpcStatusResponse? response = null;
            using var done = new ManualResetEventSlim(false);
            dq.TryEnqueue(() =>
            {
                response = HandleIpcCommand(req);
                done.Set();
            });
            done.Wait(TimeSpan.FromSeconds(2));
            return response ?? BuildStatusResponse();
        });
        _ipcServer.Start();

        _secondTimer = dq.CreateTimer();
        _secondTimer.Interval = TimeSpan.FromSeconds(1);
        _secondTimer.Tick += (_, _) => Engine.Tick();
        _secondTimer.Start();

        _animTimer = dq.CreateTimer();
        _animTimer.Interval = TimeSpan.FromMilliseconds(450);
        _animTimer.Tick += (_, _) =>
        {
            _animTick++;
            RefreshAllSurfaces();
        };
        _animTimer.Start();

        RefreshAllSurfaces();
    }

    private IpcStatusResponse HandleIpcCommand(IpcRequest request)
    {
        switch (request.Command)
        {
            case "start": Engine.Start(); break;
            case "pause": Engine.Pause(); break;
            case "toggle": Engine.Toggle(); break;
            case "reset": Engine.Reset(); break;
            case "skip": Engine.SkipPhase(); break;
            case "break": Engine.TriggerBreakPreview(); break;
            case "snooze":
                var mins = int.TryParse(request.Argument, out var m) ? m : 5;
                Engine.SnoozeBreak(mins);
                break;
            case "pet":
                if (PetKindExtensions.ParseId(request.Argument) is { } pet)
                    Engine.SelectPet(pet);
                break;
        }
        RefreshAllSurfaces();
        return BuildStatusResponse();
    }

    private IpcStatusResponse BuildStatusResponse() => new(
        Engine.PhaseTitle,
        Engine.FormattedTime,
        Engine.RemainingSeconds,
        Engine.TotalPhaseSeconds,
        Engine.IsRunning,
        Engine.Settings.SelectedPet.Id(),
        Engine.Settings.SelectedPet.DisplayName(),
        Engine.StatusSubtitle,
        Engine.TotalCompletedToday
    );

    private void OnBreakStarted(TimerPhase phase, StretchPrompt prompt)
    {
        ToastService.NotifyBreakStarted(phase, prompt);
        if (Engine.IsBreakOverlayPresented)
        {
            _breakOverlay ??= new BreakOverlayWindow(Engine, Catalog);
            _breakOverlay.UpdateFrame(_animTick);
            _breakOverlay.Activate();
        }
    }

    private void OnFocusStarted()
    {
        ToastService.NotifyFocusReady();
        OnOverlayDismissed();
    }

    private void OnOverlayDismissed()
    {
        if (_breakOverlay is not null)
        {
            _breakOverlay.Close();
            _breakOverlay = null;
        }
    }

    private void RefreshAllSurfaces()
    {
        var frame = Catalog.GetFrame(Engine.Settings.SelectedPet, Engine.PetAnimationState, _animTick);
        if (frame is not null)
        {
            var tooltip = $"PomoPet • {Engine.PhaseTitle} ({Engine.FormattedTime}) — {Engine.Settings.SelectedPet.DisplayName()}";
            _trayIcon?.UpdateFrame(frame, tooltip);
        }

        _mainWindow?.RefreshUi(_animTick);
        _floatingPill?.RefreshUi(_animTick);
        _breakOverlay?.UpdateFrame(_animTick);
    }
}
