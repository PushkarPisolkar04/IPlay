import '../models/level_model.dart';

final List<LevelModel> trademarkLevelsData = [
  LevelModel(
    id: 'trademark_1',
    realmId: 'trademark',
    levelNumber: 1,
    title: 'Introduction to Trademarks',
    difficulty: 'Easy',
    xp: 50,
    content: '''
# What is a Trademark?

A **trademark** is a unique sign, symbol, word, or combination used to identify and distinguish goods or services of one business from others.

## Types of Trademarks

1. **Word Marks**: Text-based (e.g., "Apple", "Nike")
2. **Logo Marks**: Graphic symbols (e.g., McDonald's golden arches)
3. **Combined Marks**: Word + Logo (e.g., Adidas logo with text)
4. **Sound Marks**: Unique sounds (e.g., Nokia ringtone)
5. **Shape Marks**: Product shapes (e.g., Coca-Cola bottle)

## Purpose
- Protect brand identity
- Prevent consumer confusion
- Build brand reputation

## Indian Law
Governed by the **Trade Marks Act, 1999**.

## Symbol Usage
- ™ = Unregistered trademark
- ® = Registered trademark (legal protection)

**Example**: "Tata®" is a registered trademark in India.
''',
    quiz: [
      {'question': 'What does ® symbol indicate?', 'options': ['Unregistered', 'Registered', 'Rejected', 'Reserved'], 'correctAnswer': 1, 'explanation': 'The ® symbol indicates a registered trademark with legal protection.'},
      {'question': 'Which Act governs trademarks in India?', 'options': ['Patents Act', 'Trade Marks Act, 1999', 'Copyright Act', 'Designs Act'], 'correctAnswer': 1, 'explanation': 'Trade Marks Act, 1999 is the governing law.'},
      {'question': 'Can a sound be trademarked?', 'options': ['No', 'Yes', 'Only music', 'Only words'], 'correctAnswer': 1, 'explanation': 'Sound marks like Nokia ringtone can be trademarked.'},
      {'question': 'What is the primary purpose of a trademark?', 'options': ['Decoration', 'Brand identity', 'Tax benefits', 'Export'], 'correctAnswer': 1, 'explanation': 'Trademarks protect and identify brand identity.'},
      {'question': 'Which is NOT a type of trademark?', 'options': ['Word mark', 'Logo mark', 'Patent mark', 'Sound mark'], 'correctAnswer': 2, 'explanation': 'Patent mark is not a trademark type; patents are different.'},
    ],
  ),
  LevelModel(
    id: 'trademark_2',
    realmId: 'trademark',
    levelNumber: 2,
    title: 'Registration Process',
    difficulty: 'Easy',
    xp: 50,
    content: '''
# Trademark Registration in India

## Steps to Register

1. **Trademark Search**: Check if similar marks exist
2. **Application Filing**: Submit Form TM-A to Trademark Registry
3. **Examination**: Registry examines for conflicts
4. **Publication**: Published in Trademark Journal (4 months)
5. **Opposition Period**: 4 months for objections
6. **Registration**: If no opposition, certificate issued

## Duration
- **Validity**: 10 years from filing date
- **Renewal**: Every 10 years indefinitely

## Cost (Government Fees)
- Individual/Startup: ₹4,500
- Others: ₹9,000

## Required Documents
- Applicant details
- Trademark representation
- Goods/Services classification
- Power of Attorney

## Timeline
Typically **18-24 months** for complete registration.

**Important**: You can use ™ even before registration, but ® only after registration.
''',
    quiz: [
      {'question': 'How long is a trademark valid initially?', 'options': ['5 years', '10 years', '20 years', 'Lifetime'], 'correctAnswer': 1, 'explanation': 'Trademarks are valid for 10 years and renewable.'},
      {'question': 'What is the opposition period?', 'options': ['2 months', '4 months', '6 months', '1 year'], 'correctAnswer': 1, 'explanation': 'Opposition period is 4 months after publication.'},
      {'question': 'Can you use ® before registration?', 'options': ['Yes', 'No', 'Sometimes', 'After application'], 'correctAnswer': 1, 'explanation': 'Using ® before registration is illegal; use ™ instead.'},
      {'question': 'Which form is used for application?', 'options': ['Form A', 'Form TM-A', 'Form TR-1', 'Form B'], 'correctAnswer': 1, 'explanation': 'Form TM-A is the application form.'},
      {'question': 'Registration timeline is typically?', 'options': ['6 months', '12 months', '18-24 months', '5 years'], 'correctAnswer': 2, 'explanation': 'Registration typically takes 18-24 months.'},
    ],
  ),
  LevelModel(
    id: 'trademark_3',
    realmId: 'trademark',
    levelNumber: 3,
    title: 'Classification of Goods & Services',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Nice Classification System

India follows the **Nice Classification** (11th edition) - 45 classes total.

## Structure
- **Classes 1-34**: Goods
- **Classes 35-45**: Services

## Common Classes (Examples)

**Goods:**
- Class 3: Cosmetics, soaps
- Class 9: Electronics, software
- Class 25: Clothing, footwear
- Class 30: Tea, coffee, snacks

**Services:**
- Class 35: Advertising, business management
- Class 41: Education, entertainment
- Class 42: IT services, software development
- Class 43: Restaurants, hotels

## Multi-Class Application
You can apply for multiple classes in one application.

## Fee Structure
Fees are charged **per class** applied for.

## Real Example
"Amul®" - Registered in:
- Class 29: Dairy products
- Class 30: Ice cream
- Class 43: Restaurant services

**Important**: Choose classes carefully; wrong classification can lead to rejection.
''',
    quiz: [
      {'question': 'How many classes in Nice Classification?', 'options': ['34', '45', '50', '100'], 'correctAnswer': 1, 'explanation': 'Nice Classification has 45 classes total.'},
      {'question': 'Which classes are for services?', 'options': ['1-34', '35-45', '1-45', '25-45'], 'correctAnswer': 1, 'explanation': 'Classes 35-45 are for services.'},
      {'question': 'Which class is for clothing?', 'options': ['Class 9', 'Class 25', 'Class 30', 'Class 41'], 'correctAnswer': 1, 'explanation': 'Class 25 covers clothing and footwear.'},
      {'question': 'Can you apply for multiple classes?', 'options': ['No', 'Yes', 'Only 2', 'Only goods'], 'correctAnswer': 1, 'explanation': 'Multi-class applications are allowed.'},
      {'question': 'Fees are charged per?', 'options': ['Application', 'Class', 'Year', 'Product'], 'correctAnswer': 1, 'explanation': 'Fees are charged per class applied for.'},
    ],
  ),
  LevelModel(
    id: 'trademark_4',
    realmId: 'trademark',
    levelNumber: 4,
    title: 'Infringement & Enforcement',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Trademark Infringement

## What is Infringement?
Unauthorized use of a registered trademark or deceptively similar mark that causes confusion.

## Types of Infringement

1. **Direct Infringement**: Exact copy of registered mark
2. **Passing Off**: Using similar mark to deceive consumers
3. **Dilution**: Weakening famous trademark's distinctiveness

## Remedies

**Civil Remedies:**
- Injunction (stop use)
- Damages/Account of profits
- Destruction of infringing goods

**Criminal Remedies:**
- Imprisonment up to **3 years**
- Fine up to **₹2 lakhs**
- Both for repeat offenders

## Famous Cases

**Tata Sons vs. Tata Infoway (2010)**
- Tata Sons sued for "Tata" usage
- Court ruled in favor of Tata Sons
- Trademark dilution prevented

**McDonald's vs. McD (2017)**
- Local restaurant used "McD" name
- McDonald's won; restaurant shut down
- Passing off proven

## Defense Against Infringement
- Monitor market for violations
- Send cease & desist letters
- File infringement suits promptly
''',
    quiz: [
      {'question': 'Maximum imprisonment for infringement?', 'options': ['1 year', '3 years', '5 years', '7 years'], 'correctAnswer': 1, 'explanation': 'Maximum imprisonment is 3 years.'},
      {'question': 'What is passing off?', 'options': ['Copying exactly', 'Deceiving consumers with similar mark', 'Legal use', 'Trademark sale'], 'correctAnswer': 1, 'explanation': 'Passing off is deceiving consumers with similar marks.'},
      {'question': 'Maximum fine for infringement?', 'options': ['₹50,000', '₹1 lakh', '₹2 lakhs', '₹5 lakhs'], 'correctAnswer': 2, 'explanation': 'Maximum fine is ₹2 lakhs.'},
      {'question': 'Which is a civil remedy?', 'options': ['Imprisonment', 'Injunction', 'Fine', 'Arrest'], 'correctAnswer': 1, 'explanation': 'Injunction is a civil remedy to stop use.'},
      {'question': 'Dilution means?', 'options': ['Copying', 'Weakening brand distinctiveness', 'Legal use', 'Trademark renewal'], 'correctAnswer': 1, 'explanation': 'Dilution weakens a famous trademark\'s distinctiveness.'},
    ],
  ),
  LevelModel(
    id: 'trademark_5',
    realmId: 'trademark',
    levelNumber: 5,
    title: 'Well-Known Trademarks',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Well-Known Trademarks in India

## Definition
Trademarks with **extensive reputation** and recognition among the public, even outside their registered class.

## Special Protection
- Protection in **all classes** (not just registered ones)
- Defense against dilution
- Faster enforcement

## Criteria for Recognition

1. Knowledge/recognition by relevant public
2. Duration & extent of use
3. Geographical area of use
4. Advertising & promotion
5. Registration history

## Indian Well-Known Marks (Examples)

**Domestic:**
- Tata
- Reliance
- Amul
- Britannia
- Dabur

**International:**
- Coca-Cola
- Google
- Apple
- Microsoft
- Samsung

## Legal Provisions
Section 11(6-9) of Trade Marks Act, 1999

## Case Study: Yahoo vs. Akash

**Facts**: Akash Arora registered "yahooindia.com"
**Ruling**: Delhi High Court (1999) ruled in favor of Yahoo
**Outcome**: First well-known trademark case in India

## Benefits
- Broader protection
- Enhanced enforcement
- Market dominance
''',
    quiz: [
      {'question': 'Well-known marks are protected in?', 'options': ['One class', 'Registered classes only', 'All classes', 'No classes'], 'correctAnswer': 2, 'explanation': 'Well-known marks get protection in all classes.'},
      {'question': 'Which is an Indian well-known mark?', 'options': ['Tata', 'Pepsi', 'Nike', 'BMW'], 'correctAnswer': 0, 'explanation': 'Tata is a well-known domestic trademark.'},
      {'question': 'Section covering well-known marks?', 'options': ['Section 2', 'Section 11', 'Section 28', 'Section 45'], 'correctAnswer': 1, 'explanation': 'Section 11(6-9) covers well-known trademarks.'},
      {'question': 'First well-known case in India?', 'options': ['Tata vs Tata', 'Yahoo vs Akash', 'Google vs India', 'Apple vs Samsung'], 'correctAnswer': 1, 'explanation': 'Yahoo vs Akash Arora (1999) was the first case.'},
      {'question': 'Criteria for well-known status?', 'options': ['Age only', 'Recognition & reputation', 'Government approval', 'International presence'], 'correctAnswer': 1, 'explanation': 'Recognition and extensive reputation are key criteria.'},
    ],
  ),
  LevelModel(
    id: 'trademark_6',
    realmId: 'trademark',
    levelNumber: 6,
    title: 'Collective & Certification Marks',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Special Types of Trademarks

## Collective Marks

**Definition**: Marks owned by associations/groups to identify member products/services.

**Examples:**
- Darjeeling Tea Association
- Kanchipuram Silk Weavers
- CII (Confederation of Indian Industry)

**Characteristics:**
- Owned by associations
- Used by multiple members
- Indicates membership/origin
- Requires rules of use

## Certification Marks

**Definition**: Marks certifying quality, origin, material, or manufacturing method.

**Examples:**
- ISI (Indian Standards Institute)
- Agmark (Agricultural products)
- Woolmark (Wool quality)
- Hallmark (Gold purity)

**Characteristics:**
- Owner doesn't use it commercially
- Certifies third-party products
- Strict quality standards
- Regular audits required

## Comparison

| Feature | Collective | Certification |
|---------|-----------|--------------|
| Owner | Association | Certifying body |
| Users | Members only | Any qualifying party |
| Purpose | Membership | Quality standard |

## Legal Framework
- Section 61-68: Collective marks
- Section 69-76: Certification marks

## Famous Example: GI + Certification

**Darjeeling Tea**
- GI tag (geographical indication)
- Collective mark (tea board)
- Certification mark (quality)

Triple protection!
''',
    quiz: [
      {'question': 'Who owns collective marks?', 'options': ['Individuals', 'Associations', 'Government', 'Companies'], 'correctAnswer': 1, 'explanation': 'Associations own collective marks for members.'},
      {'question': 'What does ISI certify?', 'options': ['Origin', 'Quality standard', 'Membership', 'Price'], 'correctAnswer': 1, 'explanation': 'ISI certifies quality standards.'},
      {'question': 'Who can use certification marks?', 'options': ['Owner only', 'Members only', 'Any qualifying party', 'Government'], 'correctAnswer': 2, 'explanation': 'Any party meeting standards can use certification marks.'},
      {'question': 'Which section covers certification marks?', 'options': ['Section 1-10', 'Section 61-68', 'Section 69-76', 'Section 100'], 'correctAnswer': 2, 'explanation': 'Section 69-76 covers certification marks.'},
      {'question': 'Example of collective mark?', 'options': ['ISI', 'Darjeeling Tea Association', 'Hallmark', 'Agmark'], 'correctAnswer': 1, 'explanation': 'Darjeeling Tea Association is a collective mark.'},
    ],
  ),
  LevelModel(
    id: 'trademark_7',
    realmId: 'trademark',
    levelNumber: 7,
    title: 'Madrid Protocol & International Registration',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# International Trademark Protection

## Madrid System

**What is it?**
International system for registering trademarks in multiple countries through **single application**.

**India's Status**: Member since **July 8, 2013**

## How It Works

1. **Base Application**: File in home country (India)
2. **International Application**: Through WIPO
3. **Designation**: Select countries for protection
4. **Examination**: Each country examines independently
5. **Protection**: Valid in designated countries

## Benefits

✓ **Single Application**: One form, multiple countries
✓ **Cost-Effective**: Lower than individual applications
✓ **Centralized Management**: Renewals, changes via WIPO
✓ **Language**: File in English/French/Spanish

## Coverage
- **127 countries** (as of 2023)
- Includes: USA, China, EU, Japan, Australia, etc.

## Costs
- Basic fee: 653 Swiss Francs
- Per-country fee: varies
- **Cheaper** than filing separately

## Limitations
- **Central Attack**: If base application fails in first 5 years, international registration cancels
- Not all countries are members
- Each country can still refuse protection

## Case Example

**Indian Company "XYZ Textiles"**
- Wants protection in USA, EU, China
- Option 1: File separately = ₹15+ lakhs
- Option 2: Madrid = ₹5-7 lakhs
- **Savings: 50%+**

## Alternative: Paris Convention
- File within 6 months in other countries
- Claim priority from first filing
''',
    quiz: [
      {'question': 'When did India join Madrid Protocol?', 'options': ['2010', '2013', '2015', '2020'], 'correctAnswer': 1, 'explanation': 'India joined on July 8, 2013.'},
      {'question': 'How many countries in Madrid System?', 'options': ['50', '100', '127', '195'], 'correctAnswer': 2, 'explanation': 'Madrid System covers 127 countries.'},
      {'question': 'What is central attack?', 'options': ['Military action', 'Base application failure affects all', 'Fee penalty', 'Renewal issue'], 'correctAnswer': 1, 'explanation': 'If base application fails in 5 years, international registration cancels.'},
      {'question': 'Which organization manages Madrid?', 'options': ['UN', 'WIPO', 'WTO', 'UNESCO'], 'correctAnswer': 1, 'explanation': 'WIPO manages the Madrid System.'},
      {'question': 'Main benefit of Madrid Protocol?', 'options': ['Free registration', 'Single application, multiple countries', 'No examination', 'Instant approval'], 'correctAnswer': 1, 'explanation': 'Single application covers multiple countries efficiently.'},
    ],
  ),
  LevelModel(
    id: 'trademark_8',
    realmId: 'trademark',
    levelNumber: 8,
    title: 'Assignment, Licensing & E-Commerce',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Trademark Transfer & Modern Challenges

## Assignment (Transfer)

**Definition**: Transferring ownership of trademark to another party.

**Types:**
1. **With Goodwill**: Business reputation transfers
2. **Without Goodwill**: Only trademark transfers
3. **Partial**: Limited to certain goods/services

**Process:**
- Written agreement required
- File Form TM-P with Registrar
- Both parties must sign
- Fee: ₹9,000

**Important**: Registered assignment has priority

## Licensing

**Definition**: Owner permits another to use trademark under conditions.

**Types:**
1. **Exclusive**: Only licensee can use
2. **Non-exclusive**: Multiple licensees allowed
3. **Sole**: Owner + one licensee only

**Requirements:**
- Written agreement
- Quality control clauses
- Royalty terms
- Duration specified

**Example**: McDonald's franchises use licensed trademark

## E-Commerce Challenges

**Domain Names:**
- Cybersquatting (registering brand domains)
- Typosquatting (misspelled domains)
- Solution: File complaints, UDRP

**Online Marketplaces:**
- Counterfeit goods on Amazon, Flipkart
- Trademark owners can file takedown
- Platforms have seller verification

**Meta Tags & Keywords:**
- Competitors using your brand in ads
- Google allows trademark bidding
- Legal in most cases

**Social Media:**
- Fake brand profiles
- Impersonation issues
- Report to platform + legal action

## Recent Case

**Christian Louboutin vs. Amazon (2021)**
- Counterfeit red-sole shoes on Amazon India
- Court ordered Amazon to prevent sale
- Platform liability established

## Best Practices
- Monitor online use
- Register domain variants
- Use brand protection tools
- Educate consumers
''',
    quiz: [
      {'question': 'Assignment fee in India?', 'options': ['₹4,500', '₹9,000', '₹15,000', 'Free'], 'correctAnswer': 1, 'explanation': 'Assignment filing fee is ₹9,000.'},
      {'question': 'Which allows multiple licensees?', 'options': ['Exclusive', 'Non-exclusive', 'Sole', 'Partial'], 'correctAnswer': 1, 'explanation': 'Non-exclusive licensing allows multiple licensees.'},
      {'question': 'What is cybersquatting?', 'options': ['Hacking', 'Registering brand domains', 'Selling online', 'Email spam'], 'correctAnswer': 1, 'explanation': 'Cybersquatting is registering brand names as domains.'},
      {'question': 'Form for trademark assignment?', 'options': ['TM-A', 'TM-P', 'TM-R', 'TM-O'], 'correctAnswer': 1, 'explanation': 'Form TM-P is used for assignment/transmission.'},
      {'question': 'Can platforms be liable for counterfeits?', 'options': ['Never', 'Yes, established in courts', 'Only sellers', 'Only buyers'], 'correctAnswer': 1, 'explanation': 'Courts have established platform liability for counterfeits.'},
    ],
  ),
];

