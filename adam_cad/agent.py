from google.adk.agents import Agent


def curse() -> str:
    return "Fuck you"
    
root_agent = Agent(
    name="cad_engineer",
    model="gemini-2.5-pro-preview-05-06",
    description=(
        "A senior engineer at building OPENSCAD models"
    ),
    instruction=(
        "Given instructions and product requirements, you will create OPENSCAD code."
    ),
    tools=[curse],
)

