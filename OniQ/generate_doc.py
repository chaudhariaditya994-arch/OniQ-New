from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT

doc = Document()
style = doc.styles['Normal']
style.font.name = 'Calibri'
style.font.size = Pt(11)

# TITLE PAGE
for _ in range(6):
    doc.add_paragraph('')
title = doc.add_paragraph()
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = title.add_run('OnionGuard')
run.bold = True
run.font.size = Pt(36)
run.font.color.rgb = RGBColor(76, 175, 80)

subtitle = doc.add_paragraph()
subtitle.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = subtitle.add_run('AI-Powered Onion Disease Detection\nfor Farmers in Ghana')
run.font.size = Pt(18)
run.font.color.rgb = RGBColor(100, 100, 100)

doc.add_paragraph('')
detail = doc.add_paragraph()
detail.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = detail.add_run('Technical Documentation')
run.font.size = Pt(14)
run.bold = True

doc.add_paragraph('')
info = doc.add_paragraph()
info.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = info.add_run('Nkabom Honours Team\nUniversity of Ghana\n2026')
run.font.size = Pt(12)
run.font.color.rgb = RGBColor(120, 120, 120)

doc.add_page_break()

# TABLE OF CONTENTS
doc.add_heading('Table of Contents', level=1)
toc_items = [
    '1. Problem Statement',
    '2. Solution Overview',
    '3. System Architecture',
    '4. Machine Learning Model',
    '5. Mobile Application Features',
    '6. Role-Based Access & Functionality',
    '   6.1 Farmer',
    '   6.2 Extension Officer',
    '   6.3 Admin',
    '7. Backend Microservices',
    '8. Deployment & Security',
    '9. Multi-Language Support',
    '10. Technology Stack',
    '11. Features Discussed',
]
for item in toc_items:
    p = doc.add_paragraph(item)
    p.paragraph_format.space_after = Pt(2)
doc.add_page_break()

# 1. PROBLEM STATEMENT
doc.add_heading('1. Problem Statement', level=1)
doc.add_paragraph(
    'Crop losses due to pests and diseases remain a major threat to food security in West Africa, '
    'with losses reaching up to 50% in some regions (Appiah et al., 2025). Onion farming is a critical '
    'livelihood for smallholder farmers, yet access to timely and accurate disease diagnosis remains limited. '
    'Farmers often rely on visual inspection and local knowledge, which can lead to misidentification, '
    'delayed treatment, and significant yield losses.'
)
doc.add_paragraph(
    'While AI-based disease detection has shown promise in crops like tomatoes and maize, no pre-existing '
    'machine learning models were available for onion disease classification. The TOM2024 dataset, a '
    'comprehensive collection of 25,844 field-captured images across tomato, onion, and maize crops, was '
    'published in 2025 by WASCAL researchers (Data in Brief, Elsevier). However, this dataset provides '
    'only raw and augmented images without any trained classification models.'
)
doc.add_paragraph('Key challenges identified include:')
challenges = [
    'No existing ML models for onion disease classification on the TOM2024 dataset',
    'Limited access to agricultural extension officers in rural farming communities',
    'Language barriers preventing farmers from accessing disease management information',
    'Lack of affordable, accessible diagnostic tools for smallholder farmers',
    'No centralized system for tracking disease outbreaks and regional trends',
]
for c in challenges:
    doc.add_paragraph(c, style='List Bullet')
doc.add_paragraph(
    'OnionGuard addresses these gaps by training a custom classification model on TOM2024\'s onion subset '
    'and deploying it in a mobile application that provides instant disease detection, treatment '
    'recommendations in local languages, and analytics dashboards for monitoring crop health.'
)

