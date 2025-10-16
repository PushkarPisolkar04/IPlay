import '../models/level_model.dart';

final List<LevelModel> geographicalIndicationLevelsData = [
  LevelModel(
    id: 'gi_1',
    realmId: 'geographical_indication',
    levelNumber: 1,
    title: 'Understanding Geographical Indications',
    difficulty: 'Easy',
    xp: 50,
    content: '''
# What is a Geographical Indication (GI)?

A **GI** is a sign used on products that have a specific geographical origin and possess qualities or reputation due to that origin.

## Key Features

**Location-Based:**
Product's quality/reputation linked to geographical origin

**Collective Right:**
Owned by producers from that region (not individuals)

**Quality Assurance:**
Guarantees authenticity and quality

## Examples from India

**Agricultural:**
- Darjeeling Tea (West Bengal)
- Alphonso Mango (Maharashtra)
- Basmati Rice (Punjab, Haryana)

**Handicrafts:**
- Kanchipuram Silk (Tamil Nadu)
- Channapatna Toys (Karnataka)
- Madhubani Painting (Bihar)

**Manufactured:**
- Tirupati Laddu (Andhra Pradesh)
- Kolhapuri Chappal (Maharashtra)

## Purpose of GI

✓ Protect traditional knowledge
✓ Prevent misuse/imitation
✓ Benefit local communities
✓ Promote rural economy
✓ Preserve heritage

## Indian Law

**Act:** Geographical Indications of Goods (Registration and Protection) Act, 1999

**Effective from:** September 15, 2003

**Validity:** 10 years (renewable indefinitely)

## GI vs. Trademark

| Feature | GI | Trademark |
|---------|-----|-----------|
| Owner | Community/Region | Individual/Company |
| Transfer | Cannot be sold | Can be sold |
| Scope | Geographic origin | Source identification |
| Quality | Location-linked | Brand-linked |
''',
    quiz: [
      {'question': 'GI is owned by?', 'options': ['Individual', 'Company', 'Community/Region', 'Government'], 'correctAnswer': 2, 'explanation': 'GI is a collective right owned by regional producers.'},
      {'question': 'Which Act governs GI in India?', 'options': ['GI Act, 1999', 'Trademarks Act', 'Copyright Act', 'Patents Act'], 'correctAnswer': 0, 'explanation': 'GI Act, 1999 governs geographical indications.'},
      {'question': 'GI validity period?', 'options': ['5 years', '10 years', '20 years', '50 years'], 'correctAnswer': 1, 'explanation': 'GI is valid for 10 years, renewable indefinitely.'},
      {'question': 'Can GI be sold/transferred?', 'options': ['Yes', 'No', 'Only to companies', 'Only within region'], 'correctAnswer': 1, 'explanation': 'GI cannot be sold or transferred; it belongs to the region.'},
      {'question': 'First GI registered in India?', 'options': ['Basmati Rice', 'Darjeeling Tea', 'Alphonso Mango', 'Kanchipuram Silk'], 'correctAnswer': 1, 'explanation': 'Darjeeling Tea was the first GI registered (2004).'},
    ],
  ),
  LevelModel(
    id: 'gi_2',
    realmId: 'geographical_indication',
    levelNumber: 2,
    title: 'GI Registration Process',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Registering a GI in India

## Who Can Apply?

**Authorized Users:**
- Association of producers
- Organization of producers
- Government authorities
- Any interested person from the region

**NOT:** Individuals or companies alone

## Application Process

### Step 1: Application (Form GI-1)
- Name of geographical indication
- Description of goods
- Geographical area
- Proof of origin
- Uniqueness/special qualities
- Inspection body details

### Step 2: Examination
- Registrar examines application
- Checks if criteria met
- May request additional info

### Step 3: Opposition Period
- Application published in GI Journal
- **3 months** for objections
- Any person can oppose

### Step 4: Registration
- If no opposition or objections resolved
- Certificate issued
- Published in GI Journal

**Timeline:** 18-24 months typically

## Required Documents

- Statement of case
- Proof of geographical area
- Historical evidence
- Unique qualities proof
- Producer association details
- Inspection mechanism

## Fees

**Application:** ₹5,000
**Opposition:** ₹2,000
**Renewal (10 years):** ₹5,000

**Total for perpetual protection:** ₹5,000 every 10 years

## Classification

**Three Categories:**

**1. Agricultural (Class 1-32):**
- Crops, fruits, spices
- Tea, coffee
- Wine, spirits

**2. Natural (Class 1-4):**
- Minerals
- Spring water

**3. Handicrafts/Manufactured (Class 1-45):**
- Textiles
- Pottery
- Jewelry

## Inspection Body

**Mandatory Requirement:**
- Organization to monitor quality
- Ensure compliance
- Certify authenticity

**Examples:**
- Tea Board (Darjeeling Tea)
- Spices Board (Kerala spices)
- State government agencies

## Authorized Users

After registration, **producers** must apply to become "Authorized Users" to use GI tag.

**Process:**
- Apply with proof of location
- Demonstrate compliance
- Get registered
- Use GI logo
''',
    quiz: [
      {'question': 'GI opposition period?', 'options': ['1 month', '3 months', '6 months', '12 months'], 'correctAnswer': 1, 'explanation': 'Opposition period is 3 months after publication.'},
      {'question': 'Application fee for GI?', 'options': ['₹1,000', '₹5,000', '₹10,000', '₹50,000'], 'correctAnswer': 1, 'explanation': 'GI application fee is ₹5,000.'},
      {'question': 'Is inspection body mandatory?', 'options': ['No', 'Yes', 'Optional', 'Only for food'], 'correctAnswer': 1, 'explanation': 'Inspection body is mandatory for quality monitoring.'},
      {'question': 'Who can apply for GI?', 'options': ['Any individual', 'Only government', 'Association of producers', 'Foreign companies'], 'correctAnswer': 2, 'explanation': 'Association of producers or authorized groups can apply.'},
      {'question': 'After registration, producers must?', 'options': ['Do nothing', 'Become Authorized Users', 'Pay royalty', 'Change location'], 'correctAnswer': 1, 'explanation': 'Producers must register as Authorized Users to use GI tag.'},
    ],
  ),
  LevelModel(
    id: 'gi_3',
    realmId: 'geographical_indication',
    levelNumber: 3,
    title: 'Famous Indian GI Cases',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Landmark GI Cases from India

## 1. Darjeeling Tea (2004-ongoing)

**First Indian GI registered**

**Background:**
- World-famous tea from West Bengal hills
- Unique flavor due to altitude, climate
- Widely counterfeited globally

**GI Registration:** 2004

**Challenges:**
- Fake "Darjeeling Tea" sold worldwide
- Tea Board estimates 40 million kg sold vs. 10 million kg produced!

**Enforcement:**
- Tea Board actively monitors
- Legal action in EU, USA
- Success: Protected in 70+ countries

## 2. Basmati Rice Dispute

**Background:**
- India & Pakistan both claim Basmati
- Grown in Punjab, Haryana (India) & Punjab (Pakistan)

**India GI:** 2008 (Basmati rice from specific Indian regions)

**RiceTec Case (USA, 2001):**
- US company patented "Basmati" rice lines
- India protested biopiracy
- RiceTec withdrew most claims
- India won moral victory

**Outcome:** GI helps establish India's claim

## 3. Alphonso Mango

**GI:** 2007

**Unique Features:**
- Grown in Konkan region (Maharashtra)
- Distinct taste, aroma, texture
- "King of Mangoes"

**Economic Impact:**
- Premium pricing (₹500+/kg export)
- Major export to Gulf, EU
- GI prevents "Alphonso" use elsewhere

## 4. Kanchipuram Silk

**GI:** 2005

**Characteristics:**
- Handwoven silk from Kanchipuram, Tamil Nadu
- Heavy, durable
- Unique temple borders, contrasting colors
- 400+ year tradition

**Counterfeiting Problem:**
- Power loom imitations
- Non-Kanchipuram sellers using name

**Post-GI Impact:**
- Weavers' cooperatives formed
- Quality certification
- Price premium

## 5. Chanderi Saree

**GI:** 2005

**Origin:** Chanderi, Madhya Pradesh

**Features:**
- Lightweight, sheer texture
- Hand-woven
- Gold/silver zari work

**Success Story:**
- Weavers organized
- Government support
- Export growth
- Fair pricing

## 6. Mysore Silk

**GI:** 2005

**Origin:** Karnataka

**Uniqueness:**
- Pure mulberry silk
- Traditional dyeing methods
- Softness and luster

**Protection:**
- Karnataka Silk Industries Corporation monitors
- Prevents imitation
- Maintains quality

## 7. Pochampally Ikat

**GI:** 2004

**Origin:** Telangana

**Technique:**
- Resist-dyeing before weaving
- Geometric patterns
- Vibrant colors

**Impact:**
- Weavers' income increased
- Recognition as "Silk City of India"
- Tourism boost

## Common Themes

**Success Factors:**
✓ Strong producer associations
✓ Government support
✓ Quality control mechanisms
✓ Marketing & awareness
✓ Legal enforcement

**Challenges:**
❌ Counterfeiting
❌ Lack of awareness
❌ International protection gaps
❌ Enforcement costs
''',
    quiz: [
      {'question': 'First Indian GI registered?', 'options': ['Basmati Rice', 'Darjeeling Tea', 'Alphonso Mango', 'Mysore Silk'], 'correctAnswer': 1, 'explanation': 'Darjeeling Tea was first registered in 2004.'},
      {'question': 'Alphonso Mango GI year?', 'options': ['2004', '2005', '2007', '2010'], 'correctAnswer': 2, 'explanation': 'Alphonso Mango got GI in 2007.'},
      {'question': 'RiceTec case was about?', 'options': ['Trademark', 'Basmati rice biopiracy', 'Patent infringement', 'Copyright'], 'correctAnswer': 1, 'explanation': 'RiceTec attempted to patent Basmati rice lines.'},
      {'question': 'Kanchipuram is famous for?', 'options': ['Tea', 'Silk sarees', 'Mangoes', 'Rice'], 'correctAnswer': 1, 'explanation': 'Kanchipuram is famous for handwoven silk sarees.'},
      {'question': 'Main challenge for GI products?', 'options': ['High quality', 'Counterfeiting', 'Expensive', 'Limited production'], 'correctAnswer': 1, 'explanation': 'Counterfeiting and unauthorized use is the major challenge.'},
    ],
  ),
  LevelModel(
    id: 'gi_4',
    realmId: 'geographical_indication',
    levelNumber: 4,
    title: 'International GI Protection',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Global GI Systems & Agreements

## TRIPS Agreement

**What is TRIPS?**
- Trade-Related Aspects of Intellectual Property Rights
- WTO agreement (1995)
- Includes GI protection

**Article 22:** Minimum protection for all GIs
**Article 23:** Enhanced protection for wines & spirits

**India's Compliance:**
GI Act, 1999 aligned with TRIPS

## Lisbon Agreement

**What:**
International system for registering appellations of origin

**Managed by:** WIPO

**Coverage:** 30 countries (mostly European)

**India Status:** NOT a member

**How It Works:**
- Register in home country
- Automatic protection in all member countries
- No need for separate applications

**Example:**
- Roquefort Cheese (France)
- Tequila (Mexico)
- Protected in all Lisbon countries

## Bilateral Agreements

**India has GI protection agreements with:**

**1. India-EU Agreement (2007):**
- Mutual recognition
- Darjeeling Tea protected in EU
- Champagne, Cognac protected in India

**2. India-UK MoU:**
- Post-Brexit cooperation
- Continued GI protection

**India's Protected Foreign GIs:**
- Champagne (France)
- Scotch Whisky (UK)
- Bordeaux Wine (France)
- Cognac (France)

## Madrid System (Trademarks)

**Can GI be trademarked?**

**Generally NO, but:**
- Some countries allow certification marks
- Example: "Champagne" as certification mark in USA

**India's Approach:**
- Separate GI system (not trademark)
- Prevents monopolization

## Protection Strategies

**For Indian GIs Abroad:**

**Option 1:** Register in each country separately
- Expensive but effective
- Example: Darjeeling Tea in 70+ countries

**Option 2:** Use bilateral agreements
- Limited to treaty countries
- Cheaper

**Option 3:** Use trademark/certification mark
- In countries without GI laws
- Example: USA recognizes GI via certification marks

## Enforcement Challenges

**Counterfeiting:**
- "Darjeeling" tea from other regions
- Fake "Basmati" rice
- Imitation "Kanchipuram" sarees

**Solutions:**
- Customs enforcement
- Online monitoring
- Legal action in key markets
- Consumer awareness

## Notable International GIs

**Europe:**
- Champagne (France)
- Parmigiano-Reggiano (Italy)
- Roquefort (France)
- Cognac (France)

**Asia:**
- Pu-erh Tea (China)
- Japanese Sake
- Ceylon Tea (Sri Lanka)

**Americas:**
- Tequila (Mexico)
- Florida Oranges (USA)
- Havana Cigars (Cuba)

## Economic Impact

**Benefits of GI Protection:**

✓ **Premium Pricing:** 20-50% higher prices
✓ **Export Growth:** Access to quality-conscious markets
✓ **Rural Development:** Income for local communities
✓ **Cultural Preservation:** Traditional crafts sustained
✓ **Brand Reputation:** Quality assurance

**Statistics:**
- India has **400+ registered GIs**
- Estimated value: ₹50,000+ crores annually
- Employment: 5 million+ people

## Future Trends

**Expansion:**
- More products seeking GI
- Digital products (?)
- Services (culinary tourism)

**Technology:**
- Blockchain for authenticity verification
- QR codes for tracing
- DNA testing for agricultural products
''',
    quiz: [
      {'question': 'Which WTO agreement covers GI?', 'options': ['GATT', 'TRIPS', 'GATS', 'TBT'], 'correctAnswer': 1, 'explanation': 'TRIPS Agreement includes GI protection provisions.'},
      {'question': 'Lisbon Agreement is managed by?', 'options': ['WTO', 'WIPO', 'UN', 'EU'], 'correctAnswer': 1, 'explanation': 'WIPO manages the Lisbon Agreement for appellations.'},
      {'question': 'Is India a Lisbon member?', 'options': ['Yes', 'No', 'Observer', 'Partial'], 'correctAnswer': 1, 'explanation': 'India is not a member of the Lisbon Agreement.'},
      {'question': 'How many GIs registered in India?', 'options': ['50+', '100+', '400+', '1000+'], 'correctAnswer': 2, 'explanation': 'India has 400+ registered GIs.'},
      {'question': 'GI protection benefit?', 'options': ['Tax exemption', 'Premium pricing', 'Free export', 'Government subsidy'], 'correctAnswer': 1, 'explanation': 'GI products command 20-50% premium pricing.'},
    ],
  ),
  LevelModel(
    id: 'gi_5',
    realmId: 'geographical_indication',
    levelNumber: 5,
    title: 'GI & Traditional Knowledge',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Protecting Traditional Knowledge through GI

## What is Traditional Knowledge (TK)?

**Definition:**
Knowledge, innovations, and practices of indigenous and local communities developed over generations.

**Examples:**
- Ayurvedic formulations
- Tribal handicrafts
- Traditional agricultural practices
- Folk art forms

## GI as TK Protection Tool

**Why GI for TK?**

✓ **Prevents Biopiracy:** Stops foreign patents on Indian TK
✓ **Community Rights:** Belongs to region, not individuals
✓ **Livelihood Protection:** Sustains traditional artisans
✓ **Cultural Preservation:** Keeps heritage alive

## Case Studies

### 1. Turmeric Case (1995)

**Problem:**
- US Patent 5,401,504 granted for turmeric's healing properties
- Used in India for centuries (Ayurveda)

**Action:**
- CSIR challenged patent using ancient texts
- Proved prior art (Ayurveda, Siddha literature)

**Outcome:**
- Patent revoked (1997)
- Biopiracy prevented

**Lesson:** GI + TK documentation prevents exploitation

### 2. Neem Case (2000)

**Problem:**
- European Patent on neem extract as fungicide
- Neem used in India for millennia

**Action:**
- India + Green groups challenged
- Cited traditional knowledge

**Outcome:**
- Patent revoked by EPO (2005)
- Victory for TK protection

### 3. Basmati Case (2001)

**Problem:**
- RiceTec (USA) patented Basmati rice lines

**Action:**
- India cited traditional cultivation
- GI helped establish Indian claim

**Outcome:**
- RiceTec withdrew key claims
- Basmati GI strengthened

## Traditional Knowledge Digital Library (TKDL)

**What:**
- Database of Indian traditional knowledge
- Covers Ayurveda, Unani, Siddha, Yoga

**Purpose:**
- Prevent biopiracy
- Provide prior art evidence

**Access:**
- Patent offices worldwide (9 major offices)
- Search before granting patents

**Impact:**
- 200+ patent applications rejected/withdrawn
- Saved billions in legal costs

## GI for Traditional Crafts

**Protected Crafts:**

**Textiles:**
- Chanderi Saree
- Pochampally Ikat
- Kashmiri Pashmina
- Kota Doria

**Handicrafts:**
- Channapatna Toys
- Moradabad Metal Craft
- Nirmal Paintings
- Thanjavur Art Plate

**Impact:**
- Artisan income ↑
- Craft preservation
- Market access

## Indigenous Communities & GI

**Tribal GIs:**
- Aranmula Kannadi (Kerala - tribal mirror)
- Toda Embroidery (Tamil Nadu)
- Warli Painting (Maharashtra)

**Benefits:**
- Community ownership
- Fair trade opportunities
- Cultural pride
- Economic empowerment

## Challenges

**Documentation:**
- Oral traditions hard to prove
- Lack of written records
- Need systematic documentation

**Enforcement:**
- Costly legal battles
- International jurisdiction issues
- Awareness gaps

**Modernization vs. Tradition:**
- Balancing innovation with authenticity
- Adapting to market demands

## Best Practices

**For TK Protection:**

✓ **Document:** Create comprehensive records
✓ **Register:** Obtain GI protection
✓ **Organize:** Form producer associations
✓ **Educate:** Raise consumer awareness
✓ **Monitor:** Track unauthorized use
✓ **Enforce:** Take legal action promptly

## International Frameworks

**WIPO IGC:**
- Intergovernmental Committee on IP, GR, TK, and Folklore
- Working on international TK protection

**Nagoya Protocol:**
- Access and benefit-sharing for genetic resources
- India is a party

**CBD (Convention on Biological Diversity):**
- Recognizes community rights over resources

## Success Stories

**1. Araku Coffee (Andhra Pradesh):**
- Tribal cooperative
- GI registration (2019)
- Premium global sales
- Poverty alleviation

**2. Kashmiri Pashmina:**
- Traditional craft
- GI (2008)
- Prevents fake products
- Artisan livelihoods protected
''',
    quiz: [
      {'question': 'What is TKDL?', 'options': ['Trademark Library', 'Traditional Knowledge Digital Library', 'Technology Database', 'Trade License'], 'correctAnswer': 1, 'explanation': 'TKDL is Traditional Knowledge Digital Library to prevent biopiracy.'},
      {'question': 'Turmeric patent was from?', 'options': ['India', 'USA', 'UK', 'China'], 'correctAnswer': 1, 'explanation': 'US Patent 5,401,504 on turmeric was later revoked.'},
      {'question': 'TKDL prevents?', 'options': ['Copying', 'Biopiracy', 'Competition', 'Exports'], 'correctAnswer': 1, 'explanation': 'TKDL provides prior art to prevent biopiracy and wrongful patents.'},
      {'question': 'Who benefits from tribal GIs?', 'options': ['Government', 'Companies', 'Indigenous communities', 'Foreign investors'], 'correctAnswer': 2, 'explanation': 'Tribal GIs benefit and empower indigenous communities.'},
      {'question': 'Neem patent was revoked by?', 'options': ['Indian court', 'USPTO', 'EPO', 'WIPO'], 'correctAnswer': 2, 'explanation': 'European Patent Office (EPO) revoked the neem patent.'},
    ],
  ),
  LevelModel(
    id: 'gi_6',
    realmId: 'geographical_indication',
    levelNumber: 6,
    title: 'GI Marketing & Future Trends',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Leveraging GI for Economic Growth

## Marketing GI Products

**Value Proposition:**
- **Authenticity:** Genuine origin
- **Quality:** Region-specific excellence
- **Heritage:** Cultural storytelling
- **Sustainability:** Traditional methods

**Target Markets:**
- Premium domestic buyers
- Export (EU, USA, Japan)
- Tourism sector
- E-commerce platforms

## Branding Strategies

**1. GI Logo Prominence:**
- Display on packaging
- Certify authenticity
- Build trust

**2. Storytelling:**
- Highlight artisan stories
- Cultural heritage
- Sustainable practices

**3. Digital Marketing:**
- Social media campaigns
- Influencer partnerships
- E-commerce listings

**Example: Darjeeling Tea**
- "Champagne of Teas" positioning
- Premium pricing (₹500-5000/100g)
- Global recognition

## E-Commerce & GI

**Opportunities:**
- Direct farmer-to-consumer
- Wider market access
- Traceability via QR codes

**Challenges:**
- Counterfeits on platforms
- Authentication difficulty
- Logistics for perishables

**Solutions:**
- Platform partnerships (Amazon, Flipkart GI sections)
- Blockchain for tracing
- Government GI portals

## Tourism & GI

**Agro/Craft Tourism:**

**Darjeeling:**
- Tea garden tours
- GI as attraction
- Revenue ↑ for region

**Moradabad:**
- Metal craft workshops
- Live demonstrations
- Export sales

**Kangra:**
- Painting tours
- Cultural immersion
- Artisan interaction

## Technology Integration

**1. Blockchain:**
- Track product journey
- Prevent counterfeiting
- Example: Kerala spices using blockchain

**2. QR Codes:**
- Scan for authenticity
- Producer info
- Care instructions

**3. AI Monitoring:**
- Detect fakes online
- Automated enforcement

**4. DNA Tagging:**
- For agricultural products
- Basmati rice DNA testing
- Irrefutable proof of origin

## Government Initiatives

**Schemes:**

**1. One District One Product (ODOP):**
- Promote district-specific GIs
- Financial support
- Market linkage

**2. GI Tag Support:**
- Subsidized registration
- Legal aid
- Marketing assistance

**3. Export Promotion:**
- GI pavilions at trade fairs
- Country branding
- Trade delegations

**Impact:**
- 50+ products supported annually
- Export growth 15-20%

## Future Trends

### 1. New Product Categories

**Services:**
- Can cuisine be GI? (UNESCO intangible heritage route)
- Tourism experiences?

**Digital Products:**
- Traditional music/art in NFT form?

### 2. Climate Change Adaptation

**Challenge:**
- Geographic shifts due to climate
- Quality changes

**Solution:**
- Adaptive boundaries
- Scientific monitoring

### 3. Sustainability Certification

**Combination:**
- GI + Organic certification
- GI + Fair trade
- Triple benefit: quality + ethics + sustainability

### 4. Blockchain Ecosystems

**Vision:**
- Farm to fork traceability
- Consumer trust
- Premium pricing

### 5. Cross-Border GIs

**Example:**
- Basmati (India + Pakistan)
- Himalayan products (India, Nepal, Bhutan)

**Approach:**
- Joint applications
- Shared benefits

## Economic Impact Analysis

**Case: Kanchipuram Silk**

**Pre-GI (2004):**
- Weavers: 3,000 families
- Avg income: ₹5,000/month
- Counterfeiting: 60%

**Post-GI (2020):**
- Weavers: 5,000+ families
- Avg income: ₹15,000/month
- Counterfeiting: 30%
- Export: 3x growth

**ROI:** 300%+ for community

## Global Best Practices

**Champagne (France):**
- Strictest protection
- Global enforcement
- Billion-euro industry

**Tequila (Mexico):**
- Denomination of origin
- $3 billion+ exports
- Quality control

**Lessons for India:**
- Aggressive enforcement
- Quality consistency
- Brand building

## Challenges Ahead

**1. Awareness:**
- 70% Indians unaware of GI concept
- Need education campaigns

**2. Quality Consistency:**
- Variability in products
- Need stricter monitoring

**3. Counterfeiting:**
- Online fakes proliferating
- Enforcement difficult

**4. Producer Organization:**
- Weak cooperatives
- Need capacity building

**5. International Protection:**
- Expensive to register abroad
- Need government support

## Action Plan for Stakeholders

**For Producers:**
- Form strong associations
- Maintain quality standards
- Embrace technology
- Market aggressively

**For Government:**
- Simplify registration
- Fund international protection
- Create GI e-marketplaces
- Enforce strictly

**For Consumers:**
- Demand authentic GI products
- Pay fair premium
- Support local artisans
''',
    quiz: [
      {'question': 'GI + Blockchain helps with?', 'options': ['Faster production', 'Traceability & authenticity', 'Lower costs', 'Free shipping'], 'correctAnswer': 1, 'explanation': 'Blockchain enables product tracing and prevents counterfeiting.'},
      {'question': 'ODOP stands for?', 'options': ['One Day One Product', 'One District One Product', 'Online Digital Platform', 'Origin Display Option'], 'correctAnswer': 1, 'explanation': 'ODOP is One District One Product scheme.'},
      {'question': 'What can GI be combined with?', 'options': ['Nothing', 'Organic/Fair trade certifications', 'Patents', 'Trademarks only'], 'correctAnswer': 1, 'explanation': 'GI can be combined with organic, fair trade for triple benefit.'},
      {'question': 'GI tourism example?', 'options': ['Regular tours', 'Tea garden visits in Darjeeling', 'City sightseeing', 'Beach holidays'], 'correctAnswer': 1, 'explanation': 'Darjeeling tea gardens offer GI-linked agro-tourism.'},
      {'question': 'Main challenge for GI products?', 'options': ['High quality', 'Counterfeiting', 'Too expensive', 'Overproduction'], 'correctAnswer': 1, 'explanation': 'Counterfeiting remains the biggest challenge for GI products.'},
    ],
  ),
];

