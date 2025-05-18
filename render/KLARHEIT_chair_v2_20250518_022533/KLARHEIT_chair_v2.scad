// KLARHEIT Dining Chair - IKEA Style - Polished Version 2.0

// Overall Dimensions
overall_height = 820; // from floor to top of backrest

// Seat Dimensions
seat_height_from_floor = 450; // To top surface of seat
seat_width_front = 420;
seat_width_back = 390;
seat_depth = 400;
seat_thickness = 10;
seat_waterfall_radius = 20;
seat_concave_depth = 5; // Subtle curve across width of seat

// Backrest Dimensions
backrest_panel_height = 370; // Height of the panel itself (at centerline)
backrest_width = 380; // Width at the widest point (middle of panel height)
backrest_thickness = 8;
backrest_lumbar_concave_depth = 10; // Lumbar curve (horizontal across width)
backrest_top_edge_curve_depth = 10; // Depth of the gentle curve on top edge of backrest
backrest_profile_taper_amount = 30; // Total width reduction at top/bottom edges from widest point
backrest_bottom_gap_from_seat = 15; // Gap between seat top and backrest bottom edge

// Leg Dimensions
leg_cross_section_top = 35; // At apron connection
leg_cross_section_bottom = 28; // At floor
leg_edge_radius = 3;
front_leg_splay_outwards = 4; // degrees
rear_leg_splay_outwards = 4; // degrees
rear_leg_splay_backwards = 9; // degrees (this also acts as backrest rake)

// Apron Dimensions
apron_height = 50;
apron_thickness = 20; // This is Y-thickness for front/back, X-thickness for side aprons
apron_edge_radius = 2;

// Plywood edge rounding
plywood_global_edge_radius = 1.5; // For seat and backrest outer edges

// Feet Glides
glide_diameter = 15;
glide_thickness = 3;

// Material Look (colors)
wood_color = "Tan"; // Birch-like
plywood_color = "LightGoldenrod"; // Plywood seat/backrest
glide_color = [0.9, 0.9, 0.9, 1.0]; // Off-white/transparent

// Helper variables
$fn_default = $fn; // Preserve user's $fn if set
$fn = ($fn_default != 0) ? $fn_default : 64; // Higher default for smoother curves overall
fillet_fn = $fn / 2 > 16 ? $fn / 2 : 16; // Specific $fn for fillets
epsilon = 0.01;

// Derived Z coordinates for structure
apron_z_bottom = seat_height_from_floor - seat_thickness - apron_height;
apron_z_top = seat_height_from_floor - seat_thickness;

// Apron outer footprint dimensions
apron_footprint_half_W_front = (seat_width_front - 20 - leg_cross_section_top) / 2;
apron_footprint_half_W_back = (seat_width_back - 20 - leg_cross_section_top) / 2;
apron_footprint_half_D = (seat_depth - 20 - leg_cross_section_top) / 2;


// --- Modules ---

function rodrigues_rotation_matrix(u_vec, v_vec) =
    let(u = u_vec / norm(u_vec), v = v_vec / norm(v_vec), w = cross(u, v))
    norm(w) == 0 ? (u * v < 0 ? [[-1,0,0,0],[0,-1,0,0],[0,0,-1,0],[0,0,0,1]] : diag([1,1,1,1])) :
    let(c = u * v, K = [[0, -w[2], w[1]], [w[2], 0, -w[0]], [-w[1], w[0], 0]])
    = [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]] + K + K*K * ( (1-c) / (norm(w)*norm(w)) );

module rounded_square_profile(size_x, size_y, r) {
    minkowski($fn = fillet_fn) {
        square([size_x - 2*r, size_y - 2*r], center=true);
        circle(r=r);
    }
}

module leg_segment(length, top_xy_size, bottom_xy_size, edge_r) {
    hull() {
        translate([0,0,epsilon/2]) linear_extrude(height=epsilon, center=true)
            rounded_square_profile(bottom_xy_size, bottom_xy_size, edge_r);
        translate([0,0,length - epsilon/2]) linear_extrude(height=epsilon, center=true)
            rounded_square_profile(top_xy_size, top_xy_size, edge_r);
    }
}

