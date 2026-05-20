# SolRank — Product Specification Document
**Version:** 1.0 (Beta Scope)  
**Last Updated:** May 2026  
**Repository:** https://github.com/DothrakiSpyware/SolRank  
**Platform:** iOS 17+  
**Stack:** Swift + SwiftUI + Firebase  

---

## Table of Contents
1. [The Problem](#1-the-problem)
2. [The Vision](#2-the-vision)
3. [Target Users](#3-target-users)
4. [Core Concept](#4-core-concept)
5. [XP Categories & Stat System](#5-xp-categories--stat-system)
6. [Feature List — Beta](#6-feature-list--beta)
7. [Screen Map](#7-screen-map)
8. [User Flows](#8-user-flows)
9. [Challenges](#9-challenges)
10. [Leagues](#10-leagues)
11. [Points Economy](#11-points-economy)
12. [Character System](#12-character-system)
13. [Social Feed](#13-social-feed)
14. [Home Screen & Logging](#14-home-screen--logging)
15. [Notifications](#15-notifications)
16. [Visual & UX Direction](#16-visual--ux-direction)
17. [Data & Backend Overview](#17-data--backend-overview)
18. [What Is NOT In Beta](#18-what-is-not-in-beta)
19. [Future Roadmap](#19-future-roadmap)

---

## 1. The Problem

Competing with friends on real-life goals — fitness, reading, healthy habits — starts fun but dies fast. The tracking becomes tedious, the spreadsheets get abandoned, the group chat goes quiet. There is no single place that combines the accountability of shared tracking, the motivation of real-time competition, and the reward loop that makes you want to keep going. Existing apps either track one thing well (Strava for running, Goodreads for books) or are so generic they feel like homework. Nothing makes self-improvement feel like a game you actually want to play.

---

## 2. The Vision

SolRank is a real-life RPG. Your daily actions — pushups, pages read, skipping cigarettes, going to bed on time — level up a pixel-art character that represents you. You compete against friends in structured challenges and leagues, wager points, climb leaderboards, and watch your character grow stronger as you do. The app should feel like Runescape meets Strava meets Duolingo. It is competitive, personal, visual, and fast to use. Opening the app and logging something should take under 5 seconds. Seeing a friend pull ahead in a challenge should make you want to put the phone down and go do something about it.

---

## 3. Target Users

**Beta (now):** A small closed friend group. iOS only. Known users, invite-based access.  
**V2:** Public launch, open registration, public leagues, global feed.  
**Long term:** Any person who wants to turn personal improvement into a competitive social experience.

---

## 4. Core Concept

Every user has a **Character** — a pixel-art avatar that mirrors their real-life self. The character has a set of **hardlocked XP stats** (Strength, Endurance, Wisdom, Discipline, Willpower, Vitality) that level up as the user logs real-life actions. Log pushups → Strength XP increases. Read pages → Wisdom XP increases. Avoid smoking → Willpower XP increases.

Users compete in two formats:
- **Challenges** — short, focused, 1v1 or small group, single or multi-stat (max 3), with a defined goal and end date. Points can be wagered.
- **Leagues** — longer running, group competitions with customizable stats, point values, prize structures, and optional entry wagers. Leaderboard shows live rankings.

A **social feed** shows friends' activity in real time — what they logged, XP gained, level ups, challenge updates. This feed is the engine of social accountability.

A **points economy** rewards winning and consistency. Points are a universal wallet balance used for wagering in challenges and leagues, and eventually for purchasing cosmetic items.

---

## 5. XP Categories & Stat System

### Hardlocked XP Categories
These six categories exist on every character by default and cannot be removed. Their XP rates are fixed by the app and cannot be manipulated by users.

| Category | Icon | What Feeds It | Description |
|---|---|---|---|
| Strength | 💪 | Pushups, situps, lifting, strength training sessions | Physical power and muscle-based effort |
| Endurance | 🏃 | Miles run, miles walked, steps, cardio sessions | Cardiovascular and stamina-based effort |
| Wisdom | 📖 | Pages read, languages practiced, educational content | Mental growth, learning, and knowledge |
| Discipline | 🔥 | Daily streaks, completing commitments, finishing goals | Consistency and follow-through over time |
| Willpower | 🧠 | No smoking, bed on time, no coffee, screen time limits | Resistance, restraint, and saying no |
| Vitality | ❤️ | Ate healthy, hydration, general wellness logs | Overall health and body care |

### Hardlocked Preloaded Stats
These stats are native to the app, tied to their XP category, and have fixed XP values per unit. Every user has access to them. Users do not need to track all of them — they select which ones to personally track. Examples:

**Strength:** Pushups (per rep), Situps (per rep), Did I strength train today? (boolean)  
**Endurance:** Miles Run (per mile), Miles Walked (per mile), Steps (per 1000), Did I do cardio today? (boolean)  
**Wisdom:** Pages Read (per page), Did I study/learn today? (boolean), Minutes of educational content (per minute)  
**Discipline:** Daily streak maintained (per day), Challenge completed (per completion)  
**Willpower:** No smoking today (boolean), In bed by goal time (boolean), No coffee today (boolean), Met screen time goal (boolean)  
**Vitality:** Ate healthy today (boolean), Drank enough water (boolean)

### Custom Stats
Users can create custom stats beyond the preloaded list. Custom stats work as follows:

- Created by the user on their Character page
- Have a name, tracking type (numeric or boolean), and unit (if numeric)
- **Do NOT feed into hardlocked XP categories.** This is intentional — it prevents users from gaming their character level.
- If the user wants XP tied to a custom stat, they must create a **Custom XP Bar**
- Custom XP Bars are personal, visible only on the user's own character sheet, and do not affect hardlocked category levels
- Flow: Create Stat → "Tie to XP?" → Yes → Create new Custom XP Bar or select existing one → Set XP per unit

### Custom XP Bars
- Fully personal, not comparable between users
- Named by the user (e.g. "Cold Plunge Score", "My Reading Streak")
- Appear on the character page below hardlocked stats
- Can be featured on the home screen for logging
- Future feature: users can submit a custom stat + XP proposal for app review to become a hardlocked native stat

### Stat Types
Two types exist for all stats (hardlocked and custom):

- **Numeric** — user logs a number. Adds to a running total. Example: 50 pushups. Has a daily value and a lifetime total.
- **Boolean/Streak** — user logs yes or no for today. Builds a streak counter. Example: Did I smoke today? No = +1 streak day.

### Daily vs Lifetime Values
Every numeric stat tracks both:
- **Daily Value** — what was logged today. Resets at midnight. Used for daily challenge scoring and home screen display.
- **Lifetime Total** — all time accumulated value. Drives XP and character level. Never resets.

---

## 6. Feature List — Beta

| Feature | Included in Beta |
|---|---|
| Sign in with Apple | ✅ |
| Sign in with Google | ✅ |
| Persistent login (no re-auth) | ✅ |
| Character creation with pixel avatar | ✅ |
| Hardlocked XP categories | ✅ |
| Preloaded stat selection (onboarding) | ✅ |
| Custom stats | ✅ |
| Custom XP bars | ✅ |
| Home screen customizable logging | ✅ |
| Quick log buttons (configurable increment) | ✅ |
| 1v1 and small group Challenges | ✅ |
| Multi-stat Challenges (max 3 stats) | ✅ |
| Challenge wager system | ✅ |
| Points Race Leagues | ✅ |
| League leaderboards | ✅ |
| League entry wager | ✅ |
| Friends system (username/ID, accept/decline) | ✅ |
| Friends-only social feed | ✅ |
| Feed reactions and comments | ✅ |
| Push notifications (customizable) | ✅ |
| Character page with stat sheet | ✅ |
| Points wallet | ✅ |
| Settings and profile customization | ✅ |

---

## 7. Screen Map

### Bottom Navigation (5 tabs, left to right)
1. **Feed** — Social feed
2. **Compete** — Challenges and Leagues
3. **Home** — Quick log, daily overview (default tab on open)
4. **Character** — Character sheet, stats, gear
5. **Profile/Settings** — Account, preferences, customization

### Detail Screens (accessed from main tabs)
- Challenge Detail — full stats, wand duel progress bar, history
- Create Challenge — setup flow
- League Detail — leaderboard, stats breakdown, member list
- Create League — full setup flow
- Stat Detail — lifetime graph, daily history, XP progress
- Create/Edit Stat — stat type, tracking method, XP tie
- Character Editor — avatar customization
- Friend Profile — their character, public stats, shared competitions
- Friend Search — find by username or ID
- Notification Settings — per league, per challenge, per friend
- Log Editor — manual correction of logged entries

---

## 8. User Flows

### First Launch / Onboarding
1. Welcome screen — SolRank logo, tagline, Sign in with Apple, Sign in with Google, Email option
2. Auth completes → new user detected → onboarding begins
3. **Step 1 — Create Your Character**
   - Choose character head (10-15 pixel art options)
   - Choose shirt, pants, shoes (5-10 options each)
   - Enter character name
4. **Step 2 — Choose Your Stats**
   - Shown list of preloaded stats grouped by category
   - Select 1-5 to track (can add more later)
   - Each shows name, category, tracking type
5. **Step 3 — (Optional) Add Friends**
   - Search by username or ID
   - Skip option prominent
6. **Step 4 — (Optional) Join a League or Challenge**
   - Shown any open public leagues or pending challenge invites
   - Skip option prominent
7. Land on Home screen

### Returning User Launch
- App opens directly to Home screen. No login screen. No friction.

### Logging a Stat (under 5 seconds)
1. Open app → Home screen
2. Tap quick-log button for desired stat
3. Value increments by configured amount
4. Optional: adjust value before confirming
5. Confirm → stat logged → feed event auto-generated → XP updated

### Creating a Challenge
1. Tap + on Compete tab or Home screen
2. Select "Challenge"
3. Set: Title, select stat(s) (max 3), set goal value or time limit, set end date, invite participants (search friends), set wager amount (optional, 0 by default)
4. Invited friends receive notification and must accept
5. Points deducted from all participants at acceptance
6. Challenge goes live on start date

### Creating a League
1. Tap + on Compete tab or Home screen
2. Select "League"
3. See League Creation Flow (Section 10)

---

## 9. Challenges

### Overview
Challenges are short, focused competitions between 2 or more users on 1-3 stats with a defined goal or time limit and a clear winner.

### Rules
- **Participants:** 2 minimum, small group (suggested cap: 10)
- **Stats:** 1 to 3 hardlocked or custom stats per challenge
- **Goal types:** Reach a target value first (e.g. first to 100 pushups) OR most accumulated value by end date
- **End condition:** End date reached, or goal reached by all participants
- **Winner:** Highest value at end date, or first to reach goal

### Wager System
- Creator sets a wager amount in points (can be 0)
- All participants must have sufficient points to enter
- Points are deducted from wallet at time of challenge acceptance (escrow)
- Winner receives all wagered points
- If tied: points returned to all participants
- If participant does not accept: no deduction

### UI — The Wand Duel Bar
On the Challenge Detail screen, the primary visual is a head-to-head progress bar styled like a Harry Potter wand duel. The bar is split in two — each side represents a participant (or team). Whoever is leading pushes the bar toward the opponent's side. In group challenges this becomes a ranked bar. This is the most important UI element in the app and should be the most polished thing in beta.

### Challenge Feed Events
Auto-generated feed posts when:
- Challenge is created and accepted
- A participant takes the lead
- A participant completes the goal
- Challenge ends with a winner declared

---

## 10. Leagues

### Overview
Leagues are longer-running group competitions with customizable structure, multiple stats, and live leaderboards. Think fantasy football season. Beta supports Points Race format only.

### Points Race Format
All participants accumulate points over the league duration based on their logged stats. Points are awarded per unit logged according to the league's custom point values. Leaderboard shows live rankings. Winner is whoever has the most points when the league ends (or at any point if no end date).

### League Creation Fields
| Field | Type | Notes |
|---|---|---|
| League Name | Text | Required |
| Description | Text | Optional |
| Private or Public | Toggle | Private = invite only. Public = anyone can join (beta: invite only recommended) |
| Stats Included | Multi-select | Choose from hardlocked preloaded stats or creator's custom stats |
| Points per unit per stat | Numeric per stat | e.g. 1 pushup = 1 pt, "did I strength train" = 50 pts, 1 page read = 2 pts |
| Start Date | Date picker | Required |
| End Date | Date picker | Optional — can run indefinitely |
| Prize Structure | Select | Winner takes all / Top 3 split (60/30/10) / No points awarded |
| Entry Wager | Numeric | Optional, 0 by default. Deducted at join, awarded at end per prize structure |
| Max Participants | Numeric | Optional cap |

### League Leaderboard
- Live, updates in real time as stats are logged
- Shows: rank, character avatar, username, total points, stat breakdown
- Tapping a participant opens their Friend Profile
- Creator can view detailed stat logs per participant

### League Feed Events
Auto-generated when:
- A participant takes or loses first place
- League starts or ends
- A participant hits a point milestone
- Someone joins the league

---

## 11. Points Economy

### Overview
Points are a single universal currency tied to every user's account. They represent competitive standing, reward winning, and will eventually enable cosmetic purchases.

### Earning Points
- Winning a Challenge — receive wagered points from all losers
- League prize — distributed per prize structure at league end
- Future: daily login bonus, achievement unlocks, streak rewards

### Losing Points
- Losing a Challenge — wagered points transferred to winner
- League entry wager — distributed to winners at end

### Rules
- Minimum balance is 0. Cannot go negative.
- Points are deducted at time of joining a wagered challenge or league (escrow)
- If a challenge or league is cancelled by the creator, all escrowed points are returned
- Starting balance for new users: TBD (suggest 100 points to allow immediate participation)

### Future Use
- Cosmetics shop — purchase character gear, avatar items, emotes
- Milestone rewards — bonus points for hitting character level thresholds

---

## 12. Character System

### Overview
The character is the user's RPG identity within SolRank. It has a visual appearance, a stat sheet, and a level. It is its own dedicated screen — not just a profile picture. The character grows as the user does in real life.

### Visual Appearance
Created during onboarding, editable anytime from the Character page.

Customization slots:
- Head / Face (10-15 pixel art options)
- Shirt (5-10 options)
- Pants (5-10 options)
- Shoes (5-10 options)
- Future: hair, accessories, armor, weapons (unlockable)

Style: 8-bit pixel art. Stardew Valley / early Runescape aesthetic. Characters should look distinct and personal, not generic.

### Character Stat Sheet
Displayed RuneScape style — a grid or list of the 6 hardlocked XP categories, each showing:
- Category icon and name
- Current level (1-99 scale, RuneScape inspired)
- XP progress bar toward next level
- Total lifetime XP in that category

Below hardlocked stats: any Custom XP Bars the user has created, displayed in the same format.

### Character Level
An overall character level derived from the sum of all hardlocked XP category levels. Displayed prominently on the character page and in the social feed. This is the primary bragging rights number.

### Gear Unlocks (Milestone Based)
At certain stat level milestones, cosmetic gear is unlocked. Examples:
- Strength Level 10 → Iron Gauntlets unlocked
- Endurance Level 20 → Running Shoes unlocked
- Wisdom Level 15 → Scholar's Cape unlocked
- Overall Level 50 → Exclusive title unlocked

Exact milestones and gear to be designed in a separate asset document. For beta: define the system and unlock 3-5 milestone rewards to prove the concept.

### Character Page Layout
- Top: character sprite (large, animated idle if possible)
- Character name, overall level, points balance
- Stat sheet grid (hardlocked categories)
- Custom XP bars (if any)
- Tracked stats list with daily and lifetime values
- Add Stat button
- Edit Character button (opens avatar customization)

---

## 13. Social Feed

### Overview
A real-time activity feed showing friends' logged actions, XP gains, level ups, and competition updates. Styled after Strava's feed. Beta is friends-only. Public global feed is post-beta.

### Feed Event Types
| Type | Example Post |
|---|---|
| Stat logged | "Jake logged 50 pushups. +50 Strength XP" |
| Level up | "Jake reached Strength Level 8! 💪" |
| Challenge update | "Jake took the lead in Pushup War" |
| Challenge won | "Jake won the Pushup War challenge! 🏆" |
| League milestone | "Jake hit 500 points in March Fitness League" |
| Streak milestone | "Jake is on a 7-day Willpower streak 🔥" |
| Custom | User-written post (optional manual post) |

### Feed Post Structure
Each post shows:
- Character pixel avatar (tappable → Friend Profile)
- Username
- Event description
- XP gained (if applicable)
- Current level or stat value
- Timestamp
- Reaction button (🔥 minimum, expand to emoji set later)
- Comment button (opens comment thread)

### Feed Filters
- All Friends (default)
- Just Me
- Specific Friend
- By Category (Strength, Wisdom, etc.)

### Real-Time
Feed updates in real time using Firestore listeners. No pull-to-refresh required, though it should be supported as a fallback.

---

## 14. Home Screen & Logging

### Overview
The Home screen is the default screen on app open. Its primary job is to make logging fast — under 5 seconds from open to logged. Everything else is secondary.

### Layout
- **Top section:** Quick log buttons — large, tappable, customized by user
- **Middle section:** Current challenge status summary (active challenges at a glance)
- **Bottom section:** Today's summary — daily values for tracked stats, streak statuses
- **Floating + button:** Create new challenge or league

### Quick Log Buttons
Each tracked stat can have a quick log button on the home screen. The user configures:
- Which stats appear as buttons
- The increment per tap (e.g. tap = +10 pushups, or tap = +1 mile)
- Button layout order

Tapping a button logs the increment immediately with a confirmation animation. User can tap multiple times. Long press or secondary button opens a manual entry field to log a specific value.

### Boolean Stats on Home Screen
Boolean stats (yes/no) appear as toggle buttons or swipe sliders. Example: "No Smoking Today" shows as a slider: No ←——→ Yes. Once set to Yes, it locks for the day with option to undo within a time window.

### Manual Correction
From the home screen or stat detail page, users can edit previously logged entries within a reasonable time window (suggest 24 hours). Editing older entries requires going to the Stat Detail page. This prevents retroactive cheating in competitions.

### Today's Overview
Below quick log buttons, a summary row shows each tracked stat:
- Daily value logged so far
- Daily goal progress bar (if goal is set)
- Streak status for boolean stats

---

## 15. Notifications

### Notification Types
| Trigger | Example |
|---|---|
| Friend logs a stat | "Jake just logged 30 pushups 💪" |
| You are losing a challenge | "You're down 15 pushups in Pushup War" |
| You are winning a challenge | "You're leading by 20 in Pushup War 🔥" |
| Challenge accepted | "Jake accepted your pushup challenge" |
| Challenge ending soon | "Pushup War ends in 24 hours" |
| Challenge result | "You won Pushup War! +50 points" |
| League update | "You moved to 1st in March Fitness League!" |
| League ending soon | "March Fitness League ends in 3 days" |
| Friend request received | "Jake wants to add you on SolRank" |
| Level up | "Your Strength just hit Level 9! 💪" |
| Streak at risk | "Log your Willpower stat before midnight to keep your streak" |

### Customization
All notification types are opt-in/opt-out individually. Settings are accessible:
- Globally in Settings/Profile tab
- Per league (within league settings)
- Per challenge (within challenge settings)
- Per friend (within friend profile)

---

## 16. Visual & UX Direction

### Aesthetic
- **Style:** 8-bit pixel art. Stardew Valley / early RuneScape visual language.
- **Feel:** Warm, playful, competitive but not aggressive. This is friendly rivalry, not toxic gaming.
- **Characters:** Chunky pixel sprites, expressive despite simplicity. Clear silhouettes.
- **UI:** Clean and modern app chrome (SwiftUI native components) contrasted with pixel art character/stat elements. The pixel art lives inside a clean modern app, not a retro game interface.

### Color Direction
- Dark mode first (feels more game-like)
- Rich accent colors per XP category (e.g. red for Strength, blue for Wisdom, green for Vitality)
- Gold for points, levels, and achievements
- Avoid flat/corporate color palettes — this should feel alive

### Motion & Feedback
- XP bar fills with animation on every log
- Level up triggers a full screen celebration moment (Duolingo style)
- The wand duel bar animates smoothly when the lead changes
- Quick log button has a satisfying tap feedback (haptic + animation)
- Feed posts animate in on real-time update

### Reference Apps
| App | What We Take From It |
|---|---|
| Duolingo | Streak system, level up celebration, daily goal progress, gamification loops |
| Strava | Social feed structure, activity post format, friend activity |
| RuneScape | Stat sheet layout, level 1-99 system, character gear, skill categories |
| Stardew Valley | Pixel art character aesthetic, warm and personal feel |

---

## 17. Data & Backend Overview

### Backend: Firebase
- **Firebase Auth** — Sign in with Apple, Sign in with Google, persistent session
- **Firestore** — primary database, real-time listeners for feed, challenges, leagues, leaderboards
- **Firebase Storage** — character sprite assets, any user-uploaded content (future)
- **Firebase Cloud Messaging** — push notifications

### Local: SwiftData
- Used for caching and offline state only
- Logged stats queue locally if offline, sync when connection restored

### Core Data Objects (high level)
- **User** — account info, friendIDs, characterID, pointsBalance
- **Character** — ownerID, appearance config, overall level
- **HardlockedStat** — category, currentXP, level, dailyValue, lifetimeTotal
- **CustomStat** — ownerID, name, type (numeric/boolean), unit, customXPBarID
- **CustomXPBar** — ownerID, name, currentXP, level, xpPerUnit
- **StatEntry** — statID, value, timestamp, note
- **Challenge** — participantIDs, statIDs, goalValue, endDate, status, wagerAmount, escrowedPoints
- **League** — memberIDs, statConfigs (stat + pointsPerUnit), startDate, endDate, prizeStructure, entryWager
- **LeagueEntry** — leagueID, userID, totalPoints, statBreakdown
- **FeedEvent** — authorID, type, message, relatedID, timestamp, reactions, comments
- **Notification** — recipientID, type, message, relatedID, isRead, timestamp

### Real-Time Strategy
Firestore real-time listeners attached to:
- Active challenges (live score updates)
- League leaderboards (live rank changes)
- Social feed (new posts appear instantly)
- Friend activity (triggers notifications)

---

## 18. What Is NOT In Beta

These features are explicitly excluded from the beta build to keep scope manageable.

| Feature | Reason Excluded |
|---|---|
| Public global feed | Requires moderation, scales differently, not needed for friend group |
| Public leagues open to strangers | Same as above |
| Head-to-head league format | Significantly more complex, Points Race covers beta needs |
| Cosmetics shop / points spending | Points economy needs to be established first |
| Health app / Apple Health integration | Complex sync logic, not essential for beta |
| Wealth XP category | Too personal, limited use in beta friend group |
| Community stat submission pipeline | Needs admin tooling, post-beta |
| Custom league head-to-head weekly matchups | Post-beta |
| Animated character sprites | Static pixel art sufficient for beta |
| In-app messaging / DMs | Feed comments cover social needs for beta |
| Web app / Android | iOS only for beta |

---

## 19. Future Roadmap

Listed in rough priority order for post-beta development:

1. **Public global feed** — see activity from all SolRank users worldwide
2. **Public leagues** — open enrollment, discovery tab
3. **Head-to-head league format** — weekly matchups, win/loss records
4. **Cosmetics shop** — spend points on gear, emotes, avatars
5. **Apple Health integration** — auto-sync steps, miles, workouts
6. **Animated character sprites** — idle animations, celebration animations
7. **Community stat submissions** — propose new hardlocked stats for review
8. **Wealth XP category** — financial goals, savings tracking
9. **Android app** — expand platform
10. **Seasonal events** — limited time leagues, holiday challenges, exclusive cosmetics
11. **Guilds / Teams** — group identity beyond just leagues, team vs team
12. **Achievement system** — badges and titles for milestones beyond gear unlocks

---

*This document represents the full beta scope of SolRank as designed in May 2026. All implementation decisions should reference this document first. When starting a new Claude Code or Claude Chat session, paste this document as context before describing any task.*