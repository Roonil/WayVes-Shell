#!/usr/bin/env python3
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCHEMA_PATH = os.path.join(ROOT, "Properties", "Properties.schema.json")
CONFIG_PATH = os.path.join(ROOT, "Properties", "Properties.json")

def num(desc, default=None, minimum=None, maximum=None, integer=False):
    d = {"type": "integer" if integer else "number", "description": desc}
    if default is not None: d["default"] = default
    if minimum is not None: d["minimum"] = minimum
    if maximum is not None: d["maximum"] = maximum
    return d

def boolean(desc, default):
    return {"type": "boolean", "description": desc, "default": default}

def obj(desc, props, required=None):
    d = {"type": "object", "description": desc, "properties": props, "additionalProperties": False}
    if required: d["required"] = required
    return d

def pad(where, side):
    return num(f"{where} padding on the {side} side, in px. Overrides the matching *HorizontalPadding/*VerticalPadding and *Padding keys.", minimum=0)

PRECEDENCE = ("Padding keys follow Qt Controls: a side-specific key (e.g. headerLeftPadding) wins over "
              "headerHorizontalPadding/headerVerticalPadding, which win over headerPadding. Leave a key out to fall through.")

drop_shadow = obj("Drop shadow drawn under the notch.", {
    "enabled": boolean("Draw the shadow.", False),
    "applyToShape": boolean("true: the shadow follows the notch's own shape only. false: it's computed from everything the notch "
                            "draws, including child notches that protrude from it, captured within the extents below.", True),
    "leftExtent": num("Capture padding left of the notch, in px, for content shadows (applyToShape: false). Size it to cover "
                      "child notches that protrude to the left, or their shadows get cut off. Not the visible shadow size.", 30, 0),
    "rightExtent": num("Capture padding to the right, in px. See leftExtent.", 30, 0),
    "topExtent": num("Capture padding above, in px. See leftExtent.", 30, 0),
    "bottomExtent": num("Capture padding below, in px. See leftExtent.", 30, 0),
    "verticalOffset": num("Shadow offset downwards, in px.", 8),
    "horizontalOffset": num("Shadow offset to the right, in px.", 0),
    "color": {"type": "string", "description": "Shadow colour (any Qt colour string, e.g. \"#80000000\"). Defaults to a dark tint of the theme's primary colour."},
    "blur": num("Blur radius of the shadow, in px. Keep the extents at least this large for content shadows.", 32, 0),
    "spread": num("How much larger than the notch the shadow is, as a fraction of its size (0.1 = 10% larger).", 0, 0),
})

notch_props = {
    "radius": num("Corner radius, in px. Capped at half the notch's width and height.", 28, 0),
    "minimumHeaderWidth": num("Minimum width of the header (the always-visible part), in px. -1 for none.", -1, -1),
    "minimumHeaderHeight": num("Minimum height of the header, in px. -1 for none.", -1, -1),
    "headerPadding": num("Padding on all sides of the header, in px. " + PRECEDENCE, 0, 0),
    "headerHorizontalPadding": num("Left and right header padding, in px. Overrides headerPadding.", minimum=0),
    "headerVerticalPadding": num("Top and bottom header padding, in px. Overrides headerPadding.", minimum=0),
    "headerLeftPadding": pad("Header", "left"), "headerRightPadding": pad("Header", "right"),
    "headerTopPadding": pad("Header", "top"), "headerBottomPadding": pad("Header", "bottom"),
    "minimumContentWidth": num("Minimum width of the expanded content, in px. -1 for none.", -1, -1),
    "minimumContentHeight": num("Minimum height of the expanded content, in px. -1 for none.", -1, -1),
    "contentPadding": num("Padding on all sides of the expanded content, in px. Same precedence as headerPadding.", 0, 0),
    "contentHorizontalPadding": num("Left and right content padding, in px. Overrides contentPadding.", minimum=0),
    "contentVerticalPadding": num("Top and bottom content padding, in px. Overrides contentPadding.", minimum=0),
    "contentLeftPadding": pad("Content", "left"), "contentRightPadding": pad("Content", "right"),
    "contentTopPadding": pad("Content", "top"), "contentBottomPadding": pad("Content", "bottom"),
    "panelOpacity": num("Opacity of the notch's fill (its content stays opaque). Falls back to the parent notch's value, so a child "
                        "protruding from its parent matches it at the join, then to the shared notch.panelOpacity.", 0.65, 0, 1),
    "overshoot": num("Overrides the shared notch.overshoot for this notch.", minimum=0),
    "squash": num("Overrides the shared notch.squash for this notch.", minimum=0),
    "dropShadow": {"$ref": "#/definitions/dropShadow"},
}