# 2. SOLUTION OVERVIEW
doc.add_heading('2. Solution Overview', level=1)
doc.add_paragraph(
    'OnionGuard is a mobile application built with Flutter that enables onion farmers to detect crop '
    'diseases using their smartphone camera. The app uses an on-device TensorFlow Lite model for instant '
    'disease classification, connects to a cloud backend for data persistence and analytics, and provides '
    'treatment recommendations with voice guidance in five local languages.'
)
doc.add_heading('Core Capabilities', level=2)
capabilities = [
    ('Disease Detection', 'On-device AI model classifies 6 onion conditions (Alternaria, Bulb Blight, Caterpillar, Fusarium, Healthy, Virosis) from camera or gallery images with no internet required.'),
    ('Freshness Analysis', 'Google Gemini 2.5 Flash Vision API evaluates onion freshness (Fresh, Almost Spoilt, Rotten) with storage and usage recommendations.'),
    ('Treatment Recommendations', 'Detailed treatment guides with symptoms, steps, prevention measures, and local product recommendations. Available in 5 languages with voice playback.'),
    ('Analytics & Monitoring', 'Personal scan history, disease distribution charts, and regional trend monitoring for farmers, extension officers, and administrators.'),
    ('Security', 'JWT authentication, bcrypt password hashing, biometric login, and HTTPS encryption via Let\'s Encrypt.'),
]
for t, d in capabilities:
    p = doc.add_paragraph()
    run = p.add_run(t + ': ')
    run.bold = True
    p.add_run(d)

# 3. SYSTEM ARCHITECTURE
doc.add_heading('3. System Architecture', level=1)
doc.add_paragraph(
    'OnionGuard follows a microservices architecture with a Flutter mobile frontend communicating with '
    'a Python FastAPI backend through an API Gateway. All services are containerized with Docker and '
    'deployed on an AWS EC2 instance.'
)
doc.add_heading('Architecture Flow', level=2)
doc.add_paragraph(
    'Flutter App  -->  HTTPS (443)  -->  Nginx (SSL Termination)  -->  API Gateway (:8000)  -->  Microservices'
)
doc.add_heading('Services', level=2)
table = doc.add_table(rows=6, cols=3)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Service', 'Port', 'Purpose']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
services = [
    ('API Gateway', '8000', 'Routes all client requests to the appropriate microservice'),
    ('Auth Service', '8001', 'User registration, login, JWT token management, user administration'),
    ('Diagnosis Service', '8002', 'TFLite model inference, scan result storage, diagnosis history'),
    ('Treatment Service', '8003', 'Treatment guides, voice generation via Google TTS'),
    ('Analytics Service', '8004', 'Scan statistics, disease distribution, regional trend analysis'),
]
for i, (s, p, d) in enumerate(services):
    table.rows[i+1].cells[0].text = s
    table.rows[i+1].cells[1].text = p
    table.rows[i+1].cells[2].text = d
doc.add_paragraph('')
doc.add_paragraph(
    'All microservices communicate internally via Docker networking. Only Nginx is exposed to the '
    'internet on ports 80 and 443. The database layer uses MongoDB Atlas (cloud-hosted) with separate '
    'databases for authentication, diagnosis, and analytics data.'
)

# 4. MACHINE LEARNING MODEL
doc.add_heading('4. Machine Learning Model', level=1)
doc.add_heading('4.1 Dataset: TOM2024', level=2)
doc.add_paragraph(
    'The model was trained on the onion subset of the TOM2024 dataset (Appiah et al., Data in Brief, 2025), '
    'which contains high-resolution field images captured across multiple regions in Burkina Faso under '
    'diverse environmental conditions. The onion subset consists of 3,044 images across 6 classes.'
)
table = doc.add_table(rows=7, cols=3)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Class', 'Type', 'Images']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
classes = [('Caterpillar','Pest','879'),('Fusarium','Disease','738'),('Healthy','Healthy','679'),
           ('Alternaria','Disease','515'),('Virosis','Disease','203'),('Bulb Blight','Disease','30')]
for i, (c, t, n) in enumerate(classes):
    table.rows[i+1].cells[0].text = c
    table.rows[i+1].cells[1].text = t
    table.rows[i+1].cells[2].text = n

doc.add_heading('4.2 Model Architecture', level=2)
table = doc.add_table(rows=9, cols=2)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Property', 'Value']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
props = [
    ('Base Model', 'MobileNetV3-Large (ImageNet pretrained)'),
    ('Input', '224 x 224 x 3 (RGB, normalized to [-1, 1])'),
    ('Output', '6 classes with confidence scores'),
    ('Optimizer', 'AdamW (weight_decay=0.01)'),
    ('LR Schedule', 'Cosine annealing with linear warmup'),
    ('Augmentation', 'CutMix, Mixup, RandomFlip, Rotation, Zoom, Brightness, Contrast'),
    ('Regularization', 'Dropout(0.3), Label Smoothing, Class Weights for imbalance'),
    ('Quantization', 'Float16 post-training quantization'),
]
for i, (p, v) in enumerate(props):
    table.rows[i+1].cells[0].text = p
    table.rows[i+1].cells[1].text = v

