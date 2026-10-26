# Notch

I think some of the earlier rices I saw had the Notches look, and I always kinda preferred that look, and mainly the reason I tried using any quickshell config in the first place. It also was reminiscent of the super-early Latte dock/KDE Plasma cool setups I saw years ago, and while not true notch-like in the sense of inverted radii, it 'clinged' to the edges on active Windows and that looked very satisfying. So we had to have Notches!

# What's an Item?

The heading suits because I tackled Notches without getting into the whole shell first: Just to verify my primitive can hold. By this time I had no idea that `Items` are supposed to have dimensions of 0 unless specified otherwise, and by then my idea for a notch was one that always grows downwards.

Looking into other shells and noctalia, I saw they drew circular arcs as the radii with the QtQuick Shapes and made them appear in a row/column beside the main rectangular container and that gave the look of a notch, so I also used that way initially: `RowLayout` (yes I knew a `RowLayout`, some of my Flutter work has seemed to pay off) containing the notches and the main content holder.

By this time, the desired minimum header and content dimensions were desired, and the resulting painful `implicitWidth` / `implicitHeight` calculations were a mess to look at but they worked. And I always wanted them to activate on Hover rather than a click, so I went with it, juggling the root `PanelWindow`'s `input mask` that sometimes didn't just work at all, leaving my screen inoperable/unclickable. Fun times!

# When things start getting out of hands, grow a hand

I introduced directions when my shell began growing more, and when the idea of nested notches weirdly clicked (hovered?) and held, and I had to introduce a ColumnLayout purely because of the vertical allowed directions. Also, to accommodate the fact that the parent Notch would need to stay open as long as one of its child notches was hovered onto, a short "parent-finding" logic was written, so that a nested notch would have a reference to its parent notch and can modify its property to make sure it stays expanded when the child is expanded. It worked, but the code was becoming messy. And nested notches posed another problem: What if the nested notch grows out of bounds of the parent notch? The parent notch, let's say it opens downwards, and a nested small notch that clings to the left side of the expanded parent notch wants to grow and its bottom grows lower than the bottom of the parent notch. The parent notch would still show its rounded bottom-left radius curving and going upwards, but realistically, to give a more 'union' like feel it would need to grow downwards (negative radius again), and the radii of the nested notch and the parent notch near that junction would also need to agree on the height difference. 

Because the shell largely contains left-side nested notches, I made the choice of making the adjustments solely for this case, and that rule still holds today. 

Back to the problem, when my Notches were just Rectangles in disguise, I made a `checkbottomLeftOverflow()` function that would work whenever a notch would expand or collapse (`onExpandedChanged`) and it solved the exact problem I described above, with some Coordinate transforms so the parent and the child notches had the same coordinate space, looking for height difference between the two and modifying their radii to match the difference. Also for this case, I had to introduce those special circular arcs that actually drew the negative radii, and had to properly adjust their sizes to match these specific cases, and the `implicitWidth/implicitHeight` logic only grew so much more complex with the added radii, the directions and such. But it held. Having a separate `ColumnLayout` also meant I had to make sure the variable names for the radii matched even when they didn't hold up because of the way the logic was already written, but it held still.

Some problems began to show eventually and while they weren't really 'huge', considering the Notch system actually worked, but I figured I'd need a refactor anyways. First, seams/breaks on Fractional Scaling. Because the negative radii weren't really the part of the actual content-holding `Rectangle`'s shape, there were gaps in them on fractional scale values, and no amount of alignment would fix it. The second problem became apparent with Shadows.

# Shadows