def notch(desc, extra=None):
    props = dict(notch_props)
    if extra: props.update(extra)
    return obj(desc, props)

attach = {"type": "string", "enum": ["none", "top", "edges"],
          "description": "How the bar's notches attach. none: every notch floats with rounded corners. top: notches flare into the "
                         "top edge (topMargin is ignored). edges: also into the screen's sides (both margins are ignored)."}
style_props = {
    "attach": attach,
    "topMargin": num("Gap between the screen's top edge and the bar, in px. Only used with attach: none.", minimum=0),
    "sideMargin": num("Gap between the screen's sides and the outer notches, in px. Ignored with attach: edges.", minimum=0),
}

schema = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "$id": "Properties.schema.json",
    "title": "wayves-shell Properties.json",
    "description": "Layout and behaviour of wayves-shell. Every key is optional; a missing key uses the default shown on hover.",
    "type": "object",
    "additionalProperties": False,
    "definitions": {"dropShadow": drop_shadow},
    "properties": {
        "$schema": {"type": "string", "description": "Path to this schema, for editor validation and hover docs. Ignored by the shell."},
        "bars": obj("The top bar and the side bar.", {
            "top": obj("The top bar.", {
                "exclusiveZone": num("Space the bar reserves at the top of the screen, in px. Windows are laid out below it.", 40, integer=True),
                "behavior": obj("The bar's resting style and the style it switches to while the focused workspace has windows.", {
                    "changeWhenWindowOpen": boolean("Switch to the windowOpen style while the focused workspace has a window. "
                                                    "false keeps the default style at all times.", True),
                    "default": obj("Resting style.", {
                        "attach": dict(attach, default="none"),
                        "topMargin": dict(style_props["topMargin"], default=10),
                        "sideMargin": dict(style_props["sideMargin"], default=12)}),
                    "windowOpen": obj("Style while the focused workspace has a window. Missing keys come from default.", {
                        "attach": dict(attach, default="edges"),
                        "topMargin": style_props["topMargin"], "sideMargin": style_props["sideMargin"]}),
                }),
                "left": obj("Left of the bar.", {"notch": notch("Workspaces notch.")}),
                "center": obj("Centre of the bar.", {"notch": notch(
                    "Clock notch. Expands into the media widget; the wallpaper picker opens from it.", {
                        "bottomNotch": notch("Notch hanging below the media widget (WayVes logo)."),
                        "sideNotch": notch("Player selector beside the media widget, shown with more than one player."),
                    })}),
                "systemTray": obj("System tray, left of the controls.", {
                    "notch": notch("Tray notch. Collapses to nothing while the tray is empty (its header minimums and padding are then 0)."),
                    "sideNotch": notch("Notches for tray menus and submenus."),
                }),
                "right": obj("Right of the bar.", {
                    "notch": notch("Controls notch (Wi-Fi, Bluetooth, sound)."),
                    "sideNotch": notch("Side notches of the controls cards, e.g. the sound card's output streams."),
                }),
            }),
            "side": obj("Side bar on the right edge (system usage).", {
                "rightNotch": notch("Main side-bar notch (CPU usage and temperatures)."),
                "topNotch": notch("Memory notch, protruding from the main notch."),
                "bottomNotch": notch("GPU notch, protruding from the memory notch."),
                "activationWidth": num("Width of the strip along the right edge that reveals the side bar, in px.", 10, 0),
                "activationHeight": num("Height of that strip, in px, centred on the side bar's window. Defaults to the window's "
                                        "height (1000).", 1000, 0),
                "showHoverRegion": boolean("Draw the hover region (translucent red), for tuning activationWidth/activationHeight.", False),
            }),
        }),
        "dock": obj("The dock: app icons fanned out on a tilted arc, drawn over WayVes' Angular bars.", {
            "radius": num("Radius of the arc the icons sit on, in px.", 1000),
            "viewTiltAngle": num("Viewing angle of the dock, in degrees: 0 looks straight down (icons on a semicircle), 90 looks along "
                                 "it (icons in a straight line).", 75, 0, 90),
            "viewSweepAngle": num("Angular extent of the arc the icons are spread over, in degrees.", 120, 0, 360),
            "sweepAngle": num("How far the outermost icons turn to face the centre, in degrees.", 110),
            "verticalAngle": num("How far the icons lean back into the screen, in degrees: 0 stands them upright.", 27, 0, 90),
            "indicatorDistance": num("Extra radial distance of the running-app indicators beyond the icons, in px.", 10),
            "indicatorWidthScale": num("Indicator width as a multiple of iconWidth.", 1.2, 0),
            "indicatorHeightScale": num("Indicator height as a multiple of iconHeight.", 1.2, 0),
            "radialDisplacement": num("Offset added to radius for the icons and indicators, in px (negative pulls them inwards).", -160),
            "indicatorFloatHeight": num("How far the indicators float above the bars, in px.", 15),
            "iconFloatHeight": num("How far the icons float above the indicators, in px.", 20),
            "iconWidth": num("Icon width, in px.", 80, 1, integer=True),
            "iconHeight": num("Icon height, in px.", 80, 1, integer=True),
            "perspectiveDistance": num("Distance to the projection plane for the tilt (Qt's Rotation.distanceToPlane; Qt's default is 1024). "
                                       "Smaller values exaggerate the perspective.", 2048, 1),
            "hoverWidth": num("Width of the area the cursor can move in while the dock is shown before it hides again, in px.", 1600, 0),
            "hoverHeight": num("How far above the bottom edge (past the 20 px base, the icon and indicator float heights) the cursor "
                               "can go while the dock is shown before it hides again, in px.", 300, 0),
            "activationWidth": num("Width of the strip along the bottom edge that reveals the hidden dock, in px. Defaults to hoverWidth.", 1600, 0),
            "activationHeight": num("Height of the strip along the bottom edge that reveals the hidden dock, in px.", 20, 0),
            "surfaceHeight": num("Height of the dock's window, in px (capped at the screen height). Keep it as small as fits the dock "
                                 "and its notches: Qt redraws the whole window on every frame.", 700, 1),
            "showHoverRegion": boolean("Draw the hover region, for tuning activationWidth/activationHeight (dock hidden) and hoverWidth/hoverHeight (dock shown).", False),
            "showPreviews": boolean("Clicking a running app shows live previews of its windows.", True),
            "minimumToplevelWidth": num("Width of each window preview, in px.", 420, 1),
            "numMaxChildren": num("Most window previews shown side by side.", 2, 1, integer=True),
            "previewNotch": notch("Notch holding the window previews."),
            "menuNotch": notch("Right-click menu notch."),
        }),
        "lockscreen": obj("Lock screen.", {"notch": notch("Bottom notch with the greeting, now playing and the password field.")}),
        "wallpapers": obj("Wallpapers.", {
            "directory": {"type": "string", "default": "~/Pictures/Wallpapers",
                          "description": "Folder the wallpaper picker lists images (jpg, png, webp) and videos (mp4, mkv, webm, mov) from. A leading ~ is expanded. "
                                         "Video thumbnails and previews are kept in .thumbnails and .previews inside it."}}),
        "scale": obj("Size multipliers for smaller or larger screens, e.g. 0.9 on a 1080p screen at Hyprland scale 1. Results are rounded to whole pixels.", {
            "size": num("Multiplier for every shell size: notches, cards, padding and spacing, bar margins and exclusive zone, side bar, dock geometry (radius, icons, distances, hover and activation areas), power menu and lock screen. WayVes visualiser shader sizes are not affected.", 1, 0.5, 2),
            "font": num("Multiplier for text sizes.", 1, 0.5, 2),
        }),
        "performance": obj("Lighter settings for weaker machines. potato sets the defaults of the other keys; each can still be set on its own.", {
            "potato": boolean("Potato mode: caps visualisers at 10 fps (the side bar gauges at 2, the dock visualiser and power menu HUD surface at 1), plays video wallpapers from their 1280p30 preview copy, and turns off "
                              "live video previews in the wallpaper picker. Pair it with WayVes' config_potato.yaml.", False),
            "visualiserFps": num("Most often a WayVes surface is read and its window redrawn, per second. 0 for no cap (each surface's own "
                                 "rate, mostly 60). Defaults to 10 with potato.", 0, 0, integer=True),
            "usageFps": num("Rate of the side bar's usage and temperature gauges, per second, overriding visualiserFps for them. 0 to "
                            "follow visualiserFps. Defaults to 2 with potato.", 0, 0, integer=True),
            "dockFps": num("Rate of the dock's visualiser (the bars under the icons), per second, overriding visualiserFps for it. The "
                           "app indicators are not affected. 0 to follow visualiserFps. Defaults to 1 with potato.", 0, 0, integer=True),
            "hudSurfaceFps": num("Rate of the power menu's HUD surface, per second, overriding visualiserFps for it. The waves and outer "
                                 "ring are not affected. 0 to follow visualiserFps. Defaults to 1 with potato.", 0, 0, integer=True),
            "videoWallpaper": {"type": "string", "enum": ["original", "preview", "still"], "default": "original",
                               "description": "How a video wallpaper plays: original (the file itself), preview (its 1280p30 copy in .previews, "
                                              "the original until that exists) or still (its first-frame thumbnail, no playback). Defaults to "
                                              "preview with potato."},
            "pickerVideoPreviews": boolean("Play the focused video in the wallpaper picker; off shows its thumbnail. Defaults to off with potato.", True),
        }),
        "powerMenu": obj("Power menu.", {
            "countdowns": obj("Seconds each action waits, shown as a countdown, before it runs. 0 runs it at once.", {
                "shutdown": num("Shut Down.", 5, 0, integer=True),
                "reboot": num("Reboot.", 5, 0, integer=True),
                "logout": num("Log Out.", 5, 0, integer=True),
                "lock": num("Lock.", 0, 0, integer=True)})}),
        "notch": obj("Defaults shared by every notch. A notch's own key of the same name overrides these.", {
            "overshoot": num("Resize animation: above 0 uses OutBack easing with this overshoot (e.g. 1.2 to 2.0); 0 uses a bounce.", 1, 0),
            "squash": num("Squash-and-stretch on collapse: how many px taller the shape bulges as it settles. 0 disables it.", 12, 0),
            "panelOpacity": num("Default opacity of every notch's fill. 1 is opaque, and also the cheapest to composite with blur.", 0.65, 0, 1),
        }),
    },
}


