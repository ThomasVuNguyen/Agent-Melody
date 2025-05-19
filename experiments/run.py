import os
from dotenv import load_dotenv
from google import genai
from google.genai import types
from PIL import Image
from io import BytesIO

import re

def sanitize_filename(text):
    # Replace spaces and invalid characters with underscores
    return re.sub(r'[^a-zA-Z0-9_-]', '_', text.strip().replace(' ', '_'))

def create_image_with_gemini(prompt):
    """
    Generates image(s) using Gemini Imagen 3 and saves them as PNG files named after the prompt.
    Args:
        prompt (str): The text prompt to generate the image.
    Returns:
        list: List of saved image filenames.
    """
    # Load environment variables from .env file
    load_dotenv(os.path.join(os.path.dirname(__file__), '.env'))
    api_key = os.getenv('GOOGLE_API_KEY')
    if not api_key:
        raise ValueError('GOOGLE_API_KEY not found in environment variables.')

    client = genai.Client(api_key=api_key)
    response = client.models.generate_images(
        model='imagen-3.0-generate-002',
        prompt=prompt,
        config=types.GenerateImagesConfig(number_of_images=1)
    )
    filenames = []
    sanitized_prefix = sanitize_filename(prompt)
    for idx, generated_image in enumerate(response.generated_images):
        image = Image.open(BytesIO(generated_image.image.image_bytes))
        filename = f"{sanitized_prefix}_{idx+1}.png"
        image.save(filename)
        filenames.append(filename)
    return filenames

if __name__ == '__main__':
    create_image_with_gemini("a 3x3 lego block")
    