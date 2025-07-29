const msg = @import("message.zig");
const sig = @import("signal.zig");
const std = @import("std");

const posix = std.posix;

var buf: [1]u8 = undefined;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn init(msg_type: msg.Type) void {
    sig.init(quit, exit);
    const fd = std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.DGRAM, 0) catch |e| {
        std.log.err("socket failed: {}", .{e});
        return;
    };
    defer std.posix.close(fd);
    var addr = std.posix.sockaddr.un{
        .family = std.posix.AF.UNIX,
        .path = undefined,
    };
    const path = @import("path.zig").getPath(allocator);
    defer allocator.free(path);
    @memcpy(addr.path[0..path.len], path);
    buf = .{@intFromEnum(msg_type)};
    _ = std.posix.sendto(fd, &buf, 0, @ptrCast(&addr), @intCast(path.len + 2)) catch |e| {
        std.log.err("sendto failed: {}", .{e});
    };
}

fn quit(_: i32) callconv(.C) void {
    posix.exit(0);
}

fn exit(signal: i32) callconv(.C) void {
    switch (signal) {
        posix.SIG.ILL => std.log.err("Illegal instruction", .{}),
        posix.SIG.ABRT => std.log.err("Error program aborted", .{}),
        posix.SIG.SEGV => std.log.err("Segmentation fault", .{}),
        else => {},
    }
    posix.exit(1);
}
