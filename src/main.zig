const cli = @import("cli.zig");
const client = @import("client.zig");
const server = @import("server.zig");
const std = @import("std");
const log = @import("log.zig");

pub const std_options: std.Options = .{
    .logFn = log.logger,
};

pub fn main() !void {
    log.init();
    defer log.deinit();
    if (1 == std.os.argv.len) {
        server.init();
        return;
    }
    switch (cli.parse()) {
        .Bright => return std.log.debug("Bright command needs subcommand inc or dec", .{}),
        .BrightInc => return client.init(.BrightInc),
        .BrightDec => return client.init(.BrightDec),
        .Cron => return client.init(.Cron),
        .Error => {
            std.log.err("Error in usage", .{});
            return;
        },
        .Reset => return client.init(.Reset),
        .Update => return client.init(.Update),
        .Unknown => {
            std.log.err("Unknown command: {s}", .{std.os.argv[cli.unknown()]});
            return;
        },
    }
}
