const client = @import("client.zig");
const std = @import("std");

const c = @cImport({
    @cInclude("systemd/sd-device.h");
});

var event: ?*c.sd_event = undefined;
var path: []u8 = undefined;

pub fn sigprocmask() void {
    var set: c.sigset_t = undefined;
    _ = c.sigemptyset(&set);
    _ = c.sigaddset(&set, std.posix.SIG.HUP);
    _ = c.sigaddset(&set, std.posix.SIG.INT);
    _ = c.sigaddset(&set, std.posix.SIG.QUIT);
    _ = c.sigaddset(&set, std.posix.SIG.ILL);
    _ = c.sigaddset(&set, std.posix.SIG.ABRT);
    _ = c.sigaddset(&set, std.posix.SIG.SEGV);
    _ = c.sigaddset(&set, std.posix.SIG.TERM);
    _ = c.sigprocmask(c.SIG_BLOCK, &set, null);
}

pub fn init() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    path = @import("path.zig").getPath(allocator) catch {
        std.log.err("path failed", .{});
        unlink(1);
        return;
    };
    defer allocator.free(path);
    var monitor: ?*c.sd_device_monitor = undefined;
    defer _ = c.sd_device_monitor_unref(monitor);
    if (c.sd_device_monitor_new(&monitor) < 0) {
        std.log.err("SD device monitor failed", .{});
        unlink(1);
    }
    if (c.sd_device_monitor_filter_add_match_subsystem_devtype(monitor, "drm", null) < 0) {
        std.log.err("SD device monitor filter failed", .{});
        unlink(1);
    }
    defer _ = c.sd_event_unref(event);
    if (c.sd_event_default(&event) < 0) {
        std.log.err("SD event failed", .{});
        unlink(1);
    }
    var source: ?*c.sd_event_source = null;
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.HUP, quit, null);
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.INT, quit, null);
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.QUIT, quit, null);
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.TERM, quit, null);
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.ILL, exit, null);
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.ABRT, exit, null);
    _ = c.sd_event_add_signal(event, &source, std.posix.SIG.SEGV, exit, null);
    if (c.sd_device_monitor_attach_event(monitor, event) < 0) {
        std.log.err("SD device monitor attach event failed", .{});
        unlink(1);
    }
    if (c.sd_device_monitor_start(monitor, event_handler, null) < 0) {
        std.log.err("SD device monitor start failed", .{});
        unlink(1);
    }
    if (c.sd_event_loop(event) < 0) {
        std.log.err("SD event loop failed", .{});
        unlink(1);
    }
}

fn event_handler(
    _: ?*c.sd_device_monitor,
    _: ?*c.sd_device,
    _: ?*anyopaque,
) callconv(.C) c_int {
    std.time.sleep(2 * std.time.ns_per_s);
    client.init(.Cron);
    return 0;
}

fn unlink(code: u8) void {
    std.posix.unlink(path) catch |e| std.log.err(
        "unlink failed: {}",
        .{e},
    );
    std.posix.exit(code);
}

fn quit(
    _: ?*c.sd_event_source,
    _: [*c]const c.struct_signalfd_siginfo,
    _: ?*anyopaque,
) callconv(.C) c_int {
    unlink(0);
    return 0;
}

fn exit(
    _: ?*c.sd_event_source,
    info: [*c]const c.struct_signalfd_siginfo,
    _: ?*anyopaque,
) callconv(.C) c_int {
    switch (info.*.ssi_signo) {
        std.posix.SIG.ILL => std.log.err("Illegal instruction", .{}),
        std.posix.SIG.ABRT => std.log.err("Error program aborted", .{}),
        std.posix.SIG.SEGV => std.log.err("Segmentation fault", .{}),
        else => {},
    }
    unlink(1);
    return 0;
}
