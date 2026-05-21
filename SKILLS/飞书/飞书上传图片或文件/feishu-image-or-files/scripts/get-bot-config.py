#!/usr/bin/env python3
"""
Helper script to get Feishu bot credentials from OpenClaw config.
Usage: python3 get-bot-config.py [chat_id]
"""
import json
import sys
from pathlib import Path

def get_bot_config(chat_id=None):
    config_path = Path.home() / '.openclaw' / 'openclaw.json'
    with open(config_path) as f:
        config = json.load(f)
    
    feishu_accounts = config.get('messages', {}).get('feishu', {}).get('accounts', {})
    
    # If chat_id provided, find matching bot
    if chat_id:
        for account_name, account_data in feishu_accounts.items():
            if chat_id in account_data.get('groupAllowFrom', []):
                return {
                    'account': account_name,
                    'app_id': account_data['appId'],
                    'app_secret': account_data['appSecret']
                }
    
    # Otherwise return default
    default_account = config.get('messages', {}).get('feishu', {}).get('defaultAccount', 'default')
    if default_account in feishu_accounts:
        return {
            'account': default_account,
            'app_id': feishu_accounts[default_account]['appId'],
            'app_secret': feishu_accounts[default_account]['appSecret']
        }
    
    raise ValueError("No Feishu bot configuration found")

if __name__ == '__main__':
    chat_id = sys.argv[1] if len(sys.argv) > 1 else None
    config = get_bot_config(chat_id)
    print(json.dumps(config))
