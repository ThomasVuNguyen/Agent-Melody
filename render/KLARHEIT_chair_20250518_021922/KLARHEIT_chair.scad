// KLARHEIT Dining Chair - IKEA Style - Polished Version

// Overall Dimensions
overall_height = 820; // from floor to top of backrest

// Seat Dimensions
seat_height_from_floor = 450; // To top surface of seat
seat_width_front = 420;
seat_width_back = 390;
seat_depth = 400;
seat_thickness = 10;
seat_waterfall_radius = 20;
seat_concave_depth = 5; // Subtle curve across width

// Backrest Dimensions
backrest_panel_height = 370; // Height of the panel itself
backrest_width = 380;
backrest_thickness = 8;
backrest_concave_depth = 10; // Lumbar curve (horizontal)
backrest_bottom_gap_from_seat = 15; // Gap between seat top and backrest bottom edge
backrest_top_edge_curve_depth = 10; // Depth of the gentle curve on top edge of backrest

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
apron_edge_radius = 2; // Slightly increased for softer look

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
fillet_fn = $fn / 2 > 16 ? $fn / 2 : 16; // Specific $fn for fillets, ensure it's not too low
epsilon = 0.01; // Small value for hulling flat things or overlaps

// Derived Z coordinates for structure
apron_z_bottom = seat_height_from_floor - seat_thickness - apron_height;
apron_z_top = seat_height_from_floor - seat_thickness;

// Apron outer footprint dimensions (center of leg_cross_section_top at apron connection height)
apron_footprint_half_W_front = (seat_width_front - 20 - leg_cross_section_top) / 2;
apron_footprint_half_W_back = (seat_width_back - 20 - leg_cross_section_top) / 2;
apron_footprint_half_D = (seat_depth - 20 - leg_cross_section_top) / 2;


// --- Modules ---

// Rodrigues rotation matrix: returns a matrix that aligns vector u to vector v
function rodrigues_rotation_matrix(u_vec, v_vec) =
    let(u = u_vec / norm(u_vec)) // Normalize u
    let(v = v_vec / norm(v_vec)) // Normalize v
    let(w = cross(u, v))
    norm(w) == 0 ? (u * v < 0 ? [[-1,0,0,0],[0,-1,0,0],[0,0,-1,0],[0,0,0,1]] : diag([1,1,1,1])) : // Check for 180 deg or 0 deg
    let(
        c = u * v, // Cosine of angle (since u,v are normalized)
        K = [[0, -w[2], w[1]], [w[2], 0, -w[0]], [-w[1], w[0], 0]] // Skew-symmetric matrix for w
    ) = [[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]] + K + K*K * ( (1-c) / (norm(w)*norm(w)) );

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
    pt_diff = p_bottom - p_top;
    len = norm(pt_diff);
    if (len > epsilon) {
        translate(p_top)
        multmatrix(rodrigues_rotation_matrix([0,0,1], pt_diff))
            leg_segment(len, size_top, size_bottom, edge_r);
    }
}

module rounded_cube(dims, r, center=false, local_fn=fillet_fn) {
    translate_vec = center ? [0,0,0] : [dims.x/2, dims.y/2, dims.z/2];
    translate(translate_vec) {
        minkowski($fn = local_fn) {
            cube([dims.x-2*r, dims.y-2*r, dims.z-2*r], center=true);
            sphere(r);
        }
    }
}

// --- Chair Assembly ---

// Leg connection points
fr_leg_top_center = [ apron_footprint_half_W_front, -apron_footprint_half_D, apron_z_bottom ];
fr_leg_bottom_center = [ fr_leg_top_center.x + apron_z_bottom * tan(front_leg_splay_outwards),
                         fr_leg_top_center.y, 0 ];
fl_leg_top_center = [ -apron_footprint_half_W_front, -apron_footprint_half_D, apron_z_bottom ];
fl_leg_bottom_center = [ fl_leg_top_center.x - apron_z_bottom * tan(front_leg_splay_outwards),
                         fl_leg_top_center.y, 0 ];
rr_leg_apron_conn_center = [ apron_footprint_half_W_back, apron_footprint_half_D, apron_z_bottom ];
rr_leg_bottom_center = [ rr_leg_apron_conn_center.x + apron_z_bottom * tan(rear_leg_splay_outwards),
                         rr_leg_apron_conn_center.y + apron_z_bottom * tan(rear_leg_splay_backwards), 0 ];
