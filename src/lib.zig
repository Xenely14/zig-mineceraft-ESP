const std = @import("std");
const misc = @import("misc.zig");

extern "detours.x64" fn DetourAttach(source_ptr: *const anyopaque, destenition_ptr: *const anyopaque) c_ulong;
extern "detours.x64" fn DetourUpdateThread(handle: ?*const anyopaque) c_ulong;
extern "detours.x64" fn DetourTransactionCommit() c_ulong;
extern "detours.x64" fn DetourTransactionBegin() c_ulong;

extern "opengl32" fn glBlendFunc(s_factor: c_uint, d_factor: c_uint) void;
extern "opengl32" fn glGetFloatv(pname: c_uint, params: [*]f32) void;
extern "opengl32" fn glColor4f(r: f32, b: f32, b: f32, a: f32) void;
extern "opengl32" fn glVertex3f(x: f32, y: f32, z: f32) void;
extern "opengl32" fn glLoadMatrixf(matrix_ptr: [*]f32) void;
extern "opengl32" fn glPushAttrib(mask: c_uint) void;
extern "opengl32" fn glMatrixMode(mode: c_uint) void;
extern "opengl32" fn glLineWidth(width: f32) void;
extern "opengl32" fn glDisable(cap: c_uint) void;
extern "opengl32" fn glEnable(cap: c_uint) void;
extern "opengl32" fn glBegin(mode: c_uint) void;
extern "opengl32" fn glLoadIdentity() void;
extern "opengl32" fn glPushMatrix() void;
extern "opengl32" fn glPopMatrix() void;
extern "opengl32" fn glPopAttrib() void;
extern "opengl32" fn glEnd() void;

extern "kernel32" fn GetModuleHandleA(module_name: [*]const u8) ?*const anyopaque;
extern "kernel32" fn GetProcAddress(module_handle: ?*const anyopaque, func_name: [*]const u8) *const anyopaque;

const GL_ALL_ATTRIB_BITS: c_uint = 0x000fffff;
const GL_ONE_MINUS_SRC_ALPHA: c_uint = 0x0303;
const GL_PROJECTION_MATRIX: c_uint = 0x0BA7;
const GL_MODELVIEW_MATRIX: c_uint = 0x0BA6;
const GL_LINE_SMOOTH: c_uint = 0x0B20;
const GL_DEPTH_TEST: c_uint = 0x0B71;
const GL_TEXTURE_2D: c_uint = 0x0DE1;
const GL_PROJECTION: c_uint = 0x1701;
const GL_MODELVIEW: c_uint = 0x1700;
const GL_CULL_FACE: c_uint = 0x0B44;
const GL_LIGHTING: c_uint = 0x0B50;
const GL_SRC_ALPTH: c_uint = 0x0302;
const GL_POLYGON: c_uint = 0x0009;
const GL_LINES: c_uint = 0x0001;
const GL_BLEND: c_uint = 0x0BE2;

const allocator = std.heap.page_allocator;

var chest = misc.Position.init(allocator);
var entity = misc.Position.init(allocator);
var large_chest = misc.Position.init(allocator);

// OpenGL function type defenitions
const glScalef_type = *const fn (f32, f32, f32) void;
const glTranslatef_type = *const fn (f32, f32, f32) void;
const glOrtho_type = *const fn (f64, f64, f64, f64, f64, f64) void;

var glScalefPtr: glScalef_type = undefined;
var glTranslatefPtr: glTranslatef_type = undefined;
var glOrthoPtr: glOrtho_type = undefined;

fn glScalefDetour(x: f32, y: f32, z: f32) void {
    glScalefPtr(x, y, z);

    // Entity
    if (x == 0.9375 and y == 0.9375 and z == 0.9375) {
        savePosition(&entity, 0.0, -1.0, 0.0);
    }
}

fn glTranslatefDetour(x: f32, y: f32, z: f32) void {
    glTranslatefPtr(x, y, z);

    // Chest
    if (x == 0.5 and y == 0.4375 and z == 0.9375) {
        savePosition(&chest, 0.0, 0.0625, -0.4375);
    }

    // Large chest
    if (x == 1 and y == 0.4375 and z == 0.9375) {
        savePosition(&large_chest, 0.0, 0.0625, -0.4375);
    }
}

fn glOrthoDetour(left: f64, right: f64, bottom: f64, top: f64, z_near: f64, z_far: f64) void {
    if (z_near == 1000 and z_far == 3000) {
        glPushAttrib(GL_ALL_ATTRIB_BITS);
        glPushMatrix();

        glDisable(GL_TEXTURE_2D);
        glDisable(GL_CULL_FACE);
        glDisable(GL_LIGHTING);
        glDisable(GL_DEPTH_TEST);

        glEnable(GL_LINE_SMOOTH);

        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPTH, GL_ONE_MINUS_SRC_ALPHA);

        draw(&chest, misc.Radius.init(1.0, 1.0, 1.0), misc.Color.init(127, 255, 0));
        draw(&large_chest, misc.Radius.init(2.0, 1.0, 1.0), misc.Color.init(127, 255, 0));
        draw(&entity, misc.Radius.init(0.8, 2.0, 0.8), misc.Color.init(138, 43, 226));

        glPopAttrib();
        glPopMatrix();
    }

    glOrthoPtr(left, right, bottom, top, z_near, z_far);
}

