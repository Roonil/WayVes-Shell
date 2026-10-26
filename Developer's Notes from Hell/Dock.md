# Dock

Where do I even begin with this one? I wasn't even considering a dock at the beginning but as my configuration evolved along with Qt/QML understanding (although still very limited), I desired to have a dock again. I had it in my earlier AGS setup; I used Latte Dock years ago on X11 and it felt nice to have something on your wallpaper just chilling at the bottom. Kinda funny how Wayland suddenly led to the killing of docks because of enhanced privacy constraints among applications, only to get resurrected again. But rant aside, a dock too became a part of the minimal package I cared to ship. And I made the mistake of asking Gemini to generate an image of a dock. Boy, was it beautiful. It was actually very exaggerated, in the likes of pure sci-fi, 3D dock that looked impressive, but would give minimalists pure psychic damage even before they get to look at it. But it gave me something to work with: A fanned-out layout with placeholder cubes/cuboids beneath, with icons mounted on top. I also had made the happy accident of making the Angular Visualiser from WayVes (hereon referred to as just Angular) to be very robust when changing bars, gaps and bar numbers, maximum angles and the like, so I 'naturally' thought that the fanned-out bottom placeholders would just be Angular Bars with spaces in between. Easy, right?

## The Layout

Angular with Bars at the bottom, with Icons on the top "swiveling" with some angle determined by their placement from the center. Active/inactive indicator "rings", also Angular instances, placed 'behind' the icons. And much more importantly (as I took it for granted but it hit me MUCH later on in my config), the bottom Angular Bars would need to serve as the Base and hence should appear going 'into' the screen, and the icons themselves would need to occupy that Bar's space but should appear upright and not go into the screen. The icons, when clicked, would show a Notch that would show Screen Previews (or context menu on a right-click). Also, all Angles mentioned are used in Degrees.

## 1. Initial setup
Throwing in a `Repeater` in a `RowLayout` (this is important!) worked for producing icons in a row, and using a background in the parent `Pane` to show the `Notch` Previews worked of course. A basic dock was indeed working, and some work had to be done for showing the Previews, including tracking all running instances of the clicked application, building the `ScreencopyView` for each and then displaying it in a `ListView` within the `Notch`. It was mostly me fighting QML, simply because I do not like the syntax. But it worked nonetheless. The only hurdle now was to make the icons appear rotated as they go left and right from the center.

## 2. Geometry time
My initial thought process was to imagine the icons as 'embedded' on the surface of an inverted Cone, with its apex / tip below. The Cone's curve would act as a 'guiding surface' for the icons to rotate and 'stick' to. Also importantly, we'd be looking at the icons from some angle from the Horizontal, otherwise we'd just see them embedded radially but along a line. This last Angle, we'd be talking about later. If we could get the individual icons to 'stick' to our Conical surface, then how difficult would it be to just 'rotate' the final output by some Angle to give us this last Angle (`viewTiltAngle`)?

### a. Cones!

Our Cone would need to have 2 parameters: One that determines the Angle of the Cone itself, determining how 'laid out' the Cone would be (referred to as `verticalAngle`), and the other would determine the 'Sweep' of icons (called `sweepAngle`). The Radius would be introduced later on, so I worked with just getting the Angles right. Particularly, the `sweepAngle` is the 'extent' of the Angles the icons would 'swivel' about vertically. If you have a Semi-Circle, with small Chords that lie near the Circumference, all equidistant from the Center and the adjacent Chords would have the same angle between them (this 'same angle' is different!), then the `sweepAngle` would determine the Angle that each Chord on either end would make at the Center of the Semi-Circle. This Semi-Circle would be our Dock, and the Chords would be our icons, viewed from directly upwards, as if looking down on a scene.

`sweepAngle` -> Horizontal extent of Icons' rotations
`verticalAngle` -> Vertical angle of the Conical Surface itself. Setting it to 0 would mean the icons appear upright, 90 would mean laid flat out, because our surface itself is now 'flattened out'.

I had stumbled upon the `transform` array of QML objects before, and I naturally thought of using those to combine my rotations, since both rotations are independent. 

But first, we needed to prepare some helper variables, primarily to get the index from the center rather than from left to right, so that our rotations apply nicely to the left and right halves from the center for preserving Symmetry. `indexFromCenter` does exactly this. `fractionIndexFromCenter` divides `indexFromCenter` by the total length, to essentially get our output in the range from -1 to 1, inclusive of the edge values. First up:

