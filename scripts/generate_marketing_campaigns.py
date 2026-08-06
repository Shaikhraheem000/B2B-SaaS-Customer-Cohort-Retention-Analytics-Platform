"""
Script: generate_marketing_campaigns.py
Project: B2B SaaS Customer Cohort & Retention Analytics Platform
Role: Senior Data Engineer / Analytics Engineer
Description: Generates 40 realistic marketing campaigns (marketing_campaigns.csv) 
             and assigns campaign_id foreign keys to customer accounts (data/processed/accounts.csv).
             Guarantees 100% reproducibility via fixed random seed.
"""

import os
import random
import pandas as pd
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple

# Set fixed random seed for reproducibility
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# Project paths
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RAW_DATA_DIR = os.path.join(BASE_DIR, "data", "raw")
PROCESSED_DATA_DIR = os.path.join(BASE_DIR, "data", "processed")

# Channel and type taxonomy
CHANNELS: List[str] = [
    "Google Ads", "LinkedIn", "Facebook", "Organic Search", 
    "Referral", "Partner", "Email", "Webinar", "Conference", "YouTube"
]

CAMPAIGN_TYPES: Dict[str, List[str]] = {
    "Google Ads": ["Search", "Content"],
    "LinkedIn": ["Social", "Content"],
    "Facebook": ["Social"],
    "Organic Search": ["Content"],
    "Referral": ["Referral"],
    "Partner": ["Referral", "Event"],
    "Email": ["Email"],
    "Webinar": ["Event", "Content"],
    "Conference": ["Event"],
    "YouTube": ["Social", "Content"]
}


def generate_campaign_dates() -> Tuple[datetime, Optional[datetime]]:
    """Generates realistic start and end dates within 2023-01-01 to 2025-12-31."""
    start_year = random.choice([2023, 2024, 2025])
    start_month = random.randint(1, 12 if start_year < 2025 else 6)
    start_day = random.randint(1, 28)
    start_date = datetime(start_year, start_month, start_day)
    
    # 25% chance of being an ongoing evergreen campaign (end_date = None)
    if random.random() < 0.25:
        end_date = None
    else:
        duration_days = random.randint(30, 180)
        end_date = start_date + timedelta(days=duration_days)
        if end_date > datetime(2025, 12, 31):
            end_date = datetime(2025, 12, 31)
            
    return start_date, end_date


def generate_campaigns(count: int = 40) -> pd.DataFrame:
    """
    Generates a DataFrame of marketing campaigns following business logic:
    - budget_usd > 0
    - impressions > clicks
    - clicks >= conversions
    """
    campaigns: List[Dict] = []
    
    for i in range(1, count + 1):
        campaign_id = f"CAMP-{i:03d}"
        channel = random.choice(CHANNELS)
        campaign_type = random.choice(CAMPAIGN_TYPES[channel])
        
        start_date, end_date = generate_campaign_dates()
        start_str = start_date.strftime("%Y-%m-%d")
        end_str = end_date.strftime("%Y-%m-%d") if end_date else ""
        
        # Financial & Telemetry Metrics
        budget_usd = round(random.uniform(2500.0, 75000.0), 2)
        impressions = random.randint(50000, 1500000)
        
        # Click-through rate (CTR) between 1% and 12%
        ctr = random.uniform(0.01, 0.12)
        clicks = int(impressions * ctr)
        clicks = max(clicks, 100)
        
        # Conversion rate (CR) between 1.5% and 15%
        cr = random.uniform(0.015, 0.15)
        conversions = int(clicks * cr)
        conversions = max(conversions, 5)
        
        # Descriptive campaign name
        campaign_name = f"{start_date.year}_Q{(start_date.month-1)//3 + 1}_{channel.replace(' ', '')}_{campaign_type}"
        
        campaigns.append({
            "campaign_id": campaign_id,
            "campaign_name": campaign_name,
            "channel": channel,
            "campaign_type": campaign_type,
            "start_date": start_str,
            "end_date": end_str,
            "budget_usd": budget_usd,
            "impressions": impressions,
            "clicks": clicks,
            "conversions": conversions
        })
        
    return pd.DataFrame(campaigns)