fn savePosition(position: *misc.Position, offset_x: f32, offset_y: f32, offset_z: f32) void {
    var projection: [16]f32 = undefined;
    glGetFloatv(GL_PROJECTION_MATRIX, &projection);

    var modelview: [16]f32 = undefined;
    glGetFloatv(GL_MODELVIEW_MATRIX, &modelview);

    var m3: [4]f32 = undefined;
    for (0..4) |index| {
        m3[index] = modelview[index] * offset_x + modelview[index + 4] * offset_y + modelview[index + 8] * offset_z + modelview[index + 12];
    }

    @memcpy(modelview[0..].ptr + 12, &m3);

    for (0..16) |index| {
        position.projection.append(projection[index]) catch unreachable;
        position.modelview.append(modelview[index]) catch unreachable;
    }
}

fn draw(position: *misc.Position, radius: misc.Radius, box_color: misc.Color) void {
    var counter: usize = 0;
    while (counter < position.modelview.items.len) : (counter += 16) {
        glMatrixMode(GL_PROJECTION);
        glLoadMatrixf(position.projection.items.ptr + counter);

        glMatrixMode(GL_MODELVIEW);
        glLoadMatrixf(position.modelview.items.ptr + counter);

        glLineWidth(2.0);
        glColor4f(box_color.r, box_color.g, box_color.b, 1.0);

        glBegin(GL_LINES);
        glVertex3f(radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, radius.y / 2, radius.z / 2);

        glVertex3f(-radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, radius.z / 2);

        glVertex3f(-radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);

        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, radius.y / 2, radius.z / 2);

        glVertex3f(radius.x / 2, radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, radius.y / 2, -radius.z / 2);

        glVertex3f(radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, -radius.z / 2);

        glVertex3f(radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);

        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);

        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);

        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, -radius.z / 2);

        glVertex3f(-radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, -radius.z / 2);

        glVertex3f(-radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, radius.z / 2);

        glVertex3f(radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, radius.z / 2);
        glEnd();

        glColor4f(box_color.r, box_color.g, box_color.b, 0.2);

        glBegin(GL_POLYGON);
        glVertex3f(radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);
        glEnd();

        glBegin(GL_POLYGON);
        glVertex3f(radius.x / 2, radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);
        glEnd();

        glBegin(GL_POLYGON);
        glVertex3f(radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, radius.y / 2, radius.z / 2);
        glEnd();

        glBegin(GL_POLYGON);
        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);
        glEnd();

        glBegin(GL_POLYGON);
        glVertex3f(radius.x / 2, -radius.y / 2, radius.z / 2);
        glVertex3f(radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, -radius.z / 2);
        glVertex3f(-radius.x / 2, -radius.y / 2, radius.z / 2);
        glEnd();

        glBegin(GL_POLYGON);
        glVertex3f(radius.x / 2, radius.y / 2, -radius.z / 2);
        glVertex3f(radius.x / 2, radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, radius.z / 2);
        glVertex3f(-radius.x / 2, radius.y / 2, -radius.z / 2);
        glEnd();
    }

    position.projection.shrinkAndFree(0);
    position.modelview.shrinkAndFree(0);
}

pub export fn DllMain(_: *const anyopaque, reason: u32, _: *const anyopaque) callconv(.C) c_int {
    switch (reason) {
        1 => {
            // Getting OpenGL functions
            var opengl_handle = GetModuleHandleA("opengl32.dll");

            glScalefPtr = @ptrCast(GetProcAddress(opengl_handle, "glScalef"));
            glTranslatefPtr = @ptrCast(GetProcAddress(opengl_handle, "glTranslatef"));
            glOrthoPtr = @ptrCast(GetProcAddress(opengl_handle, "glOrtho"));

            // Hooking
            _ = DetourTransactionBegin();
            _ = DetourUpdateThread(std.os.windows.kernel32.GetCurrentThread());
            _ = DetourAttach(@ptrCast(&glScalefPtr), &glScalefDetour);
            _ = DetourAttach(@ptrCast(&glTranslatefPtr), &glTranslatefDetour);
            _ = DetourAttach(@ptrCast(&glOrthoPtr), &glOrthoDetour);
            _ = DetourTransactionCommit();
        },
        else => {},
    }
    return 1;
}