rr_leg_true_top_center = [ rr_leg_apron_conn_center.x + (overall_height - apron_z_bottom) * tan(rear_leg_splay_outwards),
                           rr_leg_apron_conn_center.y + (overall_height - apron_z_bottom) * tan(rear_leg_splay_backwards),
                           overall_height ];
rl_leg_apron_conn_center = [ -apron_footprint_half_W_back, apron_footprint_half_D, apron_z_bottom ];
rl_leg_bottom_center = [ rl_leg_apron_conn_center.x - apron_z_bottom * tan(rear_leg_splay_outwards),
                         rl_leg_apron_conn_center.y + apron_z_bottom * tan(rear_leg_splay_backwards), 0 ];
rl_leg_true_top_center = [ rl_leg_apron_conn_center.x - (overall_height - apron_z_bottom) * tan(rear_leg_splay_outwards),
                           rl_leg_apron_conn_center.y + (overall_height - apron_z_bottom) * tan(rear_leg_splay_backwards),
                           overall_height ];

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
    // Front Apron Rail
    apron_F_len = (fr_leg_top_center.x - leg_cross_section_top/2) - (fl_leg_top_center.x + leg_cross_section_top/2);
    translate([fl_leg_top_center.x + leg_cross_section_top/2, // Inner face of FL leg
               fr_leg_top_center.y + leg_cross_section_top/2, // Rear face of leg's front half-thickness
               apron_z_bottom])
        rounded_cube([apron_F_len, apron_thickness, apron_height], apron_edge_radius);

    // Back Apron Rail
    apron_B_len = (rr_leg_apron_conn_center.x - leg_cross_section_top/2) - (rl_leg_apron_conn_center.x + leg_cross_section_top/2);
    translate([rl_leg_apron_conn_center.x + leg_cross_section_top/2, // Inner face of RL leg
               rr_leg_apron_conn_center.y - leg_cross_section_top/2 - apron_thickness, // Front face of leg's rear half-thickness, offset by apron_thickness
               apron_z_bottom])
        rounded_cube([apron_B_len, apron_thickness, apron_height], apron_edge_radius);

    // Side Apron Rails (using polyhedron with rounded edges via Minkowski)
    // These connect the rear face of front leg to front face of rear leg.
    // X-width of side apron is 'apron_thickness'.
    // Y-length is distance between front leg rear face and rear leg front face.

    module raw_side_apron(is_left_side) {
        sign = is_left_side ? 1 : -1;
        // Front leg interface points (outer X, inner X) for the side apron's front face
        x_f_outer = (is_left_side ? fl_leg_top_center.x : fr_leg_top_center.x) - sign * leg_cross_section_top/2;
        x_f_inner = x_f_outer + sign * apron_thickness;
        y_f = (is_left_side ? fl_leg_top_center.y : fr_leg_top_center.y) + leg_cross_section_top/2;

        // Rear leg interface points for the side apron's rear face
        x_r_outer = (is_left_side ? rl_leg_apron_conn_center.x : rr_leg_apron_conn_center.x) - sign * leg_cross_section_top/2;
        x_r_inner = x_r_outer + sign * apron_thickness;
        y_r = (is_left_side ? rl_leg_apron_conn_center.y : rr_leg_apron_conn_center.y) - leg_cross_section_top/2;

        points = [
            [x_f_outer, y_f, apron_z_bottom], // 0 Front-Bottom-Outer
            [x_f_inner, y_f, apron_z_bottom], // 1 Front-Bottom-Inner
            [x_r_inner, y_r, apron_z_bottom], // 2 Rear-Bottom-Inner
            [x_r_outer, y_r, apron_z_bottom], // 3 Rear-Bottom-Outer
            [x_f_outer, y_f, apron_z_bottom + apron_height], // 4 Front-Top-Outer
            [x_f_inner, y_f, apron_z_bottom + apron_height], // 5 Front-Top-Inner
            [x_r_inner, y_r, apron_z_bottom + apron_height], // 6 Rear-Top-Inner
            [x_r_outer, y_r, apron_z_bottom + apron_height]  // 7 Rear-Top-Outer
        ];
        faces = [
            [0,1,2,3], // Bottom face
            [7,6,5,4], // Top face (reverse order for outward normal)
            [0,4,5,1], // Front face
            [1,5,6,2], // Inner face
            [2,6,7,3], // Rear face
            [3,7,4,0]  // Outer face
        ];
        polyhedron(points = points, faces = faces);
    }

    // Left Side Rail
    minkowski($fn = fillet_fn) {
        raw_side_apron(is_left_side = true);
        sphere(r = apron_edge_radius);
    }
    // Right Side Rail
    minkowski($fn = fillet_fn) {
        raw_side_apron(is_left_side = false);
        sphere(r = apron_edge_radius);
    }
}

