const cli = @import("cli.zig");
const client = @import("client.zig");
const msg = @import("message.zig");
const server = @import("server.zig");
const std = @import("std");

pub fn main() !void {
    if (1 == std.os.argv.len) {
        server.init();
        return;
    }
    switch (cli.parse(std.os.argv)) {
        .Cron => {
            client.init();
            client.cron();
            client.deinit();
            return;
        },
        .Error => {
            std.log.err("Error in usage", .{});
            return;
        },
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
            std.log.err("Unknown command: {s}", .{std.os.argv[cli.unknown()]});
            return;
        },
    }
}
