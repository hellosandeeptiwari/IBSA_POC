"""
IBSA Pharmaceutical ML Pipeline Package

A comprehensive package for pharmaceutical data analysis, feature engineering,
and machine learning model development using Apache Spark.
"""

__version__ = "1.0.0"
__author__ = "IBSA Analytics Team"
__email__ = "analytics@ibsa.com"

from .config.settings import get_config
from .data.loaders import DataLoader
from .eda.analyzer import EDAAnalyzer
from .features.engineer import FeatureEngineer
from .models.trainer import ModelTrainer
from .utils.spark_session import get_spark_session

__all__ = [
    "get_config",
    "DataLoader",
    "EDAAnalyzer", 
    "FeatureEngineer",
    "ModelTrainer",
    "get_spark_session",
]