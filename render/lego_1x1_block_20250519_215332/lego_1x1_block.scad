// --- Parameters for LEGO Dimensions (mm) ---
P_LEGO_UNIT = 8;          // Basic LEGO unit, equivalent to stud pitch
P_BRICK_BODY_HEIGHT = 9.6;  // Height of the main body of a brick
P_STUD_HEIGHT = 1.8;      // Height of a stud
P_STUD_DIAMETER = 4.8;    // Diameter of a stud
P_TOP_WALL_THICKNESS = 1.2; // Material thickness at the top of the brick

// --- Parameters for this specific 1x1 brick ---
NUM_STUDS_X = 1;
NUM_STUDS_Y = 1;

// --- Rendering Quality ---
FN_MAIN_CYLINDER = 64;    // Facets for primary cylindrical features (stud, hole)
FN_FILLET_DETAIL = 32;    // Facets for smaller fillets and chamfers

// --- Aesthetic and Manufacturability Parameters ---
P_BODY_EDGE_FILLET_RADIUS = 0.2;   // Fillet radius for main brick body edges (0 for sharp)
P_STUD_TOP_CHAMFER_HEIGHT = 0.2;   // Height of the chamfer on top of the stud (0 for no chamfer)
P_STUD_TOP_CHAMFER_R_OFFSET = 0.2; // Radial offset for stud top chamfer (defines angle)
P_STUD_BASE_FILLET_RADIUS = 0.3;   // Radius for the convex fillet at the base of the stud (0 for sharp base)
P_BOTTOM_HOLE_CHAMFER_HEIGHT = 0.3;// Height of the chamfer for the bottom hole entrance (0 for no chamfer)
P_BOTTOM_HOLE_CHAMFER_R_OFFSET = 0.3; // Radial offset for bottom hole chamfer

// --- Derived Dimensions (calculated from parameters) ---
brick_actual_width = P_LEGO_UNIT * NUM_STUDS_X;
brick_actual_depth = P_LEGO_UNIT * NUM_STUDS_Y;
stud_radius = P_STUD_DIAMETER / 2;

// Depth of the cylindrical hole on the underside of the brick.
bottom_hole_total_depth = P_BRICK_BODY_HEIGHT - P_TOP_WALL_THICKNESS;

// Small epsilon for ensuring boolean operations work smoothly and geometry is valid
EPS = 0.001;

// Module for a cube with rounded edges and corners
module rounded_cube(size, radius) {
    // Ensure radius is not too large for the given size and non-negative
    safe_radius = max(0, min([radius, size[0]/2 - EPS, size[1]/2 - EPS, size[2]/2 - EPS]));

    if (safe_radius < EPS) { // If radius is negligible, draw a simple cube
        cube(size);
    } else {
        // Position offset due to minkowski sum with a sphere starting at origin
        translate([safe_radius, safe_radius, safe_radius])
        minkowski() {
            cube([size[0] - 2 * safe_radius,
                  size[1] - 2 * safe_radius,
                  size[2] - 2 * safe_radius]);
            sphere(r = safe_radius, $fn = FN_FILLET_DETAIL);
        }
    }
}