doc.add_heading('4.3 Training Strategy', level=2)
doc.add_paragraph(
    'The model uses a 3-stage progressive fine-tuning approach to maximize accuracy while preventing '
    'catastrophic forgetting of pretrained ImageNet features:'
)
table = doc.add_table(rows=4, cols=4)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Phase', 'Strategy', 'Epochs', 'Learning Rate']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
phases = [('Phase 1','Train classifier head only (backbone frozen)','20','1e-3'),
          ('Phase 2','Unfreeze last 30% of backbone','25','1e-4'),
          ('Phase 3','Full fine-tuning (all layers trainable)','15','1e-5')]
for i, (ph, s, e, lr) in enumerate(phases):
    table.rows[i+1].cells[0].text = ph
    table.rows[i+1].cells[1].text = s
    table.rows[i+1].cells[2].text = e
    table.rows[i+1].cells[3].text = lr

doc.add_heading('4.4 Results', level=2)

doc.add_paragraph('Overall Model Performance:')
table = doc.add_table(rows=5, cols=2)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Metric', 'Value']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
results = [('Full Model Test Accuracy','93.75%'),('TFLite INT8 Accuracy','93.75%'),
           ('Full Model Size','12.12 MB'),('TFLite Model Size','5.72 MB')]
for i, (m, v) in enumerate(results):
    table.rows[i+1].cells[0].text = m
    table.rows[i+1].cells[1].text = v

doc.add_paragraph('')
doc.add_heading('4.5 Classification Report (Per-Class Metrics)', level=2)
doc.add_paragraph(
    'The following table shows the precision, recall, and F1-score for each class on the held-out test set '
    '(304 images):'
)
table = doc.add_table(rows=10, cols=5)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Class', 'Precision', 'Recall', 'F1-Score', 'Support']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
cr_data = [
    ('Alternaria', '0.7660', '0.8780', '0.8182', '41'),
    ('Bulb Blight', '1.0000', '1.0000', '1.0000', '2'),
    ('Caterpillar', '1.0000', '0.9873', '0.9936', '79'),
    ('Fusarium', '0.9577', '0.8395', '0.8947', '81'),
    ('Healthy', '0.9452', '1.0000', '0.9718', '69'),
    ('Virosis', '0.9697', '1.0000', '0.9846', '32'),
    ('', '', '', '', ''),
    ('Macro Avg', '0.9398', '0.9508', '0.9438', '304'),
    ('Weighted Avg', '0.9416', '0.9375', '0.9378', '304'),
]
for i, (c, p, r, f, s) in enumerate(cr_data):
    table.rows[i+1].cells[0].text = c
    table.rows[i+1].cells[1].text = p
    table.rows[i+1].cells[2].text = r
    table.rows[i+1].cells[3].text = f
    table.rows[i+1].cells[4].text = s

doc.add_paragraph('')
doc.add_heading('4.6 Per-Class Accuracy', level=2)
table = doc.add_table(rows=7, cols=4)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Class', 'Correct', 'Total', 'Accuracy']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
pca_data = [
    ('Alternaria', '36', '41', '87.80%'),
    ('Bulb Blight', '2', '2', '100.00%'),
    ('Caterpillar', '78', '79', '98.73%'),
    ('Fusarium', '68', '81', '83.95%'),
    ('Healthy', '69', '69', '100.00%'),
    ('Virosis', '32', '32', '100.00%'),
]
for i, (c, co, t, a) in enumerate(pca_data):
    table.rows[i+1].cells[0].text = c
    table.rows[i+1].cells[1].text = co
    table.rows[i+1].cells[2].text = t
    table.rows[i+1].cells[3].text = a

