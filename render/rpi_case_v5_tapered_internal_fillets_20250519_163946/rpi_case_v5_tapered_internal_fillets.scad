// Raspberry Pi 4 Minimal Case - Polished Version v5 (Tapered Walls, Enhanced Internal Fillets)
// Original by: cad_engineer
// Polished by: polish_agent (Iteration 5)

// --- Rendering Quality ---
$fn = 60; // Global fragments for curves

// --- Raspberry Pi 4B Board Dimensions ---
board_x_dim = 85;
board_y_dim = 56;

// --- Core Case Design Parameters ---
case_floor_thickness = 2.0;
wall_t_at_base = 1.5;                 // Wall thickness defined at the base of the case
standoff_height_from_floor = 7.0;
pcb_to_wall_clearance = 0.5;
outer_taper_angle = 1.5;              // Angle for tapering outer walls inwards towards top (degrees)

// --- Corrected Wall Height ---
// Tallest port (USB/Eth) cutout height is 15.2mm (body) + 0.6mm (margin) = 15.8mm.
// PCB bottom is standoff_height_from_floor (7mm) + case_floor_thickness (2mm) = 9mm from case Z=0.
// Top of tallest cutout is 9mm + 15.8mm = 24.8mm from case Z=0.
// wall_height_above_floor is height of inner cavity from case inner floor.
// To clear ports, inner cavity top must be >= 24.8mm - case_floor_thickness.
// Let's ensure a bit of wall material above the tallest cutout.
// If case top edge is at 25mm, then wall_height_above_floor = 25mm - case_floor_thickness = 23mm.
wall_height_above_floor = 23.0;

// --- Standoff Parameters ---
standoff_outer_dia = 6.0;
screw_hole_dia = 2.7;
screw_head_dia = 5.0;
screw_head_h = 1.5;

// --- Port Cutout Margin ---
port_margin = 0.6;

// --- Aesthetic Improvement Parameters ---
fillet_r_outer = 2.5;                 // Fillet radius for main case outer edges (applied by tapered block module)
fillet_r_inner_cavity = 1.5;          // Fillet for inner cavity edges, including floor-to-wall (increased for smoother transition)
standoff_top_fillet_r = 0.6;
port_cutout_fillet_r = 0.8;
sd_port_cutout_fillet_r = 0.4;

// --- Base Recess Parameters ---
base_recess_depth = 0.8;
base_recess_margin = 3.0;
base_recess_fillet_r = 1.5;

// --- Ventilation Parameters ---
add_ventilation = true;
vent_slot_length = 20;
vent_slot_width = 3.5;
vent_rows = 3;
vent_cols = 2;
vent_area_margin_to_standoffs = 4;

// --- Calculated Case Dimensions ---
// Dimensions at the base of the case
outer_x_at_base = board_x_dim + 2 * pcb_to_wall_clearance + 2 * wall_t_at_base;
outer_y_at_base = board_y_dim + 2 * pcb_to_wall_clearance + 2 * wall_t_at_base;
outer_z = case_floor_thickness + wall_height_above_floor; // Total height of the case

// Dimensions at the top of the case due to taper
taper_offset_at_top_per_side = outer_z * tan(outer_taper_angle);
outer_x_at_top = outer_x_at_base - 2 * taper_offset_at_top_per_side;
outer_y_at_top = outer_y_at_base - 2 * taper_offset_at_top_per_side;

// Wall thickness at the top (for reference, must be > 0)
wall_t_at_top = wall_t_at_base - taper_offset_at_top_per_side;
// Assert(wall_t_at_top > 0.5, str("Wall thickness at top too thin: ", wall_t_at_top));

// PCB origin inside the case
pcb_origin_x_incase = wall_t_at_base + pcb_to_wall_clearance; // Inner cavity is straight
pcb_origin_y_incase = wall_t_at_base + pcb_to_wall_clearance;
pcb_bottom_z_abs = case_floor_thickness + standoff_height_from_floor;

// --- Raspberry Pi Mounting Holes Data ---
rpi_mount_holes_coords = [
    [3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]
];


// --- Helper Module: Minkowski Rounded Cube (for straight-walled rounded objects) ---
module rounded_cube(size, radius) {
    primitive_cube_size = [
        max(0.01, size[0] - 2*radius),
        max(0.01, size[1] - 2*radius),
        max(0.01, size[2] - 2*radius)
    ];
    translate([radius, radius, radius]) {
        minkowski() {
            cube(primitive_cube_size);
            sphere(r = radius);
        }
    }
}

// --- Helper Module: Tapered Block Primitive (for Minkowski sum) ---
module tapered_block_primitive(size_base, size_top, height) {
    // Ensure scaling factors are robust if a base dimension is very small or zero
    scale_x = (size_base[0] > 0.001) ? size_top[0]/size_base[0] : (size_top[0] > 0.001 ? 1000 : 1);
    scale_y = (size_base[1] > 0.001) ? size_top[1]/size_base[1] : (size_top[1] > 0.001 ? 1000 : 1);
    
