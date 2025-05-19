// Cat Cup Design - Final Polish
// Focus: Final subtle aesthetic refinements for visual appeal and smoothness, maintaining perfected manufacturability.

// Global smoothness - can be increased for final render
$fn = 75;

// --- Parameters ---

// Cup dimensions
cup_height = 80;
cup_diameter_bottom = 60;
cup_diameter_top = 70;
cup_wall_thickness = 3.5;
cup_base_thickness = 5;

// Fillet and rounding parameters for the cup body
cup_lip_rounding_factor = 0.45;
cup_inner_base_fillet_radius = 3.0; // Increased from 2.5 for a softer inner corner
cup_outer_base_fillet_radius = 2.0; // Increased from 1.5 for a softer outer base transition

// Ear dimensions and style
ear_height = 24;
ear_width_base = 22;
ear_thickness_factor = 1.6;
ear_angle_offset = 25;
ear_minkowski_rounding_factor = 0.2;
ear_scoop_enabled = true;
ear_scoop_depth_factor = 0.55;
ear_scoop_cutter_top_scale = 0.75; // Scales top of scoop cutter for angled walls
// New: Ear profile factors for subtle shape adjustment before Minkowski rounding
ear_profile_base_circ_radius_factor = 0.23; // Factor of ear_width_base for base hull circles (was effectively 0.25)
ear_profile_tip_circ_radius_factor = 0.10;  // Factor of ear_width_base for tip hull circle (was effectively 0.12)

// Handle dimensions and style (Parameters from optimally printable version)
handle_sph_radius = 5.5;
handle_attach_sph_factor = 1.3;
handle_loop_protrusion = 22;
handle_attach_spread = 38;
handle_z_center_factor = 0.55;
handle_embed_factor = 0.4;
handle_support_protrusion_factor = 0.70;
handle_support_z_offset_factor = 0.85;
handle_support_radius_factor = 0.75;
handle_apex_z_nudge_factor = -0.2;

// Face feature parameters
enable_face = true;
eye_radius = 3.8;
eye_depth = 1.8;
eye_spacing = 19;
eye_z_factor = 0.70;
eye_elongation_factor = 1.4;
eye_cutter_fn = 24;
eye_indent_edge_rounding = 0.3;

nose_size = 4.5;
nose_depth = 1.6;
nose_z_factor = 0.62;
nose_width_factor = 1.15;
nose_flatten_factor = 0.85;
nose_cutter_fn = 20;
nose_indent_edge_rounding = 0.3;

// --- Helper Functions ---
function lerp(a, b, t) = a + (b - a) * t;

// --- Modules ---

// Module for the main cup body
module main_cup_body() {
    lip_radius = cup_wall_thickness * cup_lip_rounding_factor;
    fn_torus = max(24, $fn/2);

    difference() {
        union() {
            cylinder(h = cup_height - lip_radius,
                     r1 = cup_diameter_bottom/2,
                     r2 = cup_diameter_top/2 - lip_radius, $fn=$fn);
            translate([0,0,cup_height - lip_radius])
                rotate_extrude(convexity=10, $fn=fn_torus)
                    translate([cup_diameter_top/2 - lip_radius, 0,0])
                        circle(r=lip_radius);
            if (cup_outer_base_fillet_radius > 0) {
                 translate([0,0,cup_outer_base_fillet_radius])
                    rotate_extrude(convexity=10, $fn=fn_torus)
                        translate([cup_diameter_bottom/2 - cup_outer_base_fillet_radius, 0, 0])
                            circle(r = cup_outer_base_fillet_radius);
            }
        }
        union() {
            translate([0, 0, cup_base_thickness])
                cylinder(h = cup_height - cup_base_thickness - lip_radius + 0.2,
                         r1 = (cup_diameter_bottom/2) - cup_wall_thickness,
                         r2 = (cup_diameter_top/2) - cup_wall_thickness + lip_radius,
                         $fn=$fn);
            translate([0,0,cup_height - lip_radius])
                rotate_extrude(convexity=10, $fn=fn_torus)
                    translate([(cup_diameter_top/2 - cup_wall_thickness) + lip_radius, 0,0])
                        circle(r=lip_radius);
        }
    }
    if (cup_inner_base_fillet_radius > 0) {
        translate([0,0, cup_base_thickness + cup_inner_base_fillet_radius]) {
             rotate_extrude(convexity=10, $fn=fn_torus)
                translate([(cup_diameter_bottom/2 - cup_wall_thickness) + cup_inner_base_fillet_radius, 0,0])
                    circle(r=cup_inner_base_fillet_radius);
        }
    }
}

