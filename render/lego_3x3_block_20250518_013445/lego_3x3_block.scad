// --- Parameters for LEGO Brick ---

// Basic Dimensions (in mm)
stud_diameter = 4.8;
stud_height = 1.8;      // Height of the stud cylinder itself
unit_size = 8.0;        // Center-to-center stud spacing, also width/depth of one unit
wall_thickness = 1.6;

// Brick Height Standards
// A "plate" is 1/3 the height of a "brick"
plate_base_height = 3.2;
brick_base_height = 3 * plate_base_height; // 9.6 mm (height of the brick body, excluding studs)

// Underside Tube Dimensions
tube_outer_diameter = 6.5; // Outer diameter for clutch (common value, some sources use 6.51mm)
tube_inner_diameter = stud_diameter; // Inner diameter for stud clutch

// Number of studs for this brick (user requested 3x3)
num_studs_x = 3;
num_studs_y = 3;

// Quality of curves
$fn = 48; // Number of facets for cylinders/spheres, affects smoothness

// --- Calculated Dimensions ---
brick_actual_width = num_studs_x * unit_size;
brick_actual_depth = num_studs_y * unit_size;

// Height of the main cuboid part of the brick (the boxy part under the studs)
main_cuboid_height = brick_base_height;

// Height of the underside tubes (they reach from z=0 up to the underside of the top surface of the brick)
underside_tube_height = main_cuboid_height - wall_thickness;


// --- Modules ---

// Module for a single LEGO stud
module stud() {
    cylinder(h = stud_height, d = stud_diameter);
}

// Module for the main brick shell (hollow box with a top surface, open bottom)
module brick_shell(width, depth, height, wall_t) {
    difference() {
        // Solid outer block
        cube([width, depth, height]);
        
        // Subtract inner volume to create walls and top surface.
        // The cavity starts from z=0 (bottom of the brick) and goes up to (height - wall_t).
        // This leaves a top surface of thickness wall_t.
        translate([wall_t, wall_t, 0]) { // Position of the inner volume to subtract
            cube([
                width - 2 * wall_t,  // Inner width
                depth - 2 * wall_t,  // Inner depth
                height - wall_t      // Height of the cavity
            ]);
        }
    }
}

// Module for a single underside tube (hollow cylinder for clutch)
module underside_tube() {
    difference() {
        // Outer cylinder of the tube
        cylinder(h = underside_tube_height, d = tube_outer_diameter);
        
        // Inner hole of the tube
        // Use a common trick to ensure clean boolean subtraction by slightly extending the cutting object
        translate([0, 0, -0.01]) { // Start the hole slightly below the tube's base
             cylinder(h = underside_tube_height + 0.02, d = tube_inner_diameter); // Make hole slightly taller
        }
    }
}


// --- Main Assembly of the 3x3 LEGO Brick ---
union() {
    // 1. Create the main brick shell (walls and top surface)
    brick_shell(brick_actual_width, brick_actual_depth, main_cuboid_height, wall_thickness);

    // 2. Add studs on top of the brick shell
    for (x_idx = [0 : num_studs_x - 1]) {
        for (y_idx = [0 : num_studs_y - 1]) {
            translate([
                (x_idx * unit_size) + (unit_size / 2), // x-center of the current stud
                (y_idx * unit_size) + (unit_size / 2), // y-center of the current stud
                main_cuboid_height                     // z-position for the base of the stud (on top of the shell)
            ])
            stud(); // Place a stud
        }
    }

    // 3. Add underside tube(s)
    // For a 3x3 brick, there is typically one central tube on the underside.
    // This tube is aligned with the central stud's X,Y position.
    // The center of the brick is (brick_actual_width / 2, brick_actual_depth / 2).
    if (num_studs_x == 3 && num_studs_y == 3) { // Specifically for the requested 3x3 brick
        translate([
            brick_actual_width / 2,  // X-coordinate of the brick's center
            brick_actual_depth / 2,  // Y-coordinate of the brick's center
            0                        // Z-coordinate: base of the tube is at the bottom of the brick (z=0)
        ])
        underside_tube(); // Place the central underside tube
    }
    // Note: For more general NxM bricks, the logic for placing underside tubes would be more complex.
    // For example, a 2x2 brick also has one central tube. A 2x4 brick has three tubes.
    // This model is specific to a common 3x3 configuration with one central tube.
}