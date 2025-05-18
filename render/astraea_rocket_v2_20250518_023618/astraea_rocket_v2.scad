// Astraea Orbital Launch Vehicle - Polished Design
// Target Height: ~65m
// Overall Impression: Tall, slender, multi-stage rocket, smooth continuous curve with fillets and modern aesthetics.

// Global Settings
$fn = 100; // Increased smoothness for curves
fillet_radius_small = 0.05; // General small fillet for edges
fillet_radius_medium = 0.15; // For larger transitions
fillet_radius_large = 0.3; // For stage transitions (not heavily used, stage tapers suffice)

// --- Dimensions (all in meters) ---

// I. Nose Cone / Payload Fairing
fairing_height = 12;
fairing_base_diameter = 4.5;
fairing_base_radius = fairing_base_diameter / 2;
tip_sensor_radius = 0.1;
tip_sensor_height = 0.35; // Slightly taller for better proportion
tip_sensor_fillet = 0.05; 

// II. Upper Stage (Second Stage)
upper_stage_height = 10;
upper_stage_diameter = 4.5;
upper_stage_radius = upper_stage_diameter / 2;
rcs_pod_length = 0.9; // Slightly longer for sleeker look
rcs_pod_width = 0.55; 
rcs_pod_profile_radius = 0.22; // Radius for hull shape
rcs_nozzle_radius = 0.04; // Smaller, more refined
rcs_nozzle_length = 0.07;
rcs_nozzle_exit_flare_factor = 1.5; // Flare for nozzle exit
upper_stage_engine_nozzle_height = 2.8;
upper_stage_engine_nozzle_exit_radius = 1.6;
upper_stage_engine_nozzle_throat_radius = 0.4;
upper_stage_engine_nozzle_base_radius = 0.6; 
engine_cc_height_generic = 0.5; // Generic height for CC part
engine_cc_radius_generic = 0.5; // Generic radius for CC part

// III. Interstage Adapter
interstage_height = 2;
interstage_top_diameter = 4.5;    
interstage_bottom_diameter = 5; 
interstage_top_radius = interstage_top_diameter / 2;
interstage_bottom_radius = interstage_bottom_diameter / 2;
slit_rounding_radius = 0.04; 
interstage_slit_width = 0.05; // Width of the slit opening
interstage_slit_length = 0.6; // Length of the slit opening
interstage_slit_depth = 0.1;  // How deep the slit goes

// IV. First Stage (Booster)
first_stage_total_height = 35;
first_stage_top_diameter = 5;
first_stage_base_diameter = 5.5;
first_stage_top_radius = first_stage_top_diameter / 2;
first_stage_base_radius = first_stage_base_diameter / 2;

first_stage_blue_section_height = 5; 
first_stage_white_section_height = first_stage_total_height - first_stage_blue_section_height;
radius_at_blue_white_interface = first_stage_base_radius - (first_stage_base_radius - first_stage_top_radius) * (first_stage_blue_section_height / first_stage_total_height);

// Conduits/Raceways
conduit_radius = 0.06;
num_conduits = 10; // More, smaller conduits for subtlety
conduit_coverage_factor = 0.85; // How much of the stage height they cover

// Fins (First Stage)
fin_thickness = 0.15;
fin_root_chord = 3.5;
fin_tip_chord = 1.5;
fin_span = 4.5;
fin_sweep_angle_deg = 25;
fin_sweep_offset = fin_span * tan(fin_sweep_angle_deg);
fin_attachment_z_offset = 2; 
fin_edge_rounding = 0.05; // For leading/trailing/tip edges

// V. Propulsion System (First Stage Base)
fs_engine_cc_height = 1.0; 
fs_engine_nozzle_height = 3.0; // Nozzle itself, separate from CC height budget
fs_engine_cc_radius = 0.65;
fs_engine_throat_radius = 0.35;
fs_engine_exit_radius = 1.1; 
fs_engine_peripheral_offset = fs_engine_cc_radius + fs_engine_exit_radius * 0.75; 
fs_gimbal_joint_radius = 0.25;

// VI. Landing System (First Stage Base)
leg_strut_radius = 0.1; 
leg_main_strut_length = 7;
leg_deploy_angle_from_vertical = 35; 
leg_attachment_point_on_body_z = first_stage_blue_section_height * 0.6;
leg_foot_pad_radius = 0.65;
leg_foot_pad_height = 0.12; 
leg_foot_pad_rounding = 0.06;
leg_light_radius = 0.08;
leg_light_height = 0.04;
leg_a_frame_spread_angle = 12; // Angle between A-frame struts at body attachment

