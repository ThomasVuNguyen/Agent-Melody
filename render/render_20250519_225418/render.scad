// Improved OpenSCAD Model for an 18650 Battery Cell
// Adds fillets, a more detailed positive terminal, and a recessed negative terminal.

// --- Parameters ---
// Basic dimensions for a typical 18650 cell.
cell_diameter = 18.3;      // Diameter of the battery cell in mm.
main_body_length = 65.0;   // Length of the main cylindrical body (can) in mm.

positive_terminal_diameter = 6.0; // Diameter of the positive terminal button in mm.
positive_terminal_height = 1.8;   // Height of the positive terminal button protrusion itself.

// --- Aesthetic and Detail Parameters ---
edge_fillet_radius = 0.4;     // Radius for filleting sharp edges on the main body. Set to 0 for sharp edges.

positive_terminal_base_plate_enabled = true; // Set to false to disable the base plate under the button.
positive_terminal_base_plate_height = 0.25;   // Height of the thin plate under the positive button.
positive_terminal_base_plate_diameter_factor = 1.25; // Factor of positive_terminal_diameter for the base plate diameter.

negative_terminal_recess_enabled = true;    // Set to false for a flat bottom (matching main body profile).
negative_terminal_recess_depth = 0.3;       // Depth of the recess from the main flat bottom surface of the can.
negative_terminal_plate_diameter_factor = 0.75; // Diameter factor of cell_diameter for the recessed negative terminal plate.
negative_terminal_plate_thickness = 0.2;    // Thickness of the visible metallic negative terminal plate.

// --- Appearance ---
cell_body_color = "SteelBlue";   // Color of the battery wrapper/main body
positive_terminal_color = "Silver"; // Color of the positive terminal components
negative_terminal_color = "LightSlateGray"; // Color of the negative terminal plate

// --- Resolution ---
segments = 100; // $fn value for controlling the number of facets in main curved surfaces.
// Detail segments for fillets and smaller features, derived from main segments.
segments_detail = max(24, round(segments / 2)); // Ensure at least 24 segments for details


// --- Modules ---

// Module for a cylinder with a domed top (spherical cap) and flat bottom.
// h_total: total height of the shape.
// d: diameter.
// fn: resolution.
module domed_cylinder(h_total, d, fn) {
    if (h_total < 0.001 || d < 0.001) {
        // Zero height or diameter, draw nothing
    } else {
        radius = d/2;
        if (h_total <= radius) { // Cap is less than or equal to a hemisphere
            // Spherical cap of height h_total and base diameter d.
            // Radius of the sphere that forms this cap:
            sphere_gen_radius = (radius*radius + h_total*h_total) / (2*h_total);
            // Z-offset of this sphere's center so cap base is at z=0 and top at z=h_total:
            sphere_z_offset = h_total - sphere_gen_radius;
            
            translate([0,0,sphere_z_offset]) {
                intersection() {
                    sphere(r=sphere_gen_radius, $fn=fn);
                    // Clipping cylinder to ensure base diameter is d and height is h_total
                    // Positioned so its base is at z=0 (local to translate)
                    translate([0,0,-sphere_z_offset]) 
                        cylinder(h=h_total + 0.01, d=d, $fn=fn); // +0.01 to ensure proper intersection
                }
            }
        } else { // Cap is a hemisphere on top of a cylinder part
            cyl_part_h = h_total - radius; // Height of the cylindrical section
            
            if (cyl_part_h > 0.001) {
                cylinder(h=cyl_part_h, d=d, $fn=fn);
            }
            
            // Hemispherical top
            translate([0,0,cyl_part_h > 0.001 ? cyl_part_h : 0]) {
                difference() { // Create a hemisphere
                    sphere(r=radius, $fn=fn);
                    translate([0,0,-radius-0.005]) // Shifted down for cut plane at z=0 of sphere
                        cube(d*1.1, center=true); // Cutting body for bottom half, ensure it's large enough
                }
            }
        }
    }
}


// --- Battery Cell Construction ---
union() {

    // Determine Z-coordinate of the flat bottom plane of the can (affected by fillet)
    // For a minkowski sum of cylinder and sphere, the overall height is `main_body_length`.
    // The lowest point is z=0. The flat bottom surface starts at z=edge_fillet_radius.
    main_body_flat_bottom_z = (edge_fillet_radius > 0.001) ? edge_fillet_radius : 0;