// Module for a single cat ear primitive with subtly adjusted profile
module cat_ear_primitive() {
    actual_ear_thickness = cup_wall_thickness * ear_thickness_factor;
    ear_rounding_radius = actual_ear_thickness * ear_minkowski_rounding_factor;
    fn_ear_profile = max(16, $fn/4);
    fn_minkowski_sph = max(10, $fn/6);

    // Radii for hull circles based on new profile factors
    ear_base_hull_radius = ear_width_base * ear_profile_base_circ_radius_factor;
    ear_tip_hull_radius  = ear_width_base * ear_profile_tip_circ_radius_factor;

    module ear_core_extrude() {
        linear_extrude(height = actual_ear_thickness * (1 - 2*ear_minkowski_rounding_factor), center = true) {
             hull() { // Slightly sleeker 2D profile for the ear
                translate([-ear_width_base/2 * 0.7, ear_height * 0.05]) circle(r = ear_base_hull_radius, $fn=fn_ear_profile);
                translate([ ear_width_base/2 * 0.7, ear_height * 0.05]) circle(r = ear_base_hull_radius, $fn=fn_ear_profile);
                translate([0, ear_height]) circle(r = ear_tip_hull_radius, $fn=fn_ear_profile);
            }
        }
    }

    difference() {
        minkowski($fn=fn_minkowski_sph) {
            ear_core_extrude();
            sphere(r = ear_rounding_radius, $fn=fn_minkowski_sph);
        }
        if (ear_scoop_enabled) {
            ear_scoop_visual_depth = actual_ear_thickness * ear_scoop_depth_factor;
            ear_scoop_inset = ear_rounding_radius + actual_ear_thickness * 0.05;
            ear_scoop_scale_xy = 0.65;
            fn_scoop_profile = max(12, $fn/5);

            translate([0, ear_height * 0.1, ear_scoop_inset]) {
                scale([ear_scoop_scale_xy, ear_scoop_scale_xy, 1]) {
                     linear_extrude(height = ear_scoop_visual_depth, center=true, scale = ear_scoop_cutter_top_scale) {
                        translate([0, ear_height * (1-ear_scoop_scale_xy)/2 + ear_height * 0.02, 0])
                             hull() {
                                translate([-ear_width_base/2*0.7*0.9, ear_height*0.05]) circle(r = ear_width_base*0.25*ear_scoop_scale_xy, $fn=fn_scoop_profile); // Inner scoop profile kept same
                                translate([ ear_width_base/2*0.7*0.9, ear_height*0.05]) circle(r = ear_width_base*0.25*ear_scoop_scale_xy, $fn=fn_scoop_profile);
                                translate([0, ear_height]) circle(r = ear_width_base*0.12*ear_scoop_scale_xy*0.7, $fn=fn_scoop_profile);
                            }
                    }
                }
            }
        }
    }
}

// Module to create and position both cat ears
module cat_ears() {
    ear_placement_radius_on_cup = cup_diameter_top/2;
    angle_R_global = 90 - ear_angle_offset;
    rotate([0,0, angle_R_global]) {
        translate([ear_placement_radius_on_cup, 0, cup_height]) {
            rotate([90,0,0]) { rotate([0,90,0]) { cat_ear_primitive(); } }
        }
    }
    angle_L_global = 90 + ear_angle_offset;
    rotate([0,0, angle_L_global]) {
        translate([ear_placement_radius_on_cup, 0, cup_height]) {
            rotate([90,0,0]) { rotate([0,90,0]) { cat_ear_primitive(); } }
        }
    }
}

// Module for the refined cup handle with maximally reduced overhangs
module cat_cup_handle() {
    handle_center_z_abs = cup_height * handle_z_center_factor;
    avg_cup_radius_at_handle_height = lerp(cup_diameter_bottom/2, cup_diameter_top/2, handle_center_z_abs / cup_height);
    fn_handle_sph = max(20, $fn/2.5);

    attach_sph_r = handle_sph_radius * handle_attach_sph_factor;
    attach_y_offset = -(avg_cup_radius_at_handle_height - attach_sph_r * (1-handle_embed_factor));

    p_attach_top    = [0, attach_y_offset, handle_center_z_abs + handle_attach_spread/2];
    p_attach_bottom = [0, attach_y_offset, handle_center_z_abs - handle_attach_spread/2];

