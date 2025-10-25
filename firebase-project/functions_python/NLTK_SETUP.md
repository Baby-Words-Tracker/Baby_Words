# NLTK Data Setup for Firebase Functions

## Overview

This Firebase Cloud Function requires NLTK (Natural Language Toolkit) data to be available at runtime without internet access. The function uses WordNet and multilingual WordNet corpora for word enrichment.

## Why Pre-download NLTK Data?

Firebase Cloud Functions run in a sandboxed environment where:
- Internet access may be limited or unreliable
- Downloading large datasets during function execution would cause timeouts
- The function needs consistent access to linguistic data

## Required NLTK Data

The function requires the following NLTK corpora:
- `wordnet`: English WordNet lexical database
- `omw-1.4`: Open Multilingual WordNet (supports multiple languages)

## Setup Process

### Option 1: Use the Setup Script (Recommended)

Run the setup script to automatically download all required NLTK data:

```bash
cd firebase-project/functions_python
python setup_nltk.py
```

### Option 2: Manual Download

If you prefer to download manually:

```python
import nltk
import os

# Set the NLTK data path
nltk_data_path = os.path.join(os.path.dirname(__file__), "nltk_data")
os.environ["NLTK_DATA"] = nltk_data_path

# Download required corpora
nltk.download('wordnet', download_dir=nltk_data_path)
nltk.download('omw-1.4', download_dir=nltk_data_path)
```

## Directory Structure

After setup, the directory structure should look like:

```
functions_python/
├── nltk_data/           # NLTK data directory (not in git)
│   ├── corpora/
│   │   ├── wordnet/     # English WordNet
│   │   └── omw-1.4/     # Multilingual WordNet
│   └── ...
├── main.py              # Cloud function code
├── setup_nltk.py        # Setup script
└── NLTK_SETUP.md        # This file
```

## Deployment Considerations

### For Firebase Functions Deployment

1. **Local Development**: Run `python setup_nltk.py` before testing locally
2. **CI/CD Pipeline**: Include the setup script in your deployment pipeline
3. **Manual Deployment**: Run the setup script before deploying to Firebase

### Build Process Integration

You can integrate this into your build process by:

1. Adding a pre-deploy hook in `firebase.json`:
```json
{
  "functions": {
    "predeploy": ["python firebase-project/functions_python/setup_nltk.py"]
  }
}
```

2. Or including it in your deployment script:
```bash
cd firebase-project/functions_python
python setup_nltk.py
firebase deploy --only functions
```

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure you have write permissions in the functions directory
2. **Network Issues**: The script requires internet access to download NLTK data
3. **Disk Space**: NLTK data is approximately 127MB, ensure sufficient disk space

### Verification

To verify the setup worked correctly:

```python
import nltk
import os

nltk_data_path = os.path.join(os.path.dirname(__file__), "nltk_data")
os.environ["NLTK_DATA"] = nltk_data_path
nltk.data.path.insert(0, nltk_data_path)

# Test WordNet access
from nltk.corpus import wordnet
synsets = wordnet.synsets('test')
print(f"Found {len(synsets)} synsets for 'test'")

# Test multilingual WordNet
try:
    synsets_es = wordnet.synsets('test', lang='spa')
    print(f"Found {len(synsets_es)} Spanish synsets for 'test'")
except:
    print("Multilingual WordNet not available")
```

## File Sizes

- Total NLTK data: ~127MB
- WordNet corpus: ~15MB
- Open Multilingual WordNet: ~112MB

## Notes

- The `nltk_data` directory is excluded from version control (see `.gitignore`)
- The setup script is idempotent - running it multiple times is safe
- NLTK data is cached locally after first download
