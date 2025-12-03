#!/usr/bin/env python3
"""
Bulk importer for OpenDB JSON exports into the KAZABUILD component tables.

The script is designed to be orchestrated from the backend Admin API but can
also be executed manually for local debugging.
note: clone buildcoress opendb dataset from this url https://github.com/buildcores/buildcores-open-db
Usage example:

    py -3.11 import_buildcores.py ^
         --input-dir C:\Users\ziyad\OneDrive\Documents\BUILD_CORES\buildcores-open-db\open-db ^
        --connection-string "Server=LAPTOP-94H43BFK;Database=KAZABUILD_DB;Trusted_Connection=Yes;Encrypt=Yes;TrustServerCertificate=Yes" ^
        --component-types Motherboard ^
        --odbc-driver "ODBC Driver 17 for SQL Server" ^
        --batch-size 10000
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import logging
import os
import pathlib
import re
import uuid
from dataclasses import dataclass, field
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP, getcontext
from typing import Any, Dict, Iterable, Iterator, List, Optional, Sequence, Tuple

try:
    import pyodbc  # type: ignore
except ModuleNotFoundError as exc:  # pragma: no cover - handled at runtime
    pyodbc = None

# ========================================================================== #
# GLOBAL CONSTANTS                                                           #
# ========================================================================== #

getcontext().prec = 16
DECIMAL_DB_LIMIT = Decimal("9999999999999999.99")
SUMMARY_PREFIX = "__IMPORT_SUMMARY__"
"""
Prefix string used to identify import summary output in stdout.

When the script completes successfully, it prints a JSON summary prefixed
with this string. This allows automated tools to parse the output and extract
import statistics.

Type:
    str

Value:
    "__IMPORT_SUMMARY__"
"""
BASE_COLUMNS = [
    "Id",
    "Name",
    "Manufacturer",
    "Release",
    "Type",
    "DatabaseEntryAt",
    "LastEditedAt",
    "Note",
]
"""
List of column names for the base Components table.

These columns are common to all component types and are stored in the
Components table. Component-specific fields are stored in separate tables
(e.g., CPUComponents, GPUComponents).

Type:
    List[str]

Columns:
    - Id: Unique identifier (GUID)
    - Name: Component name
    - Manufacturer: Manufacturer name
    - Release: Release date
    - Type: Component type (CPU, GPU, etc.)
    - DatabaseEntryAt: Timestamp when record was created
    - LastEditedAt: Timestamp when record was last modified
    - Note: Optional administrator/staff note field
"""
BASE_INSERT_SQL = (
    "INSERT INTO Components "
    "(Id, Name, Manufacturer, Release, Type, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
)
"""
SQL statement for inserting records into the base Components table.

This parameterized query inserts the common fields shared by all component
types. Uses ? placeholders for parameter binding to prevent SQL injection.

Type:
    str

Parameters (in order):
    1. Id (GUID string)
    2. Name (string)
    3. Manufacturer (string)
    4. Release (datetime or None)
    5. Type (string)
    6. DatabaseEntryAt (datetime)
    7. LastEditedAt (datetime)
    8. Note (string or None)
"""
COMPONENT_PARTS_INSERT_SQL = (
    "INSERT INTO ComponentParts "
    "(Id, ComponentId, SubComponentId, Amount, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?, ?, ?)"
)
"""
SQL statement for inserting ComponentPart records.

This parameterized query creates relationships between components and their
subcomponents. ComponentPart links a main component to one or more
subcomponents (e.g., a motherboard to its PCIe slots).

Type:
    str

Parameters (in order):
    1. Id (GUID string) - Unique identifier for the ComponentPart
    2. ComponentId (GUID string) - ID of the main component
    3. SubComponentId (GUID string) - ID of the subcomponent
    4. Amount (int) - Number of this subcomponent (1-50)
    5. DatabaseEntryAt (datetime) - Creation timestamp
    6. LastEditedAt (datetime) - Last modification timestamp
    7. Note (string or None) - Optional note
"""
COLOR_INSERT_SQL = (
    "INSERT INTO Colors "
    "(ColorCode, ColorName, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?)"
)
"""
SQL statement for inserting rows into the Colors table.

This parameterized query creates a color entry used by ComponentVariant/ColorVariant
links.

Type:
    str

Parameters (in order):
    1. ColorCode (string) - Hex color code (e.g. '#FFFFFF')
    2. ColorName (string) - Human readable name for the color
    3. DatabaseEntryAt (datetime)
    4. LastEditedAt (datetime)
    5. Note (string or None)
"""

COMPONENT_VARIANT_INSERT_SQL = (
    "INSERT INTO ComponentVariants "
    "(Id, ComponentId, IsAvailable, AdditionalPrice, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?, ?, ?)"
)
"""
SQL for inserting ComponentVariant rows.

ComponentVariant represents a variant of color for a component.
Parameters:
    1. Id (GUID string)
    2. ComponentId (GUID string) - referenced Components.Id
    3. IsAvailable (bool)
    4. AdditionalPrice (decimal or NULL)
    5. DatabaseEntryAt (datetime)
    6. LastEditedAt (datetime)
    7. Note (string or NULL)
"""

COLOR_VARIANT_INSERT_SQL = (
    "INSERT INTO ColorVariants "
    "(Id, ColorCode, ComponentVariantId, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?, ?)"
)
"""
SQL for inserting ColorVariant links.

ColorVariant links a Color (by ColorCode) with a ComponentVariant (by ComponentVariantId).
Parameters:
    1. Id (GUID string)
    2. ColorCode (string) - references Colors.ColorCode
    3. ComponentVariantId (GUID string) - references ComponentVariants.Id
    4. DatabaseEntryAt (datetime)
    5. LastEditedAt (datetime)
    6. Note (string or NULL)
