from pathlib import Path

# Verify existence of required model directories for both directions
models = [
    "Helsinki-NLP/opus-mt-en-ROMANCE",
    "Helsinki-NLP/opus-mt-ROMANCE-en"
]

# Check if model directories exist in the transformers cache
cache_dir = Path.home() / ".cache" / "huggingface" / "transformers"

model_dirs = [d for d in cache_dir.glob("**/opus-mt-*") if d.is_dir()]
model_dirs_str = [str(d) for d in model_dirs]

print(model_dirs_str)

