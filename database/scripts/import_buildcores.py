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


getcontext().prec = 16
DECIMAL_DB_LIMIT = Decimal("9999999999999999.99")
SUMMARY_PREFIX = "__IMPORT_SUMMARY__"
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
BASE_INSERT_SQL = (
    "INSERT INTO Components "
    "(Id, Name, Manufacturer, Release, Type, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
)
COMPONENT_PARTS_INSERT_SQL = (
    "INSERT INTO ComponentParts "
    "(Id, ComponentId, SubComponentId, Amount, DatabaseEntryAt, LastEditedAt, Note) "
    "VALUES (?, ?, ?, ?, ?, ?, ?)"
)


class SkipRecord(Exception):
    """Raised when a record should be skipped without aborting the import."""


def get_nested(payload: Any, path: str, default: Any = None) -> Any:
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
    if value is None:
        value = fallback
    text = str(value).strip()
    if not text:
        text = fallback or ""
    if max_length is not None and len(text) > max_length:
        return text[: max_length - 3] + "..."
    return text


def to_bool(value: Any, default: bool = False) -> bool:
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
    return to_decimal(value, multiplier=Decimal("0.0283168"))


def ghz_to_mhz(value: Any) -> Optional[Decimal]:
    return to_decimal(value, multiplier=Decimal("1000"))


def gb_to_mb(value: Any) -> Optional[Decimal]:
    return to_decimal(value, multiplier=Decimal("1024"))


def lbs_to_kg(value: Any) -> Optional[Decimal]:
    return to_decimal(value, multiplier=Decimal("0.45359237"))


@dataclass
class ComponentRecord:
    base: Dict[str, Any]
    specific: Dict[str, Any]


@dataclass
class ComponentStats:
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

    def as_dict(self) -> Dict[str, Any]:
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
        }


@dataclass
class ImportContext:
    now: dt.datetime


class ComponentAdapter:
    component_type: str = ""
    table_name: str = ""
    file_stem: str = ""
    columns: Sequence[str] = ()
    required_fields: Sequence[str] = ("metadata.name",)

    def __init__(self) -> None:
        self.insert_sql = self._build_insert_sql()

    def _build_insert_sql(self) -> str:
        placeholders = ", ".join(["?"] * len(self.columns))
        column_list = ", ".join(self.columns)
        return f"INSERT INTO {self.table_name} ({column_list}) VALUES ({placeholders})"

    def transform(self, raw: Dict[str, Any], context: ImportContext) -> ComponentRecord:
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
        raise NotImplementedError


@dataclass
class SubComponentRecord:
    base: Dict[str, Any]
    specific: Dict[str, Any]


class SubComponentAdapter:
    subcomponent_type: str = ""
    base_table_name: str = "SubComponents"
    table_name: str = ""
    columns: Sequence[str] = ()
    required_fields: Sequence[str] = ()

    def __init__(self) -> None:
        self.base_insert_sql = self._build_base_insert_sql()
        self.insert_sql = self._build_insert_sql()

    def _build_base_insert_sql(self) -> str:
        return (
            "INSERT INTO SubComponents "
            "(Id, Name, Type, DatabaseEntryAt, LastEditedAt, Note) "
            "VALUES (?, ?, ?, ?, ?, ?)"
        )

    def _build_insert_sql(self) -> str:
        placeholders = ", ".join(["?"] * len(self.columns))
        column_list = ", ".join(self.columns)
        return f"INSERT INTO {self.table_name} ({column_list}) VALUES ({placeholders})"

    def transform(self, raw: Dict[str, Any], context: ImportContext) -> SubComponentRecord:
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
        return raw.get("name") or raw.get("type") or ""

    def build_specific(self, raw: Dict[str, Any], context: ImportContext, base: Dict[str, Any]) -> Dict[str, Any]:
        raise NotImplementedError


class PortSubComponentAdapter(SubComponentAdapter):
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


class CPUAdapter(ComponentAdapter):
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