I initially wanted Material-3 type tonal shadows and found out they use a stack of shadows to show that behavior, and I really liked them in Flutter. Implementing the Shadows, I found out my nested Notches would also show the shadow drawn underneath and now the parent and the nested notches clearly looked separate. Using `DropShadow` straight onto the parent notch, it actually made it look like one shape and the dropshadow sat beneath the overall shape, but it worked by actually applying the shadow to all of the children elements as well, even on my `DMABufSurfaces` and that was kinda a problem (it still is, more on that later), because that meant my shell was going to be expensive to render even still. I needed a way to actually make sure the overall shape data of parent + nested notches was consistent so that it can be fed to the Shadow rendering system (the new Notch rewrite still doesn't do this, particularly because items don't seem to get tracked dynamically, and Notches have all sorts of dimensional changes so while the actual shape-union was achieved in a later version, it was dropped because the child notches were no longer sitting at their expected places occasionally). Also, my Notches could only show negative radii based on one direction: Up, Down, Left or Right. They weren't smart, and couldn't make it so that the notch would show 3 or 4 negative radii such as when clinging to 2 edges.

# Rewriting because why not?

I needed 2 things:
    1. The content sizing logic
    2. The shape data
   
Contents were loaded in dedicated `Panes` because they have holders for directional paddings, and also give an optional background Item to override, which I used in my Wi-Fi/Sound/Bluetooth controls. The minimum/maximum heights were annoying to deal with yet again but they worked eventually. Now remained:

# The SHAPE

Dealing with the negative radii especially for the bottom overflow state within the first draft, I eventually realised that a way to make the radius just negative and for the shape to flip to that radius appropriately would be a huge win: I can make the bottom-left radius be positive and it'll go upwards, make it negative and it should expand out like a negative radius. The eventual realisation that even this expansion of the negative radius can happen in 2 directions came kinda later, but it wasn't too late. But I should have caught it beforehand. The function `generateRadiiBasedOnDirection()` lays out per-corner radius based on the expansion direction for the Shape path to consume.

By this point, I had already introduced my Notch directions as proper enums as well, and used them in drawing the corners too. It was also clear that a single `radius` value should be used to dictate the radii at the 4 corners, negative or positive, but ultimately they could be overridden.

Fairly confident in my QML Shape skills, thanks to the extensive time I spent drawing the Spotify-style 15-second forward and backwards buttons, I got into it. The idea was simple: Make the content define the sizes, and the path painter should paint the path.

We start at the top-left corner, going clockwise. We draw a line, encounter a corner, and then decide the curvature logic: If the radius for that corner is positive, curve inwards. If negative, lay outwards appropriately as dictated by the Notch's direction. I only catered to the 4 types of directional notches, so I made a helper `ArcGetter` function that would draw the radius appropriately while also making sure we continue our next line for the edge at the correct place.

Now came the problem: A negative radius for a corner might mean 2 things: The expansion could be either in the direction of the shape we are drawing, or perpendicular to it. Consider this case: 

We start from the top-left corner and assume it has a radius of 0. We draw the top edge, going from top-left corner to the top-right corner. Positive radius means we curve inwards and go downwards. But a negative radius can mean 2 things: The outwards fling/expansion of the protrusion can lay in line with the top edge; we have the classic downwards notch case here. But it might also go upwards: the case when the notch opens leftwards, clinging to the right edge.

Having this as a Notch direction-based switch seemed not generalised, so I introduced flip* `bool` properties: such as flipTopRight: true. Whenever a directional flip was false, the protrusion would lay in line with the direction of drawing (clockwise), and would lay on the other edge if true. This made everything turn out nicely! I am just glad I didn't follow through with my complex-plane rotation idea here: using imaginary numbers for deciding the phase shift of the incoming direction seemed like an overkill even to me.


