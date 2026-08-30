package com.github.lindnergui.meraki

import com.ryanheise.audioservice.AudioServiceActivity

/// Uses the engine managed by audio_service so Android notification and
/// lock-screen controls stay connected to the same Flutter audio handler.
class MainActivity : AudioServiceActivity()
