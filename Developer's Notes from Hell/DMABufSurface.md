# DMABufSurface

The notes for this were made after the notes for the Dock, particularly because it took WAY TOO LONG to arrive at the now-working position. The original implementation was heavily modified, deleted and re-coded after nights of desperate frustration, and in hindsight, the current approach isn't really all thought-out well too. But for the first time now, everything "seems to work as it should". On to the deep dive, then!

Disclaimer: The following sections contain just what I know of DMABUFs and about my approach for an implementation of the idea. It might be technically correct at places, or just plain wrong at others. So keep that in mind while reading on!

# The Big (exported) Picture

Direct Memory Access Buffers (specifically for GPU/Graphics use-case) allow for essentially "sharing" a piece of Graphics output from one process to another without "copying" anything, and that is what I ideally wanted for WayVes: Not writing a library, but an "export" of its final output to another application, and the receiver application can display it however it wants. The only drawback here is writing the receiver portion of the application, and oh boy was it a rollercoaster for QtQuick/C++! I am almost certain that the 'Q' in QtQuick/QML stands for "Quantum", as in Quantum Physics, because some of the phenomena (output) I saw in some instances could only be explained by Quantum wizardry. Hovering over other elements caused updates over another, the visible flag isn't really about visibility, and a piece of code from the Destructor somehow crashed my application on start (Yeah I know, bad code, re-initialisation of surfaces, but dealing with multiple magical problems at a time can be frustrating, second only to the developer's own stupidity and incorrect assumptions).

Essentially, to get it all to work, we needed:
1. A DMABUF exporter logic for WayVes
2. A DMABUF importing logic for QtQuick

