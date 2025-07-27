const std = @import("std");

pub const Type = enum {
    Cron,
    Error,
    Reset,
    Unknown,
    Update,
};
