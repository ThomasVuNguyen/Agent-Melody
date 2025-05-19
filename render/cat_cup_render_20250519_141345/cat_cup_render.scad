// Cat Cup Design - Improved Version
// Design focused on aesthetics, smooth transitions, and manufacturability.

// Global smoothness - can be increased for final render
$fn = 75; // Increased from original for smoother curves

// --- Parameters ---
// These parameters are similar to the original, with some adjustments for new features.

// Cup dimensions
cup_height = 80;            // Height of the cup
cup_diameter_bottom = 60;   // Diameter at the base of the cup
cup_diameter_top = 70;      // Diameter at the top (rim) of the cup
cup_wall_thickness = 3.5;   // Slightly increased for robustness with fillets
cup_base_thickness = 5;     // Slightly increased for robustness with fillets

// Fillet and rounding parameters for the cup body
cup_lip_rounding_factor = 0.45; // Factor of wall_thickness for lip rounding radius (0.5 for full round)
cup_inner_base_fillet_radius = 2.5; // Radius of the fillet inside the cup at the base
cup_outer_base_fillet_radius = 1.5; // Radius of the fillet outside the cup at the base

// Ear dimensions and style
ear_height = 24;            // Height of the ears from base to tip
ear_width_base = 22;        // Approximate width of the ear at its base (for profile generation)
ear_thickness_factor = 1.6; // Multiplier for ear thickness relative to cup_wall_thickness
ear_angle_offset = 25;      // Angle (degrees) of ears from cup's side towards the front
ear_minkowski_rounding_factor = 0.2; // Factor of ear's actual_thickness for Minkowski sphere rounding (smooths edges)
ear_scoop_enabled = true;   // Enable the inner scoop detail on ears for a more organic look

// Handle dimensions and style
handle_sph_radius = 5.5;      // Radius of the main handle loop's cross-section
handle_attach_sph_factor = 1.3; // Factor for larger spheres at attachment points (e.g., 1.3 = 30% larger)
handle_loop_protrusion = 22;// How far the main loop of the handle sticks out from the cup surface
handle_attach_spread = 38;  // Vertical distance between the handle's attachment points on the cup
handle_z_center_factor = 0.55; // Vertical position of the handle's center, as a factor of cup_height
handle_embed_factor = 0.4;    // How much attachment spheres are embedded (0=surface, 1=fully embedded center)

// Face feature parameters
enable_face = true;         // Set to false to render the cup without face features
eye_radius = 3.8;           // Approximate visual radius of the eye indentations
eye_depth = 1.8;            // How deep the eye indentations are
eye_spacing = 19;           // Horizontal distance between the centers of the eyes
eye_z_factor = 0.70;        // Vertical position of eyes, as a factor of cup_height
eye_elongation_factor = 1.4; // Makes eyes wider than tall (1.0 for circular impression)
eye_cutter_fn = 24;         // $fn for eye cutting tool geometry

nose_size = 4.5;            // Approximate visual size of the nose indentation
nose_depth = 1.6;           // How deep the nose indentation is
nose_z_factor = 0.62;       // Vertical position of the nose, as a factor of cup_height
nose_width_factor = 1.15;   // Scales the X-axis of the nose cutter for a wider look
nose_flatten_factor = 0.85; // Scales the Y-axis of the nose cutter for a flatter look (into cup)
nose_cutter_fn = 20;        // $fn for nose cutting tool geometry

// --- Helper Functions ---

// Linear interpolation function
function lerp(a, b, t) = a + (b - a) * t;

// --- Modules ---

// Module for the main cup body with rounded lip and filleted base
module main_cup_body() {
    lip_radius = cup_wall_thickness * cup_lip_rounding_factor;
    fn_torus = max(24, $fn/2); // Specific $fn for torii for performance/quality balance