doc.add_paragraph('')
doc.add_heading('4.7 Evaluation Analysis', level=2)
doc.add_paragraph(
    'The model achieves strong performance across all classes with an overall accuracy of 93.75%. '
    'Key observations from the evaluation:'
)
eval_points = [
    'Caterpillar, Healthy, Virosis, and Bulb Blight achieve near-perfect or perfect classification (98-100% accuracy).',
    'Fusarium shows the lowest per-class accuracy at 83.95%, likely due to visual similarity with other fungal diseases like Alternaria.',
    'Alternaria achieves 87.80% accuracy with strong recall (0.878) but lower precision (0.766), indicating some false positives from other classes being misclassified as Alternaria.',
    'The macro average F1-score of 0.9438 indicates balanced performance across all classes despite significant class imbalance.',
    'Class weights were applied during training to handle imbalance (879 Caterpillar vs 30 Bulb Blight images), contributing to the strong performance on minority classes.',
    'The TFLite INT8 quantized model maintains the same 93.75% accuracy as the full model, demonstrating that quantization does not degrade performance for this task.',
]
for ep in eval_points:
    doc.add_paragraph(ep, style='List Bullet')

doc.add_paragraph('')
doc.add_heading('4.8 Confusion Matrix', level=2)
doc.add_paragraph(
    'The confusion matrix reveals that the primary sources of misclassification are between Fusarium '
    'and Alternaria, which share similar visual symptoms (leaf discoloration and necrotic spots). '
    'The model correctly identifies all Healthy, Virosis, and Bulb Blight samples with zero misclassifications.'
)

doc.add_heading('4.9 Key Innovation', level=2)
doc.add_paragraph(
    'No pre-trained ML models existed for onion disease classification on the TOM2024 dataset prior to '
    'this work. OnionGuard is the first application to train and deploy a production model on this dataset, '
    'bridging the gap between published agricultural data and practical farmer-facing tools.'
)

# 5. MOBILE APPLICATION FEATURES
doc.add_heading('5. Mobile Application Features', level=1)

doc.add_heading('5.1 Splash Screen & Authentication', level=2)
doc.add_paragraph(
    'The app launches with an animated splash screen featuring the OnionGuard logo. Users can register '
    'with their name, email, phone number, and username, selecting their role (Farmer, Extension Officer, '
    'or Admin). Authentication is handled via JWT tokens with bcrypt password hashing. Biometric login '
    '(fingerprint/face recognition) is available as an optional security feature.'
)
doc.add_heading('5.2 Disease Scanning', level=2)
doc.add_paragraph(
    'The core feature allows users to scan onion crops for diseases. Users can either take a photo using '
    'the device camera or select an existing image from the gallery. The on-device TFLite model processes '
    'the image (resized to 224x224, normalized to [-1, 1]) and returns predictions for all 6 classes with '
    'confidence scores. The entire inference runs locally on the device, requiring no internet connection. '
    'Results are displayed with the predicted disease name, confidence percentage, and a breakdown of all '
    'class predictions. Scan results are automatically saved to the backend for history tracking.'
)
doc.add_heading('5.3 Freshness Analysis', level=2)
doc.add_paragraph(
    'A separate feature uses the Google Gemini 2.5 Flash Vision API to evaluate onion freshness. Users '
    'photograph their onions and receive an assessment categorizing them as Fresh, Almost Spoilt, or '
    'Rotten, along with a confidence score, detailed analysis, and practical storage tips.'
)
doc.add_heading('5.4 Treatment Recommendations', level=2)
doc.add_paragraph(
    'After a disease is detected, users can view detailed treatment guides that include the disease '
    'description, severity level, list of symptoms, step-by-step treatment instructions with dosages, '
    'prevention measures, and locally available product recommendations (fungicides, biopesticides). '
    'All treatment content is available in 5 languages (English, Twi, Dagbani, Ewe, Hausa) with voice '
    'playback powered by Google Text-to-Speech (gTTS), making the app accessible to low-literacy farmers.'
)
doc.add_heading('5.5 Analytics Dashboard', level=2)
doc.add_paragraph(
    'The analytics page displays personalized farm statistics including total scans performed, healthy '
    'vs diseased counts, and disease distribution charts built with the fl_chart library. Users can '
    'track their crop health trends over time and identify recurring disease patterns.'
)
doc.add_heading('5.6 Scan History', level=2)
doc.add_paragraph(
    'All previous scans are stored and accessible through the history tab. Each entry shows the detected '
    'disease, confidence score, and time since the scan. Users can tap any entry to view the full '
    'diagnosis result and access treatment recommendations.'
)
doc.add_heading('5.7 Settings', level=2)
doc.add_paragraph(
    'The settings page provides language selection (5 languages), biometric login toggle, password change '
    'functionality, and logout. Language preferences persist across sessions via SharedPreferences.'
)

