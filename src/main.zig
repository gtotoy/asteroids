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

    const allocator = std.heap.page_allocator;
    const shader_program = blk: {
        const vertex_shader = vs: {
            const shader_path = try std.fs.path.join(allocator, &[_][]const u8{"shaders", "vert.glsl"});
            const shader_file = try std.fs.cwd().openFile(shader_path,
                                                        std.fs.File.OpenFlags{.read = true, .write = false});
            defer shader_file.close();
            const shader_src = try allocator.alloc(u8, try shader_file.getEndPos());
            defer allocator.free(shader_src);
            const len = try shader_file.read(shader_src);
            const shader_id = c.glCreateShader(c.GL_VERTEX_SHADER);
            c.glShaderSource(shader_id, 1, &shader_src.ptr, null);
            c.glCompileShader(shader_id);
            var compile_succes: c_int = undefined;
            c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &compile_succes);
            if (compile_succes == 0) {
                var info_log: [512]u8 = undefined;
                c.glGetShaderInfoLog(shader_id, 512, null, &info_log);
                std.debug.panic("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{}\n", .{info_log});
            }
            break :vs shader_id;
        };
        defer c.glDeleteShader(vertex_shader);

        const fragment_shader = fs: {
            const shader_path = try std.fs.path.join(allocator, &[_][]const u8{"shaders", "frag.glsl"});
            const shader_file = try std.fs.cwd().openFile(shader_path,
                                                        std.fs.File.OpenFlags{.read = true, .write = false});
            defer shader_file.close();
            const shader_src = try allocator.alloc(u8, try shader_file.getEndPos());
            defer allocator.free(shader_src);
            const len = try shader_file.read(shader_src);
            const shader_id = c.glCreateShader(c.GL_FRAGMENT_SHADER);
            c.glShaderSource(shader_id, 1, &shader_src.ptr, null);
            c.glCompileShader(shader_id);
            var compile_succes: c_int = undefined;
            c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &compile_succes);
            if (compile_succes == 0) {
                var info_log: [512]u8 = undefined;
                c.glGetShaderInfoLog(shader_id, 512, null, &info_log);
                std.debug.panic("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{}\n", .{info_log});
            }
            break :fs shader_id;
        };
        defer c.glDeleteShader(fragment_shader);

        const program_id = c.glCreateProgram();
        c.glAttachShader(program_id, vertex_shader);
        c.glAttachShader(program_id, fragment_shader);
        c.glLinkProgram(program_id);
        var link_succes: c_int = undefined;
        c.glGetProgramiv(program_id, c.GL_LINK_STATUS, &link_succes);
        if (link_succes == 0) {
            var info_log: [512]u8 = undefined;
            c.glGetShaderInfoLog(program_id, 512, null, &info_log);
            std.debug.panic("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{}\n", .{info_log});
        }
        break :blk program_id;
    };

    const vertices = [_]f32 {
         0.5,  0.5, 0.0, // top right
         0.5, -0.5, 0.0, // bottom right
        -0.5, -0.5, 0.0, // bottom left
        -0.5,  0.5, 0.0, // top left
    };

    const indices = [_]u32 {
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };

    var draw_list = blk: {
        var vao: c_uint = undefined;
        var vbo: c_uint = undefined;
        var ebo: c_uint = undefined;
        c.glGenVertexArrays(1, &vao);
        c.glGenBuffers(1, &vbo);
        c.glGenBuffers(1, &ebo);

        c.glBindVertexArray(vao);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
        c.glBufferData(c.GL_ARRAY_BUFFER, vertices.len * @sizeOf(f32), &vertices, c.GL_STATIC_DRAW);

        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, indices.len * @sizeOf(u32), &indices, c.GL_STATIC_DRAW);

        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), null);
        c.glEnableVertexAttribArray(0);

        c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
        c.glBindVertexArray(0);

        break :blk .{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo
        };
    };
    defer c.glDeleteVertexArrays(1, &draw_list.vao);
    defer c.glDeleteBuffers(1, &draw_list.vbo);
    defer c.glDeleteBuffers(1, &draw_list.ebo);

    while(c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glClearColor(0.2, 0.7, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        c.glUseProgram(shader_program);
        c.glBindVertexArray(draw_list.vao);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}

fn resizeViewport(window: ?*c.GLFWwindow, width: c_int, height: c_int ) callconv(.C) void {
    viewport_width = @intCast(@TypeOf(viewport_width), width);
    viewport_height = @intCast(@TypeOf(viewport_height), height);
    c.glViewport(0, 0, width, height);
}