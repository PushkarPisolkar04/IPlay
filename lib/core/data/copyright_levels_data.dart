import '../models/realm_model.dart';

/// Copyright Realm - All 8 levels with complete content
class CopyrightLevelsData {
  static List<LevelModel> getAllLevels() {
    return [
      _getLevel1(),
      _getLevel2(),
      _getLevel3(),
      _getLevel4(),
      _getLevel5(),
      _getLevel6(),
      _getLevel7(),
      _getLevel8(),
    ];
  }

  static LevelModel? getLevelById(String id) {
    try {
      return getAllLevels().firstWhere((level) => level.id == id);
    } catch (e) {
      return null;
    }
  }

  // Level 1: What is Copyright?
  static LevelModel _getLevel1() {
    return LevelModel(
      id: 'copyright_level_1',
      realmId: 'realm_copyright',
      levelNumber: 1,
      name: 'What is Copyright?',
      description: 'Introduction to copyright protection and why it matters',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4', // Placeholder video
      content: '''
# What is Copyright?

Copyright is a **legal right** that grants the creator of original work exclusive rights to its use and distribution. It is a form of intellectual property protection designed to protect creative works.

## Why Copyright Matters

Copyright protection encourages creativity and innovation by ensuring creators can:
- Control how their work is used
- Earn income from their creations
- Prevent unauthorized copying or distribution
- Maintain the integrity of their work

## What Copyright Protects

Copyright protects original works of authorship including:
- **Literary works**: Books, articles, poems, computer programs
- **Artistic works**: Paintings, photographs, sculptures
- **Musical works**: Songs, compositions, lyrics
- **Dramatic works**: Plays, scripts, choreography
- **Cinematographic films**: Movies, documentaries
- **Sound recordings**: Albums, podcasts, audio files

## What Copyright Does NOT Protect

❌ Ideas, concepts, or facts
❌ Titles, names, or short phrases
❌ Methods or systems
❌ Government documents
❌ Works in the public domain

## Automatic Protection

In India, copyright protection is **automatic** upon creation. You don't need to register to have copyright protection, though registration provides additional legal benefits.
''',
      keyPoints: [
        'Copyright protects original creative works automatically',
        'Covers literary, artistic, musical, and dramatic works',
        'Does NOT protect ideas or facts, only their expression',
        'Gives creators exclusive rights to use and distribute their work',
        'Registration provides additional legal benefits',
      ],
      quiz: [
        QuizQuestion(
          question: 'What does copyright protect?',
          options: [
            'Ideas and concepts',
            'Original creative expressions',
            'Facts and data',
            'Names and titles',
          ],
          correctIndex: 1,
          explanation: 'Copyright protects original creative expressions, not the ideas themselves. For example, you can\'t copyright the idea of a love story, but you can copyright your specific story.',
        ),
        QuizQuestion(
          question: 'When does copyright protection begin in India?',
          options: [
            'When you register with the copyright office',
            'When you publish your work',
            'Automatically upon creation',
            'After one year of publication',
          ],
          correctIndex: 2,
          explanation: 'Copyright protection in India is automatic from the moment a work is created. Registration is optional but provides additional legal benefits.',
        ),
        QuizQuestion(
          question: 'Which of these is protected by copyright?',
          options: [
            'A scientific theory',
            'A mathematical formula',
            'A novel',
            'A company name',
          ],
          correctIndex: 2,
          explanation: 'A novel is an original literary work protected by copyright. Scientific theories, formulas, and company names are not protected by copyright.',
        ),
        QuizQuestion(
          question: 'Can you copyright a title of a book?',
          options: [
            'Yes, always',
            'No, titles are too short',
            'Only if it\'s very unique',
            'Only after registration',
          ],
          correctIndex: 1,
          explanation: 'Titles, names, and short phrases cannot be copyrighted because they are too short to be considered substantial creative works. However, they may be protected under trademark law.',
        ),
        QuizQuestion(
          question: 'What is the main purpose of copyright?',
          options: [
            'To make money for the government',
            'To encourage creativity by protecting creators\' rights',
            'To prevent all copying',
            'To control information',
          ],
          correctIndex: 1,
          explanation: 'The primary purpose of copyright is to encourage creativity and innovation by ensuring creators can benefit from their work and have control over how it\'s used.',
        ),
      ],
      xpReward: 100,
      estimatedMinutes: 8,
    );
  }

