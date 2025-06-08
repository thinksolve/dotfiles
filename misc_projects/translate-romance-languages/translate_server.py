from fastapi import FastAPI
from transformers import MarianMTModel, MarianTokenizer
from pydantic import BaseModel
from typing import Optional
# import fasttext
from langdetect import detect

# lang_model = fasttext.load_model("lid.176.ftz")

# def detect_lang(text: str) -> str:
#     prediction = lang_model.predict(text.strip().replace('\n', ' '), k=1)
#     label = prediction[0][0]  # e.g. '__label__fr'
#     lang_code = label.replace("__label__", "")
#     return lang_code

app = FastAPI()

# Load models for both directions
en_to_romance_model = MarianMTModel.from_pretrained("Helsinki-NLP/opus-mt-en-ROMANCE")
en_to_romance_tokenizer = MarianTokenizer.from_pretrained("Helsinki-NLP/opus-mt-en-ROMANCE")

romance_to_en_model = MarianMTModel.from_pretrained("Helsinki-NLP/opus-mt-ROMANCE-en")
romance_to_en_tokenizer = MarianTokenizer.from_pretrained("Helsinki-NLP/opus-mt-ROMANCE-en")


DEFAULT_SOURCE_LANG="en"
DEFAULT_TARGET_LANG="es"
ROMANCE_LANGUAGES={"es", "fr", "it", "pt", "ro"}

class TranslationRequest(BaseModel):
    text: str
    source_lang: Optional[str] = None
    target_lang: Optional[str] = None
    # source_lang: str
    # target_lang: str


@app.post("/translate/")
async def translate(request: TranslationRequest):
    src = request.source_lang
    tgt = request.target_lang

    # Use langdetect only if source_lang is not provided
    if not src:
        try:
            src = detect(request.text)
        except Exception:
            return {"error": "Could not detect source language and none was provided."}

    # Apply smart defaulting
    if not tgt:
        if src == DEFAULT_SOURCE_LANG:
            tgt = DEFAULT_TARGET_LANG
        elif src in ROMANCE_LANGUAGES:
            tgt = "en"
        else:
            return {"error": f"Cannot determine default target language for detected source: {src}"}

    direction = f"{src}-{tgt}"

    if src == "en" and tgt in ROMANCE_LANGUAGES:
        tokenizer = en_to_romance_tokenizer
        model = en_to_romance_model
        prefix = f">>{tgt}<< "
        input_text = [prefix + request.text]
    elif src in ROMANCE_LANGUAGES and tgt == "en":
        tokenizer = romance_to_en_tokenizer
        model = romance_to_en_model
        input_text = [request.text]
    else:
        return {"error": f"Translation direction {direction} not supported."}

    inputs = tokenizer(input_text, return_tensors="pt", padding=True)
    outputs = model.generate(**inputs)
    translation = tokenizer.decode(outputs[0], skip_special_tokens=True)

    return {"translation": translation}





# async def translate_og(request: TranslationRequest):
#     direction = f"{request.source_lang}-{request.target_lang}"
#
#     if direction == "en-es" or direction == "en-fr" or direction == "en-it" or direction == "en-pt" or direction == "en-ro":
#         tokenizer = en_to_romance_tokenizer
#         model = en_to_romance_model
#         prefix = f">>{request.target_lang}<< "
#         input_text = [prefix + request.text]
#     elif direction == "es-en" or direction == "fr-en" or direction == "it-en" or direction == "pt-en" or direction == "ro-en":
#         tokenizer = romance_to_en_tokenizer
#         model = romance_to_en_model
#         input_text = [request.text]
#     else:
#         return {"error": f"Translation direction {direction} not supported."}
#
#     inputs = tokenizer(input_text, return_tensors="pt", padding=True)
#     outputs = model.generate(**inputs)
#     translation = tokenizer.decode(outputs[0], skip_special_tokens=True)
#
#     return {"translation": translation}
