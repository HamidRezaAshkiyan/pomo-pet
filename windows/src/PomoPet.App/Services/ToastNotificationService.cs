using Microsoft.Windows.AppNotifications;
using Microsoft.Windows.AppNotifications.Builder;
using PomoPet.Core;

namespace PomoPet.App.Services;

public sealed class ToastNotificationService
{
    private bool _initialized;

    public void Initialize()
    {
        try
        {
            AppNotificationManager.Default.Register();
            _initialized = true;
        }
        catch
        {
            _initialized = false;
        }
    }

    public void NotifyBreakStarted(TimerPhase phase, StretchPrompt prompt)
    {
        if (!_initialized) return;
        try
        {
            var title = phase == TimerPhase.LongBreak ? "Time for a Long Break" : "Time to Rest Your Eyes";
            var notification = new AppNotificationBuilder()
                .AddText(title)
                .AddText($"{prompt.Title} — {prompt.Subtitle}")
                .BuildNotification();
            AppNotificationManager.Default.Show(notification);
        }
        catch { }
    }

    public void NotifyFocusReady()
    {
        if (!_initialized) return;
        try
        {
            var notification = new AppNotificationBuilder()
                .AddText("Break Complete")
                .AddText("Refreshed and ready for your next focus session!")
                .BuildNotification();
            AppNotificationManager.Default.Show(notification);
        }
        catch { }
    }
}
