### encode-files

# Dry run (estimate time, list files)
python3 encode-files.py --config config.yml --dry-run

# Encode with parallel workers
python3 encode-files.py --config config.yml --workers 4

# Clean originals
python3 encode-files.py --config config.yml --clean

# Move originals
python3 encode-files.py --config config.yml --move
