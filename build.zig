const std = @import("std");

pub fn enableRaylibRenderer(
    compile_step: *std.Build.Step.Compile,
    clay_dep: *std.Build.Dependency,
    raylib_dep: *std.Build.Dependency,
) void {
    const clay_mod = clay_dep.module("clay");
    const raylib_mod = raylib_dep.module("raylib");
    const renderer_mod = clay_dep.module("renderer_raylib");

    clay_mod.addImport("raylib", raylib_mod);
    renderer_mod.addImport("raylib", raylib_mod);
    compile_step.root_module.addImport("clay_renderer", renderer_mod);
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
