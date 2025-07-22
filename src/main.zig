const std = @import("std");
const server = @import("server.zig");
const client = @import("client.zig");

pub fn main() !void {
    if (1 < std.os.argv.len) {
        switch (std.os.argv[1][0]) {
            'c' => {
                if (std.mem.eql(
                    u8,
                    std.mem.span(std.os.argv[1]),
                    "client",
                )) return client.init();
                return error.InvalidArgument;
            },
            else => {},
        }
        return;
    }
    server.init();
}
