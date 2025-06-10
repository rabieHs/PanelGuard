from flask import Flask, request, jsonify
import numpy as np
import pandas as pd
import joblib
import os
from datetime import datetime
import json

app = Flask(__name__)

# Load the model and scaler
model_path = 'best_model.pkl'
scaler_path = 'scaler.pkl'

# Check if model and scaler files exist
if os.path.exists(model_path) and os.path.exists(scaler_path):
    model = joblib.load(model_path)
    scaler = joblib.load(scaler_path)
    print(f"Model and scaler loaded successfully from {model_path} and {scaler_path}")
else:
    print(f"WARNING: Model or scaler file not found at {model_path} or {scaler_path}")
    model = None
    scaler = None

# Constants from ML script
SURFACE = 1.45 * 1.45  # Solar panel surface area (m²)
PUISSANCE_PANEAU = 680  # Panel rated power
DUST_THRESHOLD = 1800  # Maximum allowed dust level

# Features used in the ML model (in the exact order expected by the model)
FEATURE_COLUMNS = ['courant', 'humidity', 'luminosite', 'poussiere', 'puissance', 'temperature', 'tension']


def calculate_derived_metrics(features):
    """
    Calculate derived metrics (irradiation, rendement, efficacite) based on sensor readings.
    This matches the calculations from the ML script.
    """
    # Ensure luminosite is non-negative
    luminosite = max(0, features['luminosite'])

    # Convert Lux -> Irradiation (W/m²) (lux / 120)
    irradiation = luminosite / 120

    # Calculate efficiency (rendement) = (output power / panel rated power) * 100
    if PUISSANCE_PANEAU > 0:
        rendement = (features['puissance'] / PUISSANCE_PANEAU) * 100
    else:
        rendement = 0

    # Calculate solar efficiency (%) = (power output / (irradiation * surface area)) * 100
    if irradiation > 0 and SURFACE > 0:
        efficacite = (features['puissance'] / (irradiation * SURFACE)) * 100
    else:
        efficacite = 0

    # Ensure values are within reasonable ranges (matching ML script constraints)
    rendement = max(0, min(100, rendement))
    efficacite = max(0, min(100, efficacite))

    return irradiation, rendement, efficacite


def validate_and_filter_data(features):
    """
    Apply the same data validation and filtering as in the ML script.
    Returns True if data passes validation, False otherwise.
    """
    # Check for negative luminosity (filtered out in ML script)
    if features['luminosite'] < 0:
        return False, "Negative luminosity values are not allowed"

    # Check dust levels (filtered out in ML script)
    if features['poussiere'] > DUST_THRESHOLD:
        return False, f"Dust level exceeds threshold ({DUST_THRESHOLD})"

    # Calculate derived metrics for additional validation
    irradiation, rendement, efficacite = calculate_derived_metrics(features)

    # Check rendement range (filtered in ML script)
    if not (0 <= rendement <= 100):
        return False, f"Rendement ({rendement:.2f}%) is out of valid range (0-100%)"

    # Check efficacite range (filtered in ML script)
    if not (0 <= efficacite <= 100):
        return False, f"Efficacite ({efficacite:.2f}%) is out of valid range (0-100%)"

    return True, "Data validation passed"


def parse_timestamp(timestamp_str):
    """
    Parse timestamp from various formats and return ISO format.
    Handles both the new format (2025-06-10 09:21:45) and other formats.
    """
    if not timestamp_str:
        return datetime.now().isoformat()
    
    try:
        # Try parsing the new format: "2025-06-10 09:21:45"
        if len(timestamp_str) == 19 and ' ' in timestamp_str:
            dt = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
            return dt.isoformat()
        
        # Try parsing ISO format
        dt = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
        return dt.isoformat()
    except:
        # If parsing fails, return current time
        return datetime.now().isoformat()