def check():
    data = json.load(open(CONFIG_PATH))
    errors = []

    def resolve(s):
        while "$ref" in s:
            s = schema["definitions"][s["$ref"].split("/")[-1]]
        return s

    def walk(s, v, path):
        s = resolve(s)
        t = s.get("type")
        ok = {"object": isinstance(v, dict), "number": isinstance(v, (int, float)) and not isinstance(v, bool),
              "integer": isinstance(v, int) and not isinstance(v, bool), "string": isinstance(v, str),
              "boolean": isinstance(v, bool)}.get(t, True)
        if not ok:
            errors.append(f"{path}: expected {t}, got {v!r}")
            return
        if "enum" in s and v not in s["enum"]:
            errors.append(f"{path}: {v!r} is not one of {s['enum']}")
        if "minimum" in s and v < s["minimum"]:
            errors.append(f"{path}: {v} is below {s['minimum']}")
        if "maximum" in s and v > s["maximum"]:
            errors.append(f"{path}: {v} is above {s['maximum']}")
        if t == "object":
            for k, sub in v.items():
                if k in s.get("properties", {}):
                    walk(s["properties"][k], sub, f"{path}.{k}")
                elif s.get("additionalProperties") is False:
                    errors.append(f"{path}: unknown key {k!r}")

    walk(schema, data, "$")
    return errors


if __name__ == "__main__":
    if "--check" in sys.argv:
        problems = check()
        print("\n".join(problems) or "Properties.json is valid")
        sys.exit(1 if problems else 0)
    with open(SCHEMA_PATH, "w") as f:
        json.dump(schema, f, indent=2)
        f.write("\n")
    print("Wrote", SCHEMA_PATH)
