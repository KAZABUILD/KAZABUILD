#!/usr/bin/env python3
"""
Script to seed random prices for components that don't have prices in the database.

This script:
1. Finds all components without prices
2. Generates random prices based on component type
3. Inserts the prices into the ComponentPrices table

Usage:
    py -3.11 seed_random_prices.py ^
  --connection-string "Server=localhost;Database=KAZABUILD_DB;Trusted_Connection=Yes;Encrypt=Yes;TrustServerCertificate=Yes" ^
  --odbc-driver "ODBC Driver 17 for SQL Server"  ^
  --batch-size 1000

"""

import argparse
import logging
import random
import sys
import uuid
from datetime import datetime
from typing import Dict, List, Tuple

try:
    import pyodbc
    from tqdm import tqdm
except ImportError:
    print("Missing dependencies. Please install: pip install pyodbc tqdm", file=sys.stderr)
    sys.exit(1)

# ========================================================================== #
# CONFIGURATION                                                              #
# ========================================================================== #

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# Price ranges for different component types (in PLN)
# Format: (min_price, max_price)
COMPONENT_PRICE_RANGES: Dict[str, Tuple[float, float]] = {
    "CPU": (200.0, 4000.0),
    "GPU": (800.0, 16000.0),
    "MEMORY": (80.0, 2000.0),
    "MOTHERBOARD": (200.0, 3200.0),
    "STORAGE": (120.0, 4000.0),
    "POWER_SUPPLY": (160.0, 2000.0),
    "CASE": (120.0, 2000.0),
    "CASE_FAN": (20.0, 300.0),
    "COOLER": (80.0, 1200.0),
    "MONITOR": (400.0, 8000.0),
}

# Default price range if component type is not found
DEFAULT_PRICE_RANGE = (10.0, 1000.0)

# Default vendor names for random selection
VENDOR_NAMES = [
    "Amazon",
    "Newegg",
    "Best Buy",
    "Micro Center",
    "B&H Photo",
    "TigerDirect",
    "Walmart",
    "Target",
    "Fry's Electronics",
    "Overstock",
]

# Default currency
DEFAULT_CURRENCY = "PLN"

# ========================================================================== #
# DATABASE CLASS                                                             #
# ========================================================================== #


class DatabaseConnection:
    """Manages database connection and queries."""

    def __init__(self, connection_string: str, odbc_driver: str = "ODBC Driver 17 for SQL Server"):
        self.connection_string = connection_string
        self.odbc_driver = odbc_driver
        self.conn = None
        self.cursor = None

    def connect(self):
        """Establish database connection."""
        try:
            # Add ODBC driver to connection string if not present
            conn_str = self.connection_string
            if "Driver=" not in conn_str:
                conn_str = f"Driver={{{self.odbc_driver}}};{conn_str}"

            self.conn = pyodbc.connect(conn_str)
            self.cursor = self.conn.cursor()
            logger.info("Successfully connected to database")
        except pyodbc.Error as e:
            logger.error(f"Failed to connect to database: {e}")
            raise

    def disconnect(self):
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("Database connection closed")

    def execute(self, query: str, params: tuple = ()):
        """Execute a query."""
        if params:
            return self.cursor.execute(query, params)
        return self.cursor.execute(query)

    def executemany(self, query: str, params_list: List[tuple]):
        """Execute a query for multiple sets of parameters."""
        return self.cursor.executemany(query, params_list)

    def fetchall(self):
        """Fetch all results from the last query."""
        return self.cursor.fetchall()

    def commit(self):
        """Commit the current transaction."""
        self.conn.commit()


# ========================================================================== #
# PRICE SEEDING LOGIC                                                        #
# ========================================================================== #


def truncate_string(value: str, max_length: int) -> str:
    """
    Truncate a string to the maximum length.
    
    Args:
        value: String to truncate
        max_length: Maximum allowed length
    
    Returns:
        Truncated string
    """
    if len(value) <= max_length:
        return value
    return value[:max_length - 3] + "..."


def get_price_range(component_type: str) -> Tuple[float, float]:
    """
    Get the price range for a component type.
    
    Args:
        component_type: The type of component (e.g., "CPU", "GPU")
    
    Returns:
        Tuple of (min_price, max_price)
    """
    # Try exact match first
    if component_type in COMPONENT_PRICE_RANGES:
        return COMPONENT_PRICE_RANGES[component_type]
    
    # Try case-insensitive match
    for key, value in COMPONENT_PRICE_RANGES.items():
        if key.upper() == component_type.upper():
            return value
    
    # Return default range
    logger.warning(f"Unknown component type '{component_type}', using default price range")
    return DEFAULT_PRICE_RANGE


def generate_random_price(component_type: str) -> float:
    """
    Generate a random price for a component type.
    
    Args:
        component_type: The type of component
    
    Returns:
        Random price rounded to 2 decimal places
    """
    min_price, max_price = get_price_range(component_type)
    price = random.uniform(min_price, max_price)
    return round(price, 2)