    difference() {
        // --- Positive part: Outer shell of the cup ---
        union() {
            // Main cylinder for outer shape, stopping short for lip rounding
            cylinder(h = cup_height - lip_radius,
                     r1 = cup_diameter_bottom/2,
                     r2 = cup_diameter_top/2 - lip_radius, $fn=$fn);

            // Torus for outer part of lip rounding
            translate([0,0,cup_height - lip_radius])
                rotate_extrude(convexity=10, $fn=fn_torus)
                    translate([cup_diameter_top/2 - lip_radius, 0,0])
                        circle(r=lip_radius);

            // Outer base fillet
            if (cup_outer_base_fillet_radius > 0) {
                 translate([0,0,cup_outer_base_fillet_radius])
                    rotate_extrude(convexity=10, $fn=fn_torus)
                        translate([cup_diameter_bottom/2 - cup_outer_base_fillet_radius, 0, 0])
                            circle(r = cup_outer_base_fillet_radius);
            }
        }

        // --- Negative part: Inner void of the cup ---
        union() {
            // Main cylinder for inner void, adjusted for base thickness and lip rounding
            translate([0, 0, cup_base_thickness])
                cylinder(h = cup_height - cup_base_thickness - lip_radius + 0.2, // +0.2 ensures clean cut through lip area
                         r1 = (cup_diameter_bottom/2) - cup_wall_thickness,
                         r2 = (cup_diameter_top/2) - cup_wall_thickness + lip_radius, // Taper to meet inner lip rounding
                         $fn=$fn);

            // Torus for inner part of lip rounding (void)
            translate([0,0,cup_height - lip_radius])
                rotate_extrude(convexity=10, $fn=fn_torus)
                    translate([(cup_diameter_top/2 - cup_wall_thickness) + lip_radius, 0,0])
                        circle(r=lip_radius);
        }
    }

    // Add inner base fillet (positive material addition after main difference)
    if (cup_inner_base_fillet_radius > 0) {
        translate([0,0, cup_base_thickness + cup_inner_base_fillet_radius]) {
             rotate_extrude(convexity=10, $fn=fn_torus)
                translate([(cup_diameter_bottom/2 - cup_wall_thickness) + cup_inner_base_fillet_radius, 0,0])
                    circle(r=cup_inner_base_fillet_radius);
        }
    }
}


// Module for a single improved cat ear primitive
module cat_ear_primitive() {
    actual_ear_thickness = cup_wall_thickness * ear_thickness_factor;
    ear_rounding_radius = actual_ear_thickness * ear_minkowski_rounding_factor;
    fn_ear_profile = max(16, $fn/4); // $fn for 2D ear profile circles
    fn_minkowski_sph = max(10, $fn/6); // $fn for Minkowski helper sphere

    // Base shape for extrusion (before Minkowski rounding)
    // Extruded with reduced thickness to allow Minkowski sum to achieve target thickness
    module ear_core_extrude() {
        linear_extrude(height = actual_ear_thickness * (1 - 2*ear_minkowski_rounding_factor), center = true) {
             hull() { // Rounded 2D profile for the ear
                translate([-ear_width_base/2 * 0.7, ear_height * 0.05]) circle(r = ear_width_base * 0.25, $fn=fn_ear_profile);
                translate([ ear_width_base/2 * 0.7, ear_height * 0.05]) circle(r = ear_width_base * 0.25, $fn=fn_ear_profile);
                translate([0, ear_height]) circle(r = ear_width_base * 0.12, $fn=fn_ear_profile); // Slightly blunted tip before rounding
            }
        }
    }

