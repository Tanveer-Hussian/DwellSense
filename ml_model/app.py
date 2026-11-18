from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
import json
import os
import re
import numpy as np
import scipy.sparse as sp
import joblib
import uvicorn

app = FastAPI(title="DwellSense ML API", description="API for Fake Review Detection (TF-IDF + Behavioral Logistic Regression) and Smart Hostel Recommendations")

# ── Review Model Assets ───────────────────────────────────────────────────────
fake_review_bundle = None

POSITIVE_WORDS = {
    'good', 'great', 'excellent', 'amazing', 'love', 'nice', 'best', 'clean', 
    'helpful', 'quiet', 'friendly', 'comfortable', 'recommend', 'spacious', 
    'perfect', 'peaceful', 'wonderful', 'safe', 'delicious', 'value', 'superb', 
    'pleasant', 'tidy', 'courteous', 'spacious', 'polite', 'cozy'
}

NEGATIVE_WORDS = {
    'bad', 'worst', 'terrible', 'horrible', 'dirty', 'noisy', 'poor', 'slow', 
    'rude', 'broken', 'smell', 'bugs', 'disaster', 'scam', 'uncomfortable', 
    'cramped', 'hated', 'hate', 'awful', 'overpriced', 'disgusting', 'filthy', 
    'unacceptable', 'stinky', 'cockroach', 'cockroaches', 'freezing'
}

# ── Recommendation Model Assets ───────────────────────────────────────────────
recommendation_data = None

@app.on_event("startup")
def load_assets():
    global fake_review_bundle, recommendation_data
    base_dir = os.path.dirname(os.path.abspath(__file__))

    # 1. Fake Review Model (TF-IDF + Logistic Regression Bundle)
    for p in [os.path.join(base_dir, 'fake_review_model.joblib'), 'fake_review_model.joblib', 'ml_model/fake_review_model.joblib']:
        if os.path.exists(p):
            try:
                fake_review_bundle = joblib.load(p)
                print(f"Loaded fake review model bundle from {p}")
                break
            except Exception as e:
                print(f"Error loading {p}: {e}")

    # 2. Recommendation XGBoost Model
    rec_paths = [
        os.path.join(base_dir, 'xgboost_model.json'),
        'xgboost_model.json',
        'ml_model/xgboost_model.json'
    ]
    for p in rec_paths:
        if os.path.exists(p):
            try:
                with open(p, 'r') as f:
                    recommendation_data = json.load(f)
                print(f"Loaded recommendation model from {p}")
                break
            except Exception as e:
                print(f"Error loading {p}: {e}")

# Pre-load immediately so assets are available right away
load_assets()

# ── Fake Review Helpers ───────────────────────────────────────────────────────
def extract_single_behavioral_features(text: str, rating: float):
    text_str = text.strip()
    words = re.findall(r'\b\w+\b', text_str.lower())
    num_words = len(words)
    char_len = len(text_str)

    p_count = sum(1 for w in words if w in POSITIVE_WORDS)
    n_count = sum(1 for w in words if w in NEGATIVE_WORDS)
    tot = p_count + n_count
    sentiment = (p_count - n_count) / tot if tot > 0 else 0.0

    norm_rating = (float(rating) - 3.0) / 2.0
    discrepancy = abs(norm_rating - sentiment)
    caps_ratio = sum(1 for c in text_str if c.isupper()) / max(1, char_len)
    punct_density = (text_str.count('!') + text_str.count('?')) / max(1, num_words)
    has_elongation = 1.0 if re.search(r'(.)\1{2,}', text_str.lower()) else 0.0

    features = np.array([[
        float(rating),
        sentiment,
        discrepancy,
        float(num_words),
        float(char_len),
        caps_ratio,
        punct_density,
        has_elongation
    ]])

    reasons = []
    if discrepancy > 1.2:
        reasons.append(f"Rating-Sentiment contradiction: {rating} stars given but text polarity is opposite.")
    if num_words < 5 and (rating >= 4.5 or rating <= 1.5):
        reasons.append("Extreme rating with lack of descriptive details (under 5 words).")
    if has_elongation > 0:
        reasons.append("Character repetition spam detected (e.g., repeated letters).")
    if caps_ratio > 0.4 and char_len > 15:
        reasons.append("Excessive uppercase lettering / shouting detected.")
    if punct_density > 0.4:
        reasons.append("Excessive punctuation spam (!, ?) detected.")

    return features, reasons

