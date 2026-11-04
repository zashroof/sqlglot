from __future__ import annotations

from conformance.engines.base import Engine, EngineError, EngineUnavailable
from conformance.engines.postgres import Postgres
from conformance.engines.spark import Spark
from conformance.engines.vertica import Vertica

ENGINES: dict[str, type[Engine]] = {engine.name: engine for engine in (Postgres, Spark, Vertica)}

__all__ = ["ENGINES", "Engine", "EngineError", "EngineUnavailable"]
