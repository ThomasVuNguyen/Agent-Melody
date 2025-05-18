// Basic IKEA-style Chair in OpenSCAD
// All dimensions are in millimeters.

// --- Chair Configuration ---
seat_w = 400; // Width of the seat (X-axis)
seat_d = 400; // Depth of the seat (Y-axis)
seat_top_h = 450; // Height from floor to top of seat surface

backrest_h_above_seat = 420; // Height of backrest extending above the seat
backrest_w_ratio = 0.90; // Width of backrest relative to seat width
backrest_tilt_angle = 8; // Tilt angle of the backrest from vertical (positive tilts back)

// --- Material Thicknesses & Component Sizes ---
seat_thickness = 20;
backrest_thickness = 15;
leg_side = 35; // Square legs, side length
strut_side = 20; // Square struts, side length

// --- Derived Dimensions ---
actual_leg_h = seat_top_h - seat_thickness;
actual_backrest_w = seat_w * backrest_w_ratio;

// --- Strut Placement ---
// Z height of the *bottom* surface of the struts from the floor
strut_level_z = 100; 

$fn = 50; // Smoothness for any curves (though not explicitly used for cubes)

// --- Modules for Chair Parts ---

module leg() {
    cube([leg_side, leg_side, actual_leg_h]);
}

module seat_panel() {
    cube([seat_w, seat_d, seat_thickness]);
}

module backrest_panel() {
    // Centered for easier rotation placement later
    // Dimensions: X=width, Y=thickness, Z=height
    cube([actual_backrest_w, backrest_thickness, backrest_h_above_seat], center=true);
}

module strut_along_x(length) {
    // Strut oriented along the X-axis
    cube([length, strut_side, strut_side]);
}

module strut_along_y(length) {
    // Strut oriented along the Y-axis
    cube([strut_side, length, strut_side]);
}

// --- Assemble the Chair ---
// The chair's front-left-bottom corner (of front-left leg) is at origin [0,0,0]

union() {
    // --- Legs ---
    // Front-Left Leg
    translate([0, 0, 0]) 
        leg();
        
    // Front-Right Leg
    translate([seat_w - leg_side, 0, 0]) 
        leg();
        
    // Back-Left Leg
    translate([0, seat_d - leg_side, 0]) 
        leg();
        
    // Back-Right Leg
    translate([seat_w - leg_side, seat_d - leg_side, 0]) 
        leg();

    // --- Seat ---
    // Positioned on top of the legs. Its bottom surface is at Z = actual_leg_h.
    translate([0, 0, actual_leg_h]) 
        seat_panel();

    // --- Backrest ---
    // Pivot point for the backrest: center of the seat's back edge, on its top surface.
    backrest_pivot_x = seat_w / 2;
    backrest_pivot_y = seat_d; // At the very back edge of the seat panel
    backrest_pivot_z = seat_top_h; // At the top surface of the seat panel

    translate([backrest_pivot_x, backrest_pivot_y, backrest_pivot_z]) {
        rotate([backrest_tilt_angle, 0, 0]) { // Rotate around X-axis (tilts in Y-Z plane)
            // The backrest_panel module is already centered.
            // We need to shift it so its conceptual "front-bottom-center" aligns with the pivot.
            // Shift its center by half its thickness in Y and half its height in Z.
            translate([0, backrest_thickness / 2, backrest_h_above_seat / 2]) {
                backrest_panel();
            }
        }
    }

    // --- Struts (Support Beams) ---
    // Struts are placed between the inner faces of the legs.
    
    // Front Strut (runs along X-axis, under the front of the seat)
    front_strut_len = seat_w - 2 * leg_side;
    if (front_strut_len > 0) {
        translate([
            leg_side, // Start at inner face of left leg
            (leg_side - strut_side) / 2, // Center strut in depth of front leg
            strut_level_z // Z position from floor
        ])
            strut_along_x(front_strut_len);
    }

    // Back Strut (runs along X-axis, under the back of the seat)
    back_strut_len = seat_w - 2 * leg_side; // Same length as front strut
    if (back_strut_len > 0) {
        translate([
            leg_side, // Start at inner face of left leg
            seat_d - leg_side + (leg_side - strut_side) / 2, // Y pos: Center strut in depth of back leg
            strut_level_z // Z position from floor
        ])
            strut_along_x(back_strut_len);
    }

    // Side Struts (run along Y-axis)
    side_strut_len = seat_d - 2 * leg_side;
    if (side_strut_len > 0) {
        // Left Side Strut
        translate([
            (leg_side - strut_side) / 2, // X pos: Center strut in width of left leg
            leg_side, // Start at inner face of front leg (or back face of front leg)
            strut_level_z // Z position from floor
        ])
            strut_along_y(side_strut_len);

        // Right Side Strut
        translate([
            seat_w - leg_side + (leg_side - strut_side) / 2, // X pos: Center strut in width of right leg
            leg_side, // Start at inner face of front leg
            strut_level_z // Z position from floor
        ])
            strut_along_y(side_strut_len);
    }
}

// Example of how to view it slightly rotated:
// translate([0, -seat_d/2, 0]) rotate([0,0,30]) rotate([30,0,0]) chair(); 
// (if you wrap the union() in a module chair())