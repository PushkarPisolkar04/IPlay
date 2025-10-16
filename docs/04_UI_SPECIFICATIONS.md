# IPlay - Clean & Modern UI/UX Specifications
## 🎨 Card-Based, Minimal, Professional Design

**Design Inspiration:** Clean educational apps with card-based layouts  
**Target Audience:** Kids & Teens (10-18 years)  
**Design Philosophy:** Clean, Minimal, Card-focused, Professional yet Playful

---

## 1. Design System

### 1.1 Color Palette 🎨

```dart
// lib/core/constants/app_colors.dart
class AppColors {
  // PRIMARY BRAND COLORS
  static const primary = Color(0xFF7B68EE);      // Purple
  static const primaryDark = Color(0xFF5E4CC5);  // Darker purple
  static const primaryLight = Color(0xFF9B8FF5); // Light purple
  
  static const secondary = Color(0xFFFF6B35);    // Orange
  static const secondaryLight = Color(0xFFFF8F5C);
  
  static const accent = Color(0xFFFFC107);       // Yellow/Gold
  static const accentBlue = Color(0xFF2196F3);   // Blue
  
  // BACKGROUND COLORS
  static const background = Color(0xFFFFFFFF);   // Pure white
  static const backgroundGrey = Color(0xFFF5F7FA); // Very light grey
  
  // CARD COLORS (Solid, no gradients)
  static const cardPurple = Color(0xFF7B68EE);
  static const cardOrange = Color(0xFFFF6B35);
  static const cardYellow = Color(0xFFFFC107);
  static const cardBlue = Color(0xFF2196F3);
  static const cardGreen = Color(0xFF4CAF50);
  static const cardPink = Color(0xFFE91E63);
  static const cardTeal = Color(0xFF009688);
  static const cardIndigo = Color(0xFF3F51B5);
  
  // TEXT COLORS
  static const textPrimary = Color(0xFF2D3748);    // Dark grey
  static const textSecondary = Color(0xFF718096);  // Medium grey
  static const textTertiary = Color(0xFFA0AEC0);   // Light grey
  static const textWhite = Color(0xFFFFFFFF);      // White
  
  // SEMANTIC COLORS
  static const success = Color(0xFF4CAF50);        // Green
  static const warning = Color(0xFFFFC107);        // Yellow
  static const error = Color(0xFFFF5252);          // Red
  static const info = Color(0xFF2196F3);           // Blue
  
  // REALM COLORS (Solid colors for each realm)
  static const realmCopyright = Color(0xFFFF6B35);      // Orange
  static const realmTrademark = Color(0xFF2196F3);      // Blue
  static const realmPatent = Color(0xFF4CAF50);         // Green
  static const realmDesign = Color(0xFFE91E63);         // Pink
  static const realmGI = Color(0xFFFFC107);              // Yellow
  static const realmTradeSecret = Color(0xFF9C27B0);    // Purple
  
  // BORDERS & DIVIDERS
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEDF2F7);
  
  // SHADOWS (for cards)
  static BoxShadow cardShadow = BoxShadow(
    color: Color(0x1A000000),  // 10% black
    blurRadius: 20,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );
  
  static BoxShadow cardShadowHover = BoxShadow(
    color: Color(0x26000000),  // 15% black
    blurRadius: 30,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );
}
```

### 1.2 Typography

```dart
// Using "Inter" or "SF Pro" for clean, modern look
// Fallback: System default

class AppTextStyles {
  // HEADINGS
  static const h1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.5,
  );
  
  static const h2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const h3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  // BODY TEXT
  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );
  
  // BUTTON TEXT
  static const buttonLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    height: 1.2,
  );
  
  static const buttonMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    height: 1.2,
  );
  
  // LABELS
  static const label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.2,
    letterSpacing: 0.5,
  );
  
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.2,
  );
}
```

### 1.3 Spacing System

```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Card specific
  static const double cardPadding = 16.0;
  static const double cardRadius = 16.0;
  static const double cardSpacing = 12.0;
}
```

### 1.4 Border Radius

```dart
class AppRadius {
  static const small = BorderRadius.all(Radius.circular(8));
  static const medium = BorderRadius.all(Radius.circular(12));
  static const large = BorderRadius.all(Radius.circular(16));
  static const xlarge = BorderRadius.all(Radius.circular(24));
  static const round = BorderRadius.all(Radius.circular(9999));
}
```

---

## 2. Common Widgets

### 2.1 Clean Card Widget

