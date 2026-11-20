namespace PomoPet.Core;

public enum TimerPhase
{
    Focus,
    ShortBreak,
    LongBreak
}

public enum PetKind
{
    Cat,
    Dog,
    Capybara
}

public enum PetAnimationState
{
    Idle,
    Focusing,
    Stretching,
    Napping
}

public sealed record StretchPrompt(int Id, string Title, string Subtitle, string Glyph)
{
    public static readonly IReadOnlyList<StretchPrompt> Defaults =
    [
        new(0, "20-20-20 Eye Rest", "Look at something 20 feet away for 20 seconds to relax your eyes.", "\uE7B3"),
        new(1, "Drop & Roll Your Shoulders", "Inhale deeply, lift shoulders up, then slowly roll them back and down.", "\uE805"),
        new(2, "Stand Up & Reach High", "Step away from your chair, interlace your fingers, and stretch upward.", "\uE709"),
        new(3, "Hydrate & Unclench", "Take a sip of water, relax your jaw, and gently tilt your neck side to side.", "\uE798"),
        new(4, "Wrist & Finger Shake", "Extend each arm forward, stretch your fingers gently, then shake loose.", "\uE81A")
    ];
}

public sealed class PomoSettings
{
    public int FocusMinutes { get; set; } = 25;
    public int ShortBreakMinutes { get; set; } = 5;
    public int LongBreakMinutes { get; set; } = 15;
    public int SessionsBeforeLongBreak { get; set; } = 4;
    public PetKind SelectedPet { get; set; } = PetKind.Cat;
    public bool ShowFullScreenBreakOverlay { get; set; } = true;
    public bool ShowFloatingMiniPill { get; set; } = true;
    public bool PlaySoundChime { get; set; } = true;
    public bool AutoStartNextPhase { get; set; } = false;

    public int DurationSeconds(TimerPhase phase) => phase switch
    {
        TimerPhase.Focus => Math.Max(1, FocusMinutes) * 60,
        TimerPhase.ShortBreak => Math.Max(1, ShortBreakMinutes) * 60,
        TimerPhase.LongBreak => Math.Max(1, LongBreakMinutes) * 60,
        _ => 25 * 60
    };
}

public static class PetKindExtensions
{
    public static string DisplayName(this PetKind pet) => pet switch
    {
        PetKind.Cat => "Mochi",
        PetKind.Dog => "Biscuit",
        PetKind.Capybara => "Yuzu",
        _ => "Mochi"
    };

    public static string Id(this PetKind pet) => pet switch
    {
        PetKind.Cat => "cat",
        PetKind.Dog => "dog",
        PetKind.Capybara => "capybara",
        _ => "cat"
    };

    public static PetKind? ParseId(string? id) => id?.Trim().ToLowerInvariant() switch
    {
        "cat" or "mochi" => PetKind.Cat,
        "dog" or "shiba" or "biscuit" => PetKind.Dog,
        "capybara" or "yuzu" => PetKind.Capybara,
        _ => null
    };
}