// Accent Lighting / Details
accent_groove_depth = 0.03;
accent_groove_width = 0.04;

// --- Colors ---
color_pearlescent_white = [0.96, 0.97, 1.0]; 
color_sapphire_blue = [0.05, 0.15, 0.45]; 
color_metallic_silver = "Silver";
color_dark_engine_metal = [0.2, 0.2, 0.25]; 
color_cyan_light = "Cyan";
color_engine_bell_interior = [0.5, 0.65, 0.8, 0.7]; // Slightly bluer, with alpha
color_led_strip_groove = color_pearlescent_white * 0.85; // Darker for groove

// --- Helper function for tapered radius ---
function get_radius_on_taper(z_abs, base_z, segment_h, r_bottom, r_top) = 
    (z_abs < base_z || z_abs > base_z + segment_h) ? -1 : // Out of bounds
    r_bottom + (r_top - r_bottom) * ((z_abs - base_z) / segment_h);


// --- Helper Modules ---

module refined_engine_nozzle(nozzle_h, throat_r, exit_r, color_ext, color_int) {
    // Nozzle Bell using hull() of multiple disks for a smooth curve
    hull() { // Outer Bell
        color(color_ext) {
            base_throat_thickness = throat_r * 0.1; // Thickness for hull base
            translate([0,0,0]) cylinder(h=base_throat_thickness, r=throat_r, center=true); // Throat (provide some thickness for hull)
            // Points along a somewhat exponential/parabolic curve
            translate([0,0, -nozzle_h*0.05]) cylinder(h=0.01, r=throat_r*1.15);
            translate([0,0, -nozzle_h*0.15]) cylinder(h=0.01, r=throat_r*1.5);
            translate([0,0, -nozzle_h*0.4])  cylinder(h=0.01, r=throat_r + (exit_r - throat_r)*0.55); 
            translate([0,0, -nozzle_h*0.75]) cylinder(h=0.01, r=throat_r + (exit_r - throat_r)*0.9);
            translate([0,0, -nozzle_h])      cylinder(h=0.01, r=exit_r); // Exit
        }
    }
    // Inner Bell Surface
    hull() {
        color(color_int) {
            local_throat_r = throat_r * 0.9; // Slightly smaller for wall thickness
            local_exit_r = exit_r * 0.95;
            translate([0,0,0]) cylinder(h=0.01, r=local_throat_r);
            translate([0,0, -nozzle_h*0.05]) cylinder(h=0.01, r=local_throat_r*1.15);
            translate([0,0, -nozzle_h*0.15]) cylinder(h=0.01, r=local_throat_r*1.5);
            translate([0,0, -nozzle_h*0.4])  cylinder(h=0.01, r=local_throat_r + (local_exit_r - local_throat_r)*0.55);
            translate([0,0, -nozzle_h*0.75]) cylinder(h=0.01, r=local_throat_r + (local_exit_r - local_throat_r)*0.9);
            translate([0,0, -nozzle_h*0.98]) cylinder(h=0.01, r=local_exit_r); // Slightly shorter inner surface
        }
    }
}

// --- Rocket Component Modules ---

// I. Nose Cone / Payload Fairing
module nose_cone_shape() { // Internal module for the main shape to allow differencing
    // Ogive shape - using hull for a smooth tangent ogive-like curve
    color(color_pearlescent_white) {
        hull() {
            cylinder(h = fairing_height * 0.01, r = fairing_base_radius); // Base disk
            cylinder(h = fairing_height * 0.4, r = fairing_base_radius * 0.95, center=false); // Control point for curve
            translate([0, 0, fairing_height - tip_sensor_height*0.6]) sphere(r = fairing_base_radius*0.005); // Sharp tip point before sensor
        }
    }
    // Tip sensor array housing - more integrated and sleek
    color(color_cyan_light) {
        translate([0, 0, fairing_height - tip_sensor_height / 2]) {
             hull() {
                cylinder(h=tip_sensor_height*0.7, r=tip_sensor_radius, center=true);
                translate([0,0,tip_sensor_height*0.35]) sphere(r=tip_sensor_radius); // Rounded top
                translate([0,0,-tip_sensor_height*0.35]) sphere(r=tip_sensor_radius*0.9); // Blended base
             }
        }
    }
}
module nose_cone() {
    difference() {
        nose_cone_shape();
        // Subtle clamshell seam grooves
        for (angle = [0, 180]) { 
            rotate([0,0,angle]) {
                // Tall, thin cuboid radially aligned to cut a groove.
                // Y-axis is depth into fairing, X-axis is width of groove, Z-axis is height.
                translate([0, fairing_base_radius - accent_groove_depth/2, fairing_height/2])
                     cube([accent_groove_width, accent_groove_depth, fairing_height*1.02], center=true);
            }
        }
    }
}


