const std = @import("std");

pub const Type = enum {
    Bright,
    BrightDec,
    BrightInc,
    Cron,
    Error,
    Reset,
    Unknown,
    Update,
};

var index: usize = undefined;
var cmd: ?Type = undefined;

pub fn parse() Type {
    for (1..std.os.argv.len) |i| {
        const buf = std.mem.span(std.os.argv[i]);
        switch (buf[0]) {
            'b' => {
                if (compare("right", buf)) {
                    if (cmd) |_| return .Error;
                    cmd = .Bright;
                    continue;
                }
            },
            'c' => {
                if (compare("ron", buf)) {
                    if (cmd) |_| return .Error;
                    cmd = .Cron;
                    continue;
                }
            },
            'd' => {
                if (compare("ec", buf)) {
                    if (cmd != .Bright) return .Error;
                    cmd = .BrightDec;
                    continue;
                }
            },
            'i' => {
                if (compare("nc", buf)) {
                    if (cmd != .Bright) return .Error;
                    cmd = .BrightInc;
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
