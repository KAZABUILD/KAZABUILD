#!/usr/bin/env python3
# filepath: c:\dev\KAZABUILD_\database\scripts\check_compatibilities.py
r"""
Component Compatibility Generator for KAZABUILD.

This script connects to the database, retrieves all components and their
subcomponents, and generates compatibility relationships based on a set of rules.

Usage example:

    py -3.11 check_compatibilities.py ^
        --connection-string "Server=LAPTOP-94H43BFK;Database=KAZABUILD_DB;Trusted_Connection=Yes;Encrypt=Yes;TrustServerCertificate=Yes" ^
        --odbc-driver "ODBC Driver 17 for SQL Server" ^
        --batch-size 1000
"""

from __future__ import annotations
import argparse
import datetime as dt
import logging
import re
import sys
import uuid
from dataclasses import dataclass, field
from decimal import Decimal
from typing import List, Optional, Set, Tuple
from tqdm import tqdm

try:
    import pyodbc  # type: ignore
except ModuleNotFoundError as exc:
    pyodbc = None
    print(f"Error: pyodbc module not found. Install with: pip install pyodbc", file=sys.stderr)
    sys.exit(1)

# ========================================================================== #
# LOGGING CONFIGURATION                                                      #
# ========================================================================== #

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)

# ========================================================================== #
# COMPONENT TYPE CONSTANTS                                                   #
# ========================================================================== #

class ComponentType:
    CASE_FAN = "CASE_FAN"
    GPU = "GPU"
    CPU = "CPU"
    MEMORY = "MEMORY"
    MOTHERBOARD = "MOTHERBOARD"
    STORAGE = "STORAGE"
    MONITOR = "MONITOR"
    COOLER = "COOLER"
    POWER_SUPPLY = "POWER_SUPPLY"
    CASE = "CASE"


class SubComponentType:
    PORT = "PORT"
    M2_SLOT = "M2_SLOT"
    COOLER_SOCKET = "COOLER_SOCKET"


# ========================================================================== #
# DATA CLASSES                                                               #
# ========================================================================== #

@dataclass
class SubComponent:
    """Represents a subcomponent with its specific properties."""
    id: str
    name: str
    type: str
    amount: int = 1
    # Port-specific
    port_type: Optional[str] = None
    # Cooler Socket-specific
    socket_type: Optional[str] = None


@dataclass
class BaseComponent:
    """Base component with common fields."""
    id: str
    name: str
    type: str
    subcomponents: List[SubComponent] = field(default_factory=list)


@dataclass
class CPUComponent(BaseComponent):
    """CPU component with specific properties."""
    series: Optional[str] = None
    microarchitecture: Optional[str] = None
    core_family: Optional[str] = None
    socket_type: Optional[str] = None
    thermal_design_power: Optional[Decimal] = None


@dataclass
class MotherboardComponent(BaseComponent):
    """Motherboard component with specific properties."""
    socket_type: Optional[str] = None
    form_factor: Optional[str] = None
    chipset_type: Optional[str] = None
    ram_type: Optional[str] = None  # e.g., "DDR5", "DDR4"
    ram_slots_amount: Optional[int] = None
    max_ram_amount: Optional[int] = None  # in GB
    case_fan_header_amount: Optional[int] = None


@dataclass
class CaseComponent(BaseComponent):
    """Case component with specific properties."""
    form_factor: Optional[str] = None  # Supported motherboard form factors
    max_video_card_length: Optional[Decimal] = None
    max_cpu_cooler_height: Optional[Decimal] = None
    expansion_slot_amount: Optional[int] = None
    dimensions_depth: Optional[Decimal] = None
    dimensions_height: Optional[Decimal] = None


@dataclass
class GPUComponent(BaseComponent):
    """GPU component with specific properties."""
    thermal_design_power: Optional[Decimal] = None
    length: Optional[Decimal] = None  # in mm
    case_expansion_slot_width: Optional[int] = None
    total_slot_amount: Optional[int] = None


@dataclass
class MemoryComponent(BaseComponent):
    """Memory/RAM component with specific properties."""
    ram_type: Optional[str] = None  # e.g., "DDR5", "DDR4"
    capacity: Optional[Decimal] = None  # Total capacity in MB
    module_quantity: Optional[int] = None


@dataclass
class StorageComponent(BaseComponent):
    """Storage component with specific properties."""
    form_factor: Optional[str] = None  # M.2, 2.5", etc.


@dataclass
class PowerSupplyComponent(BaseComponent):
    """Power Supply component with specific properties."""
    power_output: Optional[Decimal] = None  # in Watts
    form_factor: Optional[str] = None  # ATX, SFX, etc.
    length: Optional[Decimal] = None  # in mm


@dataclass
class CoolerComponent(BaseComponent):
    """CPU Cooler component with specific properties."""
    height: Optional[Decimal] = None  # in mm
    is_water_cooled: Optional[bool] = None
    radiator_size: Optional[Decimal] = None  # in mm
    fan_quantity: Optional[int] = None


@dataclass
class CaseFanComponent(BaseComponent):
    """Case Fan component with specific properties."""
    quantity: Optional[int] = None


@dataclass
class MonitorComponent(BaseComponent):
    """Monitor component with specific properties."""


@dataclass
class ComponentCompatibility:
    id: str
    component_id: str
    compatible_component_id: str


# ========================================================================== #
# CHIPSET COMPATIBILITY MAPPINGS                                             #
# ========================================================================== #

# Intel chipset to supported CPU generations mapping
INTEL_CHIPSET_CPU_GENS = {
    # LGA 1700 chipsets (12th, 13th, 14th gen)
    "Z790": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    "Z690": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    "H770": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    "B760": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    "H670": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    "B660": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    "H610": ["12th", "13th", "14th", "Alder Lake", "Raptor Lake"],
    # LGA 1200 chipsets (10th, 11th gen)
    "Z590": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "Z490": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "H570": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "B560": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "H510": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "H470": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "B460": ["10th", "11th", "Comet Lake", "Rocket Lake"],
    "H410": ["10th", "Comet Lake"],
    # LGA 1151 v2 chipsets (8th, 9th gen)
    "Z390": ["8th", "9th", "Coffee Lake"],
    "Z370": ["8th", "9th", "Coffee Lake"],
    "B365": ["8th", "9th", "Coffee Lake"],
    "B360": ["8th", "9th", "Coffee Lake"],
    "H370": ["8th", "9th", "Coffee Lake"],
    "H310": ["8th", "9th", "Coffee Lake"],
    # HEDT chipsets
    "X299": ["Skylake-X", "Cascade Lake-X"],
    "X399": ["Threadripper"],
}

# AMD chipset to supported CPU generations mapping
AMD_CHIPSET_CPU_GENS = {
    # AM5 chipsets (Ryzen 7000, 8000, 9000)
    "X870E": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    "X870": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    "X670E": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    "X670": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    "B650E": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    "B650": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    "A620": ["Zen 4", "Zen 5", "Ryzen 7000", "Ryzen 8000", "Ryzen 9000"],
    # AM4 chipsets (Ryzen 1000-5000)
    "X570": ["Zen", "Zen+", "Zen 2", "Zen 3", "Ryzen 1000", "Ryzen 2000", "Ryzen 3000", "Ryzen 4000", "Ryzen 5000"],
    "B550": ["Zen 2", "Zen 3", "Ryzen 3000", "Ryzen 4000", "Ryzen 5000"],
    "A520": ["Zen 2", "Zen 3", "Ryzen 3000", "Ryzen 4000", "Ryzen 5000"],
    "X470": ["Zen", "Zen+", "Zen 2", "Zen 3", "Ryzen 1000", "Ryzen 2000", "Ryzen 3000", "Ryzen 5000"],
    "B450": ["Zen", "Zen+", "Zen 2", "Zen 3", "Ryzen 1000", "Ryzen 2000", "Ryzen 3000", "Ryzen 5000"],
    "X370": ["Zen", "Zen+", "Zen 2", "Ryzen 1000", "Ryzen 2000", "Ryzen 3000"],
    "B350": ["Zen", "Zen+", "Zen 2", "Ryzen 1000", "Ryzen 2000", "Ryzen 3000"],
    "A320": ["Zen", "Zen+", "Ryzen 1000", "Ryzen 2000"],
    # TRX40 (Threadripper)
    "TRX40": ["Zen 2", "Threadripper 3000"],
    "WRX80": ["Zen 3", "Threadripper PRO 5000"],
}

