const std = @import("std");
const server = @import("server.zig");
const client = @import("client.zig");

pub fn main() !void {
    if (1 < std.os.argv.len) {
        switch (std.os.argv[1][0]) {
            'r' => {
                if (std.mem.eql(
                    u8,
                    std.mem.span(std.os.argv[1]),
                    "reset",
                )) {
                    client.init();
                    client.reset();
                    client.deinit();
                    return;
                }
                return error.InvalidArgument;
            },
            'u' => {
                if (std.mem.eql(
                    u8,
                    std.mem.span(std.os.argv[1]),
                    "update",
                )) {
                    client.init();
                    client.update();
                    client.deinit();
                    return;
                }
                return error.InvalidArgument;
            },
            else => {},
        }
        return;
    }
    server.init();
}
