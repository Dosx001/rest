const msg = @import("message.zig");
const path = @import("path.zig");
const std = @import("std");

const c = @cImport({
    @cInclude("time.h");
});

const posix = std.posix;

const Settings = struct {
    colors: [24]u8,
};

var bright: u8 = 58;

var PATH: []u8 = undefined;
var fd: std.posix.socket_t = undefined;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn init() void {
    fd = posix.socket(posix.AF.UNIX, posix.SOCK.DGRAM, 0) catch |e| {
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
    loop();
}

fn loop() void {
    var buf: [1]u8 = undefined;
    var client: posix.sockaddr.un = undefined;
    var client_len: posix.socklen_t = @sizeOf(posix.sockaddr.un);
    var len: usize = undefined;
    var colors: [24]u8 = undefined;
    load(&colors);
    {
        const time = c.time(0);
        cmd(colors[@intCast(c.localtime(&time).*.tm_hour)]);
    }
    while (true) {
        len = posix.recvfrom(fd, &buf, 0, @ptrCast(&client), &client_len) catch |e| {
            std.log.err("recvfrom failed: {}", .{e});
            continue;
        };
        switch (@as(msg.Type, @enumFromInt(buf[0]))) {
            .BrightInc => {
                if (bright == 58) continue;
                bright += 1;
            },
            .BrightDec => {
                if (bright == 49) continue;
                bright -= 1;
            },
            .Cron => {},
            .Reset => bright = 58,
            .Update => load(&colors),
        }
        const time = c.time(0);
        cmd(colors[@intCast(c.localtime(&time).*.tm_hour)]);
    }
}

fn load(buf: *[24]u8) void {
    const user = std.process.getEnvVarOwned(
        allocator,
        "USER",
    ) catch unreachable;
    defer allocator.free(user);
    const json = std.fmt.allocPrint(
        allocator,
        "/home/{s}/.config/rest/settings.json",
        .{user},
    ) catch unreachable;
    defer allocator.free(json);
    const file = std.fs.openFileAbsolute(json, .{}) catch unreachable;
    defer file.close();
    const size = file.getEndPos() catch unreachable;
    const data = file.readToEndAlloc(allocator, size) catch unreachable;
    defer allocator.free(data);
    const parsed = std.json.parseFromSlice(Settings, allocator, data, .{}) catch unreachable;
    defer parsed.deinit();
    inline for (parsed.value.colors, 0..) |color, i| {
        buf[i] = color;
    }
}

fn cmd(color: u8) void {
    var num = [4]u8{ 0, 0, '0', '0' };
    _ = std.fmt.bufPrint(
        &num,
        "{d}",
        .{color},
    ) catch unreachable;
    var bgt = [2]u8{ '.', 0 };
    if (bright == 58) {
        bgt[0] = '1';
    } else bgt[1] = bright;
    const args = [_][]const u8{ "redshift", "-P", "-O", &num, "-b", &bgt };
    var child = std.process.Child.init(
        &args,
        allocator,
    );
    child.spawn() catch unreachable;
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