# 6. ROLE-BASED ACCESS
doc.add_heading('6. Role-Based Access & Functionality', level=1)
doc.add_paragraph(
    'OnionGuard implements three distinct user roles, each with tailored functionality accessible through '
    'a role-specific bottom navigation bar.'
)

doc.add_heading('6.1 Farmer', level=2)
doc.add_paragraph('The primary user role, designed for onion farmers in the field.')
for t, d in [
    ('Home Tab', 'Welcome card with user name, large scan button for camera capture, and gallery picker for existing images.'),
    ('Freshness Tab', 'Freshness check feature using Gemini Vision AI to assess onion quality with storage recommendations.'),
    ('History Tab', 'Chronological list of all previous scan results with disease name, confidence score, and relative timestamp. Tap any entry to view full results and treatment.'),
    ('Analytics Tab', 'Personal farm analytics showing total scans, healthy/diseased counts, and disease distribution charts.'),
]:
    p = doc.add_paragraph()
    run = p.add_run(t + ': ')
    run.bold = True
    p.add_run(d)

doc.add_heading('6.2 Extension Officer', level=2)
doc.add_paragraph('Designed for agricultural extension officers who monitor farming communities.')
for t, d in [
    ('Home Tab', 'Same scanning functionality as farmers for field assessments.'),
    ('Freshness Tab', 'Same freshness analysis capabilities.'),
    ('Scans Tab', 'View all farmer scans across the platform, grouped by farmer email. Enables monitoring of disease patterns across multiple farms and communities.'),
    ('Trends Tab', 'Regional disease statistics and trend analysis. View disease distribution across different areas to identify outbreak patterns and prioritize interventions.'),
]:
    p = doc.add_paragraph()
    run = p.add_run(t + ': ')
    run.bold = True
    p.add_run(d)

doc.add_heading('6.3 Admin', level=2)
doc.add_paragraph('System administrators with full platform management capabilities.')
for t, d in [
    ('Home Tab', 'Same scanning functionality for testing and verification.'),
    ('Freshness Tab', 'Same freshness analysis capabilities.'),
    ('Users Tab', 'Complete user management interface. View all registered users with filtering by user type (Farmer, Extension Officer, Admin). Activate or deactivate user accounts. View user details including name, email, phone, registration date, and status.'),
    ('Analytics Tab', 'Platform-wide analytics showing total scans across all users, total registered users, global disease distribution, and system-wide health metrics.'),
]:
    p = doc.add_paragraph()
    run = p.add_run(t + ': ')
    run.bold = True
    p.add_run(d)

# 7. BACKEND MICROSERVICES
doc.add_heading('7. Backend Microservices', level=1)

doc.add_heading('7.1 API Gateway (Port 8000)', level=2)
doc.add_paragraph(
    'The API Gateway is the single entry point for all client requests. Built with FastAPI, it routes '
    'requests to the appropriate microservice using async HTTP forwarding via HTTPX. It handles CORS '
    'middleware, request timeouts, file uploads for image prediction, and audio streaming for voice '
    'treatment playback.'
)
doc.add_heading('7.2 Auth Service (Port 8001)', level=2)
doc.add_paragraph(
    'Manages all authentication and user operations. Users register with name, email, phone, username, '
    'password, user type, and language preference. Passwords are hashed with bcrypt. Login returns a JWT '
    'token (HS256) containing user email, type, and name. The service enforces single-admin policy '
    '(only one admin account allowed), supports account activation/deactivation, and provides password '
    'change and forgot password functionality. Data is stored in MongoDB Atlas.'
)
doc.add_heading('7.3 Diagnosis Service (Port 8002)', level=2)
doc.add_paragraph(
    'Handles disease prediction using a server-side TFLite model. Accepts image uploads, preprocesses '
    'them (resize to 224x224, normalize to [-1, 1]), runs inference through the TFLite interpreter, '
    'and returns predictions with confidence scores for all 6 classes. Also stores diagnosis results '
    'in MongoDB and provides history retrieval endpoints. The interpreter is lazy-loaded and supports '
    'both tflite-runtime and full TensorFlow as fallback.'
)
doc.add_heading('7.4 Treatment Service (Port 8003)', level=2)
doc.add_paragraph(
    'Serves comprehensive treatment guides for each disease, including multi-language descriptions, '
    'symptoms, treatment steps with dosages, prevention measures, and local product recommendations. '
    'Generates voice audio via Google Text-to-Speech (gTTS) in 5 languages (English, Twi, Dagbani, '
    'Ewe, Hausa) and streams the audio as MP3 to the client.'
)
doc.add_heading('7.5 Analytics Service (Port 8004)', level=2)
doc.add_paragraph(
    'Aggregates scan data using MongoDB pipeline aggregations. Provides per-user summaries (total scans, '
    'healthy/diseased counts, disease distribution), platform-wide statistics (total users, global '
    'disease trends), regional breakdowns (disease distribution by geographic area), and recent activity '
    'feeds. Supports both individual farmer analytics and system-wide monitoring for administrators.'
)

