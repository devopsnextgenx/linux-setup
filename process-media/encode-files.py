#!/usr/bin/env python3
import os
import sys
import yaml
import shutil
import subprocess
from pathlib import Path
import argparse
from concurrent.futures import ProcessPoolExecutor, as_completed
from multiprocessing import Manager
from tqdm import tqdm
import time

def load_config(config_path="config.yml"):
    with open(config_path, "r") as f:
        return yaml.safe_load(f)

def get_output_path(input_file, input_folder, output_folder, container="mp4"):
    rel_path = input_file.relative_to(input_folder)
    out_path = output_folder / rel_path.with_suffix(f".{container}")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    return out_path

def encode_file(input_file, output_file, ffmpeg_params):
    try:
        if output_file.exists():
            return f"✅ Skipped (already exists): {output_file}"

        cmd = [
            "ffmpeg", "-y", "-i", str(input_file),
            *ffmpeg_params.split(),
            str(output_file)
        ]
        start = time.time()
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
        duration = time.time() - start
        return f"🎬 Encoded: {input_file} -> {output_file} in {duration:.1f}s"
    except subprocess.CalledProcessError:
        return f"❌ Failed: {input_file}"

def dry_run(files_to_encode, ffmpeg_params):
    print("\n📋 Dry run mode:")
    total_size = sum(f.stat().st_size for f in files_to_encode)
    total_gb = total_size / (1024**3)
    print(f"Found {len(files_to_encode)} AVI files needing encoding, total size {total_gb:.2f} GB")

    # Rough time estimate: assume ~0.5x realtime encoding speed
    # (1h video → ~2h encode on medium preset)
    estimated_hours = total_gb * 2  # approx per GB
    print(f"Estimated encoding time: ~{estimated_hours:.1f} hours (medium preset, libx265)\n")

    for f in files_to_encode:
        print(f"   {f}")

def main():
    parser = argparse.ArgumentParser(description="Batch encode AVI to H.265 (HEVC) MP4/MKV")
    parser.add_argument("--config", default="config.yml", help="Path to config.yml")
    parser.add_argument("--clean", action="store_true", help="Delete original AVI files after encoding")
    parser.add_argument("--move", action="store_true", help="Move original AVI files to move_folder")
    parser.add_argument("--dry-run", action="store_true", help="List files and estimate encoding time, no encoding done")
    parser.add_argument("--workers", type=int, default=os.cpu_count(), help="Number of parallel workers (default=CPU count)")
    args = parser.parse_args()

    cfg = load_config(args.config)

    input_folder = Path(cfg["input_folder"]).resolve()
    output_folder = Path(cfg["output_folder"]).resolve()
    ffmpeg_params = cfg.get("ffmpeg_params", "-c:v libx265 -preset medium -crf 23 -c:a aac -b:a 128k")
    container = cfg.get("container", "mp4")  # default mp4, can set mkv
    move_folder = Path(cfg.get("move_folder", "")) if args.move else None

    avi_files = list(input_folder.rglob("*.avi"))

    if not avi_files:
        print("⚠️ No .avi files found.")
        return

    if args.clean:
        for f in avi_files:
            print(f"🗑️ Deleting original: {f}")
            f.unlink()
        return

    if args.move:
        if not move_folder:
            print("❌ move_folder not specified in config.yml")
            sys.exit(1)
        move_folder.mkdir(parents=True, exist_ok=True)
        for f in avi_files:
            dest = move_folder / f.name
            print(f"📦 Moving {f} -> {dest}")
            shutil.move(str(f), str(dest))
        return

    # Default: encode
    files_to_encode = []
    for f in avi_files:
        out_path = get_output_path(f, input_folder, output_folder, container)
        if not out_path.exists():
            files_to_encode.append(f)

    if args.dry_run:
        dry_run(files_to_encode, ffmpeg_params)
        return

    if not files_to_encode:
        print("✅ All files already encoded.")
        return

    print(f"🚀 Starting encoding with {args.workers} workers...\n")

    inprogress = set()

    with ProcessPoolExecutor(max_workers=args.workers) as executor:
        futures = {}
        for f in files_to_encode:
            out = get_output_path(f, input_folder, output_folder, container)
            inprogress.add(f)
            futures[executor.submit(encode_file, f, out, ffmpeg_params)] = f

        for future in tqdm(as_completed(futures), total=len(futures), desc="Encoding", colour="blue"):
            f = futures[future]
            inprogress.remove(f)
            result = future.result()
            print(result)

if __name__ == "__main__":
    main()