# Form factor compatibility (case to motherboard)
CASE_MOTHERBOARD_FORM_FACTOR_COMPAT = {
    # Case form factor -> list of compatible motherboard form factors
    "Full Tower": ["E-ATX", "ATX", "Micro-ATX", "Mini-ITX", "SSI-CEB", "SSI-EEB"],
    "Mid Tower": ["ATX", "Micro-ATX", "Mini-ITX"],
    "Mini Tower": ["Micro-ATX", "Mini-ITX"],
    "Mini-ITX": ["Mini-ITX"],
    "SFF": ["Mini-ITX", "Mini-DTX"],
    "HTPC": ["Mini-ITX", "Micro-ATX"],
    "Desktop": ["Micro-ATX", "Mini-ITX"],
    "ATX Mid Tower": ["ATX", "Micro-ATX", "Mini-ITX"],
    "ATX Full Tower": ["E-ATX", "ATX", "Micro-ATX", "Mini-ITX"],
    "MicroATX Mid Tower": ["Micro-ATX", "Mini-ITX"],
    "MicroATX Mini Tower": ["Micro-ATX", "Mini-ITX"],
}

# PSU form factor compatibility with case
PSU_CASE_FORM_FACTOR_COMPAT = {
    # PSU form factor -> compatible case form factors
    "ATX": ["Full Tower", "Mid Tower", "ATX Mid Tower", "ATX Full Tower", "Desktop"],
    "SFX": ["Mini-ITX", "SFF", "Mini Tower", "MicroATX Mini Tower"],
    "SFX-L": ["Mini-ITX", "SFF", "Mini Tower", "MicroATX Mini Tower", "Mid Tower"],
    "TFX": ["HTPC", "SFF", "Desktop"],
    "Flex ATX": ["SFF", "Mini-ITX"],
}


# ========================================================================== #
# DATABASE CONNECTION AND QUERY FUNCTIONS                                    #
# ========================================================================== #

class DatabaseConnection:
    """Manages database connection and queries."""
    
    def __init__(self, connection_string: str, odbc_driver: str = "ODBC Driver 17 for SQL Server"):
        self.connection_string = connection_string
        self.odbc_driver = odbc_driver
        self.connection: Optional[pyodbc.Connection] = None
        self.cursor: Optional[pyodbc.Cursor] = None
    
    def connect(self) -> None:
        """Establish database connection."""
        try:
            # Add ODBC driver to connection string if not present
            conn_str = self.connection_string
            if "Driver=" not in conn_str:
                conn_str = f"Driver={{{self.odbc_driver}}};{conn_str}"
            
            self.connection = pyodbc.connect(conn_str)
            self.cursor = self.connection.cursor()
            logger.info("Successfully connected to database")
        except pyodbc.Error as e:
            logger.error(f"Failed to connect to database: {e}")
            raise
    
    def disconnect(self) -> None:
        """Close database connection."""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("Disconnected from database")
    
    def execute(self, query: str, params: Optional[tuple] = None) -> pyodbc.Cursor:
        """Execute a query and return the cursor."""
        if params:
            return self.cursor.execute(query, params)
        return self.cursor.execute(query)
    
    def executemany(self, query: str, params_list: List[tuple]) -> None:
        """Execute a query with multiple parameter sets."""
        self.cursor.executemany(query, params_list)
    
    def commit(self) -> None:
        """Commit the current transaction."""
        self.connection.commit()
    
    def fetchall(self) -> List[tuple]:
        """Fetch all results from the last query."""
        return self.cursor.fetchall()
    
    def fetchone(self) -> Optional[tuple]:
        """Fetch one result from the last query."""
        return self.cursor.fetchone()


# ========================================================================== #
# COMPONENT LOADING FUNCTIONS                                                #
# ========================================================================== #

def load_subcomponents_for_component(db: DatabaseConnection, component_id: str) -> List[SubComponent]:
    """Load all subcomponents for a given component."""
    subcomponents = []
    
    # Query to get subcomponents through ComponentParts
    query = """
        SELECT 
            sc.Id, sc.Name, sc.Type, cp.Amount,
            ps.PortType,
            cs.SocketType
        FROM ComponentParts cp
        INNER JOIN SubComponents sc ON cp.SubComponentId = sc.Id
        LEFT JOIN PortSubComponents ps ON sc.Id = ps.Id
        LEFT JOIN CoolerSocketSubComponents cs ON sc.Id = cs.Id
        WHERE cp.ComponentId = ?
    """
    
    db.execute(query, (component_id,))
    rows = db.fetchall()
    
    for row in rows:
        subcomponent = SubComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "",
            amount=row[3] or 1,
            port_type=row[4],
            socket_type=row[5],
        )
        subcomponents.append(subcomponent)
    
    return subcomponents


def load_cpus(db: DatabaseConnection) -> List[CPUComponent]:
    """Load all CPU components from the database."""
    cpus = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            cpu.Series, cpu.Microarchitecture, cpu.CoreFamily, cpu.SocketType,
            cpu.ThermalDesignPower
        FROM Components c
        INNER JOIN CPUComponents cpu ON c.Id = cpu.Id
        WHERE c.Type = 'CPU'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading CPUs", unit="cpu", leave=False):
        cpu = CPUComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "CPU",
            series=row[3],
            microarchitecture=row[4],
            core_family=row[5],
            socket_type=row[6],
            thermal_design_power=Decimal(str(row[7])) if row[7] is not None else None,
        )
        cpu.subcomponents = load_subcomponents_for_component(db, cpu.id)
        cpus.append(cpu)
    
    logger.info(f"Loaded {len(cpus)} CPU components")
    return cpus


def load_motherboards(db: DatabaseConnection) -> List[MotherboardComponent]:
    """Load all motherboard components from the database."""
    motherboards = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            mb.SocketType, mb.FormFactor, mb.ChipsetType, mb.RAMType,
            mb.RAMSlotsAmount, mb.MaxRAMAmount, mb.CaseFanHeaderAmount
        FROM Components c
        INNER JOIN MotherboardComponents mb ON c.Id = mb.Id
        WHERE c.Type = 'MOTHERBOARD'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Motherboards", unit="mb", leave=False):
        # Parse RAMSlotsAmount - it might be stored as a string
        ram_slots = row[7]
        if isinstance(ram_slots, str):
            try:
                ram_slots = int(ram_slots)
            except ValueError:
                ram_slots = None
        
        mb = MotherboardComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "MOTHERBOARD",
            socket_type=row[3],
            form_factor=row[4],
            chipset_type=row[5],
            ram_type=row[6],
            ram_slots_amount=ram_slots,
            max_ram_amount=row[8],
            case_fan_header_amount=row[9],
        )
        mb.subcomponents = load_subcomponents_for_component(db, mb.id)
        motherboards.append(mb)
    
    logger.info(f"Loaded {len(motherboards)} Motherboard components")
    return motherboards


def load_cases(db: DatabaseConnection) -> List[CaseComponent]:
    """Load all case components from the database."""
    cases = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            cs.FormFactor, cs.MaxVideoCardLength, cs.MaxCPUCoolerHeight,
            cs.ExpansionSlotAmount, cs.Dimensions_Depth, cs.Dimensions_Height
        FROM Components c
        INNER JOIN CaseComponents cs ON c.Id = cs.Id
        WHERE c.Type = 'CASE'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Cases", unit="case", leave=False):
        case = CaseComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "CASE",
            form_factor=row[3],
            max_video_card_length=Decimal(str(row[4])) if row[4] is not None else None,
            max_cpu_cooler_height=Decimal(str(row[5])) if row[5] is not None else None,
            expansion_slot_amount=row[6],
            dimensions_depth=Decimal(str(row[7])) if row[7] is not None else None,
            dimensions_height=Decimal(str(row[8])) if row[8] is not None else None,
        )
        case.subcomponents = load_subcomponents_for_component(db, case.id)
        cases.append(case)
    
    logger.info(f"Loaded {len(cases)} Case components")
    return cases


