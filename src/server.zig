const log = @import("log.zig");
const msg = @import("message.zig");
const std = @import("std");

const c = @cImport({
    @cInclude("time.h");
});

const posix = std.posix;

const Settings = struct {
    temps: [24]u8,
};

var bright: u8 = 100;
var action: msg.Type = .Cron;

var fd: std.posix.socket_t = undefined;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn init() void {
    fd = posix.socket(posix.AF.UNIX, posix.SOCK.DGRAM, 0) catch |e| {
        std.log.err("Server socket failed: {}", .{e});
        return;
    };
    defer posix.close(fd);
    var addr: posix.sockaddr.un = undefined;
    addr.family = posix.AF.UNIX;
    const path = @import("path.zig").getPath(allocator) catch {
        std.log.err("Server not started", .{});
        return;
    };
    defer allocator.free(path);
    @memcpy(addr.path[0..path.len], path);
    posix.bind(fd, @ptrCast(&addr), @intCast(path.len + 2)) catch |e| {
        std.log.err("Bind failed: {}", .{e});
        return;
    };
    defer posix.unlink(path) catch |e|
        std.log.err("unlink failed: {}", .{e});
    loop();
}

fn loop() void {
    var buf: [1]u8 = undefined;
    var client: posix.sockaddr.un = undefined;
    var client_len: posix.socklen_t = @sizeOf(posix.sockaddr.un);
    var len: usize = undefined;
    var temps: [24]u8 = undefined;
    load(&temps) catch {
        std.log.err("Server not started", .{});
        return;
    };
    {
        const time = c.time(0);
        cmd(temps[@intCast(c.localtime(&time).*.tm_hour)]) catch {
            std.log.err("Server not started", .{});
            return;
        };
    }
    while (true) {
        len = posix.recvfrom(fd, &buf, 0, @ptrCast(&client), &client_len) catch |e| {
            std.log.err("recvfrom failed: {}", .{e});
            continue;
        };
        action = @enumFromInt(buf[0]);
        switch (action) {
            .BrightInc => {
                if (bright == 100) continue;
                bright += 5;
            },
            .BrightDec => {
                if (bright == 5) continue;
                bright -= 5;
            },
            .Cron => {},
            .Reset => bright = 58,
            .Update => load(&temps) catch continue,
        }
        const time = c.time(0);
        cmd(temps[@intCast(c.localtime(&time).*.tm_hour)]) catch continue;
    }
}

fn load(buf: *[24]u8) !void {
    const user = std.process.getEnvVarOwned(
        allocator,
        "USER",
    ) catch |e| {
        std.log.err("USER env var for settings failed: {}", .{e});
        return e;
    };
    defer allocator.free(user);
    const zon = std.fmt.allocPrint(
        allocator,
        "/home/{s}/.config/rest.zon",
        .{user},
    ) catch |e| {
        std.log.err("path allocation for settings failed: {}", .{e});
        return e;
    };
    defer allocator.free(zon);
    const file = std.fs.openFileAbsolute(zon, .{}) catch |e| {
        std.log.err("file open for settings failed: {}", .{e});
        return e;
    };
    defer file.close();
    const size = file.getEndPos() catch |e| {
        std.log.err("file size for settings failed: {}", .{e});
        return e;
    };
    const data = file.readToEndAlloc(allocator, size) catch |e| {
        std.log.err("file read for settings failed: {}", .{e});
        return e;
    };
    defer allocator.free(data);
    var status: std.zon.parse.Status = .{};
    const parsed = std.zon.parse.fromSlice(
        Settings,
        allocator,
        @ptrCast(data),
        &status,
        .{},
    ) catch |e| {
        std.log.err("zon parse for settings failed: {}", .{e});
        return e;
    };
    defer std.zon.parse.free(allocator, parsed);
    inline for (parsed.temps, 0..) |temp, i| {
        buf[i] = temp;
    }
}

fn cmd(temp: u8) !void {
    var num = [4]u8{ 0, 0, '0', '0' };
    _ = std.fmt.bufPrint(
        &num,
        "{d}",
        .{temp},
    ) catch |e| {
        std.log.err("temperature formatting failed: {}", .{e});
        return e;
    };
    var bgt: [4]u8 = .{ '1', 0, 0, 0 };
    if (bright != 100) _ = std.fmt.bufPrint(
        &bgt,
        "0.{d}",
        .{bright},
    ) catch |e| {
        std.log.err("brightness formatting failed: {}", .{e});
        return e;
    };
    const args = [_][]const u8{ "redshift", "-P", "-O", &num, "-b", &bgt };
    var child = std.process.Child.init(
        &args,
        allocator,
    );
    child.spawn() catch |e| {
        std.log.err("child spawn failed: {}", .{e});
        return e;
    };
    switch (action) {
        .BrightInc, .BrightDec => log.notify("Brightness: {s}", .{&bgt}),
        .Cron => log.notify("Temperature: {s}K", .{&num}),
        .Reset => log.notify("Daily reset", .{}),
        .Update => log.notify("Settings updated", .{}),
    }
}