module oriented_leg_part(p_top, p_bottom, size_top, size_bottom, edge_r) {
    pt_diff = p_bottom - p_top; len = norm(pt_diff);
    if (len > epsilon) {
        translate(p_top) multmatrix(rodrigues_rotation_matrix([0,0,1], pt_diff))
            leg_segment(len, size_top, size_bottom, edge_r);
    }
}

module rounded_cube(dims, r, center=false, local_fn=fillet_fn) {
    translate_vec = center ? [0,0,0] : [dims.x/2, dims.y/2, dims.z/2];
    translate(translate_vec) minkowski($fn = local_fn) {
        cube([dims.x-2*r, dims.y-2*r, dims.z-2*r], center=true);
        sphere(r=r);
    }
}

// --- Chair Assembly ---

// Leg connection points
fr_leg_top_center = [ apron_footprint_half_W_front, -apron_footprint_half_D, apron_z_bottom ];
fr_leg_bottom_center = [ fr_leg_top_center.x + apron_z_bottom * tan(front_leg_splay_outwards), fr_leg_top_center.y, 0 ];
fl_leg_top_center = [ -apron_footprint_half_W_front, -apron_footprint_half_D, apron_z_bottom ];
fl_leg_bottom_center = [ fl_leg_top_center.x - apron_z_bottom * tan(front_leg_splay_outwards), fl_leg_top_center.y, 0 ];
rr_leg_apron_conn_center = [ apron_footprint_half_W_back, apron_footprint_half_D, apron_z_bottom ];
rr_leg_bottom_center = [ rr_leg_apron_conn_center.x + apron_z_bottom * tan(rear_leg_splay_outwards),
                         rr_leg_apron_conn_center.y + apron_z_bottom * tan(rear_leg_splay_backwards), 0 ];
rr_leg_true_top_center = [ rr_leg_apron_conn_center.x + (overall_height - apron_z_bottom) * tan(rear_leg_splay_outwards),
                           rr_leg_apron_conn_center.y + (overall_height - apron_z_bottom) * tan(rear_leg_splay_backwards), overall_height ];
rl_leg_apron_conn_center = [ -apron_footprint_half_W_back, apron_footprint_half_D, apron_z_bottom ];
rl_leg_bottom_center = [ rl_leg_apron_conn_center.x - apron_z_bottom * tan(rear_leg_splay_outwards),
                         rl_leg_apron_conn_center.y + apron_z_bottom * tan(rear_leg_splay_backwards), 0 ];
rl_leg_true_top_center = [ rl_leg_apron_conn_center.x - (overall_height - apron_z_bottom) * tan(rear_leg_splay_outwards),
                           rl_leg_apron_conn_center.y + (overall_height - apron_z_bottom) * tan(rear_leg_splay_backwards), overall_height ];

// Assemble Legs
color(wood_color) {
    oriented_leg_part(fr_leg_top_center, fr_leg_bottom_center, leg_cross_section_top, leg_cross_section_bottom, leg_edge_radius);
    oriented_leg_part(fl_leg_top_center, fl_leg_bottom_center, leg_cross_section_top, leg_cross_section_bottom, leg_edge_radius);
    oriented_leg_part(rr_leg_apron_conn_center, rr_leg_bottom_center, leg_cross_section_top, leg_cross_section_bottom, leg_edge_radius);
    oriented_leg_part(rl_leg_apron_conn_center, rl_leg_bottom_center, leg_cross_section_top, leg_cross_section_bottom, leg_edge_radius);
    oriented_leg_part(rr_leg_apron_conn_center, rr_leg_true_top_center, leg_cross_section_top, leg_cross_section_top, leg_edge_radius);
    oriented_leg_part(rl_leg_apron_conn_center, rl_leg_true_top_center, leg_cross_section_top, leg_cross_section_top, leg_edge_radius);
}