def load_gpus(db: DatabaseConnection) -> List[GPUComponent]:
    """Load all GPU components from the database."""
    gpus = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            gpu.ThermalDesignPower, gpu.Length, 
            gpu.CaseExpansionSlotWidth, gpu.TotalSlotAmount
        FROM Components c
        INNER JOIN GPUComponents gpu ON c.Id = gpu.Id
        WHERE c.Type = 'GPU'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading GPUs", unit="gpu", leave=False):
        gpu = GPUComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "GPU",
            thermal_design_power=Decimal(str(row[3])) if row[3] is not None else None,
            length=Decimal(str(row[4])) if row[4] is not None else None,
            case_expansion_slot_width=row[5],
            total_slot_amount=row[6],
        )
        gpu.subcomponents = load_subcomponents_for_component(db, gpu.id)
        gpus.append(gpu)
    
    logger.info(f"Loaded {len(gpus)} GPU components")
    return gpus


def load_memory(db: DatabaseConnection) -> List[MemoryComponent]:
    """Load all memory components from the database."""
    memories = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            mem.RAMType, mem.Capacity, mem.ModuleQuantity
        FROM Components c
        INNER JOIN MemoryComponents mem ON c.Id = mem.Id
        WHERE c.Type = 'MEMORY'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Memory", unit="mem", leave=False):
        memory = MemoryComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "MEMORY",
            ram_type=row[3],
            capacity=Decimal(str(row[4])) if row[4] is not None else None,
            module_quantity=row[5],
        )
        memory.subcomponents = load_subcomponents_for_component(db, memory.id)
        memories.append(memory)
    
    logger.info(f"Loaded {len(memories)} Memory components")
    return memories


def load_storage(db: DatabaseConnection) -> List[StorageComponent]:
    """Load all storage components from the database."""
    storages = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            st.FormFactor
        FROM Components c
        INNER JOIN StorageComponents st ON c.Id = st.Id
        WHERE c.Type = 'STORAGE'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Storage", unit="storage", leave=False):
        storage = StorageComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "STORAGE",
            form_factor=row[3],
        )
        storage.subcomponents = load_subcomponents_for_component(db, storage.id)
        storages.append(storage)
    
    logger.info(f"Loaded {len(storages)} Storage components")
    return storages


def load_power_supplies(db: DatabaseConnection) -> List[PowerSupplyComponent]:
    """Load all power supply components from the database."""
    psus = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            psu.PowerOutput, psu.FormFactor, psu.Length
        FROM Components c
        INNER JOIN PowerSupplyComponents psu ON c.Id = psu.Id
        WHERE c.Type = 'POWER_SUPPLY'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading PSUs", unit="psu", leave=False):
        psu = PowerSupplyComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "POWER_SUPPLY",
            power_output=Decimal(str(row[3])) if row[3] is not None else None,
            form_factor=row[4],
            length=Decimal(str(row[5])) if row[5] is not None else None,
        )
        psu.subcomponents = load_subcomponents_for_component(db, psu.id)
        psus.append(psu)
    
    logger.info(f"Loaded {len(psus)} Power Supply components")
    return psus


def load_coolers(db: DatabaseConnection) -> List[CoolerComponent]:
    """Load all cooler components from the database."""
    coolers = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            cl.Height, cl.IsWaterCooled, cl.RadiatorSize, cl.FanQuantity
        FROM Components c
        INNER JOIN CoolerComponents cl ON c.Id = cl.Id
        WHERE c.Type = 'COOLER'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Coolers", unit="cooler", leave=False):
        cooler = CoolerComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "COOLER",
            height=Decimal(str(row[3])) if row[3] is not None else None,
            is_water_cooled=row[4],
            radiator_size=Decimal(str(row[5])) if row[5] is not None else None,
            fan_quantity=row[6],
        )
        cooler.subcomponents = load_subcomponents_for_component(db, cooler.id)
        coolers.append(cooler)
    
    logger.info(f"Loaded {len(coolers)} Cooler components")
    return coolers


def load_case_fans(db: DatabaseConnection) -> List[CaseFanComponent]:
    """Load all case fan components from the database."""
    case_fans = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type,
            cf.Quantity
        FROM Components c
        INNER JOIN CaseFanComponents cf ON c.Id = cf.Id
        WHERE c.Type = 'CASE_FAN'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Case Fans", unit="fan", leave=False):
        case_fan = CaseFanComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "CASE_FAN",
            quantity=row[3],
        )
        case_fan.subcomponents = load_subcomponents_for_component(db, case_fan.id)
        case_fans.append(case_fan)
    
    logger.info(f"Loaded {len(case_fans)} Case Fan components")
    return case_fans


def load_monitors(db: DatabaseConnection) -> List[MonitorComponent]:
    """Load all monitor components from the database."""
    monitors = []
    
    query = """
        SELECT 
            c.Id, c.Name, c.Type
        FROM Components c
        WHERE c.Type = 'MONITOR'
    """
    
    db.execute(query)
    rows = db.fetchall()
    
    for row in tqdm(rows, desc="Loading Monitors", unit="monitor", leave=False):
        monitor = MonitorComponent(
            id=str(row[0]),
            name=row[1] or "",
            type=row[2] or "MONITOR",
        )
        monitor.subcomponents = load_subcomponents_for_component(db, monitor.id)
        monitors.append(monitor)
    
    logger.info(f"Loaded {len(monitors)} Monitor components")
    return monitors


def load_existing_compatibilities(db: DatabaseConnection) -> Set[Tuple[str, str]]:
    """Load all existing component compatibilities from the database."""
    query = "SELECT ComponentId, CompatibleComponentId FROM ComponentCompatibilities"
    db.execute(query)
    rows = db.fetchall()
    
    compatibilities = set()
    for row in rows:
        compatibilities.add((str(row[0]), str(row[1])))
    
    logger.info(f"Loaded {len(compatibilities)} existing compatibilities")
    return compatibilities


# ========================================================================== #
# COMPATIBILITY CHECK FUNCTIONS                                              #
# ========================================================================== #

def normalize_socket(socket: Optional[str]) -> Optional[str]:
    """Normalize socket name for comparison."""
    if socket is None:
        return None
    
    socket = socket.strip().upper()
    
    # Normalize common variations
    socket = socket.replace(" ", "")
    socket = socket.replace("-", "")
    
    # Normalize LGA variations
    socket = re.sub(r"^LGA(\d+)", r"LGA\1", socket)
    
    # Normalize AM variations
    socket = re.sub(r"^AM(\d+)", r"AM\1", socket)
    
    return socket


def normalize_form_factor(form_factor: Optional[str]) -> Optional[str]:
    """Normalize form factor name for comparison."""
    if form_factor is None:
        return None
    
    ff = form_factor.strip().lower()
    
    # Common normalizations
    ff = ff.replace("-", "")
    ff = ff.replace(" ", "")
    
    # Map common variations
    mappings = {
        "microatx": "micro-atx",
        "matx": "micro-atx",
        "miniitx": "mini-itx",
        "mitx": "mini-itx",
        "eatx": "e-atx",
        "extendedatx": "e-atx",
    }
    
    return mappings.get(ff, form_factor.strip())


def normalize_ddr_type(ram_type: Optional[str]) -> Optional[str]:
    """Normalize DDR type for comparison."""
    if ram_type is None:
        return None
    
    ram = ram_type.strip().upper()
    
    # Extract DDR version
    match = re.search(r"DDR(\d+)", ram)
    if match:
        return f"DDR{match.group(1)}"
    
    return ram