// II. Upper Stage (Second Stage)
module rcs_thruster_pod() {
    // Aerodynamically faired pod
    color(color_pearlescent_white) {
        hull() {
            // Base of the pod (wider part attached to rocket body)
            translate([0,0, -rcs_pod_length/2])
                rotate([90,0,0]) cylinder(h=rcs_pod_width, r=rcs_pod_profile_radius, center=true);
            // Tip of the pod (narrower)
            translate([0,0, rcs_pod_length/2]) 
                rotate([90,0,0]) cylinder(h=rcs_pod_width*0.6, r=rcs_pod_profile_radius*0.5, center=true);
        }
    }

    // Thruster Nozzles - small, conical
    color(color_dark_engine_metal) {
        // Three example thrusters
        positions = [
            [0, rcs_pod_profile_radius*0.7, rcs_pod_length*0.3],  // Side 1
            [0, -rcs_pod_profile_radius*0.7, rcs_pod_length*0.3], // Side 2
            [0, 0, rcs_pod_length*0.4] // Forward/Aft (adjust rotation)
        ];
        rotations = [
            [0,90,0],
            [0,-90,0],
            [90,0,0] // Example: Firing "forward" along pod length
        ];
        for(i = [0:len(positions)-1]){
            translate(positions[i]) rotate(rotations[i]) 
                cylinder(h=rcs_nozzle_length, r1=rcs_nozzle_radius, r2=rcs_nozzle_radius*rcs_nozzle_exit_flare_factor, $fn=16);
        }
    }
}

module upper_stage_engine() {
    // Combustion Chamber (simplified conical)
    color(color_dark_engine_metal) {
        cylinder(h = engine_cc_height_generic, r1 = upper_stage_engine_nozzle_base_radius, r2 = upper_stage_engine_nozzle_throat_radius);
    }
    // Nozzle (attached to CC base, extends downwards)
    translate([0,0,0]) // Nozzle throat aligns with CC base exit (r2)
        refined_engine_nozzle(
            nozzle_h = upper_stage_engine_nozzle_height,
            throat_r = upper_stage_engine_nozzle_throat_radius,
            exit_r = upper_stage_engine_nozzle_exit_radius,
            color_ext = color_dark_engine_metal,
            color_int = color_engine_bell_interior
        );
}

module upper_stage() {
    difference() {
        union() {
            // Main body
            color(color_pearlescent_white)
                cylinder(h = upper_stage_height, r = upper_stage_radius);

            // RCS Thruster Pods (4 radially) - faired into body
            rcs_pod_attach_height = upper_stage_height - rcs_pod_length * 0.7;
            rcs_radial_offset = upper_stage_radius - rcs_pod_profile_radius * 0.7; // Pod slightly embedded

            for (i = [0:3]) {
                rotate([0, 0, i * 90]) { // Radial placement
                    translate([rcs_radial_offset, 0, rcs_pod_attach_height]) {
                        // Pod length along rocket's Z-axis, width along X, thrusters orient accordingly
                        rotate([0, 0, 0]) // Pod oriented with its length along rocket Z
                           rcs_thruster_pod();
                    }
                }
            }
        }
        // Accent lighting grooves (example: two rings)
        for(z_offset_factor = [0.25, 0.75]) {
             translate([0,0, upper_stage_height * z_offset_factor]) 
                color(color_led_strip_groove) // Color the groove itself
                    rotate_extrude(convexity = 2) 
                        translate([upper_stage_radius - accent_groove_depth + 0.001, 0, 0]) // slightly inside surface
                            circle(r = accent_groove_width/2, $fn=24); // Cut a toroidal groove
        }
    }
    upper_stage_engine();
}

// III. Interstage Adapter
module interstage() {
    num_slits = 32; // Increased number for finer detail
    interstage_mid_height = interstage_height / 2;
    interstage_radius_at_mid = (interstage_top_radius + interstage_bottom_radius) / 2;
    
    difference() {
        color(color_sapphire_blue)
            cylinder(h = interstage_height, r1 = interstage_bottom_radius, r2 = interstage_top_radius);
        
        // Vents (slits with rounded ends, cut using minkowski)
        for (a = [0 : 360/num_slits : 359]) {
            rotate([0,0,a]) { // Position slit radially
                // Slit aligned with Z axis, X is radial depth, Y is circumferential width
                translate([interstage_radius_at_mid, 0, interstage_mid_height]) { // Center of slit on surface
                     minkowski() {
                        cube([interstage_slit_depth, interstage_slit_width - 2*slit_rounding_radius, interstage_slit_length - 2*slit_rounding_radius], center=true);
                        sphere(r=slit_rounding_radius, $fn=12);
                     }
                }
            }
        }
    }
}