"""

# ========================================================================== #
# EXCEPTIONS                                                                 #
# ========================================================================== #

class SkipRecord(Exception):
    """
    Exception raised when a record should be skipped without aborting the import.
    
    This exception is used to signal that a record cannot be processed (e.g.,
    missing required fields, invalid data) but the import should continue with
    the next record. The record will be counted in the skipped statistics.
    
    Attributes:
        msg (str): Message explaining why the record was skipped.
    
    Example:
        >>> if not required_field:
        ...     raise SkipRecord("Missing required field: name")
    """
    pass

    
# ========================================================================== #
# UTILITY FUNCTIONS                                                          #
# ========================================================================== #

def get_nested(payload: Any, path: str, default: Any = None) -> Any:
    """
    Safely extract a nested value from a dictionary or list using a dot-separated path.
    
    This function navigates through nested structures using a path string like
    "metadata.name" or "specifications.memory.types". Supports both dictionary
    keys and list indices.
    
    Args:
        payload: The data structure to navigate (dict, list, or any value).
        path: Dot-separated path to the desired value (e.g., "metadata.name").
        default: Value to return if any part of the path is missing or invalid.
    
    Returns:
        The value at the specified path, or the default value if not found.
    
    Examples:
        >>> data = {"metadata": {"name": "Intel Core i7"}}
        >>> get_nested(data, "metadata.name")
        'Intel Core i7'
        
        >>> get_nested(data, "metadata.missing", "Unknown")
        'Unknown'
        
        >>> data = {"items": [{"id": 1}, {"id": 2}]}
        >>> get_nested(data, "items.0.id")
        1
    """
    current = payload
    for part in path.split("."):
        if current is None:
            return default
        if isinstance(current, dict):
            current = current.get(part)
        elif isinstance(current, list):
            try:
                current = current[int(part)]
            except (ValueError, IndexError):
                return default
        else:
            return default
    return current if current is not None else default


def clean_text(value: Any, max_length: Optional[int] = None, fallback: str = "") -> str:
    """
    Clean and normalize text values for database storage.
    
    Performs the following operations:
    1. Converts None to fallback value
    2. Converts value to string and strips whitespace
    3. Uses fallback if result is empty
    4. Truncates to max_length if specified (appends "..." if truncated)
    
    Args:
        value: The value to clean (any type, will be converted to string).
        max_length: Maximum allowed length. If None, no truncation is performed.
        fallback: Default value to use if value is None or empty.
    
    Returns:
        Cleaned string value, truncated if necessary.
    
    Examples:
        >>> clean_text("  Hello World  ", max_length=10)
        'Hello W...'
        
        >>> clean_text(None, fallback="Unknown")
        'Unknown'
        
        >>> clean_text("", fallback="Default")
        'Default'
    """
    if value is None:
        value = fallback
    text = str(value).strip()
    if not text:
        text = fallback or ""
    if max_length is not None and len(text) > max_length:
        return text[: max_length - 3] + "..."
    return text


def to_bool(value: Any, default: bool = False) -> bool:
    """
    Convert various input types to a boolean value.
    
    Handles multiple input formats:
    - Boolean values: returned as-is
    - Numeric values: 0/0.0 = False, non-zero = True
    - String values: "true", "1", "yes", "y" = True;
                     "false", "0", "no", "n" = False
    - None: returns default value
    
    Args:
        value: The value to convert to boolean.
        default: Default value to return if conversion fails or value is None.
    
    Returns:
        Boolean representation of the input value.
    
    Examples:
        >>> to_bool("true")
        True
        
        >>> to_bool("0")
        False
        
        >>> to_bool(1)
        True
        
        >>> to_bool(None, default=True)
        True
    """
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(value)
    text = str(value).strip().lower()
    if text in {"true", "1", "yes", "y"}:
        return True
    if text in {"false", "0", "no", "n"}:
        return False
    return default


def to_decimal(
    value: Any,
    multiplier: Decimal | float | int = Decimal(1),
    quantize: Optional[str] = "0.01",
    default: Optional[Decimal] = None,
    *,
    min_value: Optional[Decimal | float | int] = None,
    max_value: Optional[Decimal | float | int] = None,
) -> Optional[Decimal]:
    """
    Convert a value to a Decimal with optional scaling, quantization, and bounds.
    
    This function is used for converting numeric values to database-compatible
    Decimal types with proper precision and range validation. It applies
    multipliers (e.g., for unit conversions), quantizes to specified precision,
    and clamps values to min/max bounds.
    
    Args:
        value: The value to convert (any type that can be converted to Decimal).
        multiplier: Value to multiply by (e.g., 1000 for GHz to MHz conversion).
        quantize: Quantization pattern (e.g., "0.01" for 2 decimal places).
                  If None, no quantization is applied.
        default: Value to return if conversion fails or value is None.
        min_value: Minimum allowed value (values below this are clamped).
        max_value: Maximum allowed value (values above this are clamped).
    
    Returns:
        Decimal value, or default if conversion fails or exceeds database limits.
    
    Examples:
        >>> to_decimal("123.456", quantize="0.01")
        Decimal('123.46')
        
        >>> to_decimal(5.5, multiplier=1000)  # GHz to MHz
        Decimal('5500.00')
        
        >>> to_decimal(100, min_value=0, max_value=50)
        Decimal('50.00')
    """
    if value is None:
        return default
    try:
        dec = Decimal(str(value)) * Decimal(str(multiplier))
        if quantize:
            dec = dec.quantize(Decimal(quantize), rounding=ROUND_HALF_UP)
        if dec is not None:
            if min_value is not None:
                min_dec = Decimal(str(min_value))
                if dec < min_dec:
                    dec = min_dec
            if max_value is not None:
                max_dec = Decimal(str(max_value))
                if dec > max_dec:
                    dec = max_dec
            if dec.as_tuple().exponent < -7:
                dec = dec.quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP)
            if abs(dec) > DECIMAL_DB_LIMIT:
                return default
        return dec
    except (InvalidOperation, ValueError):
        return default


def to_int(
    value: Any,
    default: Optional[int] = None,
    *,
    min_value: Optional[int] = None,
    max_value: Optional[int] = None,
) -> Optional[int]:
    """
    Convert a value to an integer with optional bounds checking.
    
    Converts the input to an integer, optionally clamping it to min/max bounds.
    First converts to float to handle string representations of floats, then
    converts to int.
    
    Args:
        value: The value to convert to integer.
        default: Value to return if conversion fails or value is None.
        min_value: Minimum allowed value (values below this are clamped).
        max_value: Maximum allowed value (values above this are clamped).
    
    Returns:
        Integer value, or default if conversion fails.
    
    Examples:
        >>> to_int("123")
        123
        
        >>> to_int(45.7)
        45
        
        >>> to_int(100, min_value=0, max_value=50)
        50
    """
    if value is None:
        return default
    try:
        number = int(float(value))
        if min_value is not None and number < min_value:
            number = int(min_value)
        if max_value is not None and number > max_value:
            number = int(max_value)
        return number
    except (ValueError, TypeError):
        return default


def parse_year(value: Any) -> Optional[dt.datetime]:
    """
    Convert a year value to a datetime object representing January 1st of that year.
    
    Extracts the year from the input value and creates a datetime object for
    January 1st of that year. Used for component release dates when only the
    year is known.
    
    Args:
        value: Year value (int, string, or any value that can be converted to int).
    
    Returns:
        datetime object for January 1st of the year, or None if invalid.
    
    Examples:
        >>> parse_year(2023)
        datetime.datetime(2023, 1, 1, 0, 0)
        
        >>> parse_year("2020")
        datetime.datetime(2020, 1, 1, 0, 0)
        
        >>> parse_year("invalid")
        None
    """
    year = to_int(value)
    if not year:
        return None
    try:
        return dt.datetime(year, 1, 1)
    except ValueError:
        return None


def extract_number(
    text: Any,
    *,
    quantize: Optional[str] = "0.01",
    min_value: Optional[Decimal | float | int] = None,
    max_value: Optional[Decimal | float | int] = None,
) -> Optional[Decimal]:
    """
    Extract the first numeric value from a text string using regex.
    
    Searches for the first number (integer or decimal) in the input text and
    converts it to a Decimal. Useful for extracting numeric values from
    strings like "100mm" or "2.5 GB/s".
    
    Args:
        text: The text to search for numbers (will be converted to string).
        quantize: Quantization pattern for the result (e.g., "0.01").
        min_value: Minimum allowed value (clamped if below).
        max_value: Maximum allowed value (clamped if above).
    
    Returns:
        Decimal value extracted from text, or None if no number found.
    
    Examples:
        >>> extract_number("100mm")
        Decimal('100.00')
        
        >>> extract_number("Speed: 2.5 GB/s")
        Decimal('2.50')
        
        >>> extract_number("No numbers here")
        None
    """
    if text is None:
        return None
    match = re.search(r"([0-9]+(?:\.[0-9]+)?)", str(text))
    if not match:
        return None
    return to_decimal(
        match.group(1),
        quantize=quantize,
        min_value=min_value,
        max_value=max_value,
    )


def parse_dimensions(payload: Dict[str, Any]) -> Tuple[Optional[Decimal], Optional[Decimal], Optional[Decimal]]:
    """
    Extract depth, height, and width dimensions from component data.
    
    Supports two formats:
    1. Dictionary with "dimensions_mm" containing depth, height, width keys
    2. String format like "100x200x300mm" or "100 x 200 x 300"
    
    Args:
        payload: Dictionary containing dimension data.
    
    Returns:
        Tuple of (depth, height, width) as Decimal values, or (None, None, None)
        if dimensions cannot be parsed.
    
    Examples:
        >>> data = {"dimensions_mm": {"depth": 100, "height": 200, "width": 300}}
        >>> parse_dimensions(data)
        (Decimal('100.00'), Decimal('200.00'), Decimal('300.00'))
        
        >>> data = {"dimensions": "100x200x300mm"}
        >>> parse_dimensions(data)
        (Decimal('100.00'), Decimal('200.00'), Decimal('300.00'))
    """
    dims = payload.get("dimensions_mm")
    if isinstance(dims, dict):
        depth = to_decimal(dims.get("depth"))
        height = to_decimal(dims.get("height"))
        width = to_decimal(dims.get("width"))
        return depth, height, width
    raw = payload.get("dimensions")
    if isinstance(raw, str):
        parts = [p.strip() for p in raw.lower().replace("mm", "").split("x")]
        if len(parts) == 3:
            return tuple(to_decimal(part) for part in parts)  # type: ignore[return-value]
    return None, None, None


def cfm_to_cmm(value: Any) -> Optional[Decimal]:
    """
    Convert cubic feet per minute (CFM) to cubic meters per minute (CMM).
    
    Multiplies the input value by 0.0283168 to convert from CFM to CMM.
    Used for airflow measurements in case fans.
    
    Args:
        value: CFM value to convert (any numeric type or string).
    
    Returns:
        Decimal value in CMM, or None if conversion fails.
    
    Example:
        >>> cfm_to_cmm(100)
        Decimal('2.83')
    """
    return to_decimal(value, multiplier=Decimal("0.0283168"))


def ghz_to_mhz(value: Any) -> Optional[Decimal]:
    """
    Convert gigahertz (GHz) to megahertz (MHz).
    
    Multiplies the input value by 1000 to convert from GHz to MHz.
    Used for CPU and GPU clock speeds.
    
    Args:
        value: GHz value to convert (any numeric type or string).
    
    Returns:
        Decimal value in MHz, or None if conversion fails.
    
    Example:
        >>> ghz_to_mhz(3.5)
        Decimal('3500.00')
    """
    return to_decimal(value, multiplier=Decimal("1000"))


def gb_to_mb(value: Any) -> Optional[Decimal]:
    """
    Convert gigabytes (GB) to megabytes (MB).
    
    Multiplies the input value by 1024 to convert from GB to MB.
    Used for memory and storage capacity conversions.
    
    Args:
        value: GB value to convert (any numeric type or string).
    
    Returns:
        Decimal value in MB, or None if conversion fails.
    
    Example:
        >>> gb_to_mb(16)
        Decimal('16384.00')
    """
    return to_decimal(value, multiplier=Decimal("1024"))


def lbs_to_kg(value: Any) -> Optional[Decimal]:
    """
    Convert pounds (lbs) to kilograms (kg).
    
    Multiplies the input value by 0.45359237 to convert from pounds to kilograms.
    Used for component weight measurements.
    
    Args:
        value: Pounds value to convert (any numeric type or string).
    
    Returns:
        Decimal value in kg, or None if conversion fails.
    
    Example:
        >>> lbs_to_kg(10)
        Decimal('4.54')
    """
    return to_decimal(value, multiplier=Decimal("0.45359237"))


# ========================================================================== #
# DATA CLASSES                                                               #
# ========================================================================== #

@dataclass
class ComponentRecord:
    base: Dict[str, Any]
    specific: Dict[str, Any]


@dataclass
class ComponentStats:
    """
    Statistics tracking for component import operations.
    
    Tracks various metrics during the import process, including counts of
    processed, transformed, inserted, skipped, and duplicate records. Also
    tracks subcomponent processing statistics and ComponentPart creation.
    
    Attributes:
        component_type: Type of component being imported (e.g., "CPU", "GPU").
        file_path: Path to the source file or directory.
        processed: Total number of records processed from source.
        transformed: Number of records successfully transformed.
        inserted: Number of records successfully inserted into database.
        skipped: Number of records skipped (missing fields, invalid data).
        duplicates: Number of duplicate records found (when dedupe is enabled).
        errors: List of error messages encountered during import.
        subcomponents_processed: Total number of subcomponents processed.
        subcomponents_inserted: Number of new subcomponents inserted.
        subcomponents_found: Number of existing subcomponents reused.
        subcomponents_skipped: Number of subcomponents skipped due to errors.
        component_parts_created: Number of ComponentPart relationships created.
    
    Methods:
        as_dict(): Convert statistics to dictionary for JSON serialization.
    """
    component_type: str
    file_path: str
    processed: int = 0
    transformed: int = 0
    inserted: int = 0
    skipped: int = 0
    duplicates: int = 0
    errors: List[str] = field(default_factory=list)
    subcomponents_processed: int = 0
    subcomponents_inserted: int = 0
    subcomponents_found: int = 0
    subcomponents_skipped: int = 0
    component_parts_created: int = 0
    colors_processed: int = 0
    colors_inserted: int = 0
    colors_found: int = 0
    colors_skipped: int = 0
    variants_created: int = 0

    def as_dict(self) -> Dict[str, Any]:
        """
        Convert statistics to a dictionary for JSON serialization.
        
        Returns:
            Dictionary containing all statistics with camelCase keys for JSON output.
        """
        return {
            "componentType": self.component_type,
            "file": self.file_path,
            "processed": self.processed,
            "transformed": self.transformed,
            "inserted": self.inserted,
            "skipped": self.skipped,
            "duplicates": self.duplicates,
            "errors": self.errors,
            "subcomponentsProcessed": self.subcomponents_processed,
            "subcomponentsInserted": self.subcomponents_inserted,
            "subcomponentsFound": self.subcomponents_found,
            "subcomponentsSkipped": self.subcomponents_skipped,
            "componentPartsCreated": self.component_parts_created,
            "colorsProcessed": self.colors_processed,
            "colorsInserted": self.colors_inserted,
            "colorsFound": self.colors_found,
            "colorsSkipped": self.colors_skipped,
            "variantsCreated": self.variants_created,
        }


@dataclass
class ImportContext:
    """
    Context information for the import process.
    
    Stores shared context data used throughout the import, such as the current
    timestamp used for database timestamps.
    
    Attributes:
        now: Current UTC datetime used for DatabaseEntryAt and LastEditedAt fields.
    """
    now: dt.datetime


# ========================================================================== #
# COMPONENT ADAPTER CLASSES                                                  #
# ========================================================================== #

class ComponentAdapter:
    """
    Base class for component adapters that transform OpenDB JSON to database records.
    
    Each component type (CPU, GPU, Motherboard, etc.) has a corresponding adapter
    class that extends this base class. Adapters handle the transformation of raw
    JSON data into structured records suitable for database insertion.
    
    Attributes:
        component_type: String identifier for the component type (e.g., "CPU").
        table_name: Name of the database table for component-specific fields.
        file_stem: Base filename for the component type (e.g., "CPU.json").
        columns: Tuple of column names for the component-specific table.
        required_fields: Tuple of dot-separated paths to required fields in JSON.
        insert_sql: Parameterized SQL INSERT statement (generated in __init__).
    
    Methods:
        __init__(): Initialize the adapter and build the INSERT SQL statement.
        _build_insert_sql(): Build the parameterized SQL INSERT statement.
        transform(): Transform raw JSON into ComponentRecord.
        build_base(): Build common component fields.
        build_specific(): Build component-specific fields (must be overridden).
    """
    component_type: str = ""
    table_name: str = ""
    file_stem: str = ""
    columns: Sequence[str] = ()
    required_fields: Sequence[str] = ("metadata.name",)

    def __init__(self) -> None:
        """
        Initialize the adapter and build the INSERT SQL statement.
        
        Generates the parameterized SQL INSERT statement for the component-specific
        table based on the columns defined in the subclass.
        """
        self.insert_sql = self._build_insert_sql()

    def _build_insert_sql(self) -> str:
        """
        Build the parameterized SQL INSERT statement for the component table.
        
        Returns:
            SQL INSERT statement with ? placeholders for parameter binding.
        """
        placeholders = ", ".join(["?"] * len(self.columns))
        column_list = ", ".join(self.columns)
        return f"INSERT INTO {self.table_name} ({column_list}) VALUES ({placeholders})"

    def transform(self, raw: Dict[str, Any], context: ImportContext) -> ComponentRecord:
        """
        Transform raw JSON data into a ComponentRecord.
        
        Validates required fields, builds base and specific records, and ensures
        all required columns are present in the output.
        
        Args:
            raw: Raw JSON dictionary from OpenDB export.
            context: Import context containing shared data (timestamps, etc.).
        
        Returns:
            ComponentRecord with base and specific data.
        
        Raises:
            SkipRecord: If required fields are missing or columns are invalid.
        """
        missing = [field for field in self.required_fields if get_nested(raw, field) in (None, "")]
        if missing:
            raise SkipRecord(f"Missing required fields: {', '.join(missing)}")
        base = self.build_base(raw, context)
        specific = self.build_specific(raw, context, base)
        for column in self.columns:
            if column not in specific:
                raise SkipRecord(f"Adapter bug: column '{column}' missing from specific payload")
        return ComponentRecord(base=base, specific=specific)

    def build_base(self, raw: Dict[str, Any], context: ImportContext) -> Dict[str, Any]:
        """
        Build the base component record with common fields.
        
        Extracts metadata, generates a unique ID, and creates the base record
        that will be inserted into the Components table.
        
        Args:
            raw: Raw JSON dictionary from OpenDB export.
            context: Import context with current timestamp.
        
        Returns:
            Dictionary with base component fields (Id, Name, Manufacturer, etc.).
        """
        metadata = raw.get("metadata") or {}
        opendb_id = clean_text(raw.get("opendb_id") or "", 60)
        note_parts = []
        if opendb_id:
            note_parts.append(f"OpenDB:{opendb_id}")
        variant = metadata.get("variant")
        if variant:
            note_parts.append(clean_text(variant, 120))
        note = " | ".join(note_parts) if note_parts else None
        release = parse_year(metadata.get("releaseYear"))
        base_id = uuid.uuid4()
        return {
            "Id": base_id,
            "Name": clean_text(metadata.get("name"), 255, fallback="Unnamed Component"),
            "Manufacturer": clean_text(metadata.get("manufacturer"), 50, fallback="Unknown"),
            "Release": release,
            "Type": self.component_type,
            "DatabaseEntryAt": context.now,
            "LastEditedAt": context.now,
            "Note": clean_text(note, 255, fallback="") if note else None,
        }

    def build_specific(self, raw: Dict[str, Any], context: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build component-specific fields (must be implemented by subclasses).
        
        This method is abstract and must be overridden by each component adapter
        to extract and transform component-type-specific fields.
        
        Args:
            raw: Raw JSON dictionary from OpenDB export.
            context: Import context with current timestamp.
            base: Base component record (can be used to reference the component ID).
        
        Returns:
            Dictionary with component-specific fields matching the columns tuple.
        
        Raises:
            NotImplementedError: Must be implemented by subclasses.
        """
        raise NotImplementedError


class CPUAdapter(ComponentAdapter):
    """
    Adapter for transforming CPU component data from OpenDB JSON format.
    
    Handles extraction and transformation of CPU-specific fields including:
    - Core configuration (total, performance, efficiency cores)
    - Clock speeds (base/boost for performance and efficiency cores)
    - Cache sizes (L1, L2, L3, L4)
    - Socket type and memory support
    - TDP and lithography
    
    Required fields in source JSON:
    - metadata.name
    - series
    - microarchitecture
    - coreFamily
    - socket
    - cores.total
    - cores.threads
    - specifications.tdp
    - specifications.lithography
    - specifications.memory.types
    """
    component_type = "CPU"
    table_name = "CPUComponents"
    file_stem = "CPU"
    columns = (
        "Id",
        "Series",
        "Microarchitecture",
        "CoreFamily",
        "SocketType",
        "CoreTotal",
        "PerformanceAmount",
        "EfficiencyAmount",
        "ThreadsAmount",
        "BasePerformanceSpeed",
        "BoostPerformanceSpeed",
        "BaseEfficiencySpeed",
        "BoostEfficiencySpeed",
        "L1",
        "L2",
        "L3",
        "L4",
        "IncludesCooler",
        "Lithography",
        "SupportsSimultaneousMultithreading",
        "MemoryType",
        "PackagingType",
        "SupportsECC",
        "ThermalDesignPower",
    )
    required_fields = (
        "metadata.name",
        "series",
        "microarchitecture",
        "coreFamily",
        "socket",
        "cores.total",
        "cores.threads",
        "specifications.tdp",
        "specifications.lithography",
        "specifications.memory.types",
    )

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        cores = raw.get("cores") or {}
        clocks = raw.get("clocks") or {}
        perf_clock = (clocks.get("performance") or {})
        eff_clock = (clocks.get("efficiency") or {})
        cache = raw.get("cache") or {}
        specs = raw.get("specifications") or {}
        memory = (specs.get("memory") or {})
        mem_types = memory.get("types") or []
        memory_type = mem_types[0] if mem_types else memory.get("type") or "Unknown"
        packaging = specs.get("packaging") or "Unknown"
        return {
            "Id": str(base["Id"]),
            "Series": clean_text(raw.get("series"), 100, fallback="Unknown Series"),
            "Microarchitecture": clean_text(raw.get("microarchitecture"), 100, fallback="Unknown"),
            "CoreFamily": clean_text(raw.get("coreFamily"), 100, fallback="Unknown"),
            "SocketType": clean_text(raw.get("socket"), 50, fallback="Unknown"),
            "CoreTotal": to_int(cores.get("total"), default=0),
            "PerformanceAmount": to_int(cores.get("performance")),
            "EfficiencyAmount": to_int(cores.get("efficiency")),
            "ThreadsAmount": to_int(cores.get("threads"), default=0),
            "BasePerformanceSpeed": to_decimal(
                ghz_to_mhz(perf_clock.get("base")),
                min_value=Decimal("0"),
                max_value=Decimal("10000"),
            ),
            "BoostPerformanceSpeed": to_decimal(
                ghz_to_mhz(perf_clock.get("boost")),
                min_value=Decimal("0"),
                max_value=Decimal("10000"),
            ),
            "BaseEfficiencySpeed": to_decimal(
                ghz_to_mhz(eff_clock.get("base")),
                min_value=Decimal("0"),
                max_value=Decimal("10000"),
            ),
            "BoostEfficiencySpeed": to_decimal(
                ghz_to_mhz(eff_clock.get("boost")),
                min_value=Decimal("0"),
                max_value=Decimal("10000"),
            ),
            "L1": extract_number(
                cache.get("l1"),
                quantize="0.000001",
                min_value=Decimal("0"),
                max_value=Decimal("1024"),
            ),
            "L2": to_decimal(
                cache.get("l2"),
                quantize="0.000001",
                min_value=Decimal("0"),
                max_value=Decimal("5120"),
            ),
            "L3": to_decimal(
                cache.get("l3"),
                quantize="0.000001",
                min_value=Decimal("0"),
                max_value=Decimal("64"),
            ),
            "L4": to_decimal(
                cache.get("l4"),
                quantize="0.000001",
                min_value=Decimal("0"),
                max_value=Decimal("1024"),
            ),
            "IncludesCooler": to_bool(specs.get("includesCooler")),
            "Lithography": clean_text(specs.get("lithography"), 100, fallback="Unknown"),
            "SupportsSimultaneousMultithreading": to_bool(specs.get("simultaneousMultithreading")),
            "MemoryType": clean_text(memory_type, 50, fallback="Unknown"),
            "PackagingType": clean_text(packaging, 50, fallback="Unknown"),
            "SupportsECC": to_bool(specs.get("eccSupport")),
            "ThermalDesignPower": to_decimal(
                specs.get("tdp"),
                min_value=Decimal("0"),
                max_value=Decimal("600"),
            ),
        }