### Cone Angle
As a naive QML/Math guy, I expected just applying `verticalAngle` rotation to the icons along the X-Axis would work and I'd be on my merry way to solve other 'important' problems, and I'd be half right if I didn't see that the rotations 'looked' right but not good enough. But I obviously thought that it was due to no implementation of `sweepAngle`, so I went on to implement that too. Implement a basic overall structure first, then worry about the nuances later. 

Since `verticalAngle` would apply to all icons agnostically (nuance with this caught much later, unfortunately), it'd require no other calculations based on indices, but `sweepAngle` would definitely. Primarily, the `axis` property of the `Rotation` transform allows us to give values for the 3 spatial axes, ranging from -1 to 1.

```
Rotation {
        angle: verticalAngle
        axis {
                x: 1
                y: 0
                z: 0
            }
        origin.x: iconWidth / 2
    }
```

### Sweep Angle
Ah yes, the tricky one!

To reason about this one, I assumed `verticalAngle` to be 0, that is our conical surface is essentially a vertical wall, so our Icons won't really rotate because of the surface. Just plain-old Icons in a RowLayout again!

In this set-up, our direction of rotation would stay along the Y-axis, but the angle's sign would need to be mirrored from the center, as otherwise all icons would just turn in one direction and it'd look like an icon line just facing in one horizontal direction, like prison mates in line for their lunch break. So we could use `Math.sign(indexFromCenter)` to determine this behaviour, to get -1, 0 or 1 based on the value of `indexFromCenter`, and in the end all icons indeed would turn to 'face' the center. Also, the origin for the rotation would need to be at the center of our icon. Mission accomplished! (For now!!)

```
// angleFromCenter = fractionIndexFromCenter * sweepAngle

Rotation {
        angle: angleFromCenter             
        axis {
            x: 0
            y: -Math.sign(indexFromCenter)
            z: 0
        }
        origin.x: iconWidth / 2
    }
```
The Angles still didn't look right, so I attributed it to not having implemented the radial displacement at all, since all icons still appeared along a RowLayout in a line. The actual nuance though, was also caught later on. 

### Radial Displacement

Of course I thought a `Translate` transform in the Y-Axis based on `indexFromCenter` modulated by a cosine function would work, applying a radial displacement in the Y direction to make icons displace upwards the closer they were to the center.

### Nuances that piled up all at once

Honestly, this whole setup actually looked pretty convincing. Pretty convincing except for ONE subtle fact. It all seemed to work only on some 'nice' values. `verticalAngle` would only look good at 60 or 70 degrees. Same for some `sweepAngle` value. The Radial Displacement also looked cursed because on large enough values it took the form of the first half of the overall cosine function. Something clearly wasn't right.

#### 1. Cone Angle
Remember that I assumed that this innocent property would apply agnostically to all Icons? Yeah that's wrong because 3D perspective, although very intuitive for our eyes to perceive in everyday life, can actually trick your common sense into assuming things that aren't really true, and also because I haven't really done any work on Perspective Shifts, Stereographic Projections and such. But the nuance is from the fact that `verticalAngle` would affect the surface on which the Icons 'stick', and this surface would not only just affect rotation along X-Axis. Because, if viewed from the front, standing directly in front of the central icon, the surface would slowly 'curve' into Z and Y directions. It is NOT like a thin cylindrical section, but rather the lower boundary of this section would have a slightly less radius than the boundary at the top, so essentially it's a curved strip all along. It would appear to only rotate along the X Axis if it's the icon at the center. For other Icons, it would continue to affect the Y and Z Axes as well.

I do not remember how I arrived at this rotation mechanic. It was either pure brute-force, or I narrowed down my scope by some 'intuition' that I thought was right at that point in time. But even still, it holds up pretty nicely:

```
Rotation {
        angle: verticalAngle
        axis {
                x: 1
                y: -(fractionIndexFromCenter)
                z: (fractionIndexFromCenter)
            }
        origin.x: iconWidth / 2
    }
```

`fractionIndexFromCenter` is from -1 to 1, and because axes need to be supplied in that range, we use this parameter. Essentially, it tells the Rotation to affect the Y and Z Axes as we move away from the center. Think of it like this: If you embed or stick images on the surface of an inverted cone at the same height, then they will also appear to be 'rotated' along the radially-outward Axis from each image as you move away from the Center. One Nuance down the drain! (There is still one left but thankfully it was easy to reason about, during the finale of the Dock Saga).

