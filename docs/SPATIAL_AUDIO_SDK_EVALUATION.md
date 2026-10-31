# Bôm Phim — Spatial Audio SDK Evaluation

## Current playback architecture

The app currently plays movie URLs with SwiftUI `VideoPlayer` backed by `AVPlayer`. The audio menu preference is not a DSP renderer. Do not label a processing mode as active until an actual renderer is integrated and verified.

## Candidate free/open-source libraries

### Sonic (MIT)
- Repository: https://github.com/bdnhrsn/Sonic
- Described as real-time binaural processing for iOS.
- Important limitation: its README documents 16-bit WAV LPCM at 44.1 kHz as the officially supported input and describes the iOS integration as manual/source-based. It is not a drop-in AVPlayer/HLS processor.
- Assessment: proof-of-concept only; likely requires adapting the audio pipeline and validating compatibility.

### 3DTI AudioToolkit (LGPL-3.0)
- Repository: https://github.com/3DTune-In/3dti_AudioToolkit
- C++ binaural/spatial rendering toolkit.
- Assessment: technically worth a prototype, but review LGPL obligations and verify current iOS build support before shipping.

### Apple AVAudioEngine / AVAudioEnvironmentNode
- Documentation: https://developer.apple.com/documentation/AVFAudio/audio-engine
- Native APIs support real-time audio processing and 3D mixing.
- Assessment: native spatialization is possible when the app owns the audio source/pipeline; this does not automatically transform AVPlayer's rendered output or produce Dolby Atmos from stereo.

## Required engineering investigation before implementation

1. Identify supported source stream types and audio codecs from PhimAPI URLs (HLS, progressive, DRM/FairPlay).
2. Verify whether the chosen player exposes decoded PCM buffers that can be processed and routed to output while preserving seek, pause, subtitles, A/V sync, AirPlay and Bluetooth.
3. Build a separate proof-of-concept audio pipeline using a local, user-provided unprotected stereo test clip before connecting it to movie playback.
4. Test renderer CPU, memory, battery, latency, channel layout, headphone output and audio session interruptions on a physical iPhone.
5. Clearly distinguish:
   - Native Atmos passthrough: only when the source and iOS output route support it.
   - Binaural/spatial processing: derived effect applied by the app.
   - Standard stereo: unprocessed playback.
6. Keep the Spatial Audio control disabled/unavailable until the renderer is truly active. Never claim Dolby Atmos or Netflix AMBEO compatibility without licensing and verification.

## Current status

This document is groundwork only. No third-party SDK is embedded, no renderer is active, and no claim of spatialized playback is made. A commercial SDK is not necessary for open-source prototypes, but production integration depends on technical compatibility and license compliance.
