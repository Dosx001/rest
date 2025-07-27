const std = @import("std");

pub const Type = enum {
    BrightDec,
    BrightInc,
    Cron,
    Reset,
    Update,
};
