const std = @import("std");

pub fn build(builder: *std.Build) void {
    defer std.debug.print("Build finished...", .{});

    const lib = builder.addSharedLibrary(.{
        .name = "esp",
        .link_libc = true,
        .root_source_file = .{ .path = "src/lib.zig" },
        .optimize = .ReleaseSmall,
        .target = .{
            .cpu_arch = .x86_64,
            .os_tag = .windows,
            .abi = .msvc,
        },
    });
    lib.addLibraryPath(.{
        .path = "libs",
    });

    builder.installArtifact(lib);
}