    // 1. Main Cylindrical Body
    // May have a recess cut for the negative terminal.
    difference() {
        // Base form: cylinder with rounded top/bottom edges (if edge_fillet_radius > 0)
        color(cell_body_color) {
            if (edge_fillet_radius > 0.001) {
                minkowski_core_h = main_body_length - 2*edge_fillet_radius;
                minkowski_core_d = cell_diameter - 2*edge_fillet_radius;

                if (minkowski_core_h > 0.001 && minkowski_core_d > 0.001) {
                     minkowski($fn=segments_detail) { // $fn on minkowski for the combination process
                        cylinder(h=minkowski_core_h, d=minkowski_core_d, $fn=segments);
                        sphere(r=edge_fillet_radius, $fn=segments_detail);
                    }
                } else { // Fillet radius too large for given dimensions
                    echo("Warning: edge_fillet_radius is too large. Drawing simpler shape.");
                    // Fallback: simple cylinder or sphere if dimensions are too small
                    if (main_body_length >= cell_diameter)
                        cylinder(h = main_body_length, d = cell_diameter, $fn = segments);
                    else 
                        sphere(d = cell_diameter, $fn=segments); // Use diameter for sphere if length is smaller
                }
            } else { // No fillet, sharp-edged cylinder
                cylinder(h = main_body_length, d = cell_diameter, $fn = segments);
            }
        }
        
        // Subtract recess for negative terminal from the bottom, if enabled and depth > 0
        if (negative_terminal_recess_enabled && negative_terminal_recess_depth > 0.001) {
            recess_cut_d = cell_diameter * negative_terminal_plate_diameter_factor;
            // The cutter cylinder starts slightly below the main body's flat bottom plane 
            // and extends upwards by recess_depth.
            translate([0,0, main_body_flat_bottom_z - 0.01]) { // -0.01 to ensure clean cut
                 cylinder(h = negative_terminal_recess_depth + 0.02, // +0.02 to ensure clean cut
                          d = recess_cut_d, 
                          $fn = segments_detail);
            }
        }
    }

    // 2. Negative Terminal Plate
    // Drawn if thickness is positive, positioned within recess or on flat bottom.
    if (negative_terminal_plate_thickness > 0.001) {
        color(negative_terminal_color) {
            plate_d = cell_diameter * negative_terminal_plate_diameter_factor;
            
            // Default Z for top surface of plate is the can's flat bottom plane
            plate_z_top_surface = main_body_flat_bottom_z; 
            
            if (negative_terminal_recess_enabled && negative_terminal_recess_depth > 0.001) {
                // If recessed, top surface is deeper into the can
                plate_z_top_surface = main_body_flat_bottom_z + negative_terminal_recess_depth;
            }

            // Position the plate so its top surface is at plate_z_top_surface
            translate([0,0, plate_z_top_surface - negative_terminal_plate_thickness]) {
                cylinder(h = negative_terminal_plate_thickness, 
                         d = plate_d, 
                         $fn = segments_detail);
            }
        }
    }


    // 3. Positive Terminal Assembly
    // Consists of an optional base plate and the button.
    // Sits on top of the main body's flat top surface.
    // Flat top surface Z: main_body_length - edge_fillet_radius (or main_body_length if no fillet)
    main_body_flat_top_z = main_body_length - ((edge_fillet_radius > 0.001) ? edge_fillet_radius : 0);
    
    current_assembly_z = main_body_flat_top_z; // Starting Z for stacking positive terminal parts

    // 3a. Positive Terminal Base Plate (optional)
    if (positive_terminal_base_plate_enabled && positive_terminal_base_plate_height > 0.001) {
        color(positive_terminal_color) {
            base_plate_d = positive_terminal_diameter * positive_terminal_base_plate_diameter_factor;
            if (base_plate_d > 0.001) { // Only draw if it has a positive diameter
                translate([0,0, current_assembly_z]) {
                    cylinder(h = positive_terminal_base_plate_height, 
                             d = base_plate_d, 
                             $fn = segments_detail);
                }
            }
        }
        current_assembly_z += positive_terminal_base_plate_height; // Next part sits on this plate
    }

    // 3b. Positive Terminal Button
    if (positive_terminal_height > 0.001 && positive_terminal_diameter > 0.001) {
        color(positive_terminal_color) {
            translate([0,0, current_assembly_z]) {
                domed_cylinder(h_total = positive_terminal_height, 
                               d       = positive_terminal_diameter, 
                               fn      = segments_detail);
            }
        }
    }
}

// --- Optional: Echo dimensions to console for verification ---
/*
echo(str("18650 Battery Cell Model Generated (Improved):"));
echo(str("  - Cell Nominal Diameter: ", cell_diameter, " mm"));
echo(str("  - Can Nominal Length: ", main_body_length, " mm"));
echo(str("  - Edge Fillet Radius: ", edge_fillet_radius, " mm"));

protrusion_calc_base_z = main_body_length - (edge_fillet_radius > 0.001 ? edge_fillet_radius : 0);
total_positive_protrusion_height = 0;

if (positive_terminal_base_plate_enabled && positive_terminal_base_plate_height > 0.001) {
    if (positive_terminal_diameter * positive_terminal_base_plate_diameter_factor > 0.001) { // if base plate is drawn
        total_positive_protrusion_height += positive_terminal_base_plate_height;
    }
}
if (positive_terminal_height > 0.001 && positive_terminal_diameter > 0.001) {
    total_positive_protrusion_height += positive_terminal_height;
}

true_overall_length = protrusion_calc_base_z + total_positive_protrusion_height;

echo(str("  - Positive Terminal Assembly Protrusion from Can Top Surface: ", total_positive_protrusion_height, " mm"));
echo(str("  - Calculated Overall Cell Length: ", true_overall_length, " mm"));

if (negative_terminal_plate_thickness > 0.001) {
    if (negative_terminal_recess_enabled && negative_terminal_recess_depth > 0.001) {
        echo(str("  - Negative Terminal: Recessed by ", negative_terminal_recess_depth, " mm from can bottom plane. Plate thickness: ", negative_terminal_plate_thickness, " mm"));
    } else {
        echo(str("  - Negative Terminal: Flush with can bottom profile. Plate thickness: ", negative_terminal_plate_thickness, " mm"));
    }
} else {
    echo("  - Negative Terminal: Not explicitly drawn (part of can body).");
}
*/