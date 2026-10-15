from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict
import tensorflow as tf
from tensorflow.keras.preprocessing.sequence import pad_sequences
import json
import os
import uvicorn

app = FastAPI(title="NestIQ ML API", description="API for Fake Review Detection and Smart Hostel Recommendations")

# ── Review Model Assets ───────────────────────────────────────────────────────
review_model = None
tokenizer_word_index = {}
vocab_size = 1000
max_length = 20

# ── Recommendation Model Assets ───────────────────────────────────────────────
recommendation_data = None

@app.on_event("startup")
def load_assets():
    global review_model, tokenizer_word_index, recommendation_data
    base_dir = os.path.dirname(os.path.abspath(__file__))

    # 1. Fake Review Model
    for p in [os.path.join(base_dir, 'fake_review_model.h5'), 'fake_review_model.h5']:
        if os.path.exists(p):
            try:
                review_model = tf.keras.models.load_model(p)
                print(f"Loaded {p}")
                break
            except Exception as e:
                print(f"Error loading review model: {e}")

    for p in [os.path.join(base_dir, 'tokenizer.json'), 'tokenizer.json']:
        if os.path.exists(p):
            try:
                with open(p, 'r') as f:
                    tokenizer_word_index = json.load(f)
                print(f"Loaded {p}")
                break
            except Exception as e:
                print(f"Error loading tokenizer: {e}")

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
def text_to_sequence(text, word_index, max_len):
    words = text.lower().split()
    seq = []
    for w in words:
        if w in word_index and word_index[w] < vocab_size:
            seq.append(word_index[w])
        else:
            seq.append(word_index.get("<OOV>", 1))
    
    if len(seq) < max_len:
        seq = seq + [0] * (max_len - len(seq))
    else:
        seq = seq[:max_len]
    return [seq]

class ReviewRequest(BaseModel):
    comment: str
    rating: float = 0.0

@app.post("/predict_review")
async def predict_review(request: ReviewRequest):
    if not request.comment:
        raise HTTPException(status_code=400, detail="comment required")
        
    comment = request.comment
    
    if review_model is None:
        is_suspicious = len(comment.strip()) < 10
        return {'is_suspicious': is_suspicious, 'score': 1.0 if is_suspicious else 0.0}

    padded = text_to_sequence(comment, tokenizer_word_index, max_length)
    prediction = review_model.predict(padded)[0][0]
    is_fake = bool(prediction > 0.5)
    
    return {
        'is_suspicious': is_fake,
        'score': float(prediction)
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