def update_accounts_with_campaigns(campaigns_df: pd.DataFrame) -> pd.DataFrame:
    """
    Reads raw accounts data and links each account with a campaign_id based on 
    signup_date proximity or probabilistic channel matching.
    """
    raw_accounts_path = os.path.join(RAW_DATA_DIR, "ravenstack_accounts.csv")
    if not os.path.exists(raw_accounts_path):
        raise FileNotFoundError(f"Raw accounts file not found at {raw_accounts_path}")
        
    accounts_df = pd.read_csv(raw_accounts_path)
    campaign_ids = campaigns_df["campaign_id"].tolist()
    
    # Assign campaign_id deterministically using seeded random choice
    assigned_campaigns = []
    for idx, row in accounts_df.iterrows():
        signup_dt = row["signup_date"]
        matching = campaigns_df[
            (campaigns_df["start_date"] <= signup_dt) & 
            ((campaigns_df["end_date"] >= signup_dt) | (campaigns_df["end_date"] == ""))
        ]
        
        if not matching.empty and random.random() < 0.85:
            selected_cid = random.choice(matching["campaign_id"].tolist())
        else:
            selected_cid = random.choice(campaign_ids)
            
        assigned_campaigns.append(selected_cid)
        
    accounts_df["campaign_id"] = assigned_campaigns
    return accounts_df


def main():
    """Main execution function."""
    print("=" * 70)
    print("Generating B2B SaaS Marketing Campaigns & Updating Accounts...")
    print("=" * 70)
    
    os.makedirs(RAW_DATA_DIR, exist_ok=True)
    os.makedirs(PROCESSED_DATA_DIR, exist_ok=True)
    
    # Task 1: Generate marketing campaigns
    campaigns_df = generate_campaigns(40)
    campaigns_raw_path = os.path.join(RAW_DATA_DIR, "marketing_campaigns.csv")
    campaigns_processed_path = os.path.join(PROCESSED_DATA_DIR, "marketing_campaigns.csv")
    
    campaigns_df.to_csv(campaigns_raw_path, index=False)
    campaigns_df.to_csv(campaigns_processed_path, index=False)
    print(f"[OK] Saved {len(campaigns_df)} marketing campaigns to:")
    print(f"  - {campaigns_raw_path}")
    print(f"  - {campaigns_processed_path}")
    
    # Task 2: Update accounts dataset with campaign_id
    updated_accounts_df = update_accounts_with_campaigns(campaigns_df)
    accounts_processed_path = os.path.join(PROCESSED_DATA_DIR, "accounts.csv")
    updated_accounts_df.to_csv(accounts_processed_path, index=False)
    
    print(f"\n[OK] Updated {len(updated_accounts_df)} customer accounts with campaign_id to:")
    print(f"  - {accounts_processed_path}")
    
    # Copy remaining CSV files to data/processed/ for clean execution
    raw_files_map = {
        "ravenstack_subscriptions.csv": "subscriptions.csv",
        "ravenstack_feature_usage.csv": "feature_usage.csv",
        "ravenstack_support_tickets.csv": "support_tickets.csv",
        "ravenstack_churn_events.csv": "churn_events.csv",
    }
    
    print("\n[OK] Syncing processed dataset directory (data/processed/):")
    for raw_name, proc_name in raw_files_map.items():
        src = os.path.join(RAW_DATA_DIR, raw_name)
        dst = os.path.join(PROCESSED_DATA_DIR, proc_name)
        if os.path.exists(src):
            df = pd.read_csv(src)
            df.to_csv(dst, index=False)
            print(f"  - Cleaned & saved {proc_name} ({len(df)} rows)")
            
    print("\n[OK] All dataset preparation completed successfully.")
    print("=" * 70)


if __name__ == "__main__":
    main()
