import subprocess
import os

def render_scad_multi_angle(scad_file, output_prefix="render", image_size=(800, 600)):
    """
    Renders a SCAD file from multiple predefined angles
    
    Args:
        scad_file (str): Path to the .scad file
        output_prefix (str): Prefix for output filenames
        image_size (tuple): Width and height in pixels
    """
    # Define different camera angles to render from
    # Format: translateX,translateY,translateZ,rotX,rotY,rotZ,distance
    camera_angles = [
        # Front view - increased distance from 100 to 200
        (0, 0, 0, 0, 0, 0, 200),
        # Top view
        (0, 0, 0, 90, 0, 0, 200),
        # Bottom view
        (0, 0, 0, -90, 0, 0, 200),
        # Left side view
        (0, 0, 0, 0, 0, 90, 200),
        # Right side view
        (0, 0, 0, 0, 0, -90, 200),
        # Isometric views - increased distance from 140 to 280
        (0, 0, 0, 35, 0, 25, 280),
        (0, 0, 0, 35, 0, 155, 280),
        (0, 0, 0, 35, 0, -65, 280),
        (0, 0, 0, 35, 0, -155, 280),
    ]
    
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(output_prefix)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Render each angle
    for i, camera in enumerate(camera_angles):
        output_file = f"{output_prefix}_{i+1}.png"
        
        # Convert camera parameters to string
        camera_param = ",".join(map(str, camera))
        
        # Build and execute the OpenSCAD command
        cmd = [
            "openscad",
            "-o", output_file,
            "--render",
            f"--imgsize={image_size[0]},{image_size[1]}",
            f"--camera={camera_param}",
            "--viewall",          # Auto-fit the model in view
            "--autocenter",       # Center the model
            "--colorscheme=Sunset",  # Optional: choose your preferred colorscheme
            scad_file
        ]
        
        print(f"Rendering angle {i+1}/{len(camera_angles)}: {output_file}")
        subprocess.run(cmd)
    
    print(f"Completed rendering {len(camera_angles)} angles")

# Example usage
if __name__ == "__main__":
    render_scad_multi_angle("test_files/cup.scad", "renders/view")