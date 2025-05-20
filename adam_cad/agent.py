from google.adk.agents import LlmAgent, LoopAgent
from typing import List
from google.adk.models.lite_llm import LiteLlm # For multi-model support
from adam_cad.tools import *

describe_agent = LlmAgent(
    name="describe_agent",
    model="gemini-2.0-flash",
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
    model="gemini-2.0-flash",
    description="Expert at rendering OpenSCAD code from multiple angles.",
    instruction="Given OpenSCAD code, return a list of image paths for renders from multiple angles. Only return the list of paths.",
    tools=[render_tool],
)

evaluate_agent = LlmAgent(
    name="evaluate_agent",
    model="gemini-2.0-flash",
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

from google.adk.agents import Agent

from pydantic import Field

root_agent = LoopAgent(
    name="loop_agent",
    sub_agents=[
        #describe_agent, 
        cad_agent, polish_agent, render_agent, evaluate_agent],
)