class ReviewRequest(BaseModel):
    comment: str
    rating: float = 0.0

@app.post("/predict_review")
async def predict_review(request: ReviewRequest):
    if not request.comment:
        raise HTTPException(status_code=400, detail="comment required")
        
    comment = request.comment
    rating = float(request.rating) if request.rating is not None else 3.0
    
    if fake_review_bundle is None:
        # Fallback heuristic
        is_suspicious = len(comment.strip()) < 10 and (rating >= 4.5 or rating <= 1.5)
        return {
            'is_suspicious': is_suspicious,
            'score': 1.0 if is_suspicious else 0.0,
            'reasons': ["Fallback rule triggered: very brief comment with extreme rating."] if is_suspicious else []
        }

    vectorizer = fake_review_bundle['vectorizer']
    scaler = fake_review_bundle['scaler']
    classifier = fake_review_bundle['classifier']

    feat_arr, heuristic_reasons = extract_single_behavioral_features(comment, rating)
    feat_scaled = scaler.transform(feat_arr)

    text_tfidf = vectorizer.transform([comment])
    X_input = sp.hstack([text_tfidf, feat_scaled], format='csr')

    prob_fake = float(classifier.predict_proba(X_input)[0][1])
    
    # Flag if statistical classifier >= 0.5 OR behavioral heuristics triggered with elevated probability
    is_fake = bool(prob_fake >= 0.5 or (len(heuristic_reasons) > 0 and prob_fake >= 0.30))

    if is_fake and not heuristic_reasons:
        heuristic_reasons.append("Linguistic patterns align with deceptive review benchmark markers.")

    return {
        'is_suspicious': is_fake,
        'score': round(max(prob_fake, 0.75 if (len(heuristic_reasons) > 0 and is_fake) else prob_fake), 4),
        'reasons': heuristic_reasons
    }

# ── Recommendation Model Helpers & Endpoints ─────────────────────────────────
def eval_tree_node(node, input_arr):
    if 'leaf' in node:
        return float(node['leaf'])
    f_idx = int(node['split'].replace('f', ''))
    cond = float(node['split_condition'])
    next_id = node['yes'] if (f_idx < len(input_arr) and input_arr[f_idx] < cond) else node['no']
    for c in node['children']:
        if c['nodeid'] == next_id:
            return eval_tree_node(c, input_arr)
    return 0.0

def compute_hostel_score(input_arr):
    if not recommendation_data:
        # Fallback baseline
        return 50.0
    base_score = float(recommendation_data.get('base_score', 53.13))
    trees = recommendation_data.get('trees', [])
    total = base_score + sum(eval_tree_node(t, input_arr) for t in trees)
    return max(0.0, min(100.0, float(total)))

class SingleRecommendationRequest(BaseModel):
    average_rating: float
    complaint_resolution_rate: float
    review_volume: float
    num_bookings: float
    proximity: float
    complaint_freq: float
    resolution_speed_hrs: float

@app.post("/predict_recommendation")
async def predict_recommendation(req: SingleRecommendationRequest):
    features = [
        req.average_rating,
        req.complaint_resolution_rate,
        req.review_volume,
        req.num_bookings,
        req.proximity,
        req.complaint_freq,
        req.resolution_speed_hrs
    ]
    score = compute_hostel_score(features)
    return {"smart_score": round(score, 1)}

class HostelBatchItem(BaseModel):
    id: str
    average_rating: float
    complaint_resolution_rate: float
    review_volume: float
    num_bookings: float
    proximity: float
    complaint_freq: float
    resolution_speed_hrs: float

class BatchRecommendationRequest(BaseModel):
    hostels: List[HostelBatchItem]

@app.post("/batch_predict_recommendations")
async def batch_predict_recommendations(req: BatchRecommendationRequest):
    results: Dict[str, float] = {}
    for h in req.hostels:
        features = [
            h.average_rating,
            h.complaint_resolution_rate,
            h.review_volume,
            h.num_bookings,
            h.proximity,
            h.complaint_freq,
            h.resolution_speed_hrs
        ]
        results[h.id] = round(compute_hostel_score(features), 1)
    return {"scores": results}

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "review_model_loaded": review_model is not None,
        "recommendation_model_loaded": recommendation_data is not None
    }

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    uvicorn.run("app:app", host='0.0.0.0', port=port)