# 8. DEPLOYMENT & SECURITY
doc.add_heading('8. Deployment & Security', level=1)

doc.add_heading('8.1 AWS EC2 + Docker', level=2)
doc.add_paragraph(
    'All backend services are containerized with Docker and orchestrated via Docker Compose on an AWS '
    'EC2 instance. Each service runs in its own container with internal Docker networking. Backend '
    'service ports (8001-8004) are internal only and not accessible from the internet. Only Nginx is '
    'exposed on ports 80 and 443. All containers are configured with restart policies (unless-stopped) '
    'for reliability.'
)
doc.add_heading('8.2 HTTPS with Nginx + Let\'s Encrypt + DuckDNS', level=2)
doc.add_paragraph('To secure all API traffic with HTTPS, the following infrastructure was implemented:')
for t, d in [
    ('DuckDNS', 'Free dynamic DNS service maps the domain onion-guard.duckdns.org to the EC2 public IP address, providing a stable hostname for SSL certificate issuance.'),
    ('Nginx', 'Reverse proxy container handles SSL/TLS termination, automatically redirects all HTTP (port 80) traffic to HTTPS (port 443), and forwards decrypted requests to the API Gateway container.'),
    ('Certbot', 'Obtains free SSL certificates from Let\'s Encrypt using the ACME HTTP-01 challenge. Certificates support TLS 1.2 and TLS 1.3 protocols with strong cipher suites.'),
    ('Auto-Renewal', 'A dedicated Certbot container runs alongside Nginx, checking for certificate renewal every 12 hours. This ensures certificates never expire (Let\'s Encrypt certificates are valid for 90 days).'),
]:
    p = doc.add_paragraph()
    run = p.add_run(t + ': ')
    run.bold = True
    p.add_run(d)

doc.add_heading('8.3 Application Security', level=2)
for f in [
    'JWT authentication with HS256 algorithm for stateless session management',
    'Bcrypt password hashing for secure credential storage',
    'Biometric authentication (fingerprint/face) via device-level local_auth',
    'HTTPS-only communication (android:usesCleartextTraffic="false")',
    'Environment variables for sensitive configuration (API keys, database credentials)',
    'CORS middleware on the API Gateway',
]:
    doc.add_paragraph(f, style='List Bullet')

# 9. MULTI-LANGUAGE SUPPORT
doc.add_heading('9. Multi-Language Support', level=1)
doc.add_paragraph(
    'OnionGuard supports 5 languages to serve farming communities across Ghana and West Africa. '
    'The app includes 240+ translated UI strings managed through a ChangeNotifier provider pattern, '
    'with language preferences persisted per user via SharedPreferences.'
)
table = doc.add_table(rows=6, cols=3)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Language', 'Code', 'Region']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
for i, (l, c, r) in enumerate([('English','en','Default'),('Twi','tw','Ashanti Region'),
    ('Dagbani','dg','Northern Ghana'),('Ewe','ee','Volta Region'),('Hausa','ha','West Africa')]):
    table.rows[i+1].cells[0].text = l
    table.rows[i+1].cells[1].text = c
    table.rows[i+1].cells[2].text = r
