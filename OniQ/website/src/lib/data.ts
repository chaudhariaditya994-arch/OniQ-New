export const NAV_LINKS = [
  { href: "/", label: "Home" },
  { href: "/about", label: "About" },
  { href: "/gallery", label: "Gallery" },
  { href: "/team", label: "Team" },
  { href: "/contact", label: "Contact Us" },
] as const;

export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.onionguard.app";

export const STATS = [
  { value: 94.23, suffix: "%", label: "On-device model accuracy" },
  { value: 6, suffix: "", label: "Disease & pest classes detected" },
  { value: 5, suffix: "", label: "Local languages supported" },
  { value: 5.99, suffix: "MB", label: "Model size, fully offline" },
] as const;

export const DISEASE_CLASSES = [
  "Alternaria",
  "Bulb Blight",
  "Caterpillar",
  "Fusarium",
  "Healthy",
  "Virosis",
] as const;

export const LANGUAGES = [
  { code: "en", name: "English" },
  { code: "tw", name: "Twi" },
  { code: "dg", name: "Dagbani" },
  { code: "ee", name: "Ewe" },
  { code: "ha", name: "Hausa" },
] as const;

export const FEATURES = [
  {
    title: "On-Device Disease Detection",
    description:
      "A 5.99MB TFLite model classifies 6 conditions — Alternaria, Bulb Blight, Caterpillar, Fusarium, Healthy, and Virosis — directly on the phone, no internet required.",
    icon: "scan",
  },
  {
    title: "Freshness Analysis",
    description:
      "Google Gemini 2.5 Flash Vision evaluates onion freshness as Fresh, Almost Spoilt, or Rotten, with actionable storage tips.",
    icon: "leaf",
  },
  {
    title: "Treatment Recommendations",
    description:
      "Detailed guides covering symptoms, treatment steps, prevention, and local product recommendations for every detected condition.",
    icon: "clipboard",
  },
  {
    title: "Voice Guidance in 5 Languages",
    description:
      "Treatment advice is read aloud in English, Twi, Dagbani, Ewe, and Hausa so low-literacy farmers can act on it directly.",
    icon: "volume",
  },
  {
    title: "Role-Based Dashboards",
    description:
      "Farmers track personal scan history, Extension Officers monitor regional trends, and Admins oversee the full platform.",
    icon: "chart",
  },
  {
    title: "Secure by Design",
    description:
      "JWT authentication with bcrypt hashing, biometric login, and end-to-end HTTPS via TLS 1.2/1.3 protect every account.",
    icon: "shield",
  },
] as const;

export const HOW_IT_WORKS = [
  {
    step: "01",
    title: "Scan the crop",
    description: "Point the camera at an onion plant or bulb, or pick an existing photo from the gallery.",
  },
  {
    step: "02",
    title: "Get an instant diagnosis",
    description: "The on-device model classifies the condition in seconds, entirely offline.",
  },
  {
    step: "03",
    title: "Read the treatment guide",
    description: "See symptoms, treatment steps, prevention, and local product recommendations.",
  },
  {
    step: "04",
    title: "Listen in your language",
    description: "Play the guidance aloud in English, Twi, Dagbani, Ewe, or Hausa.",
  },
] as const;

export const TEAM = [
  {
    name: "Benedicta Afi Agbodzi",
    role: "Team Lead",
    department: "Department of Communication Studies (MPhil)",
    photo: "/team/Nayram.jpeg",
  },
  {
    name: "Nathaniel Agbesi Adika",
    role: "Team Member",
    department: "Department of Computer Engineering",
    photo: "/team/Nat.jpeg",
  },
  {
    name: "Elvis Asare Nkrumah",
    role: "Team Member",
    department: "Department of Computer Science and Statistics",
    photo: "/team/Elvis.jpeg",
  },
  {
    name: "Emmanuel Bobbie",
    role: "Team Member",
    department: "Department of Crop Science",
    photo: "/team/Bobbie.jpeg",
  },
  {
    name: "Issah Jarah Muftawu",
    role: "Team Member",
    department: "Department of Materials Science and Engineering",
    photo: "/team/Issah.jpeg",
  },
] as const;