#### 2. Sweep Angle

Learning a bit from my `verticalAngle` journey that perspectives can be deceiving, I suspected that at least the X or the Z axes would need to be rotated along as well. Some more brute-forcing and trying out various angle combinations, it felt that although the Sweep itself looked nice, it still didn't look nice on the X-Axis rotation when combined with `verticalAngle`. But I had already applied rotation along this axis for `verticalAngle`, and I couldn't figure out how to get the two to essentially 'combine' together in this sense. That's when axis manipulation struck me. The following snippet works very, very well:

```
// angleFromCenter = fractionIndexFromCenter * sweepAngle

Rotation {
    angle: angleFromCenter
    axis {
        x: verticalAngle / 90.
        y: -Math.sign(indexFromCenter)
        z: 0
    }
    origin.x: iconWidth / 2
}
```

Essentially, `verticalAngle` would realistically be between 0 and 90, since it's the 'vertical' angle. The `axis` variables for each of the spatial axes take values from -1 to 1, determining how much the angle would rotate along the axis. `verticalAngle / 90.` gives us a range from 0 to 1, and essentially allows `sweepAngle` to rotate our Icons along the X axis in the same extent as the `verticalAngle` did. This is because `sweepAngle` now has information about the 'vertical steepness' of the conical surface, and thus would also affect the current Icon's rotation by that extent. This effect is much more prominent when you compare both the versions of `sweepAngle`'s implementation when `sweepAngle` is some high value, such as 180-190, essentially meaning that the icons at the edges look completely towards the center. The rotations along the X-Axis of the icons (it'd be Z-axis for us now!) won't look as convincing in the first version, but would do a good job with the improvement. 

Another nuance down the drain! It's just Radial Displacement now, right?

#### 3. Radial Displacement
On this episode of 'doing everything right only to realise you did it all wrong from the beginning', Radial Displacement proved to be more than a cosine displacement of course. I mean I had the intuition for that beforehand but had pushed it to the very last to solve. Now was the time to include `tiltAngle` in the scene, which would essentially give us the radially-displaced view. I initialised 2 variables for `viewDistanceWidth` and `viewDistanceHeight` to signify how far away the viewer is from the dock, and how high up he is. Using some basic trigonometry with Triangles drawn in `kolourpaint`, I quickly got the relation for how much the radial displacement for an icon should be based on the distance, and just applied the `Translate` along X and Y directions appropriately. The Radial Displacement would be multiplied with the Angle - wait, what Angle? `sweepAngle` was the swivel angle of the icons themselves, but this angle would essentially give us the extent of the angle of the Dock we'd be covering with the Icons.

Going back to our Semi-Circle and Chords analogy, when viewed from straight up, the angle between the individual chords (the 'same angle' from before!) would be determined by this angle: `viewSweepAngle`. `sweepAngle` is concerned with individual Icon's rotations, `viewSweepAngle` determines the Angular extent of the Icons' placement on the Dock itself. So 180 would mean that our icons occupy all of the Semi-Circle, 120 means our Icons would only go 60 degrees from the center to the left and right of the Semi-Circle, and so on. 

With this new, cursed knowledge at hand, it was simply a matter of time before I got the angles for each Icon, mapped them to the Polar Coordinates and translated them properly. Also to respect `tiltAngle`, which was derived by `viewDistanceWidth` and `viewDistanceHeight`, I simply multiplied the sine and cosine of that value for the Y and X translations. And eventually, I got rid of `viewDistanceWidth` and `viewDistanceHeight`, and introduced `viewTiltAngle`. Essentially, when `viewTiltAngle = 0`, we'd be looking straight down at the Dock and it should appear as a Semi-Circle, and when `viewTiltAngle = 90`, we'd be looking at it from the Center of the Semi-Circle, so the Icons would appear in a straight line. 

Also, I figured it was long overdue, since I actually had a valid 'backing' to validate my rotated Icons with, since anything could look 'convincing' with one set of values but not so much after tweaking any one of them. I used my Angular Visualiser for this: exported `DMABuf` and for my Pane holding the Dock Icons, put it in the `background` of the dock, and transformed it by applying Rotation to it on the X Axis with `viewTiltAngle`. As for the Angular Visualiser itself, I made it so that the Bars were thin, like spokes, going out from the center to the desired radius. Also, trivial but important, derived the logic for placing the bars at the correct positions, given the number of bars and the `viewSweepAngle`, to match them with my Icon's placements. Essentially, if I modified `viewTiltAngle`, then my `Angular DMABuf` would rotate, and by my calculations, the icons should also rotate 'inwards' to the screen. 

