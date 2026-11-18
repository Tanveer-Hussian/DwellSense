import csv
import random
import numpy as np

# Set seed for reproducible results
np.random.seed(42)
random.seed(42)

NUM_RECORDS = 1000
output_file = "ml_model/hostel_xgboost_dataset_1000.csv"

records = []

for i in range(NUM_RECORDS):
    # Tier distribution to simulate realistic real-world hostel variety
    # 25% High quality, 50% Average quality, 20% Below average, 5% New / unrated listings
    tier = random.choices(["high", "mid", "low", "new"], weights=[0.25, 0.50, 0.20, 0.05])[0]

    if tier == "high":
        rating = round(random.uniform(4.2, 4.95), 2)
        res_rate = round(random.uniform(0.82, 0.99), 2)
        reviews = random.randint(45, 280)
        bookings = random.randint(reviews, reviews + random.randint(30, 200))
        distance = round(random.uniform(0.3, 4.5), 2)
        complaint_freq = round(random.uniform(0.01, 0.10), 2)
        resolution_speed_hrs = round(random.uniform(6.0, 36.0), 1)
    elif tier == "mid":
        rating = round(random.uniform(3.2, 4.19), 2)
        res_rate = round(random.uniform(0.55, 0.81), 2)
        reviews = random.randint(15, 120)
        bookings = random.randint(reviews, reviews + random.randint(10, 90))
        distance = round(random.uniform(1.2, 8.5), 2)
        complaint_freq = round(random.uniform(0.08, 0.28), 2)
        resolution_speed_hrs = round(random.uniform(24.0, 72.0), 1)
    elif tier == "low":
        rating = round(random.uniform(1.8, 3.19), 2)
        res_rate = round(random.uniform(0.15, 0.54), 2)
        reviews = random.randint(8, 75)
        bookings = random.randint(reviews, reviews + random.randint(5, 40))
        distance = round(random.uniform(3.5, 16.0), 2)
        complaint_freq = round(random.uniform(0.25, 0.65), 2)
        resolution_speed_hrs = round(random.uniform(48.0, 140.0), 1)
    else: # "new"
        rating = round(random.uniform(3.8, 5.0), 2)
        res_rate = round(random.uniform(0.70, 1.0), 2)
        reviews = random.randint(1, 10)
        bookings = random.randint(1, 15)
        distance = round(random.uniform(0.5, 6.0), 2)
        complaint_freq = round(random.uniform(0.0, 0.12), 2)
        resolution_speed_hrs = round(random.uniform(12.0, 48.0), 1)

    # Calculate realistic ground truth target score (0 - 100)
    # 1. Rating contribution: up to 30 pts
    c_rating = (rating / 5.0) * 30.0

    # 2. Complaint resolution rate: up to 20 pts
    c_res = res_rate * 20.0

    # 3. Reviews credibility: up to 10 pts (logarithmic scale)
    c_rev = min(10.0, (np.log1p(reviews) / np.log1p(250)) * 10.0)

    # 4. Booking popularity: up to 10 pts (logarithmic scale)
    c_book = min(10.0, (np.log1p(bookings) / np.log1p(450)) * 10.0)

    # 5. Proximity bonus/penalty: up to 10 pts (closer to university = higher score)
    if distance <= 1.5:
        c_dist = 10.0
    elif distance <= 3.5:
        c_dist = 7.5
    elif distance <= 7.0:
        c_dist = 4.0
    elif distance <= 12.0:
        c_dist = 1.0
    else:
        c_dist = -2.0

    # 6. Complaint frequency penalty: up to 10 pts (fewer complaints = higher score)
    c_freq = (1.0 - min(1.0, complaint_freq)) * 10.0

    # 7. Resolution speed bonus: up to 10 pts (faster resolution = higher score)
    if resolution_speed_hrs <= 24.0:
        c_speed = 10.0
    elif resolution_speed_hrs <= 48.0:
        c_speed = 7.0
    elif resolution_speed_hrs <= 72.0:
        c_speed = 4.0
    else:
        c_speed = 1.0

    # Add minor Gaussian noise (+/- 1.2) to simulate real-world variance
    noise = np.random.normal(0, 1.2)
    target_score = round(float(np.clip(c_rating + c_res + c_rev + c_book + c_dist + c_freq + c_speed + noise, 10.0, 99.5)), 1)

    records.append({
        'average_rating': rating,
        'complaint_resolution_rate': res_rate,
        'review_volume': reviews,
        'num_bookings': bookings,
        'proximity': distance,
        'complaint_freq': complaint_freq,
        'resolution_speed_hrs': resolution_speed_hrs,
        'smart_score': target_score
    })

fieldnames = [
    'average_rating',
    'complaint_resolution_rate',
    'review_volume',
    'num_bookings',
    'proximity',
    'complaint_freq',
    'resolution_speed_hrs',
    'smart_score'
]

with open(output_file, mode='w', newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(records)

print(f"Successfully generated {len(records)} records in {output_file}")
