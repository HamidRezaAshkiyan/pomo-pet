using System.Diagnostics;
using System.IO.Pipes;
using System.Text;
using PomoPet.Core;

namespace PomoPet.PowerToys;

/// <summary>
/// Connects to a running PomoPet.App instance via Named Pipe (PomoPet.IPC.v1)
/// with automatic fallback to launching pomopet:// protocol URIs.
/// </summary>
public sealed class PomoPetIpcClient
{
    public async Task<IpcStatusResponse?> SendAsync(
        IpcRequest request,
        int timeoutMs = 800,
        CancellationToken cancellationToken = default)
    {
        try
        {
            await using var pipe = new NamedPipeClientStream(
                ".",
                IpcConstants.PipeName,
                PipeDirection.InOut,
                PipeOptions.Asynchronous);

            await pipe.ConnectAsync(timeoutMs, cancellationToken);

            await using var writer = new StreamWriter(pipe, Encoding.UTF8, leaveOpen: true) { AutoFlush = true };
            using var reader = new StreamReader(pipe, Encoding.UTF8, leaveOpen: true);

            await writer.WriteLineAsync(ProtocolUriParser.Serialize(request));
            var responseLine = await reader.ReadLineAsync(cancellationToken);
            return string.IsNullOrWhiteSpace(responseLine)
                ? null
                : ProtocolUriParser.Deserialize<IpcStatusResponse>(responseLine);
        }
        catch
        {
            LaunchUriFallback(request);
            return null;
        }
    }

    private static void LaunchUriFallback(IpcRequest request)
    {
        try
        {
            var suffix = string.IsNullOrWhiteSpace(request.Argument) ? "" : $"/{request.Argument}";
            var uri = $"{IpcConstants.UriScheme}://{request.Command}{suffix}";
            Process.Start(new ProcessStartInfo(uri) { UseShellExecute = true });
        }
        catch { }
    }
}