    difference() {
        // Main ear shape with rounded edges via Minkowski sum
        minkowski($fn=fn_minkowski_sph) {
            ear_core_extrude();
            sphere(r = ear_rounding_radius, $fn=fn_minkowski_sph); // Sphere for rounding
        }

        // Inner scoop detail for a more organic look
        if (ear_scoop_enabled) {
            ear_scoop_depth_factor = 0.6; // Scoop depth as factor of actual_ear_thickness
            ear_scoop_visual_depth = actual_ear_thickness * ear_scoop_depth_factor;
            ear_scoop_inset = ear_rounding_radius + actual_ear_thickness * 0.05; // Shift scoop "forward" (local Z+)
            ear_scoop_scale_xy = 0.65; // How much smaller the scoop profile is
            fn_scoop_profile = max(12, $fn/5);

            translate([0, ear_height * 0.1, ear_scoop_inset]) { // Position scoop within the ear
                scale([ear_scoop_scale_xy, ear_scoop_scale_xy, 1]) { // Scale X and Y for scoop shape
                     linear_extrude(height = ear_scoop_visual_depth, center=true) {
                        // Adjust Y to align scoop nicely after scaling
                        translate([0, ear_height * (1-ear_scoop_scale_xy)/2 + ear_height * 0.02, 0])
                             hull() { // Scaled down profile for scoop cutter
                                translate([-ear_width_base/2*0.7*0.9, ear_height*0.05]) circle(r = ear_width_base*0.25*ear_scoop_scale_xy, $fn=fn_scoop_profile);
                                translate([ ear_width_base/2*0.7*0.9, ear_height*0.05]) circle(r = ear_width_base*0.25*ear_scoop_scale_xy, $fn=fn_scoop_profile);
                                translate([0, ear_height]) circle(r = ear_width_base*0.12*ear_scoop_scale_xy*0.7, $fn=fn_scoop_profile); // Sharper inner tip
                            }
                    }
                }
            }
        }
    }
}

// Module to create and position both cat ears
module cat_ears() {
    // The center plane of the ear primitive is placed on the cup's outer top radius.
    // Minkowski rounding on the ear helps create a natural fillet at the join.
    ear_placement_radius_on_cup = cup_diameter_top/2;
    // Ears are placed at cup_height; they will sit on the rounded lip.

    // Right Ear (cup front is +Y, right ear is +X side of +Y)
    angle_R_global = 90 - ear_angle_offset; // Angle from world +X axis
    rotate([0,0, angle_R_global]) {
        translate([ear_placement_radius_on_cup, 0, cup_height]) { // Position ear on cup rim
            // Orient ear: Y-height to world Z (up), Z-thickness to world X (radial)
            rotate([90,0,0]) { rotate([0,90,0]) { cat_ear_primitive(); } }
        }
    }

    // Left Ear
    angle_L_global = 90 + ear_angle_offset;
    rotate([0,0, angle_L_global]) {
        translate([ear_placement_radius_on_cup, 0, cup_height]) {
            rotate([90,0,0]) { rotate([0,90,0]) { cat_ear_primitive(); } }
        }
    }
}

// Module for the improved cup handle with smoother attachments
module cat_cup_handle() {
    handle_center_z = cup_height * handle_z_center_factor;
    avg_cup_radius_at_handle_height = lerp(cup_diameter_bottom/2, cup_diameter_top/2, handle_center_z / cup_height);

    attach_sph_effective_radius = handle_sph_radius * handle_attach_sph_factor;
    fn_handle_sph = max(20, $fn/2); // $fn for handle spheres

    // Calculate Y offset for attachment points to embed them into the cup for a stronger, smoother join.
    // (1-embed_factor) * radius remains outside the original cup surface line, embed_factor * radius goes inside.
    // Center of attachment sphere: -( cup_wall_radius - part_of_sphere_radius_outside_wall )
    attachment_y_offset = -(avg_cup_radius_at_handle_height - attach_sph_effective_radius * (1-handle_embed_factor));

    p1_attach = [0, attachment_y_offset , handle_center_z + handle_attach_spread/2]; // Top attachment
    p2_attach = [0, attachment_y_offset , handle_center_z - handle_attach_spread/2]; // Bottom attachment
    p3_loop_outer = [0, -(avg_cup_radius_at_handle_height + handle_loop_protrusion), handle_center_z]; // Outer point of loop

