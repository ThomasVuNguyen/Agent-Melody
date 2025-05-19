// Raspberry Pi 4 Minimal Case - Polished Version
// Original by: cad_engineer
// Polished by: polish_agent

// --- Rendering Quality ---
// $fa: minimum angle for fragments (lower is finer)
// $fs: minimum size of fragments (lower is finer)
// $fn: number of fragments for curved surfaces (higher is finer)
// Using $fn globally for simplicity in this revision.
$fn = 60; // Increased for smoother curves on all parts

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
fillet_r_inner_cavity = 1.0;  // Fillet radius for inner cavity top edges (and influences floor/wall internal fillet)
standoff_top_fillet_r = 0.6;  // Fillet radius for the top edge of standoffs
port_cutout_fillet_r = 0.8;   // Fillet radius for edges of port cutouts

// --- Calculated Case Dimensions (mostly unchanged) ---
outer_x = board_x_dim + 2 * pcb_to_wall_clearance + 2 * wall_t;
outer_y = board_y_dim + 2 * pcb_to_wall_clearance + 2 * wall_t;
wall_height_above_floor = 16.0;
outer_z = case_floor_thickness + wall_height_above_floor;

pcb_origin_x_incase = wall_t + pcb_to_wall_clearance;
pcb_origin_y_incase = wall_t + pcb_to_wall_clearance;
pcb_bottom_z_abs = case_floor_thickness + standoff_height_from_floor;

// --- Raspberry Pi Mounting Holes Data (unchanged) ---
rpi_mount_holes_coords = [
    [3.5, 3.5], [61.5, 3.5], [3.5, 52.5], [61.5, 52.5]
];

// --- Helper Module: Rounded Cube Shape (using minkowski sum) ---
// Creates a cube with all edges and corners rounded.
// Resulting shape spans from [0,0,0] to [size[0], size[1], size[2]].
module rounded_cube(size, radius) {
    // Primitive cube dimensions are smaller to account for minkowski sum with sphere
    primitive_cube_size = [
        max(0.01, size[0] - 2*radius),
        max(0.01, size[1] - 2*radius),
        max(0.01, size[2] - 2*radius)
    ];
    // Translate the primitive cube so the final rounded shape's origin is effectively [0,0,0]
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
        // Main cylindrical shaft
        cylinder(h = height - fillet_r, r = outer_r);
        // Toroidal fillet on the top edge
        translate([0, 0, height - fillet_r]) {
            rotate_extrude(convexity = 10) {
                translate([outer_r - fillet_r, 0, 0]) {
                    circle(r = fillet_r);
                }
            }
        }
    }
}