// Module to create an enhanced 1x1 LEGO compatible block
module lego_1x1_brick_enhanced() {
    // Main Body of the Brick
    difference() {
        // 1. Solid base part of the brick, with rounded edges if specified
        rounded_cube([brick_actual_width, brick_actual_depth, P_BRICK_BODY_HEIGHT],
                     P_BODY_EDGE_FILLET_RADIUS);

        // 2. Cylindrical hole (anti-stud) on the underside
        translate([brick_actual_width / 2, brick_actual_depth / 2, 0]) {
            // Effective chamfer height, ensuring it's positive and not exceeding hole depth
            chamfer_h_eff = 0;
            if (P_BOTTOM_HOLE_CHAMFER_HEIGHT > EPS && P_BOTTOM_HOLE_CHAMFER_R_OFFSET > EPS && bottom_hole_total_depth > EPS) {
                chamfer_h_eff = min(P_BOTTOM_HOLE_CHAMFER_HEIGHT, bottom_hole_total_depth);
                
                cylinder(d1 = P_STUD_DIAMETER + 2 * P_BOTTOM_HOLE_CHAMFER_R_OFFSET,
                         d2 = (chamfer_h_eff < bottom_hole_total_depth) ? P_STUD_DIAMETER : 
                              P_STUD_DIAMETER + 2 * P_BOTTOM_HOLE_CHAMFER_R_OFFSET * (1 - bottom_hole_total_depth / P_BOTTOM_HOLE_CHAMFER_HEIGHT), // Adjust d2 if chamfer is entire hole
                         h = chamfer_h_eff + (chamfer_h_eff < bottom_hole_total_depth ? EPS : 0), // Overlap if main hole follows
                         $fn = FN_MAIN_CYLINDER);
            }

            // Main part of the anti-stud hole (if any part remains after chamfer)
            main_hole_start_z = chamfer_h_eff;
            main_hole_h = bottom_hole_total_depth - main_hole_start_z;

            if (main_hole_h > EPS) {
                 translate([0, 0, main_hole_start_z])
                 cylinder(d = P_STUD_DIAMETER,
                         h = main_hole_h, 
                         $fn = FN_MAIN_CYLINDER);
            }
        }
    }

    // Stud on top of the brick
    translate([brick_actual_width / 2, brick_actual_depth / 2, P_BRICK_BODY_HEIGHT]) {
        // Effective heights for stud components
        chamfer_h_eff = (P_STUD_TOP_CHAMFER_HEIGHT > EPS && P_STUD_TOP_CHAMFER_R_OFFSET > EPS) ? min(P_STUD_TOP_CHAMFER_HEIGHT, P_STUD_HEIGHT) : 0;
        base_fillet_rise_eff = (P_STUD_BASE_FILLET_RADIUS > EPS) ? min(P_STUD_BASE_FILLET_RADIUS, P_STUD_HEIGHT - chamfer_h_eff) : 0;

        // Height of the main cylindrical shaft of the stud
        stud_shaft_h = P_STUD_HEIGHT - chamfer_h_eff - base_fillet_rise_eff;
        // Ensure a minimum height for the shaft if it's part of hull or has a chamfer
        stud_shaft_h = max(stud_shaft_h, (chamfer_h_eff > EPS || base_fillet_rise_eff > EPS) ? EPS : 0.01);


        // Stud base and shaft
        if (base_fillet_rise_eff > EPS) { // With base fillet (using hull)
            hull() {
                // Upper part of hull: main stud cylinder (below chamfer)
                translate([0, 0, base_fillet_rise_eff])
                cylinder(d = P_STUD_DIAMETER,
                         h = stud_shaft_h + (chamfer_h_eff > EPS ? EPS:0), // Overlap with chamfer
                         $fn = FN_MAIN_CYLINDER);
                // Lower part of hull: base disk for fillet
                cylinder(d = P_STUD_DIAMETER + 2 * P_STUD_BASE_FILLET_RADIUS,
                         h = EPS, // Very thin disk
                         $fn = FN_MAIN_CYLINDER);
            }
        } else { // No base fillet, just a straight cylinder shaft
            if (stud_shaft_h > EPS) {
                 cylinder(d = P_STUD_DIAMETER,
                         h = stud_shaft_h + (chamfer_h_eff > EPS ? EPS:0), // Overlap with chamfer
                         $fn = FN_MAIN_CYLINDER);
            }
        }

        // Top chamfer of the stud
        if (chamfer_h_eff > EPS) {
            // d2_chamfer: ensure stud doesn't become pointy or inverted if offset is too large
            stud_top_chamfer_d2 = max(0, P_STUD_DIAMETER - 2 * P_STUD_TOP_CHAMFER_R_OFFSET);
            translate([0, 0, P_STUD_HEIGHT - chamfer_h_eff])
            cylinder(d1 = P_STUD_DIAMETER,
                     d2 = stud_top_chamfer_d2,
                     h = chamfer_h_eff,
                     $fn = FN_MAIN_CYLINDER);
        }
    }
}

// Instantiate the enhanced 1x1 LEGO brick
lego_1x1_brick_enhanced();
