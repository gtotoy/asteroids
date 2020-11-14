const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.build.Builder) void {
    var name = "asteroids";
    var src_dir = "src/main.zig";
    var exe = b.addExecutable(name, src_dir);
    exe.setBuildMode(b.standardReleaseOptions());

    // OS stuff
    exe.linkLibC();
    switch(builtin.os.tag) {
        .windows => {
            exe.linkSystemLibrary("kernel32");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("shell32");
            exe.linkSystemLibrary("gdi32");

            exe.addIncludeDir("c:/dev/vcpkg/installed/x64-windows-static/include");
            exe.addLibPath("c:/dev/vcpkg/installed/x64-windows-static/lib");
        },
        else => {},
    }

    // GLFW
    exe.linkSystemLibrary("glfw3");

    // GLAD
    exe.addCSourceFile("deps/glad/src/glad.c", &[_][]const u8{"-std=c99"});
    exe.addIncludeDir("deps/glad/include");

    b.default_step.dependOn(&exe.step); // zig build
    b.step("run", "Run asteroids game").dependOn(&exe.run().step); // zig build run
}