def extract_chipset_name(chipset: Optional[str]) -> Optional[str]:
    """Extract the core chipset name from a full chipset string."""
    if chipset is None:
        return None
    
    chipset = chipset.strip().upper()
    
    # Common chipset patterns
    patterns = [
        r"(Z\d{3})",  # Z790, Z690, etc.
        r"(H\d{3})",  # H770, H610, etc.
        r"(B\d{3})",  # B760, B660, etc.
        r"(X\d{3}E?)",  # X670E, X570, etc.
        r"(A\d{3})",  # A620, A520, etc.
        r"(TRX\d{2})",  # TRX40
        r"(WRX\d{2})",  # WRX80
    ]
    
    for pattern in patterns:
        match = re.search(pattern, chipset)
        if match:
            return match.group(1)
    
    return chipset


def check_chipset_cpu_compatibility(chipset: Optional[str], cpu: CPUComponent) -> bool:
    """Check if a chipset supports a CPU generation."""
    if chipset is None:
        return False
    
    chipset_name = extract_chipset_name(chipset)
    if chipset_name is None:
        return False
    
    # Check Intel chipsets
    if chipset_name in INTEL_CHIPSET_CPU_GENS:
        supported_gens = INTEL_CHIPSET_CPU_GENS[chipset_name]
        # Check microarchitecture, series, or core family
        for gen in supported_gens:
            gen_lower = gen.lower()
            if cpu.microarchitecture and gen_lower in cpu.microarchitecture.lower():
                return True
            if cpu.series and gen_lower in cpu.series.lower():
                return True
            if cpu.core_family and gen_lower in cpu.core_family.lower():
                return True
        return False
    
    # Check AMD chipsets
    if chipset_name in AMD_CHIPSET_CPU_GENS:
        supported_gens = AMD_CHIPSET_CPU_GENS[chipset_name]
        for gen in supported_gens:
            gen_lower = gen.lower()
            if cpu.microarchitecture and gen_lower in cpu.microarchitecture.lower():
                return True
            if cpu.series and gen_lower in cpu.series.lower():
                return True
            if cpu.core_family and gen_lower in cpu.core_family.lower():
                return True
        return False
    
    # Unknown chipset - be permissive
    return True


def check_case_motherboard_form_factor(case: CaseComponent, motherboard: MotherboardComponent) -> bool:
    """Check if a case supports a motherboard's form factor."""
    if case.form_factor is None or motherboard.form_factor is None:
        return False
    
    case_ff = case.form_factor.strip()
    mb_ff = normalize_form_factor(motherboard.form_factor)
    
    # Check direct compatibility mapping
    for case_type, supported_mbs in CASE_MOTHERBOARD_FORM_FACTOR_COMPAT.items():
        if case_type.lower() in case_ff.lower():
            for supported in supported_mbs:
                if normalize_form_factor(supported) == mb_ff or supported.lower() in mb_ff.lower():
                    return True
    
    # Fallback: check if MB form factor is mentioned in case form factor
    if mb_ff and mb_ff.lower() in case_ff.lower():
        return True
    
    # More permissive: larger cases generally support smaller boards
    size_order = ["mini-itx", "micro-atx", "atx", "e-atx"]
    case_ff_norm = normalize_form_factor(case_ff)
    
    try:
        case_idx = next((i for i, s in enumerate(size_order) if s in case_ff_norm.lower()), -1)
        mb_idx = next((i for i, s in enumerate(size_order) if s in mb_ff.lower()), -1)
        
        if case_idx >= 0 and mb_idx >= 0:
            return case_idx >= mb_idx
    except:
        pass
    
    return False


def get_pcie_power_connector_count(psu: PowerSupplyComponent) -> int:
    """Count the number of PCIe power connectors on a PSU."""
    count = 0
    for sub in psu.subcomponents:
        if sub.type == SubComponentType.PORT and sub.port_type == "POWER":
            # Check if it's a PCIe power connector
            name_lower = sub.name.lower() if sub.name else ""
            if "pcie" in name_lower or "pci-e" in name_lower or "gpu" in name_lower:
                count += sub.amount
    return count


def get_gpu_power_connector_requirement(gpu: GPUComponent) -> int:
    """Estimate the number of PCIe power connectors required by a GPU."""
    # Count power subcomponents
    for sub in gpu.subcomponents:
        if sub.type == SubComponentType.PORT and sub.port_type == "POWER":
            return sub.amount
    
    # Estimate based on TDP if no subcomponents
    if gpu.thermal_design_power:
        tdp = float(gpu.thermal_design_power)
        if tdp <= 75:
            return 0  # PCIe slot power only
        elif tdp <= 150:
            return 1
        elif tdp <= 300:
            return 2
        else:
            return 3
    
    return 1  # Default assumption


def get_m2_slot_count(motherboard: MotherboardComponent) -> int:
    """Count the number of M.2 slots on a motherboard."""
    count = 0
    for sub in motherboard.subcomponents:
        if sub.type == SubComponentType.M2_SLOT:
            count += sub.amount
    return count


def get_usb_header_types(motherboard: MotherboardComponent) -> Set[str]:
    """Get the set of internal USB header types on a motherboard."""
    headers = set()
    for sub in motherboard.subcomponents:
        if sub.type == SubComponentType.PORT and sub.port_type == "USB":
            name_lower = sub.name.lower() if sub.name else ""
            if "header" in name_lower or "internal" in name_lower:
                # Extract USB type
                if "3.2" in name_lower or "3.1" in name_lower or "3.0" in name_lower:
                    headers.add("USB3")
                elif "2.0" in name_lower:
                    headers.add("USB2")
                elif "type-c" in name_lower or "usb-c" in name_lower:
                    headers.add("USB-C")
    return headers


def get_case_front_usb_types(case: CaseComponent) -> Set[str]:
    """Get the set of front panel USB types on a case."""
    usb_types = set()
    for sub in case.subcomponents:
        if sub.type == SubComponentType.PORT and sub.port_type == "USB":
            name_lower = sub.name.lower() if sub.name else ""
            if "3.2" in name_lower or "3.1" in name_lower or "3.0" in name_lower:
                usb_types.add("USB3")
            elif "2.0" in name_lower:
                usb_types.add("USB2")
            elif "type-c" in name_lower or "usb-c" in name_lower:
                usb_types.add("USB-C")
    return usb_types


def get_cooler_supported_sockets(cooler: CoolerComponent) -> Set[str]:
    """Get the set of sockets supported by a cooler."""
    sockets = set()
    for sub in cooler.subcomponents:
        if sub.type == SubComponentType.COOLER_SOCKET and sub.socket_type:
            sockets.add(normalize_socket(sub.socket_type))
    return sockets


def estimate_system_wattage(cpu: CPUComponent, gpu: Optional[GPUComponent] = None) -> Decimal:
    """Estimate the total system wattage."""
    total = Decimal("100")  # Base system overhead (mobo, RAM, storage, fans)
    
    if cpu.thermal_design_power:
        total += cpu.thermal_design_power
    else:
        total += Decimal("125")  # Default CPU estimate
    
    if gpu and gpu.thermal_design_power:
        total += gpu.thermal_design_power
    
    # Add 20% headroom
    return total * Decimal("1.2")


# ========================================================================== #
# COMPATIBILITY RULE IMPLEMENTATIONS                                         #
# ========================================================================== #

def check_cpu_motherboard_compatibility(cpu: CPUComponent, motherboard: MotherboardComponent) -> Tuple[bool, str]:
    """
    Check CPU and Motherboard compatibility.
    Rules:
    - CPU and Motherboard sockets must match.
    - Motherboard chipset must support the CPU generation.
    """
    # Check socket compatibility
    if cpu.socket_type is None:
        return False, "CPU socket type is null"
    if motherboard.socket_type is None:
        return False, "Motherboard socket type is null"
    
    cpu_socket = normalize_socket(cpu.socket_type)
    mb_socket = normalize_socket(motherboard.socket_type)
    
    if cpu_socket != mb_socket:
        return False, f"Socket mismatch: CPU {cpu_socket} vs MB {mb_socket}"
    
    # Check chipset compatibility
    if motherboard.chipset_type is None:
        return False, "Motherboard chipset is null"
    
    if not check_chipset_cpu_compatibility(motherboard.chipset_type, cpu):
        return False, f"Chipset {motherboard.chipset_type} does not support CPU generation"
    
    return True, "Compatible"


