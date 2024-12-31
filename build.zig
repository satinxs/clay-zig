const std = @import("std");

pub const Renderer = union(enum) {
    html,
    sdl2,
    raylib: *std.Build.Module,
};

pub fn enableRenderer(
    root_module: *std.Build.Module,
    clay_dep: *std.Build.Dependency,
    renderer: Renderer,
) void {
    switch (renderer) {
        .raylib => |raylib_mod| {
            clay_dep.module("clay").addImport("raylib", raylib_mod);
            clay_dep.module("renderer_raylib").addImport("raylib", raylib_mod);
            root_module.addImport("clay_renderer_raylib", clay_dep.module("renderer_raylib"));
        },
        else => unreachable, // TODO: Unimplemented
    }
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const clay_lib = b.addStaticLibrary(.{
        .name = "clay",
        .target = target,
        .optimize = optimize,
    });

    const clay_src = b.dependency("clay_src", .{});
    clay_lib.addIncludePath(clay_src.path(""));
    clay_lib.addCSourceFile(.{
        .file = b.path("src/clay.c"),
    });
    b.installArtifact(clay_lib);

    const clay_mod = b.addModule("clay", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const renderer_raylib_mod = b.addModule("renderer_raylib", .{
        .root_source_file = b.path("src/renderer_raylib.zig"),
        .target = target,
        .optimize = optimize,
    });
    renderer_raylib_mod.addImport("clay", clay_mod);

    // TODO:
    // const enable_raylib = b.option(*std.Build.Module, "raylib", "Target the raylib renderer");
    // if (enable_raylib) |raylib_mod| {
    //     clay_mod.addImport("raylib", raylib_mod);
    //     renderer_raylib_mod.addImport("raylib", raylib_mod);
    // }

    const check_clay = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const test_step = b.step("test", "Check for library compilation errors");
    test_step.dependOn(&check_clay.step);
}
