// Cup dimensions
cup_height_inches = 6;
cup_diameter_inches = 2;
wall_thickness_mm = 3; // Using 3mm as a typical wall thickness

// Convert inches to mm
inch_to_mm = 25.4;
cup_height_mm = cup_height_inches * inch_to_mm;
cup_outer_radius_mm = (cup_diameter_inches / 2) * inch_to_mm;

// Number of fragments for curved surfaces (higher means smoother)
$fn = 100;

// Calculate inner dimensions
cup_inner_radius_mm = cup_outer_radius_mm - wall_thickness_mm;
// The height of the internal void.
// It starts above the base (at wall_thickness_mm) and goes up to the top of the cup.
inner_void_height_mm = cup_height_mm - wall_thickness_mm;

// Create the cup using a difference operation
difference() {
    // Outer cylinder: defines the external shape of the cup
    cylinder(h = cup_height_mm, r = cup_outer_radius_mm);

    // Inner cylinder: defines the hollow part to be subtracted
    // It is translated upwards by wall_thickness_mm to form the base of the cup.
    // A small epsilon (0.1mm) is added to its height to ensure a clean subtraction at the top rim.     
    translate([0, 0, wall_thickness_mm]) {
        cylinder(h = inner_void_height_mm + 0.1, r = cup_inner_radius_mm);
    }
}

// Output dimensions for reference (these are just comments)
// Cup Height: 152.4 mm
// Cup Outer Radius: 25.4 mm
// Cup Inner Radius: 22.4 mm
// Wall Thickness: 3 mm
// Base Thickness: 3 mm