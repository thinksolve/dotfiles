#!/usr/bin/env python3
import sys
from transformers import MarianMTModel, MarianTokenizer

def main():
    if len(sys.argv) < 2:
        print("Usage: multi_translate '>>fra<< Hello world' '>>esp<< How are you?'")
        sys.exit(1)

    src_text = sys.argv[1:]
    model_name = "Helsinki-NLP/opus-mt-en-roa"
    tokenizer = MarianTokenizer.from_pretrained(model_name)
    model = MarianMTModel.from_pretrained(model_name)
    inputs = tokenizer(src_text, return_tensors="pt", padding=True)
    translated = model.generate(**inputs)

    for t in translated:
        print(tokenizer.decode(t, skip_special_tokens=True))

if __name__ == "__main__":
    main()