// IV. First Stage (Booster)
module fin() {
    fin_points_raw = [
      [0,0], // root leading edge
      [fin_root_chord, 0], // root trailing edge
      [fin_sweep_offset + fin_tip_chord, fin_span], // tip trailing edge
      [fin_sweep_offset, fin_span]  // tip leading edge
    ];

    color(color_sapphire_blue) {
        linear_extrude(height = fin_thickness, center = true, convexity=4, scale = 0.95) { // Slight taper for sharper edges
            minkowski() {
                polygon(points = fin_points_raw);
                circle(r = fin_edge_rounding, $fn = 20); // Rounds corners & edges in 2D plane
            }
        }
    }
}

module first_stage_engine() { // Renamed from first_stage_engine_nozzle for clarity
    // Gimbal visual representation (sphere at top of CC)
    color(color_metallic_silver) 
        translate([0,0, fs_engine_cc_height + fs_gimbal_joint_radius*0.3]) 
            sphere(r=fs_gimbal_joint_radius, $fn=24);

    // Combustion Chamber (conical, as per original structure)
    color(color_dark_engine_metal) {
        cylinder(h = fs_engine_cc_height, r1 = fs_engine_cc_radius, r2 = fs_engine_throat_radius);
    }
    // Nozzle (attached to CC base, extends downwards)
    translate([0,0,0]) // Nozzle throat aligns with CC base exit (r2)
        refined_engine_nozzle(
            nozzle_h = fs_engine_nozzle_height,
            throat_r = fs_engine_throat_radius,
            exit_r = fs_engine_exit_radius,
            color_ext = color_dark_engine_metal,
            color_int = color_engine_bell_interior
        );
}

module first_stage_propulsion() {
    // Central Engine
    first_stage_engine();
    // Peripheral Engines (4)
    for (i = [0:3]) {
        rotate([0, 0, i * 90 + 45]) // Octaweb-like placement
            translate([fs_engine_peripheral_offset, 0, 0])
                rotate([7.5,0,0]) // Slight outward cant for peripheral engines
                    first_stage_engine();
    }
}

module landing_leg() {
    // Deployed A-frame leg. Rotated into position by parent module.
    // Struts are in leg's local YZ plane, Y is spread, -Z is down.
    body_attach_y_offset = leg_main_strut_length * sin(leg_a_frame_spread_angle) * 0.3; // Adjusted spread logic
    foot_converge_point_z = -leg_main_strut_length / cos(leg_a_frame_spread_angle);

    color(color_metallic_silver) {
        // Strut 1
        hull() {
            translate([0, body_attach_y_offset, 0]) sphere(r=leg_strut_radius*1.1); 
            translate([0, 0, foot_converge_point_z]) sphere(r=leg_strut_radius*0.9); 
        }
        // Strut 2
        hull() {
            translate([0, -body_attach_y_offset, 0]) sphere(r=leg_strut_radius*1.1); 
            translate([0, 0, foot_converge_point_z]) sphere(r=leg_strut_radius*0.9);
        }

        // Footpad (rounded puck shape)
        translate([0, 0, foot_converge_point_z - leg_foot_pad_height / 2]) {
            hull() { 
                cylinder(h = leg_foot_pad_height*0.6, r = leg_foot_pad_radius, center=true);
                sphere(r=leg_foot_pad_radius*0.9, $fn=24); // Rounds top/bottom
                translate([0,0,-leg_foot_pad_height*0.3]) cylinder(r=leg_foot_pad_radius*0.7, h=leg_foot_pad_height*0.4, center=true); // bottom contact plate visual
            }
            // Landing light
            color("White")
                translate([0,0,-leg_foot_pad_height*0.15]) 
                    cylinder(r=leg_light_radius, h=leg_light_height, center=true, $fn=16);
        }
    }
}


module first_stage() {
    base_z_white_section = first_stage_blue_section_height;
    height_white_section = first_stage_white_section_height;
    r_bottom_white_section = radius_at_blue_white_interface;
    r_top_white_section = first_stage_top_radius;

