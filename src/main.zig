const std = @import("std");
const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

var viewport_width: u16 = 1280;
var viewport_height: u16 = 720;

pub fn main() !void {
    const glfw_ok = c.glfwInit();
    if (glfw_ok == c.GLFW_FALSE) {
        return error.GlfwInitFailed;
    }
    defer c.glfwTerminate();

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    var window = c.glfwCreateWindow(@intCast(c_int, viewport_width),
                                    @intCast(c_int, viewport_height),
                                    "Asteroids", null, null)
                 orelse return error.GlfwCreateWindowFailed;
    defer c.glfwDestroyWindow(window);

    c.glfwMakeContextCurrent(window);
    const frame_buffer_size_callback = c.glfwSetFramebufferSizeCallback(window, resizeViewport);

    var gl_loaded = c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, c.glfwGetProcAddress));
    if (gl_loaded == 0) {
        return error.GladLoadGLLoaderFailed;
    }

    while(c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glClearColor(0.2, 0.7, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

fn resizeViewport(window: ?*c.GLFWwindow, width: c_int, height: c_int ) callconv(.C) void {
    viewport_width = @intCast(@TypeOf(viewport_width), width);
    viewport_height = @intCast(@TypeOf(viewport_height), height);
    c.glViewport(0, 0, width, height);
}