@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get data from request
        data = request.json

        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Extract features with default values and type conversion
        try:
            features = {
                'courant': float(data.get('courant', 0)),
                'humidity': float(data.get('humidity', 0)),
                'luminosite': float(data.get('luminosite', 0)),
                'poussiere': float(data.get('poussiere', 0)),
                'puissance': float(data.get('puissance', 0)),
                'temperature': float(data.get('temperature', 0)),
                'tension': float(data.get('tension', 0))
            }
        except (ValueError, TypeError) as e:
            return jsonify({"error": f"Invalid numeric values in input: {str(e)}"}), 400

        # Validate and filter data using the same criteria as ML script
        is_valid, validation_message = validate_and_filter_data(features)
        if not is_valid:
            return jsonify({
                "error": f"Data validation failed: {validation_message}",
                "input_data": features
            }), 400

        # Calculate derived metrics
        irradiation, rendement, efficacite = calculate_derived_metrics(features)

        # Handle timestamp - support both new format and fallback
        timestamp = data.get('timestamp') or data.get('timepast')
        parsed_timestamp = parse_timestamp(timestamp)

        # Check if model and scaler are loaded
        if model is None or scaler is None:
            return jsonify({
                "error": "Model not loaded. Please ensure model files exist.",
                "irradiation": round(irradiation, 2),
                "efficacite": round(efficacite, 2),
                "rendement": round(rendement, 2),
                "timestamp": parsed_timestamp,
                "validation_status": validation_message
            }), 500

        # Prepare features for prediction (ensure correct order)
        input_df = pd.DataFrame([features])[FEATURE_COLUMNS]

        # Scale the features
        features_scaled = scaler.transform(input_df)

        # Make prediction
        prediction = int(model.predict(features_scaled)[0])

        # Get prediction probabilities if available
        prediction_proba = None
        if hasattr(model, 'predict_proba'):
            try:
                proba = model.predict_proba(features_scaled)[0]
                prediction_proba = {f"class_{i}": round(float(prob), 4) for i, prob in enumerate(proba)}
            except:
                prediction_proba = None

        # Return prediction and calculated metrics
        response = {
            "niveau": prediction,
            "irradiation": round(irradiation, 2),
            "efficacite": round(efficacite, 2),
            "rendement": round(rendement, 2),
            "timestamp": parsed_timestamp,
            "validation_status": validation_message,
            "input_features": features
        }

        if prediction_proba:
            response["prediction_probabilities"] = prediction_proba

        return jsonify(response), 200

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route('/health', methods=['GET'])
def health_check():
    model_status = "Loaded" if model is not None else "Not loaded"
    scaler_status = "Loaded" if scaler is not None else "Not loaded"

    # Get model info if available
    model_info = {}
    if model is not None:
        model_info = {
            "model_type": type(model).__name__,
            "feature_columns": FEATURE_COLUMNS,
            "expected_features": len(FEATURE_COLUMNS)
        }

    return jsonify({
        "status": "healthy",
        "model_status": model_status,
        "scaler_status": scaler_status,
        "model_info": model_info,
        "constants": {
            "surface_area": SURFACE,
            "panel_power": PUISSANCE_PANEAU,
            "dust_threshold": DUST_THRESHOLD
        },
        "supported_timestamp_formats": [
            "2025-06-10 09:21:45",
            "ISO format (2025-06-10T09:21:45)",
            "Current time if not provided"
        ]
    }), 200


