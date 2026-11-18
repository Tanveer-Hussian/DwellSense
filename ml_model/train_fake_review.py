import pandas as pd
import numpy as np
import scipy.sparse as sp
import re
import os
import joblib
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score, roc_auc_score, confusion_matrix

# Domain sentiment lexicon for accommodation / hostel reviews
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

def extract_behavioral_features(texts, ratings):
    """
    Extracts 8 explainable behavioral & linguistic signals:
      1. rating (raw 1.0 - 5.0)
      2. text_sentiment (-1.0 to +1.0)
      3. rating_sentiment_discrepancy (absolute distance between rating & sentiment)
      4. word_count
      5. char_length
      6. uppercase_ratio (shouting / spam)
      7. punctuation_density (! and ? counts relative to words)
      8. character_elongation (stretching letters like 'soooo', 'greeeeat')
    """
    features = []
    for text, rating in zip(texts, ratings):
        text_str = str(text) if pd.notnull(text) else ""
        words = re.findall(r'\b\w+\b', text_str.lower())
        num_words = len(words)
        char_len = len(text_str)

        # Lexical sentiment polarity
        p_count = sum(1 for w in words if w in POSITIVE_WORDS)
        n_count = sum(1 for w in words if w in NEGATIVE_WORDS)
        total_sentiment_words = p_count + n_count
        if total_sentiment_words > 0:
            sentiment_polarity = (p_count - n_count) / total_sentiment_words
        else:
            sentiment_polarity = 0.0

        # Normalized rating in [-1.0, +1.0]: 1.0 -> -1.0, 3.0 -> 0.0, 5.0 -> +1.0
        norm_rating = (float(rating) - 3.0) / 2.0

        # Discrepancy (critical for troll / fake reviews)
        discrepancy = abs(norm_rating - sentiment_polarity)

        # Linguistic heuristics
        caps_ratio = sum(1 for c in text_str if c.isupper()) / max(1, char_len)
        punct_density = (text_str.count('!') + text_str.count('?')) / max(1, num_words)
        has_elongation = 1.0 if re.search(r'(.)\1{2,}', text_str.lower()) else 0.0

        features.append([
            float(rating),
            sentiment_polarity,
            discrepancy,
            float(num_words),
            float(char_len),
            caps_ratio,
            punct_density,
            has_elongation
        ])
    return np.array(features)

def train_model():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    dataset_path = os.path.join(base_dir, 'hostel_fake_reviews_dataset.csv')

    if not os.path.exists(dataset_path):
        dataset_path = 'hostel_fake_reviews_dataset.csv'

    print(f"Loading dataset from: {dataset_path}")
    df = pd.read_csv(dataset_path)
    print(f"Dataset shape: {df.shape}")

    X_texts = df['review_text'].values
    X_ratings = df['rating'].values
    y = df['label'].values

    # Train-test split (80% train, 20% test stratified)
    X_train_text, X_test_text, r_train, r_test, y_train, y_test = train_test_split(
        X_texts, X_ratings, y, test_size=0.2, random_state=42, stratify=y
    )

    print("\n1. Fitting TF-IDF Vectorizer (Unigrams + Bigrams)...")
    tfidf = TfidfVectorizer(
        max_features=3000,
        ngram_range=(1, 2),
        stop_words='english',
        sublinear_tf=True
    )
    X_train_tfidf = tfidf.fit_transform(X_train_text)
    X_test_tfidf = tfidf.transform(X_test_text)

    print("2. Extracting Behavioral & Sentiment Features...")
    feat_train = extract_behavioral_features(X_train_text, r_train)
    feat_test = extract_behavioral_features(X_test_text, r_test)

    scaler = StandardScaler()
    feat_train_scaled = scaler.fit_transform(feat_train)
    feat_test_scaled = scaler.transform(feat_test)

    # Combine TF-IDF sparse matrix with scaled behavioral features
    X_train_full = sp.hstack([X_train_tfidf, feat_train_scaled], format='csr')
    X_test_full = sp.hstack([X_test_tfidf, feat_test_scaled], format='csr')

    print("3. Training Logistic Regression Classifier...")
    clf = LogisticRegression(C=5.0, max_iter=1000, random_state=42)
    clf.fit(X_train_full, y_train)

    # Evaluate
    y_pred = clf.predict(X_test_full)
    y_prob = clf.predict_proba(X_test_full)[:, 1]

    acc = accuracy_score(y_test, y_pred)
    auc = roc_auc_score(y_test, y_prob)

    print("\n" + "="*50)
    print("MODEL EVALUATION RESULTS (TEST SPLIT)")
    print("="*50)
    print(f"Test Accuracy : {acc * 100:.2f}%")
    print(f"ROC-AUC Score : {auc:.4f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=['Genuine (0)', 'Fake (1)']))
    print("Confusion Matrix:")
    print(confusion_matrix(y_test, y_pred))

    # Save pipeline
    model_bundle = {
        'vectorizer': tfidf,
        'scaler': scaler,
        'classifier': clf,
        'accuracy': float(acc),
        'auc': float(auc),
        'feature_names': [
            'rating', 'sentiment_polarity', 'discrepancy',
            'word_count', 'char_length', 'caps_ratio',
            'punct_density', 'has_elongation'
        ]
    }

    out_file = os.path.join(base_dir, 'fake_review_model.joblib')
    joblib.dump(model_bundle, out_file)
    print(f"\nModel successfully saved to: {out_file}")

if __name__ == '__main__':
    train_model()