    hull() { // Top part of handle loop
        translate(p1_attach) sphere(r=attach_sph_effective_radius, $fn=fn_handle_sph);
        translate(p3_loop_outer) sphere(r=handle_sph_radius, $fn=fn_handle_sph);
    }
    hull() { // Bottom part of handle loop
        translate(p2_attach) sphere(r=attach_sph_effective_radius, $fn=fn_handle_sph);
        translate(p3_loop_outer) sphere(r=handle_sph_radius, $fn=fn_handle_sph);
    }
    // Hull connecting attachment points directly along the cup body for sturdiness
    // Use slightly smaller spheres for this connecting piece if desired.
    hull() {
        translate(p1_attach) sphere(r=attach_sph_effective_radius * 0.9, $fn=fn_handle_sph);
        translate(p2_attach) sphere(r=attach_sph_effective_radius * 0.9, $fn=fn_handle_sph);
    }
}

// Module for improved face features (eyes and nose indentations)
module cat_face_indentations() {
    // --- Eyes ---
    eye_actual_z_pos = cup_height * eye_z_factor;
    cup_surface_radius_at_eye_height = lerp(cup_diameter_bottom/2, cup_diameter_top/2, eye_actual_z_pos / cup_height);

    // Base radius for the cutting tool (before elongation or other shaping)
    eye_tool_base_radius = eye_radius * 1.2; // Adjusted for visual eye_radius after indent
    // Y position for the center of the cutting tool to achieve desired depth
    eye_tool_center_y = cup_surface_radius_at_eye_height - (eye_tool_base_radius - eye_depth);

    module eye_cutter() {
        // Pill-shaped eye using hull of two spheres for elongation effect
        pill_sphere_radius = eye_tool_base_radius * 0.75; // Radius of spheres forming the pill
        // Calculate offset for pill spheres to achieve desired visual elongation
        pill_offset_x = eye_tool_base_radius * (eye_elongation_factor - 1)/2 * 0.8 + pill_sphere_radius*0.2; // Heuristic offset
        fn_eye_pill_sph = max(12, eye_cutter_fn/2);

        hull(){
            translate([pill_offset_x,0,0]) sphere(r=pill_sphere_radius, $fn=fn_eye_pill_sph);
            translate([-pill_offset_x,0,0]) sphere(r=pill_sphere_radius, $fn=fn_eye_pill_sph);
        }
    }

    // Right Eye (on +Y face, +X offset)
    translate([eye_spacing/2, eye_tool_center_y, eye_actual_z_pos]) {
        eye_cutter();
    }
    // Left Eye (on +Y face, -X offset)
    translate([-eye_spacing/2, eye_tool_center_y, eye_actual_z_pos]) {
        eye_cutter();
    }

    // --- Nose ---
    nose_actual_z_pos = cup_height * nose_z_factor;
    nose_base_cutting_radius = nose_size * 1.1; // Base radius of cutting sphere before stylistic scaling
    cup_surface_radius_at_nose_height = lerp(cup_diameter_bottom/2, cup_diameter_top/2, nose_actual_z_pos / cup_height);

    // Y-position for the center of the cutting sphere.
    // Depth calculation uses the Y-component of the scaled sphere's radius.
    nose_sphere_center_y = cup_surface_radius_at_nose_height - (nose_base_cutting_radius * nose_flatten_factor - nose_depth);

    translate([0, nose_sphere_center_y, nose_actual_z_pos]) {
        // Apply stylistic scaling for a wider, flatter nose impression
        scale([nose_width_factor, nose_flatten_factor, 1.0])
            sphere(r = nose_base_cutting_radius, $fn=nose_cutter_fn);
    }
}

// --- Main Assembly ---
// Combine all parts of the cat cup

difference() {
    union() {
        main_cup_body();
        cat_ears();
        cat_cup_handle();
    }
    if (enable_face) {
        cat_face_indentations();
    }
}