By this time, aliasing was becoming more prominent. Using `layer.enabled` for anti-aliasing showed another challenge: The negative radii went outside the specified incoming dimensions from the content item (because they're the inward bounds) and using `layer.enabled` on these surfaces makes any outlying items get clipped, so essentially my negative radii were clipped. To fix them, 2 overflow calculation overrides were written for each edge, so that the incoming dimensions to the shape already had the negative radii within the bounds, and the notch painter deduced the reverse to draw the shape at the actual dimensions while keeping the negative radii in bounds.

The calculations also allowed to have a border color on the Notches with a given `strokeWidth`, and while it's cool, I didn't use it because the nested notches would overlap at those strokes and wouldn't look good, as we can't selectively mark the edges to show a stroke or not.

Using the smoother `Shape.CurveRenderer` made things smoother but kinda worse sometimes: Occasional filled color breaking (drawn edges didn't land on integer values or some overflow values resulted in negative path values), happened mostly during some frames at the end of the collapse animation. It was initially solved by using rounded values that mostly made it rarer still to happen, but the real fix was to clamp the drawn edge's radii from exceeding the edge during the drawing phase. Thanks for this one, Claude!

Just to torture myself further, I also seemingly wanted to make the edges of my Notch cling to more than one direction (so they can show negative radii on more than 2 edges if required). It meant my enums needed to be able to be OR'd, so we made them bits, and it also meant that a direction of 'None' would mean we have >=0 corners on all 4 sides, classic `Rectangle` case.

For this, I thought of 'tracking' how many times we encounter a corner when giving a direction. Giving an opening direction of downwards and leftwards means the notch should cling to the top and right edges. Assuming an input radius of 25 for this case, the radii for each corner would be:

- top-left = -25 (flip: true)
- top-right = 0
- bottom-right = -25 (flip: false)
- bottom-left = 25

The downwards direction classically made only the top-left and top-right radii negative and top-right was not flipped, while the leftwards direction classically made only the top-right and bottom-right radii negative and top-right was flipped. Other 2 corners for both cases separately were classically made positive.

The corner radius for any such directional combination could come out to be (surprise, surprise) negative, 0 or positive. Looking closely, the flip* bools mattered the most for each combined direction outcome, so they needed to be tracked properly.

A 'voting' mechanism was introduced in the form of 4 local tracker* variables within the radii-generation function. Essentially, we start with all flip* bools as `false`, and all 4 corner radii as positive effective radius, and the function makes it so that the second influence to any corner marks the radius for that corner to be 0, and more influences just mean we need to flip the negative radii's directions. The `undefined` and 0 based conditional checks within the function do just this: `undefined` for the tracker* value means the corner was never encountered, <0 means flip for that corner is false, 0 means the radius is 0 regardless of the flip, and >0 means flip for that corner is true.

It works exceptionally well as I am not confident in my algorithm skills even now, but it works well yet again. A win is a win is a win.

# Shadows, again

I won't make this long, since my previous attempts to actually make the nested shape be considered a part of the parent shape so the shadows would work correctly by treating the whole surface as one were very long and draining. The trick was to make it so that the parent of the painted shape of a nested notch was the same as that of the parent notch's painted shape, and while reparenting works, the coordinate magic doesn't: even `mapToItem()` isn't reactive and any reactive hacks that were used proved to only work half the time. I still haven't tried the reparenting + dynamic tracking approach with Claude, since it worked a bit to remove the seams in the rewrite as well. The seams in this case were encountered at the edges of the parent and children notches, and only appeared either with `layer.enabled` or at fractional scales again. The fix was to make sure the coordinates we pass into our Shape are 'snapped' taking into account the fractional scale and the window coordinates, ensuring only integer values get passed while drawing the shape. Seams also appeared exclusively by using Shadows at fractional scales, and it was because the content was drawn back from the texture that was used to make the Shadow, it just made the final visual not sit at the correct coordinates. Drawing the content as-is instead of drawing it from the texture fixed it. 

The `bool` `applyToShape`, when `true`, makes shadows underneath each Notch individually, so child Notches will appear discontinuous at the shadow level. When false, the old behavior of the 'single shape, but shadow is calculated for the whole surface' is back, which can be kinda expensive as it also applies on live surfaces including `DMABufSurfaces`. The individual *Extent properties of shadow also behave a bit differently for the 2 cases, because in the former we also take into account the out-of-bounds extent of any child objects, since they all get rendered to a layer, and out-of-bound items in a layer get clipped.

# Closing (Collapsing) remarks

Man, I don't know. I really didn't expect to make a multi-directional Notch for a demo of a shell that showcases a DMABUF pipeline that in turn showcases the Visualisers I made. Maybe I should start getting more sleep.