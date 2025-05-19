// Raspberry Pi 4 Minimal Case - Polished Version v4 (Stadium Vents, Recessed Base)
// Original by: cad_engineer
// Polished by: polish_agent (Iteration 4)

// --- Rendering Quality ---
$fn = 60; // Global fragments for curves

// --- Original Raspberry Pi 4B Board Dimensions ---
board_x_dim = 85;
board_y_dim = 56;

// --- Original Case Design Parameters ---
case_floor_thickness = 2.0;
wall_t = 1.5;
standoff_height_from_floor = 7.0;
pcb_to_wall_clearance = 0.5;

// --- Original Standoff Parameters ---
standoff_outer_dia = 6.0;
screw_hole_dia = 2.7;
screw_head_dia = 5.0;
screw_head_h = 1.5;

// --- Original Port Cutout Margin ---
port_margin = 0.6;

// --- Aesthetic Improvement Parameters ---
fillet_r_outer = 2.5;         // Fillet radius for main case outer edges
fillet_r_inner_cavity = 1.0;  // Fillet radius for inner cavity top edges
standoff_top_fillet_r = 0.6;  // Fillet radius for the top edge of standoffs
port_cutout_fillet_r = 0.8;   // Fillet radius for edges of most port cutouts
sd_port_cutout_fillet_r = 0.4; // Specific smaller fillet for MicroSD slot

// --- Base Recess Parameters ---
base_recess_depth = 0.8;      // How much the central part of the base is recessed
base_recess_margin = 3.0;     // Margin from outer edge to the start of the recess
base_recess_fillet_r = 1.5;   // Fillet for the recess edge, slightly larger for a softer look

// --- Ventilation Parameters ---
add_ventilation = true;             // Master toggle for adding ventilation slots
vent_slot_length = 20;              // Length of an individual vent slot
vent_slot_width = 3.5;              // Width of an individual vent slot
// vent_slot_fillet_r is now automatically vent_slot_width / 2 for true stadium shape
vent_rows = 3;                      // Number of rows of vent slots
vent_cols = 2;                      // Number of slots per row
vent_area_margin_to_standoffs = 4;  // Clearance from the edge of vent area to standoff outer edges

// --- Calculated Case Dimensions ---
outer_x = board_x_dim + 2 * pcb_to_wall_clearance + 2 * wall_t;
outer_y = board_y_dim + 2 * pcb_to_wall_clearance + 2 * wall_t;
wall_height_above_floor = 16.0;
outer_z = case_floor_thickness + wall_height_above_floor;

pcb_origin_x_incase = wall_t + pcb_to_wall_clearance;
pcb_origin_y_incase = wall_t + pcb_to_wall_clearance;
pcb_bottom_z_abs = case_floor_thickness + standoff_height_from_floor;

// --- Raspberry Pi Mounting Holes Data ---
rpi_mount_holes_coords = [
    [3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]
];

// --- Helper Module: Rounded Cube Shape ---
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

        // Effective floor thickness in the center after recess
        effective_center_floor_thickness = case_floor_thickness - base_recess_depth;
        slot_cut_depth = effective_center_floor_thickness + 0.2; // Ensure cut through remaining floor

        if (spacing_x >= 0 && spacing_y >= 0 && vent_total_width >= vent_slot_length && vent_total_height >= vent_slot_width) {
            for (r = 0; r < vent_rows; r++) {
                slot_base_y = vent_area_y_start + spacing_y + r * (vent_slot_width + spacing_y);
                for (c = 0; c < vent_cols; c++) {
                    slot_base_x = vent_area_x_start + spacing_x + c * (vent_slot_length + spacing_x);
                    // Slots are cut from bottom of recessed area upwards
                    translate([slot_base_x, slot_base_y, base_recess_depth -0.1]) { 
                        rounded_cube( // Using rounded_cube as it's identical to rounded_subtraction_box
                            [vent_slot_length, vent_slot_width, slot_cut_depth],
                            actual_vent_slot_fillet_r
                        );
                    }
                }
            }
        } else {
            // echo(str("Warning: Ventilation slots do not fit."));
        }
    }
}