class GPUAdapter(ComponentAdapter):
    """
    Adapter for transforming GPU component data from OpenDB JSON format.
    
    Handles extraction and transformation of GPU-specific fields including:
    - Chipset and chipset manufacturer
    - Video memory (amount and type)
    - Core clock speeds (base and boost)
    - Core count and memory specifications
    - Physical dimensions (length, slot width)
    - Cooling solution type
    - Frame sync technology (G-Sync, FreeSync)
    - Thermal Design Power (TDP)
    
    Also processes video output ports (HDMI, DisplayPort, DVI, VGA) as subcomponents.
    
    Required fields in source JSON:
    - metadata.name
    - chipset
    - memory
    
    Source schema: https://github.com/buildcores/buildcores-open-db/blob/main/schemas/GPU.schema.json
    """
    component_type = "GPU"
    table_name = "GPUComponents"
    file_stem = "GPU"
    columns = (
        "Id",
        "Chipset",
        "VideoMemoryAmount",
        "VideoMemoryType",
        "CoreBaseClockSpeed",
        "CoreBoostClockSpeed",
        "CoreCount",
        "EffectiveMemoryClockSpeed",
        "MemoryBusWidth",
        "FrameSync",
        "Length",
        "ThermalDesignPower",
        "CaseExpansionSlotWidth",
        "TotalSlotAmount",
        "CoolingType",
    )
    required_fields = ("metadata.name", "chipset", "memory")

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        memory_gb = raw.get("memory")
        return {
            "Id": str(base["Id"]),
            "Chipset": clean_text(raw.get("chipset"), 100, fallback="Unknown"),
            "VideoMemoryAmount": gb_to_mb(memory_gb) or Decimal("0"),
            "VideoMemoryType": clean_text(raw.get("memory_type"), 50, fallback="Unknown"),
            "CoreBaseClockSpeed": to_decimal(
                raw.get("core_base_clock"),
                default=Decimal("100"),
                min_value=Decimal("100"),
                max_value=Decimal("8000"),
            ),
            "CoreBoostClockSpeed": to_decimal(
                raw.get("core_boost_clock"),
                default=Decimal("100"),
                min_value=Decimal("100"),
                max_value=Decimal("8000"),
            ),
            "CoreCount": to_int(raw.get("core_count"), default=0),
            "EffectiveMemoryClockSpeed": to_decimal(
                raw.get("effective_memory_clock"),
                default=Decimal("100"),
                min_value=Decimal("100"),
                max_value=Decimal("50000"),
            ),
            "MemoryBusWidth": to_int(
                raw.get("memory_bus"),
                default=32,
                min_value=32,
                max_value=4096,
            ),
            "FrameSync": clean_text(raw.get("frame_sync"), 50, fallback="None"),
            "Length": to_decimal(
                raw.get("length"),
                default=Decimal("10"),
                min_value=Decimal("10"),
                max_value=Decimal("600"),
            ),
            "ThermalDesignPower": to_decimal(
                raw.get("tdp"),
                default=Decimal("1"),
                min_value=Decimal("1"),
                max_value=Decimal("2000"),
            ),
            "CaseExpansionSlotWidth": to_int(
                raw.get("case_expansion_slot_width"),
                default=1,
                min_value=1,
                max_value=10,
            ),
            "TotalSlotAmount": to_int(
                raw.get("total_slot_width"),
                default=1,
                min_value=1,
                max_value=10,
            ),
            "CoolingType": clean_text(raw.get("cooling"), 50, fallback="Unknown"),
        }


class MemoryAdapter(ComponentAdapter):
    """
    Adapter for transforming RAM/Memory component data from OpenDB JSON format.
    
    Handles extraction and transformation of memory-specific fields including:
    - Speed (MHz)
    - RAM type (DDR4, DDR5, etc.)
    - Form factor (DIMM, SODIMM, etc.)
    - Capacity (total and per module)
    - CAS latency and timings
    - Module quantity and capacity
    - ECC support and registered type
    - Physical features (heat spreader, RGB)
    - Height and voltage
    
    Required fields in source JSON:
    - metadata.name
    - speed
    - ram_type
    - form_factor
    - modules.quantity
    - modules.capacity_gb
    - capacity
    - cas_latency
    """
    component_type = "MEMORY"
    table_name = "MemoryComponents"
    file_stem = "RAM"
    columns = (
        "Id",
        "Speed",
        "RAMType",
        "FormFactor",
        "Capacity",
        "CASLatency",
        "Timings",
        "ModuleQuantity",
        "ModuleCapacity",
        "ECC",
        "RegisteredType",
        "HaveHeatSpreader",
        "HaveRGB",
        "Height",
        "Voltage",
    )
    required_fields = (
        "metadata.name",
        "speed",
        "ram_type",
        "form_factor",
        "modules.quantity",
        "modules.capacity_gb",
        "capacity",
        "cas_latency",
    )

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        modules = raw.get("modules") or {}
        module_capacity_mb = gb_to_mb(modules.get("capacity_gb")) or Decimal("0")
        total_capacity = gb_to_mb(raw.get("capacity")) or (module_capacity_mb * to_int(modules.get("quantity"), 0))
        return {
            "Id": str(base["Id"]),
            "Speed": to_decimal(raw.get("speed"), default=Decimal("0")),
            "RAMType": clean_text(raw.get("ram_type"), 50, fallback="Unknown"),
            "FormFactor": clean_text(raw.get("form_factor"), 50, fallback="Unknown"),
            "Capacity": total_capacity,
            "CASLatency": to_decimal(raw.get("cas_latency"), default=Decimal("0")),
            "Timings": clean_text(raw.get("timings"), 50, fallback=""),
            "ModuleQuantity": to_int(modules.get("quantity"), default=1),
            "ModuleCapacity": module_capacity_mb,
            "ECC": clean_text(raw.get("ecc"), 50, fallback="Non-ECC"),
            "RegisteredType": clean_text(raw.get("registered"), 50, fallback="Unbuffered"),
            "HaveHeatSpreader": to_bool(raw.get("heat_spreader")),
            "HaveRGB": to_bool(raw.get("rgb")),
            "Height": to_decimal(raw.get("height")),
            "Voltage": to_decimal(raw.get("voltage")),
        }


class MonitorAdapter(ComponentAdapter):
    """
    Adapter for transforming Monitor component data from OpenDB JSON format.
    
    Handles extraction and transformation of monitor-specific fields including:
    - Screen size (inches)
    - Resolution (horizontal and vertical pixels)
    - Refresh rate (Hz)
    - Panel type (IPS, VA, TN, OLED, etc.)
    - Response time (ms)
    - Viewing angle
    - Aspect ratio
    - Maximum brightness
    - HDR support type
    - Adaptive sync technology (G-Sync, FreeSync)
    
    Also processes video input ports (HDMI, DisplayPort, etc.) as subcomponents.
    
    Required fields in source JSON:
    - metadata.name
    - screen_size
    - resolution.horizontalRes
    - resolution.verticalRes
    - refresh_rate
    - panel_type
    - response_time
    - viewing_angle
    - aspect_ratio
    - adaptive_sync
    """
    component_type = "MONITOR"
    table_name = "MonitorComponents"
    file_stem = "Monitor"
    columns = (
        "Id",
        "ScreenSize",
        "HorizontalResolution",
        "VerticalResolution",
        "MaxRefreshRate",
        "PanelType",
        "ResponseTime",
        "ViewingAngle",
        "AspectRatio",
        "MaxBrightness",
        "HighDynamicRangeType",
        "AdaptiveSyncType",
    )
    required_fields = (
        "metadata.name",
        "screen_size",
        "resolution.horizontalRes",
        "resolution.verticalRes",
        "refresh_rate",
        "panel_type",
        "response_time",
        "viewing_angle",
        "aspect_ratio",
        "adaptive_sync",
    )

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        res = raw.get("resolution") or {}
        return {
            "Id": str(base["Id"]),
            "ScreenSize": to_decimal(raw.get("screen_size"), default=Decimal("0")),
            "HorizontalResolution": to_int(res.get("horizontalRes"), default=0),
            "VerticalResolution": to_int(res.get("verticalRes"), default=0),
            "MaxRefreshRate": to_decimal(raw.get("refresh_rate"), default=Decimal("0")),
            "PanelType": clean_text(raw.get("panel_type"), 50, fallback="Unknown"),
            "ResponseTime": to_decimal(raw.get("response_time"), default=Decimal("0")),
            "ViewingAngle": clean_text(raw.get("viewing_angle"), 20, fallback=""),
            "AspectRatio": clean_text(raw.get("aspect_ratio"), 10, fallback="Unknown"),
            "MaxBrightness": extract_number(raw.get("max_brightness")),
            "HighDynamicRangeType": clean_text(raw.get("hdr"), 50, fallback=""),
            "AdaptiveSyncType": clean_text(raw.get("adaptive_sync"), 50, fallback="None"),
        }


class MotherboardAdapter(ComponentAdapter):
    """
    Adapter for transforming Motherboard component data from OpenDB JSON format.
    
    Handles extraction and transformation of motherboard-specific fields including:
    - Socket type and form factor
    - Chipset type
    - Memory specifications (type, slots, max capacity)
    - Storage interfaces (SATA, U.2 ports)
    - Fan headers (CPU, case, pump, optional)
    - RGB headers (ARGB 5V, RGB 12V)
    - Front panel headers (power button, reset, LEDs)
    - Other headers (temperature sensors, Thunderbolt, COM ports)
    - Power connector type
    - Feature flags (ECC, RAID, BIOS flashback, CMOS clear)
    - Audio chipset and channel count
    - Wireless networking standard
    
    Also processes PCIe slots, M.2 slots, onboard Ethernet, and I/O ports as subcomponents.
    
    Required fields in source JSON:
    - metadata.name
    """
    component_type = "MOTHERBOARD"
    table_name = "MotherboardComponents"
    file_stem = "Motherboard"
    columns = (
        "Id",
        "SocketType",
        "FormFactor",
        "ChipsetType",
        "RAMType",
        "RAMSlotsAmount",
        "MaxRAMAmount",
        "SATA6GBsAmount",
        "SATA3GBsAmount",
        "U2PortAmount",
        "WirelessNetworkingStandard",
        "CPUFanHeaderAmount",
        "CaseFanHeaderAmount",
        "PumpHeaderAmount",
        "CPUOptionalFanHeaderAmount",
        "ARGB5vHeaderAmount",
        "RGB12vHeaderAmount",
        "HasPowerButtonHeader",
        "HasResetButtonHeader",
        "HasPowerLEDHeader",
        "HasHDDLEDHeader",
        "TemperatureSensorHeaderAmount",
        "ThunderboltHeaderAmount",
        "COMPortHeaderAmount",
        "MainPowerType",
        "HasECCSupport",
        "HasRAIDSupport",
        "HasFlashback",
        "HasCMOS",
        "AudioChipset",
        "MaxAudioChannels",
    )
    required_fields = ("metadata.name",)

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        memory = raw.get("memory") or {}
        storage = raw.get("storage_devices") or {}
        fan_headers = raw.get("fan_headers") or {}
        rgb_headers = raw.get("rgb_headers") or {}
        front_panel = raw.get("front_panel_headers") or {}
        other_headers = raw.get("other_headers") or {}
        bios = raw.get("bios_features") or {}
        audio = raw.get("audio") or {}
        return {
            "Id": str(base["Id"]),
            "SocketType": clean_text(raw.get("socket"), 50, fallback="Unknown"),
            "FormFactor": clean_text(raw.get("form_factor"), 50, fallback="Unknown"),
            "ChipsetType": clean_text(raw.get("chipset"), 50, fallback="Unknown"),
            "RAMType": clean_text(memory.get("ram_type"), 50, fallback="Unknown"),
            "RAMSlotsAmount": to_int(memory.get("slots"), default=0),
            "MaxRAMAmount": to_decimal(memory.get("max"), default=Decimal("0")),
            "SATA6GBsAmount": to_int(storage.get("sata_6_gb_s"), default=0),
            "SATA3GBsAmount": to_int(storage.get("sata_3_gb_s"), default=0),
            "U2PortAmount": to_int(storage.get("u2"), default=0),
            "WirelessNetworkingStandard": clean_text(raw.get("wireless_networking"), 50, fallback="None"),
            "CPUFanHeaderAmount": to_int(fan_headers.get("cpu_fan")),
            "CaseFanHeaderAmount": to_int(fan_headers.get("case_fan")),
            "PumpHeaderAmount": to_int(fan_headers.get("pump")),
            "CPUOptionalFanHeaderAmount": to_int(fan_headers.get("cpu_opt")),
            "ARGB5vHeaderAmount": to_int(rgb_headers.get("argb_5v")),
            "RGB12vHeaderAmount": to_int(rgb_headers.get("rgb_12v")),
            "HasPowerButtonHeader": to_bool(front_panel.get("power_button")),
            "HasResetButtonHeader": to_bool(front_panel.get("reset_button")),
            "HasPowerLEDHeader": to_bool(front_panel.get("power_led")),
            "HasHDDLEDHeader": to_bool(front_panel.get("hdd_led")),
            "TemperatureSensorHeaderAmount": to_int(other_headers.get("temperature_sensor")),
            "ThunderboltHeaderAmount": to_int(other_headers.get("thunderbolt")),
            "COMPortHeaderAmount": to_int(other_headers.get("com_port")),
            "MainPowerType": clean_text(get_nested(raw, "power_connectors.main_power"), 50, fallback="24-pin"),
            "HasECCSupport": to_bool(raw.get("ecc_support")),
            "HasRAIDSupport": to_bool(raw.get("raid_support")),
            "HasFlashback": to_bool(bios.get("flashback")),
            "HasCMOS": to_bool(bios.get("clear_cmos")),
            "AudioChipset": clean_text(audio.get("chipset"), 50, fallback="Unknown"),
            "MaxAudioChannels": extract_number(audio.get("channels")) or Decimal("2.0"),
        }


class PowerSupplyAdapter(ComponentAdapter):
    """
    Adapter for transforming Power Supply (PSU) component data from OpenDB JSON format.
    
    Handles extraction and transformation of PSU-specific fields including:
    - Power output (wattage)
    - Form factor (ATX, SFX, etc.)
    - Efficiency rating (80 PLUS certification)
    - Modularity type (Full, Semi-Modular, Non-Modular)
    - Physical dimensions (length)
    - Fanless operation capability
    
    Also processes power connectors (ATX 24-pin, EPS 8-pin, PCIe connectors, SATA, Molex)
    as port subcomponents.
    
    Required fields in source JSON:
    - metadata.name
    - wattage
    - form_factor
    - modular
    - length
    """
    component_type = "POWER_SUPPLY"
    table_name = "PowerSupplyComponents"
    file_stem = "PSU"
    columns = (
        "Id",
        "PowerOutput",
        "FormFactor",
        "EfficiencyRating",
        "ModularityType",
        "Length",
        "IsFanless",
    )
    required_fields = (
        "metadata.name",
        "wattage",
        "form_factor",
        "modular",
        "length",
    )

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "Id": str(base["Id"]),
            "PowerOutput": to_decimal(raw.get("wattage"), default=Decimal("0")),
            "FormFactor": clean_text(raw.get("form_factor"), 50, fallback="Unknown"),
            "EfficiencyRating": clean_text(raw.get("efficiency_rating"), 50, fallback=""),
            "ModularityType": clean_text(raw.get("modular"), 50, fallback="Non-Modular"),
            "Length": to_decimal(raw.get("length")),
            "IsFanless": to_bool(raw.get("fanless")),
        }