def check_motherboard_case_compatibility(motherboard: MotherboardComponent, case: CaseComponent) -> Tuple[bool, str]:
    """
    Check Motherboard and Case compatibility.
    Rules:
    - Case must support the motherboard form factor.
    """
    if motherboard.form_factor is None:
        return False, "Motherboard form factor is null"
    if case.form_factor is None:
        return False, "Case form factor is null"
    
    if not check_case_motherboard_form_factor(case, motherboard):
        return False, f"Case {case.form_factor} does not support MB form factor {motherboard.form_factor}"
    
    return True, "Compatible"


def check_memory_motherboard_compatibility(memory: MemoryComponent, motherboard: MotherboardComponent) -> Tuple[bool, str]:
    """
    Check Memory and Motherboard compatibility.
    Rules:
    - RAM DDR version must match motherboard DDR version.
    - Number of RAM sticks must not exceed available slots.
    - Total RAM capacity must not exceed motherboard limit.
    """
    # Check DDR version
    if memory.ram_type is None:
        return False, "Memory RAM type is null"
    if motherboard.ram_type is None:
        return False, "Motherboard RAM type is null"
    
    mem_ddr = normalize_ddr_type(memory.ram_type)
    mb_ddr = normalize_ddr_type(motherboard.ram_type)
    
    if mem_ddr != mb_ddr:
        return False, f"DDR mismatch: Memory {mem_ddr} vs MB {mb_ddr}"
    
    # Check slot count
    if memory.module_quantity is None:
        return False, "Memory module quantity is null"
    if motherboard.ram_slots_amount is None:
        return False, "Motherboard RAM slots amount is null"
    
    if memory.module_quantity > motherboard.ram_slots_amount:
        return False, f"Too many RAM modules: {memory.module_quantity} > {motherboard.ram_slots_amount} slots"
    
    # Check capacity
    if memory.capacity is None:
        return False, "Memory capacity is null"
    if motherboard.max_ram_amount is None:
        return False, "Motherboard max RAM amount is null"
    
    # Convert memory capacity from MB to GB for comparison
    memory_capacity_gb = memory.capacity / Decimal("1024")
    
    if memory_capacity_gb > motherboard.max_ram_amount:
        return False, f"RAM capacity {memory_capacity_gb}GB exceeds MB limit {motherboard.max_ram_amount}GB"
    
    return True, "Compatible"


def check_gpu_case_compatibility(gpu: GPUComponent, case: CaseComponent) -> Tuple[bool, str]:
    """
    Check GPU and Case compatibility.
    Rules:
    - GPU length must fit within the case maximum.
    - GPU thickness must fit within available case expansion slots.
    """
    # Check if case has dimensions declared
    has_dimensions = (case.dimensions_depth is not None or 
                      case.dimensions_height is not None or 
                      case.dimensions_width is not None or
                      case.max_video_card_length is not None)
    
    # Check GPU length
    if gpu.length is not None and case.max_video_card_length is not None:
        if gpu.length > case.max_video_card_length:
            return False, f"GPU length {gpu.length}mm exceeds case max {case.max_video_card_length}mm"
    elif gpu.length is not None and case.max_video_card_length is None:
        if has_dimensions:
            return False, "Case max video card length is null"
    elif gpu.length is None:
        return False, "GPU length is null"
    
    # Check expansion slots
    gpu_slots = gpu.total_slot_amount or gpu.case_expansion_slot_width
    
    if gpu_slots is not None and case.expansion_slot_amount is not None:
        if gpu_slots > case.expansion_slot_amount:
            return False, f"GPU requires {gpu_slots} slots, case has {case.expansion_slot_amount}"
    elif gpu_slots is not None and case.expansion_slot_amount is None:
        return False, "Case expansion slot amount is null"
    elif gpu_slots is None:
        return False, "GPU slot width is null"
    
    return True, "Compatible"


def check_psu_system_compatibility(psu: PowerSupplyComponent, cpu: CPUComponent, gpu: Optional[GPUComponent] = None) -> Tuple[bool, str]:
    """
    Check PSU wattage compatibility with system.
    Rules:
    - PSU wattage must cover total system estimated wattage.
    """
    if psu.power_output is None:
        return False, "PSU power output is null"
    
    estimated_wattage = estimate_system_wattage(cpu, gpu)
    
    if psu.power_output < estimated_wattage:
        return False, f"PSU {psu.power_output}W insufficient for estimated {estimated_wattage}W system"
    
    return True, "Compatible"


def check_cooler_cpu_compatibility(cooler: CoolerComponent, cpu: CPUComponent) -> Tuple[bool, str]:
    """
    Check Cooler and CPU compatibility.
    Rules:
    - Cooler must support the CPU socket.
    """
    if cpu.socket_type is None:
        return False, "CPU socket type is null"
    
    supported_sockets = get_cooler_supported_sockets(cooler)
    
    if not supported_sockets:
        # No socket info in subcomponents - check by name patterns
        cooler_name_lower = cooler.name.lower() if cooler.name else ""
        cpu_socket_norm = normalize_socket(cpu.socket_type)
        
        # Be permissive if we can't determine socket support
        if cpu_socket_norm:
            socket_patterns = [cpu_socket_norm.lower(), cpu.socket_type.lower()]
            for pattern in socket_patterns:
                if pattern in cooler_name_lower:
                    return True, "Compatible (name match)"
        
        return False, "Cooler socket support information is null"
    
    cpu_socket = normalize_socket(cpu.socket_type)
    
    if cpu_socket not in supported_sockets:
        return False, f"Cooler does not support socket {cpu_socket}"
    
    return True, "Compatible"


def check_cooler_case_compatibility(cooler: CoolerComponent, case: CaseComponent) -> Tuple[bool, str]:
    """
    Check Cooler and Case compatibility.
    Rules:
    - Air cooler height must fit within case clearance.
    - Liquid cooler radiator size must be supported by the case.
    """
    # Check if case has dimensions declared
    has_dimensions = (case.dimensions_depth is not None or 
                      case.dimensions_height is not None or 
                      case.dimensions_width is not None or
                      case.max_cpu_cooler_height is not None)
    
    # Check if it's a water cooler
    if cooler.is_water_cooled:
        # Check radiator size
        if cooler.radiator_size is None:
            return False, "Water cooler radiator size is null"
        
        # We don't have direct radiator support info in case, so be permissive
        # Larger cases generally support larger radiators
        if has_dimensions and case.dimensions_height is not None:
            # Rough estimate: case height should be at least radiator size + 100mm for clearance
            if case.dimensions_height < cooler.radiator_size + Decimal("100"):
                return False, f"Case too small for {cooler.radiator_size}mm radiator"
        
        return True, "Compatible"
    else:
        # Air cooler - check height
        if cooler.height is None:
            return False, "Air cooler height is null"
        
        if case.max_cpu_cooler_height is not None:
            if cooler.height > case.max_cpu_cooler_height:
                return False, f"Cooler height {cooler.height}mm exceeds case max {case.max_cpu_cooler_height}mm"
        elif has_dimensions:
            return False, "Case max CPU cooler height is null"
        
        return True, "Compatible"


def check_storage_motherboard_compatibility(storage: StorageComponent, motherboard: MotherboardComponent) -> Tuple[bool, str]:
    """
    Check Storage and Motherboard compatibility.
    Rules:
    - Storage M.2 drive count must not exceed motherboard slots.
    """
    # Only check M.2 drives
    if storage.form_factor is None:
        return False, "Storage form factor is null"
    
    if "m.2" not in storage.form_factor.lower() and "m2" not in storage.form_factor.lower():
        # Not an M.2 drive, assume compatible
        return True, "Compatible (not M.2)"
    
    m2_slots = get_m2_slot_count(motherboard)
    
    if m2_slots == 0:
        return False, "Motherboard has no M.2 slots"
    
    # Single drive is compatible if there's at least one slot
    return True, "Compatible"


