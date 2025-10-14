const msg = @import("message.zig");
const sig = @import("signal.zig");
const std = @import("std");

const posix = std.posix;

pub fn init(msg_type: msg.Type) void {
    sig.init(quit, exit);
    const fd = std.posix.socket(
        std.posix.AF.UNIX,
        std.posix.SOCK.DGRAM,
        0,
    ) catch |e| {
        std.log.err("client socket failed: {}", .{e});
        return;
    };
    defer std.posix.close(fd);
    var addr = std.posix.sockaddr.un{
        .family = std.posix.AF.UNIX,
        .path = undefined,
    };
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const path = @import("path.zig").getPath(allocator) catch return;
    defer allocator.free(path);
    @memcpy(addr.path[0..path.len], path);
    const buf = [1]u8{@intFromEnum(msg_type)};
    _ = std.posix.sendto(
        fd,
        &buf,
        0,
        @ptrCast(&addr),
        @intCast(path.len + 2),
    ) catch |e| {
        std.log.err("sendto failed: {}", .{e});
    };
}

fn quit(_: i32) callconv(.c) void {
    posix.exit(0);
}

fn exit(signal: i32) callconv(.c) void {
    switch (signal) {
        posix.SIG.ILL => std.log.err("Illegal instruction", .{}),
        posix.SIG.ABRT => std.log.err("Error program aborted", .{}),
        posix.SIG.SEGV => std.log.err("Segmentation fault", .{}),
        else => {},
    }
    posix.exit(1);
}