```dart
class CleanCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.background,
        borderRadius: AppRadius.large,
        boxShadow: [AppColors.cardShadow],
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

### 2.2 Primary Button

```dart
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool fullWidth;
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.large,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Text(text, style: AppTextStyles.buttonLarge),
      ),
    );
  }
}
```

### 2.3 Avatar Widget

```dart
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final bool showOnlineBadge;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.backgroundGrey,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Stack(
        children: [
          // Avatar image or initials
          Center(
            child: imageUrl != null
                ? ClipOval(child: Image.network(imageUrl!))
                : Text(initials, style: AppTextStyles.h2),
          ),
          // Online badge
          if (showOnlineBadge)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### 2.4 Progress Bar

```dart
class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color? color;
  final double height;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: color ?? AppColors.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
```

### 2.5 Top Bar with Avatar Only (Like Reference)

```dart
class TopBarWithAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool showOnlineBadge;
  final VoidCallback? onAvatarTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null 
                      ? NetworkImage(avatarUrl!) 
                      : null,
                  backgroundColor: AppColors.secondary,  // Orange
                  child: avatarUrl == null 
                      ? Text('A', style: AppTextStyles.h3.copyWith(color: Colors.white))
                      : null,
                ),
                if (showOnlineBadge)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,  // Green dot
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 2.6 Bottom Navigation (5 Icons, No Labels - Like Reference)

```dart
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home,  // Home
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.book_outlined,  // Learn
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.sports_esports_outlined,  // Play
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.leaderboard_outlined,  // Leaderboard
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_outline,  // Profile
            isSelected: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
```

---

## 3. Screen Layouts

### 3.1 Home Screen 🏠 (Like Reference Image)

```
┌─────────────────────────────────┐
│                           [👤]● │ ← Avatar with green badge (top right)
│                                 │
│ Good Afternoon!                 │ ← Greeting (bold, h1)
│ Arslan Mohamed                  │ ← Name (orange color, h3)
│                                 │
│ ┌───────────────────────────┐   │
│ │ [Illustration: IPR Book]  │   │ ← Featured card (orange bg, rounded)
│ │                           │   │   with custom illustration
│ │ Continue                  │   │ ← White text
│ │ Learning                  │   │
│ │ IPR                       │   │
│ │                           │   │
│ │ [Learn More]              │   │ ← White button (rounded)
│ └───────────────────────────┘   │
│                                 │
│ My Learning Activity [View All] │ ← Section header (black + orange)
│                                 │
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │🔴   │ │🔵   │ │🟢   │        │ ← Small cards (horizontal scroll)
│ │Copy │ │Trade│ │Pat  │        │   (orange, purple, blue)
│ │80%  │ │45% │ │20%  │        │   with icons
│ └─────┘ └─────┘ └─────┘        │
│                                 │
│ Popular This Week!   [View All] │ ← Section header
│                                 │
│ ┌───────────────────────────┐   │
│ │ [🎯] Copyright Realm      │   │ ← List item with icon (white card)
│ │ Suitable For 10 To 13     │   │   rounded corners, shadow
│ │ 6 Levels          [Free]♡ │   │ ← Green badge + heart
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ [📘] Trademark Realm      │   │ ← Another item
│ │ Suitable For 10 To 13     │   │
│ │ 6 Levels          [Free]♡ │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌───────────────────────────┐   │
│ │ [🔬] Patent Realm         │   │
│ │ Suitable For 10 To 13     │   │
│ │ 8 Levels         [Free]♡  │   │
│ └───────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
│ [🏠] [📚] [🎮] [🏆] [👤]       │ ← Bottom nav (5 icons)
└─────────────────────────────────┘
```

**Key Elements (Matching Reference):**
- ✅ Avatar with green online badge at **top right**
- ✅ No search bar (skipped)
- ✅ Large greeting text at top left
- ✅ Orange featured card with illustration and white "Learn More" button
- ✅ Section headers with "View All" links (orange color)
- ✅ Horizontal scrolling activity cards (colored, small)
- ✅ List items with:
  - Circle icon on left
  - Title and subtitle
  - Badge (Free/Premium) on bottom right
  - Heart icon on far right
  - White card background with shadow
- ✅ Bottom navigation with 5 icons (no labels)
- ✅ Clean white background
- ✅ Rounded corners everywhere (16px)
- ✅ Card shadows for depth

### 3.2 Learn Screen (Realm List) 📚

```
┌─────────────────────────────┐
│ ← Learn IPR                 │ ← App bar
│─────────────────────────────│
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔍 Search realms...     │ │ ← Search bar
│ └─────────────────────────┘ │
│                             │
│ Your Progress               │
│ ┌─────────────────────────┐ │
│ │ Overall: 45% Complete   │ │ ← Progress card
│ │ ████████░░░░░░░         │ │
│ │ 3/6 Realms • 870 XP     │ │
│ └─────────────────────────┘ │
│                             │
│ All Realms (6)              │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔴 Copyright Realm      │ │ ← Realm card (orange bg)
│ │                         │ │
│ │ Protect creative works  │ │
│ │ 6 levels • 450 XP       │ │
│ │                         │ │
│ │ ████████░░ 80%          │ │
│ │ [Continue →]            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔵 Trademark Realm      │ │ ← Realm card (blue bg)
│ │                         │ │
│ │ Brand protection        │ │
│ │ 6 levels • 420 XP       │ │
│ │                         │ │
│ │ ████░░░░░░ 45%          │ │
│ │ [Continue →]            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🟢 Patent Realm         │ │ ← Realm card (green bg)
│ │                         │ │
│ │ Innovation protection   │ │
│ │ 8 levels • 600 XP       │ │
│ │                         │ │
│ │ ██░░░░░░░░ 20%          │ │
│ │ [Start →]               │ │
│ └─────────────────────────┘ │
│                             │
│ (3 more realms...)          │
│                             │
└─────────────────────────────┘
```

### 3.3 Realm Detail Screen

```
┌─────────────────────────────┐
│ ←  Copyright Realm     [↓]  │ ← Header with download
│─────────────────────────────│
│                             │
│    [Illustration/Image]     │ ← Realm illustration
│                             │
│ ┌─────────────────────────┐ │
│ │ Your Progress           │ │ ← Stats card
│ │ ████████░░ 80%          │ │
│ │ 5/6 levels • 700/850 XP │ │
│ └─────────────────────────┘ │
│                             │
│ About                       │
│ Learn about copyright law,  │
│ fair use, and how to        │
│ protect creative works.     │
│                             │
│ Levels (6)                  │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✓ Level 1               │ │ ← Completed (green)
│ │ What is Copyright?      │ │
│ │ 100 XP • ⭐⭐⭐⭐⭐      │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ✓ Level 2               │ │ ← Completed
│ │ Types of Copyright      │ │
│ │ 120 XP • ⭐⭐⭐⭐        │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ ▶ Level 3               │ │ ← Current (orange)
│ │ Copyright Duration      │ │
│ │ 0/150 XP                │ │
│ │ [Start →]               │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🔒 Level 4              │ │ ← Locked (grey)
│ │ Fair Use Doctrine       │ │
│ │ Complete Level 3 first  │ │
│ └─────────────────────────┘ │
│                             │
│ (2 more levels...)          │
│                             │
│ [Download Offline]          │ ← Download button
│                             │
└─────────────────────────────┘
```

### 3.4 Level Content Screen

```
┌─────────────────────────────┐
│ ← Level 3: Copyright Dur... │
│ ████░░░░░░░░░░░░ 25%        │ ← Progress bar
│─────────────────────────────│
│                             │
│ [Scrollable Content]        │
│                             │
│ # Copyright Duration        │ ← h1
│                             │
│ Copyright protection lasts  │ ← body text
│ for a specific period of    │
│ time before works enter the │
│ public domain.              │
│                             │
│    [Illustration/Image]     │ ← Content image
│                             │
│ ## Key Points               │ ← h2
│                             │
│ • Lifetime + 60 years       │ ← bullet points
│ • Anonymous: 60 years       │
│ • Applies from creation     │
│                             │
│ [Video Player]              │ ← Optional video
│ ▶ Watch: Duration Explained │
│ 3:45                        │
│                             │
│ ## Did You Know?            │ ← info box
│ ┌─────────────────────────┐ │
│ │ ℹ️ In India, copyright  │ │
│ │ lasts for the lifetime  │ │
│ │ of the author plus 60   │ │
│ │ years after death.      │ │
│ └─────────────────────────┘ │
│                             │
│ (More content...)           │
│                             │
│ [Take Quiz →]               │ ← Primary button
│                             │
└─────────────────────────────┘
```

### 3.5 Quiz Screen

```
┌─────────────────────────────┐
│ ← Quiz                [⏱ 45]│ ← Timer
│─────────────────────────────│
│                             │
│ Question 3 of 5             │ ← Progress
│ ●●●○○                       │
│                             │
│ ┌─────────────────────────┐ │
│ │                         │ │ ← Question card
│ │ How long does copyright │ │
│ │ protection last in      │ │
│ │ India?                  │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ A. 50 years             │ │ ← Option (white)
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ B. Lifetime + 60 years  │ │ ← Selected (purple)
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ C. 100 years            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ D. Forever              │ │
│ └─────────────────────────┘ │
│                             │
│ [Next Question →]           │ ← Button (bottom)
│                             │
└─────────────────────────────┘
```

### 3.6 Quiz Results Screen

```
┌─────────────────────────────┐
│                             │
│      🎉 Excellent!          │ ← Large text
│                             │
│ ┌─────────────────────────┐ │
│ │                         │ │ ← Results card (white)
│ │   ⭐ ⭐ ⭐ ⭐ ⭐         │ │
│ │                         │ │
│ │   You scored 5/5!       │ │
│ │                         │ │
│ │   +150 XP earned        │ │
│ │                         │ │
│ │ ┌─────────────────────┐ │ │
│ │ │ 🏆 Perfect Score!   │ │ │ ← Badge unlock
│ │ │ Badge unlocked      │ │ │
│ │ └─────────────────────┘ │ │
│ │                         │ │
│ │ Level Progress:         │ │
│ │ ████████████ 100%       │ │
│ │                         │ │
│ │ Current Streak: 🔥 8    │ │
│ │                         │ │
│ └─────────────────────────┘ │
│                             │
│ [Next Level →]              │ ← Primary button
│ [Share Result]              │ ← Secondary button
│                             │
└─────────────────────────────┘
```

### 3.7 Play Screen (Games Hub) 🎮

```
┌─────────────────────────────┐
│ Play Games                  │
│─────────────────────────────│
│                             │
│ ┌─────────────────────────┐ │
│ │ 🏆 Your Best Scores     │ │ ← Stats card
│ │ 3,450 Total Game XP     │ │
│ │ 7 Games Played          │ │
│ └─────────────────────────┘ │
│                             │
│ All Games (7)               │
│                             │
│ ┌───────────┐ ┌───────────┐ │
│ │ 🧠        │ │ 🃏        │ │ ← Game cards (2 col)
│ │ IPR Quiz  │ │ Memory    │ │   (purple/orange)
│ │ Master    │ │ Match     │ │
│ │           │ │           │ │
│ │ Best: 850 │ │ Best: 120 │ │
│ │ [Play →]  │ │ [Play →]  │ │
│ └───────────┘ └───────────┘ │
│                             │
│ ┌───────────┐ ┌───────────┐ │
│ │ 🔍        │ │ 🏃        │ │
│ │ Spot the  │ │ IP        │ │
│ │ Original  │ │ Defender  │ │
│ │           │ │           │ │
│ │ Best: 600 │ │ Best: 750 │ │
│ │ [Play →]  │ │ [Play →]  │ │
│ └───────────┘ └───────────┘ │
│                             │
│ (3 more games...)           │
│                             │
└─────────────────────────────┘
```

### 3.8 Leaderboard Screen 🏆

```
┌─────────────────────────────┐
│ Leaderboard                 │
│─────────────────────────────│
│                             │
│ [Class][School][State][🇮🇳] │ ← Filter chips
│                             │
│ ┌─────────────────────────┐ │
│ │ Your Rank: #42          │ │ ← User rank card
│ │ 1,250 XP • 5 Badges     │ │   (purple bg)
│ └─────────────────────────┘ │
│                             │
│ Top 3                       │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │  🥈  │ │  🥇  │ │  🥉  │ │ ← Podium
│ │ Rahul│ │Priya │ │Anita │ │
│ │3,200 │ │3,450 │ │3,100 │ │
│ └──────┘ └──────┘ └──────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 4. Amit K.    2,950 XP  │ │ ← List items
│ │ 🏅 11 badges            │ │   (white cards)
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 5. Sneha P.   2,800 XP  │ │
│ │ 🏅 9 badges             │ │
│ └─────────────────────────┘ │
│                             │
│ (More ranks 6-100...)       │
│                             │
└─────────────────────────────┘
```

### 3.9 Profile Screen 👤

```
┌─────────────────────────────┐
│ ←  Profile            [⚙️]  │ ← Header
│─────────────────────────────│
│                             │
│    ┌─────────────────┐      │
│    │   [Avatar]      │      │ ← Large avatar (120px)
│    │     (AK)        │      │
│    └─────────────────┘      │
│                             │
│  Arslan Mohamed             │ ← Name (h1)
│  Grade 8 • Delhi            │ ← Details (caption)
│                             │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │ 🔥 7 │ │ 🏅 12│ │ ⭐ 5 │ │ ← Stats cards
│ │Streak│ │Badges│ │Certs │ │
│ └──────┘ └──────┘ └──────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ Level 5                 │ │ ← Level card (purple)
│ │ ████████░░░░ 1,250 XP   │ │
│ │ 350 XP to Level 6       │ │
│ └─────────────────────────┘ │
│                             │
│ My Realms                   │
│ ┌─────────────────────────┐ │
│ │ 🔴 Copyright    ████ 80%│ │ ← Realm progress list
│ │ 🔵 Trademark    ██░░ 45%│ │
│ │ 🟢 Patent       █░░░ 20%│ │
│ │ 🔴 Design       ░░░░  0%│ │
│ └─────────────────────────┘ │
│                             │
│ My Badges (12)      [View >]│
│ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│ │🏅 │ │⚡ │ │🔥 │ │🎯 │   │ ← Badge grid
│ └───┘ └───┘ └───┘ └───┘   │
│                             │
│ Certificates (5)    [View >]│
│ ┌─────────────────────────┐ │
│ │ 📜 Copyright Realm      │ │ ← Certificate list
│ │ Completed Oct 10, 2025  │ │
│ │ [Download PDF]          │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

### 3.10 Settings Screen ⚙️

```
┌─────────────────────────────┐
│ ← Settings                  │
│─────────────────────────────│
│                             │
│ Account                     │ ← Section header
│ ┌─────────────────────────┐ │
│ │ 👤 Edit Profile         │ │ ← Setting item
│ │ Update your info        │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🔒 Privacy & Security   │ │
│ │ Control visibility      │ │
│ └─────────────────────────┘ │
│                             │
│ App                         │
│ ┌─────────────────────────┐ │
│ │ 🔔 Notifications        │ │
│ │ Manage alerts           │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 📥 Downloaded Content   │ │
│ │ 2.4 GB stored           │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🌐 Language             │ │
│ │ English                 │ │
│ └─────────────────────────┘ │
│                             │
│ Legal & Help                │
│ ┌─────────────────────────┐ │
│ │ ℹ️ About IPlay          │ │
│ │ Version 1.0.0           │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 📜 Terms & Conditions   │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 🔐 Privacy Policy       │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 💬 Help & Support       │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │ 🚪 Logout               │ │ ← Danger zone (red text)
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

---

## 4. Animations & Interactions

### 4.1 Card Tap Animation
```dart
- Scale: 1.0 → 0.98 (100ms)
- Shadow: Reduce slightly
- Haptic feedback: Light impact
- On release: Spring back to 1.0
```

### 4.2 Button Press
```dart
- Scale: 1.0 → 0.95 (100ms)
- Haptic feedback: Medium impact
- On release: Spring back
```

### 4.3 Page Transitions
```dart
- Slide from right (300ms, ease-out)
- Fade in (200ms)
- Previous page slides left slightly
```

### 4.4 Bottom Nav Selection
```dart
- Selected icon: Scale 1.2x + color change
- Icon transition: 200ms ease
- Label fade in/out
```

### 4.5 XP Counter Animation
```dart
- Count up from old to new value (1000ms)
- Easing: Ease-out cubic
- Haptic at milestones
```

### 4.6 Badge Unlock
```dart
1. Fullscreen overlay (fade in)
2. Badge scales in (0 → 1.2 → 1.0, elastic)
3. Particle effects around badge
4. Name fades in below
5. Confetti falls
6. Haptic: Success pattern
```

---

## 5. Responsive Breakpoints

### Mobile (320px - 768px)
- Single column layout
- Full-width cards
- Bottom navigation visible
- 16px margin

### Tablet (768px - 1024px)
- Two-column grid for cards
- Larger text sizes (+10%)
- 24px margin
- Floating bottom nav

### Desktop (1024px+)
- Max width: 1200px (centered)
- Three-column grid
- Side navigation instead of bottom
- 32px margin

---

## 6. Accessibility

### Color Contrast
- Text on white: WCAG AAA (7:1)
- Button text: WCAG AA (4.5:1)
- Icons: Minimum 3:1

### Touch Targets
- Minimum: 48x48 dp
- Buttons: 48 dp height
- Icons: 44x44 dp clickable area

### Screen Reader Support
- All images have alt text
- Buttons have semantic labels
- Proper heading hierarchy
- Form fields have labels

---

## 7. Dark Mode (Optional - Phase 2)

```dart
// Future implementation
class AppColorsDark {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const primary = Color(0xFF9B8FF5);
  // ... more dark colors
}
```

---

**This clean, card-based design focuses on content and usability while maintaining visual appeal through thoughtful use of color and spacing.** 🎨✨


