namespace PomoPet.Core;

public sealed class PomodoroEngine
{
    private int _promptIndex;
    private DateTimeOffset? _targetEnd;
    private bool _isPreviewingBreak;
    private (TimerPhase Phase, int Remaining, int Total, bool WasRunning)? _savedBeforePreview;

    public PomoSettings Settings { get; }
    public TimerPhase Phase { get; private set; } = TimerPhase.Focus;
    public int RemainingSeconds { get; private set; }
    public int TotalPhaseSeconds { get; private set; }
    public bool IsRunning { get; private set; }
    public int CompletedFocusInCycle { get; private set; }
    public int TotalCompletedToday { get; private set; }
    public bool IsBreakOverlayPresented { get; private set; }
    public StretchPrompt CurrentStretchPrompt { get; private set; } = StretchPrompt.Defaults[0];

    public event Action? StateChanged;
    public event Action<TimerPhase, StretchPrompt>? BreakStarted;
    public event Action? FocusStarted;
    public event Action? OverlayDismissed;

    public PomodoroEngine(PomoSettings? settings = null)
    {
        Settings = settings ?? new PomoSettings();
        TotalPhaseSeconds = Settings.DurationSeconds(TimerPhase.Focus);
        RemainingSeconds = TotalPhaseSeconds;
    }

    public double Progress =>
        TotalPhaseSeconds <= 0
            ? 0
            : Math.Clamp((double)(TotalPhaseSeconds - RemainingSeconds) / TotalPhaseSeconds, 0, 1);

    public string FormattedTime
    {
        get
        {
            var clamped = Math.Max(0, RemainingSeconds);
            return $"{clamped / 60:00}:{clamped % 60:00}";
        }
    }

    public string PhaseTitle => Phase switch
    {
        TimerPhase.Focus => "Focus",
        TimerPhase.ShortBreak => "Short Break",
        TimerPhase.LongBreak => "Long Break",
        _ => "Focus"
    };

    public PetAnimationState PetAnimationState
    {
        get
        {
            if (IsBreakOverlayPresented)
                return Phase == TimerPhase.LongBreak ? PetAnimationState.Napping : PetAnimationState.Stretching;
            if (!IsRunning)
                return PetAnimationState.Idle;
            return Phase switch
            {
                TimerPhase.Focus => PetAnimationState.Focusing,
                TimerPhase.ShortBreak => PetAnimationState.Stretching,
                TimerPhase.LongBreak => PetAnimationState.Napping,
                _ => PetAnimationState.Idle
            };
        }
    }

    public string StatusSubtitle
    {
        get
        {
            var name = Settings.SelectedPet.DisplayName();
            if (IsBreakOverlayPresented) return $"{name} says: time to stretch & breathe";
            if (!IsRunning) return $"{name} is waiting for your next session";
            return Phase switch
            {
                TimerPhase.Focus => $"{name} is focusing with you",
                TimerPhase.ShortBreak => $"{name} is stretching — rest your eyes",
                TimerPhase.LongBreak => $"{name} is taking a cozy nap",
                _ => $"{name} is ready"
            };
        }
    }

    public void Start(DateTimeOffset? now = null)
    {
        if (IsRunning) return;
        var current = now ?? DateTimeOffset.UtcNow;
        IsRunning = true;
        _targetEnd = current.AddSeconds(RemainingSeconds);
        StateChanged?.Invoke();
    }

    public void Pause(DateTimeOffset? now = null)
    {
        if (!IsRunning) return;
        SyncRemaining(now ?? DateTimeOffset.UtcNow);
        IsRunning = false;
        _targetEnd = null;
        StateChanged?.Invoke();
    }

    public void Toggle(DateTimeOffset? now = null)
    {
        if (IsRunning) Pause(now);
        else Start(now);
    }

    public void Reset()
    {
        IsRunning = false;
        _targetEnd = null;
        DismissOverlayIfNeeded();
        TotalPhaseSeconds = Settings.DurationSeconds(Phase);
        RemainingSeconds = TotalPhaseSeconds;
        StateChanged?.Invoke();
    }

    public void SelectPet(PetKind pet)
    {
        Settings.SelectedPet = pet;
        StateChanged?.Invoke();
    }

    public void SkipPhase(DateTimeOffset? now = null)
    {
        var current = now ?? DateTimeOffset.UtcNow;
        if (_isPreviewingBreak)
        {
            EndBreakPreview(current);
            return;
        }
        DismissOverlayIfNeeded();
        AdvancePhase(completedNaturally: false, current);
    }

