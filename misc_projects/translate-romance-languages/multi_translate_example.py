from transformers import MarianMTModel, MarianTokenizer

src_text = [
    ">>fra<< this is a sentence in english that we want to translate to french",
    ">>por<< This should go to portuguese",
    ">>esp<< And this to Spanish",
]

model_name = "Helsinki-NLP/opus-mt-en-roa"
tokenizer = MarianTokenizer.from_pretrained(model_name)

print("Supported languages:", tokenizer.supported_language_codes)

model = MarianMTModel.from_pretrained(model_name)
inputs = tokenizer(src_text, return_tensors="pt", padding=True)
translated = model.generate(**inputs)

for translation in translated:
    print(tokenizer.decode(translation, skip_special_tokens=True))

