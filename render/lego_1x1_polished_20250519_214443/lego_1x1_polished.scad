// Standard LEGO Dimensions (in mm)
// These constants define the basic properties of LEGO bricks.

// UNIT_SIZE represents the width/depth of a single stud footprint (e.g., a 1x1 brick is UNIT_SIZE x UNIT_SIZE).
UNIT_SIZE = 8;

// BRICK_HEIGHT is the height of a standard LEGO brick.
BRICK_HEIGHT = 9.6;

// PLATE_HEIGHT is 1/3 of a BRICK_HEIGHT.
PLATE_HEIGHT = BRICK_HEIGHT / 3; // Approximately 3.2mm

// STUD_DIAMETER is the diameter of the cylindrical stud on top of LEGO bricks.
STUD_DIAMETER = 4.8;

// STUD_HEIGHT is the height of the stud that protrudes from the brick's top surface.
STUD_HEIGHT = 1.8;

// WALL_THICKNESS is the typical thickness of the outer walls and internal structures.
WALL_THICKNESS = 1.6;

// FN is the global resolution for cylindrical parts ($fn).
FN = 48;


// --- Polish Parameters ---
// These parameters control the "beautification" aspects like fillets and chamfers,
// making the design more aesthetically pleasing and manufacturable.

// Radius for filleting the main edges of the brick body.
body_edge_fillet_radius = 0.3;

// Number of segments used to approximate the quarter-circle arc in stud fillets.
// Higher values give smoother stud fillets. (e.g., 8 means 9 points for the arc)
stud_profile_fillet_detail = 8;

// Radius of the fillet on the top edge of the stud.
stud_top_edge_radius = 0.2;

// Radius of the fillet at the base of the stud, where it meets the brick top surface.
stud_base_fillet_radius = 0.3;

// Vertical depth of the chamfer on the underside cavity's opening.
cavity_chamfer_depth = 0.4;

// Horizontal extent of the chamfer (how much it widens the cavity opening at the bottom).
cavity_chamfer_horizontal_extent = 0.4;

// Small offset for boolean operations to prevent z-fighting and ensure clean cuts.
epsilon = 0.01;

// $fn values for different levels of detail in polished features.
// Higher values result in smoother curves but increase rendering time.
FN_polish_high = FN;                     // For critical curves like stud profiles, cavity.
FN_polish_medium = max(32, floor(FN*2/3)); // For body fillets. Ensures a minimum quality.


// --- Helper Module for Profiled Stud ---
// Creates a stud using rotate_extrude with a 2D profile that includes base and top fillets.
// This provides smooth transitions at the stud's base and top edge.
module lego_stud_profiled(stud_h, stud_d, top_r, base_r, detail, fn_rotate) {
    stud_radius = stud_d / 2;

    // Generate points for the 2D profile of the stud.
    // The profile defines one half of the stud's cross-section, to be rotated around the Z-axis.
    // Points are ordered to form a closed polygon for rotate_extrude.
    profile_points = concat(
        [[0,0]], // Point 1: Bottom center of the stud profile (axis of rotation)

        // Points for the base fillet (convex quarter circle)
        // This creates a smooth transition from the brick surface to the stud's vertical wall.
        // Loop generates points from (stud_radius - base_r, 0) to (stud_radius, base_r)
        [for (i = [0 : detail])
            let(angle = 90 * i / detail) // Angle for arc segment, from 0 to 90 degrees
            [stud_radius - base_r + base_r * sin(angle), base_r * (1 - cos(angle))]
        ],
        // The last point of the base fillet loop is [stud_radius, base_r].

        // Explicit point for the vertical segment of the stud, if one exists between fillets.
        // This connects the end of the base fillet [stud_radius, base_r]
        // to the start of the top fillet [stud_radius, stud_h - top_r].
        // Only add this point if there's space for a vertical segment.
        (stud_h - top_r > base_r) ? [[stud_radius, stud_h - top_r]] : [],

        // Points for the top fillet (convex quarter circle)
        // This rounds the top edge of the stud.
        // Loop generates points from (stud_radius, stud_h - top_r) to (stud_radius - top_r, stud_h)
        [for (i = [0 : detail])
            let(angle = 90 * i / detail) // Angle for arc segment, from 0 to 90 degrees
            [stud_radius - top_r + top_r*cos(angle), stud_h - top_r + top_r*sin(angle)]
        ],
        // The last point of the top fillet loop is [stud_radius - top_r, stud_h].

        [[0, stud_h]] // Point N: Top center of the stud profile (axis of rotation)
    );

