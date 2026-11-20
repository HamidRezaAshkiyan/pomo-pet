using PomoPet.Core;

namespace PomoPet.PowerToys;

public sealed record PowerToysActionItem(
    string Id,
    string Title,
    string Subtitle,
    IpcRequest Request
);

/// <summary>
/// Command provider for Windows PowerToys Command Palette (CmdPal) / PowerToys Run.
/// Typing "pomo" returns live session status and one-keystroke Pomodoro & pet controls.
/// </summary>
public sealed class PomoPetPaletteProvider
{
    public const string Keyword = "pomo";
    private readonly PomoPetIpcClient _client;

    public PomoPetPaletteProvider(PomoPetIpcClient? client = null)
    {
        _client = client ?? new PomoPetIpcClient();
    }

    public async Task<IReadOnlyList<PowerToysActionItem>> QueryAsync(
        string? filter = null,
        CancellationToken cancellationToken = default)
    {
        var status = await _client.SendAsync(new IpcRequest("status"), cancellationToken: cancellationToken);
        var items = new List<PowerToysActionItem>();

        if (status is not null)
        {
            var toggleLabel = status.IsRunning ? "Pause Pomodoro" : "Resume Pomodoro";
            items.Add(new PowerToysActionItem(
                "toggle",
                $"{toggleLabel} — {status.Phase} ({status.FormattedTime})",
                $"{status.StatusSubtitle} • Today: {status.CompletedToday} sessions",
                new IpcRequest("toggle")
            ));
        }
        else
        {
            items.Add(new PowerToysActionItem(
                "start",
                "Start PomoPet Focus Session",
                "Launches PomoPet and begins your focus timer",
                new IpcRequest("start")
            ));
        }

        items.AddRange(
        [
            new("break", "Take Break Now (Preview Overlay)", "Open the calm full-screen breathing & stretch reminder", new IpcRequest("break")),
            new("snooze", "Snooze Break (+5 min)", "Delay your break reminder by 5 minutes", new IpcRequest("snooze", "5")),
            new("skip", "Skip Current Phase", "Advance to the next focus or break phase", new IpcRequest("skip")),
            new("pet-cat", "Switch Pet: Mochi (Cat)", "Show pixel-art cat in taskbar & tray", new IpcRequest("pet", "cat")),
            new("pet-dog", "Switch Pet: Biscuit (Shiba)", "Show pixel-art Shiba dog in taskbar & tray", new IpcRequest("pet", "dog")),
            new("pet-capybara", "Switch Pet: Yuzu (Capybara)", "Show pixel-art capybara in taskbar & tray", new IpcRequest("pet", "capybara"))
        ]);

        if (string.IsNullOrWhiteSpace(filter))
            return items;

        var q = filter.Trim();
        return items
            .Where(i => i.Title.Contains(q, StringComparison.OrdinalIgnoreCase)
                     || i.Subtitle.Contains(q, StringComparison.OrdinalIgnoreCase))
            .ToList();
    }

    public Task<IpcStatusResponse?> ExecuteAsync(PowerToysActionItem item, CancellationToken cancellationToken = default)
        => _client.SendAsync(item.Request, cancellationToken: cancellationToken);
}