    difference() {
        union() {
            // Lower blue section
            color(color_sapphire_blue)
                cylinder(h = first_stage_blue_section_height, r1 = first_stage_base_radius, r2 = radius_at_blue_white_interface);

            // Upper white section
            translate([0, 0, first_stage_blue_section_height])
                color(color_pearlescent_white)
                    cylinder(h = first_stage_white_section_height, r1 = radius_at_blue_white_interface, r2 = first_stage_top_radius);

            // Longitudinal Conduits/Ridges (on white section)
            conduit_actual_length = height_white_section * conduit_coverage_factor;
            conduit_z_start_abs = base_z_white_section + height_white_section * (1-conduit_coverage_factor)/2;
            
            for (i = [0 : num_conduits-1]) {
                angle = i * 360/num_conduits;
                color(color_pearlescent_white*0.92) // Slightly off-white
                hull(){
                    // Start point of conduit on surface
                    r_s = get_radius_on_taper(conduit_z_start_abs, base_z_white_section, height_white_section, r_bottom_white_section, r_top_white_section);
                    rotate([0,0,angle]) translate([r_s, 0, conduit_z_start_abs]) sphere(r=conduit_radius, $fn=12);
                    
                    // End point of conduit on surface
                    r_e = get_radius_on_taper(conduit_z_start_abs + conduit_actual_length, base_z_white_section, height_white_section, r_bottom_white_section, r_top_white_section);
                    rotate([0,0,angle]) translate([r_e, 0, conduit_z_start_abs + conduit_actual_length]) sphere(r=conduit_radius, $fn=12);
                }
            }
        }
        // Accent lighting groove (example: near top of blue section)
        groove_z = first_stage_blue_section_height * 0.95;
        groove_r = get_radius_on_taper(groove_z, 0, first_stage_blue_section_height, first_stage_base_radius, radius_at_blue_white_interface);

        translate([0,0, groove_z])
            color(color_led_strip_groove)
                rotate_extrude(convexity = 2)
                    translate([groove_r - accent_groove_depth + 0.001, 0, 0])
                        circle(r = accent_groove_width/2, $fn=24); 
    }

    // Stabilizing Fins (4 radially) - Deployed
    fin_deploy_angle_out = 12; // More pronounced deployment
    fin_deploy_angle_down = 18;
    fin_attach_radius_actual = get_radius_on_taper(fin_attachment_z_offset, 0, first_stage_blue_section_height, first_stage_base_radius, radius_at_blue_white_interface) * 0.99;

    for (i = [0:3]) {
        rotate([0, 0, i * 90]) { // Radial placement
             // Attachment point logic needs to consider fin span and angles for visual centering
            translate([fin_attach_radius_actual, 0, fin_attachment_z_offset + fin_root_chord*0.3*sin(fin_deploy_angle_down)]) {
                 rotate([fin_deploy_angle_down, 0, 0]) // Downward tilt
                    rotate([0, -90+fin_deploy_angle_out, 0]) // Orient fin vertically then tilt outwards
                         fin();
            }
        }
    }
    
    // Landing Legs (4 radially)
    leg_attach_z_abs = leg_attachment_point_on_body_z;
    leg_attach_radius_actual = get_radius_on_taper(leg_attach_z_abs, 0, first_stage_blue_section_height, first_stage_base_radius, radius_at_blue_white_interface) * 0.95;
    
    for (i = [0:3]) {
        rotate([0,0, i*90]) { // Radial placement
            translate([leg_attach_radius_actual, 0, leg_attach_z_abs]) {
                 rotate([0,0,-90]) // Align leg's deployment axis (its local X) radially outward
                    rotate([leg_deploy_angle_from_vertical, 0, 0]) // Deploy (tilt leg's local Z downwards/outwards)
                        landing_leg();
            }
        }
    }

    first_stage_propulsion();
}


// --- Rocket Assembly ---
module astraea_rocket() {
    current_z = 0;

    // 1. First Stage (base at Z=0, engines extend below)
    first_stage();
    current_z = current_z + first_stage_total_height;

    // 2. Interstage Adapter
    translate([0, 0, current_z])
        interstage();
    current_z = current_z + interstage_height;

    // 3. Upper Stage
    translate([0, 0, current_z])
        upper_stage();
    current_z = current_z + upper_stage_height;
    
    // 4. Nose Cone / Payload Fairing
    translate([0, 0, current_z])
        nose_cone();
}

// Render the rocket
astraea_rocket();

// Total height calculation (approximate, from engine bells to nose tip):
total_rocket_body_height = first_stage_total_height + interstage_height + upper_stage_height + fairing_height;
// fs_engine_total_height = fs_engine_cc_height + fs_engine_nozzle_height (approx)
approx_total_vehicle_height = total_rocket_body_height + fs_engine_nozzle_height; // Since CC is somewhat inside/at base of stage
echo("Approximate total component height (body stack):", total_rocket_body_height, "m");
echo("Approximate total vehicle height (tip to engine exit):", approx_total_vehicle_height, "m");

