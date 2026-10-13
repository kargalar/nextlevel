enum VoiceTaskLaunchMode { regular, coldShortcut, warmShortcut }

VoiceTaskLaunchMode resolveVoiceTaskLaunchMode({
  required bool initialShortcut,
  required bool appAlreadyVisible,
}) {
  if (!initialShortcut) return VoiceTaskLaunchMode.regular;
  return appAlreadyVisible
      ? VoiceTaskLaunchMode.warmShortcut
      : VoiceTaskLaunchMode.coldShortcut;
}