This was the final piece in the jigsaw, and when I ran it, I could see that I solved the jigsaw, the pieces were right but the resulting picture was wrong. Radial displacement looked HORRENDOUS, if I say it nicely. Absolute menace, some icons were going here, some going there. With some minor corrections and adjustments in my calculations, it still wasn't convincing. The Icons didn't even look to be on a Semi-Circle when `viewTiltAngle` was 0 degrees! Thankfully, I stumbled upon this innocent-looking code that I had laid out in the beginning of my Dock's layout:

```
RowLayout {
    Repeater {
        model: combinedApps
        delegate: IconImage {
            ...
        }
    }
}
```

And that's when it hit me like a brick going at cosmic speeds right on my head. `RowLayout` itself was positioning my icons along the X axis, and I was also including X axis displacements in my `Translate` transform, and necessarily so, because otherwise the displacements won't be mathematically correct. 

The solution? Ditch the `RowLayout`, and go for an `Item` instead: It'll originally place ALL Icons at one spot and from there I could calculate the Radial Displacement for each Icon!

## Radial Displacement, Contd.

`Item` does a great job at reporting its children at 0 width and height, sometimes even when you explicitly set them (I really wish it's just me writing bad code at this point). Overall, setting `Repeater` within my `Item` worked, Icons were now at the same place. We'd just need to calculate the X and Y displacements based on the Radial Displacement and the `viewSweepAngle`, convert them from Polar Coordinates to Cartesian Coordinates and then use them in our `Translate` transform. At this point, Radial Displacement also became the sum of `radius` (the Angular Bars' radius) and `radialDisplacement` (the Icons' offset from it).


But even that didn't look convincing. I still tried some other combinations, reasoned about in `kolourpaint` for some time, but couldn't see what felt 'wrong'. Essentially, my rotated Icons didn't match with my Angular Visualiser, which was rotated using `Rotation` transform with `viewTiltAngle`. They matched perfectly fine when `viewTiltAngle = 0`, a Semi-Circle. It was at this time when another brick came flying by: 

## Perspective Projection

To put it simply, QML, when rotating anything along the X Axis, applies a distortion on the object that makes it feel like 'squished' from the edges as you go 'up', like the train tracks converging to a single point. If you rotate a Rectangle along the X Axis in this way, QML's rotation would show you a Trapezoid. But since I was just applying Translation, I'd essentially not get the same perspective, hence the `tilt` looked wrong. 

Rotating the whole Dock about the X Axis with this angle should indeed work of course!

The following Rotation was applied to the Dock itself, instead of just the `background` holding the `DMABuf` from Angular: 

```
Rotation {
            angle: viewTiltAngle
            axis {
                x: 1
                y: 0
                z: 0
                }
            origin.y: dockPane.height
            origin.x: dockPane.width / 2
        }
```

Boy, did it work! Icons were indeed spaced out correctly, even followed the tilted perspective, appearing like a projected dock. With one small problem of course: The icons were also rotated and squished into the screen with the Dock itself. 

This was because all Rotations were internally 2D, so even if I rotated my Icons by 90 degrees along the X Axis, and then applied the tilt angle to the Dock, it'd still not 'undo' the rotation of the Icons. I thought about using the native 3D rotations, but to render a dock using 3D rotation, scenes and cameras would be overkill. And by this point, it was nearly done as well! Just the icons needed to stand upright instead of getting squished along with the Dock. But despite the squishing of the Icons, they all aligned perfectly well with my Angular Visualiser! Reducing or Increasing the `radialDisplacement` matched with the Spokes from Angular, even with `viewTiltAngle` specified. 

If I could just get the coordinates of this rotated view for each Icon, then I could manually translate each Icon in a separate, non-rotated view to its correct position. `mapToItem` felt so alluring! What else could there be?

## MapToItem
Essentially, `mapToItem` transforms the coordinates from one Coordinate System to another. For a Rectangle inside another Rectangle, (0, 0) would be the top-left of the child Rectangle, but to get the same point in the Coordinate System of the parent Rectangle, we can use `mapToItem`. And it works for any Items as long as you can access them. So essentially, the strategy would be to NOT touch the correct dockPane logic so far, except for:

1. Changing `IconImage` to just `Rectangle` or `Item`
2. When the Widget fires its `onCompleted` method, we'd simply populate this Item/Rectangle into an array inside the dockPane to 'track' the individual Items that WOULD be rendered at the expected place
3. In our non-rotated layout, run the Repeater along dock Icons again, and this time, get each mapped item from our array from step 2, use `mapToItem` and then use `Translate`

Of course it did not work. Gemini says it's because `mapToItem` is not useful when it comes to perspective-projected coordinates. I immediately went into Panic mode: the Dock was literally near completion save for this last nuance.

I asked Gemini (politely) if it could generate a QtQuick/QML program that would essentially re-construct the rotation: Any view rotated with X-axis `Rotation` transform, should be able to be 'tracked' at any given coordinate from a non-rotated view. Thankfully, the code it generated worked quite well. Also, worthwhile to mention at this point, `Rotation` transform also has a `distanceToPlane` property, that is used to calculate the amount by which the scale would change when applying a rotation. By default, QML uses a value of 1024 (the dock sets it through `perspectiveDistance`, 2048 by default).

I ran the generated code and it actually gave good results! It was a program that displayed a point in a rotated Rectangle, and generated a "Tracking" text on top of it from the non-rotated view. It worked, until it stopped working. It didn't really work for steeper angles.

Prompted Gemini (politely) again, and it said that internally, QtQuick uses some shortcut to calculate the apparent depth value, and it updated it accordingly into its coordinate calculation function. It also generated a circle with a border around the tracked particle (from the non-rotated view) to better show the fact that the circle should stay centered on the tracked particle (which is on the rotated Rectangle). And finally, THAT worked! No edge cases, just plug in the local coordinates of the particle, the origin of rotation and the angle of rotation with the same `distanceToPlane` as that of the `Rotation` transform, and it'd give the rotated coordinates!

With this example at hand and with hope re-filling, I took to it again. I still got the coordinates from the array that I was maintaining earlier, and applied the function Gemini generated to it, but of course it didn't give the expected results. I tried all possible Permutations of the `mapToItem` method, but nope. After some cursing, even tried printing the coordinates of each Item placeholder, manually placing them in a local array, and using values from there, but still no banana. After some more cursing, it hit me that I can just do away with the array altogether, because I can re-construct my coordinates now. Lo and behold, implementing just the `radius + radialDisplacement` displacement from Polar to Cartesian and then supplying in the `viewTiltAngle` to the method worked! 

## Eh, what now?

Welp, I couldn't get away without using some 'magic numbers'. Essentially, the projections and rotations were just right, but they didn't really match with the 'spokes' from Angular. If the icons were dead-center on spokes when `viewTiltAngle = 0`, they should stay on the center when `viewTiltAngle` changes. They appeared to be some pixels left and right, and some more pixels up and down. And this is where it all hit me at once: Rotation Origins.

While applying `verticalAngle` and `sweepAngle`, I was only concerned with setting the origin at the horizontal Center of the icons. But in our implementation now, both these rotations' origins should be centered horizontally AND from the bottom of the icons. Because simply put, we are moving the icons to some place as dictated by the `viewTiltAngle`, then keeping the bottom of them intact, applying `verticalAngle` and `sweepAngle` rotations. To adjust for that, simply adding `origin.y` was enough for both the rotations:

```
// angleFromCenter = fractionIndexFromCenter * sweepAngle
// (0, 0) is top-left in Qt's Coordinates, and Y Axis goes down by default!

Rotation {
    angle: angleFromCenter
    axis {
        x: verticalAngle / 90.
        y: -Math.sign(indexFromCenter)
        z: 0
    }
    origin.y: iconHeight
    origin.x: iconWidth / 2
},
Rotation {
    angle: verticalAngle
    axis {
        x: 1
        y: -fractionIndexFromCenter
        z: fractionIndexFromCenter
    }
    origin.y: iconHeight
    origin.x: iconWidth / 2
}
```

Finally everything works! Bottom of the Icons stay perfectly aligned with Angular Bars. All angles work fine!

## Miscellaneous, because this rant wasn't enough

To give the Icons a 'floating' look, I added `iconFloatHeight` property, that would essentially translate the icons upwards with that value, so it would appear as if the icons are floating on top of the Angular Bars.