using System.Runtime.InteropServices;

namespace PomoPet.App.Services;

public enum TaskbarProgressState
{
    NoProgress = 0x0,
    Indeterminate = 0x1,
    Normal = 0x2,
    Error = 0x4,
    Paused = 0x8
}

/// <summary>
/// Wraps Win32 ITaskbarList3 COM interface to show live Pomodoro progress
/// directly on the Windows taskbar icon.
/// </summary>
public sealed class TaskbarProgressService
{
    private readonly ITaskbarList3? _taskbarList;

    public TaskbarProgressService()
    {
        try
        {
            _taskbarList = (ITaskbarList3)new TaskbarList();
            _taskbarList.HrInit();
        }
        catch
        {
            _taskbarList = null;
        }
    }

    public void UpdateProgress(IntPtr hwnd, double progress, bool isRunning, bool isBreak)
    {
        if (_taskbarList is null || hwnd == IntPtr.Zero) return;

        if (!isRunning && progress <= 0.001)
        {
            _taskbarList.SetProgressState(hwnd, TaskbarProgressState.NoProgress);
            return;
        }

        var state = !isRunning
            ? TaskbarProgressState.Paused
            : isBreak
                ? TaskbarProgressState.Error // warm/coral highlight for break reminder
                : TaskbarProgressState.Normal;

        _taskbarList.SetProgressState(hwnd, state);
        var completed = (ulong)Math.Clamp(progress * 1000.0, 0, 1000);
        _taskbarList.SetProgressValue(hwnd, completed, 1000);
    }

    [ComImport]
    [Guid("56FDF344-FD6D-11d0-958A-006097C9A090")]
    [ClassInterface(ClassInterfaceType.None)]
    private class TaskbarList;

    [ComImport]
    [Guid("ea1afb91-9e28-4b86-90e9-9e9f8a5eefaf")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface ITaskbarList3
    {
        void HrInit();
        void AddTab(IntPtr hwnd);
        void DeleteTab(IntPtr hwnd);
        void ActivateTab(IntPtr hwnd);
        void SetActiveAlt(IntPtr hwnd);
        void MarkFullscreenWindow(IntPtr hwnd, [MarshalAs(UnmanagedType.Bool)] bool fFullscreen);
        void SetProgressValue(IntPtr hwnd, ulong ullCompleted, ulong ullTotal);
        void SetProgressState(IntPtr hwnd, TaskbarProgressState tbpFlags);
    }
}
