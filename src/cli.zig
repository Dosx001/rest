const std = @import("std");

pub const Type = enum {
    Reset,
    Update,
    Unknown,
};

pub fn parse(buf: []u8) Type {
    switch (buf[0]) {
        'r' => {
            if (compare("eset", buf)) return .Reset;
            return .Unknown;
        },
        'u' => {
            if (compare("pdate", buf)) return .Update;
            return .Unknown;
        },
        else => return .Unknown,
    }
}

fn compare(str: []const u8, buf: []u8) bool {
    if (str.len + 1 != buf.len) return false;
    for (str, 1..) |c, i| {
        if (buf[i] != c) return false;
    }
    return true;
}
