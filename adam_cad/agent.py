from google.adk.agents import LlmAgent, SequentialAgent
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

render_agent = LlmAgent(
    name="render_agent",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "Renders SCAD models from code and outputs images."
    ),
    instruction=(
        "Given OpenSCAD code, render images from multiple angles using render_tool."
    ),
    tools=[render_tool],
)

evaluate_agent = LlmAgent(
    name="evaluate_agent",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "Evaluates rendered images and OpenSCAD code against the original instruction."
    ),
    instruction=(
        "Given the instruction, OpenSCAD code, and rendered images, evaluate how close the result is to the instruction. Return a score out of 100 and comments."
    ),
    tools=[evaluate_tool],
)

import re

class LoopAgent:
    def __init__(self, cad_agent, render_agent, evaluate_agent, target_score=90, max_iters=5):
        self.cad_agent = cad_agent
        self.render_agent = render_agent
        self.evaluate_agent = evaluate_agent
        self.target_score = target_score
        self.max_iters = max_iters

    def run(self, instruction):
        feedback = ""
        for i in range(self.max_iters):
            # Step 1: Generate code (with feedback if not first round)
            if feedback:
                prompt = f"{instruction}\nFeedback from last evaluation: {feedback}\nPlease improve the design."
            else:
                prompt = instruction
            # Call CAD agent
            openscad_code = self.cad_agent(prompt)
            # Step 2: Render images
            image_paths = self.render_agent(openscad_code)
            # Step 3: Evaluate
            eval_result = self.evaluate_agent(instruction, openscad_code, image_paths)
            score = eval_result.get("score", 0)
            comments = eval_result.get("comments", "")
            feedback = comments
            print(f"Iteration {i+1}: Score = {score}, Feedback = {comments}")
            # Check for success condition
            if score >= self.target_score and re.search(r"all required features satisfied", comments, re.IGNORECASE):
                print("Design evaluated well! Stopping loop.")
                return openscad_code, image_paths, eval_result
        print("Max iterations reached. Returning last result.")
        return openscad_code, image_paths, eval_result

# Example usage:
# loop_agent = LoopAgent(cad_agent, render_agent, evaluate_agent)
# loop_agent.run("Your instruction here")

root_agent = SequentialAgent(
    name="cad_generator_agent",
    description="Execute a sequence: generate OpenSCAD, render images, evaluate result.",
    sub_agents=[cad_agent, render_agent, evaluate_agent],
)