// Apron Rails
color(wood_color) {
    apron_F_len = (fr_leg_top_center.x - leg_cross_section_top/2) - (fl_leg_top_center.x + leg_cross_section_top/2);
    translate([fl_leg_top_center.x + leg_cross_section_top/2, fr_leg_top_center.y + leg_cross_section_top/2, apron_z_bottom])
        rounded_cube([apron_F_len, apron_thickness, apron_height], apron_edge_radius);

    apron_B_len = (rr_leg_apron_conn_center.x - leg_cross_section_top/2) - (rl_leg_apron_conn_center.x + leg_cross_section_top/2);
    translate([rl_leg_apron_conn_center.x + leg_cross_section_top/2, rr_leg_apron_conn_center.y - leg_cross_section_top/2 - apron_thickness, apron_z_bottom])
        rounded_cube([apron_B_len, apron_thickness, apron_height], apron_edge_radius);

    module raw_side_apron(is_left_side) {
        sign = is_left_side ? 1 : -1;
        x_f_outer = (is_left_side ? fl_leg_top_center.x : fr_leg_top_center.x) - sign * leg_cross_section_top/2;
        x_f_inner = x_f_outer + sign * apron_thickness;
        y_f = (is_left_side ? fl_leg_top_center.y : fr_leg_top_center.y) + leg_cross_section_top/2;
        x_r_outer = (is_left_side ? rl_leg_apron_conn_center.x : rr_leg_apron_conn_center.x) - sign * leg_cross_section_top/2;
        x_r_inner = x_r_outer + sign * apron_thickness;
        y_r = (is_left_side ? rl_leg_apron_conn_center.y : rr_leg_apron_conn_center.y) - leg_cross_section_top/2;
        points = [
            [x_f_outer, y_f, apron_z_bottom], [x_f_inner, y_f, apron_z_bottom], [x_r_inner, y_r, apron_z_bottom], [x_r_outer, y_r, apron_z_bottom],
            [x_f_outer, y_f, apron_z_bottom + apron_height], [x_f_inner, y_f, apron_z_bottom + apron_height],
            [x_r_inner, y_r, apron_z_bottom + apron_height], [x_r_outer, y_r, apron_z_bottom + apron_height] ];
        faces = [ [0,1,2,3], [7,6,5,4], [0,4,5,1], [1,5,6,2], [2,6,7,3], [3,7,4,0] ];
        polyhedron(points = points, faces = faces);
    }
    minkowski($fn = fillet_fn) { raw_side_apron(is_left_side = true); sphere(r = apron_edge_radius); }
    minkowski($fn = fillet_fn) { raw_side_apron(is_left_side = false); sphere(r = apron_edge_radius); }
}

// Seat Panel
color(plywood_color) {
    module seat_core() {
        difference() {
            hull() {
                linear_extrude(height = seat_thickness)
                    polygon([ [-seat_width_front/2, -seat_depth/2 + seat_waterfall_radius], [seat_width_front/2,  -seat_depth/2 + seat_waterfall_radius],
                              [seat_width_back/2, seat_depth/2], [-seat_width_back/2, seat_depth/2] ]);
                translate([0, -seat_depth/2 + seat_waterfall_radius, seat_thickness - seat_waterfall_radius])
                    rotate([0, 90, 0]) cylinder(r = seat_waterfall_radius, h = seat_width_front + 2*epsilon, center = true, $fn=max(32, $fn/2));
            }
            seat_concave_R = (pow(seat_width_front,2) / (8*seat_concave_depth)) + (seat_concave_depth/2);
            translate([0, 0, seat_thickness + seat_concave_R - seat_concave_depth])
                rotate([0, 90, 0]) cylinder(r = seat_concave_R, h = seat_depth + seat_waterfall_radius + 2*epsilon, center = true, $fn=max(64, $fn));
        }
    }
    translate([0, 0, apron_z_top]) {
        if (plywood_global_edge_radius > 0) minkowski($fn=fillet_fn) { seat_core(); sphere(r = plywood_global_edge_radius); }
        else seat_core();
    }
}