class StorageAdapter(ComponentAdapter):
    """
    Adapter for transforming Storage component data from OpenDB JSON format.
    
    Handles extraction and transformation of storage-specific fields including:
    - Series name
    - Capacity (GB)
    - Drive type (SSD, HDD, etc.)
    - Form factor (2.5", M.2, etc.)
    - Interface (SATA, PCIe, etc.)
    - NVMe protocol support
    
    Required fields in source JSON:
    - metadata.name
    - capacity
    - type
    - form_factor
    - interface
    """
    component_type = "STORAGE"
    table_name = "StorageComponents"
    file_stem = "Storage"
    columns = (
        "Id",
        "Series",
        "Capacity",
        "DriveType",
        "FormFactor",
        "Interface",
        "HasNVMe",
    )
    required_fields = (
        "metadata.name",
        "capacity",
        "type",
        "form_factor",
        "interface",
    )

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        metadata = raw.get("metadata") or {}
        capacity = to_decimal(
            raw.get("capacity"),
            quantize="0.000001",
            min_value=Decimal("0"),
            max_value=Decimal("8388608"),
        )
        return {
            "Id": str(base["Id"]),
            "Series": clean_text(metadata.get("series") or metadata.get("name"), 100, fallback="Unknown"),
            "Capacity": capacity or Decimal("0"),
            "DriveType": clean_text(raw.get("type"), 50, fallback="SSD"),
            "FormFactor": clean_text(raw.get("form_factor"), 50, fallback="Unknown"),
            "Interface": clean_text(raw.get("interface"), 50, fallback="Unknown"),
            "HasNVMe": to_bool(raw.get("nvme")),
        }


class CaseAdapter(ComponentAdapter):
    """
    Adapter for transforming PC Case component data from OpenDB JSON format.
    
    Handles extraction and transformation of case-specific fields including:
    - Form factor support
    - Power supply features (shrouded, included count)
    - Side panel type (transparent, material)
    - Maximum component dimensions (GPU length, CPU cooler height)
    - Drive bay counts (internal/external, 3.5"/2.5"/5.25")
    - Expansion slot count
    - Physical dimensions (depth, height, width)
    - Weight
    - Rear-connecting motherboard support
    
    Also processes I/O ports (USB, audio, etc.) as subcomponents.
    
    Required fields in source JSON:
    - metadata.name
    - max_video_card_length
    - max_cpu_cooler_height
    """
    component_type = "CASE"
    table_name = "CaseComponents"
    file_stem = "PCCase"
    columns = (
        "Id",
        "FormFactor",
        "PowerSupplyShrouded",
        "PowerSupplyAmount",
        "HasTransparentSidePanel",
        "SidePanelType",
        "MaxVideoCardLength",
        "MaxCPUCoolerHeight",
        "Internal35BayAmount",
        "Internal25BayAmount",
        "External35BayAmount",
        "External525BayAmount",
        "ExpansionSlotAmount",
        "Dimensions_Depth",
        "Dimensions_Height",
        "Dimensions_Width",
        "Weight",
        "SupportsRearConnectingMotherboard",
    )
    required_fields = (
        "metadata.name",
        "max_video_card_length",
        "max_cpu_cooler_height",
    )

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        depth, height, width = parse_dimensions(raw)
        if not all([depth, height, width]):
            raise SkipRecord("Incomplete dimension data")
        power_supply_amount = extract_number(raw.get("power_supply"))
        return {
            "Id": str(base["Id"]),
            "FormFactor": clean_text(raw.get("form_factor"), 100, fallback="Unknown"),
            "PowerSupplyShrouded": to_bool(raw.get("power_supply_shroud")),
            "PowerSupplyAmount": power_supply_amount,
            "HasTransparentSidePanel": to_bool(raw.get("has_transparent_side_panel")),
            "SidePanelType": clean_text(raw.get("side_panel"), 50, fallback=""),
            "MaxVideoCardLength": to_decimal(raw.get("max_video_card_length"), default=Decimal("0")),
            "MaxCPUCoolerHeight": to_decimal(raw.get("max_cpu_cooler_height"), default=Decimal("0")),
            "Internal35BayAmount": to_int(raw.get("internal_3_5_bays"), default=0),
            "Internal25BayAmount": to_int(raw.get("internal_2_5_bays"), default=0),
            "External35BayAmount": to_int(raw.get("external_3_5_bays"), default=0),
            "External525BayAmount": to_int(raw.get("external_5_25_bays"), default=0),
            "ExpansionSlotAmount": to_int(raw.get("expansion_slots"), default=0),
            "Dimensions_Depth": depth,
            "Dimensions_Height": height,
            "Dimensions_Width": width,
            "Weight": lbs_to_kg(raw.get("weight")) or Decimal("0"),
            "SupportsRearConnectingMotherboard": to_bool(raw.get("supports_rear_connecting_motherboard")),
        }


class CaseFanAdapter(ComponentAdapter):
    """
    Adapter for transforming Case Fan component data from OpenDB JSON format.
    
    Handles extraction and transformation of case fan-specific fields including:
    - Size (mm)
    - Quantity in package
    - Airflow range (min/max in CFM, converted to CMM)
    - Noise level range (min/max in dB)
    - PWM support
    - LED type
    - Connector type
    - Controller type
    - Static pressure
    - Flow direction
    
    Required fields in source JSON:
    - metadata.name
    - size
    - quantity
    - static_pressure
    - flow_direction
    """
    component_type = "CASE_FAN"
    table_name = "CaseFanComponents"
    file_stem = "CaseFan"
    columns = (
        "Id",
        "Size",
        "Quantity",
        "MinAirflow",
        "MaxAirflow",
        "MinNoiseLevel",
        "MaxNoiseLevel",
        "PulseWidthModulation",
        "LEDType",
        "ConnectorType",
        "ControllerType",
        "StaticPressureAmount",
        "FlowDirection",
    )
    required_fields = ("metadata.name", "size", "quantity", "static_pressure", "flow_direction")

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "Id": str(base["Id"]),
            "Size": to_decimal(raw.get("size"), default=Decimal("0")),
            "Quantity": to_int(raw.get("quantity"), default=1),
            "MinAirflow": cfm_to_cmm(raw.get("min_airflow")),
            "MaxAirflow": cfm_to_cmm(raw.get("max_airflow")),
            "MinNoiseLevel": to_decimal(raw.get("min_noise_level")),
            "MaxNoiseLevel": to_decimal(raw.get("max_noise_level")),
            "PulseWidthModulation": to_bool(raw.get("pwm")),
            "LEDType": clean_text(raw.get("led"), 50, fallback=""),
            "ConnectorType": clean_text(raw.get("connector"), 50, fallback=""),
            "ControllerType": clean_text(raw.get("controller"), 50, fallback=""),
            "StaticPressureAmount": to_decimal(raw.get("static_pressure"), default=Decimal("0")),
            "FlowDirection": clean_text(raw.get("flow_direction"), 50, fallback="Standard"),
        }


class CoolerAdapter(ComponentAdapter):
    """
    Adapter for transforming CPU Cooler component data from OpenDB JSON format.
    
    Handles extraction and transformation of cooler-specific fields including:
    - Fan rotation speed range (min/max RPM)
    - Noise level range (min/max dB)
    - Height (mm)
    - Water cooling support
    - Radiator size (for AIO coolers)
    - Fanless operation capability
    - Fan size and quantity
    
    Also processes socket compatibility as CoolerSocketSubComponent subcomponents.
    
    Required fields in source JSON:
    - metadata.name
    - height
    """
    component_type = "COOLER"
    table_name = "CoolerComponents"
    file_stem = "CPUCooler"
    columns = (
        "Id",
        "MinFanRotationSpeed",
        "MaxFanRotationSpeed",
        "MinNoiseLevel",
        "MaxNoiseLevel",
        "Height",
        "IsWaterCooled",
        "RadiatorSize",
        "CanOperateFanless",
        "FanSize",
        "FanQuantity",
    )
    required_fields = ("metadata.name", "height")

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "Id": str(base["Id"]),
            "MinFanRotationSpeed": to_decimal(
                raw.get("min_fan_rpm"),
                min_value=Decimal("0"),
                max_value=Decimal("6000"),
            ),
            "MaxFanRotationSpeed": to_decimal(
                raw.get("max_fan_rpm"),
                min_value=Decimal("0"),
                max_value=Decimal("6000"),
            ),
            "MinNoiseLevel": to_decimal(
                raw.get("min_noise_level"),
                min_value=Decimal("0"),
                max_value=Decimal("100"),
            ),
            "MaxNoiseLevel": to_decimal(
                raw.get("max_noise_level"),
                min_value=Decimal("0"),
                max_value=Decimal("100"),
            ),
            "Height": to_decimal(
                raw.get("height"),
                default=Decimal("0"),
                min_value=Decimal("0"),
                max_value=Decimal("400"),
            ),
            "IsWaterCooled": to_bool(raw.get("water_cooled")),
            "RadiatorSize": to_decimal(
                raw.get("radiator_size"),
                min_value=Decimal("0"),
                max_value=Decimal("1000"),
            ),
            "CanOperateFanless": to_bool(raw.get("fanless")),
            "FanSize": to_decimal(
                raw.get("fan_size"),
                min_value=Decimal("40"),
                max_value=Decimal("500"),
            ),
            "FanQuantity": to_int(
                raw.get("fan_quantity"),
                min_value=0,
                max_value=10,
            ),
        }


ADAPTERS: Dict[str, ComponentAdapter] = {
    adapter.component_type: adapter
    for adapter in [
        CPUAdapter(),
        GPUAdapter(),
        MemoryAdapter(),
        MonitorAdapter(),
        MotherboardAdapter(),
        PowerSupplyAdapter(),
        StorageAdapter(),
        CaseAdapter(),
        CaseFanAdapter(),
        CoolerAdapter(),
    ]
}


# ========================================================================== #
# SUBCOMPONENT ADAPTER CLASSES                                               #
# ========================================================================== #

@dataclass
class SubComponentRecord:
    base: Dict[str, Any]
    specific: Dict[str, Any]


