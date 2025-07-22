const path = @import("path.zig");
const std = @import("std");

const posix = std.posix;

var PATH: []u8 = undefined;

pub fn init() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const fd = posix.socket(posix.AF.UNIX, posix.SOCK.DGRAM, 0) catch |e| {
        std.log.err("socket failed: {}", .{e});
        return;
    };
    defer posix.close(fd);
    var addr: posix.sockaddr.un = undefined;
    addr.family = posix.AF.UNIX;
    PATH = path.getPath(allocator);
    defer allocator.free(PATH);
    @memcpy(addr.path[0..PATH.len], PATH);
    posix.bind(fd, @ptrCast(&addr), @intCast(PATH.len + 2)) catch |e| {
        std.log.err("bind failed: {}", .{e});
        return;
    };
    defer posix.unlink(PATH) catch |e| std.log.err(
        "unlink failed: {}",
        .{e},
    );
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
    var buf: [8]u8 = undefined;
    var client: posix.sockaddr.un = undefined;
    var client_len: posix.socklen_t = @sizeOf(posix.sockaddr.un);
    var len: usize = undefined;
    while (true) {
        len = posix.recvfrom(fd, &buf, 0, @ptrCast(&client), &client_len) catch |e| {
            std.log.err("recvfrom failed: {}", .{e});
            continue;
        };
        std.debug.print("read: {s}\n", .{buf[0..len]});
    }
}

fn quit(_: i32) callconv(.C) void {
    posix.unlink(PATH) catch |e| std.log.err(
        "unlink failed: {}",
        .{e},
    );
    posix.exit(0);
}

fn exit(signal: i32) callconv(.C) void {
    posix.unlink(PATH) catch |e| std.log.err(
        "unlink failed: {}",
        .{e},
    );
    switch (signal) {
        posix.SIG.ILL => std.log.err("Illegal instruction", .{}),
        posix.SIG.ABRT => std.log.err("Error program aborted", .{}),
        posix.SIG.SEGV => std.log.err("Segmentation fault", .{}),
        else => {},
    }
    posix.exit(1);
}
