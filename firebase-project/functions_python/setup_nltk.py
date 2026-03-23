#!/usr/bin/env python3
"""
NLTK Data Setup Script for Firebase Functions

This script downloads the required NLTK corpora for the word enrichment
Firebase Cloud Function. It must be run before deploying the function.

Required corpora:
- wordnet: English WordNet lexical database
- omw-1.4: Open Multilingual WordNet (supports multiple languages)

Usage:
    python setup_nltk.py

The script will:
1. Create the nltk_data directory if it doesn't exist
2. Download required NLTK corpora
3. Verify the installation
"""

import os
import sys
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def setup_nltk_data():
    """Download and setup required NLTK data."""
    
    # Get the directory where this script is located
    script_dir = Path(__file__).parent.absolute()
    nltk_data_path = script_dir / "nltk_data"
    
    # Create nltk_data directory if it doesn't exist
    nltk_data_path.mkdir(exist_ok=True)
    logger.info(f"NLTK data directory: {nltk_data_path}")
    
    # Set NLTK data path environment variable
    os.environ["NLTK_DATA"] = str(nltk_data_path)
    
    try:
        import nltk
        # Add our custom path to NLTK's data path
        nltk.data.path.insert(0, str(nltk_data_path))
    except ImportError:
        logger.error("NLTK is not installed. Please install it first:")
        logger.error("pip install nltk")
        sys.exit(1)
    
    # Required corpora
    required_corpora = [
        'wordnet',          # English WordNet
        'omw-1.4',          # Open Multilingual WordNet
        'brown',            # Brown corpus (POS fallback via universal tagset)
        'universal_tagset', # Universal POS tag mapping used by Brown corpus
    ]
    
    logger.info("Starting NLTK data download...")
    
    for corpus in required_corpora:
        logger.info(f"Downloading {corpus}...")
        try:
            nltk.download(corpus, download_dir=str(nltk_data_path), quiet=False)
            logger.info(f"✓ Successfully downloaded {corpus}")
        except Exception as e:
            logger.error(f"✗ Failed to download {corpus}: {e}")
            sys.exit(1)
    
    logger.info("NLTK data download completed successfully!")
    
    # Verify installation
    verify_installation(nltk_data_path)

def verify_installation(nltk_data_path):
    """Verify that the NLTK data was installed correctly."""
    logger.info("Verifying installation...")
    
    try:
        from nltk.corpus import wordnet
        
        # Test English WordNet
        synsets = wordnet.synsets('test')
        logger.info(f"✓ English WordNet: Found {len(synsets)} synsets for 'test'")
        
        # Test multilingual WordNet (Spanish)
        try:
            synsets_es = wordnet.synsets('test', lang='spa')
            logger.info(f"✓ Spanish WordNet: Found {len(synsets_es)} synsets for 'test'")
        except Exception as e:
            logger.warning(f"⚠ Spanish WordNet test failed: {e}")
        
        # Test multilingual WordNet (French)
        try:
            synsets_fr = wordnet.synsets('test', lang='fra')
            logger.info(f"✓ French WordNet: Found {len(synsets_fr)} synsets for 'test'")
        except Exception as e:
            logger.warning(f"⚠ French WordNet test failed: {e}")
        
        logger.info("✓ Installation verification completed")
        
    except Exception as e:
        logger.error(f"✗ Installation verification failed: {e}")
        sys.exit(1)

def check_disk_space(nltk_data_path):
    """Check if there's enough disk space for NLTK data."""
    import shutil
    
    # NLTK data is approximately 127MB
    required_space = 200 * 1024 * 1024  # 200MB buffer
    
    try:
        free_space = shutil.disk_usage(nltk_data_path.parent).free
        if free_space < required_space:
            logger.warning(f"⚠ Low disk space: {free_space // (1024*1024)}MB available, "
                          f"{required_space // (1024*1024)}MB recommended")
        else:
            logger.info(f"✓ Sufficient disk space: {free_space // (1024*1024)}MB available")
    except Exception as e:
        logger.warning(f"⚠ Could not check disk space: {e}")

def main():
    """Main function."""
    logger.info("NLTK Data Setup Script for Firebase Functions")
    logger.info("=" * 50)
    
    # Check disk space
    script_dir = Path(__file__).parent.absolute()
    nltk_data_path = script_dir / "nltk_data"
    check_disk_space(nltk_data_path)
    
    # Setup NLTK data
    setup_nltk_data()
    
    logger.info("=" * 50)
    logger.info("Setup completed successfully!")
    logger.info("You can now deploy your Firebase Functions.")
    logger.info("")
    logger.info("Next steps:")
    logger.info("1. Test locally: firebase functions:shell")
    logger.info("2. Deploy: firebase deploy --only functions")

if __name__ == "__main__":
    main()
