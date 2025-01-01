const std = @import("std");
const cl = @import("clay-zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main app
    const exe = b.addExecutable(.{
        .name = "raylib-video-demo",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    { // Dependencies
        const raylib_dep = b.dependency("raylib-zig", .{
            .target = target,
            .optimize = optimize,
            .shared = true,
        });
        exe.root_module.addImport("raylib", raylib_dep.module("raylib"));
        exe.linkLibrary(raylib_dep.artifact("raylib"));

        const clay_dep = b.dependency("clay-zig", .{
            .target = target,
            .optimize = optimize,
        });
        exe.root_module.addImport("clay", clay_dep.module("clay"));
        exe.linkLibrary(clay_dep.artifact("clay"));
        cl.enableRaylibRenderer(exe, clay_dep, raylib_dep);
    }
    { // Run command
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);
    }
    { // Test command
        const unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_unit_tests.step);
    }
}
