const Map<String, dynamic> offlineTreatments = {
  "Alternaria": {
    "disease_name": "Alternaria Leaf Blight",
    "severity": "high",
    "description": {
      "en": "Alternaria Leaf Blight is a fungal disease caused by Alternaria porri. It causes purple-brown lesions on leaves with concentric rings, leading to premature defoliation and 30-50% yield loss in severe outbreaks.",
    },
    "symptoms": [
      "Small, water-soaked lesions that turn purple-brown on leaves and seed stalks",
      "Concentric ring patterns visibly expanding within the lesions",
      "Yellowing and premature collapse of foliage from leaf tips downwards",
      "Reduced bulb size and compromised neck tissue drying",
    ],
    "treatment_steps": [
      "Spray Mancozeb 75% WP @ 2.5 g/L or Propiconazole 25% EC @ 1 ml/L water every 10-14 days",
      "Apply Chlorothalonil 75% WP @ 2 g/L at the first appearance of leaf spots",
      "Remove and safely burn severely infected crop debris from fields",
      "Avoid overhead sprinkler irrigation during warm afternoons to minimize leaf wetness duration",
      "Incorporate bio-fungicide Trichoderma viride @ 5 kg/ha mixed with well-rotted FYM",
    ],
    "prevention": [
      "Use certified disease-free seeds treated with Thiram @ 3 g/kg seed",
      "Maintain 3-year non-allium crop rotation (e.g., maize, pulses)",
      "Ensure recommended planting spacing (15 cm x 10 cm) for adequate canopy ventilation",
      "Avoid excess nitrogen fertilizer which creates lush, vulnerable succulent foliage",
    ],
    "local_products": ["Dithane M-45 (Mancozeb)", "Tilt (Propiconazole)", "Kavach (Chlorothalonil)", "Neem Extract 10000 ppm"],
  },
  "Bulb_Blight": {
    "disease_name": "Bulb Rot / Botrytis Neck Rot",
    "severity": "critical",
    "description": {
      "en": "Bulb Rot is a destructive fungal pathogen (Botrytis allii & Fusarium oxysporum) that infects onion necks and bulbs during late maturity or post-harvest storage, producing soft watery decay.",
    },
    "symptoms": [
      "Soft, spongy neck tissue collapsing under slight finger pressure",
      "Water-soaked scales turning greyish-brown with visible foul odor",
      "Grey mold or black sclerotia clusters visible under outer dry scales",
      "Rapid post-harvest breakdown and liquefaction inside storage chawls",
    ],
    "treatment_steps": [
      "Allow full neck closure and sun cure lifted bulbs for 5-7 days prior to storage",
      "Dip or spray harvested bulbs with Carbendazim 50% WP @ 1 g/L before loading into crates",
      "Segregate and discard any cut, thick-necked, or bruised bulbs immediately",
      "Maintain active air draft in storage chawls; keep relative humidity strictly under 70%",
      "Dust storage bays with sulfur powder @ 2 kg per quintal storage capacity",
    ],
    "prevention": [
      "Withhold irrigation 15 days prior to harvest to allow outer scales to dry naturally",
      "Harvest only when 50% of the field shows tops fallen over (neck break stage)",
      "Disinfect storage bins and chawl bamboo racks with 2% copper sulfate wash before stocking",
      "Avoid harvesting under damp, cloudy, or rainy morning conditions",
    ],
    "local_products": ["Bavistin (Carbendazim)", "Copper Oxychloride (Blitox)", "Sulfur 80% WDG", "Trichoderma harzianum"],
  },
  "Caterpillar": {
    "disease_name": "Spodoptera / Onion Cutworm Infestation",
    "severity": "moderate",
    "description": {
      "en": "Onion armyworms (Spodoptera exigua) and cutworms feed voraciously on tubular green onion leaves, hollowing them out from within and severing seedlings at ground level.",
    },
    "symptoms": [
      "Tubular onion leaves chewed transparently with whitish translucent patches ('windows')",
      "Presence of dark green frass (droppings) inside tubular leaf cavities",
      "Young seedlings cut off cleanly near the soil surface overnight",
      "Visible greenish-brown larvae hiding inside leaves or under loose soil around bulbs",
    ],
    "treatment_steps": [
      "Spray Emamectin Benzoate 5% SG @ 0.4 g/L water during late evening hours",
      "Apply Chlorantraniliprole 18.5% SC (Coragen) @ 0.3 ml/L for systemic caterpillar knockdown",
      "Install pheromone traps with Spodolure @ 5 traps per acre for population monitoring",
      "Spray 5% Neem Seed Kernel Extract (NSKE) or Azadirachtin 1500 ppm @ 3 ml/L water",
      "Release egg parasitoid Trichogramma chilonis @ 50,000 per acre",
    ],
    "prevention": [
      "Deep summer ploughing to expose pupae to predatory birds and intense sun",
      "Handpick and destroy egg clusters found on leaf undersides",
      "Avoid planting adjacent to heavily infested lucerne or castor fields",
      "Maintain weed-free field borders to eliminate alternate caterpillar host plants",
    ],
    "local_products": ["Proclaim (Emamectin Benzoate)", "Coragen (Chlorantraniliprole)", "Econeem", "Spinosad 45% SC"],
  },
  "Fusarium": {
    "disease_name": "Fusarium Basal Rot",
    "severity": "high",
    "description": {
      "en": "Fusarium oxysporum f. sp. cepae is a soil-borne vascular fungus that invades the basal root plate of the onion, causing root rot, yellow leaf curved dieback, and storage rotting.",
    },
    "symptoms": [
      "Progressive yellowing and curving/curling of leaves starting from the tips",
      "Complete rot and disappearance of roots, allowing the bulb to be pulled out effortlessly",
      "Brownish-pink vascular discoloration across the basal stem plate",
      "Bulb firmness failure with foul-smelling secondary bacterial soft rot in storage",
    ],
    "treatment_steps": [
      "Drench root zones with Carbendazim 12% + Mancozeb 63% WP (Saaf) @ 2.5 g/L water",
      "Apply biological consortium of Trichoderma viride + Pseudomonas fluorescens @ 5 kg/acre in FYM",
      "Drench affected patches immediately and isolate drainage runoff from healthy beds",
      "Avoid root-damaging deep weeding or tillage around the bulb perimeter",
    ],
    "prevention": [
      "Follow strict 4-5 year rotation with sorghum, maize, or marigold to suppress soil inoculum",
      "Solarize nursery beds with 25-micron transparent polyethylene film for 4-6 weeks during May",
      "Dip seedling roots in 0.2% Carbendazim suspension for 15 minutes before transplanting",
      "Improve soil drainage and avoid planting in waterlogged low-lying fields",
    ],
    "local_products": ["Saaf (Carbendazim + Mancozeb)", "Biocure-F (Trichoderma)", "Paclobutrazol", "Benomyl 50% WP"],
  },
  "Healthy": {
    "disease_name": "Healthy Onion Crop",
    "severity": "low",
    "description": {
      "en": "The inspected onion plant exhibits vigorous physiological health with erect deep-green foliage, firm unblemished necks, clean root plates, and zero fungal or insect lesions.",
    },
    "symptoms": [
      "Uniform, deep waxy green tubular leaves without lesions or necrotic tipping",
      "Firm, well-developed bulb with intact, dry, translucent outer protective scales",
      "Tight, dry neck structure ensuring natural pest and pathogen exclusion",
      "Strong white healthy root system anchoring securely into loose soil",
    ],
    "treatment_steps": [
      "No chemical pesticide intervention required. Maintain balanced fertigation",
      "Apply water-soluble 19:19:19 NPK @ 5 g/L during vegetative leaf stage",
      "Shift to 0:52:34 (Monopotassium phosphate) @ 5 g/L during bulb enlargement stage",
      "Spray micro-nutrient mixture (Zinc, Boron, Sulfur) to strengthen skin firmness and color",
    ],
    "prevention": [
      "Maintain consistent soil moisture through drip or furrow irrigation without waterlogging",
      "Monitor weather forecasts for sudden humidity spikes or unseasonal rainfall",
      "Scout crop twice weekly for early signs of thrips or purple blotch spots",
    ],
    "local_products": ["Mahadhan 19:19:19", "SoluBor (Boron 20%)", "Sulfur 80% WDG", "Bio-Stimulant Humic Acid"],
  },
  "Virosis": {
    "disease_name": "Onion Yellow Dwarf Virus (OYDV) / Iris Yellow Spot",
    "severity": "high",
    "description": {
      "en": "Onion Yellow Dwarf is a potyvirus transmitted non-persistently by aphids and thrips. It causes yellow streaking, stunting, crinkling of leaves, and severe loss in bulb weight and vigor.",
    },
    "symptoms": [
      "Distinct yellow streaks and chlorotic striping running longitudinally along leaves",
      "Crinkled, flattened, drooping, or twisted leaves with stunted fan-like appearance",
      "Distorted flower stems in seed crops, producing small, sterile umbels",
      "Markedly undersized bulbs that sprout prematurely or deteriorate rapidly in storage",
    ],
    "treatment_steps": [
      "Viruses cannot be cured chemically once inside the plant. Rogue and destroy infected plants immediately",
      "Control vector insect populations (Aphids & Thrips) using Imidacloprid 17.8% SL @ 0.5 ml/L",
      "Alternatively spray Fipronil 5% SC @ 1.5 ml/L or Thiamethoxam 25% WG @ 0.3 g/L",
      "Install blue and yellow sticky insect traps @ 20 traps per acre across the field",
      "Spray systemic plant vigor booster (Salicylic acid @ 100 ppm) to trigger systemic acquired resistance",
    ],
    "prevention": [
      "Plant only indexed, certified virus-free bulb sets and certified seeds",
      "Avoid planting next to volunteer onion volunteers or unmanaged leek/garlic fields",
      "Isolate seed production fields at least 1 km away from commercial bulb fields",
      "Eradicate perennial broadleaf weeds around borders that serve as aphid overwintering reservoirs",
    ],
    "local_products": ["Confidor (Imidacloprid)", "Actara (Thiamethoxam)", "Regent (Fipronil)", "Yellow Sticky Cards"],
  },
};