    apex_y = -(avg_cup_radius_at_handle_height + handle_loop_protrusion);
    apex_z = handle_center_z_abs + (handle_sph_radius * handle_apex_z_nudge_factor);
    p_apex = [0, apex_y, apex_z];
    apex_sph_r = handle_sph_radius;

    support_y = -(avg_cup_radius_at_handle_height + handle_loop_protrusion * handle_support_protrusion_factor);
    support_z = apex_z - (handle_sph_radius * handle_support_z_offset_factor);
    p_support = [0, support_y, support_z];
    support_sph_r = handle_sph_radius * handle_support_radius_factor;

    hull() {
        translate(p_attach_top) sphere(r=attach_sph_r, $fn=fn_handle_sph);
        translate(p_apex) sphere(r=apex_sph_r, $fn=fn_handle_sph);
    }
    hull() {
        translate(p_apex) sphere(r=apex_sph_r, $fn=fn_handle_sph);
        translate(p_support) sphere(r=support_sph_r, $fn=fn_handle_sph);
    }
    hull() {
        translate(p_support) sphere(r=support_sph_r, $fn=fn_handle_sph);
        translate(p_attach_bottom) sphere(r=attach_sph_r, $fn=fn_handle_sph);
    }

    reinforce_sph_r = attach_sph_r * 0.9;
    hull() {
        translate(p_attach_top) sphere(r=reinforce_sph_r, $fn=fn_handle_sph);
        translate(p_attach_bottom) sphere(r=reinforce_sph_r, $fn=fn_handle_sph);
    }
}

// Module for face features with softened indentation edges
module cat_face_indentations() {
    // --- Eyes ---
    eye_actual_z_pos = cup_height * eye_z_factor;
    cup_surface_radius_at_eye_height = lerp(cup_diameter_bottom/2, cup_diameter_top/2, eye_actual_z_pos / cup_height);
    eye_tool_base_radius = eye_radius * 1.2;
    eye_tool_center_y = cup_surface_radius_at_eye_height - (eye_tool_base_radius - eye_depth);
    // Increased $fn for smoother Minkowski rounding on face features
    fn_minkowski_face_sph = max(12, $fn/6);

    module eye_cutter_raw() {
        pill_sphere_radius = eye_tool_base_radius * 0.75;
        pill_offset_x = eye_tool_base_radius * (eye_elongation_factor - 1)/2 * 0.8 + pill_sphere_radius*0.2;
        fn_eye_pill_sph = max(12, eye_cutter_fn/2);
        hull(){
            translate([pill_offset_x,0,0]) sphere(r=pill_sphere_radius, $fn=fn_eye_pill_sph);
            translate([-pill_offset_x,0,0]) sphere(r=pill_sphere_radius, $fn=fn_eye_pill_sph);
        }
    }
    module eye_cutter_soft() {
        if (eye_indent_edge_rounding > 0.001) {
            minkowski($fn=fn_minkowski_face_sph) {
                eye_cutter_raw();
                sphere(r=eye_indent_edge_rounding, $fn=fn_minkowski_face_sph);
            }
        } else {
            eye_cutter_raw();
        }
    }
    translate([eye_spacing/2, eye_tool_center_y, eye_actual_z_pos]) eye_cutter_soft();
    translate([-eye_spacing/2, eye_tool_center_y, eye_actual_z_pos]) eye_cutter_soft();

    // --- Nose ---
    nose_actual_z_pos = cup_height * nose_z_factor;
    nose_base_cutting_radius = nose_size * 1.1;
    cup_surface_radius_at_nose_height = lerp(cup_diameter_bottom/2, cup_diameter_top/2, nose_actual_z_pos / cup_height);
    nose_sphere_center_y = cup_surface_radius_at_nose_height - (nose_base_cutting_radius * nose_flatten_factor - nose_depth);

    module nose_cutter_raw() {
        scale([nose_width_factor, nose_flatten_factor, 1.0])
            sphere(r = nose_base_cutting_radius, $fn=nose_cutter_fn);
    }
    module nose_cutter_soft() {
         if (nose_indent_edge_rounding > 0.001) {
            minkowski($fn=fn_minkowski_face_sph) { // Using the higher $fn here too
                nose_cutter_raw();
                sphere(r=nose_indent_edge_rounding, $fn=fn_minkowski_face_sph);
            }
        } else {
            nose_cutter_raw();
        }
    }
    translate([0, nose_sphere_center_y, nose_actual_z_pos]) nose_cutter_soft();
}

// --- Main Assembly ---
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
