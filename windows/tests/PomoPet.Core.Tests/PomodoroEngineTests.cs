using PomoPet.Core;
using Xunit;

namespace PomoPet.Core.Tests;

public sealed class PomodoroEngineTests
{
    [Fact]
    public void FocusToShortBreakAndLongBreakCadence()
    {
        var engine = new PomodoroEngine(new PomoSettings
        {
            FocusMinutes = 1,
            ShortBreakMinutes = 5,
            LongBreakMinutes = 15,
            SessionsBeforeLongBreak = 2,
            ShowFullScreenBreakOverlay = true
        });

        var now = DateTimeOffset.FromUnixTimeSeconds(10_000);
        engine.Start(now);
        Assert.Equal(PetAnimationState.Focusing, engine.PetAnimationState);

        now = now.AddSeconds(60);
        engine.Tick(now);
        Assert.Equal(TimerPhase.ShortBreak, engine.Phase);
        Assert.True(engine.IsBreakOverlayPresented);
        Assert.Equal(1, engine.TotalCompletedToday);

        engine.SkipPhase(now);
        Assert.Equal(TimerPhase.Focus, engine.Phase);
        Assert.False(engine.IsBreakOverlayPresented);

        engine.Start(now);
        now = now.AddSeconds(60);
        engine.Tick(now);
        Assert.Equal(TimerPhase.LongBreak, engine.Phase);
        Assert.Equal(15 * 60, engine.RemainingSeconds);
        Assert.Equal(PetAnimationState.Napping, engine.PetAnimationState);
    }

    [Fact]
    public void LoadsAllEmbeddedSpritesWith16x16Grids()
    {
        var catalog = PixelSpriteCatalog.LoadEmbedded();
        foreach (var pet in Enum.GetValues<PetKind>())
        {
            var sheet = catalog.GetSheet(pet);
            Assert.NotNull(sheet);
            foreach (var state in Enum.GetValues<PetAnimationState>())
            {
                var frame = catalog.GetFrame(pet, state, 0);
                Assert.NotNull(frame);
                Assert.Equal(16, frame!.Width);
                Assert.Equal(16, frame.Height);
                Assert.Equal(256, frame.Pixels.Length);
            }
        }
    }

    [Theory]
    [InlineData("pomopet://start", "start", null)]
    [InlineData("pomopet://snooze/5", "snooze", "5")]
    [InlineData("pomopet://pet/capybara", "pet", "capybara")]
    public void ParsesProtocolUris(string uri, string expectedCmd, string? expectedArg)
    {
        var req = ProtocolUriParser.Parse(uri);
        Assert.NotNull(req);
        Assert.Equal(expectedCmd, req!.Command);
        Assert.Equal(expectedArg, req.Argument);
    }
}
