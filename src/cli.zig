const std = @import("std");
const msg = @import("message.zig");

var index: usize = undefined;
var cmd: ?msg.Type = undefined;

pub fn parse(argv: [][*:0]u8) msg.Type {
    for (1..argv.len) |i| {
        const buf = std.mem.span(argv[i]);
        switch (buf[0]) {
            'c' => {
                if (compare("ron", buf)) {
                    if (cmd) |_| return .Error;
                    cmd = .Cron;
                    continue;
                }
            },
            'r' => {
                if (compare("eset", buf)) {
                    if (cmd) |_| return .Error;
                    cmd = .Reset;
                    continue;
                }
            },
            'u' => {
                if (compare("pdate", buf)) {
                    if (cmd) |_| return .Error;
                    cmd = .Update;
                    continue;
                }
            },
            else => {},
        }
        index = i;
        return .Unknown;
    }
    return cmd.?;
}

fn compare(str: []const u8, buf: []u8) bool {
    if (str.len + 1 != buf.len) return false;
    for (str, 1..) |c, i| {
        if (c != buf[i]) return false;
    }
    return true;
}

pub fn unknown() usize {
    return index;
}
