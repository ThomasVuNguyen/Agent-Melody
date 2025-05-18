// Standard LEGO Dimensions Constants (mm)
LU_CONST = 8;                             // LEGO Unit: width and depth of a 1x1 brick's base
BRICK_HEIGHT_CONST = 9.6;                 // Height of a standard brick body
PLATE_HEIGHT_CONST = BRICK_HEIGHT_CONST / 3; // Height of a plate
STUD_DIAMETER_CONST = 4.8;                // Diameter of a stud
STUD_HEIGHT_CONST = 1.8;                  // Height of a stud (LEGO uses ~1.7mm)

// Improved Design Parameters
WALL_THICKNESS_CONST = 1.2;               // Typical wall thickness for LEGO bricks
INNER_TUBE_OD_CONST = 4.8;                // Outer diameter of the central inner tube (anti-stud)
INNER_TUBE_WALL_THICKNESS_CONST = 0.8;    // Wall thickness of the inner tube (results in ~3.2mm ID)

// Aesthetics & Manufacturability Parameters
DEFAULT_FN_CONST = 64;                    // Default resolution for curves (smoother than typical 50)
BODY_FILLET_RADIUS_CONST = 0.3;           // Fillet radius for the main brick body edges
STUD_TOP_EDGE_RADIUS_CONST = 0.25;        // Radius for rounding the top edge of the stud
STUD_BASE_FILLET_RADIUS_CONST = 0.4;      // Concave fillet radius for the stud's base connection
EPS_CONST = 0.01;                         // Small epsilon value for boolean operations and thin features

// Main module for the improved 1x1 LEGO brick
module lego_1x1_brick_improved(
    unit_size = LU_CONST,
    base_height = BRICK_HEIGHT_CONST,
    stud_d = STUD_DIAMETER_CONST,
    stud_h = STUD_HEIGHT_CONST,
    wall_t = WALL_THICKNESS_CONST,
    body_fillet_r = BODY_FILLET_RADIUS_CONST,
    stud_top_r = STUD_TOP_EDGE_RADIUS_CONST,
    stud_base_r = STUD_BASE_FILLET_RADIUS_CONST,
    inner_tube_od = INNER_TUBE_OD_CONST,
    inner_tube_wall_t = INNER_TUBE_WALL_THICKNESS_CONST,
    fn = DEFAULT_FN_CONST
) {
    // Internal $fn, ensuring a minimum for detailed parts
    _fn_detail = max(16, fn / 2); 

    // The brick is constructed with its center at the local origin [0,0,0],
    // then this entire assembly is translated so its corner (previously at [-unit_size/2, -unit_size/2, -base_height/2])
    // is moved to the world origin [0,0,0], making the brick extend into positive XYZ axes.
    translate([unit_size / 2, unit_size / 2, base_height / 2]) {
        union() {
            // --- Main Brick Body (Hollow with Fillets) ---
            // All parts below are defined relative to the brick's center being at [0,0,0]
            difference() {
                // Outer filleted shape (centered at local origin)
                minkowski($fn = _fn_detail) {
                    cube([
                        unit_size - 2 * body_fillet_r,
                        unit_size - 2 * body_fillet_r,
                        base_height - 2 * body_fillet_r
                    ], center = true);
                    sphere(r = body_fillet_r, $fn = _fn_detail);
                }

                // Inner void to make the brick hollow (centered at local origin).
                // Cavity top is wall_t below brick top surface.
                // Cavity bottom extends EPS_CONST below brick bottom surface to ensure clean cut.
                _cavity_height = base_height - wall_t + EPS_CONST; // Total height of the void cube
                // Vertical center of the cavity cube, relative to brick's center:
                // Top of cavity is at z = base_height/2 - wall_t
                // Bottom of cavity is at z = -base_height/2 - EPS_CONST
                _cavity_center_z = ( (base_height / 2 - wall_t) + (-base_height / 2 - EPS_CONST) ) / 2; 
                
                translate([0, 0, _cavity_center_z]) {
                    cube([
                        unit_size - 2 * wall_t,
                        unit_size - 2 * wall_t,
                        _cavity_height
                    ], center = true);
                }
            }

            // --- Stud on Top ---
            // Stud base is on the top surface of the brick (at z = base_height / 2 relative to centered brick)
            translate([0, 0, base_height / 2]) {
                stud_with_fillets_module(
                    d = stud_d, 
                    h = stud_h, 
                    top_r = stud_top_r, 
                    base_r = stud_base_r, 
                    fn_stud = fn
                );
            }

            // --- Inner Tube (Anti-Stud) ---
            // Tube is centered in X and Y.
            // Tube extends from brick bottom (z = -base_height/2) 
            // to the underside of the top wall (z = base_height/2 - wall_t)
            _inner_tube_actual_h = base_height - wall_t;
            // Vertical center of the tube, relative to brick's center:
            // Top of tube is at z = base_height/2 - wall_t
            // Bottom of tube is at z = -base_height/2
            _inner_tube_center_z = ( (base_height / 2 - wall_t) + (-base_height / 2) ) / 2; // = -wall_t / 2
            
            if (_inner_tube_actual_h > INNER_TUBE_WALL_THICKNESS_CONST) { // Ensure tube has positive height and can be hollow
                translate([0, 0, _inner_tube_center_z]) {
                     difference() {
                        cylinder(h = _inner_tube_actual_h, d = inner_tube_od, $fn = fn, center = true);
                        // Inner cylinder to make it hollow, slightly taller to ensure clean cut
                        cylinder(h = _inner_tube_actual_h + 2 * EPS_CONST, d = inner_tube_od - 2 * inner_tube_wall_t, $fn = fn, center = true);
                    }
                }
            }
        }
    }
}