    actual_size_base = [max(0.01, size_base[0]), max(0.01, size_base[1])];

    translate([actual_size_base[0]/2, actual_size_base[1]/2, 0]) // Center the origin for linear_extrude's base
        linear_extrude(height = height, scale = [scale_x, scale_y])
            square(actual_size_base, center=true);
}

// --- Helper Module: Minkowski Rounded Tapered Block ---
module minkowski_rounded_tapered_block(size_base, size_top, height, radius) {
    primitive_h = height - 2*radius;
    primitive_size_base = [size_base[0] - 2*radius, size_base[1] - 2*radius];
    primitive_size_top = [size_top[0] - 2*radius, size_top[1] - 2*radius];

    // Ensure all primitive dimensions are positive
    primitive_size_base = [max(0.01, primitive_size_base[0]), max(0.01, primitive_size_base[1])];
    primitive_size_top = [max(0.01, primitive_size_top[0]), max(0.01, primitive_size_top[1])];
    primitive_h = max(0.01, primitive_h);
    
    translate([radius, radius, radius]) { // Offset by radius for Minkowski sum result
        minkowski() {
            tapered_block_primitive(primitive_size_base, primitive_size_top, primitive_h);
            sphere(r = radius);
        }
    }
}

// --- Helper Module: Standoff with Filleted Top Edge ---
module standoff_filleted(height, outer_r, fillet_r) {
    union() {
        cylinder(h = height - fillet_r, r = outer_r);
        translate([0, 0, height - fillet_r]) {
            rotate_extrude(convexity = 10) {
                translate([outer_r - fillet_r, 0, 0]) {
                    circle(r = fillet_r);
                }
            }
        }
    }
}

// --- Helper Module for Countersunk Screw Holes ---
module bottom_countersunk_hole(total_hole_depth, hole_radius, head_recess_radius, head_recess_depth) {
    translate([0, 0, head_recess_depth - 0.01]) 
        cylinder(h = total_hole_depth - head_recess_depth + 0.02, r = hole_radius);
    translate([0, 0, -0.01]) 
        cylinder(h = head_recess_depth + 0.01, r = head_recess_radius);
}

// --- Helper module for ventilation pattern ---
module ventilation_pattern_subtractions() {
    if (add_ventilation && vent_cols > 0 && vent_rows > 0 && vent_slot_width > 0) {
        actual_vent_slot_fillet_r = vent_slot_width / 2; // For true stadium shape

        standoff_bl_center_x = pcb_origin_x_incase + rpi_mount_holes_coords[0][0];
        standoff_bl_center_y = pcb_origin_y_incase + rpi_mount_holes_coords[0][1];
        standoff_br_center_x = pcb_origin_x_incase + rpi_mount_holes_coords[1][0];
        standoff_tl_center_y = pcb_origin_y_incase + rpi_mount_holes_coords[2][1];

        vent_area_x_start = standoff_bl_center_x + standoff_outer_dia/2 + vent_area_margin_to_standoffs;
        vent_area_x_end   = standoff_br_center_x - standoff_outer_dia/2 - vent_area_margin_to_standoffs;
        vent_area_y_start = standoff_bl_center_y + standoff_outer_dia/2 + vent_area_margin_to_standoffs;
        vent_area_y_end   = standoff_tl_center_y - standoff_outer_dia/2 - vent_area_margin_to_standoffs;
        
        vent_total_width  = vent_area_x_end - vent_area_x_start;
        vent_total_height = vent_area_y_end - vent_area_y_start;

        spacing_x = (vent_cols > 0) ? (vent_total_width - vent_cols * vent_slot_length) / (vent_cols + 1) : 0;
        spacing_y = (vent_rows > 0) ? (vent_total_height - vent_rows * vent_slot_width) / (vent_rows + 1) : 0;

        actual_recess_depth_safe = min(base_recess_depth, case_floor_thickness - 0.1);
        effective_center_floor_thickness = case_floor_thickness - actual_recess_depth_safe;
        slot_cut_depth = effective_center_floor_thickness + 0.2; 

        if (spacing_x >= -0.001 && spacing_y >= -0.001 && vent_total_width >= vent_slot_length && vent_total_height >= vent_slot_width) { // Allow for tiny float inaccuracies
            for (r = 0; r < vent_rows; r++) {
                slot_base_y = vent_area_y_start + spacing_y + r * (vent_slot_width + spacing_y);
                for (c = 0; c < vent_cols; c++) {
                    slot_base_x = vent_area_x_start + spacing_x + c * (vent_slot_length + spacing_x);
                    translate([slot_base_x, slot_base_y, actual_recess_depth_safe -0.1]) { 
                        rounded_cube(
                            [vent_slot_length, vent_slot_width, slot_cut_depth],
                            actual_vent_slot_fillet_r
                        );
                    }
                }
            }
        } else {
            // echo(str("Warning: Ventilation slots do not fit. W=", vent_total_width, ", H=", vent_total_height, ", SX=", spacing_x, ", SY=", spacing_y));
        }
    }
}

