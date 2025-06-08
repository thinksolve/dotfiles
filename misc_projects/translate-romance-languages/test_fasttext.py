import fasttext

# Load model once at startup
lang_model = fasttext.load_model("./lid.176.bin")
# lang_model = fasttext.load_model("lid.176.ftz")

def detect_lang(text: str) -> str:
    prediction = lang_model.predict(text.strip().replace('\n', ' '), k=1)
    label = prediction[0][0]  # e.g. '__label__fr'
    lang_code = label.replace("__label__", "")
    return lang_code

print(detect_lang("Comment ça va?"))  # Should return 'fr'
print(detect_lang("comment ca va?"))  # Also likely 'fr'

