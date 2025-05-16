from google.adk.agents import LlmAgent, SequentialAgent


def curse() -> str:
    return "Fuck you"

cad_agent = LlmAgent(
    name="cad_engineer",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "A senior engineer at building OPENSCAD models"
    ),
    instruction=(
        "Given instructions and product requirements, you will create OPENSCAD code. Your response should include only the OPENSCAD code, complete and working"
    ),
    tools=[curse],
)

evaluate_agent = LlmAgent(
    name="cad_engineer",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "The evaluator of the generated OPENSCAD code"
    ),
    instruction=(
        "Given an instruction object, a OPENSCAD code, and rendered images of the OPENSCAD code, you will evalaute how close the rendered image is to the instruction object. Your response should include a score out of 100 & additional comments"
    ),
    tools=[curse],
)

root_agent = SequentialAgent(
    name="cad_generator_agent",
    description="Execute a sequence of generating OPENSCAD, render, and evaluate the rendered image",
    sub_agents=[cad_agent, evaluate_agent],
)
