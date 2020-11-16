const std = @import("std");

pub const Error = error{OutOfMemory};

const IAllocator = struct {
    allocator_ptr: usize,
    allocImpl: fn (allocator_ptr: usize, n: usize) Error!void,

    pub fn alloc(iAllocator: IAllocator, n: usize) Error!void {
        try iAllocator.allocImpl(iAllocator.allocator_ptr, n);
    }

    pub fn init(allocator_ptr: anytype) IAllocator {
        const T = @TypeOf(allocator_ptr.*);
        return IAllocator{
            .allocator_ptr = @ptrToInt(allocator_ptr),
            .allocImpl = IAllocatorImpl(T).alloc,
        };
    }

    fn IAllocatorImpl(comptime T: type) type {
        return struct {
            pub fn alloc(allocator_ptr: usize, n: usize) Error!void {
                var typed = @intToPtr(*T, allocator_ptr);
                try typed.alloc(n);
            }
        };
    }
};

const MyCustomAllocator = struct {
    n: usize = 0,

    const Self = @This();

    pub fn alloc(self: *Self, n: usize) Error!void {
        self.n = n;
    }
};

test "IAllocator" {
    std.debug.print("\n", .{});
    var my_allocator = MyCustomAllocator{};
    var allocator = IAllocator.init(&my_allocator);
    std.debug.print("my_allocator.n = {}\n", .{my_allocator.n});
    try allocator.alloc(7);
    std.debug.print("my_allocator.n = {}\n", .{my_allocator.n});
}