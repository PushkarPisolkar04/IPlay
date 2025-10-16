import '../models/level_model.dart';

final List<LevelModel> industrialDesignLevelsData = [
  LevelModel(
    id: 'design_1',
    realmId: 'industrial_design',
    levelNumber: 1,
    title: 'Introduction to Industrial Designs',
    difficulty: 'Easy',
    xp: 50,
    content: '''
# What is an Industrial Design?

An **industrial design** protects the **ornamental or aesthetic aspect** of a product. It refers to the shape, pattern, configuration, or composition of lines/colors applied to a product.

## Key Elements

**Must be:**
- Visual (appeal to the eye)
- Applied to an article
- Reproducible by industrial process
- New or original

## Examples

✓ Shape of a Coca-Cola bottle
✓ Pattern on a textile
✓ Car body design
✓ Smartphone exterior
✓ Furniture configuration

## What Design Does NOT Protect

❌ Functional aspects (that's patents)
❌ Brand names (that's trademarks)
❌ Artistic works (that's copyright)

## Indian Law

Governed by **Designs Act, 2000**

**Duration:** 10 years (extendable to 15 years)

## Design vs. Others

| Feature | Design | Patent | Copyright |
|---------|--------|--------|-----------|
| Protects | Appearance | Function | Expression |
| Duration | 15 years | 20 years | Lifetime + 60 years |
| Registration | Mandatory | Mandatory | Automatic |

## Famous Indian Designs

- Tata Nano car design
- Fabindia textile patterns
- Titan watch faces
''',
    quiz: [
      {'question': 'Design protects?', 'options': ['Function', 'Appearance', 'Name', 'Process'], 'correctAnswer': 1, 'explanation': 'Design protects ornamental/aesthetic appearance.'},
      {'question': 'Which Act governs designs in India?', 'options': ['Designs Act, 2000', 'Patents Act', 'Copyright Act', 'Trademarks Act'], 'correctAnswer': 0, 'explanation': 'Designs Act, 2000 governs industrial designs.'},
      {'question': 'Initial design protection duration?', 'options': ['5 years', '10 years', '15 years', '20 years'], 'correctAnswer': 1, 'explanation': 'Initial protection is 10 years, extendable to 15.'},
      {'question': 'Can functional features be registered as design?', 'options': ['Yes', 'No', 'Sometimes', 'Only mechanical'], 'correctAnswer': 1, 'explanation': 'Designs protect aesthetics, not function.'},
      {'question': 'Design must be?', 'options': ['Hidden', 'Visual', 'Secret', 'Patented'], 'correctAnswer': 1, 'explanation': 'Design must be visual and appeal to the eye.'},
    ],
  ),
  LevelModel(
    id: 'design_2',
    realmId: 'industrial_design',
    levelNumber: 2,
    title: 'Registration Process',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Design Registration in India

## Requirements for Registration

**Novelty:**
- Must be NEW
- Not published anywhere before
- Not used publicly in India

**Originality:**
- Not mere mechanical device
- Has visual appeal
- Creative element present

**Not Obscene/Immoral:**
- No offensive designs
- Not against public order

## Registration Process

### Step 1: Application (Form 1)
- Applicant details
- Design classification (32 classes)
- Specimens/drawings
- Statement of novelty

### Step 2: Examination
- Controller examines
- Checks novelty, prior art
- Issues objections if any

### Step 3: Registration
- If no objections
- Certificate issued
- Published in Design Gazette

**Timeline:** 6-12 months

## Locarno Classification

International system: **32 classes**

**Examples:**
- Class 02: Articles of clothing
- Class 06: Furnishing
- Class 09: Packages & containers
- Class 12: Transport vehicles

## Fees (For Individuals)

| Action | Fee |
|--------|-----|
| Filing | ₹1,000 |
| Extension (5 years) | ₹2,000 |

**Total for 15 years:** ₹3,000 only!

## Drawings/Specimens

**Required:**
- Different views (front, back, side, top)
- Clear representation
- Black & white or color
- Scale if needed

## Multiple Designs

Can file up to **10 designs** in same class in one application.

**Benefit:** Cost savings

## Priority Claim

If filed abroad first, can claim priority within **6 months**.

**Example:**
File in USA on Jan 1
File in India by June 30
India filing date = Jan 1 (retroactive)
''',
    quiz: [
      {'question': 'How many classes in Locarno?', 'options': ['10', '25', '32', '45'], 'correctAnswer': 2, 'explanation': 'Locarno Classification has 32 classes.'},
      {'question': 'Filing fee for individual?', 'options': ['₹500', '₹1,000', '₹5,000', '₹10,000'], 'correctAnswer': 1, 'explanation': 'Individual filing fee is ₹1,000.'},
      {'question': 'Priority period for international filing?', 'options': ['3 months', '6 months', '12 months', '18 months'], 'correctAnswer': 1, 'explanation': 'Priority period is 6 months for designs.'},
      {'question': 'Maximum designs per application?', 'options': ['1', '5', '10', 'Unlimited'], 'correctAnswer': 2, 'explanation': 'Up to 10 designs can be filed in one application.'},
      {'question': 'Registration timeline?', 'options': ['1 month', '3 months', '6-12 months', '2 years'], 'correctAnswer': 2, 'explanation': 'Typical registration takes 6-12 months.'},
    ],
  ),
  LevelModel(
    id: 'design_3',
    realmId: 'industrial_design',
    levelNumber: 3,
    title: 'Infringement & Protection',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Design Infringement in India

## What is Infringement?

Making, selling, or importing product with **pirated design** (fraudulently or obviously imitated) without consent.

**Key Test:**
Would an average consumer be **deceived** by the similarity?

## Types of Infringement

**1. Direct Copying:**
- Exact reproduction
- Clear infringement

**2. Substantial Similarity:**
- Minor variations
- Overall appearance same
- Also infringement

**3. Colorable Imitation:**
- Disguised copying
- Attempts to hide similarity
- Still infringement

## Remedies

**Civil:**
- Injunction (stop production)
- Damages (monetary compensation)
- Account of profits
- Delivery up (hand over infringing goods)

**Criminal:**
- Fine up to **₹25,000**
- Imprisonment up to **6 months**
- Or both

## Defense Strategies

**Valid Defenses:**
1. Design is not novel
2. Registration is invalid
3. Fair use (private/non-commercial)
4. Statutory license obtained

## Time Limits

**Infringement suit:**
Must be filed within **3 years** from:
- Date of knowledge, OR
- Date design ceased to be effective

## Famous Cases

**Philips vs. Rajesh Bansal (2008)**
- Philips shaver head design
- Defendant made identical copies
- Delhi High Court: Injunction granted
- Damages awarded

**Raymond vs. Colorplus (2018)**
- Textile design pattern
- Colorplus copied Raymond's design
- Court: Clear infringement
- ₹10 lakh damages

## Overlap with Copyright

**If design is artistic:**
- Can have design + copyright protection
- Copyright lasts longer (60 years)
- But after 15 years, copyright in mass-produced articles limited

**Section 15(2):**
Once design applied to >50 articles, copyright in artistic work ceases (with some exceptions)

## International Protection

**Hague System:**
- File single application
- Protect in 94+ countries
- India NOT yet a member (considering)

**Alternative:**
- File separately in each country
- Claim priority (6 months)
''',
    quiz: [
      {'question': 'Maximum imprisonment for design infringement?', 'options': ['3 months', '6 months', '1 year', '3 years'], 'correctAnswer': 1, 'explanation': 'Maximum imprisonment is 6 months.'},
      {'question': 'Maximum fine for infringement?', 'options': ['₹10,000', '₹25,000', '₹50,000', '₹1 lakh'], 'correctAnswer': 1, 'explanation': 'Maximum fine is ₹25,000.'},
      {'question': 'Infringement suit time limit?', 'options': ['1 year', '2 years', '3 years', '5 years'], 'correctAnswer': 2, 'explanation': 'Suits must be filed within 3 years.'},
      {'question': 'Infringement test is?', 'options': ['Exact copy only', 'Would consumer be deceived?', 'Color match', 'Price similarity'], 'correctAnswer': 1, 'explanation': 'Test is whether average consumer would be deceived.'},
      {'question': 'Is India a member of Hague System?', 'options': ['Yes', 'No', 'Partial', 'Only for textiles'], 'correctAnswer': 1, 'explanation': 'India is not yet a Hague System member.'},
    ],
  ),
  LevelModel(
    id: 'design_4',
    realmId: 'industrial_design',
    levelNumber: 4,
    title: 'Design in Fashion & Textiles',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Protecting Fashion & Textile Designs

## Why Fashion Needs Design Protection

**Fast Fashion Problem:**
- Designs copied within weeks
- Cheap knockoffs flood market
- Original designers lose revenue

**Solution:** Design registration

## Textile Designs

**What's Protected:**
- Fabric patterns
- Weaving designs
- Print motifs
- Color combinations (if distinctive)

**Examples:**
- Bandhani patterns
- Kalamkari designs
- Ikat weaves

**Requirement:**
Must be **original**, not traditional

## Registration Strategy

**1. Pre-Collection:**
Register designs **before** fashion show/launch

**2. Multiple Filings:**
One application for each design variant

**3. Confidentiality:**
Keep designs secret until registration

## Fashion Weeks & IP

**Problem:**
Public display = loss of novelty

**Solution:**
- Register before show
- Use NDAs with attendees
- Limit photography

**6-Month Grace Period:**
Some countries allow filing within 6 months of public disclosure (India: case-by-case)

## Case Studies

**Sabyasachi vs. Anonymous (2018)**
- Wedding lehenga design copied
- Cease & desist issued
- Settlement reached

**Fab India vs. Shree Salasar (2016)**
- Block print textile design
- Injunction granted
- Design registration upheld

## Traditional vs. Contemporary

**Traditional Designs:**
❌ Cannot be registered (public domain)
❌ Example: Paithani saree (traditional)

**Contemporary Interpretation:**
✓ Can be registered if original
✓ Example: Modern take on Paithani

## Business Impact

**Benefits of Registration:**
- Licensing opportunities
- Higher brand value
- Legal deterrent
- Export advantage

**Indian Fashion Industry:**
- Growing awareness
- More registrations
- IP-conscious designers

## International Expansion

**EU Community Design:**
- Single registration for EU
- Unregistered design right (3 years automatic)

**US Design Patents:**
- 15-year protection
- Expensive but strong

**China:**
- Critical for manufacturing
- Rapid examination available
''',
    quiz: [
      {'question': 'Can traditional designs be registered?', 'options': ['Yes', 'No, public domain', 'Only if modified', 'Only handmade'], 'correctAnswer': 1, 'explanation': 'Traditional designs are in public domain and cannot be registered.'},
      {'question': 'When to register fashion designs?', 'options': ['After fashion show', 'Before public display', 'Anytime', 'Only after sales'], 'correctAnswer': 1, 'explanation': 'Register before public display to maintain novelty.'},
      {'question': 'What can be protected in textiles?', 'options': ['Fabric quality', 'Pattern/motif', 'Thread count', 'Price'], 'correctAnswer': 1, 'explanation': 'Patterns and motifs can be protected as designs.'},
      {'question': 'EU unregistered design lasts?', 'options': ['1 year', '3 years', '5 years', '10 years'], 'correctAnswer': 1, 'explanation': 'EU gives automatic 3-year protection for unregistered designs.'},
      {'question': 'Public display affects?', 'options': ['Nothing', 'Novelty', 'Price', 'Color'], 'correctAnswer': 1, 'explanation': 'Public display can destroy novelty for registration.'},
    ],
  ),
  LevelModel(
    id: 'design_5',
    realmId: 'industrial_design',
    levelNumber: 5,
    title: 'Product Design & User Interface',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Design Protection for Products & UI

## Industrial Product Design

**What's Protected:**
- Shapes & configurations
- Surface ornamentation
- Color schemes
- Overall appearance

**Examples:**
- Car body design
- Appliance aesthetics
- Furniture form
- Packaging design

## Automotive Design

**Highly Protected:**
- Exterior body shape
- Grille design
- Headlamp configuration
- Alloy wheel patterns

**Case: Jaguar Land Rover vs. Jiangling (China, 2019)**
- Evoque design copied
- Chinese court ruled infringement
- Landmark case in China

**India:**
Growing registrations by Tata, Mahindra, Maruti

## Electronics & Gadgets

**Protected Elements:**
- Device shape (e.g., iPhone form)
- Button layout
- Charging dock design
- Accessory appearance

**Famous: Apple vs. Samsung (Global, 2011-2018)**
- Design patent wars
- iPhone design vs. Galaxy
- Billions in damages

**Limitation:**
Functional features NOT protected

## Graphical User Interface (GUI)

**What Can Be Registered:**
- Icon designs
- Screen layouts
- Animated transitions
- Theme aesthetics

**Requirements:**
- Applied to a product (device screen)
- Visual appearance, not code
- Original & novel

**Example Applications:**
- Smartphone lock screen design
- App icon set
- Smart TV interface

**Challenges:**
- Rapidly changing tech
- Short product cycles
- Global protection needed

## Packaging Design

**Two-Layer Protection:**

**1. Design Registration:**
- Package shape
- Label layout
- Color combination

**2. Trademark:**
- Brand name
- Logo
- Trade dress

**Example:**
- Coca-Cola bottle: Design + Trademark
- Toblerone box: Design + Trade dress

## Furniture & Interior

**Protected:**
- Chair designs (Eames, Le Corbusier classics)
- Table configurations
- Lighting fixtures
- Modular systems

**Indian Brands:**
- Godrej furniture designs
- Nilkamal chairs
- Urban Ladder collections

## 3D Printing Implications

**New Challenges:**
- Easy to replicate designs
- Home manufacturing
- Difficult to track infringement

**Solution:**
- Strong design registration
- Digital rights management
- Licensing models

## Strategy for Startups

**Priority:**
1. Register core product design
2. File provisional (if budgetconstrained)
3. Expand to variations later
4. Combine with branding (TM)

**Cost-Benefit:**
- Low cost (₹1,000)
- High value (licensing, deterrence)
- Export essential
''',
    quiz: [
      {'question': 'Can GUI be design-protected?', 'options': ['No', 'Yes, if applied to product', 'Only software', 'Only hardware'], 'correctAnswer': 1, 'explanation': 'GUI can be protected if applied to a physical product screen.'},
      {'question': 'Apple vs Samsung was about?', 'options': ['Software', 'Design patents', 'Trademark', 'Copyright'], 'correctAnswer': 1, 'explanation': 'Major design patent litigation over phone appearance.'},
      {'question': 'What is NOT protected in product design?', 'options': ['Shape', 'Functional features', 'Color', 'Pattern'], 'correctAnswer': 1, 'explanation': 'Functional features are not protected by design law.'},
      {'question': 'Packaging can have?', 'options': ['Design only', 'Trademark only', 'Design + Trademark', 'Neither'], 'correctAnswer': 2, 'explanation': 'Packaging can be protected by both design and trademark.'},
      {'question': '3D printing creates what challenge?', 'options': ['None', 'Easy replication of designs', 'Better quality', 'Cheaper production'], 'correctAnswer': 1, 'explanation': '3D printing makes it easy to replicate and infringe designs.'},
    ],
  ),
  LevelModel(
    id: 'design_6',
    realmId: 'industrial_design',
    levelNumber: 6,
    title: 'Overlap with Copyright & Trademarks',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Design, Copyright & Trademark Intersections

## Design + Copyright

**When Does Design Become Copyright?**

**Artistic Work:**
If a design is an **artistic work** (painting, sculpture, drawing), it has copyright **before** being applied to product.

**Section 15(2) Limitation:**
Once design applied to **>50 articles** by industrial process:
- Copyright in artistic work **ceases**
- Design protection takes over

**Exception:**
Textile designs, wall decorations exempt from Section 15(2)

**Case: Microfibres Inc vs. Girdhar (2009)**
- Textile design had both copyright & design
- Delhi HC: Section 15(2) doesn't apply to textiles
- Dual protection allowed

## Strategy

**Before Mass Production:**
Copyright protects original artwork

**After Mass Production (>50):**
Design registration essential

**Best Practice:**
Register design BEFORE production

## Design + Trademark

**Shape Marks:**
A product shape can be BOTH:

**1. Design:** Protects appearance (15 years)
**2. Trademark:** If shape indicates source

**Requirements for Trademark:**
- Distinctive
- Identifies source
- Not functional

**Famous Example:**
**Coca-Cola Bottle**
- Design registration (expired)
- Trademark (ongoing - distinctive shape)
- 3D trademark granted globally

**Section 9 Examination:**
Shape must NOT be:
- Dictated by function
- Adding substantial value (aesthetics alone)

## Trade Dress

**Definition:**
Overall appearance and image of a product.

**Includes:**
- Packaging design
- Color scheme
- Layout
- Labeling

**Protection:**
Primarily through **trademark** (if distinctive + secondary meaning)

**Case: Colgate vs. Anchor (1938)**
- Red color + font combination
- Trade dress protection upheld
- Passing off proven

## Cumulative Protection Strategy

**Example: Smartphone**

| Element | Protection |
|---------|-----------|
| Exterior shape | Design |
| Logo | Trademark |
| UI design | Design |
| Brand name | Trademark |
| Operating system | Copyright + Patent |
| Technical features | Patent |

**Result:** Multi-layered IP fortress

## Enforcement Complexity

**Overlap Issues:**
- Which right to enforce?
- Different limitation periods
- Different remedies

**Solution:**
- Claim all applicable rights
- Parallel proceedings if needed
- Strategic choice based on strength

## International Harmonization

**WIPO Efforts:**
- Align design/copyright boundaries
- Simplify dual protection

**Challenges:**
- Different laws globally
- US: Design patents
- EU: Design rights
- India: Designs Act + Copyright Act

## Practical Checklist

**For Designers/Companies:**

✓ Create original artwork: **Copyright**
✓ Before production: **Register Design**
✓ If distinctive shape: **Trademark**
✓ Package/label: **Design + Trademark**
✓ Brand name/logo: **Trademark**
✓ Technical innovation: **Patent**

**Result:** Comprehensive IP protection
''',
    quiz: [
      {'question': 'After how many articles does copyright cease?', 'options': ['10', '25', '50', '100'], 'correctAnswer': 2, 'explanation': 'Copyright ceases after design applied to >50 articles.'},
      {'question': 'Can a shape be both design and trademark?', 'options': ['No', 'Yes, if distinctive', 'Only in USA', 'Only if patented'], 'correctAnswer': 1, 'explanation': 'Shape can be design + trademark if distinctive and indicates source.'},
      {'question': 'Which is exempt from Section 15(2)?', 'options': ['Furniture', 'Textiles', 'Electronics', 'Vehicles'], 'correctAnswer': 1, 'explanation': 'Textile designs are exempt from Section 15(2) limitation.'},
      {'question': 'Trade dress protects?', 'options': ['Function', 'Overall appearance/image', 'Price', 'Quality'], 'correctAnswer': 1, 'explanation': 'Trade dress protects overall product appearance and image.'},
      {'question': 'Coca-Cola bottle has?', 'options': ['Design only', 'Trademark only', 'Both design (expired) + trademark', 'Patent'], 'correctAnswer': 2, 'explanation': 'Coke bottle had design (expired) and ongoing trademark.'},
    ],
  ),
  LevelModel(
    id: 'design_7',
    realmId: 'industrial_design',
    levelNumber: 7,
    title: 'International Design Systems',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Global Design Protection

## Hague Agreement

**What Is It?**
International system for registering industrial designs in multiple countries via **single application**.

**Managed by:** WIPO

**Coverage:** 94 countries (EU counts as one)

**India Status:** NOT a member (considering joining)

## How Hague Works

### Single Application:
- File one application
- Designate countries
- Pay consolidated fees

### Examination:
- Each country examines independently
- Can refuse in specific countries

### Protection:
- 5 years initially
- Renewable up to 15 years (varies by country)

## Benefits

✓ **Cost Savings:** Cheaper than separate filings
✓ **Centralized Management:** One renewal, one office
✓ **Language:** File in English/French/Spanish
✓ **Fast:** Quicker than individual applications

## Costs

**Basic Fee:** ~400 Swiss Francs
**Per Design:** ~17 Swiss Francs
**Per Country:** Varies (50-100 CHF)

**Example:**
Protect 5 designs in 10 countries:
- Hague: ~₹2 lakhs
- Separate filings: ~₹8 lakhs
- **Savings: 75%**

## Paris Convention Alternative

**For Non-Hague Countries (like India):**

**6-Month Priority:**
- File in home country first
- Claim priority in other countries within 6 months
- All get original filing date

**Example:**
- File in India: January 1
- File in USA by June 30
- US filing date = January 1 (retroactive)

## Major Design Systems Compared

| System | Countries | Duration | Language |
|--------|-----------|----------|----------|
| Hague | 94 | 5-15 years | EN/FR/ES |
| EU CDR | 27 EU countries | 5-25 years | Any EU language |
| US Design Patent | USA | 15 years | English |
| China Design | China | 10-15 years | Chinese |

## EU Community Design (CDR)

**Two Types:**

**1. Registered CDR:**
- File application
- 25-year protection (5-year renewals)
- Strong rights

**2. Unregistered CDR:**
- Automatic on publication
- 3-year protection
- Cheaper but weaker

**Benefits:**
- Single registration = all 27 EU countries
- Cost-effective for exports

## Strategic Filing

**Startups with Limited Budget:**

**Phase 1:** India (₹1,000)
**Phase 2:** Key export markets (USA, EU)
**Phase 3:** Manufacturing hubs (China)

**Priority:**
Claim priority via Paris Convention

**Timing:**
File India first, others within 6 months

## Enforcement Challenges

**Global Infringement:**
- Counterfeiters in China ship to Europe
- Legal in one country, illegal in another
- Customs seizures

**Solution:**
- Register in manufacturing countries
- Register in sales markets
- Monitor online marketplaces

## Future Trends

**India + Hague:**
- India considering membership
- Would boost Indian designers
- Easier exports

**Digital Designs:**
- Growing NFT/digital design protection
- International frameworks evolving

**Harmonization:**
- WIPO pushing for global standards
- Simplify design protection worldwide
''',
    quiz: [
      {'question': 'Is India a Hague Agreement member?', 'options': ['Yes', 'No', 'Partial', 'Observer only'], 'correctAnswer': 1, 'explanation': 'India is not yet a Hague member but considering it.'},
      {'question': 'Paris Convention priority for designs?', 'options': ['3 months', '6 months', '12 months', '18 months'], 'correctAnswer': 1, 'explanation': 'Priority period is 6 months for design filings.'},
      {'question': 'EU unregistered design lasts?', 'options': ['1 year', '3 years', '5 years', '10 years'], 'correctAnswer': 1, 'explanation': 'Unregistered EU design gets automatic 3-year protection.'},
      {'question': 'Hague covers how many countries?', 'options': ['50', '75', '94', '150'], 'correctAnswer': 2, 'explanation': 'Hague Agreement covers 94 countries.'},
      {'question': 'Main benefit of Hague?', 'options': ['Free filing', 'Single application, multiple countries', 'No examination', 'Lifetime protection'], 'correctAnswer': 1, 'explanation': 'Hague allows one application to cover many countries.'},
    ],
  ),
];

