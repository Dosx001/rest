const std = @import("std");

pub fn getPath(allocator: std.mem.Allocator) ![]u8 {
    const user = std.process.getEnvVarOwned(
        allocator,
        "USER",
    ) catch |e| {
        std.log.err("USER env var for socket failed: {}", .{e});
        return e;
    };
    defer allocator.free(user);
    const path = std.fmt.allocPrint(
        allocator,
        "/home/{s}/.local/state/rest",
        .{user},
    ) catch |e| {
        std.log.err("path allocation for socket failed: {}", .{e});
        return e;
    };
    return path;
}