  // Level 2: Types of Copyrightable Works
  static LevelModel _getLevel2() {
    return LevelModel(
      id: 'copyright_level_2',
      realmId: 'realm_copyright',
      levelNumber: 2,
      name: 'Types of Copyrightable Works',
      description: 'Learn about different categories of works protected by copyright',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# Types of Copyrightable Works

The Indian Copyright Act, 1957 recognizes several categories of works that can be protected by copyright.

## 1. Literary Works 📚

Literary works include any work that is written, spoken, or sung (other than dramatic or musical works).

**Examples:**
- Books and novels
- Articles and essays  
- Computer programs and software
- Websites and blogs
- Instruction manuals
- Compilations and databases

## 2. Dramatic Works 🎭

Dramatic works include plays, scripts, and choreography.

**Examples:**
- Stage plays and scripts
- Film screenplays
- Dance choreography
- Pantomimes

## 3. Musical Works 🎵

Musical works include compositions, with or without words.

**Examples:**
- Songs and compositions
- Background scores
- Jingles and ringtones
- Instrumental pieces

## 4. Artistic Works 🎨

Artistic works include visual creations.

**Examples:**
- Paintings and drawings
- Photographs
- Sculptures
- Architectural works
- Maps, charts, and diagrams
- Graphic designs and logos

## 5. Cinematographic Films 🎬

Includes motion pictures and videos.

**Examples:**
- Movies and documentaries
- Television shows
- Video games cutscenes
- Animated films

## 6. Sound Recordings 🎧

The specific recording of sounds (different from musical works).

**Examples:**
- Music albums
- Podcast episodes
- Audio books
- Sound effects libraries

## Important Note

Each type has different protection terms and rules. For example, a song may have copyright in:
- The **musical composition** (music and lyrics)
- The **sound recording** (the specific performance)
- The **cinematographic film** (if it's a music video)
''',
      keyPoints: [
        'Copyright protects 6 main types of works in India',
        'Literary works include books, articles, and computer programs',
        'Artistic works cover paintings, photographs, and sculptures',
        'Musical works and sound recordings are protected separately',
        'One creation can have multiple copyrights (e.g., song has composition + recording)',
      ],
      quiz: [
        QuizQuestion(
          question: 'Which category does a computer program fall under?',
          options: [
            'Artistic work',
            'Literary work',
            'Dramatic work',
            'Musical work',
          ],
          correctIndex: 1,
          explanation: 'Computer programs are considered literary works under copyright law, as they are written expressions of logic and instructions.',
        ),
        QuizQuestion(
          question: 'What is the difference between a musical work and a sound recording?',
          options: [
            'There is no difference',
            'Musical work is the composition; sound recording is the specific performance',
            'Sound recording is only for albums',
            'Musical work includes sound recordings',
          ],
          correctIndex: 1,
          explanation: 'A musical work is the composition (notes and lyrics), while a sound recording is the specific recorded performance. Both have separate copyrights.',
        ),
        QuizQuestion(
          question: 'Can choreography be copyrighted?',
          options: [
            'No, it\'s just movement',
            'Yes, as a dramatic work',
            'Only if filmed',
            'Only if written down',
          ],
          correctIndex: 1,
          explanation: 'Choreography is protected as a dramatic work. It can be recorded through video, notation, or written description.',
        ),
        QuizQuestion(
          question: 'Which of these is an artistic work?',
          options: [
            'A poem',
            'A photograph',
            'A song',
            'A movie script',
          ],
          correctIndex: 1,
          explanation: 'A photograph is classified as an artistic work. Poems are literary works, songs are musical works, and scripts are dramatic works.',
        ),
        QuizQuestion(
          question: 'Can a single creation have multiple copyrights?',
          options: [
            'No, only one copyright per creation',
            'Yes, different aspects can have separate copyrights',
            'Only if made by multiple people',
            'Only for commercial works',
          ],
          correctIndex: 1,
          explanation: 'Yes! For example, a music video has copyright in the musical composition, sound recording, and cinematographic film - each protected separately.',
        ),
      ],
      xpReward: 120,
      estimatedMinutes: 10,
    );
  }

  // Simplified versions for remaining levels (3-8)
  static LevelModel _getLevel3() {
    return LevelModel(
      id: 'copyright_level_3',
      realmId: 'realm_copyright',
      levelNumber: 3,
      name: 'Copyright Ownership',
      description: 'Understanding who owns copyright and joint ownership',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# Copyright Ownership

## First Owner Rule
Generally, the **creator** of a work is the first owner of copyright.

## Work for Hire Exception
When work is created as part of employment, the **employer** owns the copyright unless there's an agreement stating otherwise.

## Joint Ownership
When multiple creators contribute to a work, they become joint owners with equal rights.

## Assignment and Licensing
Copyright owners can transfer (assign) or license their rights to others through written agreements.
''',
      keyPoints: [
        'Creator is usually the first copyright owner',
        'Employers own copyright for work-for-hire',
        'Joint ownership requires all owners\' consent for commercial use',
        'Rights can be transferred through written agreements',
      ],
      quiz: [
        QuizQuestion(
          question: 'Who owns copyright in a work created by an employee during work hours?',
          options: ['The employee', 'The employer', 'Both equally', 'The government'],
          correctIndex: 1,
          explanation: 'Under work-for-hire rules, the employer owns copyright for works created by employees in the course of employment.',
        ),
        QuizQuestion(
          question: 'Can copyright be transferred to another person?',
          options: ['No, never', 'Yes, through written agreement', 'Only after creator\'s death', 'Only to family members'],
          correctIndex: 1,
          explanation: 'Copyright can be assigned (transferred) to others through a written agreement signed by the copyright owner.',
        ),
      ],
      xpReward: 150,
      estimatedMinutes: 12,
    );
  }

  static LevelModel _getLevel4() {
    return LevelModel(
      id: 'copyright_level_4',
      realmId: 'realm_copyright',
      levelNumber: 4,
      name: 'Copyright Duration',
      description: 'How long copyright protection lasts in India',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# Copyright Duration in India

## For Most Works
Copyright lasts for the **lifetime of the author plus 60 years**.

## For Photographs
Copyright lasts for **60 years** from the beginning of the calendar year next following the year in which the photograph is published.

## For Cinematographic Films and Sound Recordings
Copyright lasts for **60 years** from the beginning of the calendar year next following the year of publication.

## For Anonymous/Pseudonymous Works
Copyright lasts for **60 years** from the beginning of the calendar year next following the year of first publication.

## After Copyright Expires
The work enters the **public domain** and can be used by anyone without permission.
''',
      keyPoints: [
        'Most copyrights last lifetime + 60 years in India',
        'Photographs, films, and recordings: 60 years from publication',
        'After expiry, works enter public domain',
        'Public domain works can be freely used by anyone',
      ],
      quiz: [
        QuizQuestion(
          question: 'How long does copyright last for a novel in India?',
          options: ['50 years', 'Lifetime + 50 years', 'Lifetime + 60 years', 'Forever'],
          correctIndex: 2,
          explanation: 'For literary works like novels, copyright lasts for the author\'s lifetime plus 60 years after death.',
        ),
        QuizQuestion(
          question: 'What happens when copyright expires?',
          options: ['Work is destroyed', 'Work enters public domain', 'Family inherits forever', 'Government takes ownership'],
          correctIndex: 1,
          explanation: 'When copyright expires, the work enters the public domain and can be freely used by anyone without permission or payment.',
        ),
      ],
      xpReward: 150,
      estimatedMinutes: 10,
    );
  }

  static LevelModel _getLevel5() {
    return LevelModel(
      id: 'copyright_level_5',
      realmId: 'realm_copyright',
      levelNumber: 5,
      name: 'Fair Use and Exceptions',
      description: 'When you can use copyrighted works without permission',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# Fair Use and Copyright Exceptions

## Fair Dealing
Indian copyright law allows limited use of copyrighted works without permission for:
- **Private or personal use** (including research)
- **Criticism or review**
- **Reporting current events**
- **Educational purposes**

## Educational Exceptions
Teachers and educational institutions can use copyrighted works for non-commercial educational purposes.

## Library Exceptions
Libraries can make copies for preservation and lending purposes.

## Disabled Persons
Special provisions allow conversion of works into accessible formats.
''',
      keyPoints: [
        'Fair dealing allows limited use without permission',
        'Personal use, criticism, news reporting are permitted',
        'Educational institutions have special exceptions',
        'Must not harm commercial value of original work',
      ],
      quiz: [
        QuizQuestion(
          question: 'Can you use a copyrighted image in your school project?',
          options: ['No, never', 'Yes, for educational purposes', 'Only if you pay', 'Only if you modify it'],
          correctIndex: 1,
          explanation: 'Educational use is permitted under fair dealing provisions, especially for non-commercial school projects.',
        ),
        QuizQuestion(
          question: 'Can a teacher photocopy book chapters for students?',
          options: ['No, it\'s piracy', 'Yes, for teaching purposes', 'Only with publisher permission', 'Only 1 page allowed'],
          correctIndex: 1,
          explanation: 'Teachers can make copies of reasonable portions for classroom teaching under educational exceptions.',
        ),
      ],
      xpReward: 180,
      estimatedMinutes: 12,
    );
  }

  static LevelModel _getLevel6() {
    return LevelModel(
      id: 'copyright_level_6',
      realmId: 'realm_copyright',
      levelNumber: 6,
      name: 'Copyright Infringement',
      description: 'Understanding violations and penalties',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# Copyright Infringement

## What is Infringement?
Using copyrighted work without permission in ways that violate owner's exclusive rights.

## Types of Infringement
- **Direct infringement**: Copying, distributing, or performing copyrighted work
- **Indirect infringement**: Enabling or facilitating infringement
- **Online piracy**: Illegal downloading, streaming, or sharing

## Penalties
- **Civil penalties**: Damages, injunctions, account of profits
- **Criminal penalties**: Imprisonment up to 3 years and fine up to ₹2 lakhs (for severe cases)

## How to Avoid Infringement
- Get permission/license from owner
- Use works in public domain
- Use Creative Commons licensed works
- Create original content
- Use fair dealing exceptions properly
''',
      keyPoints: [
        'Infringement is using copyrighted work without permission',
        'Can result in civil and criminal penalties',
        'Penalties include fines and imprisonment',
        'Always get permission or use legal exceptions',
      ],
      quiz: [
        QuizQuestion(
          question: 'Is downloading pirated movies illegal in India?',
          options: ['No, only uploading is illegal', 'Yes, it\'s copyright infringement', 'Only if you sell them', 'Legal for personal use'],
          correctIndex: 1,
          explanation: 'Downloading pirated content is copyright infringement and illegal in India, even for personal use.',
        ),
        QuizQuestion(
          question: 'What can happen if you are caught infringing copyright?',
          options: ['Nothing, it\'s not serious', 'Only a warning', 'Civil and criminal penalties', 'Just delete the content'],
          correctIndex: 2,
          explanation: 'Copyright infringement can lead to both civil lawsuits (damages) and criminal prosecution (fines and imprisonment).',
        ),
      ],
      xpReward: 200,
      estimatedMinutes: 15,
    );
  }

  static LevelModel _getLevel7() {
    return LevelModel(
      id: 'copyright_level_7',
      realmId: 'realm_copyright',
      levelNumber: 7,
      name: 'Copyright Registration Process',
      description: 'Step-by-step guide to register copyright in India',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# How to Register Copyright in India

## Why Register?
Though not mandatory, registration provides:
- Prima facie evidence of ownership
- Public record of copyright
- Easier to prove in infringement cases
- Can claim statutory damages

## Registration Process

### Step 1: Prepare Documents
- Application Form XIV (for various works)
- Two copies of the work
- Statement of particulars
- Power of attorney (if filed by agent)
- ID proof and address proof

### Step 2: Online Application
Visit: **copyright.gov.in**
- Create account
- Fill application form
- Upload required documents
- Pay fees (varies by type: ₹500-2000)

### Step 3: Examination
- Copyright office examines application
- May require clarifications (30 days to respond)
- May require modifications

### Step 4: Publication
- After examination, particulars published in Copyright Journal
- 30-day objection period

### Step 5: Registration
- If no objections, certificate issued
- Digitally signed certificate sent via email
- Process typically takes 1-2 years

## Fees Structure
- Literary/Dramatic/Musical/Artistic works: ₹500
- Sound recording/Cinematographic films: ₹2000
- For multiple authors: ₹2000

## Documents Required
- Filled application form
- Proof of authorship/ownership
- Copy of the work (2 copies for published works)
- NOC if based on existing work
- ID and address proof
''',
      keyPoints: [
        'Registration is optional but provides legal advantages',
        'Process done online at copyright.gov.in',
        'Requires application form, copy of work, and fees',
        'Examination and objection period included',
        'Certificate typically issued in 1-2 years',
      ],
      quiz: [
        QuizQuestion(
          question: 'Is copyright registration mandatory in India?',
          options: ['Yes, always required', 'No, but provides legal benefits', 'Only for commercial works', 'Only for published works'],
          correctIndex: 1,
          explanation: 'Copyright registration is not mandatory as protection is automatic, but registration provides important legal benefits and evidence.',
        ),
        QuizQuestion(
          question: 'Where do you register copyright in India?',
          options: ['Local police station', 'copyright.gov.in', 'Patent office', 'Notary public'],
          correctIndex: 1,
          explanation: 'Copyright registration in India is done online through the official website copyright.gov.in.',
        ),
        QuizQuestion(
          question: 'How long does copyright registration typically take?',
          options: ['1 week', '1 month', '6 months', '1-2 years'],
          correctIndex: 3,
          explanation: 'The copyright registration process, including examination and objection period, typically takes 1-2 years to complete.',
        ),
      ],
      xpReward: 220,
      estimatedMinutes: 18,
    );
  }

  static LevelModel _getLevel8() {
    return LevelModel(
      id: 'copyright_level_8',
      realmId: 'realm_copyright',
      levelNumber: 8,
      name: 'Copyright Enforcement & Legal Remedies',
      description: 'How to protect and enforce your copyright',
      videoUrl: 'https://www.youtube.com/watch?v=Uiq42O6rhW4',
      content: '''
# Enforcing Copyright Rights

## Detection
Monitor and identify unauthorized use through:
- Online searches
- Social media monitoring
- Reverse image search
- Copyright monitoring services

## Civil Remedies

### 1. Cease and Desist Notice
- First step: Send legal notice demanding stop of infringement
- Give reasonable time to comply
- Often resolves issues without court

### 2. File Copyright Infringement Suit
Can claim:
- **Injunction**: Court order to stop infringement
- **Damages**: Compensation for losses
- **Account of profits**: Profits made by infringer
- **Delivery**: Hand over infringing copies

## Criminal Remedies
For willful infringement for commercial gain:
- Police complaint
- Can lead to arrest and prosecution
- Penalties: Up to 3 years imprisonment + fine up to ₹2 lakhs

## Online Enforcement

### DMCA Takedown (International)
For content on foreign platforms:
- Send DMCA notice to platform
- Platform must remove content

### Court Orders
- Blocking orders against websites
- ISP directed to block access

## International Protection
- Berne Convention: Automatic protection in 179+ countries
- No need to register in each country
- Can enforce rights internationally

## Alternative Dispute Resolution
- Mediation
- Arbitration
- Faster and cheaper than court litigation

## Important Tips
- Keep evidence of creation (dates, drafts, emails)
- Keep records of copyright registration
- Document all instances of infringement
- Act quickly (within limitation period)
- Consult copyright lawyer for serious cases
''',
      keyPoints: [
        'Copyright holders can seek civil and criminal remedies',
        'Start with cease and desist notice',
        'Can claim injunction, damages, and profits',
        'International protection through Berne Convention',
        'Keep good documentation of creation and ownership',
      ],
      quiz: [
        QuizQuestion(
          question: 'What is the first step when you find copyright infringement?',
          options: ['File police case', 'Send cease and desist notice', 'Hire lawyer immediately', 'Delete your work'],
          correctIndex: 1,
          explanation: 'Sending a cease and desist notice is typically the first step, as it\'s cost-effective and often resolves issues without going to court.',
        ),
        QuizQuestion(
          question: 'Can you enforce Indian copyright internationally?',
          options: ['No, only in India', 'Yes, in 179+ countries under Berne Convention', 'Only in neighboring countries', 'Only if you register abroad'],
          correctIndex: 1,
          explanation: 'The Berne Convention provides automatic copyright protection in 179+ member countries, allowing enforcement internationally.',
        ),
        QuizQuestion(
          question: 'What remedies can a copyright owner seek?',
          options: ['Only monetary damages', 'Only injunction', 'Injunction, damages, account of profits, delivery', 'No remedies available'],
          correctIndex: 2,
          explanation: 'Copyright owners can seek multiple remedies including injunction (stop infringement), damages, account of profits, and delivery of infringing copies.',
        ),
      ],
      xpReward: 250,
      estimatedMinutes: 20,
    );
  }
}