def get_components_without_prices(db: DatabaseConnection) -> List[Tuple[str, str, str]]:
    """
    Get all components that don't have any prices.
    
    Args:
        db: Database connection
    
    Returns:
        List of tuples: (component_id, component_name, component_type)
    """
    query = """
        SELECT c.Id, c.Name, c.Type
        FROM Components c
        WHERE NOT EXISTS (
            SELECT 1
            FROM ComponentPrices cp
            WHERE cp.ComponentId = c.Id
        )
        ORDER BY c.Type, c.Name
    """
    
    db.execute(query)
    results = db.fetchall()
    
    components = []
    for row in results:
        components.append((str(row.Id), row.Name, row.Type))
    
    return components


def seed_prices_for_components(
    db: DatabaseConnection,
    components: List[Tuple[str, str, str]],
    currency: str = DEFAULT_CURRENCY,
    batch_size: int = 1000
) -> int:
    """
    Seed random prices for a list of components.
    
    Args:
        db: Database connection
        components: List of (component_id, component_name, component_type) tuples
        currency: Currency code (default: USD)
        batch_size: Number of prices to insert per batch
    
    Returns:
        Number of prices inserted
    """
    if not components:
        logger.info("No components without prices found")
        return 0
    
    insert_query = """
        INSERT INTO ComponentPrices
        (Id, SourceUrl, ComponentId, VendorName, FetchedAt, Price, Currency, DatabaseEntryAt, LastEditedAt, Note)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    now = datetime.utcnow()
    price_records = []
    
    logger.info(f"Generating prices for {len(components)} components...")
    
    for component_id, component_name, component_type in tqdm(components, desc="Generating prices"):
        price = generate_random_price(component_type)
        vendor_name = truncate_string(random.choice(VENDOR_NAMES), 50)
        
        # Generate a fake but realistic-looking URL (max 255 chars)
        base_url = f"https://www.{vendor_name.lower().replace(' ', '')}.com/product/{component_id[:8]}"
        source_url = truncate_string(base_url, 255)
        
        # Truncate note to max 255 characters
        note_text = f"Seeded random price for testing - {component_name}"
        note = truncate_string(note_text, 255)
        
        price_id = str(uuid.uuid4())
        
        price_records.append((
            price_id,
            source_url,
            component_id,
            vendor_name,
            now,
            price,
            currency,
            now,
            now,
            note
        ))
    
    # Insert in batches
    logger.info(f"Inserting {len(price_records)} prices into database...")
    total_inserted = 0
    
    for i in tqdm(range(0, len(price_records), batch_size), desc="Inserting prices"):
        batch = price_records[i:i + batch_size]
        db.cursor.fast_executemany = True
        db.executemany(insert_query, batch)
        db.commit()
        total_inserted += len(batch)
    
    logger.info(f"Successfully inserted {total_inserted} prices")
    return total_inserted


# ========================================================================== #
# MAIN                                                                       #
# ========================================================================== #


def main():
    parser = argparse.ArgumentParser(
        description="Seed random prices for components that don't have prices"
    )
    parser.add_argument(
        "--connection-string",
        required=True,
        help="SQL Server connection string (without Driver=)"
    )
    parser.add_argument(
        "--odbc-driver",
        default="ODBC Driver 17 for SQL Server",
        help="ODBC driver name (default: 'ODBC Driver 17 for SQL Server')"
    )
    parser.add_argument(
        "--currency",
        default=DEFAULT_CURRENCY,
        help=f"Currency code (default: PLN)"
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=1000,
        help="Number of prices to insert per batch (default: 1000)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without actually inserting prices"
    )
    
    args = parser.parse_args()
    
    db = DatabaseConnection(args.connection_string, args.odbc_driver)
    
    try:
        db.connect()
        
        # Get components without prices
        logger.info("Finding components without prices...")
        components = get_components_without_prices(db)
        
        if not components:
            logger.info("All components already have prices. Nothing to do.")
            return
        
        # Group by type for reporting
        type_counts: Dict[str, int] = {}
        for _, _, component_type in components:
            type_counts[component_type] = type_counts.get(component_type, 0) + 1
        
        logger.info(f"Found {len(components)} components without prices:")
        for comp_type, count in sorted(type_counts.items()):
            logger.info(f"  {comp_type}: {count}")
        
        if args.dry_run:
            logger.info("DRY RUN: Would generate prices for the above components")
            logger.info("Run without --dry-run to actually insert prices")
            return
        
        # Seed prices
        total_inserted = seed_prices_for_components(
            db,
            components,
            currency=args.currency,
            batch_size=args.batch_size
        )
        
        logger.info(f"✓ Successfully seeded {total_inserted} prices")
        
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        sys.exit(1)
    finally:
        db.disconnect()


if __name__ == "__main__":
    main()

