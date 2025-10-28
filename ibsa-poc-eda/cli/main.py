"""
Main CLI entry point for IBSA Pipeline

Usage:
    ibsa-pipeline eda --data-path ../data
    ibsa-pipeline features --input processed_data.parquet
    ibsa-pipeline model --config config.yaml
"""
import click
import logging
from pathlib import Path

from ..utils.spark_session import get_spark_session, stop_spark_session
from ..data.loaders import DataLoader  
from ..eda.analyzer import EDAAnalyzer
from ..config.settings import get_config

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@click.group()
@click.option('--verbose', '-v', is_flag=True, help='Enable verbose logging')
@click.option('--config', '-c', help='Path to configuration file')
@click.pass_context
def cli(ctx, verbose, config):
    """IBSA Pharmaceutical ML Pipeline CLI"""
    ctx.ensure_object(dict)
    
    if verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    if config:
        ctx.obj['config_path'] = config
    
    logger.info("IBSA Pipeline CLI initialized")


@cli.command()
@click.option('--data-path', '-d', help='Path to data directory')
@click.option('--output', '-o', help='Output directory for results')
@click.option('--create-templates', is_flag=True, help='Create template CSV files for missing tables')
@click.pass_context
def eda(ctx, data_path, output, create_templates):
    """Run Exploratory Data Analysis"""
    logger.info("Starting EDA analysis...")
    
    spark = None
    try:
        # Initialize Spark
        spark = get_spark_session("IBSA_EDA_Analysis")
        
        # Initialize components
        data_loader = DataLoader(spark)
        eda_analyzer = EDAAnalyzer(spark)
        
        # Create templates if requested
        if create_templates:
            logger.info("Creating template CSV files for missing tables...")
            missing_tables = data_loader.create_missing_tables_as_csv(data_path)
            if missing_tables:
                click.echo(f"Created {len(missing_tables)} template files")
                click.echo("Please populate these files with actual data and re-run the analysis")
                return
        
        # Load data
        logger.info("Loading CSV data...")
        tables = data_loader.load_csv_data(data_path)
        
        if not tables:
            click.echo("No data files found. Use --create-templates to generate template files.")
            return
        
        click.echo(f"Loaded {len(tables)} datasets:")
        for name in tables.keys():
            click.echo(f"  - {name}")
        
        # Analyze relationships
        logger.info("Analyzing table relationships...")
        relationships = data_loader.analyze_relationships()
        
        # Perform EDA on each table
        logger.info("Performing EDA analysis...")
        for table_name, df in tables.items():
            click.echo(f"\nAnalyzing: {table_name}")
            try:
                analysis = eda_analyzer.analyze_dataset(df, table_name)
                
                # Print key insights
                basic_info = analysis.get("basic_info", {})
                if "error" not in basic_info:
                    click.echo(f"  Rows: {basic_info.get('rows', 0):,}")
                    click.echo(f"  Columns: {basic_info.get('columns', 0)}")
                
                # Show pharmaceutical insights if available
                pharma_insights = analysis.get("pharmaceutical_insights", {})
                if pharma_insights:
                    if "prescriber_analysis" in pharma_insights:
                        prescriber_data = pharma_insights["prescriber_analysis"]
                        if "total_prescribers" in prescriber_data:
                            click.echo(f"  Prescribers: {prescriber_data['total_prescribers']:,}")
                    
                    if "territory_analysis" in pharma_insights:
                        territory_data = pharma_insights["territory_analysis"] 
                        if "total_territories" in territory_data:
                            click.echo(f"  Territories: {territory_data['total_territories']:,}")
                
            except Exception as e:
                click.echo(f"  Error: {str(e)}", err=True)
        
        # Generate report
        if output:
            output_path = Path(output)
            output_path.mkdir(parents=True, exist_ok=True)
            
            report_file = output_path / "eda_report.md"
            report_content = eda_analyzer.generate_report(str(report_file))
            
            # Save table summary
            summary_file = output_path / "table_summary.json"
            import json
            table_summary = data_loader.get_table_summary()
            with open(summary_file, 'w') as f:
                json.dump(table_summary, f, indent=2, default=str)
            
            # Save relationships
            relationships_file = output_path / "relationships.json"
            with open(relationships_file, 'w') as f:
                json.dump(relationships, f, indent=2, default=str)
            
            click.echo(f"\nResults saved to: {output_path}")
            click.echo(f"  - EDA Report: {report_file}")
            click.echo(f"  - Table Summary: {summary_file}")
            click.echo(f"  - Relationships: {relationships_file}")
        
        click.echo("\n✅ EDA Analysis Complete!")
        
    except Exception as e:
        logger.error(f"EDA analysis failed: {str(e)}")
        click.echo(f"Error: {str(e)}", err=True)
        raise click.Abort()
    
    finally:
        if spark:
            stop_spark_session()


