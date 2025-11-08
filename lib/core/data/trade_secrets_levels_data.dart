import '../../models/level_model.dart';

final List<LevelModel> tradeSecretsLevelsData = [
  LevelModel(
    id: 'ts_1',
    realmId: 'trade_secrets',
    levelNumber: 1,
    title: 'Understanding Trade Secrets',
    difficulty: 'Easy',
    xp: 50,
    content: '''
# What is a Trade Secret?

A **trade secret** is confidential business information that provides a competitive advantage and is protected through secrecy rather than registration.

## Key Characteristics

**1. Secret:**
- Not generally known
- Not easily discoverable

**2. Economic Value:**
- Provides competitive edge
- Value derived from secrecy

**3. Reasonable Protection:**
- Owner takes steps to maintain secrecy
- NDAs, access controls, etc.

## Famous Examples

**Global:**
- Coca-Cola formula (120+ years secret)
- KFC's 11 herbs & spices recipe
- Google search algorithm
- WD-40 formula

**Indian:**
- MDH spice blends
- Dabur Chyawanprash formula
- Haldiram's snack recipes

## Types of Trade Secrets

**1. Technical:**
- Chemical formulas
- Manufacturing processes
- Software source code
- R&D data

**2. Commercial:**
- Customer lists
- Pricing strategies
- Marketing plans
- Supplier contracts

**3. Financial:**
- Cost structures
- Profit margins
- Investment strategies

## Trade Secret vs. Patent

| Feature | Trade Secret | Patent |
|---------|--------------|--------|
| Protection | Secrecy | Registration |
| Duration | Unlimited (if secret) | 20 years |
| Disclosure | None | Full disclosure |
| Cost | Low | High (filing, maintenance) |
| Reverse Engineering | Permitted | Infringement |

## Indian Legal Framework

**No specific Trade Secrets Act in India**

**Protection through:**
- Contract Law (NDAs, employment contracts)
- Common Law (breach of confidence)
- Information Technology Act, 2000
- Copyright Act (for software)

**Remedy:** Civil suit for breach of confidence
''',
    quiz: [
      {'question': 'Trade secret duration?', 'options': ['10 years', '20 years', 'Unlimited if maintained', '50 years'], 'correctAnswer': 2, 'explanation': 'Trade secrets last indefinitely as long as secrecy is maintained.'},
      {'question': 'Famous trade secret example?', 'options': ['iPhone design', 'Coca-Cola formula', 'Eiffel Tower', 'Windows logo'], 'correctAnswer': 1, 'explanation': 'Coca-Cola formula is a famous trade secret for 120+ years.'},
      {'question': 'Is registration required?', 'options': ['Yes', 'No', 'Sometimes', 'Only in India'], 'correctAnswer': 1, 'explanation': 'Trade secrets are protected through secrecy, not registration.'},
      {'question': 'Is reverse engineering allowed?', 'options': ['No', 'Yes, for trade secrets', 'Only with permission', 'Only in USA'], 'correctAnswer': 1, 'explanation': 'Reverse engineering is permitted for trade secrets, unlike patents.'},
      {'question': 'India has specific Trade Secrets Act?', 'options': ['Yes', 'No', 'Proposed', 'State-level only'], 'correctAnswer': 1, 'explanation': 'India has no specific Act; protection is via contract/common law.'},
    ],
  ),
  LevelModel(
    id: 'ts_2',
    realmId: 'trade_secrets',
    levelNumber: 2,
    title: 'Protecting Trade Secrets',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# How to Protect Trade Secrets

## Physical Security Measures

**1. Access Control:**
- Restricted areas
- Keycard/biometric entry
- Visitor logs
- CCTV surveillance

**2. Document Security:**
- Locked cabinets
- Shredding sensitive documents
- Watermarking
- "Confidential" stamping

**3. Computer Security:**
- Password protection
- Encryption
- Firewalls
- Access logs

## Legal Measures

**1. Non-Disclosure Agreements (NDAs):**

**Types:**
- Unilateral (one-way)
- Bilateral (mutual)
- Multilateral (multiple parties)

**Key Clauses:**
- Definition of confidential info
- Obligations of receiving party
- Duration (typically 2-5 years)
- Remedies for breach

**2. Employment Contracts:**

**Must Include:**
- Confidentiality obligations
- Non-compete clauses (if valid)
- Assignment of inventions
- Return of materials on exit

**3. Visitor/Contractor Agreements:**
- Sign NDA before entry
- Limited access
- Supervision required

## Administrative Measures

**1. Need-to-Know Basis:**
- Limit information access
- Compartmentalize knowledge
- Example: Coca-Cola formula split among people

**2. Employee Training:**
- Regular confidentiality training
- Consequences of breach explained
- Reporting suspicious activities

**3. Exit Procedures:**
- Return of company property
- Reminder of ongoing obligations
- Exit interviews

## Digital Protection

**1. Data Loss Prevention (DLP):**
- Monitor data transfers
- Block unauthorized copying
- Alert on suspicious activity

**2. Email Security:**
- Encryption for sensitive emails
- Auto-classification (confidential/public)
- Prevent forwarding restrictions

**3. Cloud Security:**
- Choose secure providers
- Encryption at rest & in transit
- Access logging

## Identifying What to Protect

**Audit Process:**

**Step 1:** Identify all confidential info
**Step 2:** Classify by sensitivity
**Step 3:** Assess current protection
**Step 4:** Implement gaps

**Classification Levels:**
- Public
- Internal use only
- Confidential
- Highly confidential

## Cost-Benefit Analysis

**To Patent or Keep Secret?**

**Patent if:**
- Reverse engineering easy
- Need licensing revenue
- Short-term advantage
- Public disclosure acceptable

**Trade Secret if:**
- Difficult to reverse engineer
- Long-term competitive edge
- No need for licensing
- Avoid disclosure

**Example Decisions:**

| Information | Choice | Reason |
|-------------|--------|--------|
| Coca-Cola formula | Secret | Impossible to reverse engineer taste |
| Smartphone design | Patent | Easy to copy, needs legal protection |
| Software algorithm | Secret | Source code hidden, hard to copy |
| Drug molecule | Patent | Reverse engineering possible |

## International Travel

**Risks:**
- Border searches
- Competitor surveillance
- Data theft

**Precautions:**
- Clean devices
- Encrypted backup
- VPN usage
- Minimal information carried
''',
    quiz: [
      {'question': 'NDA stands for?', 'options': ['National Data Act', 'Non-Disclosure Agreement', 'New Design Application', 'Network Development Agency'], 'correctAnswer': 1, 'explanation': 'NDA is Non-Disclosure Agreement for confidentiality.'},
      {'question': 'Coca-Cola formula protection method?', 'options': ['Patent', 'Trademark', 'Trade secret', 'Copyright'], 'correctAnswer': 2, 'explanation': 'Coca-Cola uses trade secret, not patent, to avoid disclosure.'},
      {'question': 'Need-to-know basis means?', 'options': ['Tell everyone', 'Limit info to necessary persons only', 'Public information', 'Government sharing'], 'correctAnswer': 1, 'explanation': 'Need-to-know limits access to only those who require it.'},
      {'question': 'Typical NDA duration?', 'options': ['1 year', '2-5 years', '10 years', 'Lifetime'], 'correctAnswer': 1, 'explanation': 'NDAs typically last 2-5 years, though can vary.'},
      {'question': 'What should be done on employee exit?', 'options': ['Nothing', 'Return materials, remind obligations', 'Delete all data', 'Give severance'], 'correctAnswer': 1, 'explanation': 'Exit procedures include return of property and obligation reminders.'},
    ],
  ),
  LevelModel(
    id: 'ts_3',
    realmId: 'trade_secrets',
    levelNumber: 3,
    title: 'Trade Secret Theft & Remedies',
    difficulty: 'Medium',
    xp: 100,
    content: '''
# Trade Secret Misappropriation

## What is Misappropriation?

**Wrongful:**
- Acquisition
- Disclosure
- Use

of trade secrets without consent.

## Common Methods of Theft

**1. Insider Threats:**
- Employees copying data before leaving
- Selling info to competitors
- Taking customer lists

**2. Corporate Espionage:**
- Hiring competitors' employees for info
- Planting spies
- Surveillance

**3. Cyber Attacks:**
- Hacking
- Phishing
- Malware
- Ransomware

**4. Reverse Engineering:**
- Legal if no contract violated
- Buying product and analyzing it

## Famous Cases

### 1. Tata Motors vs. Jayem Auto (2005)

**Facts:**
- Ex-Tata employee allegedly shared design drawings
- Started competing company

**Court:**
- Injunction granted
- Breach of confidentiality upheld

**Lesson:** Employment contracts must include confidentiality

### 2. Microsoft India (2007)

**Facts:**
- Employee downloaded source code
- Attempted to sell to competitors

**Outcome:**
- Criminal case under IT Act
- Imprisonment + fine

**Lesson:** Digital theft is prosecutable

### 3. Diljit Titus vs. Alfred (Delhi HC, 2007)

**Facts:**
- Perfume manufacturer's fragrance formula
- Employee disclosed to competitor

**Court:**
- Permanent injunction
- Damages awarded

**Lesson:** Common law breach of confidence applicable

## Legal Remedies in India

**Civil Remedies:**

**1. Injunction:**
- Temporary/Permanent
- Stop use/disclosure
- Most common remedy

**2. Damages:**
- Compensate for loss
- Based on:
  - Actual loss to plaintiff
  - Gain to defendant
  - Reasonable royalty

**3. Account of Profits:**
- Defendant must hand over profits made

**4. Delivery Up:**
- Surrender of materials containing trade secret

**Criminal Remedies:**

**IT Act, 2000 (if digital):**
- Section 43: Unauthorized access (₹1 crore penalty)
- Section 66: Computer related offences (3 years imprisonment)

**IPC:**
- Section 405: Criminal breach of trust

## Burden of Proof

**Plaintiff must prove:**

1. **Information was secret**
2. **Owner took reasonable steps** to protect
3. **Defendant wrongfully acquired/used**
4. **Economic harm** resulted

## Defenses

**Valid Defenses:**

1. **Independent Discovery:**
- Defendant developed independently
- No access to plaintiff's secrets

2. **Reverse Engineering:**
- Legally obtained product
- Analyzed without breach

3. **Public Domain:**
- Information already public
- No longer secret

4. **Authorized Disclosure:**
- Consent obtained
- Within NDA terms

## Time Limitations

**Limitation Period:**
- **3 years** from knowledge of breach (most states)
- Can vary by jurisdiction

**Injunction:**
- Can be granted even after limitation if continuing harm

## International Aspects

**If trade secret stolen and used abroad:**

**Challenges:**
- Jurisdiction issues
- Evidence gathering
- Enforcement difficulty

**Solutions:**
- File in foreign courts
- Use international treaties (if applicable)
- Diplomatic channels (govt-to-govt)

## Prevention Checklist

✓ Robust NDAs
✓ Employee training
✓ Exit procedures
✓ Technical safeguards
✓ Regular audits
✓ Incident response plan
✓ Legal counsel on standby
''',
    quiz: [
      {'question': 'Common source of trade secret theft?', 'options': ['Competitors', 'Employees', 'Customers', 'Government'], 'correctAnswer': 1, 'explanation': 'Insider threats from employees are the most common source.'},
      {'question': 'Is reverse engineering legal?', 'options': ['Never', 'Yes, if no contract violated', 'Only in USA', 'Only for software'], 'correctAnswer': 1, 'explanation': 'Reverse engineering is legal if done without breach of contract.'},
      {'question': 'IT Act Section 43 penalty?', 'options': ['₹10,000', '₹1 lakh', '₹1 crore', '₹10 crore'], 'correctAnswer': 2, 'explanation': 'Section 43 allows up to ₹1 crore penalty.'},
      {'question': 'Limitation period for breach suit?', 'options': ['1 year', '3 years', '5 years', '10 years'], 'correctAnswer': 1, 'explanation': 'Typically 3 years from knowledge of breach.'},
      {'question': 'Most common remedy?', 'options': ['Damages', 'Injunction', 'Imprisonment', 'Fine'], 'correctAnswer': 1, 'explanation': 'Injunction to stop use/disclosure is most common.'},
    ],
  ),
  LevelModel(
    id: 'ts_4',
    realmId: 'trade_secrets',
    levelNumber: 4,
    title: 'Non-Compete & Non-Solicit Agreements',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Restrictive Covenants in India

## Non-Compete Agreements

**Definition:**
Clause preventing employee from joining competitor or starting competing business for a period after leaving.

**Indian Law:**

**Section 27, Indian Contract Act:**
"Every agreement by which anyone is restrained from exercising a lawful profession, trade, or business of any kind, is to that extent void."

**Interpretation:**
Non-compete clauses are **VOID** in India (with exceptions).

### Exceptions (Valid Non-Competes):

**1. Sale of Goodwill (Section 27 exception):**
- Seller of business can agree not to compete
- Must be reasonable in time, geography, scope

**Example:**
- X sells restaurant to Y
- X agrees not to open similar restaurant in same city for 3 years
- Valid ✓

**2. Partnership Agreements:**
- Partners can agree not to compete during partnership
- After partnership, generally void

**3. During Employment:**
- Employee cannot work for competitor simultaneously
- Conflict of interest

### Landmark Cases

**Niranjan Shankar Golikari vs. Century Spinning (1967)**

**Facts:**
- Managing agent terminated
- Had 5-year non-compete clause

**Supreme Court:**
- Non-compete void under Section 27
- Cannot enforce post-employment

**Principle:**
"Negative Covenants in restraint of trade are void."

**Percept D'Mark (India) vs. Zaheer Khan (2006)**

**Facts:**
- Celebrity endorsement contract
- Exclusivity clause

**Court:**
- Exclusivity during contract term: Valid
- After termination: Invalid

**VFS Global vs. Suprit Roy (2008)**

**Facts:**
- 1-year non-compete after employment

**Delhi HC:**
- Struck down as void
- Employee's right to livelihood paramount

## Non-Solicitation Agreements

**Definition:**
Prevents ex-employee from:
- Soliciting clients
- Poaching employees

**Indian Law:**

**More Lenient than Non-Compete:**
- Not directly covered by Section 27
- Courts may uphold if reasonable

**Conditions for Validity:**

✓ **Limited Duration:** 6 months - 1 year
✓ **Limited Scope:** Specific clients only
✓ **Reasonable Geography:** Not entire country
✓ **Protects Legitimate Interest:** Client relationships built using employer resources

### Case Law

**Wipro vs. Beckman Coulter (2006)**

**Facts:**
- Employee poached Wipro clients after joining competitor

**Court:**
- Granted injunction
- Unfair solicitation of clients

**Reasoning:**
Client relationships were confidential info

**SanDisk vs. Aseem Jain (2017)**

**Facts:**
- Ex-employee solicited SanDisk's clients

**Court:**
- Injunction granted for 6 months
- Non-solicit upheld as protecting trade secrets (client lists)

## Garden Leave

**Definition:**
Employee serves notice period but doesn't work; stays "in the garden."

**Purpose:**
- Prevent immediate competition
- Allow memory to fade
- Client transition time

**Validity in India:**
- If employee is paid: Generally valid
- If unpaid: May be challenged

**Typical Duration:** 3-6 months

## Strategies for Employers

**Since Non-Compete is Void:**

**1. Strong Confidentiality Clauses:**
- Protect trade secrets
- Enforceable unlike non-compete

**2. Non-Solicitation (Reasonable):**
- Limited duration
- Specific clients/employees

**3. Garden Leave:**
- Pay during notice period
- Keep employee idle

**4. Deferred Compensation:**
- Bonuses paid post-employment
- Forfeited if joining competitor (gray area)

**5. Specialized Training Bonds:**
- Employee pays if leaves early after costly training
- Must be reasonable

## Employee Rights

**Constitutional Protection:**

**Article 19(1)(g):**
Right to practice any profession, trade, or business

**Article 21:**
Right to livelihood

**Courts Balance:**
- Employer's legitimate interest
- vs. Employee's right to livelihood

**Generally:** Employee rights prevail

## Comparison: India vs. Global

| Country | Non-Compete Validity |
|---------|---------------------|
| India | Void (Section 27) |
| USA | Valid if reasonable (state-dependent) |
| UK | Valid if reasonable |
| California (USA) | Void (like India) |

## Practical Tips

**For Employers:**
- Don't waste time on non-compete
- Focus on confidentiality + non-solicit
- Build retention through culture, not clauses

**For Employees:**
- Non-compete in India is unenforceable
- But honor confidentiality obligations
- Avoid client poaching (legal risk)
- Consult lawyer if threatened
''',
    quiz: [
      {'question': 'Are non-compete clauses valid in India?', 'options': ['Yes always', 'No, void under Section 27', 'Only for executives', 'Only for 1 year'], 'correctAnswer': 1, 'explanation': 'Section 27 makes non-compete clauses void in India (with rare exceptions).'},
      {'question': 'Which is more enforceable in India?', 'options': ['Non-compete', 'Non-solicitation', 'Both equal', 'Neither'], 'correctAnswer': 1, 'explanation': 'Non-solicitation is more likely to be upheld if reasonable.'},
      {'question': 'Garden leave means?', 'options': ['Gardening duty', 'Paid notice without work', 'Unpaid leave', 'Termination'], 'correctAnswer': 1, 'explanation': 'Garden leave is paid notice period without working.'},
      {'question': 'Which Constitutional Article protects livelihood?', 'options': ['Article 14', 'Article 19(1)(g)', 'Article 32', 'Article 51'], 'correctAnswer': 1, 'explanation': 'Article 19(1)(g) protects right to practice any profession/business.'},
      {'question': 'Non-compete valid for sale of goodwill?', 'options': ['No', 'Yes, if reasonable', 'Only for companies', 'Only for partnerships'], 'correctAnswer': 1, 'explanation': 'Section 27 exception allows reasonable non-compete when selling business.'},
    ],
  ),
  LevelModel(
    id: 'ts_5',
    realmId: 'trade_secrets',
    levelNumber: 5,
    title: 'Economic Espionage & Cyber Threats',
    difficulty: 'Hard',
    xp: 150,
    content: '''
# Modern Threats to Trade Secrets

## Economic Espionage

**Definition:**
Theft of trade secrets by or for the benefit of a **foreign entity** (government/company).

**Difference from Industrial Espionage:**
- Economic: Foreign entity involved
- Industrial: Domestic competitor

**Methods:**

**1. State-Sponsored:**
- Intelligence agencies
- Cyber attacks on corporations
- Infiltration via students/researchers

**2. Corporate-Sponsored:**
- Hiring competitor's employees specifically for info
- Bribery
- Blackmail

**Famous Incidents:**

**Operation Aurora (2010):**
- Chinese hackers targeted Google, Adobe, others
- Stole source code, IP
- Google partly withdrew from China

**APT1 (Advanced Persistent Threat):**
- Chinese military unit
- Hacked 141+ companies globally
- Stole R&D, trade secrets

## Cyber Threats to Trade Secrets

### 1. Phishing

**How:**
- Fake emails mimicking trusted sources
- Employee clicks malicious link
- Credentials stolen or malware installed

**Example:**
CEO fraud - "Urgent: Transfer funds" email

**Defense:**
- Employee training
- Email authentication (SPF, DKIM)
- Multi-factor authentication

### 2. Ransomware

**How:**
- Malware encrypts all data
- Demands ransom for decryption key
- Often threatens to leak data

**Famous:**
- WannaCry (2017): 200,000+ victims
- REvil: Attacked Quanta (Apple supplier), leaked blueprints

**Defense:**
- Regular backups (offline)
- Patch management
- Network segmentation

### 3. Insider Threats (Digital)

**How:**
- Employee downloads files before leaving
- USB drives, cloud uploads
- Email to personal account

**Statistics:**
- 60%+ breaches involve insiders
- Intentional or negligent

**Defense:**
- Data Loss Prevention (DLP) tools
- Monitor unusual data transfers
- Disable USB ports

### 4. Supply Chain Attacks

**How:**
- Compromise supplier/vendor
- Use their access to target main company

**Famous:**
- SolarWinds (2020): Malware in software update
- Affected 18,000+ organizations

**Defense:**
- Vet vendors
- Limit vendor access
- Monitor vendor activities

## Legal Framework in India

### IT Act, 2000

**Section 43:**
Unauthorized access, data theft
- Penalty: Up to ₹1 crore

**Section 66:**
Computer-related offences
- Imprisonment: Up to 3 years
- Fine: Up to ₹5 lakhs

**Section 66B:**
Dishonestly receiving stolen computer resource
- Imprisonment: Up to 3 years + fine

**Section 72:**
Breach of confidentiality/privacy
- Imprisonment: up to 2 years + fine

### IPC Provisions

**Section 378:**
Theft (including data)

**Section 405:**
Criminal breach of trust

**Section 420:**
Cheating

## Case Study: Uber vs. Waymo (2017)

**Background:**
- Anthony Levandowski left Google's Waymo
- Joined Uber
- Allegedly took 14,000 confidential files

**Allegations:**
- Trade secret theft (LiDAR technology)
- Economic espionage

**Outcome:**
- Uber settled for \$245 million
- Levandowski criminally charged
- Lesson: Digital forensics critical

## Investigating Trade Secret Theft

**Steps:**

**1. Incident Detection:**
- Unusual data access
- Employee behavior changes
- Competitor's sudden advancement

**2. Preserve Evidence:**
- Forensic image of devices
- Email logs
- Access logs

**3. Internal Investigation:**
- Interview suspects
- Review contracts
- Timeline reconstruction

**4. Legal Action:**
- Send cease & desist
- File police complaint (if criminal)
- Civil suit

**5. Notify Authorities:**
- CERT-In (for cyber incidents)
- Police cyber cell
- Industry regulators

## Preventive Measures

### Technical

✓ Encryption (at rest & in transit)
✓ DLP software
✓ Network monitoring (IDS/IPS)
✓ Endpoint protection
✓ Regular security audits
✓ Incident response plan

### Organizational

✓ Background checks
✓ Need-to-know access
✓ Regular training
✓ Clear policies
✓ Exit interviews
✓ Monitor ex-employees (legally)

### Legal

✓ Strong NDAs
✓ IP assignment clauses
✓ Prompt action on breach
✓ Insurance (cyber + IP)

## Emerging Threats

**1. AI-Powered Attacks:**
- Deepfake voice (CEO fraud)
- Automated phishing
- Intelligent malware

**2. IoT Vulnerabilities:**
- Smart devices in offices
- Unsecured entry points

**3. Quantum Computing:**
- Future threat to encryption
- Need quantum-resistant methods

**4. Remote Work Risks:**
- Home networks less secure
- Shared devices
- Insider access from anywhere

## International Cooperation

**MLAT (Mutual Legal Assistance Treaty):**
- India has with 40+ countries
- Share evidence for prosecution

**Budapest Convention:**
- Cybercrime treaty
- India not a party (yet)
- Limits international enforcement

**Interpol:**
- Coordinates across borders
- Economic crimes division
''',
    quiz: [
      {'question': 'Economic espionage involves?', 'options': ['Domestic competitor', 'Foreign entity', 'Employee only', 'Customer'], 'correctAnswer': 1, 'explanation': 'Economic espionage involves foreign governments or entities.'},
      {'question': 'IT Act Section 43 penalty?', 'options': ['₹10,000', '₹1 lakh', '₹1 crore', '₹10 crore'], 'correctAnswer': 2, 'explanation': 'Section 43 allows penalty up to ₹1 crore.'},
      {'question': 'Most common breach source?', 'options': ['Hackers', 'Insiders', 'Competitors', 'Government'], 'correctAnswer': 1, 'explanation': '60%+ of breaches involve insiders (intentional or negligent).'},
      {'question': 'Ransomware does what?', 'options': ['Steals money', 'Encrypts data, demands ransom', 'Deletes files', 'Sends spam'], 'correctAnswer': 1, 'explanation': 'Ransomware encrypts data and demands ransom for decryption.'},
      {'question': 'DLP stands for?', 'options': ['Digital License Protection', 'Data Loss Prevention', 'Document Legal Policy', 'Device Location Protocol'], 'correctAnswer': 1, 'explanation': 'DLP is Data Loss Prevention to stop unauthorized data transfers.'},
    ],
  ),
  LevelModel(
    id: 'ts_6',
    realmId: 'trade_secrets',
    levelNumber: 6,
    title: 'Trade Secrets in Startups & Licensing',
    difficulty: 'Expert',
    xp: 200,
    content: '''
# Trade Secrets for Startups & Business

## Why Trade Secrets for Startups?

**Advantages:**

✓ **No Cost:** Unlike patents (₹50,000-5 lakhs)
✓ **Immediate:** Protection starts now
✓ **No Disclosure:** Competitors don't learn
✓ **Unlimited Duration:** If maintained
✓ **Flexibility:** Can patent later if needed

**Ideal For:**
- Early-stage startups
- Bootstrapped companies
- Software/SaaS
- Algorithms, processes
- Customer databases

## Startup Protection Strategy

### Phase 1: Founding (Day 1)

**Founders' Agreement:**
- IP ownership clauses
- All IP belongs to company
- Confidentiality obligations

**Incorporation:**
- IP assignment from founders to company
- Document all pre-existing IP

### Phase 2: Early Employees (Month 1-6)

**Employment Contracts Must Have:**

1. **Confidentiality Clause**
2. **IP Assignment** (work product belongs to company)
3. **No Solicitation** (reasonable)
4. **Return of Materials** on exit

**Example Clause:**
"All inventions, discoveries, and work product created during employment shall be the sole property of the Company."

### Phase 3: Fundraising (Seed/Series A)

**Investors Will Ask:**

- What IP do you own?
- Is it properly protected?
- Any employee disputes?
- Third-party claims?

**Due Diligence Prep:**

✓ All employees signed IP agreements
✓ Contractors have assignment clauses
✓ No pending disputes
✓ Trade secret policy documented

### Phase 4: Growth (Scaling)

**Expanded Measures:**

- Formal classification system
- Access control matrices
- Security audits
- Background checks
- Legal counsel on retainer

## Licensing Trade Secrets

**Can You License a Secret?**

**Yes, but carefully:**

**License vs. Disclosure:**
- Disclose secret to licensee
- But maintain confidentiality
- Licensee can use but not re-disclose

**License Agreement Must Include:**

1. **Definition** of trade secret being licensed
2. **Scope** of permitted use
3. **Duration** of license
4. **Confidentiality** obligations
5. **Royalty** terms
6. **Return/Destruction** on termination
7. **No Sub-Licensing** (usually)

**Example:**

**Coca-Cola Bottling:**
- Coca-Cola licenses syrup formula to bottlers
- Bottlers sign strict confidentiality
- No disclosure, no reverse engineering
- Decades-long relationships

### Types of Licenses

**1. Exclusive:**
- One licensee only
- Licensor can't use or license to others

**2. Non-Exclusive:**
- Multiple licensees
- Licensor retains rights

**3. Sole:**
- One licensee + licensor can use
- No other licensees

## Joint Ventures & Collaborations

**Challenges:**

- Sharing secrets with partner
- Risk of misuse
- IP ownership disputes

**Protections:**

**1. Clear JV Agreement:**
- What's shared, what's not
- Ownership of new IP created
- Confidentiality obligations
- Exit provisions

**2. Background vs. Foreground IP:**
- Background: Pre-existing IP (each keeps)
- Foreground: Created in JV (shared or assigned)

**3. Disclosure Limitations:**
- Share only what's necessary
- Redact sensitive parts
- Staged disclosure

**Example:**

**Tata-Fiat JV:**
- Tata shared manufacturing processes
- Fiat shared engine tech
- Clear agreements on IP ownership
- JV ended, IP returned/separated

## Trade Secrets in M&A

**Acquisition Scenario:**

**Buyer's Concerns:**
- Is target's IP properly protected?
- Any employee theft risks?
- Litigation pending?

**Seller's Concerns:**
- Protect secrets during due diligence
- Prevent buyer from backing out and using info

**Solutions:**

**1. Tiered Disclosure:**
- High-level info first
- Detailed info after LOI signed
- Most sensitive info post-closing only

**2. Clean Room:**
- Neutral party reviews sensitive info
- Provides summary to buyer
- Full access only after deal closes

**3. Escrow:**
- Detailed trade secrets in escrow
- Released only on closing
- Returned if deal fails

## Open Source & Trade Secrets

**Conflict:**

- Open source requires code disclosure
- Trade secret requires secrecy

**Can't Have Both for Same Code**

**Strategies:**

**1. Dual Licensing:**
- Open source version (basic)
- Proprietary version (advanced features secret)
- Example: MySQL

**2. Open Core:**
- Core product open source
- Premium features/plugins closed
- Example: GitLab

**3. SaaS Model:**
- Code remains secret (not distributed)
- Provide as service
- Example: Google Search (algorithm secret)

## Trade Secrets in Remote Work Era

**New Challenges:**

- Employees work from home
- Personal devices
- Unsecured networks
- Global team (jurisdiction issues)

**Solutions:**

**Technical:**
- VPN mandatory
- Company-issued devices only
- Cloud security (encrypted, logged)
- DLP tools

**Policy:**
- Remote work security policy
- No public WiFi for work
- Background-free video calls (no whiteboards visible)

**Legal:**
- Updated contracts for remote workers
- Jurisdiction clauses
- Governing law

## Startup Exit Scenarios

### Scenario 1: Acquisition

**Trade Secrets Transfer:**
- Valuation includes IP value
- Proper documentation critical
- Employee retention (key secret holders)

**Acquirer Checklist:**
- All employees signed IP agreements?
- Trade secret policy in place?
- No litigation?
- Secrets properly documented?

### Scenario 2: Failure/Shutdown

**What Happens to Secrets?**

- Company owns, not founders (if done right)
- Liquidator may sell IP assets
- Founders bound by confidentiality

**Founders Can't:**
- Take customer lists to new venture
- Use proprietary processes
- Disclose to others

## Valuation of Trade Secrets

**Methods:**

**1. Cost Approach:**
- What did it cost to develop?
- R&D expenses

**2. Market Approach:**
- What would competitor pay for it?
- Licensing comparables

**3. Income Approach:**
- Future earnings attributable to secret
- Discounted to present value

**Example:**

**Zomato Customer Data (2015):**
- 17 million user records allegedly leaked
- Estimated value: \$10-50 million
- Based on: Ad revenue potential, competitive edge

**KFC Recipe:**
- Estimated value: \$5-10 billion
- Based on: Brand value, sales advantage

## Key Takeaways for Startups

✓ **From Day 1:** IP assignment agreements
✓ **Document Everything:** What's secret, who knows, how protected
✓ **Employees:** Robust contracts
✓ **Partners/Vendors:** Strong NDAs
✓ **Fundraising:** Clean IP ownership
✓ **Exit:** Proper documentation increases valuation

**Remember:**
Trade secrets are assets. Protect like you protect cash.
''',
    quiz: [
      {'question': 'Startup advantage of trade secrets?', 'options': ['Expensive', 'No cost, immediate protection', 'Requires disclosure', 'Only for big companies'], 'correctAnswer': 1, 'explanation': 'Trade secrets have no filing cost and immediate protection, ideal for startups.'},
      {'question': 'Founders Agreement should include?', 'options': ['Nothing', 'IP ownership and assignment to company', 'Salary details', 'Office location'], 'correctAnswer': 1, 'explanation': 'All IP must be assigned to the company not individual founders.'},
      {'question': 'Can you license a trade secret?', 'options': ['No', 'Yes, with strict confidentiality', 'Only patents can be licensed', 'Only to government'], 'correctAnswer': 1, 'explanation': 'Trade secrets can be licensed with strict confidentiality obligations.'},
      {'question': 'Open source and trade secret for same code?', 'options': ['Yes', 'No, conflicting', 'Sometimes', 'Only in USA'], 'correctAnswer': 1, 'explanation': 'Cannot have both for same code; open source requires disclosure.'},
      {'question': 'In M&A, buyer should check?', 'options': ['Office size', 'IP agreements signed by employees', 'Lunch menu', 'Parking spaces'], 'correctAnswer': 1, 'explanation': 'Buyer must verify all employees signed IP assignment agreements.'},
    ],
  ),
];