// Seat Panel
color(plywood_color) {
    module seat_core() {
        difference() {
            // Base seat shape with integrated waterfall front edge using hull
            hull() {
                // Main seat slab, stopping where the curve of the waterfall begins tangentially
                linear_extrude(height = seat_thickness)
                    polygon([ [-seat_width_front/2, -seat_depth/2 + seat_waterfall_radius],
                              [seat_width_front/2,  -seat_depth/2 + seat_waterfall_radius],
                              [seat_width_back/2,    seat_depth/2],
                              [-seat_width_back/2,   seat_depth/2] ]);
                // Cylinder for waterfall edge
                translate([0, -seat_depth/2 + seat_waterfall_radius, seat_thickness - seat_waterfall_radius]) {
                    rotate([0, 90, 0]) { // Align cylinder along X-axis
                        cylinder(r = seat_waterfall_radius, h = seat_width_front + 2*epsilon, center = true, $fn=max(32, $fn/2));
                    }
                }
            }
            // Concave cut for ergonomic shape (across width)
            seat_concave_R = (pow(seat_width_front,2) / (8*seat_concave_depth)) + (seat_concave_depth/2);
            translate([0, 0, seat_thickness + seat_concave_R - seat_concave_depth]) {
                rotate([0, 90, 0]) { // Rotate cylinder axis to be along global X (cuts U-shape along depth)
                    cylinder(r = seat_concave_R, h = seat_depth + seat_waterfall_radius + 2*epsilon, center = true, $fn=max(64, $fn));
                }
            }
        }
    }
    translate([0, 0, apron_z_top]) {
        if (plywood_global_edge_radius > 0) {
            minkowski($fn=fillet_fn) {
                seat_core();
                sphere(r = plywood_global_edge_radius);
            }
        } else {
            seat_core();
        }
    }
}

// Backrest Panel
color(plywood_color) {
    backrest_center_z = seat_height_from_floor + backrest_bottom_gap_from_seat + backrest_panel_height/2;
    t_param_backrest = (backrest_center_z - rl_leg_apron_conn_center.z) / (rl_leg_true_top_center.z - rl_leg_apron_conn_center.z);
    backrest_leg_axis_pt = rl_leg_apron_conn_center + t_param_backrest * (rl_leg_true_top_center - rl_leg_apron_conn_center);
    y_leg_front_face = backrest_leg_axis_pt.y + (leg_cross_section_top/2) / cos(rear_leg_splay_backwards) * cos(rear_leg_splay_outwards);
    backrest_center_y = y_leg_front_face + (backrest_thickness/2) * cos(rear_leg_splay_backwards);

    module backrest_core() {
        difference() {
            // Base rounded rectangle for backrest
            // Make it slightly taller to cut the top curve
            base_h = backrest_panel_height + (backrest_top_edge_curve_depth > 0 ? plywood_global_edge_radius*2 : 0) ;
            rounded_cube([backrest_width, backrest_thickness, base_h],
                         plywood_global_edge_radius > 0 ? plywood_global_edge_radius : apron_edge_radius, // Use global or fallback
                         center=true, local_fn=fillet_fn);

            // Horizontal concave cut (lumbar support)
            backrest_concave_R = (pow(backrest_width,2)/(8*backrest_concave_depth)) + (backrest_concave_depth/2);
            translate([0, -backrest_thickness/2 - backrest_concave_R + backrest_concave_depth, 0]) {
                 rotate([0,0,90]) { // Cylinder axis along current Y of backrest
                    cylinder(r=backrest_concave_R, h=backrest_panel_height + 2*epsilon, center=true, $fn=max(64,$fn));
                 }
            }

            // Gentle curve on top edge
            if (backrest_top_edge_curve_depth > 0) {
                top_curve_R = (pow(backrest_width, 2) / (8 * backrest_top_edge_curve_depth)) + (backrest_top_edge_curve_depth / 2);
                translate([0, 0, (base_h)/2 + top_curve_R - backrest_top_edge_curve_depth])
                rotate([90,0,0]) // Cylinder axis along Y
                    cylinder(r=top_curve_R, h=backrest_thickness + 2*epsilon, center=true, $fn=max(64,$fn));
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
    glide_at(fr_leg_bottom_center);
    glide_at(fl_leg_bottom_center);
    glide_at(rr_leg_bottom_center);
    glide_at(rl_leg_bottom_center);
}

// End of KLARHEIT chair model - Polished