Except for the fact that I knew little about Quickshell/QtQuick/QML, and initially thought QML alone could suffice for this but shortly found out I need to deal with CMake (haven't used it much even still), QtQuick's life-cycle and QML and how they communicate.

# Baby steps
At first, getting a POC would be enough. Export something, import something, and I should see the exported Visual here in QtQuick Window, without even considering Quickshell.


For the WayVes/sender side, I introduced `rendering-mode` property, and in the `Detached` mode, I simply rendered the last stage in a Visualiser chain to a texture, and then exported it for DMABUF imports. Essentially, it exports a file-descriptor that the receiver process reads via an IPC mechanism and then re-creates the image that was exported. 

For QtQuick/receiver side, I proceeded with making a simple .cpp file that would show me a surface on a Window that I create using a .qml file. 

At this point, the big win would be seeing ANYTHING at all. Even if garbled graphics appeared to move with music, it meant the overall logic was "correct" in a way. Also, my beloved (now retired) MSI laptop housed an integrated Intel GPU with an NVIDIA GTX 1650 Ti Mobile, and Hyprland only worked with Intel for that laptop (no mux switch or something?) so I just worked with light shaders with one pass: Linear Shader showing some simple bars.

## Intel

Wasn't really straightforward but I'm thankful it worked that quickly. After implementing sockets on sender and receiver ends, I read online (cough-AI-cough) that the "attributes" exported along with the File Descriptor need to be correct, along with some other information, like number of planes and such. I still don't have much idea how they work, but they're significant enough to be included. 

Essentially, `eglExportDMABUFImageMESA()` is the "magic" function here that allows our final output texture to be exported via DMABUFs. `MESA` was alarming here, because it SCREAMED "No NVIDIA Proprietary allowed!" and that was exactly the system I was using. Intel was good, but heavier Visualiser configurations like `NCS` NEEDED NVIDIA to work. And this wasn't really about just my system, it needed to be general-purpose enough to not cater just to `WayVes`, but to any other DMABUF import/export logic. 

Tweaking around, I was initially able to see a garbled, audio-reactive output. Just meant some attributes were wrong. After a bit, I was actually able to get it to work on Intel! My `DMABufSurface` Widget included the socket listening logic, imported the texture, and rendered it in a simple `QSGNode`, by wrapping our imported OpenGL texture in a `QSGTexture` and having the Node display the texture. Even multiple-stage Shaders worked by this point, so having `Glow` effect on the Shader worked, and `NCS` worked too! Pretty neat!

Slight caveat here about DMABUFs regarding continuous frame updates: DMABUF implementations would often mention explicit sync mechanisms for changing images: Essentially dictating the "frame-rate" from the sender application, so that the receiver doesn't read from the texture when the sender is writing to it. I THINK using double-buffering was also mentioned as a way around this, but I didn't go any of those ways. Because practically, even at higher frame-rates, I see no tearing or artifacts and for now it is a good enough "demo". Maybe we can definitely introduce syncing but that is definitely not for now. In broad terms, as long as our original exported texture remains "pointed to" by the imported DMABUF FD, we should be able to keep re-using our imported OpenGL texture and should see updates as we normally would in a non-DMABUF setup.

## NVIDIA?

Of course it broke on NVIDIA. I mostly saw a black texture. Before moving onward to a cleaner architecture, it was absolutely essential to get it working on NVIDIA (this sentence right here marks the downfall of many projects and developers alike). But hey, on we go!

The following section is VERY MUCH PRONE to errors in deductions, assumptions and reasonings. Please be careful!

I initially suspected the problem was the `eglExportDMABUFImageMESA()` function because MESA would be open-source, whereas NVIDIA Proprietary won't be (fully). I looked around, used AI to get a more "bare-metal" way to export DMABUFs but nothing really worked.

I even investigated GBM-based exporting logic, but it failed on my NVIDIA Card again. I believe it is because the card couldn't really be used for DRM mode for some reason because even Hyprland wouldn't work on NVIDIA, and yes, `modeset` and `fbdev` were all correct. 

Scouring over the internet for a minimal working example, I found this: https://github.com/AlwinEsch/dma-buf-texture-sharing. Compiled and tested on NVIDIA, and it seemed to work. At least DMABUF wasn't a complete dead-end yet!

I was working late on a Sunday night, almost about to fall asleep and couldn't think straight. THAT is when NVIDIA worked! And it worked with our `MESA` function too. I think some of the attributes I mentioned earlier were incorrect, as only a re-write made it work. But I was glad, I could see the `NCS` Visualiser work on NVIDIA at full-speed on my QtQuick Window!

# Better than crawling now

With this, Quickshell came into play. A small bar-based DMABufSurface implementation could be seen in a Noctalia configuration that I updated, and it looked fine, also at smaller sizes. 

Separating `DMABufSurface` into its QML part and a `Manager` part that would allow the Socket logic and Buffer update information to pass down to the `DMABufSurface` was kinda straightforward, just needed to make our `Manager` to persist for the whole duration of the Quickshell application. Bit of a head-scratcher but got it running too. It also allowed ONE Manager to power multiple `DMABufSurface` widgets, meaning only one exported texture could be shown at multiple places. It was also becoming apparent at this point that a Quickshell config was needed for a demo and would seem nice enough.

# Why is my GPU trying to launch a Spacecraft?

I think this was during the writing of the Quickshell Configuration that I encountered the nuance of it all: Performance. On my machine, I was seeing a GPU usage that was, unexpectedly high. Even a simple 380x380 Window was consuming much of the GPU utilisation for no apparent reason. `WayVes` was exporting at 60 FPS, and QtQuick should be running maximum at 144 FPS (refresh rate of my setup back then), and still the usage felt a bit high. This meant that more Shaders would slow down the system. Not what we want, exactly!

I suspected that calling `update()` within `updatePaintNode()` wasn't really a good idea. But moving it to a `signal` like `onFrameSwapped()` didn't seem to help much either, at least that is supposed to not exceed the display frame-rate. And still, I felt that a spam of updates from CPU shouldn't really bump my GPU THAT much for a small Output window.

Even still, I feel QtQuick's animations consume higher GPU than usual, even a simple `FrameAnimation` on a text on a very small surface (180x50) felt it was doing more work than it should. I also ruled out "stepped clocks" by running `WayVes` at exactly that resolution and highest frame-rate, and the GPU utilisation was barely anything. Not just for NVIDIA, but also for Intel. The most obvious solution was to now bring down the framerate of the QtQuick window. Enter custom tickers!

# ZZZ....

We had 2 approaches to implement for manual FPS control:

1. Binding a `QTimer` to call `update()` at the frame-duration interval, or
2. Similar to GTK, sleeping on a worker thread for a frame duration (corresponding to 60 FPS for now) and then re-drawing our scene, we should get our output update at the specified FPS instead of the Display Refresh Rate, (hopefully) saving us some cycles.

Both approaches felt suboptimal in performance still. The GPU was still doing an ungodly amount of work, and I don't think I experienced that even during the development of `WayVes` itself. I was feeling it was time for a re-write of the widget, but without the RenderNode mechanism.

# The Old Approach

Using `updatePaintNode()` should have been clear enough. You invoke the `update()` method, the contents of this widget get marked as dirty, and QtQuick would re-paint it on the next frame, calling `updatePaintNode()`. It worked, until it didn't.

For instance, in the central expanded Panel, if I hovered over the Media Buttons, I saw that the WayVes logo at the bottom would also get rendered more "smoothly", meaning it was also getting marked as dirty by the SceneGraph somehow. That could also mean that somehow our 60 FPS widgets were still getting updated at 144 Hz!

Also, with `QSGRenderNode`, deleting a texture (during `WayVes` resize, as we would need to import a DMABUF FD again) would show garbled graphics, and this became apparent while fully implementing DMABufSurface for the Dock, specifically for the active/inactive Indicator rings. I saw icons and whatnot behind, well, icons. I was eventually able to do away with that by using a deletion strategy after 3 frames instead of deleting the textures right then.

# The New Approach

As is the norm for ditching away completely performant back-ends and instead bringing in Vulkan and whatnot to claim increased performance (looking at you, GTK4. I still haven't forgotten your re-write of the OpenGL back-end that completely destroyed `WayVes`' performance at one point), QtQuick followed suit and marked `QQuickFrameBufferObject` as legacy, and moved forward with `QQuickRhiItem`. RHI is meant to be general-purpose in a sense, so you write code that should work on all graphics back-ends: DirectX, OpenGL, Vulkan and the like.

Also, by this point, I moved to a more powerful laptop, and was using Hyprland with all its blur-glory on my NVIDIA card, and was also using `DMABufSurface` here, and could be a bit liberal about performance but I decided to hone in on it more.

I didn't consider `QQuickFrameBufferObject` because of the legacy status, and even though it could still be here for years, knowing my luck, I decided not to go that way. Pretty confident that if I completed the write of the Widget and published the demo, it would get removed from Quickshell/QtQuick on the very same day. I wish I was exaggerating. 

To put it quite simply, I have NEVER seen anything like this. The `initialize()` method of the renderer gets called more than once for instance! And their "example" OpenGL triangle includes having to compile existing Fragment and Vertex Shaders into a ShaderBaker object and feed them into QQuickRhiItem/Renderer and I was close to pulling all of my hair out at once while trying to get that to work. Again, I feel GTK's documentation is much better in this regard, the examples were clear too. I couldn't even get simple Triangles to render here! But maybe because RHI is meant to render more than Triangles and I was trying to crack open a walnut with a sledgehammer. Should have worked though.

RHI implementation works like this: `QQuickRhiItem` lives on the GUI/main thread, while the `QQuickRhiItemRenderer` lives on its separate Renderer thread, meant only for rendering. `synchronize()` method is the means of communication between the two; the GUI thread is essentially paused here to transfer QML properties from the GUI thread to the Renderer. This also means we should be free from unnecessary dirty-state checking and updates from the SceneGraph as we did earlier. We finally control the updates, maybe?

The official RHI Example didn't really seem to point it out, but calling `update()` in both these items works differently, and a call of `update()` from `QQuickRhiItem` won't really call for an update to the `QQuickRhiItemRenderer`. Subtle, but important. Also, `QQuickRhiItemRenderer` can be made a `QObject`, meaning it can connect to signals as well. The documentation seems to make it as if this is a bad idea, and maybe it is, so initially it wasn't a `QObject`. No signals, just getting instructions from the `QQuickRhiItem`. 

By this point, I was exclusively using a dedicated thread for FPS, and emitted a `tick()` signal whenever an update should be queued, and still am using this approach. I might switch it for the dedicated QTimer firing logic and connecting it to call `update()` directly, but for now this approach seems intuitive and error-free.

Calling `rendererItem->update()` from the GUI Thread's Item, while sounding stupid and dangerous, seemed to work for the most part. Crashes kept happening after a while, and it was because we called update() from the wrong thread. But the errors still took quite a while to occur, so as long as we could nail performance down, we might fine-tune other things. 

Visibility was also another aspect, since we need to make sure our Widget doesn't call `update()` when it is not visible. Not only that, we needed WayVes to stop rendering when not required as well.

# Patching up the remaining stuff

After upgrading `QQuickRhiItemRenderer` to `QObject` and allowing for signal binds, it was finally possible to bind the update function directly from the renderer thread to the Frame Emitter Thread. It was also now possible to change WayVes' visibility by queuing a visibilityChangeCommand to execute when the visibility changed. Integrating that in, and our GPU usage was FINALLY starting to make more sense. We were only starting up Cars now (reference to the very first `WayVes` post?) and even 10 FPS looked like 10 FPS on spamming hover on buttons. Nice!

Integrating Visibility accommodation and also queuing a `WayVes` Visibility change, the idle GPU usage seemed a bit high, but that was now purely on `WayVes` side and not QtQuick (feels strange to not blame QtQuick for once), and thankfully I already suspected why that was. 

`WayVes` was only clearing the contents of the screen when its Visibility was supposed to be off, but the render function was still getting called per frame, and it was a deliberate choice to keep the Audio Shaders rendering so the other Shaders down the chain won't get affected. To tackle that, I implemented a bit-mask logic to track active consumers in an `AudioShaderStage`, and it'd follow the same old pattern if the non-visible Shader would need to drive Audio for other, visible Shaders, but would completely turn-off the call to the render function if no Audio-consuming Shaders are visible, literally stopping any GPU usage in this case!

With this, `initial-visibility` and an option to not hot-reload on glsl file changes were also finally written, so that the Shaders' internal render function won't get called on startup until they are made visible manually, and also to use uniforms to update properties while allowing `Matugen` to write to the `Colors.glsl` file without triggering a complete teardown of all Shaders.

It was also observed that showing and hiding a DMABufSurface was slowly causing a VRAM leak. My overall 3-frame deletion logic was sound, because it fired during a widget resize and it survived even a spam, but that same cleanup was failing to happen properly when the surface was getting destroyed (in other words, a collapse of the center notch with the Visualisers left some undeleted textures in the VRAM). Thread affinity I guess, but using RHI Items' texture and FBO IDs made it work, and the manual logic for clearing the texture IDs after 3 frames was no longer needed

# Frame-pacing nuances, yet again

Turns out the decision to blit into the framebuffer directly was a good one, since assigning the imported texture directly to the `colorTexture` of the `QQuickRhiItem` makes the old FPS problem appear again: FPS won't be respected and the surface could be drawn at higher rates than desired. So we still deliberately blit into the FBO even today.

# Final thoughts

My GPU Usage is nice. I think this is it. Further expense comes from QtQuick's Scene Graph rendering, as any parent surface also gets redrawn whenever any child animates, so the bigger a parent's extent (even if it's transparent), the higher the penalty. This is very unintuitive, and can be seen on other shells like Noctalia as well: The Settings UI in Noctalia has no animations except for a blinking text input cursor, and having it blink causes GPU utilisation to go up as well. Furthermore, a simple text marquee animation proves expensive when its parent surface has large extents; the same animation costs nothing when the parent surface is small, despite the text having a fixed size and the parent being transparent.