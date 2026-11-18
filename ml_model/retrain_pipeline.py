import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import xgboost as xgb
import json
import os
import random

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        # Use Application Default Credentials when deployed to GCP/Cloud Functions
        cred = credentials.ApplicationDefault()
        firebase_admin.initialize_app(cred, {
            'storageBucket': 'smart-hostel-system-9f924.firebasestorage.app'
        })
    except Exception:
        # Fallback if already initialized or testing
        try:
            firebase_admin.initialize_app()
        except ValueError:
            pass

def fetch_real_data(db):
    """
    Fetch hostels from Firestore to build a training dataset.
    Features (7):
      1. average_rating
      2. complaint_resolution_rate
      3. review_volume
      4. num_bookings
      5. proximity (distance in km from hostel to student's university)
      6. complaint_freq (complaints relative to bookings, 0.0 - 1.0)
      7. resolution_speed_hrs (average hours taken to resolve complaints)
    """
    print("Fetching data from Firestore...")
    hostels_ref = db.collection('hostels').stream()
    
    data = []
    
    for doc in hostels_ref:
        hostel = doc.to_dict()
        
        # ── Authenticity Filter: Compute ratings & review volume excluding flagged fake reviews ──
        try:
            unflagged_reviews = (
                db.collection('reviews')
                .where('hostelId', '==', doc.id)
                .where('isFlagged', '==', False)
                .stream()
            )
            valid_ratings = [float(r.to_dict().get('rating', 0.0)) for r in unflagged_reviews]
            if valid_ratings:
                rating = float(round(sum(valid_ratings) / len(valid_ratings), 1))
                review_volume = float(len(valid_ratings))
            else:
                rating = float(hostel.get('averageRating', 0.0))
                review_volume = float(hostel.get('totalReviews', 0))
        except Exception as e:
            print(f"Warning: could not recalculate unflagged reviews for {doc.id}: {e}")
            rating = float(hostel.get('averageRating', 0.0))
            review_volume = float(hostel.get('totalReviews', 0))

        num_bookings = float(hostel.get('totalBookings', 0))
        complaint_res_rate = float(hostel.get('complaintResolutionRate', 1.0))
        total_complaints = float(hostel.get('totalComplaints', 0))
        resolved_complaints = float(hostel.get('resolvedComplaints', 0))
        total_res_time = float(hostel.get('totalResolutionTimeHours', 0))
        
        # Complaint frequency (complaints / bookings, capped at 1.0)
        if num_bookings > 0:
            complaint_freq = min(1.0, total_complaints / num_bookings)
        else:
            complaint_freq = 1.0 if total_complaints > 0 else 0.0
            
        # Resolution speed in hours (lower is faster/better)
        if resolved_complaints > 0:
            resolution_speed_hrs = total_res_time / resolved_complaints
        else:
            resolution_speed_hrs = 24.0 if total_complaints == 0 else 72.0
            
        for _ in range(5):
            proximity = random.uniform(0.5, 20.0) # 0.5km to 20km
            
            # Ground truth target score formula logic (0 - 100)
            score = (rating / 5.0 * 30.0) + (complaint_res_rate * 20.0) + (min(review_volume, 100) * 0.1) + (min(num_bookings, 100) * 0.1)
            
            # Proximity bonus/penalty
            if proximity < 2.0:
                score += 10.0
            elif proximity < 5.0:
                score += 5.0
            else:
                score -= min(5.0, proximity * 0.4)
                
            # Complaint frequency penalty
            score += (1.0 - complaint_freq) * 10.0
            
            # Resolution speed bonus
            if resolution_speed_hrs <= 24.0:
                score += 10.0
            elif resolution_speed_hrs <= 48.0:
                score += 7.0
            elif resolution_speed_hrs <= 72.0:
                score += 4.0
            else:
                score += 1.0
                
            data.append({
                'average_rating': rating,
                'complaint_resolution_rate': complaint_res_rate,
                'review_volume': review_volume,
                'num_bookings': num_bookings,
                'proximity': proximity,
                'complaint_freq': complaint_freq,
                'resolution_speed_hrs': resolution_speed_hrs,
                'target_score': max(0.0, min(100.0, score)) # Clamp 0-100
            })
            
    return pd.DataFrame(data)

def generate_synthetic_data():
    """Fallback if Firestore has no data yet."""
    print("Generating synthetic data since Firestore is empty...")
    data = []
    for _ in range(1000):
        rating = random.uniform(1.0, 5.0)
        complaint_res_rate = random.uniform(0.0, 1.0)
        review_volume = random.uniform(0, 200)
        num_bookings = random.uniform(0, 300)
        proximity = random.uniform(0.5, 20.0)
        complaint_freq = random.uniform(0.0, 0.6)
        resolution_speed_hrs = random.uniform(6.0, 120.0)
        
        score = (rating / 5.0 * 30.0) + (complaint_res_rate * 20.0) + (min(review_volume, 100) * 0.1) + (min(num_bookings, 100) * 0.1)
        if proximity < 2.0:
            score += 10.0
        elif proximity < 5.0:
            score += 5.0
        else:
            score -= min(5.0, proximity * 0.4)
            
        score += (1.0 - complaint_freq) * 10.0
        
        if resolution_speed_hrs <= 24.0:
            score += 10.0
        elif resolution_speed_hrs <= 48.0:
            score += 7.0
        elif resolution_speed_hrs <= 72.0:
            score += 4.0
        else:
            score += 1.0
            
        data.append({
            'average_rating': rating,
            'complaint_resolution_rate': complaint_res_rate,
            'review_volume': review_volume,
            'num_bookings': num_bookings,
            'proximity': proximity,
            'complaint_freq': complaint_freq,
            'resolution_speed_hrs': resolution_speed_hrs,
            'target_score': max(0.0, min(100.0, score))
        })
    return pd.DataFrame(data)

def train_and_export():
    initialize_firebase()

    try:
        db = firestore.client()
        df = fetch_real_data(db)
        if df.empty:
            df = generate_synthetic_data()
    except Exception as e:
        print(f"Could not fetch from Firestore: {e}")
        df = generate_synthetic_data()

    feature_cols = [
        'average_rating',
        'complaint_resolution_rate',
        'review_volume',
        'num_bookings',
        'proximity',
        'complaint_freq',
        'resolution_speed_hrs'
    ]

    print(f"Training XGBRegressor on {len(df)} records with {len(feature_cols)} features...")
    X = df[feature_cols].values
    y = df['target_score'].values

    model = xgb.XGBRegressor(n_estimators=100, max_depth=3, learning_rate=0.1)
    model.fit(X, y)

    # Extract base_score (regression intercept baseline)
    config = json.loads(model.get_booster().save_config())
    base_score = float(config['learner']['learner_model_param']['base_score'])

    trees = [json.loads(t) for t in model.get_booster().get_dump(dump_format='json')]
    json_model = json.dumps({
        "base_score": base_score,
        "features": feature_cols,
        "trees": trees
    })

    output_paths = [
        'ml_model/xgboost_model.json',
        'assets/ml/xgboost_model.json'
    ]

    for p in output_paths:
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w') as f:
            f.write(json_model)
        print(f"Model (base_score={base_score:.2f}, {len(trees)} trees) saved to {p}")

if __name__ == '__main__':
    train_and_export()
