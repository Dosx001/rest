const std = @import("std");

pub fn getPath(allocator: std.mem.Allocator) []u8 {
    const user = std.process.getEnvVarOwned(
        allocator,
        "USER",
    ) catch unreachable;
    defer allocator.free(user);
    const path = std.fmt.allocPrint(
        allocator,
        "/home/{s}/.local/state/rest",
        .{user},
    ) catch unreachable;
    return path;
}
