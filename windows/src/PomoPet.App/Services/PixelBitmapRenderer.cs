using System.Runtime.InteropServices.WindowsRuntime;
using Microsoft.UI.Xaml.Media.Imaging;
using PomoPet.Core;

namespace PomoPet.App.Services;

public static class PixelBitmapRenderer
{
    /// <summary>
    /// Renders a 16x16 PixelFrame into a nearest-neighbor upscaled WriteableBitmap
    /// so WinUI 3 Image controls display razor-sharp pixel art.
    /// </summary>
    public static WriteableBitmap ToWriteableBitmap(PixelFrame frame, int scale = 8)
    {
        var width = frame.Width * scale;
        var height = frame.Height * scale;
        var bitmap = new WriteableBitmap(width, height);
        var bgra = new byte[width * height * 4];

        for (var y = 0; y < frame.Height; y++)
        {
            for (var x = 0; x < frame.Width; x++)
            {
                var px = frame.Pixels[y * frame.Width + x];
                for (var sy = 0; sy < scale; sy++)
                {
                    for (var sx = 0; sx < scale; sx++)
                    {
                        var offset = ((y * scale + sy) * width + (x * scale + sx)) * 4;
                        bgra[offset] = px.B;
                        bgra[offset + 1] = px.G;
                        bgra[offset + 2] = px.R;
                        bgra[offset + 3] = px.A;
                    }
                }
            }
        }

        using var stream = bitmap.PixelBuffer.AsStream();
        stream.Write(bgra, 0, bgra.Length);
        bitmap.Invalidate();
        return bitmap;
    }
}
