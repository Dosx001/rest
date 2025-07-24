pub const Type = enum {
    Reset,
    Update,
    Unknown,
};

pub fn parse(buf: []u8) Type {
    switch (buf[0]) {
        'r' => if (compare("eset", buf)) return .Reset,
        'u' => if (compare("pdate", buf)) return .Update,
        else => return .Unknown,
    }
    return .Unknown;
}

fn compare(str: []const u8, buf: []u8) bool {
    if (str.len + 1 != buf.len) return false;
    for (str, 1..) |c, i| {
        if (c != buf[i]) return false;
    }
    return true;
}
