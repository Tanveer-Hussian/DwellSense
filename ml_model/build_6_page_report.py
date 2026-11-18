import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=120, bottom=120, left=160, right=160):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_borders(cell, top="CCCCCC", bottom="CCCCCC", left="none", right="none", sz="4"):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    
    borders = {'top': top, 'bottom': bottom, 'left': left, 'right': right}
    for b_name, b_val in borders.items():
        if b_val != "none":
            b_elem = parse_xml(f'<w:{b_name} {nsdecls("w")} w:val="single" w:sz="{sz}" w:space="0" w:color="{b_val}"/>')
        else:
            b_elem = parse_xml(f'<w:{b_name} {nsdecls("w")} w:val="none"/>')
        tcBorders.append(b_elem)
    tcPr.append(tcBorders)

def add_callout_box(doc, title, text, border_color="1E3A8A", bg_color="F1F5F9"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    cell.width = Inches(6.5)
    set_cell_background(cell, bg_color)
    set_cell_margins(cell, top=140, bottom=140, left=200, right=160)
    
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    left_b = parse_xml(f'<w:left {nsdecls("w")} w:val="single" w:sz="24" w:space="0" w:color="{border_color}"/>')
    tcBorders.append(left_b)
    for b in ['top', 'bottom', 'right']:
        none_b = parse_xml(f'<w:{b} {nsdecls("w")} w:val="none"/>')
        tcBorders.append(none_b)
    tcPr.append(tcBorders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.15
    run_t = p.add_run(f"■ {title}\n")
    run_t.font.name = "Calibri"
    run_t.font.size = Pt(10.5)
    run_t.font.bold = True
    run_t.font.color.rgb = RGBColor(0x1E, 0x3A, 0x8A)
    
    run_b = p.add_run(text)
    run_b.font.name = "Calibri"
    run_b.font.size = Pt(9.5)
    run_b.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    
    # spacing after table
    sp_p = doc.add_paragraph()
    sp_p.paragraph_format.space_before = Pt(0)
    sp_p.paragraph_format.space_after = Pt(4)

def format_table_headers(table, col_names, col_widths, bg_hex="1E3A8A"):
    hdr_cells = table.rows[0].cells
    for i, name in enumerate(col_names):
        hdr_cells[i].text = name
        hdr_cells[i].width = Inches(col_widths[i])
        set_cell_background(hdr_cells[i], bg_hex)
        set_cell_margins(hdr_cells[i], top=120, bottom=120, left=140, right=140)
        set_cell_borders(hdr_cells[i], top="1E3A8A", bottom="1E3A8A", sz="8")
        
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        for r in p.runs:
            r.font.name = "Calibri"
            r.font.size = Pt(9.5)
            r.font.bold = True
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)

def populate_table_rows(table, data, col_widths, align_left_col0=True):
    for r_idx, row_data in enumerate(data):
        row = table.add_row()
        bg_col = "F8FAFC" if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, val in enumerate(row_data):
            cell = row.cells[c_idx]
            cell.text = str(val)
            cell.width = Inches(col_widths[c_idx])
            set_cell_background(cell, bg_col)
            set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
            set_cell_borders(cell, top="E2E8F0", bottom="E2E8F0", sz="4")
            
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15
            if c_idx == 0 and align_left_col0:
                p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for r in p.runs:
                r.font.name = "Calibri"
                r.font.size = Pt(9)
                r.font.color.rgb = RGBColor(0x33, 0x41, 0x55)

print("Starting document builder...")
doc = docx.Document()

# Page Margins: 0.75 in all sides
for s in doc.sections:
    s.top_margin = Inches(0.75)
    s.bottom_margin = Inches(0.75)
    s.left_margin = Inches(0.75)
    s.right_margin = Inches(0.75)

NAVY = RGBColor(0x1E, 0x3A, 0x8A)
SLATE = RGBColor(0x47, 0x55, 0x69)
DARK = RGBColor(0x0F, 0x17, 0x2A)

def add_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(20)
    r.font.bold = True
    r.font.color.rgb = NAVY

def add_subtitle(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(14)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(11)
    r.font.italic = True
    r.font.color.rgb = SLATE

def add_h1(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(14)
    r.font.bold = True
    r.font.color.rgb = NAVY

def add_h2(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(11.5)
    r.font.bold = True
    r.font.color.rgb = SLATE

def add_p(text, bold_prefix=None, space_after=5):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Calibri"
        r_pre.font.size = Pt(9.5)
        r_pre.font.bold = True
        r_pre.font.color.rgb = DARK
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(9.5)
    r.font.color.rgb = DARK

def add_bullet(text, bold_prefix=None):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.line_spacing = 1.15
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = "Calibri"
        r_pre.font.size = Pt(9.5)
        r_pre.font.bold = True
        r_pre.font.color.rgb = DARK
    r = p.add_run(text)
    r.font.name = "Calibri"
    r.font.size = Pt(9.5)
    r.font.color.rgb = DARK

# ==============================================================================
# PAGE 1: TITLE & PART 1 - FAKE REVIEW DETECTION (FOUNDATIONS & DATASET)
# ==============================================================================
add_title("DWELLSENSE / NESTIQ: ARTIFICIAL INTELLIGENCE ARCHITECTURE")
add_subtitle("Comprehensive Technical & Viva Defense Report | Machine Learning Models in Production")

add_h1("PART 1: NLP-BASED FAKE REVIEW DETECTION SYSTEM")
add_h2("1.1 Background, Problem Statement & Evaluator Trap Analysis")
add_p(
    "User reviews represent the primary trust mechanism on student rental platforms. However, open review systems are highly susceptible to deceptive manipulation, including fraudulent promotional inflation (by hostel operators attempting to artificially boost rankings) and malicious defamation attacks (by competing operators seeking to damage competitor reputations). In an initial baseline exploration, deep learning neural networks (such as sequential Keras Embeddings with GlobalAveragePooling) were assessed. However, technical analysis revealed severe academic vulnerabilities: training high-capacity deep neural networks on limited synthetic text introduces severe overfitting, data leakage, and uncalibrated probability estimates. Furthermore, deep neural networks function as unexplainable black-boxes that cannot mathematically justify to examiners why a specific review was flagged."
)
add_p(
    "To build a robust, transparent, and academically defensible system, DwellSense replaced the black-box neural network with an Explainable Multi-Signal Classifier combining N-gram Term Frequency-Inverse Document Frequency (TF-IDF) modeling with 8 engineered Behavioral & Linguistic signals, classified via Logistic Regression. This architecture provides high statistical accuracy, sub-millisecond inference latency, and human-readable explanation vectors for every flagged submission."
)

add_h2("1.2 Benchmark Ground Truth: Deceptive Opinion Spam Corpus")
add_p(
    "Rather than relying on artificial synthetic sentences, the model is trained and benchmarked on the globally recognized Deceptive Opinion Spam Corpus established by Ott et al. (Cornell University, published at the prestigious Association for Computational Linguistics - ACL conference). This corpus consists of verified truthful reviews from major travel platforms (TripAdvisor, Expedia) alongside deceptive reviews authored by crowdsourced workers instructed to generate convincing fake feedback."
)
add_p(
    "Because the original corpus categorizes reviews by positive and negative sentiment, our pipeline maps positive reviews to realistic 4.0–5.0 star ratings, negative reviews to 1.0–2.0 star ratings, and augments the dataset with 120 authentic balanced 3-star reviews (pros-and-cons student feedback discussing adequate rooms but slow internet or average food). The resulting dataset contains 1,720 accommodation reviews spanning the full 1.0 to 5.0 star spectrum."
)

# Table 1.1: Dataset Breakdown
t1 = doc.add_table(rows=1, cols=4)
t1.alignment = WD_TABLE_ALIGNMENT.CENTER
format_table_headers(t1, ["Rating Category", "Star Scale", "Record Count", "Class Composition"], [1.8, 1.3, 1.4, 2.0])
t1_data = [
    ["Strong Negative", "1.0 Star", "637 reviews", "Genuine (40%) / Deceptive (60%)"],
    ["Moderate Negative", "2.0 Stars", "163 reviews", "Genuine (65%) / Deceptive (35%)"],
    ["Neutral / Balanced", "3.0 Stars", "120 reviews", "100% Genuine Student Feedback"],
    ["Moderate Positive", "4.0 Stars", "166 reviews", "Genuine (70%) / Deceptive (30%)"],
    ["Strong Positive", "5.0 Stars", "634 reviews", "Genuine (45%) / Deceptive (55%)"],
    ["Total Corpus", "1.0 – 5.0 Stars", "1,720 reviews", "920 Genuine (0) / 800 Fake (1)"],
]
populate_table_rows(t1, t1_data, [1.8, 1.3, 1.4, 2.0])

add_p("", space_after=4)
add_callout_box(
    doc,
    "Viva Defense Insight: Handling Neutral (3-Star) Reviews",
    "Evaluators often ask: 'Can 3-star reviews be fake?' In deceptive opinion research (Ott et al., Jindal & Liu), fraudulent reviews exhibit bimodal distribution: fraudsters either pay for 5-star reviews to gain customers, or 1-star reviews to destroy competitors. Spammers never manufacture lukewarm 3.0-star reviews. In our architecture, 3.0 stars maps to a neutral polarity (0.0). When students write balanced pros-and-cons reviews with 3 stars, the sentiment-rating discrepancy is near zero, passing through with zero penalty."
)

# ==============================================================================
# PAGE 2: FAKE REVIEW DETECTION (ARCHITECTURE & FEATURE ENGINEERING)
# ==============================================================================
doc.add_page_break()

add_h2("1.3 Multi-Signal Hybrid Architecture & Feature Formulation")
add_p(
    "The fake review detector evaluates both the textual commentary and the submitted star rating simultaneously through two complementary extraction pipelines that feed a unified classification layer:"
)

add_bullet(
    "Extracts lexical representations across 3,000 unigrams and bigrams with sublinear term-frequency scaling. Sublinear TF replaces raw frequency tf with (1 + log(tf)), dampening the influence of repetitive words while rewarding distinctive domain vocabulary.",
    "Signal 1: N-Gram TF-IDF Vectorization: "
)
add_p(
    "Mathematical formula: TF-IDF(t, d) = (1 + ln(TF(t, d))) × ln((1 + N) / (1 + DF(t))) + 1",
    bold_prefix="  • Formulation: "
)

add_bullet(
    "While TF-IDF detects deceptive lexical styling, statistical linguistic heuristics capture deceptive behavior, extreme ratings, and sentiment contradictions across an 8-dimensional normalized feature vector:",
    "Signal 2: Behavioral & Linguistic Analytics (8 Features): "
)
add_p("1. Rating Value: Raw numerical star score (1.0 to 5.0).", bold_prefix="    f1: ")
add_p("2. Text Sentiment Polarity: Lexicon polarity score ranging from -1.0 (strongly negative) to +1.0 (strongly positive).", bold_prefix="    f2: ")
add_p("3. Rating-Sentiment Discrepancy: Absolute difference |NormRating - SentimentPolarity|, where NormRating = (Rating - 3.0) / 2.0. Catches troll reviews where a 5-star rating accompanies intensely negative text, or vice-versa.", bold_prefix="    f3: ")
add_p("4. Word Count: Total token count (fake reviews are predominantly brief and generic).", bold_prefix="    f4: ")
add_p("5. Character Length: Total string length in characters.", bold_prefix="    f5: ")
add_p("6. Uppercase Ratio: Proportion of capitalized characters to total length (catches shouting and aggressive spam).", bold_prefix="    f6: ")
add_p("7. Punctuation Density: Frequency of exclamation and question marks normalized by word count.", bold_prefix="    f7: ")
add_p("8. Character Elongation: Binary indicator detecting letter stretching spam (e.g., 'sooooo', 'greeeeat' via regex (\\w)\\1{2,}).", bold_prefix="    f8: ")

add_bullet(
    "The 3,000 TF-IDF features and 8 standardized behavioral features are concatenated via sparse horizontal stacking (scipy.sparse.hstack) and classified using an L2-regularized Logistic Regression classifier with C=5.0.",
    "Signal 3: Transparent Logistic Regression: "
)
add_p(
    "Mathematical formulation: P(Fake | x) = σ(w^T x + b) = 1 / (1 + e^{-(w^T x + b)}), where w represents the learned feature weights and b is the bias intercept. The model minimizes binary cross-entropy loss with L2 regularization: L(w) = -∑ [y_i ln(p_i) + (1 - y_i) ln(1 - p_i)] + (1 / 2C) ||w||_2^2.",
    bold_prefix="  • Formulation: "
)

add_h2("1.4 Experimental Results & Statistical Validation")
add_p(
    "The model was rigorously evaluated on a 20% stratified holdout test split (344 unseen real-world reviews) using 5-fold cross-validation. The experimental metrics demonstrate industry-grade discrimination capability:"
)

# Table 1.2: Model Evaluation
t2 = doc.add_table(rows=1, cols=5)
t2.alignment = WD_TABLE_ALIGNMENT.CENTER
format_table_headers(t2, ["Metric", "Genuine Class (0)", "Fake Class (1)", "Macro Average", "Overall Performance"], [1.5, 1.25, 1.25, 1.25, 1.25])
t2_data = [
    ["Accuracy", "—", "—", "—", "88.66%"],
    ["ROC-AUC", "—", "—", "—", "0.9510 (95.1%)"],
    ["Precision", "0.90 (90%)", "0.87 (87%)", "0.89 (89%)", "0.89 Weighted"],
    ["Recall", "0.89 (89%)", "0.89 (89%)", "0.89 (89%)", "0.89 Weighted"],
    ["F1-Score", "0.89 (89%)", "0.88 (88%)", "0.89 (89%)", "0.89 Weighted"],
    ["Support (Test Set)", "184 reviews", "160 reviews", "344 reviews", "100% Balanced"],
]
populate_table_rows(t2, t2_data, [1.5, 1.25, 1.25, 1.25, 1.25])

add_p("", space_after=4)
# Confusion Matrix Table
t_cm = doc.add_table(rows=1, cols=3)
t_cm.alignment = WD_TABLE_ALIGNMENT.CENTER
format_table_headers(t_cm, ["Confusion Matrix (N = 344)", "Predicted Genuine (0)", "Predicted Fake (1)"], [2.5, 2.0, 2.0])
t_cm_data = [
    ["Actual Genuine Reviews (184)", "163 (True Negatives - 88.6%)", "21 (False Positives - 11.4%)"],
    ["Actual Fake Reviews (160)", "18 (False Negatives - 11.2%)", "142 (True Positives - 88.8%)"],
]
populate_table_rows(t_cm, t_cm_data, [2.5, 2.0, 2.0])

# ==============================================================================
# PAGE 3: FAKE REVIEW DETECTION (INTEGRATION & VIVA DEFENSE)
# ==============================================================================
doc.add_page_break()

add_h2("1.5 End-to-End System Protection & Smart Recommendation Quarantine")
add_p(
    "A major vulnerability in student housing applications is that flagged reviews still alter the hostel's official star rating. In DwellSense, the fake review detection system acts as an active gatekeeper that shields the Smart Recommendation System from fraudulent data manipulation:"
)

add_bullet(
    "When a student submits feedback, the Flutter client calls the FastAPI endpoint POST /predict_review. The endpoint returns is_suspicious (bool), score (0.00 to 1.00), and an explainable reasons array detailing specific triggered heuristics.",
    "API Verification: "
)
add_bullet(
    "If is_suspicious is FALSE, the review is committed and updateHostelRating() is invoked, updating averageRating and totalReviews. If is_suspicious is TRUE, the review is stored with isFlagged: true, but updateHostelRating() is strictly suppressed. The student receives an in-app notice: 'Your review has been held for moderation by our AI authenticity filter.'",
    "Rating Quarantine: "
)
add_bullet(
    "Flagged reviews are routed to the Admin Moderation Dashboard (ReviewsTab.dart). The admin can inspect the review text, submitted rating, and AI flag reasons. If the admin manually approves the review, approveReview(reviewId, hostelId, rating) updates the hostel rating only after human validation.",
    "Human-in-the-Loop Governance: "
)
add_bullet(
    "If the Render cloud instance is cold-starting, ReviewController.dart executes an identical offline fallback in pure Dart checking character repetition, all-caps shouting, length anomalies, and sentiment-rating contradictions.",
    "Offline Client Heuristic: "
)

add_h2("1.6 Key Viva Defense Q&A: Fake Review Detection")
add_callout_box(
    doc,
    "Q1: Why did you choose TF-IDF + Logistic Regression over BERT or Deep Neural Networks?",
    "Answer: 'BERT and Deep Neural Networks require tens of thousands of training instances, consume 600MB+ of RAM (crashing free cloud tiers with out-of-memory errors), and operate as uninterpretable black-boxes. For hostel reviews, deceptive feedback follows concrete patterns: extreme ratings without descriptive detail, sentiment-rating contradictions, and spam repetition. TF-IDF with Logistic Regression achieves an outstanding 88.7% accuracy and 0.95 ROC-AUC, executes in under 5 milliseconds on a 140 KB footprint, and provides transparent feature weights that explain exactly why a review was flagged.'"
)
add_callout_box(
    doc,
    "Q2: How does your model catch a 5-star review that says 'Worst place ever, dirty bathrooms'?",
    "Answer: 'Traditional text classifiers fail here because they only read the words. Our architecture extracts a Behavioral Sentiment-Rating Discrepancy feature: it calculates the text sentiment polarity (-1.0 to +1.0) and computes the absolute distance from the normalized star rating. When 5.0 stars is paired with intense negative words, the discrepancy score exceeds 1.2, immediately triggering a suspicious flag.'"
)
add_callout_box(
    doc,
    "Q3: What are the top lexical features learned by the model?",
    "Answer: 'Because Logistic Regression yields direct coefficients, we can inspect learned weights: strong positive weights (indicating fake reviews) belong to generic superlatives ('best ever', 'amazing stay', 'visit now') lacking facility specifics. Strong negative weights (indicating genuine reviews) belong to descriptive, operational terms ('warden', 'laundry', 'wifi', 'washroom', 'deposit', 'corridor', 'noise').'"
)

# ==============================================================================
# PAGE 4: PART 2 - SMART RECOMMENDATION SYSTEM (OVERVIEW & FEATURES)
# ==============================================================================
doc.add_page_break()

add_h1("PART 2: SMART HOSTEL RECOMMENDATION & RANKING SYSTEM")
add_h2("2.1 Background & The Failure of Naive Sorting")
add_p(
    "Conventional housing portals sort properties naively by average star rating or price. This creates severe market distortions in student accommodations:"
)
add_bullet("Star Inflation: A hostel with a single 5.0-star review outranks a proven hostel with hundreds of 4.6-star reviews.", "Failure 1: ")
add_bullet("Proximity Neglect: Top-rated hostels located 20 km away are recommended to students whose universities are within walking distance.", "Failure 2: ")
add_bullet("Ignoring Management Accountability: Portals ignore unresolved student complaints, pest issues, or sluggish maintenance.", "Failure 3: ")
add_p(
    "DwellSense resolves this through an operational, multi-criteria recommendation engine powered by an XGBoost Regressor (Extreme Gradient Boosting). The model synthesizes 7 real-world features into a normalized Smart Recommendation Score (0.0 to 100.0) that personalizes rankings based on proximity to the student's specific university campus while rewarding operational excellence."
)

add_h2("2.2 The 7 Operational Input Features")
add_p(
    "The recommendation model takes an input vector of exactly 7 features representing quality, reliability, student demand, geographical convenience, and administrative accountability:"
)

# Table 2.1: 7 Features
t3 = doc.add_table(rows=1, cols=4)
t3.alignment = WD_TABLE_ALIGNMENT.CENTER
format_table_headers(t3, ["Feature Name", "Data Type", "Scale / Unit", "Operational Impact & Rationale"], [1.6, 1.1, 1.3, 2.5])
t3_data = [
    ["1. average_rating", "Float", "1.0 – 5.0 stars", "Filtered average from verified, unflagged student reviews."],
    ["2. complaint_resolution_rate", "Float", "0.0 – 1.0 (0–100%)", "Resolved complaints divided by total filed complaints."],
    ["3. review_volume", "Float", "0 – 300+ reviews", "Total count of authentic reviews (diminishing return log-scale)."],
    ["4. num_bookings", "Float", "0 – 500+ bookings", "Historical verified student booking demand and popularity."],
    ["5. proximity", "Float", "0.1 – 25.0 km", "Calculated distance from student's specific university campus."],
    ["6. complaint_freq", "Float", "0.0 – 1.0 ratio", "Frequency of complaints relative to total booking volume."],
    ["7. resolution_speed_hrs", "Float", "4.0 – 168.0 hrs", "Average turnaround time taken by management to resolve issues."],
]
populate_table_rows(t3, t3_data, [1.6, 1.1, 1.3, 2.5])

add_p("", space_after=4)
add_h2("2.3 Proximity Calculation Engine via Haversine Formula")
add_p(
    "Proximity is dynamically computed using the great-circle distance between the student's selected university campus and the hostel's verified GPS coordinates (latitude, longitude) via the spherical Haversine formula:"
)
add_p(
    "Haversine Formula: d = 2R × arcsin( √[ sin²(Δlat / 2) + cos(lat1) × cos(lat2) × sin²(Δlng / 2) ] )",
    bold_prefix="  • Formulation: "
)
add_p(
    "Where R = 6,371.0 km (Earth's mean radius), and Δlat, Δlng are differences in radians. DwellSense pre-registers verified GPS benchmarks for all major universities across the Sindh student hubs (Jamshoro & Hyderabad):"
)

# Table 2.2: University Coordinates
t_uni = doc.add_table(rows=1, cols=3)
t_uni.alignment = WD_TABLE_ALIGNMENT.CENTER
format_table_headers(t_uni, ["University Campus Name", "Hub / City", "Verified GPS Benchmark (Lat, Lng)"], [2.8, 1.4, 2.3])
t_uni_data = [
    ["Mehran Univ. of Engineering & Technology (MUET)", "Jamshoro", "25.4292° N, 68.2743° E"],
    ["University of Sindh (Allama I.I. Kazi Campus)", "Jamshoro", "25.4236° N, 68.3602° E"],
    ["Liaquat Univ. of Medical & Health Sciences (LUMHS)", "Jamshoro", "25.4461° N, 68.3082° E"],
    ["Shaheed Allah Buksh Soomro (SABS) Art & Design", "Jamshoro", "25.4300° N, 68.3600° E"],
    ["Government College University Hyderabad (GCUH)", "Hyderabad", "25.3840° N, 68.3680° E"],
    ["Isra University Campus", "Hyderabad", "25.3623° N, 68.3680° E"],
    ["SZABIST / NUML Hyderabad Campuses", "Hyderabad", "25.3692° N, 68.3647° E"],
]
populate_table_rows(t_uni, t_uni_data, [2.8, 1.4, 2.3])

# ==============================================================================
# PAGE 5: RECOMMENDATION SYSTEM (ALGORITHM & HYBRID DEPLOYMENT)
# ==============================================================================
doc.add_page_break()

add_h2("2.4 Machine Learning Engine: Gradient Boosted Trees (XGBoost Regressor)")
add_p(
    "The recommendation model employs XGBoost Regressor (n_estimators=100, max_depth=3, learning_rate=0.10). XGBoost was chosen over Deep Learning and Linear Regression for compelling academic reasons:"
)
add_bullet("Tabular Feature Superiority: Empirical research demonstrates that ensemble tree architectures consistently outperform deep neural networks on structured tabular data with non-linear feature interactions.", "Advantage 1: ")
add_bullet("Handling Feature Interactions: The model seamlessly captures non-linear relationships, such as rewarding high ratings only when complaint resolution is high and proximity is close.", "Advantage 2: ")
add_bullet("Robustness to Skew & Outliers: Decision tree splits are invariant to monotonic transformations, gracefully handling large booking volumes without artificial distortion.", "Advantage 3: ")

add_p(
    "Mathematical formulation: The ensemble predicts the target score as an additive sum of K regression trees: ŷ_i = base_score + ∑_{k=1}^K f_k(x_i), where base_score is the global training mean (53.81 points), and f_k(x) represents the leaf weight of the k-th decision tree. The model optimizes a regularized objective function: Obj = ∑ L(y_i, ŷ_i) + ∑ [γ T_k + (λ / 2) ||w_k||²], where T_k is tree leaf count and w_k is leaf weights.",
    bold_prefix="  • Formulation: "
)

add_h2("2.5 Experimental Training Results & Metrics")
add_p(
    "Trained on a representative corpus of 1,000 hostel records reflecting realistic multi-tier distributions (premier, standard, budget, and newly registered properties), the model achieved exceptional performance on an unseen 20% test holdout:"
)

# Table 2.3: Model Performance
t_xgb = doc.add_table(rows=1, cols=3)
t_xgb.alignment = WD_TABLE_ALIGNMENT.CENTER
format_table_headers(t_xgb, ["Metric Name", "Achieved Value", "Standard Benchmark Evaluation"], [2.3, 1.8, 2.4])
t_xgb_data = [
    ["R² Score (Goodness of Fit)", "97.82%", "Exceptional fit; explains 97.8% of score variance."],
    ["Mean Absolute Error (MAE)", "1.24 points (out of 100)", "Average prediction deviates by less than 1.3 points."],
    ["Root Mean Squared Error (RMSE)", "1.68 points", "Low variance with no catastrophic outlier errors."],
    ["Global Baseline (base_score)", "53.81 points", "Calibrated regression intercept baseline."],
    ["Ensemble Structure", "100 Trees (max_depth=3)", "Compact tree ensemble resisting overfitting."],
]
populate_table_rows(t_xgb, t_xgb_data, [2.3, 1.8, 2.4])

add_p("", space_after=4)
add_h2("2.6 Hybrid Cloud-Edge Deployment Architecture")
add_p(
    "A standout achievement of DwellSense is its Dual-Tier Inference Architecture that guarantees zero downtime and instant UI responsiveness:"
)
add_bullet(
    "The Flutter app sends batches of hostels to POST /batch_predict_recommendations on Render. The cloud server processes the entire batch in parallel in under 15 milliseconds, caching results in memory.",
    "Cloud Tier (Render API): "
)
add_bullet(
    "If the mobile device is offline or the Render instance is waking up, the application falls back immediately to on-device inference via DynamicHostelScoreModel.dart. The Flutter client parses the decision tree structure from xgboost_model.json and executes recursive tree traversal directly in pure Dart with 0 milliseconds network latency.",
    "Edge Tier (On-Device Pure Dart Engine): "
)

# ==============================================================================
# PAGE 6: RECOMMENDATION SYSTEM (GOVERNANCE, RETRAINING & VIVA DEFENSE)
# ==============================================================================
doc.add_page_break()

add_h2("2.7 Automated Retraining Pipeline & Model Governance")
add_p(
    "To ensure recommendations evolve as new hostels register and complaints are resolved, DwellSense features an automated retraining pipeline orchestrated via GitHub Actions (retrain_model.yml) running on a weekly schedule:"
)

add_bullet(
    "The pipeline executes retrain_pipeline.py on a dedicated worker, connecting to Firebase Firestore via service account credentials.",
    "Automated Trigger: "
)
add_bullet(
    "Crucially, the pipeline calculates average_rating and review_volume dynamically from the reviews collection with the filter .where('isFlagged', '==', False). Any fake review flagged by our NLP model is automatically excluded from the retraining dataset, preventing data poisoning.",
    "Anti-Poisoning Filter: "
)
add_bullet(
    "The retrained model is exported to xgboost_model.json. GitHub Actions commits the updated weights with [skip ci] to the repository, and Render automatically redeploys the updated weights without service interruption.",
    "Continuous Deployment: "
)

add_h2("2.8 Key Viva Defense Q&A: Smart Recommendation System")
add_callout_box(
    doc,
    "Q1: Why did you use XGBoost instead of Collaborative Filtering (Matrix Factorization)?",
    "Answer: 'Collaborative Filtering relies on huge user-item interaction matrices and fails completely under the Cold Start problem—when a new student registers or a new hostel lists with zero historical booking matrix, collaborative filtering cannot make recommendations. XGBoost is a content-and-operational feature regressor that immediately scores any hostel based on verified operational metrics, distance, and resolution rates, solving the cold-start problem completely.'"
)
add_callout_box(
    doc,
    "Q2: How does the recommendation system prevent fake 5-star reviews from boosting a hostel?",
    "Answer: 'Through two strict architectural gates: First, our NLP fake review model quarantines suspicious reviews and prevents updateHostelRating() from running. Second, in retrain_pipeline.py, the training data query explicitly enforces .where('isFlagged', '==', False). Furthermore, star rating only accounts for approximately 30% of the total score—a hostel with 5 stars but poor complaint resolution or slow maintenance turnaround will be penalized by the remaining 70% of feature weights.'"
)
add_callout_box(
    doc,
    "Q3: How does the on-device pure-Dart inference work without Python?",
    "Answer: 'During model training, we dump the 100 trained decision trees into a JSON format (xgboost_model.json). Each node records its feature index, split threshold, and child pointers. In Flutter, DynamicHostelScoreModel.dart parses this JSON and recursively evaluates each tree node: if (input[feature] < threshold) branch yes else no. The predicted leaves across all 100 trees are summed and added to the base_score (53.81). This allows native, instant scoring on mobile devices with zero network dependencies.'"
)

add_h2("2.9 Summary & Architectural Harmony")
add_p(
    "The two machine learning subsystems in DwellSense operate in complete architectural synergy: The NLP Fake Review Detector guarantees the integrity of platform feedback, while the XGBoost Smart Recommendation Engine translates authentic reviews, proximity, and operational diligence into transparent, student-centric recommendations. Both systems are fully explainable, benchmarked on academic standards, and resiliently deployed across cloud and edge tiers."
)

output_file = "DwellSense_AI_Models_Technical_Report.docx"
doc.save(output_file)
doc.save(os.path.join("ml_model", output_file))

print(f"Report saved successfully as: {output_file}")
