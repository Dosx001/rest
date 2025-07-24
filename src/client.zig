const msg = @import("message.zig");
const std = @import("std");

const posix = std.posix;

var buf: [6]u8 = undefined;

pub fn init() !void {
    var sa = posix.Sigaction{
        .handler = .{ .handler = quit },
        .mask = posix.empty_sigset,
        .flags = 0,
    };
    posix.sigaction(posix.SIG.HUP, &sa, null);
    posix.sigaction(posix.SIG.INT, &sa, null);
    posix.sigaction(posix.SIG.QUIT, &sa, null);
    posix.sigaction(posix.SIG.TERM, &sa, null);
    sa.handler = .{ .handler = exit };
    posix.sigaction(posix.SIG.ILL, &sa, null);
    posix.sigaction(posix.SIG.ABRT, &sa, null);
    posix.sigaction(posix.SIG.SEGV, &sa, null);
    const fd = std.posix.socket(std.posix.AF.UNIX, std.posix.SOCK.DGRAM, 0) catch |e| {
        std.log.err("socket failed: {}", .{e});
        return;
    };
    defer std.posix.close(fd);
    var addr: std.posix.sockaddr.un = undefined;
    addr.family = std.posix.AF.UNIX;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const path = @import("path.zig").getPath(allocator);
    defer allocator.free(path);
    @memcpy(addr.path[0..path.len], path);
    buf = .{ @intFromEnum(msg.Type.Reset), 'H', 'E', 'L', 'L', 'O' };
    _ = std.posix.sendto(fd, &buf, 0, @ptrCast(&addr), @intCast(path.len + 2)) catch |e| {
        std.log.err("sendto failed: {}", .{e});
    };
    buf[0] = @intFromEnum(msg.Type.Update);
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

