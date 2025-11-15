# Patent Detective - Clue-Based Detective Game

## 🎯 Game Concept
**NO IMAGES NEEDED!** A text-based detective game where players read clues and deduce which patented object is being described. Uses brain power and deduction skills!

## 🎮 How It Works

### Game Flow
1. Player sees a "Case Number" (e.g., Case #001)
2. Clues are revealed one at a time (5 clues total)
3. Player has 4 suspects to choose from
4. Player selects their answer
5. Game reveals if correct and shows patent information
6. Move to next case
7. After 10 cases, show final score

### Clue System
- **Clue 1**: Very general (category/era)
- **Clue 2**: Historical context (inventor/year)
- **Clue 3**: Technical detail
- **Clue 4**: Usage/purpose
- **Clue 5**: Specific patent detail

Players can reveal clues one at a time or all at once (their choice).

## 💻 Simple Implementation

### Data Model

```dart
class DetectiveCase {
  final String id;
  final String caseNumber;
  final String category;
  final String difficulty;
  final int points;
  final List<String> clues;
  final List<String> suspects;
  final int correctIndex;
  final PatentInfo patentInfo;
  final String explanation;
}
```

### Game Screen

```dart
class PatentDetectiveScreen extends StatefulWidget {
  @override
  _PatentDetectiveScreenState createState() => _PatentDetectiveScreenState();
}

class _PatentDetectiveScreenState extends State<PatentDetectiveScreen> {
  List<DetectiveCase> cases = [];
  int currentCaseIndex = 0;
  int cluesRevealed = 1; // Start with 1 clue
  int? selectedSuspect;
  int score = 0;
  bool showingResult = false;
  
  @override
  Widget build(BuildContext context) {
    if (currentCaseIndex >= 10) {
      return _buildResultsScreen();
    }
    
    final currentCase = cases[currentCaseIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('🔍 Patent Detective'),
        actions: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('Case ${currentCaseIndex + 1}/10 | Score: $score'),
          ),
        ],
      ),
      body: showingResult 
          ? _buildResultView(currentCase)
          : _buildDetectiveView(currentCase),
    );
  }
  
  Widget _buildDetectiveView(DetectiveCase case_) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan, Colors.blue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_open, color: Colors.white, size: 40),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      case_.caseNumber,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      case_.category,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Clues Section
          Text(
            'Evidence:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          
          // Revealed Clues
          ...List.generate(cluesRevealed, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  border: Border.all(color: Colors.amber, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  case_.clues[index],
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }),
          
          // Reveal Next Clue Button
          if (cluesRevealed < case_.clues.length && selectedSuspect == null)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    cluesRevealed++;
                  });
                },
                icon: Icon(Icons.lightbulb_outline),
                label: Text('Reveal Next Clue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          SizedBox(height: 24),
          
          // Suspects Section
          Text(
            'Suspects:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            'Which object matches the evidence?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 12),
          
          // Suspect Cards
          ...List.generate(case_.suspects.length, (index) {
            final isSelected = selectedSuspect == index;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedSuspect = index;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.cyan.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    border: Border.all(
                      color: isSelected ? Colors.cyan : Colors.grey,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected 
                            ? Icons.radio_button_checked 
                            : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.cyan : Colors.grey,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          case_.suspects[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 24),
          
          // Submit Button
          if (selectedSuspect != null)
            Center(
              child: ElevatedButton(
                onPressed: _submitAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: Text(
                  'Solve Case',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildResultView(DetectiveCase case_) {
    final isCorrect = selectedSuspect == case_.correctIndex;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Result Icon
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            size: 100,
            color: isCorrect ? Colors.green : Colors.red,
          ),
          SizedBox(height: 16),
          
          // Result Text
          Text(
            isCorrect ? 'Case Solved!' : 'Case Unsolved',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 8),
          
          // Points
          if (isCorrect)
            Text(
              '+${case_.points} points',
              style: TextStyle(fontSize: 24, color: Colors.green),
            ),
          SizedBox(height: 24),
          
          // Correct Answer
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'The Answer:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  case_.suspects[case_.correctIndex],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          
          // Explanation
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explanation:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(case_.explanation, style: TextStyle(fontSize: 15)),
              ],
            ),
          ),
          SizedBox(height: 20),
          
          // Patent Info Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withOpacity(0.2),
                  Colors.blue.withOpacity(0.2)
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, color: Colors.cyan, size: 30),
                    SizedBox(width: 12),
                    Text(
                      'Patent Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(height: 30),
                _buildInfoRow('Patent', case_.patentInfo.patentNumber),
                _buildInfoRow('Inventor', case_.patentInfo.inventor),
                _buildInfoRow('Year', case_.patentInfo.year.toString()),
                _buildInfoRow('Title', case_.patentInfo.title),
                SizedBox(height: 16),
                Text(
                  'Innovation:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  case_.patentInfo.innovation,
                  style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          
          // Next Button
          ElevatedButton(
            onPressed: _nextCase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
            ),
            child: Text(
              currentCaseIndex < 9 ? 'Next Case' : 'See Final Results',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  void _submitAnswer() {
    final currentCase = cases[currentCaseIndex];
    final isCorrect = selectedSuspect == currentCase.correctIndex;
    
    if (isCorrect) {
      // Bonus points for using fewer clues
      final clueBonus = (5 - cluesRevealed) * 2;
      score += currentCase.points + clueBonus;
    }
    
    setState(() {
      showingResult = true;
    });
  }
  
  void _nextCase() {
    setState(() {
      currentCaseIndex++;
      cluesRevealed = 1;
      selectedSuspect = null;
      showingResult = false;
    });
  }
}
```

## 🎯 Benefits

✅ **Zero images needed** - Pure text-based gameplay
✅ **Uses brain power** - Deduction and reasoning skills
✅ **Educational** - Learn about real patents and inventors
✅ **Quick to implement** - Just JSON data and Flutter widgets
✅ **Engaging** - Detective theme makes it fun
✅ **Scalable** - Easy to add more cases
✅ **Small app size** - No asset bloat
✅ **Works offline** - No dependencies

## 🎮 Scoring System

- Base points per case (15-25 based on difficulty)
- Clue bonus: +2 points for each unused clue
- Example: If you solve with 2 clues, you get +6 bonus points (3 unused clues × 2)

## 📊 Difficulty Levels

- **Easy (15 pts)**: Common household items, obvious clues
- **Medium (20 pts)**: More specific items, requires thinking
- **Hard (25 pts)**: Complex inventions, subtle clues

## 🎨 UI Features

- Detective-themed colors (cyan, amber, blue)
- Case folder aesthetic
- Evidence/clue cards
- Suspect selection
- Patent information cards
- Progress tracking

## 📝 Content

30 cases covering:
- Office equipment
- Kitchen appliances
- Home electronics
- School supplies
- Medical devices
- Automotive safety
- Writing instruments
- Climate control
- Furniture

Each case teaches about real patents, inventors, and innovations!
