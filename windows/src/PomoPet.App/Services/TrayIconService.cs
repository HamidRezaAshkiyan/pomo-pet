using System.Runtime.InteropServices;
using PomoPet.Core;

namespace PomoPet.App.Services;

/// <summary>
/// Renders animated 16x16 pixel-art pet frames directly into the Windows System Tray
/// using Win32 Shell_NotifyIconW and dynamically generated HICON handles.
/// </summary>
public sealed class TrayIconService : IDisposable
{
    private const uint NIM_ADD = 0x00000000;
    private const uint NIM_MODIFY = 0x00000001;
    private const uint NIM_DELETE = 0x00000002;
    private const uint NIF_MESSAGE = 0x00000001;
    private const uint NIF_ICON = 0x00000002;
    private const uint NIF_TIP = 0x00000004;
    public const uint WM_TRAY_CALLBACK = 0x8001;

    private readonly IntPtr _hwnd;
    private IntPtr _currentIcon = IntPtr.Zero;
    private bool _added;

    public TrayIconService(IntPtr hwnd)
    {
        _hwnd = hwnd;
    }

    public void UpdateFrame(PixelFrame frame, string tooltip)
    {
        var newIcon = CreateIconFromPixelFrame(frame);
        if (newIcon == IntPtr.Zero) return;

        var data = new NOTIFYICONDATA
        {
            cbSize = (uint)Marshal.SizeOf<NOTIFYICONDATA>(),
            hWnd = _hwnd,
            uID = 1,
            uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE,
            uCallbackMessage = WM_TRAY_CALLBACK,
            hIcon = newIcon,
            szTip = tooltip.Length > 127 ? tooltip[..127] : tooltip
        };

        Shell_NotifyIcon(_added ? NIM_MODIFY : NIM_ADD, ref data);
        _added = true;

        if (_currentIcon != IntPtr.Zero)
            DestroyIcon(_currentIcon);
        _currentIcon = newIcon;
    }

    public void Dispose()
    {
        if (_added)
        {
            var data = new NOTIFYICONDATA
            {
                cbSize = (uint)Marshal.SizeOf<NOTIFYICONDATA>(),
                hWnd = _hwnd,
                uID = 1
            };
            Shell_NotifyIcon(NIM_DELETE, ref data);
            _added = false;
        }
        if (_currentIcon != IntPtr.Zero)
        {
            DestroyIcon(_currentIcon);
            _currentIcon = IntPtr.Zero;
        }
    }

    private static unsafe IntPtr CreateIconFromPixelFrame(PixelFrame frame)
    {
        const int size = 32; // Crisp 2x nearest-neighbor upscale of 16x16 sprite
        var bgra = new byte[size * size * 4];
        for (var y = 0; y < frame.Height; y++)
        {
            for (var x = 0; x < frame.Width; x++)
            {
                var px = frame.Pixels[y * frame.Width + x];
                for (var sy = 0; sy < 2; sy++)
                {
                    for (var sx = 0; sx < 2; sx++)
                    {
                        var offset = ((y * 2 + sy) * size + (x * 2 + sx)) * 4;
                        bgra[offset] = px.B;
                        bgra[offset + 1] = px.G;
                        bgra[offset + 2] = px.R;
                        bgra[offset + 3] = px.A;
                    }
                }
            }
        }

        var bmi = new BITMAPINFOHEADER
        {
            biSize = (uint)Marshal.SizeOf<BITMAPINFOHEADER>(),
            biWidth = size,
            biHeight = -size, // top-down DIB
            biPlanes = 1,
            biBitCount = 32,
            biCompression = 0
        };

        var hdc = GetDC(IntPtr.Zero);
        var hColor = CreateDIBSection(hdc, ref bmi, 0, out var bitsPtr, IntPtr.Zero, 0);
        ReleaseDC(IntPtr.Zero, hdc);
        if (hColor == IntPtr.Zero || bitsPtr == IntPtr.Zero) return IntPtr.Zero;

        Marshal.Copy(bgra, 0, bitsPtr, bgra.Length);
        var hMask = CreateBitmap(size, size, 1, 1, IntPtr.Zero);

        var info = new ICONINFO
        {
            fIcon = true,
            hbmColor = hColor,
            hbmMask = hMask
        };
        var hIcon = CreateIconIndirect(ref info);

        DeleteObject(hColor);
        DeleteObject(hMask);
        return hIcon;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct NOTIFYICONDATA
    {
        public uint cbSize;
        public IntPtr hWnd;
        public uint uID;
        public uint uFlags;
        public uint uCallbackMessage;
        public IntPtr hIcon;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string szTip;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BITMAPINFOHEADER
    {
        public uint biSize;
        public int biWidth;
        public int biHeight;
        public ushort biPlanes;
        public ushort biBitCount;
        public uint biCompression;
        public uint biSizeImage;
        public int biXPelsPerMeter;
        public int biYPelsPerMeter;
        public uint biClrUsed;
        public uint biClrImportant;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct ICONINFO
    {
        [MarshalAs(UnmanagedType.Bool)] public bool fIcon;
        public uint xHotspot;
        public uint yHotspot;
        public IntPtr hbmMask;
        public IntPtr hbmColor;
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool Shell_NotifyIcon(uint dwMessage, ref NOTIFYICONDATA lpData);

    [DllImport("user32.dll")]
    private static extern IntPtr GetDC(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern int ReleaseDC(IntPtr hWnd, IntPtr hDC);

    [DllImport("gdi32.dll")]
    private static extern IntPtr CreateDIBSection(IntPtr hdc, ref BITMAPINFOHEADER pbmi, uint usage, out IntPtr ppvBits, IntPtr hSection, uint offset);

    [DllImport("gdi32.dll")]
    private static extern IntPtr CreateBitmap(int nWidth, int nHeight, uint nPlanes, uint nBitCount, IntPtr lpBits);

    [DllImport("gdi32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeleteObject(IntPtr ho);

    [DllImport("user32.dll")]
    private static extern IntPtr CreateIconIndirect(ref ICONINFO piconinfo);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DestroyIcon(IntPtr hIcon);
}
