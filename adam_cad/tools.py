from google.adk.agents import LlmAgent, SequentialAgent, LoopAgent
from adam_cad.render import render_scad_multi_angle
import tempfile
import os
import json
from typing import List



import datetime

def get_unique_run_folder(prefix: str = "run") -> str:
    """
    Returns a unique subfolder path under 'render/' based on timestamp.
    """
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    base_dir = os.path.join(os.getcwd(), "render")
    run_folder = os.path.join(base_dir, f"{prefix}_{timestamp}")
    os.makedirs(run_folder, exist_ok=True)
    return run_folder


def write_scad_file(openscad_code: str, run_folder: str, prefix: str = "cad_model") -> str:
    """
    Writes OpenSCAD code to a .scad file in the given run_folder and returns the file path.
    """
    scad_file = os.path.join(run_folder, f"{prefix}.scad")
    with open(scad_file, "w") as f:
        f.write(openscad_code)
    return scad_file


def render_tool(openscad_code: str, output_prefix: str = "render") -> List[str]:
    """
    Renders OpenSCAD code from multiple angles and returns a list of image paths, all in a unique subfolder.
    Args:
        openscad_code (str): The OpenSCAD code to render
        output_prefix (str): Prefix for output image files
    Returns:
        List[str]: List of rendered image file paths
    """
    run_folder = get_unique_run_folder(output_prefix)
    scad_file = write_scad_file(openscad_code, run_folder, prefix=output_prefix)
    image_prefix = os.path.abspath(os.path.join(run_folder, output_prefix))
    render_scad_multi_angle(scad_file, image_prefix)
    image_paths = [f"{image_prefix}_{i+1}.png" for i in range(9)]
    return image_paths


def evaluate_tool(instruction: str, openscad_code: str, image_paths: List[str]) -> dict:
    """
    Evaluates the rendered images against the instruction and code.
    Args:
        instruction (str): The user instruction
        openscad_code (str): The OpenSCAD code
        image_paths (List[str]): List of rendered image file paths
    Returns:
        dict: Score and comments
    """
    # Placeholder logic, should be replaced with actual evaluation
    return {
        "score": 100,
        "comments": f"Evaluation complete for images: {json.dumps(image_paths)}"
    }

