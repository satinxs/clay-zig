### Zig Language Bindings

> [!IMPORTANT]
> Zig 0.14.0 or higher is required.

> [!NOTE]
> This project currently is in beta.

This directory contains bindings for the [Zig](odin-lang.org) programming language, as well as an example implementation of the [clay website](https://nicbarker.com/clay) in Zig.

Special thanks to [johan0A](githubusercontent.com/johan0A) for the reference implementation.

If you haven't taken a look at the [full documentation for clay](https://github.com/nicbarker/clay/blob/main/README.md), it's recommended that you take a look there first to familiarise yourself with the general concepts. This README is abbreviated and applies to using clay in Zig specifically.

The **most notable difference** between the C API and the Zig bindings is the use of if statements to open the scope for declaring child elements and then having to close it "manually" with a deferred function call.

Other changes include:
 - minor naming changes
 - ability to initialize a parameter by calling a function that is part of its type's namespace for example `.fixed()` or `.all()`
 - ability to initialize a parameter by using a public constant that is part of its type's namespace for example `.grow` 

TODO:
 - Talk about integrations with raylib
 - Talk about special `getOpenElementId()`, `element()`, and `hovered()` functions

```c
// C macro for creating a scope
CLAY(
    CLAY_ID("SideBar"),
    CLAY_LAYOUT({
        .layoutDirection = CLAY_TOP_TO_BOTTOM,
        .childAlignment = { .x = CLAY_ALIGN_X_CENTER, .y = CLAY_ALIGN_Y_TOP  },
        .sizing = { .width = CLAY_SIZING_FIXED(300), .height = CLAY_SIZING_GROW() },
        .padding = {16, 16},
        .childGap = 16,
    }),
    CLAY_RECTANGLE({ .color = COLOR_LIGHT })
) {
    // Child elements here
}
```

```zig
// Zig form of element macros
if (clay.open(.{
    .id = clay.Id("SideBar"),
    .layout = .{
        .direction = .top_to_bottom,
        .alignment = .center_top,
        .sizing = .{ .w = .fixed(300), .h = .grow },
        .padding = .all(16),
        .child_gap = 16,
    },
    .rectangle = .{ .color = COLOR_LIGHT },
})) {
    defer clay.close();
    // Child elements here
}
```

### Install

Download and add `clay-zig` as a dependency by running the following command in your project root:
```sh
zig fetch --save https://github.com/raugl/clay-zig/archive/<commit sha>.tar.gz
```
Then add `clay-zig` as a dependency and import its modules and artifact in your build.zig:
```zig
const clay_dep = b.dependency("clay-zig", .{
    .target = target,
    .optimize = optimize,
});
exe.linkLibrary(clay_dep.artifact("clay"));
exe.root_module.addImport("clay", clay_dep.module("clay"));
```
To enable a builtin renderer you should first add its third party library to your project separately (eg: raylib, sdl2), then tell clay-zig about it. In this example we are using [raylib-zig](https://github.com/Not-Nik/raylib-zig):
```zig
const cl = @import("clay-zig");

const raylib_dep = b.dependency("raylib-zig", .{ ... });
cl.enableRenderer(exe.root_module, clay_dep, .{ .raylib = raylib_dep.module("raylib") });
```

### Quick Start

1. Ask clay for how much static memory it needs using [clay.minMemorySize()](https://github.com/nicbarker/clay/blob/main/README.md#clay_minmemorysize), create an Arena for it to use with [clay.createArenaWithCapacityAndMemory(min_memory_size, memory)](https://github.com/nicbarker/clay/blob/main/README.md#clay_createarenawithcapacityandmemory), and initialize it with [clay.initialize(arena, layout_size, error_handler)](https://github.com/nicbarker/clay/blob/main/README.md#clay_initialize).

```zig
const memory = try allocator.alloc(u8, clay.minMemorySize());
defer allocator.free(memory);
const arena = clay.createArenaWithCapacityAndMemory(@intCast(memory.len), @ptrCast(memory));
clay.initialize(arena, .{}, .{});
```

2. Provide a `measureText(text, config)` function with [clay.setMeasureTextFunction(function)](https://github.com/nicbarker/clay/blob/main/README.md#clay_setmeasuretextfunction) so that clay can measure and wrap text.

```zig
// Example measure text function
pub fn measureText(text: []const u8, config: *clay.TextConfig) clay.Dimensions {
    // clay.TextConfig contains members such as font_id, font_size, letter_spacing etc
}

// Tell clay how to measure text
clay.setMeasureTextFunction(measureText)
```

3. **Optional** - Call [clay.setPointerPosition(pointerPosition)](https://github.com/nicbarker/clay/blob/main/README.md#clay_setpointerposition) if you want to use mouse interactions.

```zig
clay.setPointerState(.{ .x = mouse_position_x, .y = mouse_position_y }, is_left_mouse_button_down);
```

4. Call [clay.beginLayout()](https://github.com/nicbarker/clay/blob/main/README.md#clay_beginlayout) and declare your layout using the provided functions.

```zig
const COLOR_LIGHT = clay.Color.init(224, 215, 210, 255);
const COLOR_RED = clay.Color.init(168, 66, 28, 255);
const COLOR_ORANGE = clay.Color.init(225, 138, 50, 255);

// Layout config is just a struct that can be declared statically, or inline
const sidebar_item_layout = clay.LayoutConfig{
    .sizing = .{ .w = .grow, .h = .fixed(50) },
};

// Re-useable components are just normal functions
fn sidebarItemComponent(index: usize) void {
    clay.element(.{
        .id = clay.IdWithIndex("SidebarBlob", index),
        .layout = sidebar_item_layout,
        .rectangle = .{ .color = COLOR_ORANGE },
    });
}

// An example function to begin the "root" of your layout tree
fn createLayout() clay.RenderCommandArray {
    clay.beginLayout();

    // An example of laying out a UI with a fixed width sidebar and flexible width main content
    if (clay.open(.{
        .id = clay.Id("OuterContainer"),
        .layout = .{ .sizing = .grow, .padding = .all(16), .child_gap = 16 },
        .rectangle = .{ .color = .init(250, 250, 250, 255) },
    })) {
        defer clay.close();
        if (clay.open(.{
            .id = clay.Id("SideBar"),
            .layout = .{ .direction = .top_to_bottom, .sizing = .{ .w = .fixed(300), .h = .grow }, .padding = .all(16), .child_gap = 16 },
            .rectangle = .{ .color = COLOR_LIGHT },
        })) {
            defer clay.close();
            if (clay.open(.{
                .id = clay.Id("ProfilePictureOuter"),
                .layout = .{ .sizing = .{ .w = .grow }, .padding = .all(16), .child_gap = 16, .alignment = .left_center },
                .rectangle = .{ .color = COLOR_RED },
            })) {
                defer clay.close();
                clay.element(.{
                    .id = clay.Id("ProfilePicture"),
                    .layout = .{ .sizing = .fixed(60) },
                    .image = .{ .image_data = &profile_picture, size = .all(60) },
                });
                clay.text("Clay - UI Library", .{ .font_size = 24, .text_color = .init(255, 255, 255, 255) });
            }

            // Standard Zig code like loops etc. work inside components
            for (0..10) |i| sidebarItemComponent(i)
        }

        if (clay.open(.{
            .id = clay.Id("MainContent"),
            .layout = .{ .sizing = .grow },
            .rectangle = .{ .color = COLOR_LIGHT },
        })) {
            defer clay.close();
            // ...
        }
    }
    return clay.endLayout();
}
```

5. Call [clay.endLayout()](https://github.com/nicbarker/clay/blob/main/README.md#clay_endlayout) and process the resulting [clay.RenderCommandArray](https://github.com/nicbarker/clay/blob/main/README.md#clay_rendercommandarray) in your choice of renderer.

```zig
const render_commands = clay.endLayout();

for (render_commands.slice()) |render_command| {
    switch (render_command.type) {
        .rectangle => {
            drawRectangle(render_command.bounding_box, render_command.config.rectangle.color);
        },
        // ... Implement handling of other command types
    }
}
```

Please see the [full C documentation for clay](https://github.com/nicbarker/clay/blob/main/README.md) for API details. All public C functions and Macros have Zig binding equivalents, generally of the form `Clay_BeginLayoup` (C) -> `clay.beginLayout` (Zig)
