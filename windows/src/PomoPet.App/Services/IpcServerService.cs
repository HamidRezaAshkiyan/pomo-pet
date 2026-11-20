using System.IO.Pipes;
using System.Text;
using PomoPet.Core;

namespace PomoPet.App.Services;

/// <summary>
/// Named Pipe IPC server (PomoPet.IPC.v1) allowing the PowerToys Command Palette
/// extension and pomopet:// URI activations to query live status and trigger actions.
/// </summary>
public sealed class IpcServerService : IDisposable
{
    private readonly Func<IpcRequest, IpcStatusResponse> _handler;
    private readonly CancellationTokenSource _cts = new();
    private Task? _listenTask;

    public IpcServerService(Func<IpcRequest, IpcStatusResponse> handler)
    {
        _handler = handler;
    }

    public void Start()
    {
        _listenTask = Task.Run(ListenLoopAsync);
    }

    private async Task ListenLoopAsync()
    {
        while (!_cts.IsCancellationRequested)
        {
            try
            {
                await using var server = new NamedPipeServerStream(
                    IpcConstants.PipeName,
                    PipeDirection.InOut,
                    NamedPipeServerStream.MaxAllowedServerInstances,
                    PipeTransmissionMode.Byte,
                    PipeOptions.Asynchronous);

                await server.WaitForConnectionAsync(_cts.Token);

                using var reader = new StreamReader(server, Encoding.UTF8, leaveOpen: true);
                await using var writer = new StreamWriter(server, Encoding.UTF8, leaveOpen: true) { AutoFlush = true };

                var line = await reader.ReadLineAsync(_cts.Token);
                if (string.IsNullOrWhiteSpace(line)) continue;

                var request = ProtocolUriParser.Deserialize<IpcRequest>(line) ?? new IpcRequest("status");
                var response = _handler(request);
                await writer.WriteLineAsync(ProtocolUriParser.Serialize(response));
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch
            {
                await Task.Delay(250, _cts.Token);
            }
        }
    }

    public void Dispose()
    {
        _cts.Cancel();
        _cts.Dispose();
    }
}
