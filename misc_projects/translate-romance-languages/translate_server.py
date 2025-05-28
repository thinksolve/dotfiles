from fastapi import FastAPI
from transformers import MarianMTModel, MarianTokenizer
from pydantic import BaseModel

app = FastAPI()

# Load models for both directions
en_to_romance_model = MarianMTModel.from_pretrained("Helsinki-NLP/opus-mt-en-ROMANCE")
en_to_romance_tokenizer = MarianTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-ROMANCE")

romance_to_en_model = MarianMTModel.from_pretrained("Helsinki-NLP/opus-mt-ROMANCE-en")
romance_to_en_tokenizer = MarianTokenizer.from_pretrained("Helsinki-NLP/opus-mt-ROMANCE-en")

class TranslationRequest(BaseModel):
    text: str
    source_lang: str
    target_lang: str

@app.post("/translate/")
async def translate(request: TranslationRequest):
    direction = f"{request.source_lang}-{request.target_lang}"

    if direction == "en-es" or direction == "en-fr" or direction == "en-it" or direction == "en-pt" or direction == "en-ro":
        tokenizer = en_to_romance_tokenizer
        model = en_to_romance_model
        prefix = f">>{request.target_lang}<< "
        input_text = [prefix + request.text]
    elif direction == "es-en" or direction == "fr-en" or direction == "it-en" or direction == "pt-en" or direction == "ro-en":
        tokenizer = romance_to_en_tokenizer
        model = romance_to_en_model
        input_text = [request.text]
    else:
        return {"error": f"Translation direction {direction} not supported."}

    inputs = tokenizer(input_text, return_tensors="pt", padding=True)
    outputs = model.generate(**inputs)
    translation = tokenizer.decode(outputs[0], skip_special_tokens=True)

    return {"translation": translation}