// --- Main Case Construction ---
difference() {
    // --- Positive Geometry: Case Shell (Tapered) + Standoffs ---
    union() {
        // 1. Main Case Shell (tapered and rounded)
        difference() {
            minkowski_rounded_tapered_block(
                [outer_x_at_base, outer_y_at_base], 
                [outer_x_at_top, outer_y_at_top], 
                outer_z, 
                fillet_r_outer
            );
            
            // Inner cavity (straight walls, rounded edges including floor-to-wall transition)
            cavity_x_dim = outer_x_at_base - 2 * wall_t_at_base; // Inner cavity size is based on base wall thickness
            cavity_y_dim = outer_y_at_base - 2 * wall_t_at_base;
            cavity_height_for_cut = wall_height_above_floor + fillet_r_outer + fillet_r_inner_cavity + 1; // Ensure full cut through top and filleted floor area

            translate([wall_t_at_base, wall_t_at_base, case_floor_thickness - fillet_r_inner_cavity]) {
                 rounded_cube( // This creates the inner cavity volume to be removed
                    [cavity_x_dim, cavity_y_dim, cavity_height_for_cut],
                    fillet_r_inner_cavity // This radius creates fillets on all internal edges of the cavity
                );
            }
        }

        // 2. Standoffs
        for (hole_coord = rpi_mount_holes_coords) {
            standoff_center_x = pcb_origin_x_incase + hole_coord[0];
            standoff_center_y = pcb_origin_y_incase + hole_coord[1];
            translate([standoff_center_x, standoff_center_y, case_floor_thickness]) {
                standoff_filleted(
                    height = standoff_height_from_floor,
                    outer_r = standoff_outer_dia / 2,
                    fillet_r = standoff_top_fillet_r
                );
            }
        }
    } // End of positive geometry union

    // --- Negative Geometry: Screw Holes, Base Recess, Port Cutouts, and Ventilation ---

    // 1. Screw Holes for mounting Raspberry Pi
    for (hole_coord = rpi_mount_holes_coords) {
        hole_center_x = pcb_origin_x_incase + hole_coord[0];
        hole_center_y = pcb_origin_y_incase + hole_coord[1];
        translate([hole_center_x, hole_center_y, 0]) {
            bottom_countersunk_hole(
                total_hole_depth = pcb_bottom_z_abs, // Hole goes up to where PCB bottom rests (on standoffs)
                hole_radius = screw_hole_dia / 2,
                head_recess_radius = screw_head_dia / 2,
                head_recess_depth = screw_head_h
            );
        }
    }
    
    // 2. Base Recess (creates perimeter foot)
    actual_recess_depth_safe = min(base_recess_depth, case_floor_thickness - 0.1); 
    if (actual_recess_depth_safe > 0) {
        translate([base_recess_margin, base_recess_margin, -0.01]) 
          rounded_cube(
            [outer_x_at_base - 2*base_recess_margin, outer_y_at_base - 2*base_recess_margin, actual_recess_depth_safe + 0.02],
            base_recess_fillet_r
          );
    }

    // Port cutout penetration depth calculations
    // Max wall thickness is at base (wall_t_at_base). Taper makes it thinner at top.
    // Penetration should be enough to clear wall_t_at_base + pcb_clearance + fillet_r + safety.
    // The port cutouts are defined from the *outside* of the max dimensions (at base).
    cutout_penetration_general = wall_t_at_base + pcb_to_wall_clearance + port_cutout_fillet_r + outer_z*tan(outer_taper_angle) + 0.2;
    cutout_penetration_sd = wall_t_at_base + pcb_to_wall_clearance + sd_port_cutout_fillet_r + outer_z*tan(outer_taper_angle) + 0.2;


    // 3. Port Cutouts
    // Side 1: Ethernet and USB ports (on PCB's "far" Y-edge, Y_MAX)
    eth_body_w = 15.8; eth_body_h = 13.6;
    eth_cut_w = eth_body_w + port_margin; eth_cut_h = eth_body_h + port_margin;
    eth_pcb_center_x = 76.75;
    eth_cut_x_start = pcb_origin_x_incase + eth_pcb_center_x - eth_cut_w/2;
    translate([eth_cut_x_start, outer_y_at_base - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([eth_cut_w, cutout_penetration_general, eth_cut_h], port_cutout_fillet_r);

    usb2_body_w = 28.6; usb2_body_h = 15.2;
    usb2_cut_w = usb2_body_w + port_margin; usb2_cut_h = usb2_body_h + port_margin;
    usb2_pcb_center_x = 54.25;
    usb2_cut_x_start = pcb_origin_x_incase + usb2_pcb_center_x - usb2_cut_w/2;
    translate([usb2_cut_x_start, outer_y_at_base - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([usb2_cut_w, cutout_penetration_general, usb2_cut_h], port_cutout_fillet_r);

    usb3_body_w = 28.6; usb3_body_h = 15.2;
    usb3_cut_w = usb3_body_w + port_margin; usb3_cut_h = usb3_body_h + port_margin;
    usb3_pcb_center_x = 30.5;
    usb3_cut_x_start = pcb_origin_x_incase + usb3_pcb_center_x - usb3_cut_w/2;
    translate([usb3_cut_x_start, outer_y_at_base - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([usb3_cut_w, cutout_penetration_general, usb3_cut_h], port_cutout_fillet_r);

    // Side 2: Power, HDMI, Audio (on PCB's "right" X-edge, X_MAX)
    pwr_body_y_dim = 8.4; pwr_body_z_dim = 5.3;
    pwr_pcb_y_start_edge = 3.6;
    pwr_cut_y_start = pcb_origin_y_incase + pwr_pcb_y_start_edge - port_margin/2;
    pwr_cut_width_y = pwr_body_y_dim + port_margin; pwr_cut_height_z = pwr_body_z_dim + port_margin;
    translate([outer_x_at_base - cutout_penetration_general, pwr_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, pwr_cut_width_y, pwr_cut_height_z], port_cutout_fillet_r);

    hdmi_body_y_dim = 7.4; hdmi_body_z_dim = 4.6;
    hdmi_cut_width_y = hdmi_body_y_dim + port_margin; hdmi_cut_height_z = hdmi_body_z_dim + port_margin;
    hdmi0_pcb_y_start_edge = 18.3;
    hdmi0_cut_y_start = pcb_origin_y_incase + hdmi0_pcb_y_start_edge - port_margin/2;
    translate([outer_x_at_base - cutout_penetration_general, hdmi0_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, hdmi_cut_width_y, hdmi_cut_height_z], port_cutout_fillet_r);

    hdmi1_pcb_y_start_edge = 31.8;
    hdmi1_cut_y_start = pcb_origin_y_incase + hdmi1_pcb_y_start_edge - port_margin/2;
    translate([outer_x_at_base - cutout_penetration_general, hdmi1_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, hdmi_cut_width_y, hdmi_cut_height_z], port_cutout_fillet_r);

    audio_body_y_dim = 6.5; audio_body_z_dim = 5.6;
    audio_pcb_y_start_edge = 47.2;
    audio_cut_y_start = pcb_origin_y_incase + audio_pcb_y_start_edge - port_margin/2;
    audio_cut_width_y = audio_body_y_dim + port_margin; audio_cut_height_z = audio_body_z_dim + port_margin;
    translate([outer_x_at_base - cutout_penetration_general, audio_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, audio_cut_width_y, audio_cut_height_z], port_cutout_fillet_r);

    // Side 3: MicroSD card slot & GPIO (on PCB's "front" Y-edge, Y_MIN)
    sd_body_x_dim = 12.0; sd_body_z_dim = 2.0;
    sd_slot_z_offset_from_pcb_bottom = 0.2;
    sd_pcb_center_x = 37.5;
    sd_cut_width_x = sd_body_x_dim + port_margin; sd_cut_height_z = sd_body_z_dim + port_margin;
    sd_cut_x_start = pcb_origin_x_incase + sd_pcb_center_x - sd_cut_width_x/2;
    translate([sd_cut_x_start, 0 - cutout_penetration_sd, pcb_bottom_z_abs + sd_slot_z_offset_from_pcb_bottom])
        rounded_cube([sd_cut_width_x, cutout_penetration_sd, sd_cut_height_z], sd_port_cutout_fillet_r);
            
    gpio_pcb_x_start_edge = 17; gpio_pcb_x_width_dim = 51; 
    gpio_cutout_clearance_h = 13.0;
    gpio_cut_width_x = gpio_pcb_x_width_dim + port_margin;
    gpio_cut_x_start = pcb_origin_x_incase + gpio_pcb_x_start_edge - port_margin/2;
    translate([gpio_cut_x_start, 0 - cutout_penetration_general, pcb_bottom_z_abs]) // Use general penetration
        rounded_cube([gpio_cut_width_x, cutout_penetration_general, gpio_cutout_clearance_h], port_cutout_fillet_r);

    // 4. Ventilation Slots on the case floor
    ventilation_pattern_subtractions();

} // End of main difference()
