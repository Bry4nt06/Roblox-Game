# Cinematic Intro

The intro camera is client-only and targets `Workspace.Rig`.

- Camera is Scriptable until PLAY is pressed.
- Player controls are disabled during the intro.
- A subtle camera drift frames the Rig.
- PLAY fades to the normal player camera.

Camera framing can be tuned in `src/client/CinematicIntro.client.luau` with `CAMERA_OFFSET`, `LOOK_OFFSET`, and `CAMERA_FOV`.