// --- Helper Module: Rounded Port Subtraction Shape ---
// Creates a rounded cuboid intended for subtraction, similar to rounded_cube.
// Resulting shape spans from [0,0,0] to [size[0], size[1], size[2]].
module rounded_subtraction_box(size, radius) {
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

// --- Helper Module for Countersunk Screw Holes (from bottom of the case, minor $fn update if needed) ---
module bottom_countersunk_hole(total_hole_depth, hole_radius, head_recess_radius, head_recess_depth) {
    // Main screw hole shaft
    translate([0, 0, head_recess_depth - 0.01]) 
        cylinder(h = total_hole_depth - head_recess_depth + 0.02, r = hole_radius); // Use global $fn
    // Screw head recess (countersink)
    translate([0, 0, -0.01]) 
        cylinder(h = head_recess_depth + 0.01, r = head_recess_radius); // Use global $fn
}

// --- Main Case Construction ---
difference() {
    // --- Positive Geometry: Case Shell + Standoffs ---
    union() {
        // 1. Main Case Shell (floor and walls, with rounded edges)
        difference() {
            // Outer solid block with rounded edges
            rounded_cube([outer_x, outer_y, outer_z], fillet_r_outer);
            
            // Inner cavity to hollow out the box, with its own rounded edges
            // Cavity height needs to ensure it cuts through the filleted top of the outer shell.
            cavity_height = wall_height_above_floor + fillet_r_outer + 1; // +1 for guaranteed cut
            translate([wall_t, wall_t, case_floor_thickness]) {
                rounded_cube(
                    [outer_x - 2 * wall_t, outer_y - 2 * wall_t, cavity_height],
                    fillet_r_inner_cavity
                );
            }
        }

        // 2. Standoffs (with filleted tops, placed on the case's inner floor)
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

    // --- Negative Geometry: Screw Holes and Port Cutouts ---
    union() { // Union all subtractions for a single difference operation
        // 1. Screw Holes for mounting Raspberry Pi (countersunk from bottom)
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

        // Port cutout penetration depth (ensures cut through wall and clearance area)
        cutout_penetration = wall_t + pcb_to_wall_clearance + port_cutout_fillet_r + 0.1; // Ensure penetration considers fillet

        // 2. Port Cutouts (with rounded edges)
        // All port Z coordinates relative to PCB bottom (pcb_bottom_z_abs).
        // Port dimensions are for the cutout (raw dimension + port_margin).

        // Side 1: Ethernet and USB ports (on PCB's "far" Y-edge, Y_MAX)
        // Cutouts in wall at outer_y, extruding inwards.
        
        // Ethernet Port (RJ45)
        eth_body_w = 15.8; eth_body_h = 13.6;
        eth_cut_w = eth_body_w + port_margin;
        eth_cut_h = eth_body_h + port_margin;
        eth_pcb_center_x = 76.75;
        eth_cut_x_start = pcb_origin_x_incase + eth_pcb_center_x - eth_cut_w/2;
        translate([eth_cut_x_start, outer_y - cutout_penetration, pcb_bottom_z_abs]) {
            rounded_subtraction_box([eth_cut_w, cutout_penetration, eth_cut_h], port_cutout_fillet_r);
        }

        // USB 2.0 Stack (Black)
        usb2_body_w = 28.6; usb2_body_h = 15.2;
        usb2_cut_w = usb2_body_w + port_margin;
        usb2_cut_h = usb2_body_h + port_margin;
        usb2_pcb_center_x = 54.25;
        usb2_cut_x_start = pcb_origin_x_incase + usb2_pcb_center_x - usb2_cut_w/2;
        translate([usb2_cut_x_start, outer_y - cutout_penetration, pcb_bottom_z_abs]) {
            rounded_subtraction_box([usb2_cut_w, cutout_penetration, usb2_cut_h], port_cutout_fillet_r);
        }

        // USB 3.0 Stack (Blue)
        usb3_body_w = 28.6; usb3_body_h = 15.2;
        usb3_cut_w = usb3_body_w + port_margin;
        usb3_cut_h = usb3_body_h + port_margin;
        usb3_pcb_center_x = 30.5;
        usb3_cut_x_start = pcb_origin_x_incase + usb3_pcb_center_x - usb3_cut_w/2;
        translate([usb3_cut_x_start, outer_y - cutout_penetration, pcb_bottom_z_abs]) {
            rounded_subtraction_box([usb3_cut_w, cutout_penetration, usb3_cut_h], port_cutout_fillet_r);
        }

        // Side 2: Power, HDMI, Audio (on PCB's "right" X-edge, X_MAX)
        // Cutouts in wall at outer_x, extruding inwards.

        // USB-C Power Port
        pwr_body_y_dim = 8.4; pwr_body_z_dim = 5.3;
        pwr_pcb_y_start_edge = 3.6;
        pwr_cut_y_start = pcb_origin_y_incase + pwr_pcb_y_start_edge - port_margin/2;
        pwr_cut_width_y = pwr_body_y_dim + port_margin;
        pwr_cut_height_z = pwr_body_z_dim + port_margin;
        translate([outer_x - cutout_penetration, pwr_cut_y_start, pcb_bottom_z_abs]) {
            rounded_subtraction_box([cutout_penetration, pwr_cut_width_y, pwr_cut_height_z], port_cutout_fillet_r);
        }

        // Micro HDMI0 Port
        hdmi_body_y_dim = 7.4; hdmi_body_z_dim = 4.6;
        hdmi_cut_width_y = hdmi_body_y_dim + port_margin;
        hdmi_cut_height_z = hdmi_body_z_dim + port_margin;
        hdmi0_pcb_y_start_edge = 18.3;
        hdmi0_cut_y_start = pcb_origin_y_incase + hdmi0_pcb_y_start_edge - port_margin/2;
        translate([outer_x - cutout_penetration, hdmi0_cut_y_start, pcb_bottom_z_abs]) {
            rounded_subtraction_box([cutout_penetration, hdmi_cut_width_y, hdmi_cut_height_z], port_cutout_fillet_r);
        }

        // Micro HDMI1 Port
        hdmi1_pcb_y_start_edge = 31.8;
        hdmi1_cut_y_start = pcb_origin_y_incase + hdmi1_pcb_y_start_edge - port_margin/2;
        translate([outer_x - cutout_penetration, hdmi1_cut_y_start, pcb_bottom_z_abs]) {
            rounded_subtraction_box([cutout_penetration, hdmi_cut_width_y, hdmi_cut_height_z], port_cutout_fillet_r);
        }

        // Audio Jack Port (3.5mm)
        audio_body_y_dim = 6.5; audio_body_z_dim = 5.6;
        audio_pcb_y_start_edge = 47.2;
        audio_cut_y_start = pcb_origin_y_incase + audio_pcb_y_start_edge - port_margin/2;
        audio_cut_width_y = audio_body_y_dim + port_margin;
        audio_cut_height_z = audio_body_z_dim + port_margin;
        translate([outer_x - cutout_penetration, audio_cut_y_start, pcb_bottom_z_abs]) {
            rounded_subtraction_box([cutout_penetration, audio_cut_width_y, audio_cut_height_z], port_cutout_fillet_r);
        }

        // Side 3: MicroSD card slot & GPIO (on PCB's "front" Y-edge, Y_MIN)
        // Cutouts in wall at Y=0 (case coordinates), extruding outwards (negative Y direction).

        // MicroSD Card Slot
        sd_body_x_dim = 12.0; sd_body_z_dim = 2.0;
        sd_slot_z_offset_from_pcb_bottom = 0.2;
        sd_pcb_center_x = 37.5;
        sd_cut_width_x = sd_body_x_dim + port_margin;
        sd_cut_height_z = sd_body_z_dim + port_margin;
        sd_cut_x_start = pcb_origin_x_incase + sd_pcb_center_x - sd_cut_width_x/2;
        translate([sd_cut_x_start, 0 - cutout_penetration, pcb_bottom_z_abs + sd_slot_z_offset_from_pcb_bottom]) {
            rounded_subtraction_box([sd_cut_width_x, cutout_penetration, sd_cut_height_z], port_cutout_fillet_r);
        }
            
        // GPIO Header Cutout
        gpio_pcb_x_start_edge = 17;
        gpio_pcb_x_width_dim = 51; 
        gpio_cutout_clearance_h = 13.0;
        gpio_cut_width_x = gpio_pcb_x_width_dim + port_margin;
        gpio_cut_x_start = pcb_origin_x_incase + gpio_pcb_x_start_edge - port_margin/2;
        translate([gpio_cut_x_start, 0 - cutout_penetration, pcb_bottom_z_abs]) {
            rounded_subtraction_box([gpio_cut_width_x, cutout_penetration, gpio_cutout_clearance_h], port_cutout_fillet_r);
        }
    } // End of negative geometry union
} // End of main difference()