// Backrest Panel
color(plywood_color) {
    backrest_center_z = seat_height_from_floor + backrest_bottom_gap_from_seat + backrest_panel_height/2;
    t_param_backrest = (backrest_center_z - rl_leg_apron_conn_center.z) / (rl_leg_true_top_center.z - rl_leg_apron_conn_center.z);
    backrest_leg_axis_pt = rl_leg_apron_conn_center + t_param_backrest * (rl_leg_true_top_center - rl_leg_apron_conn_center);
    y_leg_front_face = backrest_leg_axis_pt.y + (leg_cross_section_top/2) / cos(rear_leg_splay_backwards) * cos(rear_leg_splay_outwards);
    backrest_center_y = y_leg_front_face + (backrest_thickness/2) * cos(rear_leg_splay_backwards); // Positions center of backrest thickness

    module backrest_xz_profile(bw_mid, bw_t_b, bh_panel) {
        points = [ [bw_t_b/2, -bh_panel/2], [bw_mid/2, 0], [bw_t_b/2, bh_panel/2],
                   [-bw_t_b/2, bh_panel/2], [-bw_mid/2, 0], [-bw_t_b/2, -bh_panel/2] ];
        polygon(points);
    }

    module backrest_core() {
        backrest_width_at_ends = backrest_width - backrest_profile_taper_amount;
        actual_plywood_radius = plywood_global_edge_radius > 0 ? plywood_global_edge_radius : 0;

        difference() {
            // Main body: tapered profile extruded along Y (thickness), then all edges rounded by minkowski sum
            minkowski($fn=fillet_fn) {
                linear_extrude(height = backrest_thickness, center=true) // Extrudes along Y-axis
                    backrest_xz_profile(backrest_width, backrest_width_at_ends, backrest_panel_height);
                if (actual_plywood_radius > 0) sphere(r = actual_plywood_radius); else sphere(r=epsilon/2); // sphere(0) can be an issue
            }

            // Horizontal lumbar concave cut (into front face: local -Y)
            // Cylinder axis is vertical (along Z of the panel).
            if (backrest_lumbar_concave_depth > 0) {
                lumbar_R = (pow(backrest_width,2)/(8*backrest_lumbar_concave_depth)) + (backrest_lumbar_concave_depth/2);
                // Front surface of minkowski sum is at y = -(backrest_thickness/2 + actual_plywood_radius)
                y_lumbar_cut_center = -(backrest_thickness/2 + actual_plywood_radius) + lumbar_R - backrest_lumbar_concave_depth;
                translate([0, y_lumbar_cut_center, 0]) {
                    cylinder(r=lumbar_R, h=backrest_panel_height + 2*actual_plywood_radius + 2*epsilon, center=true, $fn=max(64,$fn));
                }
            }

            // Gentle curve on top edge (cut into top face: local +Z)
            // Cylinder axis is horizontal (along Y of the panel).
            if (backrest_top_edge_curve_depth > 0) {
                top_curve_R = (pow(backrest_width_at_ends, 2) / (8 * backrest_top_edge_curve_depth)) + (backrest_top_edge_curve_depth / 2); // Use width at top for more natural curve
                // Top surface of minkowski sum is at z = backrest_panel_height/2 + actual_plywood_radius
                z_top_cut_center = (backrest_panel_height/2 + actual_plywood_radius) + top_curve_R - backrest_top_edge_curve_depth;
                translate([0, 0, z_top_cut_center])
                rotate([90,0,0]) // Cylinder axis along Y
                    cylinder(r=top_curve_R, h=backrest_thickness + 2*actual_plywood_radius + 2*epsilon, center=true, $fn=max(64,$fn));
            }
        }
    }

    translate([0, backrest_center_y, backrest_center_z]) {
        rotate([rear_leg_splay_backwards, 0, 0]) { // Tilt with leg rake
            backrest_core();
        }
    }
}

// Feet Glides
color(glide_color) {
    module glide_at(pos) {
        translate(pos + [0,0,glide_thickness/2]) cylinder(d=glide_diameter, h=glide_thickness, center=true, $fn=max(16, fillet_fn));
    }
    glide_at(fr_leg_bottom_center); glide_at(fl_leg_bottom_center);
    glide_at(rr_leg_bottom_center); glide_at(rl_leg_bottom_center);
}

// End of KLARHEIT chair model - Polished 2.0