// Helper module for a stud with top and base fillets
module stud_with_fillets_module(d, h, top_r, base_r, fn_stud) {
    _fn_c = fn_stud;                         // Cylinder resolution
    _fn_s = max(12, fn_stud / 2);            // Sphere/detail resolution for minkowski/fillets
    _fn_re = max(16, fn_stud / (base_r > 0 ? 1 : 2) ); // Resolution for rotate_extrude revolutions

    _shaft_h = h - top_r; 

    union() {
        if (h > EPS_CONST) {
            if (top_r > EPS_CONST && h >= top_r) { // Use >= for robust rounding
                hull() {
                    if (_shaft_h > EPS_CONST) {
                        cylinder(d = d, h = _shaft_h, $fn = _fn_c);
                    } else { 
                        cylinder(d = d, h = EPS_CONST, $fn = _fn_c); // Min height for hull
                    }
                    translate([0, 0, h - top_r]) 
                    minkowski($fn = _fn_s) {
                        cylinder(h = EPS_CONST, d = max(EPS_CONST, d - 2 * top_r), center = true, $fn = _fn_c);
                        sphere(r = top_r, $fn = _fn_s);
                    }
                }
            } else { 
                cylinder(d = d, h = h, $fn = _fn_c);
            }
        }
        
        if (base_r > 0 && d > 0) {
            rotate_extrude(convexity = 10, $fn = _fn_re) {
                translate([d / 2, 0, 0]) 
                difference() {
                    square([base_r, base_r]);
                    translate([base_r, base_r, 0]) 
                    circle(r = base_r, $fn = _fn_s);
                }
            }
        }
    }
}

// Instantiate the improved 1x1 LEGO brick
lego_1x1_brick_improved();

// --- Examples (uncomment to view) ---

// Example of a 1x1 plate (1/3 height of a brick)
// translate([LU_CONST * 1.5, 0, 0]) {
//     lego_1x1_brick_improved(base_height = PLATE_HEIGHT_CONST, fn = 48, stud_base_r = 0.2);
// }

// Example with different fillet sizes
// translate([LU_CONST * 3.0, 0, 0]) {
//    lego_1x1_brick_improved(body_fillet_r = 0.8, stud_top_r = 0.5, stud_base_r = 0.6);
// }

// Lower resolution example
// translate([LU_CONST * -1.5, 0, 0]) {
//    lego_1x1_brick_improved(fn = 24);
// }
