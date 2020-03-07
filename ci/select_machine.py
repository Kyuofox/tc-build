#!/usr/bin/env python3

import json
import sys

import requests


# All core datacenters, ranked by latency from the author's location
preferred_locations = (
    "sjc1",
    "dfw2",
    "iad1",
    "ewr1",
    "nrt1",
    "ams1",
    "sin3",
)

preferred_machines = (
    # (type, ondemand_price)
    ("m2.xlarge.x86", 2),
    ("c2.medium.x86", 1),
    ("n2.xlarge.x86", 2.25),
    ("g2.large.x86", 5),
)

if len(sys.argv) > 1:
    token = sys.argv[1]
else:
    print("A Packet API token is required.")
    exit(1)

def check_locations(prices, max_price, locations):
    for loc in locations:
        if loc in prices and prices[loc] < max_price:
            return loc, prices[loc]
    
    return (None, None)

def select_machine():
    for machine, ondemand_price in preferred_machines:
        with requests.get(f"https://api.packet.net/market/spot/prices?plan={machine}", headers={"X-Auth-Token": token}) as r:
            data = r.json()["spot_market_prices"]

        prices = {loc: list(matches.values())[0]["price"] for loc, matches in data.items()}
        max_price = ondemand_price * 10 # 10x == no spot market capacity available
        location, price = check_locations(prices, max_price, preferred_locations)
        if location:
            return {
                "type": machine,
                "location": location,
                "price": str(price * 1.2) # 20% margin to ensure we get enough time to run
                # Stringified because Terraform requires all external values to be strings
            }


result = select_machine()
if not result:
    print("No viable machines found!")
    exit(1)

print(json.dumps(result))