    public void SnoozeBreak(int minutes = 5, DateTimeOffset? now = null)
    {
        var current = now ?? DateTimeOffset.UtcNow;
        if (_isPreviewingBreak)
        {
            EndBreakPreview(current);
            return;
        }
        DismissOverlayIfNeeded();
        Phase = TimerPhase.Focus;
        var snoozeSeconds = Math.Max(1, minutes) * 60;
        TotalPhaseSeconds = snoozeSeconds;
        RemainingSeconds = snoozeSeconds;
        IsRunning = true;
        _targetEnd = current.AddSeconds(snoozeSeconds);
        StateChanged?.Invoke();
    }

    public void TriggerBreakPreview(DateTimeOffset? now = null)
    {
        if (IsBreakOverlayPresented) return;
        var current = now ?? DateTimeOffset.UtcNow;
        _savedBeforePreview = (Phase, RemainingSeconds, TotalPhaseSeconds, IsRunning);
        _isPreviewingBreak = true;
        IsRunning = true;
        Phase = TimerPhase.ShortBreak;
        TotalPhaseSeconds = 60;
        RemainingSeconds = 60;
        _targetEnd = current.AddSeconds(60);
        AdvanceStretchPrompt();
        IsBreakOverlayPresented = true;
        StateChanged?.Invoke();
        BreakStarted?.Invoke(TimerPhase.ShortBreak, CurrentStretchPrompt);
    }

    public void DismissOverlayOnly(DateTimeOffset? now = null)
    {
        if (_isPreviewingBreak)
        {
            EndBreakPreview(now ?? DateTimeOffset.UtcNow);
            return;
        }
        DismissOverlayIfNeeded();
        StateChanged?.Invoke();
    }

    public void Tick(DateTimeOffset? now = null)
    {
        if (!IsRunning) return;
        var current = now ?? DateTimeOffset.UtcNow;
        SyncRemaining(current);
        if (RemainingSeconds <= 0)
        {
            if (_isPreviewingBreak)
                EndBreakPreview(current);
            else
                AdvancePhase(completedNaturally: true, current);
        }
        else
        {
            StateChanged?.Invoke();
        }
    }

    private void SyncRemaining(DateTimeOffset now)
    {
        if (_targetEnd is null) return;
        var diff = (int)Math.Ceiling((_targetEnd.Value - now).TotalSeconds);
        RemainingSeconds = Math.Max(0, diff);
    }

    private void EndBreakPreview(DateTimeOffset now)
    {
        _isPreviewingBreak = false;
        DismissOverlayIfNeeded();
        if (_savedBeforePreview is { } saved)
        {
            Phase = saved.Phase;
            RemainingSeconds = saved.Remaining;
            TotalPhaseSeconds = saved.Total;
            IsRunning = saved.WasRunning;
            _targetEnd = saved.WasRunning ? now.AddSeconds(saved.Remaining) : null;
            _savedBeforePreview = null;
        }
        StateChanged?.Invoke();
    }

    private void DismissOverlayIfNeeded()
    {
        if (IsBreakOverlayPresented)
        {
            IsBreakOverlayPresented = false;
            OverlayDismissed?.Invoke();
        }
    }

    private void AdvanceStretchPrompt()
    {
        CurrentStretchPrompt = StretchPrompt.Defaults[_promptIndex % StretchPrompt.Defaults.Count];
        _promptIndex++;
    }

    private void AdvancePhase(bool completedNaturally, DateTimeOffset now)
    {
        TimerPhase nextPhase;
        if (Phase == TimerPhase.Focus)
        {
            if (completedNaturally)
            {
                CompletedFocusInCycle++;
                TotalCompletedToday++;
            }

            if (CompletedFocusInCycle >= Math.Max(1, Settings.SessionsBeforeLongBreak))
            {
                CompletedFocusInCycle = 0;
                nextPhase = TimerPhase.LongBreak;
            }
            else
            {
                nextPhase = TimerPhase.ShortBreak;
            }
        }
        else
        {
            nextPhase = TimerPhase.Focus;
        }

        Phase = nextPhase;
        TotalPhaseSeconds = Settings.DurationSeconds(nextPhase);
        RemainingSeconds = TotalPhaseSeconds;

        if (nextPhase is TimerPhase.ShortBreak or TimerPhase.LongBreak)
        {
            AdvanceStretchPrompt();
            IsRunning = true;
            _targetEnd = now.AddSeconds(RemainingSeconds);
            if (Settings.ShowFullScreenBreakOverlay)
                IsBreakOverlayPresented = true;
            StateChanged?.Invoke();
            BreakStarted?.Invoke(nextPhase, CurrentStretchPrompt);
        }
        else
        {
            DismissOverlayIfNeeded();
            if (Settings.AutoStartNextPhase)
            {
                IsRunning = true;
                _targetEnd = now.AddSeconds(RemainingSeconds);
            }
            else
            {
                IsRunning = false;
                _targetEnd = null;
            }
            StateChanged?.Invoke();
            FocusStarted?.Invoke();
        }
    }
}
