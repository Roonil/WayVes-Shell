# Developer's Notes from Hell

Please don't read them if you don't want to be confused. But they more-or-less document the journey I had with QtQuick/Quickshell (and frustrations, inconsistencies, bugs and the like) in making the final shell that I have today. They're not technically reliable, and some of it is probably wrong. But read on if you must!

- [The Notch](Notch.md): How the Notch was thought of
- [The Dock](Dock.md): How the idea came to life and how the rotations work
- [The DMABufSurface](DMABufSurface.md): The real sauce of the shell, showing Visualisers running in an external `WayVes` process exported as DMA-BUF FDs and imported into Quickshell for the final output.

Known issues:
- Author