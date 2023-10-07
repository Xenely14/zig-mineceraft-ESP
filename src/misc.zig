const std = @import("std");

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,

    pub fn init(r: u8, g: u8, b: u8) @This() {
        return @This(){
            .r = @as(f32, @floatFromInt(r)) / 255,
            .g = @as(f32, @floatFromInt(g)) / 255,
            .b = @as(f32, @floatFromInt(b)) / 255,
        };
    }
};

pub const Radius = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z: f32) @This() {
        return @This(){
            .x = x,
            .y = y,
            .z = z,
        };
    }
};

pub const Position = struct {
    projection: std.ArrayList(f32),
    modelview: std.ArrayList(f32),

    pub fn init(allocator: std.mem.Allocator) @This() {
        return @This(){
            .projection = std.ArrayList(f32).init(allocator),
            .modelview = std.ArrayList(f32).init(allocator),
        };
    }

    pub fn deinit(this: *@This()) void {
        this.projection.deinit();
        this.projection.deinit();
    }
};
