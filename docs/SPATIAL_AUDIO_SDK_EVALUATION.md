# Bôm Phim — Spatial Audio Integration

## Implemented: native iOS spatial rendering request

The movie player still uses SwiftUI `VideoPlayer` backed by `AVPlayer`. Playback now configures `AVPlayerItem.allowedAudioSpatializationFormats` according to the user's audio mode:

- **Spatial Audio** — explicitly allows Apple's native spatial rendering for mono, stereo, and multichannel sources (`.monoStereoAndMultichannel`).
- **Automatic** — permits system spatial rendering for multichannel sources (`.multichannel`); stereo spatial upmix is not explicitly requested.
- **Standard** — sets an empty spatialization format, asking AVPlayer not to spatialize the item.

Apple documents that AVPlayerItem spatialization uses psychoacoustic rendering for compatible headphone/speaker routes, and that users can also control spatial audio at the system level. A spatialized stereo source is still not a Dolby Atmos mix and must not be labeled as Atmos. See:
- https://developer.apple.com/documentation/avfoundation/avplayeritem/allowedaudiospatializationformats
- https://developer.apple.com/videos/play/wwdc2021/10265/

## Important limits

- The setting is a request to Apple's native renderer; the app cannot guarantee the route/device will render spatial audio. Compatible output hardware and system settings are required.
- It does not synthesize Atmos metadata, recreate discrete height/object channels, or provide Netflix AMBEO.
- The PhimAPI stream must be decodable by AVPlayer. Unsupported codecs, unavailable tracks, or DRM restrictions remain outside this feature.
- The app has not yet been tested on a physical iPhone with Spatial Audio-capable headphones. CI simulator build does not verify the audible effect.

## Open-source DSP candidates (separate future experiment)

### Sonic (MIT)
- Repository: https://github.com/bdnhrsn/Sonic
- Real-time binaural processing library for iOS.
- README documents 16-bit WAV LPCM at 44.1 kHz as its officially supported input and manual source integration.
- Not a drop-in AVPlayer/HLS processor.

### 3DTI AudioToolkit (LGPL-3.0)
- Repository: https://github.com/3DTune-In/3dti_AudioToolkit
- C++ binaural/spatial rendering toolkit.
- Review LGPL obligations and verify current iOS build support before shipping.

## Next verification steps

1. Build with GitHub Actions.
2. Install on a physical iPhone and connect Spatial Audio-compatible AirPods.
3. Test Spatial Audio vs Standard on the same stereo movie, checking route status, soundstage, loudness and artifacts.
4. Test Automatic with a multichannel source if PhimAPI exposes one.
5. Confirm pause, seek, subtitles, orientation, AirPlay and Bluetooth continue to work.
6. Only after physical listening tests, describe the effect in user-facing marketing. Do not use Dolby Atmos or Netflix AMBEO branding for Apple's generic spatialization.
