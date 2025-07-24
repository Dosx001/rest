const std = @import("std");
const server = @import("server.zig");
const client = @import("client.zig");
const cli = @import("cli.zig");

pub fn main() !void {
    if (1 < std.os.argv.len) {
        switch (cli.parse(std.mem.span(std.os.argv[1]))) {
            .Reset => {
                client.init();
                client.reset();
                client.deinit();
                return;
            },
            .Update => {
                client.init();
                client.update();
                client.deinit();
                return;
            },
            .Unknown => {
                std.debug.print("Unknown command: {s}\n", .{std.os.argv[1]});
                return;
            },
        }
    }
    server.init();
}