def check_psu_case_compatibility(psu: PowerSupplyComponent, case: CaseComponent) -> Tuple[bool, str]:
    """
    Check PSU and Case compatibility.
    Rules:
    - PSU form factor must match case support.
    - PSU length must fit within case PSU clearance.
    """
    # Check form factor
    if psu.form_factor is None:
        return False, "PSU form factor is null"
    if case.form_factor is None:
        return False, "Case form factor is null"
    
    psu_ff = psu.form_factor.strip().upper()
    
    # Check if PSU form factor is compatible with case
    compatible_cases = PSU_CASE_FORM_FACTOR_COMPAT.get(psu_ff, [])
    
    case_compatible = False
    for case_type in compatible_cases:
        if case_type.lower() in case.form_factor.lower():
            case_compatible = True
            break
    
    # Also check if it's a standard ATX case with ATX PSU
    if not case_compatible:
        if "ATX" in psu_ff and ("tower" in case.form_factor.lower() or "atx" in case.form_factor.lower()):
            case_compatible = True
    
    if not case_compatible:
        return False, f"PSU form factor {psu_ff} not compatible with case {case.form_factor}"
    
    # Check PSU length (we don't have explicit PSU clearance, but can estimate)
    # Typically, mid-tower cases can fit PSUs up to 200mm
    if psu.length is not None and case.dimensions_depth is not None:
        # Rough estimate: PSU should be less than 40% of case depth
        max_psu_length = case.dimensions_depth * Decimal("0.4")
        if psu.length > max_psu_length:
            return False, f"PSU length {psu.length}mm may not fit in case (estimated max {max_psu_length}mm)"
    
    return True, "Compatible"


def check_psu_gpu_compatibility(psu: PowerSupplyComponent, gpu: GPUComponent) -> Tuple[bool, str]:
    """
    Check PSU and GPU power connector compatibility.
    Rules:
    - PSU must have enough PCIe power connectors for the GPU.
    """
    gpu_required = get_gpu_power_connector_requirement(gpu)
    
    if gpu_required == 0:
        return True, "Compatible (no power connectors required)"
    
    psu_available = get_pcie_power_connector_count(psu)
    
    if psu_available == 0:
        # No subcomponent info - estimate based on wattage
        if psu.power_output is not None:
            if psu.power_output >= Decimal("500"):
                return True, "Compatible (estimated)"
            else:
                return False, "PSU wattage too low for discrete GPU"
        return False, "PSU PCIe power connector count is null"
    
    if psu_available < gpu_required:
        return False, f"PSU has {psu_available} PCIe connectors, GPU needs {gpu_required}"
    
    return True, "Compatible"


def check_case_front_panel_motherboard_compatibility(case: CaseComponent, motherboard: MotherboardComponent) -> Tuple[bool, str]:
    """
    Check Case front panel and Motherboard USB header compatibility.
    Rules:
    - Case Front Panel USB types must match available Motherboard internal headers.
    """
    case_usb_types = get_case_front_usb_types(case)
    mb_header_types = get_usb_header_types(motherboard)
    
    if not case_usb_types:
        # No front panel USB - compatible
        return True, "Compatible (no front USB)"
    
    if not mb_header_types:
        # No header info - be permissive
        return True, "Compatible (no header info)"
    
    # Check that all case USB types have matching motherboard headers
    for usb_type in case_usb_types:
        if usb_type not in mb_header_types:
            return False, f"Case has {usb_type} but motherboard lacks matching header"
    
    return True, "Compatible"

def check_case_fan_motherboard_compatibility(case_fan: CaseFanComponent, motherboard: MotherboardComponent) -> Tuple[bool, str]:
    """
    Check Case Fan and Motherboard compatibility.
    Rules:
    - Case fan quantity must be less or equal to Motherboard fan header amount.
    """
    if case_fan.quantity is None:
        return False, "Case fan quantity is null"
    
    # Get total fan headers (case fan + CPU fan headers can sometimes be used)
    total_headers = 0
    if motherboard.case_fan_header_amount is not None:
        total_headers += motherboard.case_fan_header_amount
    
    if total_headers == 0:
        return False, "Motherboard fan header amount is null or zero"
    
    if case_fan.quantity > total_headers:
        return False, f"Case fan quantity {case_fan.quantity} exceeds motherboard headers {total_headers}"
    
    return True, "Compatible"


def check_psu_cpu_compatibility(psu: PowerSupplyComponent, cpu: CPUComponent) -> Tuple[bool, str]:
    """
    Check PSU and CPU compatibility based on wattage.
    Rules:
    - PSU wattage must cover CPU TDP with headroom.
    """
    if psu.power_output is None:
        return False, "PSU power output is null"
    
    estimated_wattage = estimate_system_wattage(cpu, None)
    
    if psu.power_output < estimated_wattage:
        return False, f"PSU {psu.power_output}W insufficient for CPU (estimated {estimated_wattage}W system)"
    
    return True, "Compatible"


# ========================================================================== #
# COMPATIBILITY GENERATION ENGINE                                            #
# ========================================================================== #

@dataclass
class CompatibilityResult:
    """Result of a compatibility check."""
    component_id: str
    compatible_component_id: str
    is_compatible: bool
    reason: str