doc.add_paragraph('')
doc.add_paragraph(
    'Treatment guides and voice playback are also available in all 5 languages, with Google TTS '
    'generating audio on-demand from the Treatment Service.'
)

# 10. TECHNOLOGY STACK
doc.add_heading('10. Technology Stack', level=1)
table = doc.add_table(rows=15, cols=3)
table.style = 'Light Grid Accent 1'
for i, h in enumerate(['Layer', 'Technology', 'Purpose']):
    table.rows[0].cells[i].text = h
    for p in table.rows[0].cells[i].paragraphs:
        for r in p.runs:
            r.bold = True
stack = [
    ('Frontend','Flutter / Dart','Cross-platform mobile application'),
    ('Backend','FastAPI / Python 3.11','Async microservices framework'),
    ('Database','MongoDB Atlas','Cloud-hosted NoSQL document store'),
    ('ML Inference','TensorFlow Lite','On-device and server-side model inference'),
    ('Vision AI','Google Gemini 2.5 Flash','Onion freshness analysis'),
    ('Voice','Google TTS (gTTS)','Treatment voice playback'),
    ('State Management','Provider','Reactive state management in Flutter'),
    ('Charts','fl_chart','Analytics data visualization'),
    ('Auth','JWT + Bcrypt','Token-based authentication'),
    ('Biometrics','local_auth','Fingerprint and face recognition'),
    ('Containerization','Docker + Docker Compose','Service isolation and orchestration'),
    ('Reverse Proxy','Nginx','SSL termination and request routing'),
    ('SSL/TLS','Let\'s Encrypt + Certbot','Free automated SSL certificates'),
    ('DNS','DuckDNS','Dynamic DNS for domain mapping'),
]
for i, (l, t, p) in enumerate(stack):
    table.rows[i+1].cells[0].text = l
    table.rows[i+1].cells[1].text = t
    table.rows[i+1].cells[2].text = p

doc.add_page_break()

# FEATURES DISCUSSED
doc.add_heading('11. Features Discussed', level=1)
doc.add_paragraph(
    'The following features were discussed during the project review for future development and improvement:'
)
features_discussed = [
    ('Fingerprint', 'Biometric authentication using fingerprint and face recognition for secure login.'),
    ('LLM in case of scanning a disease', 'Integrate a Large Language Model to provide AI-generated analysis and contextual advice when a disease is detected, offering deeper insights beyond the classification result.'),
    ('Linking farmers to customers (1)', 'A marketplace feature connecting onion farmers directly to buyers, enabling them to sell their produce through the platform.'),
    ('Freshness to customer (2)', 'Allow farmers to share freshness analysis results with potential buyers as proof of onion quality, building trust in transactions.'),
    ('Removal of admin from UI', 'Simplify the user interface by removing or restructuring the admin role from the main app flow.'),
    ('Analytics page is too simple', 'Enhance the analytics dashboard with more detailed charts, trends over time, comparative data, and actionable insights for farmers.'),
    ('Voice feature to read text in local languages', 'Expand voice capabilities to read all app text content (not just treatment guides) in local languages, improving accessibility for low-literacy users.'),
]
for t, d in features_discussed:
    p = doc.add_paragraph()
    run = p.add_run(t + ': ')
    run.bold = True
    p.add_run(d)

doc.add_paragraph('')
doc.add_heading('Needed', level=2)
needed_items = [
    'API keys for additional services',
    'Apple Developer account for iOS App Store deployment',
]
for item in needed_items:
    doc.add_paragraph(item, style='List Bullet')

doc.add_page_break()

# CLOSING
doc.add_heading('Google Play Store Status', level=1)
doc.add_paragraph(
    'OnionGuard is currently in closed testing on the Google Play Store. The application targets '
    'onion farmers where early disease detection can prevent significant crop losses and improve food '
    'security. The app is pending production approval following the required 14-day closed testing period '
    'with a minimum of 12 testers.'
)
doc.add_paragraph('')
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('This project was developed as part of academic research at the University of Ghana.')
run.italic = True
run.font.color.rgb = RGBColor(120, 120, 120)

doc.save('C:/Users/12345/Desktop/Projects/OnionGuard/OnionGuard-Documentation-v2.docx')
print('Done! Saved to OnionGuard-Documentation.docx')