    rotate_extrude(convexity = 10, $fn = fn_rotate)
        polygon(profile_points);
}


// --- Main Module for Polished 1x1 LEGO Brick ---
module lego_1x1_brick_polished() {
    // Calculate base dimensions for the 1x1 brick
    brick_width = 1 * UNIT_SIZE;
    brick_depth = 1 * UNIT_SIZE;
    main_body_height = BRICK_HEIGHT;

    difference() {
        // --- Part 1: Positive Geometry (Solid parts of the brick) ---
        union() {
            // 1a. Main Body of the Brick - Filleted Cube
            // Creates a cube with all edges and corners smoothly filleted.
            // This is achieved by taking the Minkowski sum of a slightly smaller inner cube and a sphere.
            // The resulting filleted cube accurately spans from [0,0,0] to [brick_width, brick_depth, main_body_height].
            minkowski() {
                // Inner cube, translated so the minkowski sum aligns its corner to origin [0,0,0].
                translate([body_edge_fillet_radius, body_edge_fillet_radius, body_edge_fillet_radius])
                    cube([brick_width  - 2*body_edge_fillet_radius,
                          brick_depth  - 2*body_edge_fillet_radius,
                          main_body_height - 2*body_edge_fillet_radius]);
                // Sphere used for filleting. Its $fn value controls the smoothness of the fillets.
                sphere(r = body_edge_fillet_radius, $fn = FN_polish_medium);
            }

            // 1b. Top Stud - With filleted base and top edge
            // Positioned at the center of the brick's top surface.
            // The stud's base fillet will blend smoothly with the (now slightly curved due to filleting) top surface of the main body.
            translate([brick_width / 2, brick_depth / 2, main_body_height]) {
                 lego_stud_profiled(
                     stud_h = STUD_HEIGHT,                // Target height of the stud
                     stud_d = STUD_DIAMETER,              // Target diameter of the stud
                     top_r = stud_top_edge_radius,        // Radius of the top edge fillet
                     base_r = stud_base_fillet_radius,    // Radius of the base fillet
                     detail = stud_profile_fillet_detail, // Number of segments for fillet arcs
                     fn_rotate = FN_polish_high           // $fn for rotate_extrude smoothness
                 );
            }
        }

        // --- Part 2: Negative Geometry (Cavity on the underside) ---
        // Standard LEGO underside cavity parameters
        cavity_diameter = STUD_DIAMETER;
        // Depth of the cavity's main cylindrical part, measured from the brick's top surface (underside of the "ceiling").
        cavity_main_section_depth_from_top = main_body_height - WALL_THICKNESS;

        // Position the center of the cavity system at the brick's underside center (X,Y) and bottom plane (Z=0).
        translate([brick_width / 2, brick_depth / 2, 0]) {
            // Main cutting cylinder for the cavity.
            // This cylinder starts at the top of the chamfer and extends upwards to form the main part of the cavity.
            // Epsilon offset is used for robust boolean subtraction.
            translate([0,0, cavity_chamfer_depth - epsilon]) // Position base of cylinder at top of chamfer
                cylinder(h = cavity_main_section_depth_from_top - cavity_chamfer_depth + 2*epsilon, // Height of main cylinder
                         d = cavity_diameter,
                         $fn = FN_polish_high);

            // Chamfer cutter for the cavity opening.
            // This is a conical cylinder (frustum) that creates a chamfered (sloped) edge at the cavity's mouth (z=0).
            // It improves manufacturability (mold release) and ease of assembly with other bricks.
            // It extends from slightly below z=0 up to cavity_chamfer_depth.
            translate([0,0, -epsilon]) // Start cutter slightly below z=0 for a clean cut
                cylinder(h = cavity_chamfer_depth + epsilon, // Height of the chamfer cutting tool
                         d1 = cavity_diameter + 2*cavity_chamfer_horizontal_extent, // Wider diameter at the base (z=0)
                         d2 = cavity_diameter,                                  // Normal diameter at the top of the chamfer
                         $fn = FN_polish_high);
        }
    }
}

// Instantiate the module to generate the polished 1x1 LEGO brick model.
lego_1x1_brick_polished();
