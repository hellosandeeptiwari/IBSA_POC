"""
CLEANUP: Remove Old CSV Files Not Used by UI
This script deletes old CSV files that are not loaded by the UI.

UI ONLY USES (KEEP):
1. IBSA_ModelReady_Enhanced_WithPredictions.csv (82.9 MB) - Main production data
2. Reporting_BI_PrescriberProfile_Sample.csv (0.02 MB) - Prescriber profiles
3. competitive_conversion_predictions.csv (48.34 MB) - Competitive intelligence

ALL OTHER CSVs will be deleted.
"""

import os
from pathlib import Path

# Files that UI actually uses - DO NOT DELETE
UI_REQUIRED_FILES = {
    'IBSA_ModelReady_Enhanced_WithPredictions.csv',
    'Reporting_BI_PrescriberProfile_Sample.csv', 
    'competitive_conversion_predictions.csv',
}

def get_file_size_mb(filepath):
    """Get file size in MB"""
    return os.path.getsize(filepath) / (1024 * 1024)

def find_and_delete_unused_csvs():
    """Find and delete CSV files not used by UI"""
    
    project_root = Path(__file__).parent
    ui_data_dir = project_root / 'ibsa_precall_ui' / 'public' / 'data'
    
    # Track what we're doing
    files_to_delete = []
    total_size_mb = 0
    
    print("=" * 80)
    print("SCANNING FOR UNUSED CSV FILES")
    print("=" * 80)
    print(f"\n📁 Scanning directory: {ui_data_dir}")
    print(f"✅ Files UI needs (will KEEP): {len(UI_REQUIRED_FILES)}")
    for f in sorted(UI_REQUIRED_FILES):
        print(f"   • {f}")
    
    if not ui_data_dir.exists():
        print(f"\n❌ UI data directory not found: {ui_data_dir}")
        return
    
    # Find all CSV files in UI data directory
    csv_files = list(ui_data_dir.glob('*.csv'))
    
    print(f"\n📊 Found {len(csv_files)} total CSV files in UI data directory")
    print("\n" + "-" * 80)
    print("FILES TO DELETE (not used by UI):")
    print("-" * 80)
    
    for csv_file in sorted(csv_files):
        filename = csv_file.name
        
        # Skip files that UI needs
        if filename in UI_REQUIRED_FILES:
            continue
        
        # Add to delete list
        size_mb = get_file_size_mb(csv_file)
        files_to_delete.append((csv_file, size_mb))
        total_size_mb += size_mb
        
        print(f"🗑️  {filename:60} ({size_mb:8.2f} MB)")
    
    # Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"📁 Files to keep (UI required):  {len(UI_REQUIRED_FILES)}")
    print(f"🗑️  Files to delete (unused):     {len(files_to_delete)}")
    print(f"💾 Space to reclaim:             {total_size_mb:,.2f} MB")
    
    if not files_to_delete:
        print("\n✅ No unused CSV files found - directory is clean!")
        return
    
    # Confirm deletion
    print("\n" + "=" * 80)
    response = input("⚠️  DELETE these files? (yes/no): ").strip().lower()
    
    if response != 'yes':
        print("❌ Deletion cancelled - no files removed")
        return
    
    # Delete files
    print("\n" + "-" * 80)
    print("DELETING FILES...")
    print("-" * 80)
    
    deleted_count = 0
    deleted_size = 0
    
    for csv_file, size_mb in files_to_delete:
        try:
            csv_file.unlink()
            deleted_count += 1
            deleted_size += size_mb
            print(f"✅ Deleted: {csv_file.name}")
        except Exception as e:
            print(f"❌ Failed to delete {csv_file.name}: {e}")
    
    # Final summary
    print("\n" + "=" * 80)
    print("CLEANUP COMPLETE")
    print("=" * 80)
    print(f"✅ Deleted {deleted_count} files")
    print(f"💾 Reclaimed {deleted_size:,.2f} MB")
    print(f"📁 Kept {len(UI_REQUIRED_FILES)} UI-required files")
    
    print("\n✅ UI data directory is now clean!")
    print(f"📂 Location: {ui_data_dir}")

if __name__ == '__main__':
    find_and_delete_unused_csvs()