@app.route('/batch_predict', methods=['POST'])
def batch_predict():
    try:
        # Get data from request
        data = request.json

        if not data or not isinstance(data, list):
            return jsonify({"error": "Invalid data format. Expected a list of sensor readings."}), 400

        results = []
        valid_count = 0
        invalid_count = 0

        for i, item in enumerate(data):
            try:
                # Extract features with safeguards
                features = {
                    'courant': float(item.get('courant', 0)),
                    'humidity': float(item.get('humidity', 0)),
                    'luminosite': float(item.get('luminosite', 0)),
                    'poussiere': float(item.get('poussiere', 0)),
                    'puissance': float(item.get('puissance', 0)),
                    'temperature': float(item.get('temperature', 0)),
                    'tension': float(item.get('tension', 0))
                }

                # Validate data
                is_valid, validation_message = validate_and_filter_data(features)

                # Calculate derived metrics
                irradiation, rendement, efficacite = calculate_derived_metrics(features)

                # Handle timestamp
                timestamp = item.get('timestamp') or item.get('timepast')
                parsed_timestamp = parse_timestamp(timestamp)

                result = {
                    "index": i,
                    "irradiation": round(irradiation, 2),
                    "efficacite": round(efficacite, 2),
                    "rendement": round(rendement, 2),
                    "timestamp": parsed_timestamp,
                    "validation_status": validation_message,
                    "is_valid": is_valid
                }

                if is_valid:
                    # Scale the features and predict if model is available
                    if model is not None and scaler is not None:
                        input_df = pd.DataFrame([features])[FEATURE_COLUMNS]
                        features_scaled = scaler.transform(input_df)
                        niveau = int(model.predict(features_scaled)[0])

                        # Add prediction probabilities if available
                        if hasattr(model, 'predict_proba'):
                            try:
                                proba = model.predict_proba(features_scaled)[0]
                                result["prediction_probabilities"] = {
                                    f"class_{i}": round(float(prob), 4) for i, prob in enumerate(proba)
                                }
                            except:
                                pass
                    else:
                        niveau = -1  # Indicate model not available

                    result["niveau"] = niveau
                    valid_count += 1
                else:
                    result["niveau"] = None  # No prediction for invalid data
                    result["error"] = validation_message
                    invalid_count += 1

                results.append(result)

            except Exception as e:
                # If one item fails, add error info but continue processing others
                results.append({
                    "index": i,
                    "error": f"Failed to process item: {str(e)}",
                    "data": item,
                    "is_valid": False
                })
                invalid_count += 1

        # Add summary statistics
        summary = {
            "total_processed": len(data),
            "valid_predictions": valid_count,
            "invalid_entries": invalid_count,
            "success_rate": round(valid_count / len(data) * 100, 2) if len(data) > 0 else 0
        }

        return jsonify({
            "results": results,
            "summary": summary
        }), 200

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


@app.route('/validate', methods=['POST'])
def validate_data():
    """
    Endpoint to validate sensor data without making predictions.
    Useful for checking if data meets the requirements before processing.
    """
    try:
        data = request.json
        if not data:
            return jsonify({"error": "No data provided"}), 400

        # Extract features
        try:
            features = {
                'courant': float(data.get('courant', 0)),
                'humidity': float(data.get('humidity', 0)),
                'luminosite': float(data.get('luminosite', 0)),
                'poussiere': float(data.get('poussiere', 0)),
                'puissance': float(data.get('puissance', 0)),
                'temperature': float(data.get('temperature', 0)),
                'tension': float(data.get('tension', 0))
            }
        except (ValueError, TypeError) as e:
            return jsonify({"error": f"Invalid numeric values: {str(e)}"}), 400

        # Validate data
        is_valid, validation_message = validate_and_filter_data(features)

        # Calculate derived metrics regardless of validation status
        irradiation, rendement, efficacite = calculate_derived_metrics(features)

        # Handle timestamp
        timestamp = data.get('timestamp') or data.get('timepast')
        parsed_timestamp = parse_timestamp(timestamp)

        return jsonify({
            "is_valid": is_valid,
            "validation_message": validation_message,
            "input_features": features,
            "derived_metrics": {
                "irradiation": round(irradiation, 2),
                "efficacite": round(efficacite, 2),
                "rendement": round(rendement, 2)
            },
            "timestamp": parsed_timestamp
        }), 200

    except Exception as e:
        import traceback
        print(traceback.format_exc())
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


if __name__ == '__main__':
    print("Starting Flask server...")
    print(f"Model path: {model_path} (exists: {os.path.exists(model_path)})")
    print(f"Scaler path: {scaler_path} (exists: {os.path.exists(scaler_path)})")
    print(f"Expected features: {FEATURE_COLUMNS}")
    print(f"Solar panel constants: Surface={SURFACE}m², Power={PUISSANCE_PANEAU}W")
    print("Supported timestamp formats:")
    print("  - 2025-06-10 09:21:45 (new Firebase format)")
    print("  - ISO format (2025-06-10T09:21:45)")
    print("  - Current time if not provided")
    app.run(debug=True, host='0.0.0.0', port=5050)
