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
