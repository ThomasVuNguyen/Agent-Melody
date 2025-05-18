from google.adk.agents import LlmAgent, SequentialAgent, LoopAgent
from adam_cad.render import render_scad_multi_angle
import tempfile
import os
import json
from typing import List



def curse() -> str:
    return "Fuck you"


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


describe_agent = LlmAgent(
    name="describe_agent",
    model="gemini-2.5-pro-preview-05-06",
    description="Expert at summarizing and extracting key requirements from a prompt.",
    instruction="You are a requirements analyst. Given a prompt, return a detailed and precise description of the reference object, including all key features, dimensions, and visual style. Only return the description.",
    tools=[],
)

cad_agent = LlmAgent(
    name="cad_engineer",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "A senior engineer at building OPENSCAD models"
    ),
    instruction=(
        "Given instructions and product requirements, you will create OPENSCAD code. Your response should include only the OPENSCAD code, complete and working."
    ),
    tools=[],
)

polish_agent = LlmAgent(
    name="polish_agent",
    model="gemini-2.5-pro-preview-05-06",
    description="Improves and beautifies functional OpenSCAD code, adding curves, fillets, and making the design more visually appealing and manufacturable.",
    instruction=(
        "Given OpenSCAD code and a reference description, improve the design to make it more beautiful, modern, and manufacturable. Add curves, fillets, smooth transitions, and any other aesthetic or ergonomic improvements while keeping all required features. Return only the improved OpenSCAD code."
    ),
    tools=[],
    )

render_agent = LlmAgent(
    name="render_agent",
    model="gemini-2.5-pro-preview-05-06",
    description="Expert at rendering OpenSCAD code from multiple angles.",
    instruction="Given OpenSCAD code, return a list of image paths for renders from multiple angles. Only return the list of paths.",
    tools=[render_tool],
)

evaluate_agent = LlmAgent(
    name="evaluate_agent",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "Extremely strict evaluator for rendered images and OpenSCAD code against the original instruction and reference."
    ),
    instruction=(
        "You are a world-class industrial design reviewer. "
        "Given the instruction, reference description, OpenSCAD code, and rendered images, "
        "evaluate with absolute strictness. "
        "Deduct points for any missing, extra, or ambiguous features, even if minor. "
        "The design must be beautiful, manufacturable, and 3D printable. "
        "Reject any design that is not perfectly to spec, not fully manufacturable, or not aesthetically excellent. "
        "Return a score out of 100 and detailed comments. "
        "Be harsh: only give a score of 90+ if the design is flawless in all respects."
    ),
    tools=[evaluate_tool],
    )

import re
import datetime

def log_step(step: str, input_data, output_data):
    log_dir = "logs"
    os.makedirs(log_dir, exist_ok=True)
    log_path = os.path.join(log_dir, "agent_workflow_steps.log")
    log_entry = {
        "timestamp": datetime.datetime.now().isoformat(),
        "step": step,
        "input": input_data,
        "output": output_data
    }
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(log_entry, ensure_ascii=False) + "\n")


from google.adk.agents import Agent

from pydantic import Field

root_agent = LoopAgent(
    name="loop_agent",
    sub_agents=[
        #describe_agent, 
        cad_agent, polish_agent, render_agent, evaluate_agent],
)
