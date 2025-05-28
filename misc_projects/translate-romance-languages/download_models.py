from transformers import MarianMTModel, MarianTokenizer

models = [
    "Helsinki-NLP/opus-mt-en-ROMANCE",
    "Helsinki-NLP/opus-mt-ROMANCE-en"
]

for model_name in models:
    print(f"Downloading model: {model_name}")
    MarianTokenizer.from_pretrained(model_name)
    MarianMTModel.from_pretrained(model_name)
print("✅ Models are downloaded and cached.")