class SubComponentAdapter:
    """
    Base class for subcomponent adapters that transform subcomponent data.
    
    Subcomponents are reusable parts that can be shared between multiple components
    (e.g., a USB port can appear on multiple motherboards). Each subcomponent type
    has an adapter that extends this base class.
    
    Attributes:
        subcomponent_type: String identifier (e.g., "PORT", "PCIE_SLOT").
        base_table_name: Name of the base SubComponents table.
        table_name: Name of the type-specific table (e.g., "PortSubComponents").
        columns: Tuple of column names for the type-specific table.
        required_fields: Tuple of required field paths in JSON.
        base_insert_sql: SQL for inserting into SubComponents table.
        insert_sql: SQL for inserting into type-specific table.
    
    Methods:
        transform(): Transform raw JSON into SubComponentRecord.
        build_base(): Build common subcomponent fields.
        build_specific(): Build type-specific fields (must be overridden).
        _extract_name(): Extract or generate subcomponent name.
    """
    subcomponent_type: str = ""
    base_table_name: str = "SubComponents"
    table_name: str = ""
    columns: Sequence[str] = ()
    required_fields: Sequence[str] = ()

    def __init__(self) -> None:
        """
        Initialize the adapter and build INSERT SQL statements.
        
        Generates both the base SubComponents INSERT statement and the
        type-specific table INSERT statement.
        """
        self.base_insert_sql = self._build_base_insert_sql()
        self.insert_sql = self._build_insert_sql()

    def _build_base_insert_sql(self) -> str:
        """
        Build SQL INSERT statement for the base SubComponents table.
        
        Returns:
            Parameterized SQL INSERT statement for SubComponents.
        """
        return (
            "INSERT INTO SubComponents "
            "(Id, Name, Type, DatabaseEntryAt, LastEditedAt, Note) "
            "VALUES (?, ?, ?, ?, ?, ?)"
        )

    def _build_insert_sql(self) -> str:
        """
        Build SQL INSERT statement for the type-specific subcomponent table.
        
        Returns:
            Parameterized SQL INSERT statement with ? placeholders.
        """
        placeholders = ", ".join(["?"] * len(self.columns))
        column_list = ", ".join(self.columns)
        return f"INSERT INTO {self.table_name} ({column_list}) VALUES ({placeholders})"

    def transform(self, raw: Dict[str, Any], context: ImportContext) -> SubComponentRecord:
        """
        Transform raw JSON data into a SubComponentRecord.
        
        Validates required fields, builds base and specific records.
        
        Args:
            raw: Raw JSON dictionary for the subcomponent.
            context: Import context with current timestamp.
        
        Returns:
            SubComponentRecord with base and specific data.
        
        Raises:
            SkipRecord: If required fields are missing.
        """
        missing = [field for field in self.required_fields if get_nested(raw, field) in (None, "")]
        if missing:
            raise SkipRecord(f"Missing required fields: {', '.join(missing)}")
        base = self.build_base(raw, context)
        specific = self.build_specific(raw, context, base)
        for column in self.columns:
            if column not in specific:
                raise SkipRecord(f"Adapter bug: column '{column}' missing from specific payload")
        return SubComponentRecord(base=base, specific=specific)

    def build_base(self, raw: Dict[str, Any], context: ImportContext) -> Dict[str, Any]:
        """
        Build the base subcomponent record with common fields.
        
        Generates a unique ID and creates the base record for the SubComponents table.
        
        Args:
            raw: Raw JSON dictionary for the subcomponent.
            context: Import context with current timestamp.
        
        Returns:
            Dictionary with base subcomponent fields.
        """
        base_id = uuid.uuid4()
        name = self._extract_name(raw)
        return {
            "Id": base_id,
            "Name": clean_text(name, 255, fallback="Unnamed SubComponent"),
            "Type": self.subcomponent_type,
            "DatabaseEntryAt": context.now,
            "LastEditedAt": context.now,
            "Note": None,
        }

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        """
        Extract or generate the subcomponent name from raw data.
        
        Can be overridden by subclasses to provide custom name extraction logic.
        
        Args:
            raw: Raw JSON dictionary for the subcomponent.
        
        Returns:
            Name string for the subcomponent.
        """
        return raw.get("name") or raw.get("type") or ""

    def build_specific(self, raw: Dict[str, Any], context: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build type-specific subcomponent fields (must be implemented by subclasses).
        
        Args:
            raw: Raw JSON dictionary for the subcomponent.
            context: Import context with current timestamp.
            base: Base subcomponent record (can reference the subcomponent ID).
        
        Returns:
            Dictionary with type-specific fields matching the columns tuple.
        
        Raises:
            NotImplementedError: Must be implemented by subclasses.
        """
        raise NotImplementedError


class PortSubComponentAdapter(SubComponentAdapter):
    """
    Adapter for transforming port subcomponent data (USB, HDMI, DisplayPort, etc.).
    
    Maps port type strings to PortType enum values (USB, VIDEO, POWER, PIN, OTHER).
    Extracts port type from JSON and generates appropriate name if not provided.
    
    Required fields:
    - type (or port_type): Port type identifier
    """
    subcomponent_type = "PORT"
    table_name = "PortSubComponents"
    columns = ("Id", "PortType")
    required_fields = ("type",)

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        port_type = raw.get("type") or raw.get("port_type") or ""
        port_name = raw.get("name") or ""
        if port_name:
            return port_name
        return clean_text(port_type, 255, fallback="Port")

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        port_type_raw = raw.get("type") or raw.get("port_type") or ""
        port_type_str = clean_text(port_type_raw, 50).upper()
        
        port_type_mapping = {
            "USB": "USB",
            "HDMI": "VIDEO",
            "DISPLAYPORT": "VIDEO",
            "DP": "VIDEO",
            "DVI": "VIDEO",
            "VGA": "VIDEO",
            "POWER": "POWER",
            "PIN": "PIN",
        }
        
        port_type = "OTHER"
        for key, value in port_type_mapping.items():
            if key in port_type_str:
                port_type = value
                break
        
        return {
            "Id": str(base["Id"]),
            "PortType": port_type,
        }


class PCIeSlotSubComponentAdapter(SubComponentAdapter):
    """
    Adapter for transforming PCIe slot subcomponent data.
    
    Extracts PCIe generation (e.g., "5.0", "4.0") and lane count (e.g., "x16", "x4").
    Normalizes lane format to ensure it starts with "x".
    
    Required fields:
    - gen (or version, generation): PCIe generation
    - lanes (or lane_count): Number of lanes
    """
    subcomponent_type = "PCIE_SLOT"
    table_name = "PCIeSlotSubComponents"
    columns = ("Id", "Gen", "Lanes")
    required_fields = ("gen", "lanes")

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        gen = raw.get("gen") or ""
        lanes = raw.get("lanes") or ""
        if gen and lanes:
            return f"PCIe {gen} {lanes}"
        return "PCIe Slot"

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        gen = clean_text(raw.get("gen") or raw.get("version") or raw.get("generation"), 5, fallback="Unknown")
        lanes = clean_text(raw.get("lanes") or raw.get("lane_count"), 5, fallback="x1")
        
        if lanes and not lanes.startswith("x"):
            lanes = f"x{lanes}"
        
        return {
            "Id": str(base["Id"]),
            "Gen": gen,
            "Lanes": lanes,
        }


class M2SlotSubComponentAdapter(SubComponentAdapter):
    """
    Adapter for transforming M.2 slot subcomponent data.
    
    Extracts M.2 slot specifications including:
    - Form factor size (e.g., "2280", "22110")
    - Key type (M key, B key, B+M key)
    - Interface specification (e.g., "PCIe 4.0 x4", "SATA")
    
    Normalizes key type format to ensure it includes "Key" suffix.
    
    Required fields:
    - size (or form_factor): M.2 form factor size
    - key_type (or key): Key type identifier
    - interface (or specification): Interface specification
    """
    subcomponent_type = "M2_SLOT"
    table_name = "M2SlotSubcomponents"
    columns = ("Id", "Size", "KeyType", "Interface")
    required_fields = ("size", "key_type", "interface")

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        size = raw.get("size") or ""
        key_type = raw.get("key_type") or ""
        if size and key_type:
            return f"M.2 {size} {key_type}"
        return "M.2 Slot"

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        size = clean_text(raw.get("size") or raw.get("form_factor"), 100, fallback="Unknown")
        key_type = clean_text(raw.get("key_type") or raw.get("key"), 50, fallback="Unknown")
        interface = clean_text(raw.get("interface") or raw.get("specification"), 50, fallback="Unknown")
        
        if key_type and "key" not in key_type.lower():
            key_type = f"{key_type} Key"
        
        return {
            "Id": str(base["Id"]),
            "Size": size,
            "KeyType": key_type,
            "Interface": interface,
        }


class OnboardEthernetSubComponentAdapter(SubComponentAdapter):
    """
    Adapter for transforming onboard Ethernet subcomponent data.
    
    Extracts network specifications including:
    - Speed (e.g., "1 Gbit/s", "2.5 Gbit/s")
    - Controller model (e.g., "Intel I225-V", "Realtek RTL8125")
    
    Generates name from controller and speed if not provided.
    
    Required fields:
    - speed (or network_speed): Ethernet speed specification
    - controller (or network_controller): Network controller model
    """
    subcomponent_type = "ONBOARD_ETHERNET"
    table_name = "OnboardEthernetSubComponents"
    columns = ("Id", "Speed", "Controller")
    required_fields = ("speed", "controller")

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        speed = raw.get("speed") or ""
        controller = raw.get("controller") or ""
        if speed and controller:
            return f"{controller} ({speed})"
        elif speed:
            return f"Ethernet {speed}"
        elif controller:
            return controller
        return "Onboard Ethernet"

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        speed = clean_text(raw.get("speed") or raw.get("network_speed"), 50, fallback="Unknown")
        controller = clean_text(raw.get("controller") or raw.get("network_controller"), 50, fallback="Unknown")
        
        return {
            "Id": str(base["Id"]),
            "Speed": speed,
            "Controller": controller,
        }


class IntegratedGraphicsSubComponentAdapter(SubComponentAdapter):
    """
    Adapter for transforming integrated graphics subcomponent data.
    
    Extracts iGPU specifications including:
    - Model name (e.g., "Intel UHD Graphics 770")
    - Base clock speed (MHz)
    - Boost clock speed (MHz)
    - Core count (shaders/execution units)
    
    Used for CPUs with integrated graphics processors.
    
    Required fields:
    - base_clock (or base_clock_speed): Base clock speed in MHz
    - boost_clock (or boost_clock_speed): Boost clock speed in MHz
    - core_count (or cores): Number of cores/shaders
    """
    subcomponent_type = "INTEGRATED_GRAPHICS"
    table_name = "IntegratedGraphicsSubComponents"
    columns = ("Id", "Model", "BaseClockSpeed", "BoostClockSpeed", "CoreCount")
    required_fields = ("base_clock", "boost_clock", "core_count")

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        """Extract integrated graphics name."""
        model = raw.get("model") or raw.get("name")
        if model:
            return clean_text(model, 255)
        # Generate name from specs
        base_clock = raw.get("base_clock") or raw.get("base_clock_speed")
        return f"Integrated Graphics ({base_clock} MHz)" if base_clock else "Integrated Graphics"

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        model = clean_text(raw.get("model") or raw.get("name"), 100)
        base_clock = to_int(
            raw.get("base_clock") or raw.get("base_clock_speed") or raw.get("baseClockSpeed"),
            default=100,
            min_value=100,
            max_value=10000,
        )
        boost_clock = to_int(
            raw.get("boost_clock") or raw.get("boost_clock_speed") or raw.get("boostClockSpeed"),
            default=100,
            min_value=100,
            max_value=10000,
        )
        core_count = to_int(
            raw.get("core_count") or raw.get("cores") or raw.get("coreCount"),
            default=1,
            min_value=1,
            max_value=50000,
        )
        
        return {
            "Id": str(base["Id"]),
            "Model": model,
            "BaseClockSpeed": base_clock,
            "BoostClockSpeed": boost_clock,
            "CoreCount": core_count,
        }


class CoolerSocketSubComponentAdapter(SubComponentAdapter):
    """
    Adapter for transforming cooler socket compatibility subcomponent data.
    
    Extracts socket type that the cooler is compatible with (e.g., "AM5", "LGA1700", "TR4").
    Used to link CPU coolers to the socket types they support.
    
    Required fields:
    - socket_type (or socket): Socket type identifier
    """
    subcomponent_type = "COOLER_SOCKET"
    table_name = "CoolerSocketSubComponents"
    columns = ("Id", "SocketType")
    required_fields = ("socket_type",)

    def _extract_name(self, raw: Dict[str, Any]) -> str:
        socket_type = raw.get("socket_type") or raw.get("socket") or ""
        if socket_type:
            return clean_text(socket_type, 255)
        return "Unknown Socket"

    def build_specific(self, raw: Dict[str, Any], _: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        socket_type = clean_text(
            raw.get("socket_type") or raw.get("socket") or raw.get("name"),
            50,
            fallback="Unknown"
        )
        
        return {
            "Id": str(base["Id"]),
            "SocketType": socket_type,
        }


SUBCOMPONENT_ADAPTERS: Dict[str, SubComponentAdapter] = {
    adapter.subcomponent_type: adapter
    for adapter in [
        PortSubComponentAdapter(),
        PCIeSlotSubComponentAdapter(),
        M2SlotSubComponentAdapter(),
        OnboardEthernetSubComponentAdapter(),
        IntegratedGraphicsSubComponentAdapter(),
        CoolerSocketSubComponentAdapter(),
    ]
}


# ========================================================================== #
# MAIN IMPORTER CLASS                                                        #
# ========================================================================== #

class BuildCoreImporter:
    """
    Main importer class that orchestrates the import of OpenDB JSON data.
    
    Handles file loading, data transformation, database insertion, and subcomponent
    processing. Manages batching, error handling, and statistics tracking.
    
    Attributes:
        input_dir: Directory containing OpenDB JSON files.
        component_types: List of component types to import.
        batch_size: Number of records to insert per database batch.
        truncate: Whether to delete existing records before importing.
        dry_run: If True, parse and validate without database operations.
        limit: Maximum number of records to process per component type.
        connection_string: SQL Server connection string.
        odbc_driver: ODBC driver name for database connection.
        dedupe: Whether to skip duplicate records within a single import run.
        context: ImportContext with current timestamp.
        stats: List of ComponentStats for each processed component type.
    
    Methods:
        run(): Execute the import process.
        _create_connection(): Create database connection.
        _parse_connection_string(): Parse connection string into components.
        _truncate_types(): Delete existing records for selected component types.
        _process_adapter(): Process all records for a component type.
        _load_records(): Load records from a single JSON file.
        _load_directory_records(): Load records from a directory of JSON files.
        _build_signature(): Create signature for component deduplication.
        _build_subcomponent_signature(): Create signature for subcomponent deduplication.
        _find_existing_subcomponent(): Check if subcomponent already exists.
        _get_subcomponent_base(): Retrieve base subcomponent data from database.
        _get_subcomponent_specific(): Retrieve specific subcomponent data from database.
        _insert_subcomponent(): Insert a new subcomponent into database.
        _insert_component_parts(): Insert ComponentPart relationship records.
        _extract_subcomponents(): Extract subcomponents from component JSON.
        _process_subcomponents(): Process and link subcomponents for a component.
        _flush_batch(): Insert a batch of component records into database.
    """
    def __init__(
        self,
        *,
        input_dir: pathlib.Path,
        component_types: Sequence[str],
        batch_size: int,
        truncate: bool,
        dry_run: bool,
        limit: Optional[int],
        connection_string: Optional[str],
        odbc_driver: str,
        dedupe: bool,
    ) -> None:
        """
        Initialize the importer with configuration parameters.
        
        Args:
            input_dir: Directory containing OpenDB JSON export files.
            component_types: List of component type names to import.
            batch_size: Number of records per database batch insert.
            truncate: If True, delete existing records before importing.
            dry_run: If True, validate without database operations.
            limit: Maximum records to process per component type (None = no limit).
            connection_string: SQL Server connection string (or None to use env var).
            odbc_driver: Name of ODBC driver for SQL Server.
            dedupe: If True, skip duplicate records within this import run.
        """
        self.input_dir = input_dir
        self.component_types = component_types
        self.batch_size = batch_size
        self.truncate = truncate
        self.dry_run = dry_run
        self.limit = limit
        self.connection_string = connection_string
        self.odbc_driver = odbc_driver
        self.dedupe = dedupe
        self.context = ImportContext(now=dt.datetime.utcnow())
        self.stats: List[ComponentStats] = []

    def run(self) -> Dict[str, Any]:
        """
        Execute the complete import process.
        
        Orchestrates the import workflow:
        1. Validates pyodbc availability (unless dry_run)
        2. Selects adapters for requested component types
        3. Creates database connection (unless dry_run)
        4. Optionally truncates existing data
        5. Processes each component type
        6. Collects and returns summary statistics
        
        Returns:
            Dictionary containing import summary with:
            - startedAt: ISO timestamp of import start
            - componentTypes: List of processed component types
            - batchSize: Batch size used
            - dryRun: Whether this was a dry run
            - truncate: Whether truncation was performed
            - results: List of ComponentStats dictionaries
        
        Raises:
            RuntimeError: If pyodbc is missing (and not dry_run) or no valid
                         component types are selected.
        """
        if pyodbc is None and not self.dry_run:
            raise RuntimeError("pyodbc is not installed. Install it or run with --dry-run.")
        selected_adapters = [ADAPTERS[t] for t in self.component_types if t in ADAPTERS]
        if not selected_adapters:
            raise RuntimeError("No valid component types selected.")

        conn = None
        if not self.dry_run:
            conn = self._create_connection()
        try:
            if conn and self.truncate:
                self._truncate_types(conn, selected_adapters)
            for adapter in selected_adapters:
                stats = self._process_adapter(adapter, conn)
                self.stats.append(stats)
        finally:
            if conn:
                conn.close()
        return {
            "startedAt": self.context.now.isoformat() + "Z",
            "componentTypes": self.component_types,
            "batchSize": self.batch_size,
            "dryRun": self.dry_run,
            "truncate": self.truncate,
            "results": [stat.as_dict() for stat in self.stats],
        }

    def _create_connection(self):
        """
        Create and return a SQL Server database connection using pyodbc.
        
        Parses the connection string, extracts connection parameters, and
        constructs an ODBC connection string. Supports both Windows
        authentication and SQL authentication.
        
        Returns:
            pyodbc connection object with autocommit disabled.
        
        Raises:
            RuntimeError: If connection string is missing required parameters
                         (Server, Database) or authentication credentials.
        """
        parts = self._parse_connection_string()
        driver = self.odbc_driver
        server = parts.get("server") or parts.get("data source")
        database = parts.get("database") or parts.get("initial catalog")
        if not server or not database:
            raise RuntimeError("Connection string must include Server and Database.")
        encrypt = parts.get("encrypt", "yes")
        trust_cert = parts.get("trustservercertificate", "true")
        uid = parts.get("user id") or parts.get("uid")
        pwd = parts.get("password") or parts.get("pwd")
        trusted = parts.get("trusted_connection") or parts.get("integrated security")
        if trusted and trusted.lower() in {"true", "yes", "sspi"}:
            auth = "Trusted_Connection=Yes"
        elif uid and pwd:
            auth = f"UID={uid};PWD={pwd}"
        else:
            raise RuntimeError("Connection string must include either credentials or Trusted_Connection.")
        odbc_conn = (
            f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};{auth};"
            f"Encrypt={encrypt};TrustServerCertificate={trust_cert}"
        )
        logging.debug("Using ODBC connection string: %s", odbc_conn)
        conn = pyodbc.connect(odbc_conn, autocommit=False)
        return conn

    def _parse_connection_string(self) -> Dict[str, str]:
        """
        Parse a semicolon-separated connection string into key-value pairs.
        
        Handles connection strings in the format:
        "Server=X;Database=Y;Trusted_Connection=Yes;..."
        
        Falls back to KAZABUILD_CONN_STRING environment variable if connection
        string is not provided.
        
        Returns:
            Dictionary with lowercase keys and trimmed values.
        
        Raises:
            RuntimeError: If connection string is not provided and environment
                         variable is also not set.
        """
        if not self.connection_string:
            env_conn = os.environ.get("KAZABUILD_CONN_STRING")
            if not env_conn:
                raise RuntimeError("Provide --connection-string or set KAZABUILD_CONN_STRING.")
            self.connection_string = env_conn
        parts = {}
        for segment in self.connection_string.split(";"):
            if not segment.strip():
                continue
            if "=" not in segment:
                continue
            key, value = segment.split("=", 1)
            parts[key.strip().lower()] = value.strip()
        return parts

    def _truncate_types(self, conn, adapters: Sequence[ComponentAdapter]) -> None:
        """
        Delete all existing records for the specified component types.
        
        First deletes ComponentPart relationships, then deletes the components
        themselves. This ensures referential integrity is maintained.
        
        Args:
            conn: Database connection object.
            adapters: List of component adapters whose types should be truncated.
        
        Note:
            This operation is irreversible. All data for the specified types
            will be permanently deleted.
        """
        cursor = conn.cursor()
        for adapter in adapters:
            logging.info("Truncating existing %s components", adapter.component_type)
            cursor.execute(
                """
                DELETE cp FROM ComponentParts cp
                INNER JOIN Components c ON cp.ComponentId = c.Id
                WHERE c.Type = ?
                """,
                adapter.component_type
            )
            cursor.execute("DELETE FROM Components WHERE Type = ?", adapter.component_type)
        conn.commit()

    def _process_adapter(self, adapter: ComponentAdapter, conn) -> ComponentStats:
        """
        Process all records for a specific component type.
        
        Loads records from file or directory, transforms them, handles
        deduplication, batches inserts, and processes subcomponents. Tracks
        comprehensive statistics throughout the process.
        
        Args:
            adapter: Component adapter for the component type to process.
            conn: Database connection object (None if dry_run).
        
        Returns:
            ComponentStats object with processing statistics.
        """
        file_path = self.input_dir / f"{adapter.file_stem}.json"
        dir_path = self.input_dir / adapter.file_stem
        stats = ComponentStats(component_type=adapter.component_type, file_path=str(file_path))
        if file_path.exists():
            records = self._load_records(file_path)
        elif dir_path.exists():
            stats.file_path = str(dir_path)
            records = self._load_directory_records(dir_path, stats)
        else:
            stats.errors.append("Source file or directory missing")
            logging.warning(
                "Skipping %s (source not found: %s or %s)",
                adapter.component_type,
                file_path,
                dir_path,
            )
            return stats
        batch: List[Tuple[ComponentRecord, Dict[str, Any]]] = []
        seen_signatures: Optional[set[str]] = set() if self.dedupe else None
        for raw in records:
            stats.processed += 1
            if self.limit and stats.processed > self.limit:
                logging.info("Reached limit %s for %s", self.limit, adapter.component_type)
                break
            try:
                record = adapter.transform(raw, self.context)
                stats.transformed += 1
            except SkipRecord as exc:
                stats.skipped += 1
                logging.debug("Skipping %s record: %s", adapter.component_type, exc)
                continue
            if seen_signatures is not None:
                signature = self._build_signature(record, adapter)
                if signature in seen_signatures:
                    stats.duplicates += 1
                    continue
                seen_signatures.add(signature)
            batch.append((record, raw))
            if not self.dry_run and len(batch) >= self.batch_size:
                try:
                    records_to_insert = [r for r, _ in batch]
                    inserted = self._flush_batch(conn, records_to_insert, adapter)
                    stats.inserted += inserted
                    for rec, rec_raw in batch:
                        try:
                            self._process_subcomponents(conn, rec.base["Id"], rec_raw, adapter.component_type, stats)
                        except Exception as exc:
                            logging.warning(
                                "Error processing subcomponents for component %s: %s",
                                rec.base["Id"],
                                exc
                            )
                        try:
                            self._process_colors(conn, rec.base["Id"], rec_raw, adapter.component_type, stats)
                        except Exception as exc_col:
                            logging.warning(
                                "Error processing colors for component %s: %s",
                                rec.base["Id"],
                                exc_col
                            )
                    batch.clear()
                except Exception as exc:
                    logging.error(
                        "Failed to flush batch for %s: %s. Skipping batch.",
                        adapter.component_type,
                        exc
                    )
                    stats.errors.append(f"Batch insert failed: {exc}")
                    batch.clear() 
        if not self.dry_run and batch:
            try:
                records_to_insert = [r for r, _ in batch]
                stats.inserted += self._flush_batch(conn, records_to_insert, adapter)
                for rec, rec_raw in batch:
                    try:
                        self._process_subcomponents(conn, rec.base["Id"], rec_raw, adapter.component_type, stats)
                    except Exception as exc:
                        logging.warning(
                            "Error processing subcomponents for component %s: %s",
                            rec.base["Id"],
                            exc
                        )
                    try:
                        self._process_colors(conn, rec.base["Id"], rec_raw, adapter.component_type, stats)
                    except Exception as exc:
                        logging.warning(
                            "Error processing colors for component %s: %s",
                            rec.base["Id"],
                            exc
                        )
            except Exception as exc:
                logging.error(
                    "Failed to flush final batch for %s: %s",
                    adapter.component_type,
                    exc
                )
                stats.errors.append(f"Final batch insert failed: {exc}")   
                batch.clear()
        return stats

    def _load_records(self, file_path: pathlib.Path) -> Iterable[Dict[str, Any]]:
        """
        Load component records from a single JSON file.
        
        Supports multiple JSON formats:
        - Array of objects: [{"id": 1}, {"id": 2}]
        - Object with "items" array: {"items": [...]}
        - Object with "data" array: {"data": [...]}
        - Newline-delimited JSON (NDJSON): one JSON object per line
        
        Args:
            file_path: Path to the JSON file to load.
        
        Returns:
            Iterable of dictionary records.
        
        Raises:
            RuntimeError: If JSON format is not recognized.
        """
        with file_path.open("r", encoding="utf-8") as handle:
            content = handle.read().strip()
            if not content:
                return []
            try:
                data = json.loads(content)
            except json.JSONDecodeError:
                records = []
                handle.seek(0)
                for line in handle:
                    line = line.strip()
                    if not line:
                        continue
                    records.append(json.loads(line))
                return records
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            if "items" in data and isinstance(data["items"], list):
                return data["items"]
            if "data" in data and isinstance(data["data"], list):
                return data["data"]
        raise RuntimeError(f"Unsupported JSON format in {file_path}")

    def _load_directory_records(self, dir_path: pathlib.Path, stats: ComponentStats) -> Iterable[Dict[str, Any]]:
        """
        Load component records from all JSON files in a directory.
        
        Iterates through all .json files in the directory, loads each one,
        and yields individual records. Handles both single-object files and
        array files.
        
        Args:
            dir_path: Directory containing JSON files.
            stats: ComponentStats object to update with errors.
        
        Returns:
            Iterator that yields dictionary records from all files.
        """
        json_files = sorted(p for p in dir_path.glob("*.json") if p.is_file())
        if not json_files:
            logging.warning("No JSON files found in %s", dir_path)
            stats.errors.append("Directory contains no JSON files")
            return []

        def iterator() -> Iterator[Dict[str, Any]]:
            for file_path in json_files:
                try:
                    with file_path.open("r", encoding="utf-8") as handle:
                        data = json.load(handle)
                except json.JSONDecodeError as exc:
                    logging.warning("Skipping invalid JSON file %s: %s", file_path, exc)
                    stats.errors.append(f"Invalid JSON: {file_path.name}")
                    continue
                if isinstance(data, dict):
                    yield data
                elif isinstance(data, list):
                    for item in data:
                        if isinstance(item, dict):
                            yield item
                        else:
                            logging.debug("Ignoring non-object entry in %s", file_path)
                else:
                    logging.debug("Ignoring unsupported JSON root in %s", file_path)

        return iterator()

    def _build_signature(self, record: ComponentRecord, adapter: ComponentAdapter) -> str:
        """
        Create a unique signature for a component record for deduplication.
        
        Generates a JSON string from the record's data (excluding IDs and
        timestamps) that can be used to identify duplicate records.
        
        Args:
            record: ComponentRecord to create signature for.
            adapter: Component adapter (used for component type).
        
        Returns:
            JSON string signature sorted by keys for consistent comparison.
        """
        base_payload = {
            key: value
            for key, value in record.base.items()
            if key not in {"Id", "DatabaseEntryAt", "LastEditedAt"}
        }
        specific_payload = {
            key: value for key, value in record.specific.items() if key != "Id"
        }
        payload = {"base": base_payload, "specific": specific_payload, "type": adapter.component_type}
        return json.dumps(payload, sort_keys=True, default=str)
    
    def _build_subcomponent_signature(self, record: SubComponentRecord, adapter: SubComponentAdapter) -> str:
        """
        Create a unique signature for a subcomponent record for deduplication.
        
        Similar to _build_signature but for subcomponents. Used to identify
        existing subcomponents in the database.
        
        Args:
            record: SubComponentRecord to create signature for.
            adapter: SubComponent adapter (used for subcomponent type).
        
        Returns:
            JSON string signature sorted by keys for consistent comparison.
        """
        base_payload = {
            key: value
            for key, value in record.base.items()
            if key not in {"Id", "DatabaseEntryAt", "LastEditedAt"}
        }
        specific_payload = {
            key: value for key, value in record.specific.items() if key != "Id"
        }
        payload = {
            "base": base_payload,
            "specific": specific_payload,
            "type": adapter.subcomponent_type
        }
        return json.dumps(payload, sort_keys=True, default=str)

    def _find_existing_subcomponent(self, conn, subcomponent_type: str, signature: str) -> Optional[uuid.UUID]:
        """
        Check if a subcomponent with the given signature already exists in the database.
        
        Queries all subcomponents of the specified type, builds signatures for each,
        and compares them to find a match. Returns the ID of the matching subcomponent
        if found.
        
        Args:
            conn: Database connection object.
            subcomponent_type: Type of subcomponent to search for.
            signature: Signature string to match against.
        
        Returns:
            UUID of matching subcomponent, or None if not found.
        
        Note:
            This method can be slow with many subcomponents.
        """
        cursor = conn.cursor()
        cursor.execute(
            "SELECT Id FROM SubComponents WHERE Type = ?",
            subcomponent_type
        )
        rows = cursor.fetchall()
        
        for row in rows:
            subcomp_id = row[0]
            base_data = self._get_subcomponent_base(conn, subcomp_id)
            specific_data = self._get_subcomponent_specific(conn, subcomponent_type, subcomp_id)
            
            if base_data and specific_data:
                base_payload = {
                    k: v for k, v in base_data.items()
                    if k not in {"Id", "DatabaseEntryAt", "LastEditedAt"}
                }
                specific_payload = {k: v for k, v in specific_data.items() if k != "Id"}
                existing_payload = {
                    "base": base_payload,
                    "specific": specific_payload,
                    "type": subcomponent_type
                }
                existing_signature = json.dumps(existing_payload, sort_keys=True, default=str)
                
                if existing_signature == signature:
                    return uuid.UUID(str(subcomp_id))
        return None

    def _get_subcomponent_base(self, conn, subcomp_id: uuid.UUID) -> Optional[Dict[str, Any]]:
        """
        Retrieve base subcomponent data from the SubComponents table.
        
        Args:
            conn: Database connection object.
            subcomp_id: UUID of the subcomponent to retrieve.
        
        Returns:
            Dictionary with base subcomponent fields, or None if not found.
        """
        cursor = conn.cursor()
        cursor.execute(
            "SELECT Id, Name, Type, DatabaseEntryAt, LastEditedAt, Note "
            "FROM SubComponents WHERE Id = ?",
            str(subcomp_id)
        )
        row = cursor.fetchone()
        if row:
            return {
                "Id": row[0],
                "Name": row[1],
                "Type": row[2],
                "DatabaseEntryAt": row[3],
                "LastEditedAt": row[4],
                "Note": row[5],
            }
        return None

    def _get_subcomponent_specific(self, conn, subcomponent_type: str, subcomp_id: uuid.UUID) -> Optional[Dict[str, Any]]:
        """
        Retrieve type-specific subcomponent data from the appropriate table.
        
        Queries the type-specific subcomponent table (e.g., PortSubComponents)
        to get the additional fields beyond the base SubComponents table.
        
        Args:
            conn: Database connection object.
            subcomponent_type: Type of subcomponent (determines which table to query).
            subcomp_id: UUID of the subcomponent to retrieve.
        
        Returns:
            Dictionary with type-specific fields, or None if not found.
        """
        adapter = SUBCOMPONENT_ADAPTERS.get(subcomponent_type)
        if not adapter:
            return None
        
        cursor = conn.cursor()
        
        columns = ", ".join(adapter.columns)
        cursor.execute(
            f"SELECT {columns} FROM {adapter.table_name} WHERE Id = ?",
            str(subcomp_id)
        )
        row = cursor.fetchone()
        if row:
            return dict(zip(adapter.columns, row))
        return None

    def _insert_subcomponent(self, conn, record: SubComponentRecord, adapter: SubComponentAdapter) -> uuid.UUID:
        """
        Insert a new subcomponent into both base and type-specific tables.
        
        Performs two inserts in a transaction:
        1. Insert into SubComponents table (base fields)
        2. Insert into type-specific table (e.g., PortSubComponents)
        
        Args:
            conn: Database connection object.
            record: SubComponentRecord to insert.
            adapter: SubComponent adapter for the subcomponent type.
        
        Returns:
            UUID of the inserted subcomponent.
        
        Raises:
            RuntimeError: If database insertion fails (transaction is rolled back).
        """
        cursor = conn.cursor()
        cursor.fast_executemany = True
        
        try:
            base_row = (
                str(record.base["Id"]),
                record.base["Name"],
                record.base["Type"],
                record.base["DatabaseEntryAt"],
                record.base["LastEditedAt"],
                record.base["Note"],
            )
            cursor.execute(adapter.base_insert_sql, base_row)
            
            specific_row = tuple(record.specific[column] for column in adapter.columns)
            cursor.execute(adapter.insert_sql, specific_row)
            
            conn.commit()
            return record.base["Id"]
        except Exception as exc:
            conn.rollback()
            raise RuntimeError(f"Failed to insert subcomponent: {exc}") from exc

    def _insert_component_parts(self, conn, component_id: uuid.UUID, parts: List[Tuple[uuid.UUID, int]]) -> None:
        """
        Insert ComponentPart records linking a component to its subcomponents.
        
        Creates relationship records in the ComponentParts table that connect
        a main component to one or more subcomponents with specified amounts.
        
        Args:
            conn: Database connection object.
            component_id: UUID of the main component.
            parts: List of (subcomponent_id, amount) tuples to link.
        
        Raises:
            RuntimeError: If database insertion fails (transaction is rolled back).
        """
        if not parts:
            return
        
        cursor = conn.cursor()
        cursor.fast_executemany = True
        
        try:
            rows = []
            for subcomp_id, amount in parts:
                part_id = uuid.uuid4()
                rows.append((
                    str(part_id),
                    str(component_id),
                    str(subcomp_id),
                    amount,
                    self.context.now,
                    self.context.now,
                    None,  # Note
                ))
            
            cursor.executemany(COMPONENT_PARTS_INSERT_SQL, rows)
            conn.commit()
        except Exception as exc:
            conn.rollback()
            logging.error(
                "Failed to insert ComponentParts for component %s: %s",
                component_id,
                exc
            )
            raise RuntimeError(
                f"Failed to create ComponentPart links: {exc}"
            ) from exc

    def _extract_subcomponents(self, raw: Dict[str, Any], component_type: str) -> List[Tuple[str, Dict[str, Any], int]]:
        """
        Extract subcomponents from a component JSON record based on
        its component type.

        Supported subcomponent types:
            - INTEGRATED_GRAPHICS
            - COOLER_SOCKET
            - PCIE_SLOT
            - M2_SLOT
            - ONBOARD_ETHERNET
            - PORT

        Rules per component type:

        CPU:
            - Extracts integrated graphics (specifications.integratedGraphics)
              as INTEGRATED_GRAPHICS.

        COOLER:
            - Extracts cpu_sockets[] as COOLER_SOCKET.

        GPU:
            - Extracts video outputs as PORT subcomponents.
              PortType = VIDEO.
              Examples: HDMI versions, DisplayPort versions, DVI-D, VGA.

        MOTHERBOARD:
            - Extracts pcie_slots[] as PCIE_SLOT.
            - Extracts m2_slots[] as M2_SLOT.
            - Extracts onboard_ethernet[] or ethernet[] entries
              as ONBOARD_ETHERNET.
            - Extracts back_panel_ports[] as PORT
              (PortType may be USB, VIDEO, POWER, or PIN).

        POWER_SUPPLY:
            - Extracts all electrical connectors
              (ATX, EPS, PCIe, SATA, Molex, Floppy) as PORT subcomponents
              with PortType = POWER.

        CASE:
            - Extracts front I/O ports (ports[] / io_ports[])
              as PORT subcomponents (USB or PIN).

        MONITOR:
            - Extracts video input ports (ports[] / io_ports[])
              as PORT subcomponents with PortType = VIDEO.

        Returns:
            A list of (subcomponent_type, subcomponent_data, amount) tuples.
        """
        subcomponents = []
        
        def _normalize_connector_key(k: str) -> str:
            return (k or "").lower().replace("-", "_").replace(" ", "_")
        
        def _get_count_from_connector_dict(conn_dict: Dict[str, Any], *variants) -> int:
            for v in variants:
                if v in conn_dict:
                    return to_int(conn_dict.get(v), default=0, min_value=0, max_value=50)
                # try normalized keys
                for key in conn_dict.keys():
                    if _normalize_connector_key(key) == _normalize_connector_key(v):
                        return to_int(conn_dict.get(key), default=0, min_value=0, max_value=50)
            return 0
        
        def _choose_amount_from_slot(slot: Dict[str, Any]) -> int:
            for k in ("quantity", "amount", "qty"):
                if k in slot:
                    return to_int(slot.get(k), default=1, min_value=1, max_value=50)
            return 1
        
        def _classify_port_keyword(keyword: str) -> str:
            k = keyword.lower()
            if any(x in k for x in ("hdmi", "displayport", "dvi", "vga", "dp", "display port")):
                return "VIDEO"
            if any(x in k for x in ("atx", "eps", "pci", "12vhpwr", "pcie", "molex", "sata", "floppy", "power")):
                return "POWER"
            if any(x in k for x in ("usb", "type-c", "type-c)", "type-a", "usb-c", "usb-a", "usb")):
                return "USB"
            if any(x in k for x in ("pin", "header", "pinout", "pins", "front_panel", "front usb", "usb header")):
                return "PIN"
            return "OTHER"

        def _parse_port_string(s: str):
            if not s or not isinstance(s, str):
                return 1, "OTHER", s or ""

            s_strip = s.strip()
            m = re.match(r"^\s*(\d+)\s*[x×]\s*(.+)$", s_strip, flags=re.IGNORECASE)
            if not m:
                m = re.match(r"^\s*(\d+)\s*x?\s*(.+)$", s_strip, flags=re.IGNORECASE)
            if m:
                amount = to_int(m.group(1), default=1, min_value=1, max_value=50)
                rest = m.group(2).strip()
            else:
                amount = 1
                rest = s_strip

            tokens = rest.split()
            name = rest
            keyword = rest.lower()
            if "displayport" in keyword or "dp" in keyword:
                name = "DisplayPort"
            elif "hdmi" in keyword:
                ver_m = re.search(r"hdmi\s*([0-9\.]+)", keyword)
                if ver_m:
                    name = f"HDMI {ver_m.group(1)}"
                else:
                    name = "HDMI"
            elif "dvi" in keyword:
                name = "DVI"
            elif "vga" in keyword:
                name = "VGA"
            else:
                name = rest

            port_type = _classify_port_keyword(keyword)
            return amount, port_type, name
        
        if component_type == "CPU":
            specs = raw.get("specifications", {}) or {}
            igpu = specs.get("integratedGraphics") or specs.get("integrated_graphics") or specs.get("igpu")
            if isinstance(igpu, dict):
                subcomponents.append(("INTEGRATED_GRAPHICS", igpu, 1))
        
        elif component_type == "COOLER":
            sockets = raw.get("cpu_sockets") or raw.get("sockets") or raw.get("socket_compatibility")
            if sockets and isinstance(sockets, list):
                for socket_name in sockets:
                    if isinstance(socket_name, str):
                        subcomponents.append(("COOLER_SOCKET", {"socket_type": socket_name}, 1))
                    elif isinstance(socket_name, dict):
                        amount = to_int(socket_name.get("amount"), default=1, min_value=1, max_value=50) if isinstance(socket_name, dict) else 1
                        subcomponents.append(("COOLER_SOCKET", socket_name, amount))
                    
        elif component_type == "GPU":
            video_outputs = raw.get("video_outputs") or raw.get("videoOutputs") or raw.get("outputs")
            if isinstance(video_outputs, dict):
                for key, value in video_outputs.items():
                    if str(key).startswith("_"):
                        continue
                    count = to_int(value, default=0, min_value=0, max_value=50)
                    if count <= 0:
                        continue
                    k = key.lower()
                    if "hdmi" in k:
                        ver = re.search(r"hdmi[_\s]?([0-9ab\.]+)", k)
                        name = f"HDMI {ver.group(1).replace('_', '.').replace('a','a').replace('b','b')}" if ver else "HDMI"
                    elif "displayport" in k or k.startswith("dp") or "display_port" in k:
                        ver = re.search(r"displayport[_\s]?(.+)$", k)
                        if ver:
                            dp_ver = ver.group(1).replace("_", ".")
                            name = f"DisplayPort {dp_ver}"
                        else:
                            name = "DisplayPort"
                    elif "dvi" in k:
                        name = "DVI-D" if "dvi" in k else "DVI"
                    elif "vga" in k:
                        name = "VGA"
                    else:
                        name = str(key)

                    port_raw = {
                        "port_type": "VIDEO",
                        "type": name,
                        "name": name
                    }
                    subcomponents.append(("PORT", port_raw, count))
                    
        elif component_type == "MOTHERBOARD":
            pcie_slots = raw.get("pcie_slots") or raw.get("pcie")
            if isinstance(pcie_slots, list):
                for slot_data in pcie_slots:
                    if isinstance(slot_data, dict):
                        amount = _choose_amount_from_slot(slot_data)
                        subcomponents.append(("PCIE_SLOT", slot_data, amount))
            
            m2_slots = raw.get("m2_slots") or raw.get("m2")
            if isinstance(m2_slots, list):
                for slot_data in m2_slots:
                    if isinstance(slot_data, dict):
                        amount = _choose_amount_from_slot(slot_data)
                        subcomponents.append(("M2_SLOT", slot_data, amount))
            
            ethernet = raw.get("onboard_ethernet") or raw.get("ethernet")
            if ethernet:
                if isinstance(ethernet, dict):
                    subcomponents.append(("ONBOARD_ETHERNET", ethernet, 1))
                elif isinstance(ethernet, list):
                    for item in ethernet:
                        if isinstance(item, dict):
                            subcomponents.append(("ONBOARD_ETHERNET", item, 1))
            
            back_ports = raw.get("back_panel_ports") or raw.get("back_connectors") or raw.get("back_io") or raw.get("ports") or raw.get("io_ports")
            if back_ports:
                if isinstance(back_ports, list):
                    for entry in back_ports:
                        if isinstance(entry, str):
                            amount, ptype, name = _parse_port_string(entry)
                            port_raw = {
                                "port_type": ptype,
                                "type": name,
                                "name": name
                            }
                            subcomponents.append(("PORT", port_raw, amount))
                        elif isinstance(entry, dict):
                            amount = _choose_amount_from_slot(entry)
                            entry_name = entry.get("name") or entry.get("type") or str(entry)
                            ptype = _classify_port_keyword(entry_name)
                            port_raw = dict(entry)
                            port_raw.setdefault("port_type", ptype)
                            subcomponents.append(("PORT", port_raw, amount))
                elif isinstance(back_ports, str):
                    amount, ptype, name = _parse_port_string(back_ports)
                    subcomponents.append(("PORT", {"port_type": ptype, "type": name, "name": name}, amount))

        
        elif component_type == "POWER_SUPPLY":
            connectors = raw.get("connectors") or raw.get("power_connectors") or raw.get("power_connectors_map")
            if isinstance(connectors, dict):
                connector_variants = {
                    "atx_24_pin": ("atx_24_pin", "atx24", "atx_24", "atx"),
                    "eps_8_pin": ("eps_8_pin", "eps8", "eps_8", "eps"),
                    "pcie_12vhpwr": ("pcie_12vhpwr", "pcie_12vhpwr", "pcie_12v_hpwr", "pcie_12v"),
                    "pcie_6_plus_2_pin": ("pcie_6_plus_2_pin", "pcie_6_2", "pcie_6+2", "pcie_6plus2", "pcie_6_2_pin"),
                    "pcie_8_pin": ("pcie_8_pin", "pcie_8", "pcie8"),
                    "sata": ("sata",),
                    "molex_4_pin": ("molex_4_pin", "molex", "molex4"),
                    "floppy_4_pin": ("floppy_4_pin", "floppy", "fdd")
                }

                for canonical, variants in connector_variants.items():
                    count = _get_count_from_connector_dict(connectors, *variants)
                    if count and count > 0:
                        name_map = {
                            "atx_24_pin": "ATX 24-pin",
                            "eps_8_pin": "EPS 8-pin",
                            "pcie_12vhpwr": "PCIe 12VHPWR (12+4 pin)",
                            "pcie_6_plus_2_pin": "PCIe 6+2-pin",
                            "pcie_8_pin": "PCIe 8-pin",
                            "sata": "SATA Power",
                            "molex_4_pin": "Molex 4-pin",
                            "floppy_4_pin": "Floppy 4-pin"
                        }
                        pretty_name = name_map.get(canonical, canonical)
                        port_raw = {
                            "port_type": "POWER",
                            "type": pretty_name,
                            "name": pretty_name
                        }
                        subcomponents.append(("PORT", port_raw, count))
        
        elif component_type == "CASE":
            front_usb_list = raw.get("front_usb_ports") or raw.get("front_usb") or raw.get("front_panel_usb_list")
            if isinstance(front_usb_list, list):
                for entry in front_usb_list:
                    if isinstance(entry, str):
                        amount, ptype, name = _parse_port_string(entry)
                        port_raw = {"port_type": ptype, "type": name, "name": name}
                        subcomponents.append(("PORT", port_raw, amount))
                    elif isinstance(entry, dict):
                        amount = _choose_amount_from_slot(entry)
                        entry_name = entry.get("name") or entry.get("type") or str(entry)
                        ptype = _classify_port_keyword(entry_name)
                        entry.setdefault("port_type", ptype)
                        subcomponents.append(("PORT", entry, amount))
                        
            front_panel_usb = raw.get("front_panel_usb") or raw.get("front_panel_usb_port") or raw.get("front_panel")
            if isinstance(front_panel_usb, str) and front_panel_usb.strip():
                parts = re.split(r"\s{2,}|[,;]|(?=\d+\s*[x×])", front_panel_usb)
                for part in parts:
                    part = part.strip()
                    if not part:
                        continue
                    amount, ptype, name = _parse_port_string(part)
                    port_raw = {"port_type": ptype, "type": name, "name": name}
                    subcomponents.append(("PORT", port_raw, amount))

            case_ports = raw.get("ports") or raw.get("io_ports")
            if case_ports:
                if isinstance(case_ports, list):
                    for p in case_ports:
                        if isinstance(p, str):
                            amount, ptype, name = _parse_port_string(p)
                            subcomponents.append(("PORT", {"port_type": ptype, "type": name, "name": name}, amount))
                        elif isinstance(p, dict):
                            amount = _choose_amount_from_slot(p)
                            p_name = p.get("name") or p.get("type") or str(p)
                            p_type = _classify_port_keyword(p_name)
                            p.setdefault("port_type", p_type)
                            subcomponents.append(("PORT", p, amount))
                            
        elif component_type == "MONITOR":
            connectors_val = raw.get("connectors") or raw.get("back_panel_ports") or raw.get("ports") or raw.get("io_ports")
            if isinstance(connectors_val, str):
                parts = re.split(r"\s{2,}|[,;]|(?=\d+\s*[x×])", connectors_val)
                for part in parts:
                    part = part.strip()
                    if not part:
                        continue
                    amount, ptype, name = _parse_port_string(part)
                    port_raw = {"port_type": ptype, "type": name, "name": name}
                    subcomponents.append(("PORT", port_raw, amount))
            elif isinstance(connectors_val, list):
                for entry in connectors_val:
                    if isinstance(entry, str):
                        amount, ptype, name = _parse_port_string(entry)
                        port_raw = {"port_type": ptype, "type": name, "name": name}
                        subcomponents.append(("PORT", port_raw, amount))
                    elif isinstance(entry, dict):
                        amount = _choose_amount_from_slot(entry)
                        entry_name = entry.get("name") or entry.get("type") or str(entry)
                        ptype = _classify_port_keyword(entry_name)
                        entry.setdefault("port_type", ptype)
                        subcomponents.append(("PORT", entry, amount))
        
        return subcomponents

    def _process_subcomponents(self, conn, component_id: uuid.UUID, raw: Dict[str, Any], component_type: str, stats: ComponentStats) -> None:
        """
        Process and link all subcomponents for a component.
        
        For each subcomponent found in the component data:
        1. Transforms the subcomponent data
        2. Checks if it already exists in the database
        3. Inserts it if new, or reuses existing ID
        4. Creates ComponentPart relationship
        
        Updates statistics throughout the process.
        
        Args:
            conn: Database connection object.
            component_id: UUID of the component to link subcomponents to.
            raw: Raw JSON dictionary for the component.
            component_type: Type of component (used for subcomponent extraction).
            stats: ComponentStats object to update with subcomponent statistics.
        
        Note:
            This method is called for each component after it's added to the batch.
            Subcomponent processing errors are logged but don't abort the import.
        """
        if self.dry_run:
            return
        
        subcomponent_data = self._extract_subcomponents(raw, component_type)
        
        if not subcomponent_data:
            return
        
        component_parts = []
        seen_subcomp_signatures: Dict[str, uuid.UUID] = {}
        
        for subcomp_type, subcomp_raw, amount in subcomponent_data:
            stats.subcomponents_processed += 1
            adapter = SUBCOMPONENT_ADAPTERS.get(subcomp_type)
            if not adapter:
                logging.debug("No adapter found for subcomponent type: %s", subcomp_type)
                stats.subcomponents_skipped += 1
                continue
            
            try:
                subcomp_record = adapter.transform(subcomp_raw, self.context)
                
                signature = self._build_subcomponent_signature(subcomp_record, adapter)
                
                if signature in seen_subcomp_signatures:
                    subcomp_id = seen_subcomp_signatures[signature]
                else:
                    subcomp_id = self._find_existing_subcomponent(conn, subcomp_type, signature)
                    
                    if not subcomp_id:
                        subcomp_id = self._insert_subcomponent(conn, subcomp_record, adapter)
                        stats.subcomponents_inserted += 1
                        logging.debug("Inserted new subcomponent: %s (%s)", subcomp_type, subcomp_id)
                    else:
                        stats.subcomponents_found += 1
                        logging.debug("Found existing subcomponent: %s (%s)", subcomp_type, subcomp_id)
                    
                    seen_subcomp_signatures[signature] = subcomp_id
                
                component_parts.append((subcomp_id, amount))
                
            except SkipRecord as exc:
                stats.subcomponents_skipped += 1
                logging.debug("Skipping subcomponent %s: %s", subcomp_type, exc)
                continue
            except Exception as exc:
                stats.subcomponents_skipped += 1
                logging.warning("Error processing subcomponent %s: %s", subcomp_type, exc)
                continue
        
        if component_parts:
            self._insert_component_parts(conn, component_id, component_parts)
            stats.component_parts_created += len(component_parts)
            logging.debug("Created %d ComponentPart links for component %s", len(component_parts), component_id)

    def _extract_colors(self, raw: Dict[str, Any]) -> List[str]:
        """
        Extract color values from a component record.

        Supports multiple source shapes:
        - "color": string or list (primary)
        - "colors": list
        - "color_variant": string or list

        Normalization and splitting rules:
        - If value is a string, splits on common delimiters (comma, semicolon, slash, pipe)
          and on occurrences of multiple spaces.
        - If value is a list, each non-empty element is returned as a stripped string.
        - Returns an empty list if no color data found.

        Args:
            raw: Component JSON payload.

        Returns:
            List[str] - list of raw color tokens (trimmed).
        """
        colors = raw.get("color") or raw.get("colors") or raw.get("color_variant") or None
        if colors is None:
            return []
        if isinstance(colors, str):
            parts = re.split(r"[;,/|]\s*|\s{2,}", colors.strip())
            return [p.strip() for p in parts if p.strip()]
        if isinstance(colors, list):
            return [str(c).strip() for c in colors if c]
        return []

    def _normalize_color(self, raw_color: str) -> Tuple[str, str]:
        """
        Normalize a raw color token into a canonical ColorCode and a display name.

        Behavior:
        - If the token is a 6-digit hex (with or without '#') returns '#RRGGBB' and preserves
          the original token as the display name.
        - Maps a small set of common color names (e.g., 'BLACK', 'WHITE', 'BROWN') to reasonable
          hex codes.
        - For unknown freeform names, returns a deterministic fallback hex generated from
          the md5 of the input (first 6 hex digits) to ensure the Colors.ColorCode column
          remains a valid hex-like identifier while being deterministic across runs.

        Args:
            raw_color: Raw color string extracted from JSON.

        Returns:
            Tuple[str, str] where:
                - first element is ColorCode (normalized '#RRGGBB'),
                - second element is the original/raw display name to store as ColorName.
        """
        s = raw_color.strip()
        hex_match = re.match(r"^#?([0-9a-fA-F]{6})$", s)
        if hex_match:
            code = "#" + hex_match.group(1).upper()
            name = s if s.startswith("#") else f"#{hex_match.group(1).upper()}"
            return code, raw_color
        mapping = {
            "BLACK": "#000000",
            "WHITE": "#FFFFFF",
            "RED": "#FF0000",
            "GREEN": "#008000",
            "BLUE": "#0000FF",
            "BROWN": "#8B4513",
            "GRAY": "#808080",
            "GREY": "#808080",
            "SILVER": "#C0C0C0",
            "GOLD": "#D4AF37",
            "YELLOW": "#FFFF00",
            "ORANGE": "#FFA500",
            "PURPLE": "#800080",
            "PINK": "#FFC0CB",
        }
        up = s.upper()
        if up in mapping:
            return mapping[up], raw_color
        digest = hashlib.md5(s.encode("utf-8")).hexdigest()[:6].upper()
        return f"#{digest}", raw_color

    def _find_existing_color(self, conn, color_code: str) -> bool:
        """
        Check whether a color with the given ColorCode exists.

        Performs a simple SELECT by ColorCode. Returns True if exists, False otherwise.

        Args:
            conn: Database connection object.
            color_code: Normalized color code (e.g., '#AABBCC').

        Returns:
            bool - True if color present in Colors table.
        """
        cursor = conn.cursor()
        cursor.execute("SELECT ColorCode FROM Colors WHERE ColorCode = ?", color_code)
        return cursor.fetchone() is not None

    def _insert_color(self, conn, color_code: str, color_name: Optional[str]) -> None:
        """
        Insert a new Colors row if it does not already exist.

        This function uses a simple INSERT then commits. A race condition with concurrent
        processes inserting the same color is handled by rolling back and checking existence
        again; if the color now exists the error is suppressed.

        Args:
            conn: Database connection object.
            color_code: Normalized ColorCode (e.g., '#RRGGBB').
            color_name: Human readable name for the color.

        Raises:
            Exception when the insert fails for reasons other than a concurrent insert.
        """
        cursor = conn.cursor()
        try:
            cursor.execute(COLOR_INSERT_SQL, (color_code, color_name or color_code, self.context.now, self.context.now, None))
            conn.commit()
        except Exception:
            conn.rollback()
            if not self._find_existing_color(conn, color_code):
                raise

    def _get_component_variant_ids(self, conn, component_id: uuid.UUID) -> List[uuid.UUID]:
        """
        Retrieve all ComponentVariant IDs for a given component.

        Args:
            conn: Database connection object.
            component_id: UUID of the parent component.

        Returns:
            List[uuid.UUID]: List of ComponentVariant IDs associated with the component.

        Example:
            >>> self._get_component_variant_ids(conn, some_component_id)
            [UUID('...'), UUID('...')]
        """
        cursor = conn.cursor()
        cursor.execute("SELECT Id FROM ComponentVariants WHERE ComponentId = ?", str(component_id))
        return [uuid.UUID(str(r[0])) for r in cursor.fetchall()]

    def _get_variant_color_codes(self, conn, variant_id: uuid.UUID) -> set:
        """
        Return the set of ColorCode strings associated with a ComponentVariant.

        Args:
            conn: Database connection object.
            variant_id: UUID of the ComponentVariant.

        Returns:
            set: Set of ColorCode strings (e.g. {'#000000', '#FFFFFF'}).

        Example:
            >>> self._get_variant_color_codes(conn, variant_id)
            {'#000000', '#FFFFFF'}
        """
        cursor = conn.cursor()
        cursor.execute("SELECT ColorCode FROM ColorVariants WHERE ComponentVariantId = ?", str(variant_id))
        return {row[0] for row in cursor.fetchall()}

    def _find_variant_matching_color_set(self, conn, component_id: uuid.UUID, color_codes: set) -> Optional[uuid.UUID]:
        """
        Find a ComponentVariant for a component whose linked ColorCodes exactly match the provided set.

        The function iterates the component's variants and returns the variant id where
        the set of linked ColorCodes equals the provided color_codes set.

        Args:
            conn: Database connection object.
            component_id: UUID of the component.
            color_codes: Set of ColorCode strings to match.

        Returns:
            Optional[uuid.UUID]: Matching ComponentVariant id if found, otherwise None.

        Example:
            >>> self._find_variant_matching_color_set(conn, comp_id, {'#000000', '#FFFFFF'})
            UUID('...')
        """
        for variant_id in self._get_component_variant_ids(conn, component_id):
            existing = self._get_variant_color_codes(conn, variant_id)
            if existing == color_codes:
                return variant_id
        return None

    def _insert_component_variant_and_link(self, conn, component_id: uuid.UUID, color_codes: List[Tuple[str, str]]) -> uuid.UUID:
        """
        Insert a new ComponentVariant and link it to multiple Colors via ColorVariants.

        Performs both the insert into ComponentVariants and the corresponding
        ColorVariants inserts in a single transaction and commits.

        Args:
            conn: Database connection object.
            component_id: UUID of the parent component.
            color_codes: List of (ColorCode, ColorName) tuples to link to the new variant.

        Returns:
            uuid.UUID: The newly created ComponentVariant Id.

        Raises:
            RuntimeError: If the database operations fail (transaction rolled back).

        Example:
            >>> pairs = [('#000000', 'Black'), ('#8B4513', 'Brown')]
            >>> self._insert_component_variant_and_link(conn, comp_id, pairs)
            UUID('...')
        """
        cursor = conn.cursor()
        try:
            variant_id = uuid.uuid4()
            variant_row = (
                str(variant_id),
                str(component_id),
                True,
                None,
                self.context.now,
                self.context.now,
                None,
            )
            cursor.execute(COMPONENT_VARIANT_INSERT_SQL, variant_row)

            rows = []
            for code, _ in color_codes:
                color_variant_id = uuid.uuid4()
                rows.append((
                    str(color_variant_id),
                    code,
                    str(variant_id),
                    self.context.now,
                    self.context.now,
                    None,
                ))
            cursor.fast_executemany = True
            cursor.executemany(COLOR_VARIANT_INSERT_SQL, rows)
            conn.commit()
            return variant_id
        except Exception as exc:
            conn.rollback()
            raise RuntimeError(f"Failed to insert component variant/color links: {exc}") from exc

    def _process_colors(self, conn, component_id: uuid.UUID, raw: Dict[str, Any], component_type: str, stats: ComponentStats) -> None:
        """
        Extract colors from the component JSON, ensure Colors exist, and create or reuse a ComponentVariant.

        Workflow:
            1. Extract and normalize color tokens from the raw component payload.
            2. Ensure each Color exists in the Colors table (insert if missing).
            3. If a ComponentVariant already exists with the exact set of ColorCodes, reuse it.
            4. Otherwise create a new ComponentVariant and link all colors to it via ColorVariants.

        Args:
            conn: Database connection object.
            component_id: UUID of the component to attach variant(s) to.
            raw: Raw JSON dictionary for the component.
            component_type: Component type string (provided for parity with subcomponent function).
            stats: ComponentStats instance to update counters.

        Returns:
            None

        Example:
            >>> self._process_colors(conn, comp_id, raw_payload, 'CASE', stats)
        """
        if self.dry_run:
            return
        color_values = self._extract_colors(raw)
        if not color_values:
            return

        normalized: List[Tuple[str, str]] = []
        seen_codes: set = set()
        for raw_color in color_values:
            code, name = self._normalize_color(raw_color)
            if code in seen_codes:
                continue
            normalized.append((code, name))
            seen_codes.add(code)

        if not normalized:
            return

        stats.colors_processed += len(normalized)

        for code, name in normalized:
            try:
                if self._find_existing_color(conn, code):
                    stats.colors_found += 1
                else:
                    self._insert_color(conn, code, name)
                    stats.colors_inserted += 1
            except Exception as exc:
                stats.colors_skipped += 1
                logging.warning("Failed to ensure Color %s: %s", code, exc)
                seen_codes.discard(code)
        final_codes = [c for c, _ in normalized if self._find_existing_color(conn, c)]
        final_set = set(final_codes)
        if not final_codes:
            return

        existing_variant = self._find_variant_matching_color_set(conn, component_id, final_set)
        if existing_variant:
            return

        try:
            pairs_to_link = [(c, next((n for (cc, n) in normalized if cc == c), c)) for c in final_codes]
            self._insert_component_variant_and_link(conn, component_id, pairs_to_link)
            stats.variants_created += 1
        except Exception as exc:
            stats.colors_skipped += 1
            logging.warning("Failed to create ComponentVariant + ColorVariants for %s: %s", component_id, exc)

    def _flush_batch(self, conn, batch: Sequence[ComponentRecord], adapter: ComponentAdapter) -> int:
        """
        Insert a batch of component records into the database.
        
        Performs two batch inserts in a transaction:
        1. Insert base records into Components table
        2. Insert specific records into component-type table
        
        Args:
            conn: Database connection object.
            batch: List of ComponentRecord objects to insert.
            adapter: Component adapter for the component type.
        
        Returns:
            Number of successfully inserted records.
        
        Raises:
            RuntimeError: If database insertion fails (transaction is rolled back).
        """
        cursor = conn.cursor()
        cursor.fast_executemany = True
        
        try:
            base_rows = [
                (
                    str(record.base["Id"]),
                    record.base["Name"],
                    record.base["Manufacturer"],
                    record.base["Release"],
                    record.base["Type"],
                    record.base["DatabaseEntryAt"],
                    record.base["LastEditedAt"],
                    record.base["Note"],
                )
                for record in batch
            ]
            cursor.executemany(BASE_INSERT_SQL, base_rows)
            specific_rows = [
                tuple(record.specific[column] for column in adapter.columns) for record in batch
            ]
            cursor.executemany(adapter.insert_sql, specific_rows)
            conn.commit()
            return len(batch)
        except Exception as exc:
            conn.rollback()
            logging.error(
                "Failed to insert batch of %d %s components: %s",
                len(batch),
                adapter.component_type,
                exc
            )
            raise RuntimeError(
                f"Batch insert failed for {adapter.component_type}: {exc}"
            ) from exc


# ========================================================================== #
# COMMAND-LINE INTERFACE FUNCTIONS                                           #
# ========================================================================== #

def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    """
    Parse command-line arguments for the import script.
    
    Defines all command-line options including input directory, component types,
    batch size, connection settings, and various import options.
    
    Args:
        argv: Optional list of command-line arguments (defaults to sys.argv).
    
    Returns:
        argparse.Namespace object containing parsed arguments.
    
    Arguments:
        --input-dir: Directory containing OpenDB JSON exports (default: database/opend-db).
        --component-types: Space-separated list of component types to import.
        --batch-size: Number of records per database batch (default: 100).
        --truncate: Delete existing records before importing.
        --dry-run: Parse and validate without database operations.
        --dedupe: Skip duplicate records within a single import run.
        --limit: Maximum number of records to process per component type.
        --connection-string: SQL Server connection string.
        --odbc-driver: ODBC driver name (default: "ODBC Driver 17 for SQL Server").
        --log-level: Logging level - DEBUG, INFO, WARNING, ERROR (default: INFO).
    """
    parser = argparse.ArgumentParser(description="Import OpenDB JSON dumps into the component tables.")
    parser.add_argument(
        "--input-dir",
        type=pathlib.Path,
        default=pathlib.Path("database/opend-db"),
        help="Directory containing the component exports (per-type JSON files or folders).",
    )
    parser.add_argument(
        "--component-types",
        nargs="+",
        default=list(ADAPTERS.keys()),
        help=f"Component types to import. Available: {', '.join(ADAPTERS.keys())}",
    )
    parser.add_argument("--batch-size", type=int, default=100, help="Number of rows per database batch.")
    parser.add_argument("--truncate", action="store_true", help="Delete existing rows for the selected types before importing.")
    parser.add_argument("--dry-run", action="store_true", help="Parse and validate without touching the database.")
    parser.add_argument("--dedupe", action="store_true", help="Skip inserting duplicate records within a single import run.")
    parser.add_argument("--limit", type=int, help="Maximum number of records to process per type.")
    parser.add_argument("--connection-string", type=str, help="SQL Server connection string. If omitted, KAZABUILD_CONN_STRING will be used.")
    parser.add_argument("--odbc-driver", type=str, default="ODBC Driver 17 for SQL Server", help="ODBC driver name to use.")
    parser.add_argument("--log-level", type=str, default="INFO", help="Logging level (DEBUG, INFO, WARNING, ERROR).")
    return parser.parse_args(argv)


def main(argv: Optional[Sequence[str]] = None) -> int:
    """
    Main entry point for the import script.
    
    Parses command-line arguments, configures logging, creates the importer,
    executes the import, and outputs the results. Designed to be called from
    the command line or from the backend Admin API.
    
    Args:
        argv: Optional list of command-line arguments (defaults to sys.argv).
    
    Returns:
        Exit code: 0 for success, 1 for failure.
    
    Output:
        On success, prints a JSON summary prefixed with SUMMARY_PREFIX to stdout.
        The summary can be parsed by automated tools to extract import statistics.
    
    Raises:
        SystemExit: Always raised with the return code for proper exit handling.
    """
    args = parse_args(argv)
    logging.basicConfig(level=getattr(logging, args.log_level.upper(), logging.INFO), format="%(levelname)s %(message)s")
    component_types = [c.upper() for c in args.component_types if c.upper() in ADAPTERS]
    importer = BuildCoreImporter(
        input_dir=args.input_dir,
        component_types=component_types,
        batch_size=args.batch_size,
        truncate=args.truncate,
        dry_run=args.dry_run,
        limit=args.limit,
        connection_string=args.connection_string,
        odbc_driver=args.odbc_driver,
        dedupe=args.dedupe,
    )
    try:
        summary = importer.run()
    except Exception as exc:  # pragma: no cover - CLI error handling
        logging.error("Import failed: %s", exc)
        return 1
    print(f"{SUMMARY_PREFIX}{json.dumps(summary, default=str)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

