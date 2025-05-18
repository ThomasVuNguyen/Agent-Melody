// Simple Modern Chair
// Design by an AI CAD Engineer

// --- Parameters ---
// General chair dimensions
seat_width = 40;          // Width of the seat (along X-axis)
seat_depth = 40;          // Depth of the seat (along Y-axis)
seat_thickness = 4;       // Thickness of the seat plate

// Leg properties
leg_diameter = 4;         // Diameter of the cylindrical legs
leg_height = 40;          // Height of the legs (floor to bottom of seat)
leg_inset = 3;            // Distance legs are inset from the seat edges

// Backrest properties
backrest_width_factor = 0.95; // Backrest width as a factor of seat_width
backrest_height = 45;     // Height of the backrest panel (from seat surface)
backrest_thickness = seat_thickness; // Thickness of the backrest panel
backrest_angle = 10;      // Backwards tilt angle of the backrest in degrees

// --- Quality Settings ---
// $fn is used by cylinder() for number of facets. Higher is smoother.
cylinder_fn = 32;

// --- Derived Parameters (calculated from primary parameters) ---
backrest_actual_width = seat_width * backrest_width_factor; // Actual width of the backrest

// --- Component Modules ---

// Module for the seat
module seat_component() {
    // The seat is a simple cube.
    // It's centered horizontally (X, Y axes).
    // Its bottom surface is positioned at Z = leg_height.
    // So, its center is at Z = leg_height + seat_thickness / 2.
    translate([0, 0, leg_height + seat_thickness / 2])
        cube([seat_width, seat_depth, seat_thickness], center = true);
}

// Module for a single leg
// The leg is a cylinder.
// Its origin (0,0,0 within this module) is at the center of its bottom face.
module leg_component() {
    cylinder(h = leg_height, d = leg_diameter, $fn = cylinder_fn);
}

// Module for the backrest
module backrest_component() {
    // The backrest is positioned and rotated relative to the seat's top-rear edge.
    // The rotation axis for the tilt is along the X-direction,
    // located at Y = seat_depth / 2 (rear edge of the seat),
    // and Z = leg_height + seat_thickness (top surface of the seat).
    
    base_z_position = leg_height + seat_thickness;
    base_y_position = seat_depth / 2;

    // Translate to the pivot point on the seat's rear edge
    translate([0, base_y_position, base_z_position]) {
        // Rotate for the backrest tilt
        rotate([backrest_angle, 0, 0]) {
            // Create the backrest cube itself.
            // In its own local coordinate system (before transformations in this module):
            // - It's centered along its width (X-axis).
            // - Its "front" face (surface towards the seat center) is at Y = 0.
            // - Its "bottom" face (surface resting on the seat) is at Z = 0.
            translate([-backrest_actual_width / 2, 0, 0])
                cube([backrest_actual_width, backrest_thickness, backrest_height]);
        }
    }
}

// --- Main Chair Assembly Module ---
module chair() {
    // Add the seat
    seat_component();

    // Calculate the XY offset for placing the center of each leg.
    // This positions the legs relative to the chair's center (0,0).
    leg_center_offset_x = seat_width / 2 - leg_diameter / 2 - leg_inset;
    leg_center_offset_y = seat_depth / 2 - leg_diameter / 2 - leg_inset;

    // Place the four legs
    // Front-left leg
    translate([-leg_center_offset_x, -leg_center_offset_y, 0])
        leg_component();

    // Front-right leg
    translate([leg_center_offset_x, -leg_center_offset_y, 0])
        leg_component();

    // Back-left leg
    translate([-leg_center_offset_x, leg_center_offset_y, 0])
        leg_component();

    // Back-right leg
    translate([leg_center_offset_x, leg_center_offset_y, 0])
        leg_component();
    
    // Add the backrest
    backrest_component();
}

// --- Instantiate the Chair ---
// This line creates the chair model.
chair();