const std = @import("std");

const c = @cImport({
    @cInclude("libnotify/notify.h");
    @cInclude("syslog.h");
});

pub fn init() void {
    _ = c.notify_init("rest");
}

pub fn deinit() void {
    c.notify_uninit();
}

pub fn logger(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const scope_name = if (scope == .default) "" else "(" ++ @tagName(scope) ++ "): ";
    if (@import("builtin").mode == .Debug) {
        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();
        const stderr = std.io.getStdErr().writer();
        nosuspend stderr.print(
            @tagName(level) ++ "|" ++ scope_name ++ format ++ "\n",
            args,
        ) catch return;
    }
    var buf: [64]u8 = undefined;
    const msg = std.fmt.bufPrintZ(
        &buf,
        scope_name ++ format,
        args,
    ) catch return;
    if (@intFromEnum(level) < @intFromEnum(std.log.Level.info)) {
        const note = c.notify_notification_new("rest", msg.ptr, null);
        _ = c.notify_notification_show(note, null);
        _ = c.g_object_unref(note);
    }
    c.syslog(switch (level) {
        .err => c.LOG_ERR,
        .warn => c.LOG_WARNING,
        .info => c.LOG_INFO,
        .debug => c.LOG_DEBUG,
    }, "%s", msg.ptr);
}

pub fn notify(comptime fmt: []const u8, args: anytype) void {
    var buf: [64]u8 = undefined;
    const msg = std.fmt.bufPrintZ(
        &buf,
        fmt,
        args,
    ) catch return;
    const note = c.notify_notification_new("rest", msg.ptr, null);
    _ = c.notify_notification_show(note, null);
    _ = c.g_object_unref(note);
}
