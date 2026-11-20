using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PomoPet.Core;

public readonly record struct RgbaPixel(byte R, byte G, byte B, byte A)
{
    public static readonly RgbaPixel Clear = new(0, 0, 0, 0);

    public static RgbaPixel FromHex(string? hex)
    {
        if (string.IsNullOrWhiteSpace(hex)) return Clear;
        var clean = hex.Trim().ToLowerInvariant();
        if (clean == "transparent") return Clear;
        if (clean.StartsWith('#')) clean = clean[1..];
        if (clean.Length != 6 || !uint.TryParse(clean, System.Globalization.NumberStyles.HexNumber, null, out var v))
            return Clear;

        return new RgbaPixel(
            (byte)((v >> 16) & 0xFF),
            (byte)((v >> 8) & 0xFF),
            (byte)(v & 0xFF),
            255
        );
    }
}

public sealed record PixelFrame(int Width, int Height, RgbaPixel[] Pixels);

public sealed record PetAnimation(double Fps, IReadOnlyList<PixelFrame> Frames);

public sealed record PetSpriteSheet(
    PetKind Id,
    string DisplayName,
    string Species,
    string AccentHex,
    IReadOnlyDictionary<PetAnimationState, PetAnimation> States
);

public sealed class PixelSpriteCatalog
{
    private readonly IReadOnlyDictionary<PetKind, PetSpriteSheet> _sheets;

    public PixelSpriteCatalog(IReadOnlyDictionary<PetKind, PetSpriteSheet> sheets)
    {
        _sheets = sheets;
    }

    public PetSpriteSheet? GetSheet(PetKind pet) => _sheets.GetValueOrDefault(pet);

    public PixelFrame? GetFrame(PetKind pet, PetAnimationState state, int tick)
    {
        if (!_sheets.TryGetValue(pet, out var sheet)) return null;
        if (!sheet.States.TryGetValue(state, out var anim) && !sheet.States.TryGetValue(PetAnimationState.Idle, out anim))
            return null;
        if (anim.Frames.Count == 0) return null;
        var idx = Math.Abs(tick) % anim.Frames.Count;
        return anim.Frames[idx];
    }

    public static PixelSpriteCatalog LoadEmbedded()
    {
        var assembly = Assembly.GetExecutingAssembly();
        using var stream = assembly.GetManifestResourceStream("PomoPet.Core.sprites.json")
            ?? throw new InvalidOperationException("Embedded resource PomoPet.Core.sprites.json not found.");
        return Decode(stream);
    }

    public static PixelSpriteCatalog Decode(Stream stream)
    {
        var raw = JsonSerializer.Deserialize<RawCatalog>(stream)
            ?? throw new InvalidDataException("Failed to deserialize sprites.json.");
        var sheets = new Dictionary<PetKind, PetSpriteSheet>();

        foreach (var rawPet in raw.Pets)
        {
            var petKind = PetKindExtensions.ParseId(rawPet.Id);
            if (petKind is null) continue;

            var palette = rawPet.Palette.ToDictionary(kv => kv.Key, kv => RgbaPixel.FromHex(kv.Value));
            var states = new Dictionary<PetAnimationState, PetAnimation>();

            foreach (var (stateKey, rawState) in rawPet.States)
            {
                if (!Enum.TryParse<PetAnimationState>(stateKey, ignoreCase: true, out var animState))
                    continue;

                var frames = new List<PixelFrame>();
                foreach (var rows in rawState.Frames)
                {
                    if (rows.Count != raw.GridSize)
                        throw new InvalidDataException($"Invalid row count for {rawPet.Id}/{stateKey}.");

                    var pixels = new RgbaPixel[raw.GridSize * raw.GridSize];
                    var idx = 0;
                    foreach (var row in rows)
                    {
                        if (row.Length != raw.GridSize)
                            throw new InvalidDataException($"Invalid column count for {rawPet.Id}/{stateKey}.");
                        foreach (var ch in row)
                        {
                            pixels[idx++] = palette.TryGetValue(ch.ToString(), out var px) ? px : RgbaPixel.Clear;
                        }
                    }
                    frames.Add(new PixelFrame(raw.GridSize, raw.GridSize, pixels));
                }

                states[animState] = new PetAnimation(rawState.Fps, frames);
            }

            sheets[petKind.Value] = new PetSpriteSheet(
                petKind.Value,
                rawPet.DisplayName,
                rawPet.Species,
                rawPet.AccentHex,
                states
            );
        }

        return new PixelSpriteCatalog(sheets);
    }

    private sealed class RawCatalog
    {
        [JsonPropertyName("version")] public int Version { get; set; }
        [JsonPropertyName("gridSize")] public int GridSize { get; set; }
        [JsonPropertyName("pets")] public List<RawPet> Pets { get; set; } = [];
    }

    private sealed class RawPet
    {
        [JsonPropertyName("id")] public string Id { get; set; } = "";
        [JsonPropertyName("displayName")] public string DisplayName { get; set; } = "";
        [JsonPropertyName("species")] public string Species { get; set; } = "";
        [JsonPropertyName("accentHex")] public string AccentHex { get; set; } = "";
        [JsonPropertyName("palette")] public Dictionary<string, string> Palette { get; set; } = [];
        [JsonPropertyName("states")] public Dictionary<string, RawState> States { get; set; } = [];
    }

    private sealed class RawState
    {
        [JsonPropertyName("fps")] public double Fps { get; set; }
        [JsonPropertyName("frames")] public List<List<string>> Frames { get; set; } = [];
    }
}