@cli.command()
@click.option('--input', '-i', required=True, help='Input data file/directory')
@click.option('--output', '-o', required=True, help='Output directory')
@click.option('--target', '-t', help='Target variable column name')
@click.pass_context  
def features(ctx, input, output, target):
    """Run Feature Engineering"""
    logger.info("Starting Feature Engineering...")
    
    spark = None
    try:
        spark = get_spark_session("IBSA_Feature_Engineering")
        
        # Feature engineering logic will be implemented in features module
        click.echo(f"Input: {input}")
        click.echo(f"Output: {output}")
        click.echo(f"Target: {target}")
        
        click.echo("🔧 Feature Engineering - Coming Soon!")
        click.echo("This will include:")
        click.echo("  - Automated feature selection")
        click.echo("  - Pharmaceutical domain features")
        click.echo("  - Spark ML Pipeline creation")
        click.echo("  - Feature importance analysis")
        
    except Exception as e:
        logger.error(f"Feature engineering failed: {str(e)}")
        click.echo(f"Error: {str(e)}", err=True)
        raise click.Abort()
    
    finally:
        if spark:
            stop_spark_session()


@cli.command()
@click.option('--input', '-i', required=True, help='Input feature data')
@click.option('--output', '-o', required=True, help='Output model directory')
@click.option('--model-type', '-m', default='random_forest', help='Model type to train')
@click.pass_context
def model(ctx, input, output, model_type):
    """Train ML Model"""
    logger.info("Starting Model Training...")
    
    spark = None
    try:
        spark = get_spark_session("IBSA_Model_Training")
        
        # Model training logic will be implemented in models module
        click.echo(f"Input: {input}")
        click.echo(f"Output: {output}")
        click.echo(f"Model Type: {model_type}")
        
        click.echo("🤖 Model Training - Coming Soon!")
        click.echo("This will include:")
        click.echo("  - Multiple ML algorithms")
        click.echo("  - Hyperparameter tuning")
        click.echo("  - Cross-validation")
        click.echo("  - Model evaluation")
        click.echo("  - MLflow integration")
        
    except Exception as e:
        logger.error(f"Model training failed: {str(e)}")
        click.echo(f"Error: {str(e)}", err=True)
        raise click.Abort()
    
    finally:
        if spark:
            stop_spark_session()


@cli.command()
@click.option('--data-path', '-d', help='Path to data directory')
@click.option('--output', '-o', help='Output directory')
@click.option('--target', '-t', help='Target variable')
@click.option('--model-type', '-m', default='random_forest', help='Model type')
@click.pass_context
def run_pipeline(ctx, data_path, output, target, model_type):
    """Run complete pipeline: EDA -> Features -> Model"""
    logger.info("Starting complete IBSA ML Pipeline...")
    
    click.echo("🚀 Running Complete Pipeline:")
    click.echo("  1. EDA Analysis")
    click.echo("  2. Feature Engineering") 
    click.echo("  3. Model Training")
    click.echo("  4. Model Evaluation")
    
    # This would orchestrate the complete pipeline
    click.echo("\n📊 Step 1: EDA Analysis")
    ctx.invoke(eda, data_path=data_path, output=output)
    
    click.echo("\n🔧 Step 2: Feature Engineering")
    # ctx.invoke(features, input=f"{output}/processed", output=f"{output}/features", target=target)
    
    click.echo("\n🤖 Step 3: Model Training")  
    # ctx.invoke(model, input=f"{output}/features", output=f"{output}/models", model_type=model_type)
    
    click.echo("\n✅ Pipeline Complete!")


def main():
    """Entry point for CLI"""
    cli()


if __name__ == "__main__":
    main()