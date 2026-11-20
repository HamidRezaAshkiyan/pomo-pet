using System.Text.Json;

namespace PomoPet.Core;

public static class IpcConstants
{
    public const string PipeName = "PomoPet.IPC.v1";
    public const string UriScheme = "pomopet";
}

public sealed record IpcRequest(string Command, string? Argument = null);

public sealed record IpcStatusResponse(
    string Phase,
    string FormattedTime,
    int RemainingSeconds,
    int TotalSeconds,
    bool IsRunning,
    string PetId,
    string PetName,
    string StatusSubtitle,
    int CompletedToday
);

public static class ProtocolUriParser
{
    /// <summary>
    /// Parses pomopet:// URIs into IpcRequest commands.
    /// Examples: pomopet://start, pomopet://pause, pomopet://toggle,
    /// pomopet://break, pomopet://skip, pomopet://snooze/5, pomopet://pet/capybara
    /// </summary>
    public static IpcRequest? Parse(string uriText)
    {
        if (!Uri.TryCreate(uriText, UriKind.Absolute, out var uri))
            return null;
        if (!string.Equals(uri.Scheme, IpcConstants.UriScheme, StringComparison.OrdinalIgnoreCase))
            return null;

        var command = uri.Host.Trim().ToLowerInvariant();
        if (string.IsNullOrEmpty(command))
            return null;

        var arg = uri.AbsolutePath.Trim('/');
        return new IpcRequest(command, string.IsNullOrEmpty(arg) ? null : arg);
    }

    public static string Serialize<T>(T payload) => JsonSerializer.Serialize(payload);
    public static T? Deserialize<T>(string json) => JsonSerializer.Deserialize<T>(json);
}
