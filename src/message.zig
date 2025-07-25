const std = @import("std");

pub const Type = enum {
    Cron,
    Reset,
    Update,
};