// --- Main Case Construction ---
difference() {
    // --- Positive Geometry: Case Shell + Standoffs ---
    union() {
        // 1. Main Case Shell
        difference() {
            rounded_cube([outer_x, outer_y, outer_z], fillet_r_outer);
            cavity_height = wall_height_above_floor + fillet_r_outer + 1;
            translate([wall_t, wall_t, case_floor_thickness]) {
                rounded_cube(
                    [outer_x - 2 * wall_t, outer_y - 2 * wall_t, cavity_height],
                    fillet_r_inner_cavity
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

    // --- Negative Geometry: Screw Holes, Port Cutouts, Base Recess, and Ventilation ---

    // 1. Screw Holes for mounting Raspberry Pi
    for (hole_coord = rpi_mount_holes_coords) {
        hole_center_x = pcb_origin_x_incase + hole_coord[0];
        hole_center_y = pcb_origin_y_incase + hole_coord[1];
        translate([hole_center_x, hole_center_y, 0]) {
            bottom_countersunk_hole(
                total_hole_depth = pcb_bottom_z_abs,
                hole_radius = screw_hole_dia / 2,
                head_recess_radius = screw_head_dia / 2,
                head_recess_depth = screw_head_h
            );
        }
    }
    
    // 2. Base Recess (creates perimeter foot)
    // Ensure recess does not go deeper than floor thickness
    actual_recess_depth = min(base_recess_depth, case_floor_thickness - 0.1); 
    if (actual_recess_depth > 0) {
        translate([base_recess_margin, base_recess_margin, -0.01]) 
          rounded_cube( // Using rounded_cube as it's identical to rounded_subtraction_box
            [outer_x - 2*base_recess_margin, outer_y - 2*base_recess_margin, actual_recess_depth + 0.02],
            base_recess_fillet_r
          );
    }


    // Port cutout penetration depth calculations
    cutout_penetration_general = wall_t + pcb_to_wall_clearance + port_cutout_fillet_r + 0.2; // Increased slightly for robustness
    cutout_penetration_sd = wall_t + pcb_to_wall_clearance + sd_port_cutout_fillet_r + 0.2; // Increased slightly

    // 3. Port Cutouts
    // Side 1: Ethernet and USB ports
    eth_body_w = 15.8; eth_body_h = 13.6;
    eth_cut_w = eth_body_w + port_margin; eth_cut_h = eth_body_h + port_margin;
    eth_pcb_center_x = 76.75;
    eth_cut_x_start = pcb_origin_x_incase + eth_pcb_center_x - eth_cut_w/2;
    translate([eth_cut_x_start, outer_y - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([eth_cut_w, cutout_penetration_general, eth_cut_h], port_cutout_fillet_r);

    usb2_body_w = 28.6; usb2_body_h = 15.2;
    usb2_cut_w = usb2_body_w + port_margin; usb2_cut_h = usb2_body_h + port_margin;
    usb2_pcb_center_x = 54.25;
    usb2_cut_x_start = pcb_origin_x_incase + usb2_pcb_center_x - usb2_cut_w/2;
    translate([usb2_cut_x_start, outer_y - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([usb2_cut_w, cutout_penetration_general, usb2_cut_h], port_cutout_fillet_r);

    usb3_body_w = 28.6; usb3_body_h = 15.2;
    usb3_cut_w = usb3_body_w + port_margin; usb3_cut_h = usb3_body_h + port_margin;
    usb3_pcb_center_x = 30.5;
    usb3_cut_x_start = pcb_origin_x_incase + usb3_pcb_center_x - usb3_cut_w/2;
    translate([usb3_cut_x_start, outer_y - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([usb3_cut_w, cutout_penetration_general, usb3_cut_h], port_cutout_fillet_r);

    // Side 2: Power, HDMI, Audio
    pwr_body_y_dim = 8.4; pwr_body_z_dim = 5.3;
    pwr_pcb_y_start_edge = 3.6;
    pwr_cut_y_start = pcb_origin_y_incase + pwr_pcb_y_start_edge - port_margin/2;
    pwr_cut_width_y = pwr_body_y_dim + port_margin; pwr_cut_height_z = pwr_body_z_dim + port_margin;
    translate([outer_x - cutout_penetration_general, pwr_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, pwr_cut_width_y, pwr_cut_height_z], port_cutout_fillet_r);

    hdmi_body_y_dim = 7.4; hdmi_body_z_dim = 4.6;
    hdmi_cut_width_y = hdmi_body_y_dim + port_margin; hdmi_cut_height_z = hdmi_body_z_dim + port_margin;
    hdmi0_pcb_y_start_edge = 18.3;
    hdmi0_cut_y_start = pcb_origin_y_incase + hdmi0_pcb_y_start_edge - port_margin/2;
    translate([outer_x - cutout_penetration_general, hdmi0_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, hdmi_cut_width_y, hdmi_cut_height_z], port_cutout_fillet_r);

    hdmi1_pcb_y_start_edge = 31.8;
    hdmi1_cut_y_start = pcb_origin_y_incase + hdmi1_pcb_y_start_edge - port_margin/2;
    translate([outer_x - cutout_penetration_general, hdmi1_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, hdmi_cut_width_y, hdmi_cut_height_z], port_cutout_fillet_r);

    audio_body_y_dim = 6.5; audio_body_z_dim = 5.6;
    audio_pcb_y_start_edge = 47.2;
    audio_cut_y_start = pcb_origin_y_incase + audio_pcb_y_start_edge - port_margin/2;
    audio_cut_width_y = audio_body_y_dim + port_margin; audio_cut_height_z = audio_body_z_dim + port_margin;
    translate([outer_x - cutout_penetration_general, audio_cut_y_start, pcb_bottom_z_abs])
        rounded_cube([cutout_penetration_general, audio_cut_width_y, audio_cut_height_z], port_cutout_fillet_r);

    // Side 3: MicroSD card slot & GPIO
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
    translate([gpio_cut_x_start, 0 - cutout_penetration_general, pcb_bottom_z_abs])
        rounded_cube([gpio_cut_width_x, cutout_penetration_general, gpio_cutout_clearance_h], port_cutout_fillet_r);

    // 4. Ventilation Slots on the case floor
    ventilation_pattern_subtractions();

} // End of main difference()
