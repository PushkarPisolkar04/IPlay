import '../models/level_model.dart';

final List<LevelModel> patentLevelsData = [
  LevelModel(
    id: 'patent_1',
    realmId: 'patent',
    levelNumber: 1,
    title: 'Introduction to Patents',
    difficulty: 'Easy',
    xp: 50,
    content: '''
# What is a Patent?

A **patent** is an exclusive right granted for an invention - a product or process that provides a new way of doing something or offers a new technical solution to a problem.

## Key Features

- **Territorial**: Valid only in the country granted
- **Time-Limited**: 20 years from filing date
- **Exclusive Rights**: Owner can prevent others from making, using, selling
- **Disclosure**: Full invention details must be public

## Types of Patents in India

1. **Utility Patents**: Most common (machines, processes, compositions)
2. **Design Patents**: Ornamental design (covered under Designs Act separately)
3. **Plant Patents**: Not recognized in India

## Why Patents Matter

✓ Encourage innovation
✓ Reward inventors
✓ Knowledge sharing (disclosure requirement)
✓ Economic growth

## Indian Law
Governed by the **Patents Act, 1970** (amended 2005).

## Famous Indian Patents
- **Turmeric Patent** (revoked 1997 - biopiracy case)
- **Neem Patent** (revoked 2000 - traditional knowledge)
''',
    quiz: [
      {'question': 'Patent validity in India?', 'options': ['10 years', '15 years', '20 years', 'Lifetime'], 'correctAnswer': 2, 'explanation': 'Patents are valid for 20 years from filing date.'},
      {'question': 'Which Act governs patents in India?', 'options': ['Patents Act, 1970', 'Patents Act, 1999', 'IP Act, 2000', 'Innovation Act'], 'correctAnswer': 0, 'explanation': 'Patents Act, 1970 (amended 2005) governs patents.'},
      {'question': 'What must a patent owner disclose?', 'options': ['Nothing', 'Full invention details', 'Only name', 'Only price'], 'correctAnswer': 1, 'explanation': 'Full disclosure is mandatory for public knowledge.'},
      {'question': 'Are plant patents recognized in India?', 'options': ['Yes', 'No', 'Sometimes', 'Only for trees'], 'correctAnswer': 1, 'explanation': 'Plant patents are not recognized under Indian law.'},
      {'question': 'Patent rights are?', 'options': ['Global', 'Territorial', 'Universal', 'Optional'], 'correctAnswer': 1, 'explanation': 'Patents are territorial and valid only in granting country.'},
    ],
  ),
  LevelModel(
    id: 'patent_2',
    realmId: 'patent',
    levelNumber: 2,
    title: 'Patentability Criteria',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# What Can Be Patented?

## Three Essential Criteria

### 1. **Novelty** (New)
- Must be NEW worldwide
- Not disclosed anywhere before
- Not in prior art (existing knowledge)

### 2. **Inventive Step** (Non-Obvious)
- Not obvious to a person skilled in the art
- Requires technical advancement
- More than simple modification

### 3. **Industrial Application** (Useful)
- Can be made or used in industry
- Practical utility required
- Must work as claimed

## What CANNOT Be Patented in India

**Section 3 Exclusions:**

❌ Frivolous inventions
❌ Mathematical methods
❌ Business methods
❌ Computer programs per se
❌ Algorithms
❌ Diagnostic methods
❌ Treatments for humans/animals
❌ Plants & animals (except microorganisms)
❌ Traditional knowledge
❌ Inventions against public order/morality

## Examples

**Patentable:**
✓ New pharmaceutical composition
✓ Improved engine design
✓ Novel manufacturing process

**Not Patentable:**
✗ E = mc² (mathematical formula)
✗ Method of teaching (mental activity)
✗ Ayurvedic formulation (traditional knowledge)

## Case Study: Section 3(d)

**Novartis vs. Union of India (2013)**
- Novartis sought patent for Glivec (cancer drug)
- Supreme Court rejected: mere modification, not inventive
- Prevented evergreening of patents
''',
    quiz: [
      {'question': 'How many criteria for patentability?', 'options': ['2', '3', '4', '5'], 'correctAnswer': 1, 'explanation': 'Three criteria: Novelty, Inventive Step, Industrial Application.'},
      {'question': 'Can software be patented in India?', 'options': ['Yes always', 'No, computer programs per se excluded', 'Sometimes', 'Only apps'], 'correctAnswer': 1, 'explanation': 'Computer programs per se are excluded under Section 3.'},
      {'question': 'What is novelty?', 'options': ['New in India', 'New worldwide', 'New in Asia', 'New in town'], 'correctAnswer': 1, 'explanation': 'Novelty requires worldwide newness, not disclosed anywhere.'},
      {'question': 'Can traditional knowledge be patented?', 'options': ['Yes', 'No', 'Only if modified', 'Only in India'], 'correctAnswer': 1, 'explanation': 'Traditional knowledge is explicitly excluded.'},
      {'question': 'Novartis case was about?', 'options': ['New drug', 'Evergreening prevention', 'Copyright', 'Trademark'], 'correctAnswer': 1, 'explanation': 'Novartis case prevented evergreening by rejecting minor modifications.'},
    ],
  ),
  LevelModel(
    id: 'patent_3',
    realmId: 'patent',
    levelNumber: 3,
    title: 'Patent Application Process',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Filing a Patent in India

## Step-by-Step Process

### 1. **Provisional Application** (Optional)
- File preliminary details
- Establishes priority date
- 12 months to file complete specification

### 2. **Complete Specification**
- Detailed invention description
- Claims defining scope
- Drawings if required
- Abstract (150 words max)

### 3. **Publication** (18 months)
- Application published in Patent Journal
- Can request early publication

### 4. **Request for Examination** (RFE)
- Must be filed within **48 months**
- Fee: ₹4,000 (individual), ₹16,000 (others)

### 5. **Examination Report**
- Controller examines for patentability
- Issues objections if any
- 6 months to respond

### 6. **Grant**
- If no objections or resolved
- Patent certificate issued
- Valid for 20 years

## Forms Required

- **Form 1**: Application
- **Form 2**: Specification
- **Form 3**: Declaration (for foreign applications)
- **Form 5**: Power of Attorney
- **Form 9**: Statement of inventorship

## Fees (Individual/Startup)

| Action | Fee |
|--------|-----|
| Filing | ₹1,600 |
| Examination | ₹4,000 |
| Grant | ₹2,400 |
| Renewal (yearly after 3 years) | ₹800 - ₹8,000 |

## Timeline
**Total: 3-5 years** for grant

## Fast Track
**Startups & Small Entities**: 80% fee discount + expedited examination
''',
    quiz: [
      {'question': 'When must RFE be filed?', 'options': ['12 months', '18 months', '48 months', '60 months'], 'correctAnswer': 2, 'explanation': 'Request for Examination must be within 48 months.'},
      {'question': 'Provisional application validity?', 'options': ['6 months', '12 months', '18 months', '24 months'], 'correctAnswer': 1, 'explanation': 'Provisional application is valid for 12 months.'},
      {'question': 'When is application published?', 'options': ['Immediately', '6 months', '18 months', '24 months'], 'correctAnswer': 2, 'explanation': 'Applications are published after 18 months.'},
      {'question': 'Startup fee discount?', 'options': ['50%', '60%', '80%', '100%'], 'correctAnswer': 2, 'explanation': 'Startups get 80% fee discount.'},
      {'question': 'Form for specification?', 'options': ['Form 1', 'Form 2', 'Form 3', 'Form 5'], 'correctAnswer': 1, 'explanation': 'Form 2 is for complete specification.'},
    ],
  ),
  LevelModel(
    id: 'patent_4',
    realmId: 'patent',
    levelNumber: 4,
    title: 'Claims & Specifications',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Writing Patent Claims

## What are Claims?

Claims define the **legal scope** of patent protection. They determine what is protected and what is not.

## Structure of Specification

1. **Title**: Clear, concise invention title
2. **Field of Invention**: Technical domain
3. **Background**: Prior art, problem solved
4. **Summary**: Brief overview
5. **Detailed Description**: How it works
6. **Claims**: Legal boundaries
7. **Drawings**: Visual representation
8. **Abstract**: 150-word summary

## Types of Claims

### 1. Independent Claims
- Stand-alone, complete invention
- Broader scope
- Must include all essential features

**Example:**
"A device for purifying water comprising: a filter, a UV chamber, and an outlet."

### 2. Dependent Claims
- Refer to independent claim
- Add specific features
- Narrower scope

**Example:**
"The device of claim 1, wherein the filter is made of activated carbon."

## Claim Drafting Principles

**Broad vs. Narrow:**
- Broad = More protection but easier to invalidate
- Narrow = Stronger but limited protection
- Strategy: Multiple claims of varying scope

**Clear Language:**
- Avoid ambiguity
- Use technical terms correctly
- "Comprising" (open-ended) vs. "Consisting of" (closed)

## Example: Smartphone Camera

**Broad Claim:**
"A mobile device with image capture means."

**Narrow Claim:**
"A smartphone with a 48MP rear camera, optical image stabilization, f/1.8 aperture, and AI scene detection."

## Common Mistakes

❌ Too vague or broad
❌ Describing result, not means
❌ Ambiguous terms
❌ Inconsistent with description
''',
    quiz: [
      {'question': 'What defines patent scope?', 'options': ['Title', 'Abstract', 'Claims', 'Drawings'], 'correctAnswer': 2, 'explanation': 'Claims define the legal scope of protection.'},
      {'question': 'Abstract word limit?', 'options': ['100', '150', '200', '250'], 'correctAnswer': 1, 'explanation': 'Abstract must be maximum 150 words.'},
      {'question': 'Dependent claims refer to?', 'options': ['Nothing', 'Independent claims', 'Abstract', 'Title'], 'correctAnswer': 1, 'explanation': 'Dependent claims refer to independent claims and add features.'},
      {'question': '"Comprising" means?', 'options': ['Closed list', 'Open-ended', 'Optional', 'Forbidden'], 'correctAnswer': 1, 'explanation': 'Comprising is open-ended, allows additional elements.'},
      {'question': 'Broader claims are?', 'options': ['Stronger', 'Weaker', 'More protection but easier to invalidate', 'Always better'], 'correctAnswer': 2, 'explanation': 'Broad claims give more protection but are easier to challenge.'},
    ],
  ),
  LevelModel(
    id: 'patent_5',
    realmId: 'patent',
    levelNumber: 5,
    title: 'Patent Infringement & Enforcement',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Patent Infringement in India

## What is Infringement?

Unauthorized making, using, selling, or importing patented invention **without permission**.

## Types of Infringement

### 1. **Direct Infringement**
- Exact copy of patented invention
- All claim elements present

### 2. **Indirect Infringement** (Contributory)
- Supplying components for infringing product
- Knowing it will be used for infringement

### 3. **Doctrine of Equivalents**
- Product performs same function
- In substantially same way
- With same result

## Remedies

**Civil:**
- **Injunction**: Stop production/sale
- **Damages**: Monetary compensation
- **Account of Profits**: Defendant's profits given to plaintiff
- **Seizure**: Infringing goods confiscated

**Criminal:**
Not available for patent infringement in India (unlike copyright/trademark)

## Defenses Against Infringement

1. **Prior Use**: Used before patent filing
2. **Experimentation**: Research purposes
3. **Government Use**: Section 100 allows govt use
4. **Invalidity**: Challenge patent validity
5. **Exhaustion**: First sale doctrine

## Compulsory Licensing

**Section 84**: Government can grant license to others if:
- Patent not worked in India
- Public demand not met at reasonable price
- Patent not available to public

**Famous Case:**
**Natco vs. Bayer (2012)**
- First compulsory license in India
- Cancer drug Nexavar
- Bayer charged ₹2.8 lakhs/month
- Natco allowed to sell at ₹9,000/month

## Bolar Provision (Section 107A)

Allows generic companies to test patented drugs **before** patent expiry for regulatory approval.

**Purpose**: Generic availability immediately after patent expiry
''',
    quiz: [
      {'question': 'Is criminal remedy available for patents?', 'options': ['Yes', 'No', 'Sometimes', 'Only for pharmaceuticals'], 'correctAnswer': 1, 'explanation': 'Criminal remedies are not available for patent infringement in India.'},
      {'question': 'First compulsory license case?', 'options': ['Tata vs Reliance', 'Natco vs Bayer', 'Cipla vs Pfizer', 'Dr. Reddy vs Novartis'], 'correctAnswer': 1, 'explanation': 'Natco vs Bayer (2012) was the first compulsory license.'},
      {'question': 'Section for compulsory licensing?', 'options': ['Section 3', 'Section 84', 'Section 100', 'Section 107'], 'correctAnswer': 1, 'explanation': 'Section 84 deals with compulsory licensing.'},
      {'question': 'Bolar provision allows?', 'options': ['Free use', 'Testing before expiry', 'Stealing patents', 'Price control'], 'correctAnswer': 1, 'explanation': 'Bolar provision allows testing before patent expiry.'},
      {'question': 'First sale doctrine is called?', 'options': ['Prior use', 'Exhaustion', 'Equivalents', 'Compulsory'], 'correctAnswer': 1, 'explanation': 'First sale doctrine is also called exhaustion of rights.'},
    ],
  ),
  LevelModel(
    id: 'patent_6',
    realmId: 'patent',
    levelNumber: 6,
    title: 'International Patent Filing',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Patent Cooperation Treaty (PCT)

## What is PCT?

International system to file **single application** for patent protection in **156 countries**.

**India Status**: Member since 1998

## How PCT Works

### Phase 1: International Phase

1. **File PCT Application**: With WIPO or national office
2. **International Search**: Search report on prior art
3. **Publication**: 18 months from priority date
4. **Optional**: International Preliminary Examination

**Timeline**: Up to 30 months

### Phase 2: National Phase

- Enter specific countries
- Pay national fees
- Each country examines independently
- Grant or reject per national laws

**Deadline**: Usually 30-31 months from priority date

## Benefits

✓ **Single Application**: One filing, multiple countries
✓ **Time Advantage**: 30 months to decide countries
✓ **Cost Savings**: Delay national fees
✓ **Search Report**: Assess patentability early
✓ **Amendments**: Improve application before national phase

## Costs

**International Fees:**
- Filing: ~₹1 lakh
- Search: ~₹1.5 lakhs
- Per country (national phase): ₹2-5 lakhs each

**Example**: Protecting in USA, EU, Japan, China
- Direct filing: ₹30+ lakhs upfront
- PCT route: ₹2.5 lakhs initially, ₹25 lakhs later (30 months)

## Paris Convention Alternative

- File in home country first
- **12 months** to file abroad
- Claim priority date
- Cheaper for few countries

## Strategy

**PCT if:**
- Targeting 3+ countries
- Need time to assess commercial viability
- Want early search report

**Paris if:**
- 1-2 countries only
- Faster grant needed
- Lower initial investment

## Patent Prosecution Highway (PPH)

Fast-track examination if allowed in one country.

**India-Japan PPH**: Since 2019
**India-US PPH**: Under discussion
''',
    quiz: [
      {'question': 'How many countries in PCT?', 'options': ['50', '100', '156', '195'], 'correctAnswer': 2, 'explanation': 'PCT covers 156 countries.'},
      {'question': 'National phase deadline?', 'options': ['12 months', '18 months', '30 months', '36 months'], 'correctAnswer': 2, 'explanation': 'National phase entry is typically at 30-31 months.'},
      {'question': 'Who manages PCT?', 'options': ['UN', 'WIPO', 'WTO', 'IPO'], 'correctAnswer': 1, 'explanation': 'WIPO manages the PCT system.'},
      {'question': 'Paris Convention priority period?', 'options': ['6 months', '12 months', '18 months', '24 months'], 'correctAnswer': 1, 'explanation': 'Paris Convention allows 12 months for foreign filing.'},
      {'question': 'When did India join PCT?', 'options': ['1995', '1998', '2000', '2005'], 'correctAnswer': 1, 'explanation': 'India became a PCT member in 1998.'},
    ],
  ),
  LevelModel(
    id: 'patent_7',
    realmId: 'patent',
    levelNumber: 7,
    title: 'Pharmaceutical Patents & Mailbox',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Pharmaceutical Patents in India

## Historical Context

**Pre-2005:**
- **Process patents** only (not product)
- Companies could reverse-engineer drugs
- India became "pharmacy of the world"

**Post-2005 (TRIPS Compliance):**
- **Product patents** introduced
- 20-year protection
- But with safeguards

## Mailbox Provision

**Background:**
- Patents Act amended in 1995, 2005
- Applications filed 1995-2005 kept in "mailbox"
- Examined after 2005

**Exclusive Marketing Rights (EMR):**
- Temporary protection (5 years) until patent grant
- Given to mailbox applications

## Section 3(d) - The Game Changer

**Prevents Evergreening:**
- New form of known substance NOT patentable
- Unless significantly different efficacy
- Targets minor modifications

**Novartis vs. India (2013)**
- Glivec (cancer drug) - beta crystalline form
- Supreme Court: Not sufficiently inventive
- Saved India billions in healthcare

## Data Exclusivity

**NOT granted in India** (unlike US/EU)
- Generic companies can use clinical trial data
- Accelerates generic availability
- Reduces costs

## Bolar Exception (Section 107A)

Generics can test/prepare **before** patent expiry without infringement.

**Impact:**
- Generics ready on day 1 after expiry
- Immediate price drop
- Public health benefit

## Compulsory Licensing in Pharma

**Natco vs. Bayer (2012):**
- Nexavar (kidney cancer) - ₹2.8L/month
- CL granted: Natco sold at ₹9,000/month
- Conditions: 6% royalty to Bayer, supply obligations

## Recent Developments

**COVID-19 Patents:**
- Voluntary licenses granted widely
- Covax facility
- TRIPS waiver discussions

**Balancing Act:**
- Innovation incentive vs. public health
- India's unique model
''',
    quiz: [
      {'question': 'Before 2005, India allowed?', 'options': ['Product patents', 'Process patents', 'No patents', 'Both'], 'correctAnswer': 1, 'explanation': 'Before 2005, only process patents were allowed for pharma.'},
      {'question': 'What is Section 3(d)?', 'options': ['Compulsory license', 'Evergreening prevention', 'Data exclusivity', 'Bolar exception'], 'correctAnswer': 1, 'explanation': 'Section 3(d) prevents evergreening by rejecting minor modifications.'},
      {'question': 'Does India grant data exclusivity?', 'options': ['Yes', 'No', 'Only for NCEs', 'Only for biologics'], 'correctAnswer': 1, 'explanation': 'India does not grant data exclusivity, unlike US/EU.'},
      {'question': 'Bolar exception section?', 'options': ['Section 3(d)', 'Section 84', 'Section 107A', 'Section 100'], 'correctAnswer': 2, 'explanation': 'Section 107A is the Bolar exception.'},
      {'question': 'Nexavar CL royalty rate?', 'options': ['0%', '6%', '10%', '15%'], 'correctAnswer': 1, 'explanation': 'Natco was ordered to pay 6% royalty to Bayer.'},
    ],
  ),
  LevelModel(
    id: 'patent_8',
    realmId: 'patent',
    levelNumber: 8,
    title: 'Patent Analytics & Prior Art',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Patent Search & Analytics

## Why Search?

**Before Filing:**
- Check novelty
- Assess patentability
- Identify competitors
- Estimate costs

**During Examination:**
- Respond to objections
- Find supporting prior art

**For Business:**
- Freedom to operate (FTO)
- Competitor intelligence
- Technology trends

## Types of Searches

### 1. **Novelty Search**
- Is invention new?
- Search: Patents + non-patent literature

### 2. **Invalidity Search**
- Find prior art to invalidate patent
- Deeper than novelty search

### 3. **Freedom to Operate (FTO)**
- Can we make/sell without infringing?
- Search active patents in target country

### 4. **State of the Art**
- What exists in this field?
- Technology landscape

## Search Databases

**Free:**
- Google Patents
- Indian Patent Office (ipindia.gov.in)
- Espacenet (EPO)
- USPTO
- WIPO PatentScope

**Paid:**
- Derwent Innovation
- Orbit
- PatBase
- TotalPatent

## Search Strategy

**Keywords:**
- Invention terms + synonyms
- Technical jargon
- IPC/CPC classifications

**Classification Codes:**
- IPC: International Patent Classification
- CPC: Cooperative Patent Classification

**Example:** Electric vehicle battery
- IPC: H01M (batteries)
- CPC: Y02E 60/10 (electric vehicles)

## Prior Art

**Definition**: Everything publicly available **before** filing date.

**Sources:**
- Published patents
- Scientific journals
- Conference papers
- Websites, blogs
- Product manuals
- YouTube videos!

**Famous Case:**
**Bicycle Track Stand (2015)**
- Patent challenged using 1950s footage
- Video evidence = prior art
- Patent invalidated

## Patent Analytics

**Metrics:**
- Citation analysis (who cites whom?)
- Technology evolution
- Competitor portfolios
- White space identification

**Tools:**
- Patent landscapes
- Citation maps
- Timeline analysis
- Geographic distribution

## Practical Tips

✓ Search in English + local languages
✓ Go back 50+ years for basic tech
✓ Use multiple databases
✓ Check non-patent literature
✓ Document search thoroughly
''',
    quiz: [
      {'question': 'FTO search checks for?', 'options': ['Novelty', 'Active patents we might infringe', 'Expired patents', 'Trademarks'], 'correctAnswer': 1, 'explanation': 'FTO checks if we can operate without infringing active patents.'},
      {'question': 'What is IPC?', 'options': ['Indian Patent Code', 'International Patent Classification', 'Invention Process Code', 'IP Council'], 'correctAnswer': 1, 'explanation': 'IPC is International Patent Classification system.'},
      {'question': 'Prior art includes?', 'options': ['Only patents', 'Patents + non-patent literature', 'Only journals', 'Only Indian sources'], 'correctAnswer': 1, 'explanation': 'Prior art includes all publicly available information.'},
      {'question': 'Can YouTube videos be prior art?', 'options': ['No', 'Yes', 'Only for software', 'Only if patented'], 'correctAnswer': 1, 'explanation': 'Yes, public videos qualify as prior art if dated.'},
      {'question': 'Which is a free patent database?', 'options': ['Derwent', 'Orbit', 'Google Patents', 'TotalPatent'], 'correctAnswer': 2, 'explanation': 'Google Patents is a free patent search database.'},
    ],
  ),
  LevelModel(
    id: 'patent_9',
    realmId: 'patent',
    levelNumber: 9,
    title: 'Emerging Tech: AI, Biotech & Green Patents',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Patents in Cutting-Edge Technologies

## Artificial Intelligence & Machine Learning

**Challenges:**
- Algorithm patenting (Section 3(k) excludes computer programs per se)
- Must show technical contribution
- Hardware implementation often required

**Patentable:**
✓ AI-powered medical diagnostic device
✓ ML system for fraud detection (with hardware)
✓ Neural network chip design

**Not Patentable:**
✗ Standalone algorithm
✗ Software app with AI (per se)
✗ Business method using AI

**Case Example:**
**Microsoft India (2016)**
- AI-based speech recognition
- Granted: Had technical effect + hardware integration

## Biotechnology Patents

**Patentable in India:**
✓ Microorganisms
✓ Genetically modified organisms (GMOs)
✓ Isolated genes with industrial application
✓ Biotech processes

**Not Patentable:**
✗ Plants & animals in whole
✗ Seeds
✗ Diagnostic methods on humans
✗ Human genes in natural form

**Section 3(j):**
Plants/animals not inventions, BUT microorganisms are.

**Famous Case:**
**Monsanto vs. India (2019)**
- BT Cotton gene patent
- Supreme Court: Traits can't be patented under Patents Act
- But Seeds Act doesn't allow trait fees either

## Green Technology Patents

**Fast Track:** Green patents get expedited examination in many countries.

**India Green Patents:**
- Solar panel innovations
- Wind turbine designs
- Waste-to-energy
- Electric vehicle tech

**Government Push:**
- Renewable energy patents prioritized
- Startups encouraged
- PLI schemes

**Example:**
**IIT Delhi - Solar Cooling**
- Patent granted 2020
- Uses solar energy for AC
- Licensed to Indian company

## Blockchain Patents

**Challenges:**
- Often tied to business methods
- Must show technical advancement

**Patentable:**
✓ Blockchain-based security system (hardware)
✓ Consensus algorithm with technical effect

**Not Patentable:**
✗ Cryptocurrency per se
✗ Business model using blockchain

## Standard Essential Patents (SEPs)

Patents essential for industry standards (e.g., 4G, 5G).

**FRAND Obligation:**
- Fair
- Reasonable
- Non-Discriminatory licensing

**India's Stand:**
- FRAND royalties must be reasonable
- Not excessive

## Future Trends

**CRISPR Gene Editing:**
- Huge patent battles globally
- India watching closely

**Quantum Computing:**
- Early stage patenting
- Hardware + algorithms

**Space Tech:**
- Satellite innovations
- Launch vehicles
- ISRO patents growing
''',
    quiz: [
      {'question': 'Can pure software be patented in India?', 'options': ['Yes always', 'No, computer programs per se excluded', 'Only if open source', 'Only if paid'], 'correctAnswer': 1, 'explanation': 'Pure software is excluded; must have technical contribution.'},
      {'question': 'Are plant varieties patentable?', 'options': ['Yes', 'No', 'Only trees', 'Only GMOs'], 'correctAnswer': 1, 'explanation': 'Plants/animals are not patentable, but microorganisms are.'},
      {'question': 'What does FRAND mean?', 'options': ['Free and Random', 'Fair, Reasonable, Non-Discriminatory', 'France and Denmark', 'Federal Royalty Standard'], 'correctAnswer': 1, 'explanation': 'FRAND is Fair, Reasonable, Non-Discriminatory licensing.'},
      {'question': 'Green patents get?', 'options': ['No benefit', 'Expedited examination', 'Free filing', 'Automatic grant'], 'correctAnswer': 1, 'explanation': 'Green tech patents often get fast-track examination.'},
      {'question': 'Monsanto case was about?', 'options': ['Trademark', 'BT Cotton gene patent', 'Copyright', 'Design'], 'correctAnswer': 1, 'explanation': 'Monsanto case dealt with patentability of plant traits.'},
    ],
  ),
];