def generate_all_compatibilities(
    cpus: List[CPUComponent],
    motherboards: List[MotherboardComponent],
    cases: List[CaseComponent],
    gpus: List[GPUComponent],
    memories: List[MemoryComponent],
    storages: List[StorageComponent],
    psus: List[PowerSupplyComponent],
    coolers: List[CoolerComponent],
    case_fans: List[CaseFanComponent],
    monitors: List[MonitorComponent],
) -> List[CompatibilityResult]:
    """
    Generate all compatibility pairs between components.
    Returns a list of CompatibilityResult for compatible pairs only.
    """
    compatible_pairs: List[CompatibilityResult] = []
    
    total_checks = 0
    compatible_count = 0
    
    # CPU <-> Motherboard
    cpu_mb_pairs = [(cpu, mb) for cpu in cpus for mb in motherboards]
    for cpu, mb in tqdm(cpu_mb_pairs, desc="CPU <-> Motherboard", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_cpu_motherboard_compatibility(cpu, mb)
        if is_compat:
            compatible_count += 1
            compatible_pairs.append(CompatibilityResult(cpu.id, mb.id, True, reason))
            compatible_pairs.append(CompatibilityResult(mb.id, cpu.id, True, reason))
    logger.info(f"  CPU <-> Motherboard: {compatible_count} compatible pairs found")
    
    # Motherboard <-> Case
    mb_case_pairs = [(mb, case) for mb in motherboards for case in cases]
    mb_case_count = 0
    for mb, case in tqdm(mb_case_pairs, desc="Motherboard <-> Case", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_motherboard_case_compatibility(mb, case)
        if is_compat:
            mb_case_count += 1
            compatible_pairs.append(CompatibilityResult(mb.id, case.id, True, reason))
            compatible_pairs.append(CompatibilityResult(case.id, mb.id, True, reason))
    compatible_count += mb_case_count
    logger.info(f"  Motherboard <-> Case: {mb_case_count} compatible pairs found")
    
    # Memory <-> Motherboard
    mem_mb_pairs = [(memory, mb) for memory in memories for mb in motherboards]
    mem_mb_count = 0
    for memory, mb in tqdm(mem_mb_pairs, desc="Memory <-> Motherboard", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_memory_motherboard_compatibility(memory, mb)
        if is_compat:
            mem_mb_count += 1
            compatible_pairs.append(CompatibilityResult(memory.id, mb.id, True, reason))
            compatible_pairs.append(CompatibilityResult(mb.id, memory.id, True, reason))
    compatible_count += mem_mb_count
    logger.info(f"  Memory <-> Motherboard: {mem_mb_count} compatible pairs found")
    
    # GPU <-> Case
    gpu_case_pairs = [(gpu, case) for gpu in gpus for case in cases]
    gpu_case_count = 0
    for gpu, case in tqdm(gpu_case_pairs, desc="GPU <-> Case", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_gpu_case_compatibility(gpu, case)
        if is_compat:
            gpu_case_count += 1
            compatible_pairs.append(CompatibilityResult(gpu.id, case.id, True, reason))
            compatible_pairs.append(CompatibilityResult(case.id, gpu.id, True, reason))
    compatible_count += gpu_case_count
    logger.info(f"  GPU <-> Case: {gpu_case_count} compatible pairs found")
    
    # Cooler <-> CPU
    cooler_cpu_pairs = [(cooler, cpu) for cooler in coolers for cpu in cpus]
    cooler_cpu_count = 0
    for cooler, cpu in tqdm(cooler_cpu_pairs, desc="Cooler <-> CPU", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_cooler_cpu_compatibility(cooler, cpu)
        if is_compat:
            cooler_cpu_count += 1
            compatible_pairs.append(CompatibilityResult(cooler.id, cpu.id, True, reason))
            compatible_pairs.append(CompatibilityResult(cpu.id, cooler.id, True, reason))
    compatible_count += cooler_cpu_count
    logger.info(f"  Cooler <-> CPU: {cooler_cpu_count} compatible pairs found")
    
    # Cooler <-> Case
    cooler_case_pairs = [(cooler, case) for cooler in coolers for case in cases]
    cooler_case_count = 0
    for cooler, case in tqdm(cooler_case_pairs, desc="Cooler <-> Case", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_cooler_case_compatibility(cooler, case)
        if is_compat:
            cooler_case_count += 1
            compatible_pairs.append(CompatibilityResult(cooler.id, case.id, True, reason))
            compatible_pairs.append(CompatibilityResult(case.id, cooler.id, True, reason))
    compatible_count += cooler_case_count
    logger.info(f"  Cooler <-> Case: {cooler_case_count} compatible pairs found")
    
    # Storage <-> Motherboard
    storage_mb_pairs = [(storage, mb) for storage in storages for mb in motherboards]
    storage_mb_count = 0
    for storage, mb in tqdm(storage_mb_pairs, desc="Storage <-> Motherboard", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_storage_motherboard_compatibility(storage, mb)
        if is_compat:
            storage_mb_count += 1
            compatible_pairs.append(CompatibilityResult(storage.id, mb.id, True, reason))
            compatible_pairs.append(CompatibilityResult(mb.id, storage.id, True, reason))
    compatible_count += storage_mb_count
    logger.info(f"  Storage <-> Motherboard: {storage_mb_count} compatible pairs found")
    
    # PSU <-> Case
    psu_case_pairs = [(psu, case) for psu in psus for case in cases]
    psu_case_count = 0
    for psu, case in tqdm(psu_case_pairs, desc="PSU <-> Case", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_psu_case_compatibility(psu, case)
        if is_compat:
            psu_case_count += 1
            compatible_pairs.append(CompatibilityResult(psu.id, case.id, True, reason))
            compatible_pairs.append(CompatibilityResult(case.id, psu.id, True, reason))
    compatible_count += psu_case_count
    logger.info(f"  PSU <-> Case: {psu_case_count} compatible pairs found")
    
    # PSU <-> GPU
    psu_gpu_pairs = [(psu, gpu) for psu in psus for gpu in gpus]
    psu_gpu_count = 0
    for psu, gpu in tqdm(psu_gpu_pairs, desc="PSU <-> GPU", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_psu_gpu_compatibility(psu, gpu)
        if is_compat:
            psu_gpu_count += 1
            compatible_pairs.append(CompatibilityResult(psu.id, gpu.id, True, reason))
            compatible_pairs.append(CompatibilityResult(gpu.id, psu.id, True, reason))
    compatible_count += psu_gpu_count
    logger.info(f"  PSU <-> GPU: {psu_gpu_count} compatible pairs found")
    
    # PSU <-> CPU
    psu_cpu_pairs = [(psu, cpu) for psu in psus for cpu in cpus]
    psu_cpu_count = 0
    for psu, cpu in tqdm(psu_cpu_pairs, desc="PSU <-> CPU", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_psu_cpu_compatibility(psu, cpu)
        if is_compat:
            psu_cpu_count += 1
            compatible_pairs.append(CompatibilityResult(psu.id, cpu.id, True, reason))
            compatible_pairs.append(CompatibilityResult(cpu.id, psu.id, True, reason))
    compatible_count += psu_cpu_count
    logger.info(f"  PSU <-> CPU: {psu_cpu_count} compatible pairs found")
    
    # Case Fan <-> Motherboard (with check)
    fan_mb_pairs = [(fan, mb) for fan in case_fans for mb in motherboards]
    fan_mb_count = 0
    for fan, mb in tqdm(fan_mb_pairs, desc="Case Fan <-> MB", unit="pair", leave=False):
        total_checks += 1
        is_compat, reason = check_case_fan_motherboard_compatibility(fan, mb)
        if is_compat:
            fan_mb_count += 1
            compatible_pairs.append(CompatibilityResult(fan.id, mb.id, True, reason))
            compatible_pairs.append(CompatibilityResult(mb.id, fan.id, True, reason))
    compatible_count += fan_mb_count
    logger.info(f"  Case Fan <-> Motherboard: {fan_mb_count} compatible pairs found")
    
    # ========================================================================== #
    # ALWAYS COMPATIBLE PAIRINGS (no checks required)                            #
    # ========================================================================== #
    
    # Cooler <-> Motherboard (always compatible)
    cooler_mb_pairs = [(cooler, mb) for cooler in coolers for mb in motherboards]
    cooler_mb_count = 0
    for cooler, mb in tqdm(cooler_mb_pairs, desc="Cooler <-> MB (auto)", unit="pair", leave=False):
        cooler_mb_count += 1
        compatible_pairs.append(CompatibilityResult(cooler.id, mb.id, True, "Always compatible"))
        compatible_pairs.append(CompatibilityResult(mb.id, cooler.id, True, "Always compatible"))
    compatible_count += cooler_mb_count
    logger.info(f"  Cooler <-> Motherboard: {cooler_mb_count} compatible pairs added")
    
    # GPU <-> Motherboard (always compatible)
    gpu_mb_pairs = [(gpu, mb) for gpu in gpus for mb in motherboards]
    gpu_mb_count = 0
    for gpu, mb in tqdm(gpu_mb_pairs, desc="GPU <-> MB (auto)", unit="pair", leave=False):
        gpu_mb_count += 1
        compatible_pairs.append(CompatibilityResult(gpu.id, mb.id, True, "Always compatible"))
        compatible_pairs.append(CompatibilityResult(mb.id, gpu.id, True, "Always compatible"))
    compatible_count += gpu_mb_count
    logger.info(f"  GPU <-> Motherboard: {gpu_mb_count} compatible pairs added")
    
    # PSU <-> Motherboard (always compatible)
    psu_mb_pairs = [(psu, mb) for psu in psus for mb in motherboards]
    psu_mb_count = 0
    for psu, mb in tqdm(psu_mb_pairs, desc="PSU <-> MB (auto)", unit="pair", leave=False):
        psu_mb_count += 1
        compatible_pairs.append(CompatibilityResult(psu.id, mb.id, True, "Always compatible"))
        compatible_pairs.append(CompatibilityResult(mb.id, psu.id, True, "Always compatible"))
    compatible_count += psu_mb_count
    logger.info(f"  PSU <-> Motherboard: {psu_mb_count} compatible pairs added")
    
    # Case Fan <-> Case (always compatible)
    fan_case_pairs = [(fan, case) for fan in case_fans for case in cases]
    fan_case_count = 0
    for fan, case in tqdm(fan_case_pairs, desc="Fan <-> Case (auto)", unit="pair", leave=False):
        fan_case_count += 1
        compatible_pairs.append(CompatibilityResult(fan.id, case.id, True, "Always compatible"))
        compatible_pairs.append(CompatibilityResult(case.id, fan.id, True, "Always compatible"))
    compatible_count += fan_case_count
    logger.info(f"  Case Fan <-> Case: {fan_case_count} compatible pairs added")
    
    # Monitor <-> GPU (always compatible)
    monitor_gpu_pairs = [(monitor, gpu) for monitor in monitors for gpu in gpus]
    monitor_gpu_count = 0
    for monitor, gpu in tqdm(monitor_gpu_pairs, desc="Monitor <-> GPU (auto)", unit="pair", leave=False):
        monitor_gpu_count += 1
        compatible_pairs.append(CompatibilityResult(monitor.id, gpu.id, True, "Always compatible"))
        compatible_pairs.append(CompatibilityResult(gpu.id, monitor.id, True, "Always compatible"))
    compatible_count += monitor_gpu_count
    logger.info(f"  Monitor <-> GPU: {monitor_gpu_count} compatible pairs added")
    
    return compatible_pairs


# ========================================================================== #
# DATABASE OPERATIONS                                                        #
# ========================================================================== #

def delete_existing_compatibilities(db: DatabaseConnection, component_ids: Set[str]) -> int:
    """
    Delete existing compatibilities for the given component IDs.
    Returns the number of deleted records.
    """
    if not component_ids:
        return 0
    
    # Delete in batches to avoid parameter limits
    deleted_count = 0
    component_list = list(component_ids)
    batch_size = 500
    
    total_batches = (len(component_list) + batch_size - 1) // batch_size
    
    with tqdm(total=total_batches, desc="Deleting old compatibilities", unit="batch") as pbar:
        for i in range(0, len(component_list), batch_size):
            batch = component_list[i:i + batch_size]
            placeholders = ",".join(["?" for _ in batch])
            
            # Delete where ComponentId is in batch
            query = f"""
                DELETE FROM ComponentCompatibilities 
                WHERE ComponentId IN ({placeholders}) OR CompatibleComponentId IN ({placeholders})
            """
            db.execute(query, tuple(batch + batch))
            deleted_count += db.cursor.rowcount
            pbar.update(1)
    
    db.commit()
    logger.info(f"Deleted {deleted_count} existing compatibility records")
    return deleted_count


def insert_compatibilities(
    db: DatabaseConnection,
    compatible_pairs: List[CompatibilityResult],
    batch_size: int = 1000
) -> int:
    """
    Insert compatibility records into the database.
    Returns the number of inserted records.
    """
    if not compatible_pairs:
        return 0
    
    now = dt.datetime.utcnow()
    inserted_count = 0
    
    insert_sql = """
        INSERT INTO ComponentCompatibilities 
        (Id, ComponentId, CompatibleComponentId, DatabaseEntryAt, LastEditedAt, Note)
        VALUES (?, ?, ?, ?, ?, ?)
    """
    
    # Process in batches with progress bar
    with tqdm(total=len(compatible_pairs), desc="Inserting compatibilities", unit="record") as pbar:
        for i in range(0, len(compatible_pairs), batch_size):
            batch = compatible_pairs[i:i + batch_size]
            params_list = []
            
            for result in batch:
                params = (
                    str(uuid.uuid4()),
                    result.component_id,
                    result.compatible_component_id,
                    now,
                    now,
                    None,  # Note
                )
                params_list.append(params)
            
            try:
                db.cursor.fast_executemany = True
                db.executemany(insert_sql, params_list)
                db.commit()
                inserted_count += len(batch)
                pbar.update(len(batch))
            except pyodbc.Error as e:
                logger.error(f"Error inserting batch: {e}")
                # Try inserting one by one to identify problematic records
                for params in params_list:
                    try:
                        db.execute(insert_sql, params)
                        db.commit()
                        inserted_count += 1
                        pbar.update(1)
                    except pyodbc.Error as inner_e:
                        logger.warning(f"Failed to insert compatibility {params[1]} <-> {params[2]}: {inner_e}")
                        pbar.update(1)
    
    logger.info(f"Total inserted: {inserted_count} compatibility records")
    return inserted_count


def get_all_component_ids(
    cpus: List[CPUComponent],
    motherboards: List[MotherboardComponent],
    cases: List[CaseComponent],
    gpus: List[GPUComponent],
    memories: List[MemoryComponent],
    storages: List[StorageComponent],
    psus: List[PowerSupplyComponent],
    coolers: List[CoolerComponent],
    case_fans: List[CaseFanComponent],
    monitors: List[MonitorComponent],
) -> Set[str]:
    """Get all component IDs from the loaded components."""
    ids = set()
    for component_list in [cpus, motherboards, cases, gpus, memories, storages, psus, coolers, case_fans, monitors]:
        for component in component_list:
            ids.add(component.id)
    return ids


# ========================================================================== #
# MAIN FUNCTION                                                              #
# ========================================================================== #

def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Generate component compatibility relationships for KAZABUILD database."
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
        "--batch-size",
        type=int,
        default=1000,
        help="Batch size for database operations (default: 1000)"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Perform compatibility checks without modifying the database"
    )
    
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose logging"
    )
    
    return parser.parse_args()


def main() -> int:
    """Main entry point."""
    args = parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    logger.info("=" * 70)
    logger.info("KAZABUILD Component Compatibility Checker")
    logger.info("=" * 70)
    
    # Connect to database
    db = DatabaseConnection(args.connection_string, args.odbc_driver)
    
    try:
        db.connect()
        
        # Load all components
        logger.info("Loading components from database...")
        cpus = load_cpus(db)
        motherboards = load_motherboards(db)
        cases = load_cases(db)
        gpus = load_gpus(db)
        memories = load_memory(db)
        storages = load_storage(db)
        psus = load_power_supplies(db)
        coolers = load_coolers(db)
        case_fans = load_case_fans(db)
        monitors = load_monitors(db)
        
        total_components = (
            len(cpus) + len(motherboards) + len(cases) + len(gpus) +
            len(memories) + len(storages) + len(psus) + len(coolers) +
            len(case_fans) + len(monitors)
        )
        logger.info(f"Total components loaded: {total_components}")
        
        if total_components == 0:
            logger.warning("No components found in database. Exiting.")
            return 0
        
        # Generate compatibility pairs
        logger.info("Generating compatibility pairs...")
        compatible_pairs = generate_all_compatibilities(
            cpus, motherboards, cases, gpus, memories, storages, psus, coolers, case_fans, monitors
        )
        
        if args.dry_run:
            logger.info("Dry run mode - no database changes will be made")
            logger.info(f"Would insert {len(compatible_pairs)} compatibility records")
            return 0
        
        # Get all component IDs for deletion
        all_component_ids = get_all_component_ids(
            cpus, motherboards, cases, gpus, memories, storages, psus, coolers, case_fans, monitors
        )
        
        # Delete existing compatibilities
        logger.info("Deleting existing compatibility records...")
        deleted_count = delete_existing_compatibilities(db, all_component_ids)
        
        # Insert new compatibilities
        logger.info("Inserting new compatibility records...")
        inserted_count = insert_compatibilities(db, compatible_pairs, args.batch_size)
        
        # Summary
        logger.info("=" * 70)
        logger.info("SUMMARY")
        logger.info("=" * 70)
        logger.info(f"Components processed: {total_components}")
        logger.info(f"  - CPUs: {len(cpus)}")
        logger.info(f"  - Motherboards: {len(motherboards)}")
        logger.info(f"  - Cases: {len(cases)}")
        logger.info(f"  - GPUs: {len(gpus)}")
        logger.info(f"  - Memory: {len(memories)}")
        logger.info(f"  - Storage: {len(storages)}")
        logger.info(f"  - Power Supplies: {len(psus)}")
        logger.info(f"  - Coolers: {len(coolers)}")
        logger.info(f"  - Case Fans: {len(case_fans)}")
        logger.info(f"  - Monitors: {len(monitors)}")
        logger.info(f"Compatibility records deleted: {deleted_count}")
        logger.info(f"Compatibility records inserted: {inserted_count}")
        logger.info("=" * 70)
        
        return 0
        
    except pyodbc.Error as e:
        logger.error(f"Database error: {e}")
        return 1
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return 1
    finally:
        db.disconnect()


if __name__ == "__main__":
    sys.exit(main())