export const GALLERY_PHOTOS = Array.from({ length: 14 }, (_, i) => ({
  src: `/screenshots/${i + 1}.jpeg`,
  alt: `The Nkabom Honours Team building and presenting OnionGuard, photo ${i + 1}`,
}));

// Indices chosen to exclude the handful of portrait-oriented source photos
// (2, 9, 12) so these landscape-tuned hero bands show the full photo with
// no left/right cropping.
export const HOME_HERO_IMAGES = [
  GALLERY_PHOTOS[12],
  GALLERY_PHOTOS[13],
  GALLERY_PHOTOS[3],
  GALLERY_PHOTOS[7],
  GALLERY_PHOTOS[9],
];

export const ABOUT_HERO_IMAGES = [
  GALLERY_PHOTOS[0],
  GALLERY_PHOTOS[2],
  GALLERY_PHOTOS[4],
  GALLERY_PHOTOS[5],
];

export const GALLERY_HERO_IMAGES = [
  GALLERY_PHOTOS[5],
  GALLERY_PHOTOS[6],
  GALLERY_PHOTOS[9],
  GALLERY_PHOTOS[10],
];

export const TEAM_HERO_IMAGES = TEAM.map((m) => ({
  src: m.photo,
  alt: `${m.name}, ${m.role}`,
}));

export const CONTACT_HERO_IMAGES = [GALLERY_PHOTOS[2], GALLERY_PHOTOS[6], GALLERY_PHOTOS[9]];

export const HOME_TYPING_PHRASES = [
  "Scan a crop, get an instant diagnosis, and hear treatment guidance in your own language.",
  "AI-powered onion disease detection, built for farmers in Ghana.",
  "Works fully offline, right on your phone — no internet required.",
  "Detects 6 conditions in seconds, with 94% on-device accuracy.",
  "Free to download and live now on the Google Play Store.",
] as const;

export const ABOUT_TYPING_PHRASES = [
  "Crop losses from pests and disease reach up to 50% in West Africa.",
  "No onion-specific AI model existed before OnionGuard.",
  "Trained on 3,044 field images from the TOM2024 dataset.",
  "A MobileNetV3-Large model fine-tuned in three progressive stages.",
  "Just 5.99MB — small enough to run entirely on-device.",
] as const;

export const GALLERY_TYPING_PHRASES = [
  "See the Nkabom team pitch OnionGuard to the Nkabom Honours Program.",
  "Field visits to onion markets across Ghana.",
  "Video reflections from the team behind the project.",
  "Photos from Nkabom Students Networking Day.",
  "A behind-the-scenes look at building OnionGuard.",
] as const;

export const TEAM_TYPING_PHRASES = [
  "Five students at the University of Ghana.",
  "Communication, computer science, crop science, and engineering — together.",
  "Led by Benedicta Afi Agbodzi, Team Lead.",
  "Built through the Nkabom Honours Program.",
  "United to bring AI to the onion farmers who need it most.",
] as const;

export const CONTACT_TYPING_PHRASES = [
  "Got a question about OnionGuard? We're listening.",
  "Partnership ideas? Let's talk.",
  "Feedback from the field helps us improve.",
  "Reach the Nkabom Honours Team directly.",
  "We usually reply within a few days.",
] as const;

export const VIDEOS = [
  { src: "/videos/Video_1.mp4", label: "Nkabom Honours Program — team reflection 1" },
  { src: "/videos/Video_2.mp4", label: "Nkabom Honours Program — team reflection 2" },
  { src: "/videos/Video_3.mp4", label: "Nkabom Honours Program — team reflection 3" },
] as const;

export const TECH_STACK = [
  "Flutter",
  "FastAPI",
  "MongoDB Atlas",
  "TensorFlow Lite",
  "Gemini 2.5 Flash",
  "Docker",
  "AWS EC2",
  "Nginx",
] as const;