class BuildCoreImporter:
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
        batch: List[ComponentRecord] = []
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
            batch.append(record)
            if not self.dry_run and conn:
                try:
                    self._process_subcomponents(conn, record.base["Id"], raw, adapter.component_type, stats)
                except Exception as exc:
                    logging.warning(
                        "Error processing subcomponents for component %s: %s",
                        record.base["Id"],
                        exc
                    )
            if not self.dry_run and len(batch) >= self.batch_size:
                try:
                    inserted = self._flush_batch(conn, batch, adapter)
                    stats.inserted += inserted
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
                stats.inserted += self._flush_batch(conn, batch, adapter)
            except Exception as exc:
                logging.error(
                    "Failed to flush final batch for %s: %s",
                    adapter.component_type,
                    exc
                )
                stats.errors.append(f"Final batch insert failed: {exc}")    
        return stats

    def _load_records(self, file_path: pathlib.Path) -> Iterable[Dict[str, Any]]:
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
        """Check if a subcomponent with the given signature already exists."""
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
        subcomponents = []
        
        if component_type == "CPU":
            igpu = raw.get("integrated_graphics") or raw.get("igpu")
            if igpu:
                if isinstance(igpu, dict):
                    subcomponents.append(("INTEGRATED_GRAPHICS", igpu, 1))
                elif isinstance(igpu, list):
                    for item in igpu:
                        if isinstance(item, dict):
                            subcomponents.append(("INTEGRATED_GRAPHICS", item, 1))
        
        elif component_type == "COOLER":
            sockets = raw.get("sockets") or raw.get("socket_compatibility")
            if sockets:
                if isinstance(sockets, list):
                    for socket_data in sockets:
                        if isinstance(socket_data, dict):
                            amount = to_int(socket_data.get("amount"), default=1, min_value=1, max_value=50)
                            subcomponents.append(("COOLER_SOCKET", socket_data, amount))
                        elif isinstance(socket_data, str):
                            # If it's just a string, create a dict
                            subcomponents.append(("COOLER_SOCKET", {"socket_type": socket_data}, 1))
        
        elif component_type == "MOTHERBOARD":
            pcie_slots = raw.get("pcie_slots") or raw.get("pcie")
            if pcie_slots:
                if isinstance(pcie_slots, list):
                    for slot_data in pcie_slots:
                        if isinstance(slot_data, dict):
                            amount = to_int(slot_data.get("amount"), default=1, min_value=1, max_value=50)
                            subcomponents.append(("PCIE_SLOT", slot_data, amount))
            
            m2_slots = raw.get("m2_slots") or raw.get("m2")
            if m2_slots:
                if isinstance(m2_slots, list):
                    for slot_data in m2_slots:
                        if isinstance(slot_data, dict):
                            amount = to_int(slot_data.get("amount"), default=1, min_value=1, max_value=50)
                            subcomponents.append(("M2_SLOT", slot_data, amount))
            
            ethernet = raw.get("onboard_ethernet") or raw.get("ethernet")
            if ethernet:
                if isinstance(ethernet, dict):
                    subcomponents.append(("ONBOARD_ETHERNET", ethernet, 1))
                elif isinstance(ethernet, list):
                    for item in ethernet:
                        if isinstance(item, dict):
                            subcomponents.append(("ONBOARD_ETHERNET", item, 1))
            
            ports = raw.get("ports") or raw.get("io_ports")
            if ports:
                if isinstance(ports, list):
                    for port_data in ports:
                        if isinstance(port_data, dict):
                            amount = to_int(port_data.get("amount"), default=1, min_value=1, max_value=50)
                            subcomponents.append(("PORT", port_data, amount))
        
        elif component_type in ("CASE", "MONITOR"):
            ports = raw.get("ports") or raw.get("io_ports")
            if ports:
                if isinstance(ports, list):
                    for port_data in ports:
                        if isinstance(port_data, dict):
                            amount = to_int(port_data.get("amount"), default=1, min_value=1, max_value=50)
                            subcomponents.append(("PORT", port_data, amount))
        
        return subcomponents

    def _process_subcomponents(self, conn, component_id: uuid.UUID, raw: Dict[str, Any], component_type: str, stats: ComponentStats) -> None:
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

    def _flush_batch(self, conn, batch: Sequence[ComponentRecord], adapter: ComponentAdapter) -> int:
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


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
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

